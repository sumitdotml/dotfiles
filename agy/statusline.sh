#!/bin/bash
# Antigravity CLI (agy) status line, wired from ~/.gemini/antigravity-cli/settings.json
input=$(cat)

# resolving the symlink so ~/.gemini/antigravity-cli/statusline.sh finds the shared library in the repo
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../agents/statusline-lib.sh"

# reading every field in one jq pass: stripping the effort suffix repeated in
# display_name ("Gemini 4 Neon (High)"), measuring context from total_input_tokens
# (which matches used_percentage), and picking gemini-* vs 3p-* quota buckets
eval "$(jq -r "$JQ_FMT"'
  def b_used: if .remaining_fraction == null then "" else ((1 - .remaining_fraction) * 100 | pct) end;
  def b_at: if .reset_in_seconds == null then "" else (now + .reset_in_seconds | floor | tostring) end;
  (if (.model.id // "") | test("gemini|orchestrator"; "i") then "gemini" else "3p" end) as $p
  | (.quota["\($p)-5h"] // {}) as $h5
  | (.quota["\($p)-weekly"] // {}) as $d7
  | @sh "MODEL=\(.model.display_name // .model.id // "?" | sub(" \\([^)]*\\)$"; ""))",
    @sh "EFFORT=\(.model.effort // "")",
    @sh "MODE=\(.cycle_mode // "")",
    @sh "CTX=\(.context_window.used_percentage | pct)",
    @sh "CTX_TOK=\(.context_window.total_input_tokens // 0 | tok)",
    @sh "CTX_MAX=\(.context_window.context_window_size // 0 | tok)",
    @sh "DIR=\(.workspace.current_dir // .cwd // "")",
    @sh "PROJ=\(.workspace.project_dir // .workspace.current_dir // .cwd // "")",
    @sh "H5=\($h5 | b_used)",
    @sh "H5_AT=\($h5 | b_at)",
    @sh "D7=\($d7 | b_used)",
    @sh "D7_AT=\($d7 | b_at)",
    @sh "TERM_WIDTH=\(.terminal_width // "")",
    @sh "VERSION=\(.version // "")",
    @sh "VIM=\(.vim.mode // "")"
' <<<"$input")"

render_statusline

# showing Vim mode and shift+tab cycle mode on the line below, since a custom
# status line replaces Antigravity's built-in footer
FOOTER=""
if [ -n "$VIM" ]; then
  case "$VIM" in
    NORMAL)  vc=$'\033[1;38;2;137;180;250m' ;;
    INSERT)  vc=$'\033[1;38;2;166;227;161m' ;;
    VISUAL*) vc=$'\033[1;38;2;203;166;247m' ;;
    *)       vc=$'\033[1m' ;;
  esac
  add FOOTER "${DIM}--${RESET} ${vc}${VIM}${RESET} ${DIM}--${RESET}"
fi
[ -n "$MODE" ] && add FOOTER $'\033[38;5;215m'"▶▶ $MODE$RESET"
if [ -n "$FOOTER" ]; then echo "$FOOTER"; fi
