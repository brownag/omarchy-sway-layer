# State 3 — Directional pair reorientation and modal resizing

## Baseline checklist

- [x] Repository and conventions checked; no root `AGENTS.md` or `CONTRIBUTING.md` found.
- [x] Existing plans 1 and 2, README, relevant bindings/helper/tests, and accepted ADRs 0001–0003 inspected.
- [x] Relevant source file sizes recorded in `planning/EXECUTION_PLAN_3.md`.
- [x] Baseline `make test` passed: group movement, installer, Lua binding, and static checks.
- [x] Current compositor identified as Hyprland 0.56.2; `hyprctl` is available.
- [x] No existing reusable live-test script found in repo; prior live tests used disposable windows as recorded in `TODO.md` and `planning/STATE_2.md`.
- [x] Worktree checked; preserve unrelated untracked research files.

## Wave board

| Wave | Task | Title | Status | Dependencies |
| --- | --- | --- | --- | --- |
| 1 | 3.1.1 | Directional pair reorientation and modal resizing | complete | none |
| 2 | 3.2.1 | Document verified movement and resize behavior | complete | 3.1.1 |

## Task reports

### 3.1.1 — Directional pair reorientation and modal resizing

Complete; no live deployment or binding change was performed.

- `scripts/sway-group-move` accepts `lua|plain` mode plus a direction. It preserves the Lua group move-out/join and ordinary swap behavior, while plain mode falls back to native `movewindow`. A clear pair is exactly two visible, mapped, ungrouped, non-floating tiled clients on the workspace with unambiguous axis-aligned geometry; extra/ambiguous tiled state fails closed.
- For a cross-axis pair move, the helper dispatches `hl.dsp.layout("togglesplit")` in Lua mode or `layoutmsg togglesplit` in plain mode, checks that focus and pair identity remain, and uses a mode-appropriate directional swap only if needed to put the active client on the requested side. It verifies the resulting orientation and side. Same-axis and non-pair behavior stays on the pre-existing fallback path.
- Plain focus/move bindings now have arrow aliases; the plain resize submap has arrow aliases at 20-pixel steps. Lua focus arrows are added, and Lua `SUPER+r` enters a documented `hl.define_submap`/`hl.dsp.submap` resize mode with H/J/K/L and arrows, 20-pixel relative steps, and Return/Escape exits. `SUPER+b/v` remain present.
- Regression tests cover Lua and plain dispatch selection, all four pair transformations and selected-side outcomes, same-axis/floating/ambiguous/multi-window/no-neighbor cases, group behavior, query failures, aliases, manual split toggles, and resize mappings.
- Targeted validation passed: `bash -n scripts/sway-group-move tests/test-sway-group-move.sh`; `shellcheck scripts/sway-group-move tests/test-sway-group-move.sh`; `bash tests/test-sway-group-move.sh`; `luac -p config/hypr/binds_sway.lua tests/test-sway-bindings.lua`; `lua tests/test-sway-bindings.lua`; `make test`; `git diff --check`.
- Authorized disposable live tests on Hyprland 0.56.2 verified all four Lua-dispatch cross-axis cases. Every case used `hl.dsp.layout("togglesplit")` followed by `hl.dsp.window.swap({ direction = ... })`, retained active PID/address `116520` / `0x5717452e4e70`, and placed it on the requested side:
  - Up from side-by-side: A `[12,55]` and B `[690,55]` (both `664x701`) became A `[12,413]` (`1342x343`) and B `[12,55]` (`1342x344`).
  - Down from side-by-side: A `[690,55]` and B `[12,55]` (both `664x701`) became A `[12,55]` (`1342x344`) and B `[12,413]` (`1342x343`).
  - Left from top-bottom: A `[12,55]` (`1342x344`) and B `[12,413]` (`1342x343`) became A `[690,55]` and B `[12,55]` (both `664x701`).
  - Right from top-bottom: A `[12,413]` (`1342x343`) and B `[12,55]` (`1342x344`) became A `[12,55]` and B `[690,55]` (both `664x701`).
- The disposable windows were terminated by their launch PIDs `116498` and `116520`. Post-cleanup checks confirmed both PIDs absent, baseline client addresses preserved, workspace 1 active, and the pre-existing Omawrite client on workspace 99 untouched. Captures are under `/tmp/omarchy-sway-pair-final.KLQf04`.
- Not live-tested: plain-mode dispatch, same-axis/non-pair behavior, or resize mode (testing used the existing live runtime but did not deploy/reload this project’s bindings). No claim is made for those live paths.

### 3.2.1 — Document verified movement and resize behavior

Complete.

- Updated `README.md` with directional aliases, conservative pair reorientation and fallback boundaries, manual split controls, modal resize, and the distinction between Lua generic and plain axis-specific split toggles.
- Updated ADR-0001 to record that user-approved plain-config parity supersedes the earlier deferral while preserving the installed-helper boundary and limited scope.
- Documentation explicitly limits live evidence to four Lua-dispatch pair transformations on Hyprland 0.56.2; plain dispatch, same-axis/non-pair behavior, and resize mode remain untested live, and the project bindings were not deployed/reloaded.
- Acceptance passed: `grep -Fq 'SUPER+r' README.md && grep -Fq '20-pixel' README.md && grep -Fq 'arrow' README.md && grep -Fq 'plain-config' README.md && grep -Fq 'supersed' docs/decisions/0001-contextual-movement-through-installed-omarchy-helper.md && git diff --check`.
- Documentation-task edits were limited to `README.md` and ADR-0001; the broader worktree also contains the completed Task 3.1.1 implementation changes.

## Orchestration status

All tasks in Plan 3 are complete. Implementation and documentation validation passed; the authorized live test covered only Lua-dispatch pair reorientation. No project configuration was deployed or live bindings reloaded. Plain dispatch and resize-mode live behavior remain unverified.
