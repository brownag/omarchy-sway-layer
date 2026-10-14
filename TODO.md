# TODO

## Goal
Make the Sway-style bindings actually register when Omarchy loads the Lua configuration, while preserving the existing plain-Hyprland config path.

## Tasks

### 1. Register Lua bindings through Omarchy
- [x] Replace the inert returned table in `config/hypr/binds_sway.lua` with registrations using the installed Omarchy `o.bind` / `hl.dsp` API, following `/usr/share/omarchy/default/hypr/helpers.lua` and `bindings/tiling.lua`.
- [x] Register and, where needed, unbind the specified focus, move, split/layout, workspace, close, float/fullscreen, and scratchpad bindings; use Ctrl+Super resize chords in Lua mode because the local API has no documented submap option, and document that limitation.
- [x] Keep the plain `binds_sway.conf` path unchanged.

### 2. Validate the Lua integration
- [x] Run `luac -p config/hypr/binds_sway.lua` — passed.
- [x] Run a small temporary Lua harness with mocked `o` and `hl` APIs; it verified 41 bindings and key/action mappings.
- [x] Review the existing `pcall(require, "sway_bindings")` hook; no installer change was needed.

### 3. Document and deploy the fix
- [x] Update `README.md` to describe Omarchy Lua registration and the resize-submap difference.
- [x] Run README acceptance checks, `luac -p`, `jq`, Bash syntax checks, and relevant static greps — passed. Full `make test` remains blocked by missing ShellCheck.
- [x] Reinstall the managed template (backup created), reload Hyprland, and verify `hyprctl binds -j` reports `SUPER + H` as `Focus l`. Manual focus behavior still needs confirmation with two windows open.

## Notes
- Diagnosis: this machine reports `LUA_ENGINE=1`; its `~/.config/hypr/bindings.lua` loads `sway_bindings`, but the installed module currently only returns a table that Omarchy ignores.
- Omarchy's local `bindings.lua` comments show the user API (`o.bind`, `hl.unbind`); `/usr/share/omarchy/default/hypr/helpers.lua` defines `o.bind`, and `bindings/tiling.lua` provides reference dispatcher patterns. Treat these files as read-only references.
- Do not modify Omarchy's `/usr/share/omarchy` or `~/.local/share/omarchy` files. Deployment through the project CLI creates a timestamped user-config backup before copying the updated managed Lua file.
- This is a focused fix for the Omarchy Lua path; no unrelated installer, bar, or configuration refactors.
