# STATE_4 — Orchestration 4 state

- Plan: `planning/EXECUTION_PLAN_4.md`
- Prompt: `planning/PROMPT_TEMPLATE_4.md`
- Research: `planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`
- Worker model: `opencode-go/deepseek-v4.1-flash:low` (D8); escalation to `openai/gpt-6-luna`
- Execution: single writer, sequential waves, no worktrees (D7)
- Resume point: this file. Highest-numbered orchestration is 4.

## Baseline (before wave 1)

Recorded 2026-10-15 by the orchestrator on `main` @ `2503b39`.

- [x] `command -v shellcheck jq luac lua bemenu omarchy-theme-color` — all present
- [x] `make test` — PASS (`test-sway-group-move: passed`,
      `test-sway-installer: passed`, `test-sway-bindings: passed`,
      `make test: all static checks passed`)
- [x] `git status --porcelain` — clean except untracked planning artifacts (committed separately)

## Wave board

| Wave | Task | Depends on | Status |
| --- | --- | --- | --- |
| 1 | 4.1.1 Wrapper core + test | — | done |
| 2 | 4.2.1 Opt-in install + binding rewrite + backup/uninstall | 4.1.1 | pending |
| 3 | 4.3.1 Docs + ADR 0004 | 4.2.1 | pending |
| 4 | 4.4.1 Theme-fidelity fixtures + contrast | 4.1.1 | pending |

## Task reports

<!-- Workers append a <=15-line report under a "## <id>" heading here. -->

## 4.1.1

- Created `scripts/bemenu-themed` (executable, `set -euo pipefail`): live palette
  resolution via `omarchy-theme-color` with a `sed` direct-read fallback that
  captures the leading `#`; 16 key→flag color mappings; centered geometry defaults;
  `exec bemenu-run` on TTY stdin else `exec bemenu`, passing `"$@"`.
- Created `tests/test-bemenu-themed.sh` (no Wayland needed): stub `bemenu`,
  `bemenu-run`, keyed `omarchy-theme-color`; asserts geometry/`--fn`, resolver
  mappings for every region, direct-read fallback with the resolver genuinely absent
  (isolated PATH excluding `/usr/bin`), and TTY (`script -qec`) selects `bemenu-run`
  while a pipe selects `bemenu`.
- Wired `scripts/bemenu-themed` + `tests/test-bemenu-themed.sh` into the Makefile
  `bash -n` and `shellcheck` lists and added the test to the `test` recipe; the
  `bind = SUPER, d, exec, bemenu-run` grep assertion is unchanged.
- Validation: `bash -n` OK; `shellcheck` OK; `bash tests/test-bemenu-themed.sh`
  passed. Full `make test` not run (orchestrator owns it). No commit made.
- Risk: TTY dispatch test depends on util-linux `script` (present here; not in the
  Makefile's required-tool list).

## Manual checks

- [ ] **4.4.1 appearance** (deferred, D6): with `--enable-bemenu-themed` installed,
      open `SUPER+D` under the active dark theme and one light theme; confirm the menu
      is centered and readable. Record monitor, themes, result.
