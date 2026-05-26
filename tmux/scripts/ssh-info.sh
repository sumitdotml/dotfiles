#!/usr/bin/env bash
# tmux status bar: SSH traffic rates + RTT.
# Output is empty when not in an SSH session, so callers can use the
# tmux #{?...,...,} conditional to hide the whole segment off-ssh.
#
# Up   = client -> server (your keystrokes, scp uploads).
# Down = server -> client (terminal output, scp downloads).
#
# We read counters from `ss -tin` (no root needed for user-owned sockets)
# and diff against a state file at /tmp/.tmux-ssh-info-$UID.

[ -z "${SSH_CONNECTION:-}" ] && exit 0

STATE="/tmp/.tmux-ssh-info-${UID}"
client_port=$(awk '{print $2}' <<< "$SSH_CONNECTION")

# Sum bytes_sent / bytes_received across all user-visible established ssh
# sockets. Capture RTT of the socket matching $SSH_CONNECTION's client port
# (the connection that started this tmux server); fall back to first seen.
read -r srv_sent srv_recv rtt_ms < <(
  ss -tin '( sport = :ssh or dport = :ssh )' 2>/dev/null \
  | awk -v cport="$client_port" '
    $1 == "ESTAB" {
      peer = $5; sub(/.*:/, "", peer); pport = peer
      getline detail
      match(detail, /bytes_sent:[0-9]+/);
      if (RSTART) total_sent += substr(detail, RSTART+11, RLENGTH-11) + 0
      match(detail, /bytes_received:[0-9]+/);
      if (RSTART) total_recv += substr(detail, RSTART+15, RLENGTH-15) + 0
      match(detail, /rtt:[0-9.]+/);
      if (RSTART) {
        cur = substr(detail, RSTART+4, RLENGTH-4)
        if (pport == cport || rtt == "") rtt = cur
      }
    }
    END { print total_sent+0, total_recv+0, rtt+0 }
  '
)

now_ns=$(date +%s%N)
prev_ts=$now_ns; prev_sent=$srv_sent; prev_recv=$srv_recv
if [ -r "$STATE" ]; then
  read -r prev_ts prev_sent prev_recv < "$STATE" 2>/dev/null || true
fi
printf '%s %s %s\n' "$now_ns" "$srv_sent" "$srv_recv" > "$STATE"

human() {
  awk -v b="$1" 'BEGIN {
    if (b < 1)           printf "0"
    else if (b < 1024)   printf "%dB", b
    else if (b < 1048576) printf "%.0fK", b/1024
    else if (b < 1073741824) printf "%.1fM", b/1048576
    else                  printf "%.1fG", b/1073741824
  }'
}

# user-upload = bytes the server *received*; user-download = bytes server *sent*
up_rate=$(awk -v c="$srv_recv" -v p="$prev_recv" -v t="$now_ns" -v pt="$prev_ts" \
  'BEGIN { e=(t-pt)/1e9; print (e>0.1 && c>=p) ? (c-p)/e : 0 }')
dn_rate=$(awk -v c="$srv_sent" -v p="$prev_sent" -v t="$now_ns" -v pt="$prev_ts" \
  'BEGIN { e=(t-pt)/1e9; print (e>0.1 && c>=p) ? (c-p)/e : 0 }')

rtt_fmt=""
[ -n "$rtt_ms" ] && awk -v r="$rtt_ms" 'BEGIN { exit !(r > 0) }' && \
  rtt_fmt=$(awk -v r="$rtt_ms" 'BEGIN {
    if (r < 10) printf "%.1fms", r; else printf "%.0fms", r
  }')

printf '↑%s ↓%s %s' "$(human "$up_rate")" "$(human "$dn_rate")" "$rtt_fmt"
