#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

# using the event's volume (SketchyBar sends 0 while muted) rather than querying again, since a
# slow query could finish after a newer event's; AppleScript is only for startup, and it reports
# "missing value" for outputs without volume control
if [ -n "$INFO" ]; then
  vol=$INFO
else
  read -r vol muted < <(osascript -e 'set s to get volume settings' \
    -e '(output volume of s as text) & " " & (output muted of s as text)' 2>/dev/null)
  [ "$muted" = "true" ] && vol=0
fi
label="${vol}%"

case "$vol" in
  0)            icon="󰖁" color=$OVERLAY ;;
  [1-9] | [1-3][0-9]) icon="󰕿" color=$SAPPHIRE ;;
  [4-6][0-9])   icon="󰖀" color=$SAPPHIRE ;;
  [7-9][0-9] | 100) icon="󰕾" color=$SAPPHIRE ;;
  *)            icon="󰖁" color=$OVERLAY label="--" ;;
esac

sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="$label"
