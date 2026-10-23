#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

CACHE="$HOME/Library/Caches/sketchybar"
read -r height pad < <(sketchybar --query bar | jq -r '"\(.height) \(.padding_left)"')
output=$("$CONFIG_DIR/helpers/backdrop" "$CACHE" "$height" 2>/dev/null) || output=""

args=()
keep=" "
fallback=0
[ -z "$output" ] && fallback=1

while read -r n path; do
  [ -z "$n" ] && continue
  if [ "$path" = "-" ]; then
    fallback=1
    continue
  fi
  item="backdrop.$n"
  keep+="$item "
  if ! sketchybar --query "$item" >/dev/null 2>&1; then
    first=$(sketchybar --query bar | jq -r '[.items[] | select(startswith("backdrop.") | not)][0]')
    sketchybar --add item "$item" left \
      --move "$item" before "$first" \
      --set "$item" width=0 padding_left=0 padding_right=0 \
        icon.drawing=off label.drawing=off \
        background.drawing=on background.color=0x00000000 \
        background.height=$((height + 1)) background.padding_left=-$pad \
        background.image.scale=0.5
  fi
  args+=(--set "$item" display="$n" background.image="$path")
done <<< "$output"

for item in $(sketchybar --query bar | jq -r '.items[] | select(startswith("backdrop."))'); do
  if [ "$fallback" = 1 ] || [[ "$keep" != *" $item "* ]]; then
    args+=(--remove "$item")
  fi
done

if [ "$fallback" = 1 ]; then
  args+=(--bar color="$BAR_COLOR" blur_radius=40)
else
  args+=(--bar color=0x00000000 blur_radius=0)
fi

sketchybar "${args[@]}"
