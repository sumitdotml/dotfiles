#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

usage=$(top -l 2 -s 0 | grep -E "^CPU usage" | tail -1 \
  | awk '{u=$3; s=$5; gsub(/%/,"",u); gsub(/%/,"",s); printf "%d", u+s}')

case "$usage" in
  [0-9] | [1-4][0-9]) color=$GREEN ;;
  [5-7][0-9])         color=$YELLOW ;;
  *)                  color=$RED ;;
esac

sketchybar --set "$NAME" icon.color="$color" label="${usage}%"
