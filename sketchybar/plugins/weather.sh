#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

# wttr.in: location auto-detected by IP. %t = temperature, %C = condition text.
read -r temp cond < <(curl -s --max-time 5 "wttr.in/?format=%t|%C" | tr '|' ' ')

if [ -z "$temp" ]; then
  sketchybar --set "$NAME" icon="󰖐" label="--"
  exit 0
fi

case "$cond" in
  *Sunny* | *Clear*)        icon="󰖙" ;;
  *Partly*)                 icon="󰖕" ;;
  *Cloud* | *Overcast*)     icon="󰖐" ;;
  *Rain* | *Drizzle*)       icon="󰖗" ;;
  *Hail* | *Sleet*)         icon="󰖒" ;;
  *Snow*)                   icon="󰖘" ;;
  *Thunder*)                icon="󰖓" ;;
  *Fog* | *Mist*)           icon="󰖑" ;;
  *)                        icon="󰖐" ;;
esac

sketchybar --set "$NAME" icon="$icon" icon.color="$TEAL" label="${temp// /}"
