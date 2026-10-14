#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"${HOME:?HOME must be set}/.config"}
hypr_config="$config_home/hypr"

file_exists() {
    [[ -f $1 ]] && printf '1' || printf '0'
}

command_available() {
    command -v "$1" >/dev/null 2>&1 && printf '1' || printf '0'
}

config_contains() {
    local pattern=$1
    local root=$2
    [[ -d $root ]] && grep -R -I -q -E -- "$pattern" "$root" 2>/dev/null
}

detect_lua_engine() {
    BINDINGS_LUA=$(file_exists "$hypr_config/bindings.lua")
    LOOKNFEEL_LUA=$(file_exists "$hypr_config/looknfeel.lua")
    LUA_ENGINE=0
    if [[ $BINDINGS_LUA == 1 || $LOOKNFEEL_LUA == 1 ]]; then
        LUA_ENGINE=1
    fi
}

detect_lua_engine

HYPRLAND_CONFIG=$(file_exists "$hypr_config/hyprland.conf")
USER_CUSTOM_CONF=$(file_exists "$hypr_config/user_custom.conf")
QUICKSHELL_LAUNCH=0
WAYBAR_LAUNCH=0
if config_contains 'quickshell|(^|[^[:alnum:]_])qs([[:space:]]|$)' "$config_home"; then
    QUICKSHELL_LAUNCH=1
fi
if config_contains 'waybar' "$config_home"; then
    WAYBAR_LAUNCH=1
fi
HYPRCTL_AVAILABLE=$(command_available hyprctl)
WAYBAR_AVAILABLE=$(command_available waybar)
QUICKSHELL_AVAILABLE=$(command_available quickshell)

printf 'HYPRLAND_CONFIG=%s\n' "$HYPRLAND_CONFIG"
printf 'USER_CUSTOM_CONF=%s\n' "$USER_CUSTOM_CONF"
printf 'BINDINGS_LUA=%s\n' "$BINDINGS_LUA"
printf 'LOOKNFEEL_LUA=%s\n' "$LOOKNFEEL_LUA"
printf 'LUA_ENGINE=%s\n' "$LUA_ENGINE"
printf 'QUICKSHELL_LAUNCH=%s\n' "$QUICKSHELL_LAUNCH"
printf 'WAYBAR_LAUNCH=%s\n' "$WAYBAR_LAUNCH"
printf 'HYPRCTL_AVAILABLE=%s\n' "$HYPRCTL_AVAILABLE"
printf 'WAYBAR_AVAILABLE=%s\n' "$WAYBAR_AVAILABLE"
printf 'QUICKSHELL_AVAILABLE=%s\n' "$QUICKSHELL_AVAILABLE"
