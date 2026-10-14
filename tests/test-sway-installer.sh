#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_CONFIG_HOME="$tmp/config"
export HOME="$tmp/home"
mkdir -p "$XDG_CONFIG_HOME/hypr"
printf '# isolated Lua fixture\n' >"$XDG_CONFIG_HOME/hypr/bindings.lua"
before=$(find "$XDG_CONFIG_HOME" -type f -printf '%P\n' | sort)
bash "$root/bin/apply-sway-layer" --dry-run >/dev/null
after=$(find "$XDG_CONFIG_HOME" -type f -printf '%P\n' | sort)
[[ $before == "$after" ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/sway-group-move ]]
bash "$root/bin/apply-sway-layer" >/dev/null
cmp -s "$root/scripts/sway-group-move" "$XDG_CONFIG_HOME/hypr/sway-group-move"
[[ -x $XDG_CONFIG_HOME/hypr/sway-group-move ]]
bash "$root/bin/apply-sway-layer" --uninstall >/dev/null
[[ ! -e $XDG_CONFIG_HOME/hypr/sway-group-move ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/sway_bindings.lua ]]
[[ -f $XDG_CONFIG_HOME/hypr/bindings.lua ]]
printf 'test-sway-installer: passed\n'
