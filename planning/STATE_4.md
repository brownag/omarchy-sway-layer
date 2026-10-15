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
| 1 | 4.1.1 Wrapper core + test | — | pending |
| 2 | 4.2.1 Opt-in install + binding rewrite + backup/uninstall | 4.1.1 | pending |
| 3 | 4.3.1 Docs + ADR 0004 | 4.2.1 | pending |
| 4 | 4.4.1 Theme-fidelity fixtures + contrast | 4.1.1 | pending |

## Task reports

<!-- Workers append a <=15-line report under a "## <id>" heading here. -->

## Manual checks

- [ ] **4.4.1 appearance** (deferred, D6): with `--enable-bemenu-themed` installed,
      open `SUPER+D` under the active dark theme and one light theme; confirm the menu
      is centered and readable. Record monitor, themes, result.
