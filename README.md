# omarchy-sway-layer

Want to use your i3/Sway muscle memory on Omarchy? This project adds H/J/K/L and arrow-key bindings to Hyprland. It mainly targets Omarchy's Lua bindings. A plain Hyprland config is included for setups without the Lua engine.

This is a Hyprland setup, not a native Sway config. The repository is dedicated to the public domain under [CC0 1.0 Universal](LICENSE).

## Install

Preview the changes, then install:

```sh
./bin/apply-sway-layer --dry-run
./bin/apply-sway-layer
```

The installer backs up affected files under `~/.config/omarchy-sway-backup/`. In Lua mode, it adds `sway_bindings.lua` and a require line to `~/.config/hypr/bindings.lua`. Without the Lua engine, it sources `binds_sway.conf` from your Hyprland config.

Waybar is optional. To use the included config, install with:

```sh
./bin/apply-sway-layer --enable-waybar
```

The default install leaves your bar unchanged. If you enable Waybar, check that your existing setup does not start another bar.

A themed launcher is optional too. To install a centered, theme-aware bemenu wrapper:

```sh
./bin/apply-sway-layer --enable-bemenu-themed
```

This installs `bemenu-themed` to your user bin dir (`${XDG_BIN_HOME:-$HOME/.local/bin}`), repoints `SUPER+D` at it, and is removed by `--uninstall`. The wrapper reads the live Omarchy palette on every invocation, so it follows theme changes with no hook. The default install leaves `SUPER+D` on `bemenu-run`.

## Keybindings

`SUPER` is the modifier. `SUPER+D` runs `bemenu-run` by default; install bemenu to use it. The `--enable-bemenu-themed` install repoints it at the `bemenu-themed` wrapper.

| Keys | Action |
| --- | --- |
| `SUPER + h/j/k/l` or arrows | Focus left/down/up/right |
| `SUPER + SHIFT + h/j/k/l` or arrows | Move directionally; Lua mode handles group join/leave |
| `SUPER + b` / `SUPER + v` | Toggle split layout. Lua mode uses Omarchy's generic toggle |
| `SUPER + e` | Toggle split layout |
| `SUPER + 1` … `9`, `0` | Switch to workspaces 1–10 |
| `SUPER + SHIFT + 1` … `9`, `0` | Move window to workspaces 1–10 |
| `SUPER + w` | Toggle the focused window's group (Lua mode) |
| `SUPER + SHIFT + q` | Close window (Lua mode) |
| `SUPER + SHIFT + Space` | Toggle floating |
| `SUPER + f` | Toggle fullscreen |
| `SUPER + SHIFT + -` / `SUPER + -` | Send to / toggle the special scratchpad workspace |
| `SUPER + r`, then H/J/K/L or arrows | Resize in 20-pixel steps |
| `Return` or `Escape` | Exit resize mode |

In Lua mode, directional movement can join an adjacent group or move a window out of its group. For a pair of exactly two visible, mapped, ungrouped, non-floating tiled windows with clear geometry, moving across the split direction changes the layout and puts the focused window on the requested side. It does not swap the windows. Other layouts keep their existing movement behavior. `SUPER+g` and `SUPER+ALT+arrows` remain available for Omarchy groups.

Hyprland groups work differently from Sway's stacking.

## Uninstall, rollback, and tests

```sh
./bin/apply-sway-layer --uninstall
./bin/apply-sway-layer --rollback latest
make test
```

`make test` checks the shell scripts, JSON, Lua, installer, and bindings. The installer does not change Omarchy files under `/usr/share/omarchy` or `~/.local/share/omarchy`. Run `./bin/apply-sway-layer --help` for all options.
