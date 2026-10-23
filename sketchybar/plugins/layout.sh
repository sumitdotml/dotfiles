#!/usr/bin/env bash
# AeroSpace's NSScreen index matches SketchyBar's display numbering; 1 is the main display

args=()
while read -r ws monitor; do
  args+=(--set "space.$ws" display="$monitor")
done < <(aerospace list-workspaces --all --format '%{workspace} %{monitor-appkit-nsscreen-screens-id}')

for item in weather tailscale language volume battery; do
  args+=(--set "$item" display=1)
done

sketchybar "${args[@]}"
