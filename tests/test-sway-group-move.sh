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
swap_pair() {
  local active_address temp
  active_address=$(jq -r '.address' "$ACTIVE_JSON")
  temp=$(mktemp "$TMP_DIR/clients.XXXXXX")
  jq --arg active "$active_address" '
    . as $clients |
    ($clients[] | select(.address == $active)) as $a |
    ($clients[] | select(.address != $active)) as $b |
    map(if .address == $active then .at = $b.at | .size = $b.size
        else .at = $a.at | .size = $a.size end)
  ' "$CLIENTS_JSON" >"$temp"
  mv "$temp" "$CLIENTS_JSON"
}
toggle_pair() {
  local temp
  temp=$(mktemp "$TMP_DIR/clients.XXXXXX")
  jq '
    def x_pair($a; $b):
      (($a.at[0] + $a.size[0] <= $b.at[0]) or ($b.at[0] + $b.size[0] <= $a.at[0])) and
      ([ $a.at[1], $b.at[1] ] | max) < ([ $a.at[1] + $a.size[1], $b.at[1] + $b.size[1] ] | min);
    . as $clients |
    ($clients[0]) as $a | ($clients[1]) as $b |
    if x_pair($a; $b) then
      ($clients | sort_by(.at[0])) as $ordered |
      [($ordered[0] + {at: [12,55], size: [1342,344]}),
       ($ordered[1] + {at: [12,413], size: [1342,343]})]
    else
      ($clients | sort_by(.at[1])) as $ordered |
      [($ordered[0] + {at: [12,55], size: [664,701]}),
       ($ordered[1] + {at: [690,55], size: [664,701]})]
    end
  ' "$CLIENTS_JSON" >"$temp"
  mv "$temp" "$CLIENTS_JSON"
}
case "$*" in
  '-j activewindow')
    [[ ${ACTIVE_FAIL:-0} == 0 ]] || exit 1
    cat "$ACTIVE_JSON"
    ;;
  '-j clients')
    [[ ${CLIENTS_FAIL:-0} == 0 ]] || exit 1
    cat "$CLIENTS_JSON"
    ;;
  'dispatch hl.dsp.layout("togglesplit")'|'dispatch layoutmsg togglesplit')
    [[ ${DISPATCH_FAIL:-0} == 0 ]] || exit 1
    if [[ ${PAIR_TEST:-0} == 1 ]]; then toggle_pair; fi
    ;;
  dispatch\ hl.dsp.window.swap*|dispatch\ swapwindow\ *)
    [[ ${DISPATCH_FAIL:-0} == 0 ]] || exit 1
    if [[ ${PAIR_TEST:-0} == 1 ]]; then swap_pair; fi
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
export PATH="$tmp/bin:$PATH" CALL_LOG="$tmp/log" ACTIVE_JSON="$tmp/active.json" CLIENTS_JSON="$tmp/clients.json" TMP_DIR="$tmp" ACTIVE_FAIL=0 CLIENTS_FAIL=0 DISPATCH_FAIL=0 PAIR_TEST=0
run() {
    : >"$CALL_LOG"
    if ! "$root/scripts/sway-group-move" lua "$@"; then
        printf 'Lua helper failed for direction %s; dispatch log:\n' "$1" >&2
        cat "$CALL_LOG" >&2
        return 1
    fi
}
run_plain() {
    : >"$CALL_LOG"
    if ! "$root/scripts/sway-group-move" plain "$@"; then
        printf 'Plain helper failed for direction %s; dispatch log:\n' "$1" >&2
        cat "$CALL_LOG" >&2
        return 1
    fi
}

# Existing Lua grouping and ordinary behavior remains unchanged outside a clear pair.
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
CLIENTS_FAIL=1 run_plain u
grep -Fqx 'dispatch movewindow u' "$CALL_LOG"
ACTIVE_FAIL=1 run_plain d
grep -Fqx 'dispatch movewindow d' "$CALL_LOG"
DISPATCH_FAIL=1 CLIENTS_FAIL=1
if run r 2>/dev/null; then exit 1; fi
DISPATCH_FAIL=0 CLIENTS_FAIL=0

# Retain aligned-group preference and nearest ordinary-neighbor selection.
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
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
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
{"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
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
{"address":"A","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
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
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[300,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"grouped":[]}
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

pair_fixture() {
    local axis=$1 active_position=$2
    if [[ $axis == x ]]; then
        if [[ $active_position == first ]]; then
            cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[12,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
JSON
            cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[12,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},{"address":"B","at":[690,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}]
JSON
        else
            cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[690,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
JSON
            cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[690,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},{"address":"B","at":[12,55],"size":[664,701],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}]
JSON
        fi
    elif [[ $active_position == first ]]; then
        cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[12,55],"size":[1342,344],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
JSON
        cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[12,55],"size":[1342,344],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},{"address":"B","at":[12,413],"size":[1342,343],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}]
JSON
    else
        cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[12,413],"size":[1342,343],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
JSON
        cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[12,413],"size":[1342,343],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},{"address":"B","at":[12,55],"size":[1342,344],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}]
JSON
    fi
}
assert_pair_result() {
    local direction=$1 expected_axis=$2 axis side
    axis=$(jq -er '
      . as $c | ($c[0]) as $a | ($c[1]) as $b |
      if (($a.at[0]+$a.size[0] <= $b.at[0] or $b.at[0]+$b.size[0] <= $a.at[0]) and ([ $a.at[1],$b.at[1] ]|max)<([ $a.at[1]+$a.size[1],$b.at[1]+$b.size[1] ]|min)) then "x"
      elif (($a.at[1]+$a.size[1] <= $b.at[1] or $b.at[1]+$b.size[1] <= $a.at[1]) and ([ $a.at[0],$b.at[0] ]|max)<([ $a.at[0]+$a.size[0],$b.at[0]+$b.size[0] ]|min)) then "y"
      else "ambiguous" end' "$CLIENTS_JSON")
    [[ $axis == "$expected_axis" ]]
    side=$(jq -r --arg d "$direction" '
      . as $c | ($c[]|select(.address=="A")) as $a | ($c[]|select(.address=="B")) as $b |
      if $d=="l" then (($a.at[0]+$a.size[0]/2)<($b.at[0]+$b.size[0]/2))
      elif $d=="r" then (($a.at[0]+$a.size[0]/2)>($b.at[0]+$b.size[0]/2))
      elif $d=="u" then (($a.at[1]+$a.size[1]/2)<($b.at[1]+$b.size[1]/2))
      else (($a.at[1]+$a.size[1]/2)>($b.at[1]+$b.size[1]/2)) end' "$CLIENTS_JSON")
    [[ $side == true && $(jq -r '.address' "$ACTIVE_JSON") == A ]]
}
run_pair_case() {
    local mode=$1 direction=$2 axis=$3 position=$4 expected_axis expected_dispatch
    pair_fixture "$axis" "$position"
    PAIR_TEST=1
    if [[ $mode == lua ]]; then
        expected_dispatch='dispatch hl.dsp.layout("togglesplit")'
    else
        expected_dispatch='dispatch layoutmsg togglesplit'
    fi
    if [[ $direction == l || $direction == r ]]; then expected_axis=x; else expected_axis=y; fi
    : >"$CALL_LOG"
    "$root/scripts/sway-group-move" "$mode" "$direction"
    grep -Fqx "$expected_dispatch" "$CALL_LOG"
    if [[ $mode == lua ]]; then
        grep -Fqx "dispatch hl.dsp.window.swap({ direction = \"$direction\" })" "$CALL_LOG"
    else
        grep -Fqx "dispatch swapwindow $direction" "$CALL_LOG"
    fi
    [[ $(grep -c '^dispatch ' "$CALL_LOG") == 2 ]]
    assert_pair_result "$direction" "$expected_axis"
}

# Verify both modes, both starting split orientations, and all cross-axis directions.
run_pair_case lua u x second
run_pair_case lua d x first
run_pair_case lua l y second
run_pair_case lua r y first
run_pair_case plain u x second
run_pair_case plain d x first
run_pair_case plain l y second
run_pair_case plain r y first

# Same-axis moves and ambiguous/multi-window workspaces retain their mode-specific fallback.
pair_fixture x first
PAIR_TEST=0
run r
grep -Fqx 'dispatch hl.dsp.window.swap({ direction = "r" })' "$CALL_LOG"
if grep -q 'togglesplit\|layoutmsg' "$CALL_LOG"; then exit 1; fi
run_plain r
grep -Fqx 'dispatch movewindow r' "$CALL_LOG"
if grep -q 'togglesplit\|swapwindow' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/active.json" <<'JSON'
{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
JSON
cat >"$tmp/clients.json" <<'JSON'
[{"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},{"address":"B","at":[0,0],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}]
JSON
run l
grep -Fqx 'dispatch hl.dsp.window.swap({ direction = "l" })' "$CALL_LOG"
if grep -q 'togglesplit' "$CALL_LOG"; then exit 1; fi
run_plain l
grep -Fqx 'dispatch movewindow l' "$CALL_LOG"
if grep -q 'togglesplit\|swapwindow' "$CALL_LOG"; then exit 1; fi
cat >"$tmp/clients.json" <<'JSON'
[
 {"address":"A","at":[100,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},
 {"address":"B","at":[0,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]},
 {"address":"C","at":[300,100],"size":[100,100],"workspace":{"id":1},"mapped":true,"floating":false,"hidden":false,"grouped":[]}
]
JSON
run d
if grep -q 'togglesplit' "$CALL_LOG"; then exit 1; fi
run_plain d
grep -Fqx 'dispatch movewindow d' "$CALL_LOG"
if grep -q 'togglesplit\|swapwindow' "$CALL_LOG"; then exit 1; fi

# A floating client is not part of the clear tiled pair predicate.
pair_fixture x first
jq '.[1].floating = true' "$CLIENTS_JSON" >"$tmp/clients.json.new"
mv "$tmp/clients.json.new" "$CLIENTS_JSON"
run u
if grep -q 'togglesplit' "$CALL_LOG"; then exit 1; fi
run_plain u
grep -Fqx 'dispatch movewindow u' "$CALL_LOG"
if grep -q 'togglesplit\|swapwindow' "$CALL_LOG"; then exit 1; fi
printf 'test-sway-group-move: passed\n'
