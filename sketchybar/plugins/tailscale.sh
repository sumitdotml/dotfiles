#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

state=$(tailscale status --json 2>/dev/null | jq -r '
  if .BackendState == "Running" then
    if .ExitNodeStatus != null then
      if .ExitNodeStatus.Online then "exit" else "offline" end
    else "direct" end
  else "disconnected" end
' 2>/dev/null)

# padding per glyph, since SketchyBar places a label by its cell but sizes it by its ink
case "$state" in
  exit)         label="→" color=$TEAL    lpad=8 rpad=7 ;;
  direct)       label=""  color=$SUBTEXT lpad=8 rpad=7 ;;
  offline)      label="!" color=$YELLOW  lpad=5 rpad=9 ;;
  disconnected) label="×" color=$OVERLAY lpad=7 rpad=8 ;;
  *)            label="?" color=$YELLOW  lpad=7 rpad=9 ;;
esac

# standing in for the hidden label's padding when the logo is alone
if [ -n "$label" ]; then
  drawing=on pad=2
else
  drawing=off pad=9
fi

sketchybar --set "$NAME" label="$label" label.color="$color" label.drawing="$drawing" \
  label.padding_left="$lpad" label.padding_right="$rpad" padding_right="$pad"
