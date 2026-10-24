#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

# capping AeroSpace queries, since its CLI can block for good while the server is busy
aerospace() { perl -e 'alarm 2; exec @ARGV' aerospace "$@"; }

FOCUSED=${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}
FONT="JetBrainsMono Nerd Font"

if [ "$1" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" icon.color="$SKY" icon.font="$FONT:ExtraBold:13.0"
else
  sketchybar --set "$NAME" icon.color="$WORKSPACE_DIM" icon.font="$FONT:SemiBold:13.0"
fi
