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

## Follow-up Goal
Restore `make test` after ShellCheck was installed by fixing its reported warnings without changing runtime behavior.

## Follow-up Tasks

### 4. Fix ShellCheck warnings
- [x] Split the `backup_dir` / `manifest` local declarations in `bin/apply-sway-layer` so `manifest` expands after `backup_dir` is assigned.
- [x] Initialize the three presence flags in `scripts/backup.sh` before the indirect `printf -v` assignments so ShellCheck recognizes them. Targeted ShellCheck and Bash syntax checks passed.

### 5. Validate and commit
- [x] Run targeted ShellCheck, then `make test`; `make test` passed with `make test: all static checks passed`.
- [x] Create a conventional fix commit after all checks pass.

## Follow-up Goal: Fix Omarchy Lua group and directional movement

Diagnose and repair why group toggles, directional swapping, and moving windows into or out of groups do not work in the installed Omarchy Lua mode.

### Tasks

#### 1. Confirm the live API/state shape
- [x] Read the current Hyprland active-window and client JSON fields relevant to grouping and geometry; verify their JSON types against the helper's jq assumptions. The `grouped` field is an array; current active focus is ungrouped and is the only visible client on workspace 1, so the helper correctly selects no directional action in this exact state.
- [x] Check installed binding registration for `SUPER+w`, `SUPER+g`, `SUPER+SHIFT+directions`; `hyprctl binds -j` shows each intended Omarchy Lua binding registered. `SUPER+ALT+G` is the existing move-out binding and `SUPER+ALT+arrows` are registered group-in bindings.
- [x] Identify the dispatcher mismatch before changing implementation. On this Omarchy/Hyprland Lua build, `hyprctl dispatch` parses its argument as Lua (`hl.dispatch(...)`); the helper currently sends bare strings such as `swapwindow l`, which fail Lua parsing. A no-op workspace-switch probe failed with `')' expected near '10'`; the equivalent `hl.dsp.focus({workspace = "10"})` succeeded. This explains why every shell-helper swap/join/leave dispatch is silently ignored. The helper must dispatch Omarchy Lua expressions, not plain Hyprland dispatcher text.
- [x] Reproduced with disposable windows and confirmed the helper must send Lua dispatcher expressions. Tests now assert swap/join/leave expressions and verify dispatch errors propagate.

#### 2. Fix and test the root cause
- [x] Update only the affected helper and its tests with a regression fixture for the live array-shaped `grouped` field and Lua dispatcher syntax.
- [x] Test ordinary directional swap, group toggle, joining a group, and moving a grouped window out; dispatcher errors are no longer swallowed.
- [x] Run `make test` and `git diff --check`; both passed.

#### 3. Validate safely
- [x] Confirmed Omarchy Lua registration with `hyprctl -j binds`; installed through `./bin/apply-sway-layer` (backup: `/home/andrew/.config/omarchy-sway-backup/20261013-194758`), ran `hyprctl reload`, and verified the installed helper matches the source.
- [x] Non-destructive disposable-window checks on workspace 10 passed: helper swapped two windows; group toggle created group state; an ungrouped neighbor joined the group; helper moved that member out. Test windows were terminated and workspace 1 restored.
- [x] No remaining API limitation found. Physical key events were not synthetically injected; binding registrations and their underlying dispatchers were verified.

### Notes
- User reports both HJKL and arrows fail for group movement; ordinary swaps with `SUPER+SHIFT+direction` also do not work. `SUPER+w` and `SUPER+g` appear not to toggle groups. `SUPER+ALT+arrows` can move windows into groups but not back out.
- Root cause: Omarchy's Lua-enabled `hyprctl dispatch` parses its argument as a Lua expression. Plain dispatcher strings (`swapwindow l`, etc.) failed Lua parsing; the helper silenced errors. It now calls the installed `hl.dsp.window.swap` / `hl.dsp.window.move` dispatchers through Lua expressions and returns dispatch failures.
- Live `grouped` values are arrays, matching the parser/test fixture. The plain-config path remains unchanged.
