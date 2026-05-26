#!/usr/bin/env bash
# Compact per-GPU display for tmux status bar.
# - Whole GPU: "G1 0%/0G"      (util% / mem-used)
# - MIG GPU:   "G0[4g+3g]"     (slice profile — aggregate util/mem are N/A under MIG)

command -v nvidia-smi >/dev/null 2>&1 || exit 0

# Build MIG slice map as "0=4g+3g;1=...;" (single line for safe -v passing)
mig_map=$(nvidia-smi -L 2>/dev/null | awk '
/^GPU [0-9]+:/ {
    match($0, /[0-9]+/); gpu = substr($0, RSTART, RLENGTH); slices[gpu] = ""
}
/^[ \t]+MIG [0-9]+g/ {
    match($0, /[0-9]+g/); s = substr($0, RSTART, RLENGTH)
    slices[gpu] = (slices[gpu] == "" ? s : slices[gpu] "+" s)
}
END {
    out = ""
    for (g in slices) if (slices[g] != "") out = out g "=" slices[g] ";"
    print out
}')

nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null \
| awk -F',' -v mig="$mig_map" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
BEGIN {
    n = split(mig, parts, ";")
    for (i = 1; i <= n; i++) {
        if (parts[i] == "") continue
        split(parts[i], kv, "=")
        m[kv[1]] = kv[2]
    }
}
{
    idx = NR - 1
    if (idx in m) {
        out = out sprintf("G%d[%s] ", idx, m[idx])
    } else {
        util = trim($1); used = trim($2) + 0
        if (util == "[N/A]" || util == "") util = "--"
        out = out sprintf("G%d %s%%/%.0fG ", idx, util, used/1024)
    }
}
END { sub(/ $/, "", out); print out }
'
