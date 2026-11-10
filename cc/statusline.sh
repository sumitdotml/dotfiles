#!/bin/bash
# Claude Code status line (fields: https://code.claude.com/docs/en/statusline)
# One line of four groups, from local to account-wide, split by │:
#   where (folder, branch) │ who (model, effort, fast) │ this session (context,
#   cost) │ account (5h, weekly, spend, credits left, with when each resets)
# The account group wraps onto a second line only when it all wouldn't fit.
input=$(cat)

# icons are Nerd Font v3 glyphs: atom, brain, bar chart, custom-folder_oct, git
# branch, clock, calendar, credit card, bolt, receipt. The folder and card draw
# wider than one cell, so they carry a second space.
I_MODEL="󰝨"; I_EFFORT="󰧑"; I_CTX=""; I_DIR=" "; I_BRANCH=""
I_5H=""; I_7D=""; I_SPEND=" "; I_FAST=""; I_COST="󰑉"

# reading every field in one jq pass; percentages arrive as floats, so rounding here
eval "$(jq -r '
  def pct: if . == null then "" else (. | round | tostring) end;
  def tok: if . >= 1000000 then "\((. / 100000 | round) / 10)M"
           elif . >= 1000 then "\(. / 1000 | round)k" else tostring end;
  (.context_window.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | @sh "MODEL=\(.model.display_name // "?")",
    @sh "EFFORT=\(.effort.level // "")",
    @sh "FAST=\(.fast_mode // false)",
    @sh "CTX=\(.context_window.used_percentage | pct)",
    @sh "CTX_TOK=\($used | tok)",
    @sh "CTX_MAX=\(.context_window.context_window_size // 0 | tok)",
    @sh "DIR=\(.workspace.current_dir // .cwd // "")",
    @sh "PROJ=\(.workspace.project_dir // .workspace.current_dir // .cwd // "")",
    @sh "H5=\(.rate_limits.five_hour.used_percentage | pct)",
    @sh "H5_AT=\(.rate_limits.five_hour.resets_at // "")",
    @sh "D7=\(.rate_limits.seven_day.used_percentage | pct)",
    @sh "D7_AT=\(.rate_limits.seven_day.resets_at // "")",
    @sh "SP=\(.rate_limits.spend_limit.used_percentage | pct)",
    @sh "SP_AT=\(.rate_limits.spend_limit.resets_at // "")",
    @sh "SP_USD=\(.rate_limits.spend_limit.used_usd // "" | if . == "" then . else round end)",
    @sh "SP_LIM=\(.rate_limits.spend_limit.limit_usd // "" | if . == "" then . else round end)",
    @sh "SP_PERIOD=\(.rate_limits.spend_limit.period // "")",
    @sh "COST=\(.cost.total_cost_usd // 0 | . * 100 | round / 100)"
' <<<"$input")"

RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
SEP=" ${DIM}│${RESET} "

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

# items within a group sit two spaces apart; │ only separates groups
GAP="  "
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

# reading the branch of the agent's folder, not of wherever this script runs, so
# it follows the agent into another repo
WHERE=""
add WHERE "$I_DIR $(location)"
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] && add WHERE "$I_BRANCH $BRANCH"

WHO=""
add WHO "$I_MODEL $MODEL"
[ -n "$EFFORT" ] && add WHO "$I_EFFORT $EFFORT"
[ "$FAST" = "true" ] && add WHO "$I_FAST fast"

SESSION=""
CTX=${CTX:-0}
add SESSION "$I_CTX $(color_left $(( 100 - CTX )))${CTX}%${RESET} ${DIM}${CTX_TOK}/${CTX_MAX}${RESET}"

# spend dollars arrive minutes after the percentage, so adding them once both are in
SP_EXTRA=""
[ -n "$SP_USD" ] && [ -n "$SP_LIM" ] && SP_EXTRA="\$${SP_USD}/\$${SP_LIM}${SP_PERIOD:+ $SP_PERIOD}"
ACCOUNT=""
for p in "$(limit "$I_5H" 5h "$H5" "$H5_AT")" "$(limit "$I_7D" 7d "$D7" "$D7_AT")" "$(limit "$I_SPEND" spend "$SP" "$SP_AT" "$SP_EXTRA")"; do
  [ -n "$p" ] && add ACCOUNT "$p"
done

# usage credits (e.g. an Enterprise seat's monthly limit), which Claude Code
# doesn't pass to status lines. Fetching them from the endpoint behind /usage,
# which is undocumented and may change; any failure just hides the segment.
# Only for sessions without 5h/weekly limits, so a subscription is untouched.
# Nothing secret lives in this file: the token is read from the Keychain entry
# Claude Code keeps for this config dir, held only in memory, and handed to curl
# on stdin. The cache holds just the credit figures, outside the repo.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
KEY="default"; KC_SERVICE="Claude Code-credentials"
if [ -n "$CLAUDE_CONFIG_DIR" ]; then
  KEY=$(printf %s "$CLAUDE_CONFIG_DIR" | shasum -a 256 | cut -c1-8)
  KC_SERVICE+="-$KEY"
fi
CREDITS_CACHE="$CACHE_DIR/credits-$KEY.json"
CREDITS_ATTEMPT="$CACHE_DIR/credits-$KEY.attempt"

# refreshing in the background at most every 5 minutes (the endpoint rate limits),
# so the status line never waits on the network
refresh_credits() {
  [ -f "$CREDITS_ATTEMPT" ] && (( $(date +%s) - $(stat -f %m "$CREDITS_ATTEMPT") < 300 )) && return
  (
    umask 077; mkdir -p "$CACHE_DIR"; touch "$CREDITS_ATTEMPT"
    tok=$(security find-generic-password -s "$KC_SERVICE" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
    [ -n "$tok" ] || exit 0
    resp=$(printf 'header = "Authorization: Bearer %s"\n' "$tok" |
      curl -sS -m 10 -K - -H 'anthropic-beta: oauth-2025-04-20' https://api.anthropic.com/api/oauth/usage) || exit 0
    credits=$(printf %s "$resp" | jq -ce 'select(has("extra_usage")) | .extra_usage // {}') || exit 0
    printf '%s\n' "$credits" > "$CREDITS_CACHE.tmp" && mv "$CREDITS_CACHE.tmp" "$CREDITS_CACHE"
  ) </dev/null >/dev/null 2>&1 &
}

# "$152 left" after the card icon, skipping a cache older than a day
credits_segment() {
  [ -f "$CREDITS_CACHE" ] || return
  (( $(date +%s) - $(stat -f %m "$CREDITS_CACHE") > 86400 )) && return
  jq -r '
    select(.is_enabled == true and (.monthly_limit // 0) > 0)
    | (pow(10; .decimal_places // 2)) as $d
    | ((.monthly_limit - (.used_credits // 0)) / $d) as $left
    | "\(if $left < 0 then 0 else $left end | round) \(.currency // "USD") \(100 - (.utilization // 0) | round)"
  ' "$CREDITS_CACHE" 2>/dev/null | {
    read -r left cur pct || return
    if [ "$cur" = USD ]; then cur='$'; else cur="$cur "; fi
    (( pct < 0 )) && pct=0
    printf '%s %s%s%s left%s' "$I_SPEND" "$(color_left "$pct")" "$cur" "$left" "$RESET"
  }
}

if [ -z "$H5" ] && [ -z "$D7" ]; then
  refresh_credits
  C=$(credits_segment)
  [ -n "$C" ] && add ACCOUNT "$C"
fi

# session cost, only without 5h/weekly limits (API billing): a subscription
# never shows it, and hiding $0 skips the moment before the first reply when
# a subscription's limits haven't arrived yet. It is Claude Code's estimate at
# list price, hence the ~
if [ -z "$H5" ] && [ -z "$D7" ] && [ "$COST" != "0" ]; then
  add SESSION "$I_COST ${DIM}~${RESET}\$$(printf '%.2f' "$COST") ${DIM}session${RESET}"
fi

# counting characters without colour codes, in perl since bash may count bytes
width() {
  printf '%s' "$1" | perl -CS -ne 's/\e\[[0-9;]*m//g; print length'
}

S="$WHERE$SEP$WHO$SEP$SESSION"
if [ -z "$ACCOUNT" ]; then
  echo "$S"
# leaving 4 columns for the padding Claude Code puts around the status line
elif (( $(width "$S$SEP$ACCOUNT") <= ${COLUMNS:-80} - 4 )); then
  echo "$S$SEP$ACCOUNT"
else
  echo "$S"
  echo "$ACCOUNT"
fi
