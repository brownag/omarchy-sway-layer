#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"${HOME:?HOME must be set}/.config"}
bin_home=${XDG_BIN_HOME:-"${HOME:?HOME must be set}/.local/bin"}
backup_root=${OMARCHY_SWAY_BACKUP_ROOT:-"$config_home/omarchy-sway-backup"}
timestamp=$(date '+%Y%m%d-%H%M%S')
backup_dir="$backup_root/$timestamp"
suffix=0
mkdir -p -- "$backup_root"
while [[ -e $backup_dir ]]; do
    suffix=$((suffix + 1))
    backup_dir="$backup_root/$timestamp-$suffix"
done
mkdir -- "$backup_dir"

hypr_source="$config_home/hypr"
waybar_source="$config_home/waybar"
quickshell_source="$config_home/quickshell"
bemenu_source="$bin_home/bemenu-themed"

copy_if_present() {
    local source=$1
    local destination=$2
    local presence_variable=$3
    if [[ -e $source || -L $source ]]; then
        cp -a -- "$source" "$destination"
        printf -v "$presence_variable" '1'
    else
        printf -v "$presence_variable" '0'
    fi
}

hypr_present=0
waybar_present=0
quickshell_present=0
bemenu_present=0

copy_if_present "$hypr_source" "$backup_dir/hypr" hypr_present
copy_if_present "$waybar_source" "$backup_dir/waybar" waybar_present
copy_if_present "$quickshell_source" "$backup_dir/quickshell" quickshell_present
copy_if_present "$bemenu_source" "$backup_dir/bemenu-themed" bemenu_present

write_manifest() {
    local manifest="$backup_dir/manifest.txt"
    {
        printf 'TIMESTAMP=%s\n' "${backup_dir##*/}"
        printf 'HYPR_PRESENT=%s\n' "$hypr_present"
        printf 'HYPR_SOURCE=%s\n' "$hypr_source"
        printf 'WAYBAR_PRESENT=%s\n' "$waybar_present"
        printf 'WAYBAR_SOURCE=%s\n' "$waybar_source"
        printf 'QUICKSHELL_PRESENT=%s\n' "$quickshell_present"
        printf 'QUICKSHELL_SOURCE=%s\n' "$quickshell_source"
        printf 'BEMENU_PRESENT=%s\n' "$bemenu_present"
        printf 'BEMENU_SOURCE=%s\n' "$bemenu_source"
    } >"$manifest"
}

write_manifest
printf '%s\n' "$backup_dir"
