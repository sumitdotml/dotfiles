// Renders the strip of wallpaper behind the bar as frosted glass, since SketchyBar's
// own blur barely softens a 37pt strip. Only wallpaper sits under the bar, so it matches.
//
// usage: backdrop <cache_dir> <bar_height_pt>
// prints "<display> <image scale> <png>" per display, or "<display> -" if the wallpaper can't be reproduced
import AppKit
import CoreImage

let blurPt = 24.0
let saturation = 1.8
let targetContrast = 2.8    // against the brightest 10% of the strip; the text shadow does the rest
let localContrast = 3.5     // against local bright patches, which get extra tint just there
let tintRange = 0.25...0.7
let featherPt = 6.0
let crust = [0x11, 0x11, 0x1b].map { Double($0) / 255 }
let text = [0xcd, 0xd6, 0xf4].map { Double($0) / 255 }

let args = CommandLine.arguments
guard args.count == 3, let barPt = Double(args[2]) else {
  FileHandle.standardError.write("usage: backdrop <cache_dir> <bar_height_pt>\n".data(using: .utf8)!)
  exit(2)
}
let cacheDir = args[1]
let imagePt = barPt + 1     // covering the top edge, since SketchyBar centres images 0.5pt low
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CIContext(options: [.workingColorSpace: srgb])

func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
func luminance(_ r: Double, _ g: Double, _ b: Double) -> Double {
  0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
}

func fnv1a(_ s: String) -> String {
  var h: UInt64 = 0xcbf29ce484222325
  for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
  return String(h, radix: 16)
}

func render(_ screen: NSScreen, from url: URL, to path: String) -> Bool {
  guard let src = CIImage(contentsOf: url) else { return false }
  let s = screen.backingScaleFactor
  let W = screen.frame.width * s, H = screen.frame.height * s
  // matching macOS "Fill Screen": scale to cover, centre-crop
  let k = max(W / src.extent.width, H / src.extent.height)
  var img = src.transformed(by: CGAffineTransform(scaleX: k, y: k))
  img = img.transformed(by: CGAffineTransform(translationX: -(img.extent.width - W) / 2 - img.extent.minX,
                                              y: -(img.extent.height - H) / 2 - img.extent.minY))
  img = img.clampedToExtent()
    .applyingGaussianBlur(sigma: blurPt * s / 2)
    .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: saturation])

  let w = Int(W), h = Int(imagePt * s)
  var px = [UInt8](repeating: 0, count: w * h * 4)
  ctx.render(img, toBitmap: &px, rowBytes: w * 4, bounds: CGRect(x: 0, y: H - Double(h), width: W, height: Double(h)),
             format: .RGBA8, colorSpace: srgb)

  var lums: [Double] = []
  for y in Int(10 * s)..<min(h, Int(28 * s)) {
    for x in stride(from: 0, to: w, by: 4) {
      let o = (y * w + x) * 4
      lums.append(luminance(Double(px[o]) / 255, Double(px[o + 1]) / 255, Double(px[o + 2]) / 255))
    }
  }
  lums.sort()
  let p90 = lums[lums.count * 9 / 10]
  let textL = luminance(text[0], text[1], text[2]), crustL = luminance(crust[0], crust[1], crust[2])
  func needed(_ l: Double, _ maxL: Double) -> Double { l <= maxL ? 0 : (l - maxL) / (l - crustL) }
  let maxL = (textL + 0.05) / targetContrast - 0.05
  let tint = min(tintRange.upperBound, max(tintRange.lowerBound, needed(p90, maxL)))

  // smoothing local tint over ~120pt so it never reads as a shape
  let localMaxL = (textL + 0.05) / localContrast - 0.05
  var columnL = [Double](repeating: 0, count: w)
  for x in 0..<w {
    for y in stride(from: Int(10 * s), to: min(h, Int(28 * s)), by: 2) {
      let o = (y * w + x) * 4
      columnL[x] = max(columnL[x], luminance(Double(px[o]) / 255, Double(px[o + 1]) / 255, Double(px[o + 2]) / 255))
    }
  }
  func windowMax(_ v: [Double], _ r: Int) -> [Double] {
    v.indices.map { i in v[max(0, i - r)...min(v.count - 1, i + r)].max()! }
  }
  func boxBlur(_ v: [Double], _ r: Int) -> [Double] {
    var sums = [0.0]
    for x in v { sums.append(sums.last! + x) }
    return v.indices.map { i in
      let a = max(0, i - r), b = min(v.count - 1, i + r)
      return (sums[b + 1] - sums[a]) / Double(b - a + 1)
    }
  }
  let local = boxBlur(boxBlur(windowMax(columnL, Int(24 * s)).map { needed($0, localMaxL) }, Int(60 * s)), Int(60 * s))
  let tints = local.map { min(tintRange.upperBound, max(tint, $0)) }

  for y in 0..<h {
    let a = max(0, min(1, (barPt - Double(y) / s) / featherPt))
    let fade = a * a * (3 - 2 * a)            // feathering the bottom edge into the wallpaper
    for x in 0..<w {
      let o = (y * w + x) * 4
      let tint = tints[x]
      for c in 0..<3 {
        let v = (Double(px[o + c]) / 255 * (1 - tint) + crust[c] * tint) * fade   // premultiplied
        px[o + c] = UInt8((v * 255).rounded())
      }
      px[o + 3] = UInt8((fade * 255).rounded())
    }
  }
  guard let cg = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: srgb,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage(),
        let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { return false }
  return (try? png.write(to: URL(fileURLWithPath: path), options: .atomic)) != nil
}

try? FileManager.default.createDirectory(atPath: cacheDir, withIntermediateDirectories: true)
let cached = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir)) ?? []

for (i, screen) in NSScreen.screens.enumerated() {
  let n = i + 1
  let options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
  let clips = (options[.allowClipping] as? Bool) ?? true
  guard let url = NSWorkspace.shared.desktopImageURL(for: screen), clips,
        let mtime = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else {
    print(n, "-")
    continue
  }
  // naming by input hash, since SketchyBar caches images by path
  let key = "v2|\(url.path)|\(mtime.timeIntervalSince1970)|\(screen.frame.size)|\(screen.backingScaleFactor)|\(barPt)"
  let name = "backdrop-\(n)-\(fnv1a(key)).png"
  let path = "\(cacheDir)/\(name)"
  if !FileManager.default.fileExists(atPath: path) && !render(screen, from: url, to: path) {
    print(n, "-")
    continue
  }
  for old in cached where old.hasPrefix("backdrop-\(n)-") && old != name {
    try? FileManager.default.removeItem(atPath: "\(cacheDir)/\(old)")
  }
  print(n, 1 / screen.backingScaleFactor, path)
}
