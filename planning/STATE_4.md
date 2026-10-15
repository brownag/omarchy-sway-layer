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
| 2 | 4.2.1 Opt-in install + binding rewrite + backup/uninstall | 4.1.1 | done |
| 3 | 4.3.1 Docs + ADR 0004 | 4.2.1 | done |
| 4 | 4.4.1 Theme-fidelity fixtures + contrast | 4.1.1 | done |

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

## 4.2.1

- `bin/apply-sway-layer`: added `--enable-bemenu-themed` (install-only guard mirroring
  `--enable-waybar`), `BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}`, reusable
  `replace_line` (exact line) / `replace_text` (literal substring) helpers,
  `rewrite_bemenus`, and `bin_home_in_path`/`warn_bin_home_not_in_path` (stderr,
  no hard fail; not emitted on `--dry-run`).
- Install: copies `scripts/bemenu-themed` -> `$BIN_HOME/bemenu-themed` (`chmod +x`),
  rewrites the *copied* `binds_sway.conf`/`sway_bindings.lua`; uninstall removes the
  wrapper; dry-run prints wrapper + rewritten-binding diffs (reuses the replace
  helpers on temp copies so preview can't drift).
- `scripts/backup.sh`: snapshots `$BIN_HOME/bemenu-themed` and records
  `BEMENU_PRESENT`/`BEMENU_SOURCE`; `rollback_layer` gained an explicit `BEMENU)`
  branch; HYPR/WAYBAR/QUICKSHELL behavior unchanged.
- `tests/test-sway-installer.sh`: adds default-install (no wrapper, binding stays
  `bemenu-run`), opt-in install (wrapper + both bindings rewritten, repo sources
  intact), dry-run diff, missing-`PATH` warning, and uninstall-removes-wrapper cases.
- Validation: `bash -n` OK; `shellcheck` OK; `bash tests/test-sway-installer.sh`
  passed; scratch backup/rollback verified both present=1 restore and pre-install
  present=0 removal. Full `make test` not run (orchestrator owns it). No commit made.

## 4.3.1

- `README.md`: `SUPER+D` note now says it runs `bemenu-run` **by default**; added an
  opt-in `--enable-bemenu-themed` block (installs `bemenu-themed` to
  `${XDG_BIN_HOME:-$HOME/.local/bin}`, repoints `SUPER+D`, removed by `--uninstall`,
  reads the live palette with no hook).
- `AGENTS.md`: added `scripts/bemenu-themed` to "Find Things".
- New `docs/decisions/0004-live-palette-wrapper-for-bemenu.md` (Accepted, 2026-10-15,
  0003 structure): live-read wrapper over `themed/*.tpl`/`theme-set` hook, opt-in
  install repoints the managed binding; source binding stays `bemenu-run`.
- `docs/decisions/README.md`: added the 0004 row (Accepted, no supersedes).
- `Makefile`: added the three doc grep assertions next to the existing `bemenu-run`
  config grep; that assertion is unchanged.
- Validation: all three new `grep -Fq` assertions exit 0; Makefile recipe structure
  intact. Full `make test` not run (orchestrator owns it). No commit made.

## 4.4.1

- `tests/test-bemenu-themed.sh`: added dark (`$tmp/dark-colors.toml`) and light
  (`$tmp/light-colors.toml`) palette fixtures plus `contrast_ratio` and
  `assert_palette_mapping` helpers.
- Each fixture runs through the wrapper with the resolver absent (isolated `$nobin`
  PATH -> direct `sed` read) and `OMARCHY_THEME_COLORS` at the fixture; all 18 mapped
  flags (`--nb/--nf/--hb/--sb/--hf/--sf/--tb/--tf/--fb/--ff/--cb/--cf/--fbb/--fbf/`
  `--ab/--af/--scb/--scf`) are asserted verbatim (guards channel-order/pass-through).
- Informational contrast (no threshold) of `--hf` on `--hb`: dark `#f7e8b2` on
  `#32473b` = 8.16:1; light `#002b36` on `#d8d2b8` = 9.89:1.
- Validation: `bash -n` OK; `shellcheck` OK; `bash tests/test-bemenu-themed.sh` passed.
  Full `make test` not run (orchestrator owns it). No commit made.
- Manual visual check: NOT performed by the worker (cannot view the rendered menu).
  Environment for the human check: monitor `LVDS-1` (AU Optronics 0x315C), active
  theme `osaka-jade` (dark). Disposition: deferred to orchestrator/user.

## Manual checks

- [x] **4.4.1 appearance** (D6): confirmed by the user after the null-stdin hotfix
      (`a322984`). `SUPER+D` opens the centered, themed, searchable command list on
      monitor `LVDS-1` (AU Optronics 0x315C) under the active dark theme `osaka-jade`.
      A separate light-theme visual pass was not performed; the automated light
      fixture in `tests/test-bemenu-themed.sh` covers palette mapping and contrast
      (9.89:1).

## Discovered defects

### Hotfix: `SUPER+D` showed an empty menu under Hyprland

- **Symptom (reported at the manual check):** the centered box appeared and accepted
  text, but listed no commands and did nothing on Enter.
- **Root cause:** the wrapper dispatched with `[[ -t 0 ]]`. Hyprland `exec_cmd` runs
  the command with stdin at `/dev/null` (probed: `tty=no`, `link=/dev/null`), so the
  check was false and the wrapper ran plain `bemenu` with empty stdin instead of
  `bemenu-run`.
- **Fix:** dispatch on piped/redirected stdin instead — `[[ -p /dev/stdin || -f /dev/stdin ]]`
  selects `bemenu` (list mode); a terminal or `/dev/null` selects `bemenu-run`.
- **Regression test:** `tests/test-bemenu-themed.sh` now asserts `/dev/null` stdin
  selects `bemenu-run`, alongside the TTY and pipe cases.
- **Note:** the installed copy at `$BIN_HOME/bemenu-themed` is stale until the opt-in
  install is re-run (`./bin/apply-sway-layer --enable-bemenu-themed`).
