#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat >"$tmp/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"$CALL_LOG"
case "$*" in
  '-j activewindow') cat "$ACTIVE_JSON" ;;
  '-j clients')
    [[ ${CLIENTS_FAIL:-0} == 0 ]] || exit 1
    cat "$CLIENTS_JSON"
    ;;
  *) [[ ${DISPATCH_FAIL:-0} == 0 ]] ;;
esac
MOCK
chmod +x "$tmp/bin/hyprctl"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["B","C"]},
 {"address":"C","at":[300,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
]
JSON
export PATH="$tmp/bin:$PATH" CALL_LOG="$tmp/log" ACTIVE_JSON="$tmp/active.json" CLIENTS_JSON="$tmp/clients.json" CLIENTS_FAIL=0 DISPATCH_FAIL=0
run() { : >"$CALL_LOG"; "$root/scripts/sway-group-move" "$@"; }
run l
grep -Fqx 'dispatch hl.dsp.window.move({ into_group = "l" })' "$CALL_LOG"
if grep -Eq 'dispatch focus|focuswindow' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},{"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}]
JSON
run l
grep -Fqx 'dispatch hl.dsp.window.swap({ direction = "l" })' "$CALL_LOG"
cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}]
JSON
run l
if grep -q 'dispatch ' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":["A","B"]}
JSON
run l
grep -Fqx 'dispatch hl.dsp.window.move({ out_of_group = true })' "$CALL_LOG"
grep -Fqx 'dispatch hl.dsp.window.move({ direction = "left" })' "$CALL_LOG"
run r
grep -Fqx 'dispatch hl.dsp.window.move({ out_of_group = true })' "$CALL_LOG"
[[ $(grep -c '^dispatch ' "$CALL_LOG") == 1 ]]
run u
grep -Fqx 'dispatch hl.dsp.window.move({ out_of_group = true })' "$CALL_LOG"
grep -Fqx 'dispatch hl.dsp.window.move({ direction = "up" })' "$CALL_LOG"
run d
grep -Fqx 'dispatch hl.dsp.window.move({ out_of_group = true })' "$CALL_LOG"
grep -Fqx 'dispatch hl.dsp.window.move({ direction = "down" })' "$CALL_LOG"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
CLIENTS_FAIL=1 run r
grep -Fqx 'dispatch hl.dsp.window.swap({ direction = "r" })' "$CALL_LOG"
DISPATCH_FAIL=1
CLIENTS_FAIL=1
if run r 2>/dev/null; then exit 1; fi
DISPATCH_FAIL=0
CLIENTS_FAIL=0

# In a quadrant layout, prefer an aligned group over a diagonal ordinary window.
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[100,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["B","B2"]},
 {"address":"C","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"D","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
]
JSON
run u
grep -Fqx 'dispatch hl.dsp.window.move({ into_group = "u" })' "$CALL_LOG"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["B","B2"]},
 {"address":"C","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"D","at":[100,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
]
JSON
run l
grep -Fqx 'dispatch hl.dsp.window.move({ into_group = "l" })' "$CALL_LOG"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["B","B2"]},
 {"address":"C","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"D","at":[100,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
]
JSON
run d
grep -Fqx 'dispatch hl.dsp.window.move({ into_group = "d" })' "$CALL_LOG"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[100,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["B","B2"]},
 {"address":"C","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"D","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
]
JSON
run r
grep -Fqx 'dispatch hl.dsp.window.move({ into_group = "r" })' "$CALL_LOG"

# An intervening ungrouped neighbor wins over a more distant group.
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[300,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[300,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"B","at":[200,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},
 {"address":"G","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":["G","G2"]}
]
JSON
run l
grep -Fqx 'dispatch hl.dsp.window.swap({ direction = "l" })' "$CALL_LOG"
printf 'test-sway-group-move: passed\n'
