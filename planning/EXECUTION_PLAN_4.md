# EXECUTION_PLAN_4 — Themed, centered bemenu wrapper for the Sway layer

## Goal & Scope

Ship an opt-in, theme-aware, centered `bemenu` launcher for Omarchy users of this
Sway-style Hyprland layer. A self-contained wrapper (`bemenu-themed`) reads the
active Omarchy palette on every invocation and runs `bemenu`/`bemenu-run` centered
with matching colors. Installing it is opt-in (`--enable-bemenu-themed`), which also
repoints the managed `SUPER+D` binding at install time. Default installs are
unchanged, and both the source binding and the `make test` literal assertion stay
`bemenu-run`.

**In scope (from `planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`, workstreams W1–W4):**
- W1: `scripts/bemenu-themed` wrapper + tests.
- W2 (installer): opt-in flag that installs the wrapper to the user bin dir and
  rewrites the managed binding; backup/uninstall/dry-run coverage.
- W3 (docs): README + ADR 0004 + index.
- W4: theme-fidelity validation fixtures and contrast check.

**Out of scope (explicit deferrals):**
- A `~/.config/omarchy/themed/bemenu.tpl` template or a `theme-set` hook. Rejected in
  research: the live-read wrapper makes both unnecessary (ADR 0004).
- Changes to `/usr/share/omarchy` or `~/.local/share/omarchy` (never touched by this
  repo).
- Changing the default/source `SUPER+D` binding: it stays `bemenu-run` unless the user
  opts in.
- Any non-bemenu launcher, and any new runtime dependency beyond `bemenu`,
  `omarchy-theme-color`, and standard coreutils.

**Verbatim constraints:**
- D1: "opt-in install" mirroring `--enable-waybar`.
- D2: "the opt-in flag installs the wrapper and rewrites the managed binding."
- D3: honor `${XDG_BIN_HOME}` else `$HOME/.local/bin`; "verify the directory is on
  `PATH` and warn if not" (not a hard failure).
- D6: "targeted test per task, full `make test` per wave, rendered appearance a
  recorded manual check in STATE_4.md."
- D7: single writer, sequential waves, no worktrees.
- D8: all worker tasks on `opencode-go/deepseek-v4.1-flash` with thinking `low`.

## Decision log

- **2026-10-15 — D1 Install scope: opt-in.** The wrapper ships in `scripts/` and is
  installed to the user bin dir only under `--enable-bemenu-themed`. Rationale: repo
  posture is opt-in for non-binding extras; a new managed path outside `$CONFIG_HOME`
  is the riskiest part and stays explicit. Rejected: auto-install; docs-only.
- **2026-10-15 — D2 Binding: opt-in flag rewrites the managed binding at install
  time.** Source `binds_sway.conf`/`binds_sway.lua` and the `make test` literal
  assertion stay `bemenu-run`; the installer rewrites the *copied* managed files only
  when the flag is set. Rationale: keeps default installs and existing assertions
  valid, gives opt-in users a working binding without hand-editing. Rejected:
  unconditional repoint (breaks non-opted-in users, contradicts D1); manual-only
  repoint.
- **2026-10-15 — D3 Bin path: `${XDG_BIN_HOME:-$HOME/.local/bin}`, warn if not on
  `PATH`.** Mirrors the installer's `${XDG_CONFIG_HOME:-…}` pattern; a `PATH` problem
  surfaces at install time as a warning, not a hard fail (the dir may be added by a
  login shell the installer cannot see).
- **2026-10-15 — D4 One plan (orchestration 4).** The opt-in flag is the only thing
  that activates the binding change, so splitting would ship a wrapper nothing invokes.
- **2026-10-15 — D5 ADR `0004`, Accepted.** Records the live-read-wrapper-over-
  template/hook decision as an enduring constraint.
- **2026-10-15 — D6 Acceptance: targeted test per task; `make test` per wave;
  appearance manual.** Rendered appearance is environment-dependent (font, monitor,
  GPU); screenshot-gating would be brittle. W4 records a manual result.
- **2026-10-15 — D7 Single writer, sequential waves, no worktrees.** Small repo,
  shared `Makefile`; parallel coordination overhead exceeds benefit.
- **2026-10-15 — D8 Worker model `opencode-go/deepseek-v4.1-flash` at thinking
  `low`.** Operator choice; tasks are small and self-contained. Escalation (per the
  wave-orchestration ladder) falls back to the orchestrator's model,
  `openai/gpt-6-luna`.

## Reconciled facts (hazards for workers)

- The `Makefile` `test` target asserts the literal
  `grep -Fq 'bind = SUPER, d, exec, bemenu-run' config/hypr/binds_sway.conf`. This
  assertion MUST remain valid because the source binding is unchanged (D2).
- `bin/apply-sway-layer` copies managed files into `$CONFIG_HOME` via
  `write_managed_files()`, enumerates the same set in `show_managed_file_diffs()` and
  `uninstall_layer()`. The wrapper target lives **outside** `$CONFIG_HOME`.
- `scripts/backup.sh` snapshots `$CONFIG_HOME/{hypr,waybar,quickshell}` only; the
  user-bin wrapper needs its own snapshot entry for rollback fidelity.
- `binds_sway.lua` is copied to `$CONFIG_HOME/hypr/sway_bindings.lua`; rewrite the
  copied target, never the source.
- Installed `bemenu` is `0.6.23`, option surface identical to upstream master
  (verified). Use only documented flags.
- `bemenu` applies `BEMENU_OPTS` before argv, so the wrapper's CLI flags win; do not
  add an `unset`.
- Color values are standard CSS hex (`#RRGGBB`); the renderer compensates for
  bemenu's internal channel storage, so pass values verbatim.

## Wave table

| Wave | Task | Depends on | Files in scope |
| --- | --- | --- | --- |
| 1 | 4.1.1 Wrapper core + test | — | `scripts/bemenu-themed` (new), `tests/test-bemenu-themed.sh` (new), `Makefile` |
| 2 | 4.2.1 Opt-in install + binding rewrite + backup/uninstall | 4.1.1 | `bin/apply-sway-layer`, `scripts/backup.sh`, `tests/test-sway-installer.sh` |
| 3 | 4.3.1 Docs + ADR 0004 | 4.2.1 | `README.md`, `AGENTS.md`, `docs/decisions/README.md`, `docs/decisions/0004-live-palette-wrapper-for-bemenu.md` (new) |
| 4 | 4.4.1 Theme-fidelity fixtures + contrast | 4.1.1 | `tests/test-bemenu-themed.sh` |

One task per wave (D7 single writer). Wave 4 re-touches the Wave 1 test file, which is
safe because waves are sequential.

---

## Task specs

### 4.1.1 — Implement `scripts/bemenu-themed` and its test

- **Repo:** omarchy-sway-layer
- **Files in scope — must edit:** `Makefile`
- **Files in scope — can create:** `scripts/bemenu-themed`,
  `tests/test-bemenu-themed.sh`. Scratch: `/tmp`.
- **Do not touch:** `config/**`, `bin/apply-sway-layer`, `scripts/backup.sh`,
  `docs/**`, `tests/test-sway-installer.sh`.
- **Depends on:** none.
- **Spec prose:** Create an executable bash wrapper that:
  1. Resolves the palette file from `${OMARCHY_THEME_COLORS:-$HOME/.local/state/omarchy/current/theme/colors.toml}`.
  2. Defines `omarchy_color key fallback` that prefers
     `omarchy-theme-color --file "$colors_file" "$key" "$fallback"` when on `PATH`,
     and falls back to a direct `sed` read of `colors.toml` (quoted value; must
     capture the leading `#`), else the fallback.
  3. Maps keys to flags: `--nb=background`, `--nf=foreground`,
     `--hb=--sb=selection_background`, `--hf=--sf=bright_foreground`,
     `--tb=background`, `--tf=foreground`, `--fb=background`, `--ff=accent`,
     `--cb=accent`, `--cf=background`, `--fbb=background`, `--fbf=muted`,
     `--ab=lighter_background`, `--af=muted`, `--scb=darker_background`,
     `--scf=muted`.
  4. Adds geometry `-c -l "${BEMENU_LINES:-10}" --fixed-height
     -W "${BEMENU_WIDTH:-0.4}" -M "${BEMENU_MARGIN:-8}"
     -B "${BEMENU_BORDER:-2}" -R "${BEMENU_RADIUS:-8}"
     -H "${BEMENU_LINE_HEIGHT:-26}"` and
     `--fn "${BEMENU_FONT:-JetBrainsMono Nerd Font 12}"`.
  5. `exec`s `bemenu-run` when stdin is a TTY (`[[ -t 0 ]]`), else `bemenu`, passing
     `"$@"`. Use `set -euo pipefail`.
- **Reference implementation:** the wrapper block in
  `planning/RESEARCH_BEMENU_OMARCHY_THEMING.md` ("Solution design").
- **Test (`tests/test-bemenu-themed.sh`):** must run without a Wayland session. Put
  stub `bemenu`/`bemenu-run` (echo `"$@"`) and a stub `omarchy-theme-color` in a
  temp dir on `PATH`; source/execute the wrapper and assert: centered + themed flags
  present; palette values mapped for each region; direct-read fallback works when the
  resolver is absent; TTY path selects `bemenu-run` and piped path selects `bemenu`.
  Follow the structure of `tests/test-sway-installer.sh` (temp dir, `fail()` helper,
  `trap` cleanup).
- **Makefile wiring:** add `scripts/bemenu-themed` and `tests/test-bemenu-themed.sh`
  to the `bash -n` list and the `shellcheck` list, and add
  `bash tests/test-bemenu-themed.sh` to the `test` recipe. Do NOT change the
  `bemenu-run` grep assertion.
- **Grep anchors:** `Makefile` occurrences of `bash -n bin/apply-sway-layer`,
  `shellcheck bin/apply-sway-layer`, `bash tests/test-sway-installer.sh`.
- **Acceptance:** `bash tests/test-bemenu-themed.sh` passes; `make test` green.

### 4.2.1 — Opt-in installer support: wrapper install, binding rewrite, backup/uninstall

- **Repo:** omarchy-sway-layer
- **Files in scope — must edit:** `bin/apply-sway-layer`, `scripts/backup.sh`,
  `tests/test-sway-installer.sh`
- **Files in scope — can create:** `${XDG_BIN_HOME:-$HOME/.local/bin}/bemenu-themed`
  (Installed at runtime by the opt-in path; the repo source is the existing
  `scripts/bemenu-themed`. Test scratch/fixtures under `/tmp`.)
- **Scratch:** `/tmp`
- **Do not touch:** `scripts/bemenu-themed`, `Makefile`, `config/**`, `tests/test-bemenu-themed.sh`, `docs/**`.
- **Depends on:** 4.1.1 (wrapper path and contract).
- **Spec prose:** Add an install-only flag `--enable-bemenu-themed` (mirror
  `--enable-waybar` handling in `parse_args`/`install_layer`). When set:
  1. `BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}`; copy
     `scripts/bemenu-themed` to `$BIN_HOME/bemenu-themed`, `chmod +x`.
  2. After `write_managed_files` copies the configs, rewrite the copied binding:
     in `$CONFIG_HOME/hypr/binds_sway.conf` replace the exact line
     `bind = SUPER, d, exec, bemenu-run` with `bind = SUPER, d, exec, bemenu-themed`,
     and in `$CONFIG_HOME/hypr/sway_bindings.lua` replace `bemenu-run` with
     `bemenu-themed`. Add a reusable exact-line replace helper (adjacent to
     `ensure_line`/`remove_line`); never edit the repo source files.
  3. Warn on stderr when `$BIN_HOME` is not in `PATH` (colon-split check; no hard
     fail). Do NOT warn during `--dry-run` for state that isn't written.
  4. In `--dry-run`, print the wrapper diff (new/existing) and the rewritten binding
     diff. Default install (flag absent) must not create the wrapper and must leave
     the binding `bemenu-run`.
  5. In `--uninstall`, remove `$BIN_HOME/bemenu-themed`. In `scripts/backup.sh`,
     snapshot an existing `$BIN_HOME/bemenu-themed` into the backup dir and record it
     in `manifest.txt` so `--rollback` restores or removes it; keep existing
     HYPR/WAYBAR/QUICKSHELL behavior intact.
- **Hazards:** `binds_sway.lua` is copied as `sway_bindings.lua` — rewrite the copied
  target. Keep `set -euo pipefail`; use the existing `fail()`.
- **Grep anchors:** `parse_args`, `ENABLE_WAYBAR`, `write_managed_files`,
  `show_managed_file_diffs`, `uninstall_layer`, `CURRENT` vars in `scripts/backup.sh`.
- **Acceptance:** extend `tests/test-sway-installer.sh` with cases — default install
  creates no wrapper and keeps `bemenu-run`; `--enable-bemenu-themed` creates
  `$BIN_HOME/bemenu-themed` and rewrites both copied bindings; `--dry-run` prints
  wrapper + binding diffs; `--uninstall` removes the wrapper; missing-`PATH` warning
  emitted. `bash tests/test-sway-installer.sh` and `make test` green.

### 4.3.1 — Document the wrapper and record ADR 0004

- **Repo:** omarchy-sway-layer
- **Files in scope — must edit:** `README.md`, `AGENTS.md`, `docs/decisions/README.md`,
  `Makefile`
- **Files in scope — can create:** `docs/decisions/0004-live-palette-wrapper-for-bemenu.md`
- **Do not touch:** everything else.
- **Depends on:** 4.2.1 (final flag/path contract).
- **Spec prose:**
  1. `README.md`: update the `SUPER+D` note to state it runs `bemenu-run` by default;
     add a short section for `--enable-bemenu-themed` — installs a theme-aware,
     centered `bemenu-themed` wrapper to the user bin dir, repoints `SUPER+D`, and is
     removed by `--uninstall`; note the wrapper reads the live Omarchy palette so it
     follows theme changes with no hook.
  2. `AGENTS.md`: add `scripts/bemenu-themed` to the "Find Things" inventory.
  3. New ADR `0004-live-palette-wrapper-for-bemenu.md`: status Accepted, date
     2026-10-15, context `planning/EXECUTION_PLAN_4.md`,
     `planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`. Decision: theme bemenu with a
     live-read runtime wrapper rather than a `themed/*.tpl` template or a `theme-set`
     hook; install is opt-in and repoints the managed binding at install time.
     Consequences: no staleness, no write outside the user bin/config; source binding
     stays `bemenu-run`. Match the structure of `docs/decisions/0003-*.md`.
  4. Add a row for 0004 to `docs/decisions/README.md` (Status Accepted, no supersedes,
     Context `planning/EXECUTION_PLAN_4.md`).
- **Grep anchors:** `README.md` line containing `bemenu-run`; `AGENTS.md` "Find Things"
  list; `docs/decisions/README.md` table; `docs/decisions/0003-*.md` headings.
- **Acceptance:** add these assertions to the `Makefile` test recipe (targeted
  check): `grep -Fq -- '--enable-bemenu-themed' README.md`,
  `grep -Fq '0004-live-palette-wrapper-for-bemenu' docs/decisions/README.md`, and
  `grep -Fq 'scripts/bemenu-themed' AGENTS.md`; then `make test` green.

### 4.4.1 — Theme-fidelity fixtures and contrast validation

- **Repo:** omarchy-sway-layer
- **Files in scope — must edit:** `tests/test-bemenu-themed.sh`
- **Files in scope — can edit (report only):** `planning/STATE_4.md`
- **Scratch:** `/tmp`
- **Do not touch:** everything else.
- **Depends on:** 4.1.1.
- **Spec prose:** Add two `colors.toml` fixtures (a dark and a light palette) to the
  test. For each, run the wrapper with `OMARCHY_THEME_COLORS` pointing at the fixture
  and the stub renderer, and assert every mapped flag carries the fixture value
  verbatim (guards channel-order/verbatim assumptions). Also compute and record the
  contrast ratio of `--hf` (`bright_foreground`) on `--hb` (`selection_background`)
  for each fixture as informational output — no pass/fail threshold. Record the
  manual visual result (monitor, theme, outcome) in the `## 4.4.1` report in
  `planning/STATE_4.md`.
- **Grep anchors:** the assertion helpers/flag dump already in
  `tests/test-bemenu-themed.sh` from 4.1.1.
- **Acceptance:** `bash tests/test-bemenu-themed.sh` passes; `make test` green.

---

## Worker execution notes

- One worker per wave (D7); spawn on `opencode-go/deepseek-v4.1-flash:low` (D8).
  On the escalation ladder (acceptance fails after one retry, or malformed reports),
  re-run the task on the orchestrator model `openai/gpt-6-luna`.
- Each worker produces `planning/tasks/4.W.1.todo.md`, waits for `APPROVED -- execute
  the plan as written.`, then executes and appends a <=15-line report to
  `planning/STATE_4.md`.
- Orchestrator runs `make test` serially at each wave end and commits one commit per
  task (conventional format, one sentence, no orchestration/wave numbers).
- Escalation ladder per wave-orchestration: off-spec micro-plan twice → orchestrator
  writes the TODO; acceptance fails after one retry → re-run on a stronger model.
