# Execution Plan 2 — Context-aware Omarchy window grouping

## Goal & Scope

### Goal
Make the Omarchy Lua keymap use familiar Sway-style directional shortcuts for both ordinary window movement and group-aware movement. `SUPER+w` toggles grouping for the focused window; `SUPER+SHIFT+q` is the sole close binding. The same `SUPER+SHIFT` direction keys work contextually: move/swap normally, join an adjacent group when appropriate, or move the focused window out of its group. The change targets Omarchy's Lua engine first.

### In scope
- Omarchy Lua registrations using the installed `o.bind` / `hl.dsp` API.
- One group-aware directional action for both `SUPER+SHIFT+h/j/k/l` and `SUPER+SHIFT+arrows`.
- `SUPER+w` group toggle, with Omarchy's `SUPER+w` close binding removed; only `SUPER+SHIFT+q` closes through the managed layer.
- Context-aware directional behavior: focused window already grouped -> move it out in the requested direction; otherwise, if the directional neighbor is grouped -> move the focused window into that group; otherwise -> ordinary directional move/swap.
- Install, dry-run, and uninstall support for any managed helper needed by the Lua bindings.
- Automated tests for context selection and runtime registration, README updates, and live validation on the current Omarchy/Hyprland machine.
- Preserve Omarchy's existing `SUPER+g` group toggle, `SUPER+ALT+arrows` group-movement bindings, and `SUPER+ALT+TAB` / `SUPER+ALT+SHIFT+TAB` group cycling.

### Out of scope
- Updating the plain Hyprland config path (`config/hypr/binds_sway.conf`). It remains unchanged for now; a future shared/intermediary implementation may be planned separately.
- Changing Omarchy upstream files under `/usr/share/omarchy` or `~/.local/share/omarchy`.
- Removing existing Omarchy group aliases, group-cycle controls, or unrelated Omarchy bindings.
- Waybar, Quickshell, general installer refactors, or an exact implementation of Sway's container tree/layout model.

### Verbatim constraints and decisions from the user
- "super+w toggles grouping.ideally we could use the super+shift+hjkl or +arrow keys combined with grouping similar to how sway works"
- "i dont want distinct chords though. i want to be able to use hjkl or arrows with shift+super to move/swap+into/out of groupps"
- "exactly tthat is what i want context sensitive"
- "yes both" (HJKL and arrow aliases)
- "yes only super shift q. this is harder to do by accident and closing a window should always be deliberate"
- "i see no reason to unbind them at this time" (Omarchy's existing `SUPER+ALT+arrows` group-movement bindings remain)
- "target Omarchy Lua path first. the plain-config path can be addressed later, perhaps we will create some sort of intermediary code that can be shared in future refactor"
- The user approved acceptance that checks the live binding list and manually tests behavior with two tiled windows.

## Recon log

- Repository: `/home/andrew/workspace/omarchy-sway-layer`; branch `master`; existing orchestration is Plan 1, so this is Plan 2.
- No repository-root `AGENTS.md` or `CONTRIBUTING.md` exists. Existing process artifacts are `planning/EXECUTION_PLAN_1.md`, `planning/PROMPT_TEMPLATE_1.md`, `planning/STATE_1.md`, `planning/tasks/`, and the referenced `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`.
- Current relevant file sizes: `config/hypr/binds_sway.lua` 50 lines, `config/hypr/binds_sway.conf` 58 lines, `bin/apply-sway-layer` 293 lines, `Makefile` 31 lines, `README.md` 107 lines. Use the named symbols/anchors below rather than broad reads.
- Baseline: `luac -p config/hypr/binds_sway.lua`, `jq empty config/waybar/config.jsonc`, and Bash syntax checks passed. `make test` stops clearly because `shellcheck` is unavailable; `jq` and `luac` are installed.
- Live target: Omarchy Lua engine detected (`LUA_ENGINE=1`) on Hyprland 0.56.2. `hyprctl activewindow -j` exposes `group` and `grouped` fields; `hyprctl clients -j` reports geometry, workspace, and group fields.
- Live Omarchy bindings observed: `SUPER+W` closes; `SUPER+SHIFT+arrows` swaps; `SUPER+ALT+arrows` moves into groups; `SUPER+ALT+TAB` / `SUPER+ALT+SHIFT+TAB` cycle group members; `SUPER+G` toggles grouping. The managed Lua layer currently closes on both `SUPER+Q` and `SUPER+SHIFT+Q`, and its shifted directional actions are static swaps.
- Reference implementations: `/usr/share/omarchy/default/hypr/helpers.lua:92-106` (`o.bind`); `/usr/share/omarchy/default/hypr/bindings/tiling.lua:1,39-42,73-82` (close, swap, group, and cycle APIs); `/usr/share/omarchy/default/hypr/bindings/utilities.lua:117-123` (Lua callback dispatch); `/usr/share/omarchy/default/hypr/bindings/clipboard.lua:21-34` (`hl.get_active_window`). These are read-only system references.
- Hyprland/Sway comparison and dispatcher-source links are recorded in `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`.
- Current worktree contains untracked project and Plan 1 artifacts. Do not stage or alter unrelated files. Work is sequenced; worktree isolation is unavailable until the existing untracked content is committed, which this planning task does not authorize.

## Decision log

- 2026-10-13 — The target is the current Omarchy Lua engine first; leave `binds_sway.conf` unchanged and defer a shared implementation/refactor.
- 2026-10-13 — `SUPER+w` toggles the focused window's group membership. Unbind Omarchy's `SUPER+w` close action; close only on `SUPER+SHIFT+q`, and do not leave `SUPER+q` as a close alias.
- 2026-10-13 — Use the same context-aware action on both HJKL and arrow aliases with `SUPER+SHIFT`: grouped focused window -> move out; ungrouped focused window with grouped directional neighbor -> move into that group; otherwise -> ordinary directional swap/move.
- 2026-10-13 — Preserve Omarchy's `SUPER+g`, `SUPER+ALT+arrows`, and group-cycle bindings; do not remove these existing aliases.
- 2026-10-13 — Acceptance includes live `hyprctl binds` verification and a manual two-window behavior check. Do not claim live behavior from static checks alone.

## Hazard notes

- The behavior is state-dependent; a static dispatcher cannot choose among swap, move-into-group, and move-out-of-group. Task 2.1.1 must verify the installed Lua/Hyprland query surface and must not leave focus changed while inspecting a directional neighbor.
- Group JSON fields and `moveintogroup` / `moveoutofgroup` behavior can vary by Hyprland version. Test against installed 0.56.2; handle no-neighbor and command-failure cases without losing focus or silently closing/moving a window.
- Deployment must use `./bin/apply-sway-layer` so a timestamped backup is made before managed user config is replaced. Do not manually edit user bindings or upstream files.
- `make test` cannot be fully green until ShellCheck is available in this environment; run targeted tests and report that prerequisite accurately.
- Grouped-window focus/movement behavior requires a manual two-window test; `hyprctl binds -j` alone proves only registration.

## Wave table

| Wave | Tasks | Purpose | Dependencies | Parallelism notes |
| --- | --- | --- | --- | --- |
| 1 | 2.1.1 | Implement and test context-aware Omarchy Lua group movement, managed helper installation, and safe close/group bindings | none | One tightly coupled task; shared logic/config/installer/tests stay together |
| 2 | 2.2.1 | Document the Omarchy-specific behavior and the plain-config deferral | 2.1.1 | README-only task after implementation is verified |

## Task specs

### Task 2.1.1 — Context-aware Omarchy Lua grouping

- **id:** `2.1.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `config/hypr/binds_sway.lua`
    - `bin/apply-sway-layer`
    - `Makefile`
    - `scripts/sway-group-move`
    - `tests/test-sway-group-move.sh`
    - `tests/test-sway-bindings.lua`
    - `tests/test-sway-installer.sh`
  - Can create: parent directory `tests/`.
  - Temp/scratch: `.development/task-2.1.1/` only, if needed.
  - May read but must not edit: `config/hypr/binds_sway.conf`, `README.md`, `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`, and the named installed Omarchy references in the Recon log.
- **depends-on:** none.
- **spec:** Implement the approved Omarchy Lua behavior. Bind `SUPER+w` to `hl.dsp.group.toggle()` after unbinding its Omarchy close action. Keep close only on `SUPER+SHIFT+q`; explicitly ensure `SUPER+q` does not remain a managed close binding. Bind both HJKL and arrow variants of `SUPER+SHIFT+direction` to one context-aware movement implementation: if the focused window is grouped, dispatch move-out in that direction; if it is ungrouped and the directional neighbor is grouped, dispatch move-into-group; otherwise dispatch the normal directional move/swap. Preserve existing Omarchy `SUPER+g`, `SUPER+ALT+arrows`, and group-cycle bindings. Keep the plain Hyprland config template unchanged. If a helper is needed, install it as a managed file under the user's Hypr config directory, include it in dry-run and uninstall handling, and do not reference the source checkout at runtime. Add targeted tests for all three context branches, focus restoration/no-neighbor behavior, Lua binding registration, and the installer helper lifecycle (isolated dry-run, install, and uninstall using an explicit temporary `XDG_CONFIG_HOME`).
- **constraints / do not touch:** Do not edit `config/hypr/binds_sway.conf`, README, research artifacts, or `/usr/share/omarchy` / `~/.local/share/omarchy`. Do not add group-specific chords beyond the requested `SUPER+w` toggle and already-existing Omarchy defaults. Do not test by closing the user's real windows. Do not modify user config except through the CLI after a timestamped backup; do not run against a temporary `HOME` while inheriting the live `XDG_CONFIG_HOME`.
- **grep anchors:** `local function bind`, `hl.get_active_window`, `hl.dsp.group.toggle`, `SUPER + SHIFT + Q`, `copy_managed`, `write_managed_files`, `uninstall_layer`, `test:` in Makefile, `hyprctl activewindow -j`, `moveintogroup`, `moveoutofgroup`.
- **reference implementations:** Omarchy API patterns in `/usr/share/omarchy/default/hypr/helpers.lua:92-106`, `/usr/share/omarchy/default/hypr/bindings/tiling.lua:39-42,73-82`, `/usr/share/omarchy/default/hypr/bindings/utilities.lua:117-123`; CLI managed-file pattern in `bin/apply-sway-layer`; project static validation in `Makefile`.
- **acceptance + targeted test command:** `bash -n scripts/sway-group-move tests/test-sway-group-move.sh tests/test-sway-installer.sh bin/apply-sway-layer scripts/*.sh && bash tests/test-sway-group-move.sh && bash tests/test-sway-installer.sh && luac -p config/hypr/binds_sway.lua tests/test-sway-bindings.lua && lua tests/test-sway-bindings.lua && jq empty config/waybar/config.jsonc`; installer smoke tests must explicitly set a disposable `XDG_CONFIG_HOME` and prove dry-run creates no files, install copies the helper, and uninstall removes it. Then run `make test` (currently expected to stop on missing ShellCheck unless installed). On the live target, install through the CLI, run `hyprctl reload`, verify `SUPER+w`, `SUPER+SHIFT+q`, and both directional key families with `hyprctl binds -j`, then manually test: ordinary swap with two ungrouped tiled windows; join an adjacent group; move a grouped focused window out. Confirm the directional probe restores focus and leaves unrelated windows unchanged.

### Task 2.2.1 — Document group-aware Omarchy behavior

- **id:** `2.2.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must edit: `README.md`.
  - May read but must not edit: all implementation files and `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`.
  - Temp/scratch: `.development/task-2.2.1/` only, if needed.
- **depends-on:** `2.1.1`.
- **spec:** Document `SUPER+w` as the Omarchy Lua group toggle, `SUPER+SHIFT+q` as the only managed close chord, both HJKL and arrow directional aliases, the context-aware swap/join/leave behavior, and the intentionally retained Omarchy `SUPER+g` / `SUPER+ALT+arrows` aliases. State clearly that this currently targets Omarchy Lua mode; the plain Hyprland config path is unchanged and deferred to a future shared-code refactor. Explain that Hyprland groups approximate, but do not reproduce, Sway stacking.
- **constraints / do not touch:** Do not claim plain-config parity, exact Sway layout semantics, or live behavior beyond what Task 2.1.1 verifies. Do not modify code, templates, Makefile, or research notes.
- **grep anchors:** `SUPER+w`, `SUPER+SHIFT+q`, `SUPER+SHIFT+h/j/k/l`, `SUPER+ALT+arrows`, `context-aware`, `plain-config path`.
- **reference implementations:** `config/hypr/binds_sway.lua`, `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`, and the verified behavior report in `planning/STATE_2.md`.
- **acceptance + targeted test command:** `test -s README.md && grep -Fq 'SUPER+w' README.md && grep -Fq 'SUPER+SHIFT+q' README.md && grep -Fq 'SUPER+ALT+arrows' README.md && grep -Fq 'plain-config path' README.md && grep -Fq 'context-aware' README.md`.

## Plan review notes

### Spec-axis review
- Every user decision maps to Task 2.1.1 or Task 2.2.1: `SUPER+w` group toggle, deliberate close only on `SUPER+SHIFT+q`, both directional key families, state-dependent group behavior, retention of current Omarchy aliases, Lua-only target, plain-config deferral, and live behavior verification.
- The task does not invent a full Sway container/layout port; it describes groups as an approximation.

### Standards-axis review
- Core implementation and its tests are in one task because they share the Lua template, installed helper, installer, and validation code. Documentation is a dependent, README-only task.
- The independent standards pass found that CLI helper lifecycle was not covered by an automated check. Resolved by adding `tests/test-sway-installer.sh` and requiring a disposable `XDG_CONFIG_HOME` dry-run/install/uninstall smoke test.
- Each worker task has explicit files, named reference implementations, grep anchors, a targeted command, and <=12-step expected micro-planning.
- The tasks are sequential; the existing dirty/untracked worktree rules out safe worktree isolation. No shared global suite is delegated to parallel workers.
