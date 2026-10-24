#!/usr/bin/env bash
# AeroSpace's NSScreen index matches SketchyBar's display numbering; 1 is the main display

# capping AeroSpace queries, since its CLI can block for good while the server is busy
aerospace() { perl -e 'alarm 2; exec @ARGV' aerospace "$@"; }

args=()
while read -r ws monitor; do
  args+=(--set "space.$ws" display="$monitor")
done < <(aerospace list-workspaces --all --format '%{workspace} %{monitor-appkit-nsscreen-screens-id}')

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
