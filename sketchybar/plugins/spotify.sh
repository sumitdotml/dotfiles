#!/usr/bin/env bash

CACHE="$HOME/Library/Caches/sketchybar/spotify-artists"
STATE="$HOME/Library/Caches/sketchybar/spotify-label"
RUN="$HOME/Library/Caches/sketchybar/spotify-run"
COVERS="$HOME/Library/Caches/sketchybar/spotify-covers"
SEP=$'\x1f'

# printing the label as-is if it fits ~43 columns (CJK renders two wide, and that clears a long
# app name by the notch), otherwise one window per step through "label + gap", wrapping around
frames() {
  perl -CSA -e '$max = 43; @c = split //, $ARGV[0]; $w = sub { $_[0] =~ /\p{EA=W}|\p{EA=F}/ ? 2 : 1 };
    $t += $w->($_) for @c; if ($t <= $max) { print "$ARGV[0]\n"; exit }
    push @c, (" ") x 5;
    for $i (0 .. $#c) { ($out, $used) = ("", 0);
      for ($j = $i; $used + $w->($c[$j % @c]) <= $max; $j++) { $used += $w->($c[$j % @c]); $out .= $c[$j % @c] }
      print "$out\n" }' "$1"
}

# redrawing a cover as 24px over 2 transparent rows, shown at scale 0.5, since SketchyBar rounds
# the 37pt bar's centre down and draws images 0.5pt low; the extra rows lift the picture back.
# rounding the corners here too, as SketchyBar's corner_radius would round the padded box instead
pad_cover() {
  osascript -l JavaScript - "$1" "$2" >/dev/null 2>&1 <<'JXA'
ObjC.import('AppKit');
function run(argv) {
  const img = $.NSImage.alloc.initWithContentsOfFile(argv[0]);
  if (img.isNil()) throw 'unreadable cover';
  const rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, 24, 26, 8, 4, true, false, $.NSDeviceRGBColorSpace, 0, 0);
  $.NSGraphicsContext.saveGraphicsState;
  $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
  $.NSGraphicsContext.currentContext.imageInterpolation = $.NSImageInterpolationHigh;
  $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius($.NSMakeRect(0, 2, 24, 24), 6, 6).addClip;
  img.drawInRectFromRectOperationFraction($.NSMakeRect(0, 2, 24, 24), $.NSZeroRect, $.NSCompositingOperationCopy, 1);
  $.NSGraphicsContext.restoreGraphicsState;
  if (!rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $()).writeToFileAtomically(argv[1], true))
    throw 'unwritable cover';
}
JXA
}

# scrolling long labels ourselves, since SketchyBar's scroll_texts can't hold for a set time and
# keeps scrolling across label changes; exiting once a newer run rewrites $STATE. "$0 --ticker"
# stays in perl's arguments so pkill/pgrep -f still find the ticker after the exec
if [ "$1" = "--ticker" ]; then
  steps=()
  while IFS= read -r f; do steps+=("$f"); done < <(frames "$3")
  exec perl -CSA -MTime::HiRes=time,sleep -e '($mark, $token, $state, $name, $pad, @steps) = @ARGV;
    sub mine { open my $f, "<", $state or return; (split /\x1f/, <$f>)[0] eq $token }
    for (;;) {
      sleep 3.5; $t = time;
      for $k (1 .. $#steps, 0) {
        # swapping in the next window pushed right by the leaving character (7pt, 12pt for CJK),
        # then gliding back to the resting padding at 1pt per 3 frames (20pt/s); staying positive,
        # since SketchyBar rounds animated values toward zero and would stall around 0
        $d = substr($steps[$k - 1], 0, 1) =~ /\p{EA=W}|\p{EA=F}/ ? 12 : 7;
        mine() && system("sketchybar", "--set", $name, "label=$steps[$k]", "label.padding_left=" . ($pad + $d),
          "--animate", "linear", 3 * $d, "--set", $name, "label.padding_left=$pad") == 0 or exit;
        # keeping an absolute clock, so each step starts just as the previous glide ends
        $t += $d / 20; sleep $t - time if $t > time;
      }
    }' "$0 --ticker" "$2" "$STATE" "$NAME" "$4" "${steps[@]}"
fi

mkdir -p "${RUN%/*}"
echo "$$" > "$RUN"

if [ "$SENDER" = "spotify_change" ] && [ -n "$INFO" ]; then
  fields=$(printf '%s' "$INFO" | jq -r '[.["Player State"], .["Track ID"], .Name, .Artist] | map(. // "") | join("\u001f")' 2>/dev/null)
elif pgrep -x Spotify >/dev/null; then
  fields=$(osascript 2>/dev/null <<'APPLESCRIPT'
tell application "Spotify"
  if it is running then
    set t to current track
    set s to ASCII character 31
    return (player state as text) & s & (id of t) & s & (name of t) & s & (artist of t)
  end if
end tell
APPLESCRIPT
  )
fi

IFS="$SEP" read -r state id name artist <<< "$fields"

if [[ "$state" != [Pp]laying ]] || [ -z "$name" ]; then
  pkill -f "$0 --ticker"
  rm -f "$STATE"
  sketchybar --set "$NAME.logo" drawing=off --set "$NAME" drawing=off label=""
  exit 0
fi

# Spotify's notification and AppleScript only name the first artist, but the track's public
# page lists them all; waiting for it, so a new song appears complete rather than in two steps
cover="$COVERS/${id##*:}.png"
cached=$(grep -m1 "^$id$SEP" "$CACHE" 2>/dev/null)
if [ -n "$cached" ]; then
  artists=${cached#*"$SEP"}
else
  artists=$artist
  if [[ "$id" == spotify:track:* ]] && page=$(curl -fsL --max-time 3 "https://open.spotify.com/track/${id##*:}"); then
    all=$(printf '%s' "$page" | sed -n 's/.*<meta name="music:musician_description" content="\([^"]*\)".*/\1/p' \
      | sed -e 's/&quot;/"/g' -e "s/&#x27;/'/g" -e "s/&#39;/'/g" -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/\&/g')
    artists=${all:-$artist}
    # fetching the 64px copy (ab67616d00004851...) of the 640px cover the page links
    # (ab67616d0000b273...)
    art=$(printf '%s' "$page" | sed -n 's/.*<meta property="og:image" content="https:\/\/i.scdn.co\/image\/ab67616d0000b273\([0-9a-f]*\)".*/\1/p')
    if [ -n "$art" ] && mkdir -p "$COVERS" && curl -fs --max-time 3 -o "$cover.$$.jpg" "https://i.scdn.co/image/ab67616d00004851$art" \
      && pad_cover "$cover.$$.jpg" "$cover.$$"; then
      mv "$cover.$$" "$cover"
      ls -t "$COVERS" | tail -n +201 | while read -r old; do rm -f "$COVERS/$old"; done
    fi
    rm -f "$cover.$$.jpg" "$cover.$$"
    # keeping the 200 most recent songs, newest first, so going back to one is instant
    { printf '%s%s%s\n' "$id" "$SEP" "$artists"; head -n 199 "$CACHE" 2>/dev/null; } > "$CACHE.$$"
    mv "$CACHE.$$" "$CACHE"
  fi
  # dropping this run if a newer one (a skip, a pause) started while the page loaded
  read -r latest < "$RUN"
  [ "$latest" = "$$" ] || exit 0
fi

label=$name
[ -n "$artists" ] && label+=" · $artists"

# leaving a running ticker alone when the 30s poll or a reload finds the same label
IFS="$SEP" read -r _ current 2>/dev/null < "$STATE"
if [ "$current" = "$label" ] && pgrep -f "$0 --ticker" >/dev/null; then
  sketchybar --set "$NAME.logo" drawing=on --set "$NAME" drawing=on
  exit 0
fi

pkill -f "$0 --ticker"
printf '%s%s%s\n' "$$" "$SEP" "$label" > "$STATE"

steps=$(frames "$label")
# falling back to the logo alone for songs without a cover (local files, an unreachable page);
# spacing the text from the cover with label padding, since icon paddings don't apply to an image
if [ -f "$cover" ]; then
  icon=(icon.drawing=on icon.background.image="$cover") pad=9
else
  icon=(icon.drawing=off) pad=0
fi
sketchybar --set "$NAME.logo" drawing=on \
  --set "$NAME" drawing=on label="${steps%%$'\n'*}" label.padding_left="$pad" "${icon[@]}"
if [[ "$steps" == *$'\n'* ]]; then
  "$0" --ticker "$$" "$label" "$pad" >/dev/null 2>&1 &
fi
