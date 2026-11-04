import AppKit
import Foundation

// reading heading requests as JSON on stdin and printing the written PNGs as JSON;
// a heading that fits on one line is drawn tight to fitPath so window width does not
// matter, a longer one wraps at width and goes to wrapPath; a heading with a rule
// colour is drawn across the full width with a GitHub-style line under it

func color(_ hex: String) -> NSColor {
    let value = UInt32(hex, radix: 16) ?? 0
    return NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255,
                   green: CGFloat((value >> 8) & 255) / 255,
                   blue: CGFloat(value & 255) / 255, alpha: 1)
}

// "system" is SF Pro, "serif" New York, "rounded" SF Pro Rounded and "mono" SF Mono
func headingFont(_ name: String, size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let system = NSFont.systemFont(ofSize: size, weight: weight)
    let designs: [String: NSFontDescriptor.SystemDesign] = ["serif": .serif, "rounded": .rounded, "mono": .monospaced]
    guard let design = designs[name], let descriptor = system.fontDescriptor.withDesign(design) else { return system }
    return NSFont(descriptor: descriptor, size: size) ?? system
}

func styled(_ source: String, base: NSFont, strong: NSFont, foreground: NSColor, code: NSColor) -> NSAttributedString {
    guard let parsed = try? AttributedString(markdown: source,
        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else {
        return NSAttributedString(string: source, attributes: [.font: base, .foregroundColor: foreground])
    }
    let result = NSMutableAttributedString()
    for run in parsed.runs {
        let intent = run.inlinePresentationIntent ?? []
        var font = base
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: foreground]
        if intent.contains(.code) {
            font = NSFont.monospacedSystemFont(ofSize: base.pointSize * 0.86, weight: .medium)
            attributes[.foregroundColor] = code
        } else {
            if intent.contains(.stronglyEmphasized) { font = strong }
            if intent.contains(.emphasized) {
                font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            }
            if intent.contains(.strikethrough) {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
        }
        attributes[.font] = font
        result.append(NSAttributedString(string: String(parsed[run.range].characters), attributes: attributes))
    }
    return result
}

let input = FileHandle.standardInput.readDataToEndOfFile()
guard let requests = (try? JSONSerialization.jsonObject(with: input)) as? [[String: Any]] else {
    FileHandle.standardError.write("heading-image: invalid request\n".data(using: .utf8)!)
    exit(2)
}
var results: [[String: Any]] = []
for item in requests {
    guard let source = item["text"] as? String, let level = item["level"] as? Int, (1...3).contains(level),
          let maxWidth = item["width"] as? Int, let cellWidth = item["cellWidth"] as? Double,
          let cellHeight = item["cellHeight"] as? Double,
          let foreground = item["foreground"] as? String, let code = item["code"] as? String,
          let background = item["background"] as? String,
          let fitKey = item["fitKey"] as? String, let wrapKey = item["wrapKey"] as? String,
          let fitPath = item["fitPath"] as? String, let wrapPath = item["wrapPath"] as? String
    else { continue }
    let rule = (item["rule"] as? String).map(color)
    let fontName = item["font"] as? String ?? "system"
    let size = CGFloat(cellHeight * [1.65, 1.30, 1.05][level - 1])
    let base = headingFont(fontName, size: size, weight: level == 1 ? .bold : .semibold)
    let strong = headingFont(fontName, size: size, weight: .heavy)
    let attributed = styled(source, base: base, strong: strong, foreground: color(foreground), code: color(code))
    // sizing rows from the heading font alone, so Japanese or emoji fallback fonts cannot add a row
    let lineHeight = ceil(base.ascender - base.descender)
    let natural = ceil(attributed.size().width) + 2
    let fits = natural <= CGFloat(maxWidth)
    let textWidth = fits ? natural : CGFloat(maxWidth)
    let empty = source.isEmpty
    let textHeight = empty ? 0 : fits ? lineHeight : ceil(attributed.boundingRect(
        with: NSSize(width: textWidth, height: 10000), options: [.usesLineFragmentOrigin]).height)
    // reserving room under the text for a gap, the rule and a little space below it
    let thickness = max(1, (CGFloat(cellHeight) / 16).rounded())
    let gap = empty ? 0 : (size * 0.18).rounded()
    let below = (CGFloat(cellHeight) * 0.08).rounded()
    let reserved = rule == nil ? 0 : gap + thickness + below
    let drawWidth = rule == nil ? textWidth : CGFloat(maxWidth)
    let rows = max(1, Int(ceil((textHeight + reserved) / CGFloat(cellHeight))))
    let cols = max(1, Int(ceil(drawWidth / CGFloat(cellWidth))))
    let width = Int(ceil(Double(cols) * cellWidth)), height = Int(ceil(Double(rows) * cellHeight))
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { continue }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    color(background).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    // leaving most spare height above the text so a heading sits on the content it introduces;
    // a ruled heading puts all of it above, keeping the text close to its line
    let spare = CGFloat(height) - textHeight - reserved
    let top = reserved + spare * (rule == nil ? 0.35 : 0) + textHeight
    // extending the rect downwards so a taller fallback line is drawn instead of dropped
    attributed.draw(with: NSRect(x: 0, y: top - 4 * textHeight, width: textWidth, height: 4 * textHeight),
        options: [.usesLineFragmentOrigin])
    if let rule {
        // centring the rule of an empty heading in its row, so the space above and below it is equal
        let y = empty ? ((CGFloat(height) - thickness) / 2).rounded() : below
        rule.setFill()
        NSRect(x: 0, y: y, width: CGFloat(width), height: thickness).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    let path = fits ? fitPath : wrapPath
    guard let png = bitmap.representation(using: .png, properties: [:]),
          (try? png.write(to: URL(fileURLWithPath: path), options: .atomic)) != nil else { continue }
    results.append(["request": fitKey, "key": fits ? fitKey : wrapKey, "path": path, "rows": rows, "cols": cols])
}
FileHandle.standardOutput.write(try! JSONSerialization.data(withJSONObject: results))
