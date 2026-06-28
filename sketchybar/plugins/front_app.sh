#!/usr/bin/env bash

app="${INFO:-}"

if [ -z "$app" ]; then
  app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
fi

if [ -n "$app" ]; then
  sketchybar --set "$NAME" label="$app"
fi
