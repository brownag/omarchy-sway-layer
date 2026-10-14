# State 1 — omarchy-sway-layer orchestration

## Baseline checklist

- [x] Repo path confirmed: `/home/andrew/workspace/omarchy-sway-layer`
- [x] Current branch checked: `master`
- [x] Latest commit checked: `6347d96 Initial plan`
- [x] Initial file inventory checked: only `planning/INITIAL_PROMPT.md` outside `.git`
- [x] Entry-point size checked: `planning/INITIAL_PROMPT.md` — 125 lines
- [x] No existing `AGENTS.md`, `CONTRIBUTING.md`, Makefile, source files, tests, execution plans, or state files found
- [x] Baseline test status: no runnable test suite exists yet
- [x] Pre-wave-1 orchestrator check: `git status --short` shows only the three untracked planning artifacts; no user changes were present.

## Wave board

| Wave | Task | Title | Status | Dependencies |
| --- | --- | --- | --- | --- |
| 1 | 1.1 | Static configuration templates | done | none |
| 1 | 1.2 | Detection and backup helper scripts | done | none |
| 2 | 2.1 | Main installer CLI | done | 1.1, 1.2 |
| 3 | 3.1 | Makefile validation workflow | done | 2.1 |
| 3 | 3.2 | README documentation | done | 2.1 |

## Worker reports

## 1.1 — Static configuration templates
- Status: complete.
- Changed files: `config/hypr/binds_sway.conf`, `config/hypr/binds_sway.lua`, `config/waybar/config.jsonc`, `config/waybar/style.css`, `config/quickshell/BarOverrides.qml`.
- Tests: `test -s config/hypr/binds_sway.conf && test -s config/hypr/binds_sway.lua && test -s config/waybar/config.jsonc && test -s config/waybar/style.css && test -s config/quickshell/BarOverrides.qml` — PASS.
- Test: `grep -q 'bind = SUPER, h, movefocus, l' config/hypr/binds_sway.conf` — PASS.
- Test: `grep -q 'submap = resize' config/hypr/binds_sway.conf` — PASS.
- Test: `grep -q 'hyprland/workspaces' config/waybar/config.jsonc` — PASS.
- Deviations: none.
- Dependency gotcha: Lua artifact returns a binding table; no Omarchy consumer API is specified, so integration must consume it.

## 1.2 — Detection and backup helper scripts
- Status: complete.
- Changed files: `scripts/detect_omarchy.sh` (lines 1–55), `scripts/backup.sh` (lines 1–50), `planning/tasks/1.2.todo.md` (TODO checklist completed).
- Tests: `bash -n scripts/detect_omarchy.sh scripts/backup.sh` — PASS; 0 syntax errors.
- Tests: `grep -q 'set -euo pipefail' scripts/detect_omarchy.sh scripts/backup.sh` and `grep -q 'OMARCHY_SWAY_BACKUP_ROOT' scripts/backup.sh` — PASS.
- Behavior check: temp-HOME detection of config/Lua/bar strings and backup copy+manifest with present and absent trees — PASS.
- Deviations: none; both scripts are executable and use XDG config/HOME paths with `OMARCHY_SWAY_BACKUP_ROOT` override.
- Dependency gotcha: detection emits `KEY=value` booleans; backup prints its timestamped directory and records source-presence flags in `manifest.txt`.

## Orchestration status

Waves 1, 2, and 3 are complete. All tasks are done.

## Orchestrator verification note

A manual temp-HOME smoke initially inherited the session's `XDG_CONFIG_HOME`, so three install invocations briefly targeted the live config. The orchestrator restored the pre-test snapshot, removed only the three test-created backup directories, verified the managed source line was absent, and reran the smoke with `XDG_CONFIG_HOME` unset; the corrected test passed.

## 2.1 — Main installer CLI
- Status: complete.
- Changed files: `bin/apply-sway-layer` (lines 1–293; executable); `planning/tasks/2.1.todo.md` (all 11 steps checked); `planning/STATE_1.md` (this report and wave status).
- Tests: `bash -n bin/apply-sway-layer` — PASS; grep acceptance checks for `install_layer()`, `rollback_layer()`, `DRY_RUN=` — PASS; `bin/apply-sway-layer --help` — PASS.
- Temp-HOME smoke: dry-run no-write, plain install/idempotence/Waybar opt-in/rollback by timestamp/uninstall preservation — PASS.
- Temp-HOME smoke: looknfeel-only Lua integration, no hyprland.conf overwrite, dry-run, uninstall — PASS.
- Deviations: none. No real-home install or live-session reload was run.
- Dependency gotchas: detection uses stable booleans and backup manifest presence flags; Lua template returns a binding table without a specified Omarchy consumer API, while CLI performs the required `pcall(require, "sway_bindings")` integration.

## 3.1 — Makefile validation workflow
- Status: complete; `make test` is blocked from full validation because `shellcheck` is unavailable.
- Changed files: `Makefile`; `planning/tasks/3.1.todo.md`; `planning/STATE_1.md`.
- `make -n install uninstall test lint` — PASS; output confirmed CLI recipes without executing them.
- Grep acceptance for `shellcheck`, `jq`, and `luac -p` in Makefile — PASS.
- `bash -n` for CLI and both scripts, temporary JSONC copy validated by `jq`, `luac -p`, and static binding/managed-line greps — PASS.
- `make test` — FAIL as expected: `make test: required tool not found: shellcheck`; `jq` and `luac` are installed.
- Installer actions were not run; no real-home target was touched.
- Deviations: ShellCheck could not be run because it is not installed; no other deviations.

## 3.2 — README documentation
- Status: complete.
- Changed files: `README.md` (lines 1–106); `planning/tasks/3.2.todo.md` (lines 1–26; all 11 steps checked); `planning/STATE_1.md` (lines 68–77).
- Acceptance: `test -s README.md && grep -q -- '--enable-waybar' README.md && grep -q -- '--rollback latest' README.md && grep -q 'Native Sway/i3 vs Hyprland' README.md` — PASS.
- Additional README anchors: `SUPER + h/j/k/l` and `/usr/share/omarchy` — PASS.
- README covers purpose, layout, prerequisites, static local validation, deployment, supported CLI options, verification, keybindings, and Hyprland semantic differences.
- Lua caveat documented: returned binding table has no specified Omarchy consumer API; `require` alone does not prove activation.
- No live Omarchy testing is claimed; no code or Makefile was changed.
- Deviations: none.
