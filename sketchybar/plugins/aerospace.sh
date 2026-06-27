#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

FOCUSED=${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}

# Waybar-style workspaces: equal-size dots, state carried by Catppuccin accents.
if [ "$1" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" icon="●" icon.font="JetBrainsMono Nerd Font:Bold:14.0" icon.color="$SKY" background.drawing=off
else
  sketchybar --set "$NAME" icon="●" icon.font="JetBrainsMono Nerd Font:Bold:14.0" icon.color="$OVERLAY" background.drawing=off
fi
