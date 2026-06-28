#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="$DOTFILES_DIR/assets/macos-theme"
LANDSCAPE_DIR="$THEME_DIR/landscapes"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "macOS theme can only be applied on macOS." >&2
    exit 1
fi

images=()
while IFS= read -r image_path; do
    images+=("$image_path")
done < <(
    find "$LANDSCAPE_DIR" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
        | sort
)

if [ "${#images[@]}" -eq 0 ]; then
    echo "No wallpapers found in $LANDSCAPE_DIR." >&2
    exit 1
fi

today="$(date +%F)"
today_epoch="$(date -j -f "%Y-%m-%d" "$today" +%s)"
image="${images[$(((today_epoch / 86400) % ${#images[@]}))]}"

osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$image\""
echo "desktop wallpaper applied: $(basename "$image")"

uuid=$(dscl . -read "/Users/$(whoami)" GeneratedUID | awk '{print $2}')
lock_dir="/Library/Caches/Desktop Pictures/$uuid"

mkdir -p "$lock_dir"
sips -s format png "$image" --out "$lock_dir/lockscreen.png" >/dev/null
chmod 750 "$lock_dir" 2>/dev/null || true
chmod 640 "$lock_dir/lockscreen.png" 2>/dev/null || true
chgrp _securityagent "$lock_dir" "$lock_dir/lockscreen.png" 2>/dev/null || true
echo "lockscreen wallpaper applied: $(basename "$image")"
