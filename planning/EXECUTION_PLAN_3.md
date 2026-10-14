# Execution Plan 3 — Directional pair reorientation and modal resizing

## Goal & Scope

### Goal
Make H/J/K/L and arrow keys equivalent for focus, directional window movement, and resizing; when a directional move is requested across the current split axis for a clear two-window tiled pair, reorient the pair and place the focused window on the requested side (down below, up above, right to the right, left to the left), rather than swapping their positions. Provide a `SUPER+r` resize mode in both plain-config and Omarchy Lua integrations, with H/J/K/L and arrows resizing by the existing 20-pixel increments.

### In scope
- Bind H/J/K/L and arrow aliases equivalently for focus and directional movement in plain Hyprland and Omarchy Lua modes.
- Extend contextual movement to reorient a clear two-window pair only when a move crosses its split axis; preserve ordinary existing behavior for other layouts and same-axis moves.
- Make selected-window placement follow the requested direction; down means below, up above, right on the right, left on the left.
- Provide `SUPER+r` as a modal resize entry in both modes; accept both H/J/K/L and arrows, use 20-pixel increments, and exit with Escape or Return.
- Automated tests, live behavior validation where possible, README documentation, and update the accepted ADR that currently defers plain-config parity.

### Out of scope
- General rearrangement/reorientation of layouts with more than the clear two-window pair.
- Replacing Hyprland's layout/tree model with a complete Sway container-tree implementation.
- Changing unrelated bindings, Omarchy upstream files, or unrelated installer behavior.

### Verbatim constraints and decisions from the user
- "i'd like h/j/k/l to be analogous to the arrow keys"
- "i'd like super+b or super+v to be \"automatic\" when moving a vertical split window down to create a horizontal split."
- "is it possible to create super+r so it is a mode that behaves as if y9ou had super+ctrl held down, and you could use hjkl or arrows to adjust equivaletly"
- "i think the selected window would end up below but this is not a \"swap\"; it should equivalently apply to left/right applied to a top/bottom arrangement"
- "agree" (limit automatic reorientation to a clear two-window tiled pair)
- "yes" (provide resize mode in both paths, both key families, 20px steps, Escape/Return exit)
- "yes" (apply automatic reorientation to both plain and Lua paths, superseding the plain-path deferral in ADR-0001)
- "yes correct" (reorient only on cross-axis moves; along-axis moves retain existing behavior)
- "agree, should be possible to do live tests, i believe we have some scripts doing that already"
- "yes" (serial implementation, no parallel workers)
- "yes remain available" (retain `SUPER+b` and `SUPER+v` as explicit manual split-orientation toggles alongside automatic directional reorientation)

## Recon log

- Repo: `/home/andrew/workspace/omarchy-sway-layer`; no root `AGENTS.md` or `CONTRIBUTING.md` found. Existing numbered plans are 1 and 2; this is plan 3.
- Relevant file sizes: `config/hypr/binds_sway.conf` 58 lines; `config/hypr/binds_sway.lua` 61; `scripts/sway-group-move` 66; `tests/test-sway-bindings.lua` 44; `tests/test-sway-group-move.sh` 139; `README.md` 116.
- Baseline: `make test` passed (`test-sway-group-move`, `test-sway-installer`, `test-sway-bindings`, static checks). Current Hyprland is 0.56.2; `hyprctl` is available.
- Plain config binds only H/J/K/L focus/move, has native move dispatchers, explicit split bindings `SUPER+b/v`, and a resize submap accepting H/J/K/L only. Lua binds focus on H/J/K/L, shifted move/group actions on H/J/K/L and arrows, explicit `SUPER+b/v/e` layout toggles, and Ctrl+Super H/J/K/L direct resize actions; no Lua resize mode is present.
- The already-installed `scripts/sway-group-move` helper selects a geometric directional neighbor from read-only activewindow/client state and handles group leave/join/swap in Lua mode. It is installed to `~/.config/hypr/sway-group-move` by the installer. Tests use mocked `hyprctl`; no reusable live behavior script was found in the repository, despite the user's recollection. Check the existing test and prior validation records for safe live-test patterns before executing.
- Accepted ADRs: ADR-0001 chooses an installed helper for contextual movement and explicitly defers plain-config parity; ADR-0002 requires read-only geometry/client state for directional probes; ADR-0003 requires Omarchy Lua expressions for Lua-path dispatch and visible failures. User explicitly approved extending behavior to plain config, superseding ADR-0001's deferral; preserve ADR-0002's read-only probing and ADR-0003's Lua-only dispatch contract.
- Omarchy's local `o.bind` wrapper delegates to `hl.bind` and has no documented submap option; no submap implementation was found in the inspected default Hyprland Lua files. The existing project README records this limitation. The implementation must establish a reliable Lua-mode resize-mode mechanism rather than silently retaining Ctrl+Super direct chords. Plain-config `SUPER+r` submap already exists.
- The installer already manages the helper in dry-run/install/uninstall. Avoid unrelated installer changes unless implementation demonstrates they are required.

## Decision log

- 2026-10-14 — Add arrow aliases alongside H/J/K/L for focus, movement, and resizing in both integration modes.
- 2026-10-14 — On a clear two-window tiled pair, a cross-axis direction reorients the pair and places the focused window on the requested side; this is not a swap. Down means below; up above; right to the right; left to the left. Same-axis moves and layouts beyond a clear pair keep existing behavior.
- 2026-10-14 — Apply the pair behavior to both plain Hyprland and Omarchy Lua integrations, superseding ADR-0001's plain-path deferral. Do not modify Omarchy upstream files.
- 2026-10-14 — Keep `SUPER+b` and `SUPER+v` as explicit manual split-orientation toggles; automatic directional reorientation does not replace them.
- 2026-10-14 — `SUPER+r` enters resize mode in both paths; accept H/J/K/L and arrows, use 20-pixel increments, exit with Return/Escape.
- 2026-10-14 — Require automated regression coverage and live two-window testing where the target session permits; do not claim untested runtime behavior.
- 2026-10-14 — Execute serially because behavior/config/tests are coupled and share files; no parallel workers/worktrees.

## Hazard notes

- A geometric neighbor is not necessarily a direct sibling in Hyprland's internal layout tree. The implementation must use a conservative, testable definition of a clear two-window pair and must not reorient ambiguous/multi-window layouts.
- The pair transition must be non-destructive and preserve focus/window identity. Test all four cross-axis directions, both pair orientations, same-axis no-reorientation, no neighbor, and ambiguous/multi-window states.
- Plain Hyprland dispatcher syntax and Omarchy Lua-expression dispatch are distinct (ADR-0003); do not send Lua expressions to plain mode or silently suppress dispatch errors.
- Lua mode currently has no documented submap support through `o.bind`; validate any resize-mode mechanism against the installed Omarchy/Hyprland APIs and live bindings before relying on it.
- Existing live-test records in `TODO.md`/`planning/STATE_2.md` used disposable windows. Do not close or disturb user windows; obtain explicit confirmation before any deployment or live test that changes the active layout.

## Wave table

| Wave | Tasks | Purpose | Dependencies | Parallelism notes |
| --- | --- | --- | --- | --- |
| 1 | 3.1.1 | Implement equivalent directional aliases, conservative pair reorientation in both paths, modal resize in both paths, and regression/live validation | none | Serial, one coupled implementation task |
| 2 | 3.2.1 | Document behavior and update ADR-0001 to record the approved plain-path extension | 3.1.1 | Serial, docs/decision updates follow verified implementation |

## Task specs

### Task 3.1.1 — Directional pair reorientation and modal resizing

- **id:** `3.1.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must edit: `config/hypr/binds_sway.conf`, `config/hypr/binds_sway.lua`, `scripts/sway-group-move`, `tests/test-sway-group-move.sh`, `tests/test-sway-bindings.lua`, and `Makefile` only if needed to keep validation checks accurate.
  - May read but must not edit: `bin/apply-sway-layer`, `tests/test-sway-installer.sh`, `planning/STATE_2.md`, `TODO.md`, ADR-0001/0002/0003, installed Omarchy files under `/usr/share/omarchy`.
  - Temp/scratch: `.development/task-3.1.1/` only.
- **depends-on:** none.
- **spec:** Add arrow aliases for focus and movement in plain config and Lua mode, so H/J/K/L and arrows invoke equivalent directions. For a clear two-window tiled pair, when movement crosses its current split axis (up/down for a side-by-side pair; left/right for a top/bottom pair), change the pair's arrangement and place the active window on the requested side; this is placement, not a swap. Preserve existing behavior for same-axis movement, ambiguous layouts, and layouts not qualifying as a clear pair. Maintain group-aware actions where applicable. Retain `SUPER+b` and `SUPER+v` as explicit manual split-orientation toggles. Implement `SUPER+r` resize mode in both integrations; the mode accepts H/J/K/L and arrow keys with 20-pixel steps and exits on Return/Escape. Verify a robust Lua-mode implementation against installed APIs, since the current binding wrapper has no documented submap support. Keep Lua expression dispatch and plain dispatcher syntax appropriately separated. Add mocked regression tests for key aliases, all four pair transformations, selected-window placement, same-axis and non-pair no-reorientation, no-neighbor, retention of the `SUPER+b/v` split toggles, and resize-mode registration/exit/step mappings. Then perform safe live checks with disposable windows in both pair orientations and both modes when available; record exactly what was tested and do not deploy without explicit authorization.
- **constraints / do not touch:** Do not edit README, ADRs, installer, tests outside the listed scope, or upstream Omarchy files. Do not change existing group semantics except where needed to retain them alongside pair reorientation. Do not treat a geometric neighbor as a pair unless the conservative pair condition is met. Never test with or close user windows; no live deployment/layout mutation without explicit user authorization. Do not introduce a dependency.
- **grep anchors:** `local function bind`, `local function context_move`, direction table in `config/hypr/binds_sway.lua`; `movefocus`, `movewindow`, `submap = resize`, `resizeactive` in `config/hypr/binds_sway.conf`; `active=$(hyprctl -j activewindow` and `selection=$(jq -er` in `scripts/sway-group-move`; mocked directional fixtures in `tests/test-sway-group-move.sh`; binding assertions in `tests/test-sway-bindings.lua`.
- **reference implementations:** Existing neighbor selection and group behavior in `scripts/sway-group-move`; existing context fixtures in `tests/test-sway-group-move.sh`; Omarchy registration mock in `tests/test-sway-bindings.lua`; existing plain resize submap in `config/hypr/binds_sway.conf`; `hl.dsp.window.resize` registration in `config/hypr/binds_sway.lua`; ADR-0002 read-only probing and ADR-0003 mode-specific dispatch contract.
- **acceptance + targeted test command:** `bash -n scripts/sway-group-move tests/test-sway-group-move.sh && shellcheck scripts/sway-group-move tests/test-sway-group-move.sh && bash tests/test-sway-group-move.sh && luac -p config/hypr/binds_sway.lua tests/test-sway-bindings.lua && lua tests/test-sway-bindings.lua && make test && git diff --check`. Tests must assert all requested alias/direction/mode mappings and all pair boundary behaviors. Live validation: disposable two-window layouts, test down/up from side-by-side and left/right from top-bottom, verify active window ends on requested side; verify same-axis and non-pair behavior stays unchanged; verify resize mode entry, both key families, 20px increments, and exits. Run in both integration modes if safely available; document unavailable mode/tests and do not claim they passed.

### Task 3.2.1 — Document verified movement and resize behavior

- **id:** `3.2.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must edit: `README.md`, `docs/decisions/0001-contextual-movement-through-installed-omarchy-helper.md`.
  - May read but must not edit: implementation files from Task 3.1.1, `planning/STATE_3.md`, ADR-0002 and ADR-0003.
  - Temp/scratch: `.development/task-3.2.1/` only, if needed.
- **depends-on:** `3.1.1`.
- **spec:** Document that H/J/K/L and arrows are aliases for focus/move/resize, describe the verified two-window cross-axis behavior and its non-swap selected-side outcome, state that same-axis and ambiguous/multi-window arrangements retain existing behavior, retain `SUPER+b/v` as manual split toggles, and explain `SUPER+r` modal resizing (20-pixel increments; Return/Escape exits) in both modes. State any verified limitations of the Lua implementation and do not claim universal Sway equivalence. Update ADR-0001 to record that user-approved plain-config parity supersedes its deferral, while preserving its installed-helper boundary and scope limits.
- **constraints / do not touch:** Do not claim any live behavior that Task 3.1.1 did not verify. Do not change code, tests, installer, or other ADRs.
- **grep anchors:** `Keybindings`, `Omarchy Lua mode`, `SUPER + r`, `SUPER + CTRL`, ADR-0001 `Decision Outcome` and `Consequences`.
- **reference implementations:** Existing README behavior table and native Sway/Hyprland comparison; ADR-0001 existing decision outcome; Task 3.1.1 test/live report in STATE_3.
- **acceptance + targeted test command:** `grep -Fq 'SUPER+r' README.md && grep -Fq '20-pixel' README.md && grep -Fq 'arrow' README.md && grep -Fq 'plain-config' README.md && grep -Fq 'supersed' docs/decisions/0001-contextual-movement-through-installed-omarchy-helper.md && git diff --check`.

## Plan review notes

### Spec-axis review
- All user decisions are mapped to Task 3.1.1 or 3.2.1: aliases, automatic pair reorientation, exact selected-side placement, cross-axis-only condition, both integration modes, resize mode/keys/steps/exits, live validation, serial execution, and retention of explicit `SUPER+b/v` toggles.
- Larger/ambiguous layouts, complete Sway tree semantics, unrelated bindings, and upstream changes are explicitly out of scope.

### Standards-axis review
- Core implementation and tests share the helper, binding config, and fixtures and therefore remain one serial task; documentation and ADR update are a dependent second wave.
- The independent standards pass found and corrected one inaccurate grep anchor; all task scopes, dependencies, references, and targeted acceptance commands are explicit.
- Live tests require disposable windows and explicit authorization before changing active layout or deploying configuration.
