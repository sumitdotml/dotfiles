#!/bin/bash
# Claude Code status line (fields: https://code.claude.com/docs/en/statusline)
input=$(cat)

# resolving the symlink so ~/.claude/statusline.sh finds the shared library in the repo
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../agents/statusline-lib.sh"

# credit card draws wider than one cell, so it carries a second space
I_SPEND=" "; I_FAST=""; I_COST="󰑉"

# reading every field in one jq pass; percentages arrive as floats, so rounding here
eval "$(jq -r "$JQ_FMT"'
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
    @sh "COST=\(.cost.total_cost_usd // 0 | . * 100 | round / 100)",
    @sh "VERSION=\(.version // "")"
' <<<"$input")"

WHO_EXTRA=""
[ "$FAST" = "true" ] && WHO_EXTRA="$I_FAST fast"

# spend dollars arrive minutes after the percentage, so adding them once both are in
SP_EXTRA=""
[ -n "$SP_USD" ] && [ -n "$SP_LIM" ] && SP_EXTRA="\$${SP_USD}/\$${SP_LIM}${SP_PERIOD:+ $SP_PERIOD}"
ACCOUNT_EXTRA=$(limit "$I_SPEND" spend "$SP" "$SP_AT" "$SP_EXTRA")

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
  [ -n "$C" ] && add ACCOUNT_EXTRA "$C"
fi

# session cost, only without 5h/weekly limits (API billing): a subscription
# never shows it, and hiding $0 skips the moment before the first reply when
# a subscription's limits haven't arrived yet. It is Claude Code's estimate at
# list price, hence the ~
SESSION_EXTRA=""
if [ -z "$H5" ] && [ -z "$D7" ] && [ "$COST" != "0" ]; then
  SESSION_EXTRA="$I_COST ${DIM}~${RESET}\$$(printf '%.2f' "$COST") ${DIM}session${RESET}"
fi

render_statusline
