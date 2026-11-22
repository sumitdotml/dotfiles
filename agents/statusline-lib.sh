# shared rendering helpers for agent CLI status lines (sourced by cc/ and agy/)
# one line of four groups, from local to account-wide, split by │:
#   where (folder, branch) │ who (model, effort, ...) │ this session (context, ...) │ account (5h, weekly, ...)
# the account group wraps onto a second line only when it all wouldn't fit.

# icons are Nerd Font v3 glyphs: atom, brain, bar chart, custom-folder_oct, git
# branch, clock, calendar. The folder draws wider than one cell, so it carries a second space.
I_MODEL="󰝨"; I_EFFORT="󰧑"; I_CTX=""; I_DIR=" "; I_BRANCH=""
I_5H=""; I_7D=""

RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
SEP=" ${DIM}│${RESET} "
# items within a group sit two spaces apart; │ only separates groups
GAP="  "

JQ_FMT='
  def pct: if . == null then "" else (. | round | tostring) end;
  def tok: if . >= 1000000 then "\((. / 100000 | round) / 10)M"
           elif . >= 1000 then "\(. / 1000 | round)k" else tostring end;
'

# colouring by how much is left: green 50%+, yellow 20-49%, red below 20%
color_left() {
  if (( $1 >= 50 )); then printf %s "$GREEN"
  elif (( $1 >= 20 )); then printf %s "$YELLOW"
  else printf %s "$RED"; fi
}

# showing the reset as a local clock time (no countdown to go stale while idle):
# just the time within a day, the weekday within a week, else the date
reset_time() {
  local at=$1 now; now=$(date +%s)
  if (( at - now < 86400 )); then date -r "$at" +%H:%M
  elif (( at - now < 604800 )); then date -r "$at" '+%a %H:%M'
  else date -r "$at" '+%b %d'; fi
}

# "5h 76% left ↻ 16:16"; a window is absent before the first reply and right
# after it resets, so leaving it out then
limit() {
  local icon=$1 name=$2 used=$3 at=$4 extra=$5
  [ -z "$used" ] && return
  local left=$(( 100 - used )); (( left < 0 )) && left=0
  printf '%s %s %s%d%% left%s' "$icon" "$name" "$(color_left "$left")" "$left" "$RESET"
  [ -n "$extra" ] && printf ' %s%s%s' "$DIM" "$extra" "$RESET"
  [ -n "$at" ] && printf ' %s↻ %s%s' "$DIM" "$(reset_time "$at")" "$RESET"
}

# appending $2 to the group variable named $1 (bash 3.2 has no namerefs, hence eval;
# $2 is only referenced, never expanded into the eval'd code)
add() { eval "$1+=\"\${$1:+\$GAP}\$2\""; }

short_path() {
  local p=$1
  if (( ${#p} > 32 )); then
    local IFS=/; set -- $p
    (( $# > 3 )) && { shift $(( $# - 3 )); p="…/$*"; }
  fi
  printf %s "$p"
}

# where the agent is, relative to where the session started: "dotfiles" there,
# "dotfiles/rex" in a subfolder (start dimmed, subfolder cyan), and in yellow
# "dotfiles → ../nvim" next door or "dotfiles → ~/.config/rex" anywhere else
location() {
  local home=${PROJ##*/}
  if [ "$DIR" = "$PROJ" ]; then
    printf %s "${DIR##*/}"
  elif [ "${DIR#"$PROJ"/}" != "$DIR" ]; then
    printf '%s%s/%s%s%s%s' "$DIM" "$home" "$RESET" "$CYAN" "$(short_path "${DIR#"$PROJ"/}")" "$RESET"
  else
    local away=${DIR/#$HOME/\~} parent=${PROJ%/*}
    [ "${DIR#"$parent"/}" != "$DIR" ] && away="../${DIR#"$parent"/}"
    printf '%s %s→ %s%s' "$home" "$YELLOW" "$(short_path "$away")" "$RESET"
  fi
}

# counting characters without colour codes, in perl since bash may count bytes
width() {
  printf '%s' "$1" | perl -CS -ne 's/\e\[[0-9;]*m//g; print length'
}

render_statusline() {
  local where="" branch who="" session="" account="" p s
  add where "$I_DIR $(location)"
  # reading the branch of the agent's folder, not of wherever this script runs, so
  # it follows the agent into another repo
  branch=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && add where "$I_BRANCH $branch"

  add who "$I_MODEL $MODEL"
  [ -n "$EFFORT" ] && add who "$I_EFFORT $EFFORT"
  [ -n "$WHO_EXTRA" ] && add who "$WHO_EXTRA"
  [ -n "$VERSION" ] && add who "${DIM}v$VERSION$RESET"

  CTX=${CTX:-0}
  add session "$I_CTX $(color_left $(( 100 - CTX )))${CTX}%${RESET} ${DIM}${CTX_TOK}/${CTX_MAX}${RESET}"
  [ -n "$SESSION_EXTRA" ] && add session "$SESSION_EXTRA"

  for p in "$(limit "$I_5H" 5h "$H5" "$H5_AT")" "$(limit "$I_7D" 7d "$D7" "$D7_AT")" "$ACCOUNT_EXTRA"; do
    [ -n "$p" ] && add account "$p"
  done

  s="$where$SEP$who$SEP$session"
  if [ -z "$account" ]; then
    echo "$s"
  # leaving 4 columns for the padding the CLI puts around the status line
  elif (( $(width "$s$SEP$account") <= ${TERM_WIDTH:-${COLUMNS:-80}} - 4 )); then
    echo "$s$SEP$account"
  else
    echo "$s"
    echo "$account"
  fi
}
