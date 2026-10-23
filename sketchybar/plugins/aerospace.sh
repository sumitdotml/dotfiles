#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

FOCUSED=${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}
FONT="JetBrainsMono Nerd Font"

if [ "$1" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" icon.color="$SKY" icon.font="$FONT:ExtraBold:13.0"
else
  sketchybar --set "$NAME" icon.color="$WORKSPACE_DIM" icon.font="$FONT:SemiBold:13.0"
fi
