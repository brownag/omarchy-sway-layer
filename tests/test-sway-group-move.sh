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
export PATH="$tmp/bin:$PATH" CALL_LOG="$tmp/log" ACTIVE_JSON="$tmp/active.json" CLIENTS_JSON="$tmp/clients.json"
run() { : >"$CALL_LOG"; "$root/scripts/sway-group-move" "$@"; }
run l
grep -Fqx 'dispatch moveintogroup l' "$CALL_LOG"
if grep -Eq 'dispatch focus|focuswindow' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]},{"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}]
JSON
run l
grep -Fqx 'dispatch swapwindow l' "$CALL_LOG"
cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}]
JSON
run l
if grep -q 'dispatch ' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":["A","B"]}
JSON
run r
grep -Fqx 'dispatch moveoutofgroup r' "$CALL_LOG"
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"grouped":[]}
JSON
CLIENTS_FAIL=1 run r
grep -Fqx 'dispatch swapwindow r' "$CALL_LOG"
DISPATCH_FAIL=1 run r
printf 'test-sway-group-move: passed\n'
