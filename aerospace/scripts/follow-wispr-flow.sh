#!/usr/bin/env bash

workspace="${1:-}"

if [ -z "$workspace" ]; then
    workspace=$(aerospace list-workspaces --focused 2>/dev/null)
fi

if [ -z "$workspace" ]; then
    exit 0
fi

aerospace list-windows \
    --monitor all \
    --app-bundle-id com.electron.wispr-flow \
    --format '%{window-id}' 2>/dev/null |
while IFS= read -r window_id; do
    [ -n "$window_id" ] || continue

    if ! aerospace move-node-to-workspace --window-id "$window_id" "$workspace" 2>/dev/null; then
        aerospace layout --window-id "$window_id" tiling 2>/dev/null || true
        aerospace move-node-to-workspace --window-id "$window_id" "$workspace" 2>/dev/null || true
    fi

    aerospace layout --window-id "$window_id" floating 2>/dev/null || true
done
