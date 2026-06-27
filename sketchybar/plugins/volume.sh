#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

vol="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
muted=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)

if [ "$muted" = "true" ]; then
  icon="󰖁" color=$OVERLAY
else
  case "$vol" in
    0)            icon="󰖁" color=$OVERLAY ;;
    [1-9] | [1-3][0-9]) icon="󰕿" color=$TEAL ;;
    [4-6][0-9])   icon="󰖀" color=$TEAL ;;
    *)            icon="󰕾" color=$TEAL ;;
  esac
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="${vol}%"
