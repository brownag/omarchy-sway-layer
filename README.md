# omarchy-sway-layer

This repository is dedicated to the public domain under [CC0 1.0 Universal](LICENSE).

`omarchy-sway-layer` installs a managed set of Sway/i3-inspired keybindings and compact Waybar configuration artifacts for Hyprland, with integration paths for Omarchy's plain-config and Lua-based configuration layouts. The bindings translate familiar workflows to Hyprland dispatchers; they are not a Sway compositor configuration.

The installer does not modify Omarchy's upstream system files in `/usr/share/omarchy` or `~/.local/share/omarchy`. It integrates through user configuration and writes managed files under the user's config directory.

## Repository layout

- `bin/apply-sway-layer` — install, dry-run, uninstall, and backup rollback CLI.
- `config/hypr/` — plain Hyprland bindings and a Lua binding table.
- `config/waybar/` — dense Waybar JSONC configuration and CSS.
- `config/quickshell/` — intentionally minimal fallback override artifact.
- `scripts/` — Omarchy/config detection and timestamped backup helper.
- `Makefile` — local static validation plus install/uninstall shortcuts.

## Prerequisites

For developer validation, use Bash, GNU Make, ShellCheck, `jq`, and Lua's `luac` compiler. `make test` requires `shellcheck`, `jq`, and `luac`; it checks shell syntax/lint, JSON validity, Lua syntax, and selected static configuration strings. It does not run an Omarchy integration test. The `SUPER+D` command runner requires `bemenu-run` (provided by bemenu) on the target system.

Deployment is intended for a user session running Omarchy on Hyprland. The installer does not require root. Waybar is needed only if opting into the Waybar startup line. A machine running Ubuntu Sway or another non-Omarchy environment can inspect the repository and run its static tests; this does not make the Hyprland/Omarchy layer a native Sway configuration or verify target-machine behavior.

## Local validation

From the repository root, run:

```sh
make test
```

The Makefile also provides `make install` and `make uninstall` for invoking the CLI, but do not use those against a real user configuration when you only intend to validate the source tree. On Ubuntu Sway or another non-Omarchy machine, use `make test` for source validation; deployment and live behavior require the intended Hyprland/Omarchy target. The Task 3.1.1 live check verified four Lua-dispatch pair-reorientation cases on Hyprland 0.56.2 using disposable windows, but did not deploy or reload this project's bindings. Plain-mode dispatch, same-axis/non-pair live behavior, and resize mode were not live-tested.

## Deploy on Omarchy

Review the preview first, then install:

```sh
./bin/apply-sway-layer --dry-run
./bin/apply-sway-layer
```

A normal install creates a timestamped snapshot below `~/.config/omarchy-sway-backup/` before changing files. It copies the managed binding, Waybar, and Quickshell artifacts beneath `~/.config/`. For plain Hyprland configuration, it adds `source = ~/.config/hypr/binds_sway.conf` to `~/.config/hypr/user_custom.conf` when that file exists; otherwise it adds the line to `~/.config/hypr/hyprland.conf`. It appends the integration line rather than replacing the existing configuration.

When the Omarchy Lua engine files are detected, the installer writes `~/.config/hypr/sway_bindings.lua` and adds `pcall(require, "sway_bindings")` to `~/.config/hypr/bindings.lua` (creating that file if only `looknfeel.lua` is present). The module registers bindings through Omarchy's `o.bind` and `hl.dsp` APIs. Both integrations provide H/J/K/L and arrow aliases for directional focus, movement, and resizing, plus a `SUPER + r` modal resize mode with 20-pixel steps and Return/Escape exits. Lua mode uses Hyprland Lua's `hl.define_submap` / `hl.dsp.submap` API for resize mode. Group-aware movement and close behavior described below applies only to Omarchy Lua mode. Directional cross-axis pair reorientation is implemented in both integrations; it is a conservative behavior for clear two-window pairs, not general layout rearrangement.

### Bar selection

The default install leaves the existing bar selection unchanged. To add the managed Waybar startup line explicitly:

```sh
./bin/apply-sway-layer --enable-waybar
```

This adds `exec-once = waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css` to the selected user Hyprland config. It does not disable Quickshell. Review your existing bar startup configuration if you opt in, to avoid starting two bars.

### Dry-run, uninstall, and rollback

- `-n` or `--dry-run` previews intended changes without creating a backup or writing files. The install preview requires an existing Hyprland config or detected Lua engine.
- `--uninstall` removes the installer's managed files and exact managed integration lines; unrelated configuration content is retained.
- `--rollback latest` restores the newest timestamped snapshot. Use `--rollback TIMESTAMP` to restore a particular backup directory (for example, `20261013-123456`). Rollback restores or removes the saved Hyprland, Waybar, and Quickshell config directories according to the snapshot manifest, so it can affect other changes made in those directories since that snapshot.
- `-h` or `--help` prints usage.

Examples:

```sh
./bin/apply-sway-layer --uninstall
./bin/apply-sway-layer --rollback latest
./bin/apply-sway-layer --rollback 20261013-123456
```

## Verification

The repository's automated checks are static and do not prove runtime integration. On the target, inspect the CLI help and expected installed artifacts/integration lines:

```sh
./bin/apply-sway-layer --help
test -s ~/.config/hypr/binds_sway.conf
test -s ~/.config/waybar/sway-dense.jsonc
grep -F 'source = ~/.config/hypr/binds_sway.conf' ~/.config/hypr/user_custom.conf ~/.config/hypr/hyprland.conf 2>/dev/null
grep -F 'exec-once = waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css' ~/.config/hypr/user_custom.conf ~/.config/hypr/hyprland.conf 2>/dev/null
```

The source line is expected for plain-config integration; the Waybar line is expected only after `--enable-waybar`. For Lua integration, inspect `~/.config/hypr/bindings.lua` for `pcall(require, "sway_bindings")` and `~/.config/hypr/sway_bindings.lua` for Omarchy API registrations. These checks confirm file contents only, not that a live session loads or behaves as intended.

## Keybindings

Bindings use `SUPER` as the modifier. `SUPER + D` opens the bemenu command runner for arbitrary executables on `PATH`; this is separate from Omarchy's `SUPER + Space` application menu. Install bemenu so `bemenu-run` is available in the Hyprland session's `PATH`. `SUPER + 0` selects workspace 10; shifted number bindings move the active window to the corresponding workspace.

| Keys | Action |
| --- | --- |
| `SUPER + d` | Open `bemenu-run` to launch an executable by name |
| `SUPER + h/j/k/l` or `SUPER + LEFT/DOWN/UP/RIGHT` | Focus left/down/up/right |
| `SUPER + SHIFT + h/j/k/l` or `SUPER + SHIFT + arrows` | Move in that direction. Plain config uses native movement except for qualifying cross-axis pairs; Omarchy Lua mode uses contextual movement/group actions (see below) |
| `SUPER + b` / `SUPER + v` | Manual split toggle. Plain config requests horizontal / vertical; Lua mode maps both to Omarchy's generic `togglesplit` |
| `SUPER + e` | Send the `togglesplit` layout message |
| `SUPER + 1` … `9`, `SUPER + 0` | Switch to workspaces 1 … 10 |
| `SUPER + SHIFT + 1` … `9`, `SUPER + SHIFT + 0` | Move the active window to workspaces 1 … 10 |
| `SUPER + q` | Plain Hyprland config close binding |
| `SUPER+SHIFT+q` | Omarchy Lua mode's only managed close chord |
| `SUPER+w` | Omarchy Lua mode: toggle the focused window's group |
| `SUPER+g`, `SUPER+ALT+arrows` | Existing Omarchy group aliases remain available |
| `SUPER + SHIFT + Space` | Toggle floating |
| `SUPER + f` | Toggle fullscreen |
| `SUPER + SHIFT + -` | Move the active window to the special scratchpad workspace |
| `SUPER + -` | Toggle the special scratchpad workspace |
| `SUPER+r`, then `h/j/k/l` or arrows | Enter resize mode in either integration and resize in 20-pixel steps |
| `Return` or `Escape` while resizing | Exit resize mode in either integration |

### Omarchy Lua mode: groups and directional actions

In both integrations, cross-axis movement on a clear two-window tiled pair reorients the pair and places the focused window on the requested side; this is placement, not a swap (down below, up above, right to the right, left to the left). The helper only treats a pair as clear when there are exactly two visible, mapped, ungrouped, non-floating tiled clients with unambiguous axis-aligned geometry. Same-axis moves and ambiguous or larger arrangements retain their existing mode-specific behavior; this is not general layout rearrangement.

In Omarchy Lua mode, `SUPER+SHIFT+h/j/k/l` and `SUPER+SHIFT+arrows` remain context-aware. Outside the pair-reorientation case, when neither the focused window nor its directional neighbor is grouped, the action moves or swaps the focused window in that direction. When the neighbor is grouped, it joins that adjacent group. When the focused window is grouped, it moves out of its group in the requested direction. `SUPER+w` toggles the focused window's group; `SUPER+SHIFT+q` is the only close chord managed by this Lua integration. Existing Omarchy aliases `SUPER+g` and `SUPER+ALT+arrows` remain available. Hyprland groups approximate, but do not reproduce, Sway stacking.

Live verification was limited to the four Lua-dispatch cross-axis pair transformations on Hyprland 0.56.2 using disposable windows. The project bindings were not deployed or reloaded for that test. Plain-mode dispatch, same-axis/non-pair behavior, and resize mode have not been live-tested; automated regression coverage does not establish runtime behavior.

## Native Sway/i3 vs Hyprland

Hyprland does not implement Sway's container tree and layout model identically. These bindings map familiar actions to Hyprland dispatchers (`movefocus`, `movewindow`, `togglesplit`, `layoutmsg`, and special-workspace actions), providing best-effort equivalents rather than guaranteeing identical Sway/i3 split, focus, or container semantics. The resize modes and workspace/window actions are likewise Hyprland bindings, not a native Sway configuration. Plain `SUPER+b`/`SUPER+v` request horizontal/vertical split toggles; Lua mode maps both keys to Omarchy's generic `togglesplit` dispatcher. Lua resize mode uses the Hyprland Lua submap API. Adjust the user configuration to suit the target's actual Hyprland version and Omarchy setup.
