#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

src=$("$CONFIG_DIR/helpers/inputsource" 2>/dev/null)

case "$src" in
  *Katakana*)                          label="ア" ;;
  *Japanese* | *Hiragana* | *Kotoeri.Japanese) label="あ" ;;
  *.Roman*)                            label="EN" ;;
  *keylayout.ABC* | *keylayout.US* | *keylayout.British*) label="EN" ;;
  "")                                  label="?" ;;
  *) label="${src##*.}"; label="${label:0:2}" ;;
esac

sketchybar --set "$NAME" icon="󰗊" icon.color="$YELLOW" label="$label"
