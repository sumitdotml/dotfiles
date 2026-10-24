#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

batt=$(pmset -g batt)
pct=$(grep -Eo '[0-9]+%' <<< "$batt" | cut -d% -f1)
charging=$(grep 'AC Power' <<< "$batt")

if [ -z "$pct" ]; then
  exit 0
fi

if [ -n "$charging" ]; then
  icon="󰂄"
  color=$GREEN
else
  case "$pct" in
    100 | 9[0-9]) icon="󰁹" color=$BLUE ;;
    [678][0-9])   icon="󰂁" color=$BLUE ;;
    [45][0-9])    icon="󰁾" color=$YELLOW ;;
    [23][0-9])    icon="󰁻" color=$PEACH ;;
    *)            icon="󰁺" color=$RED ;;
  esac
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="${pct}%"
