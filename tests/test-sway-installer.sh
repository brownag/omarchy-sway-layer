#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_CONFIG_HOME="$tmp/config"
export XDG_BIN_HOME="$tmp/bin"
export HOME="$tmp/home"
mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_BIN_HOME"
printf '# isolated Lua fixture\n' >"$XDG_CONFIG_HOME/hypr/bindings.lua"

# Dry run writes nothing, with or without the opt-in flag.
before=$(find "$XDG_CONFIG_HOME" "$XDG_BIN_HOME" -type f -printf '%P\n' | sort)
bash "$root/bin/apply-sway-layer" --dry-run >/dev/null
after=$(find "$XDG_CONFIG_HOME" "$XDG_BIN_HOME" -type f -printf '%P\n' | sort)
[[ $before == "$after" ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/sway-group-move ]]
[[ ! -e $XDG_BIN_HOME/bemenu-themed ]]

# Dry run with the opt-in flag previews the wrapper and the rewritten binding.
dry_out=$(bash "$root/bin/apply-sway-layer" --enable-bemenu-themed --dry-run 2>/dev/null)
grep -Fq "$XDG_BIN_HOME/bemenu-themed (after)" <<<"$dry_out"
grep -Fq '+bind = SUPER, d, exec, bemenu-themed' <<<"$dry_out"
[[ ! -e $XDG_BIN_HOME/bemenu-themed ]]

# Default install stays byte-for-byte: no wrapper, binding remains bemenu-run.
bash "$root/bin/apply-sway-layer" >/dev/null 2>&1
[[ ! -e $XDG_BIN_HOME/bemenu-themed ]]
grep -Fqx 'bind = SUPER, d, exec, bemenu-run' "$XDG_CONFIG_HOME/hypr/binds_sway.conf"
if grep -Fq 'bemenu-themed' "$XDG_CONFIG_HOME/hypr/sway_bindings.lua"; then exit 1; fi
cmp -s "$root/scripts/sway-group-move" "$XDG_CONFIG_HOME/hypr/sway-group-move"
[[ -x $XDG_CONFIG_HOME/hypr/sway-group-move ]]

# Uninstall removes the managed files.
bash "$root/bin/apply-sway-layer" --uninstall >/dev/null
[[ ! -e $XDG_CONFIG_HOME/hypr/sway-group-move ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/sway_bindings.lua ]]
[[ -f $XDG_CONFIG_HOME/hypr/bindings.lua ]]

# Opt-in install: wrapper lands on PATH dir and both copied bindings are repointed.
warn_err=$(bash "$root/bin/apply-sway-layer" --enable-bemenu-themed 2>&1 >/dev/null)
[[ -x $XDG_BIN_HOME/bemenu-themed ]]
cmp -s "$root/scripts/bemenu-themed" "$XDG_BIN_HOME/bemenu-themed"
grep -Fqx 'bind = SUPER, d, exec, bemenu-themed' "$XDG_CONFIG_HOME/hypr/binds_sway.conf"
if grep -Fq 'bemenu-run' "$XDG_CONFIG_HOME/hypr/binds_sway.conf"; then exit 1; fi
grep -Fq 'bemenu-themed' "$XDG_CONFIG_HOME/hypr/sway_bindings.lua"
if grep -Fq 'bemenu-run' "$XDG_CONFIG_HOME/hypr/sway_bindings.lua"; then exit 1; fi
grep -Fq 'is not in PATH' <<<"$warn_err"

# Repo sources are never rewritten.
grep -Fqx 'bind = SUPER, d, exec, bemenu-run' "$root/config/hypr/binds_sway.conf"
grep -Fq 'bemenu-run' "$root/config/hypr/binds_sway.lua"

# Uninstall removes the installed wrapper.
bash "$root/bin/apply-sway-layer" --uninstall >/dev/null
[[ ! -e $XDG_BIN_HOME/bemenu-themed ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/binds_sway.conf ]]

printf 'test-sway-installer: passed\n'
