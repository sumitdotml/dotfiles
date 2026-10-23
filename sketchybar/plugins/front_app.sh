#!/usr/bin/env bash

# following focus, so with two monitors the name also shows which one is active
display=$(aerospace list-monitors --focused --format '%{monitor-appkit-nsscreen-screens-id}' 2>/dev/null)
[ -n "$display" ] && sketchybar --set "$NAME" display="$display"

[ "$SENDER" = "aerospace_workspace_change" ] && exit 0

app="${INFO:-}"

if [ -z "$app" ]; then
  app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
fi

if [ -n "$app" ]; then
  sketchybar --set "$NAME" label="$app"
fi
