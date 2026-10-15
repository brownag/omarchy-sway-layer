# Git history evolution digest

## Scope and method

Studied `master` from the initial commit `6347d96` through HEAD `7d7e136`, using
additions of `planning/EXECUTION_PLAN_*.md` as milestones. There are no tags and no
merge commits, so plan creation is the only available boundary signal. The
`planning/EXECUTION_PLAN_*.md` pattern yields three boundaries (`8796e88`,
`4c5c08a`, `cc5c4ed`); the repository root and `HEAD` are added to close the first and
last intervals.

Four intervals result:

- **I0** `6347d96..8796e88` — bootstrap (compatibility layer, behavior docs, plans 1–2)
- **I1** `8796e88..4c5c08a` — Plan 2 completion + Plan 3 (group movement, pair reorientation, resize)
- **I2** `4c5c08a..cc5c4ed` — Plan 4 planning + LICENSE/README
- **I3** `cc5c4ed..7d7e136` — Plan 4 execution (themed bemenu wrapper, opt-in install, hotfix)

Commits are ordered topologically/reverse-chronologically within each interval;
diffs are rename-aware (`-M`). Machine-readable records are in `interval-ledger.json`.

> **Tooling note.** `interval_ledger.js` only appends root/HEAD when fewer than two
> pattern boundaries exist. With three boundaries it emitted just the two interior
> intervals (`I1`, `I2`), dropping the bootstrap and the entire Plan 4 execution. The
> ledger and this digest were assembled from one `--pattern` run plus `--range`
> runs for `root..8796e88` and `cc5c4ed..HEAD`, then merged.

## Interval overview

| Interval | Span | Commits | Churn | Commit types | Readout |
|---|---|---:|---:|---|---|
| `I0` | `6347d96..8796e88` | 3 | +1,575 / -0 · 23 files | feat 1, docs 2 | Bootstrap: installer, bindings, Waybar/Quickshell config, and Plans 1–2. Not a development interval. |
| `I1` | `8796e88..4c5c08a` | 13 | +1,583 / -69 · 30 files | docs 7, feat 3, fix 3 | The densest interval. Context-aware group movement, Lua-dispatch correction, ADRs 0001–0003, command-runner binding, conservative pair reorientation + modal resize, and test/onboarding scaffolding. |
| `I2` | `4c5c08a..cc5c4ed` | 3 | +869 / -92 · 6 files | docs 3 | Planning-heavy: LICENSE, README refresh, Plan 4 + bemenu research. Almost no code. |
| `I3` | `cc5c4ed..7d7e136` | 6 | +755 / -20 · 15 files | feat 2, docs 2, test 1, fix 1 | Plan 4 execution: themed bemenu wrapper, opt-in installer path, ADR 0004, theme-fidelity fixtures, and the null-stdin hotfix. |

Total: 25 commits, +4,782 / −181 lines across 74 file-touches.

## Subsystem evolution matrix

Approximate line churn aggregated by top-level directory (add+delete).

| Subsystem | I0 | I1 | I2 | I3 | Interpretation |
|---|---:|---:|---:|---:|---|
| `bin/` (installer CLI) | 293 | 6 | 0 | 108 | Established in I0; modelled helper lifecycle in I1; gained the opt-in `bemenu-themed` install/rewrite path in I3. |
| `config/` (Hypr/waybar/quickshell) | 248 | 81 | 0 | 0 | Binding surfaces stabilized after I1; no binding edits across I2–I3. |
| `scripts/` | 105 | 201 | 0 | 66 | Helper logic (`sway-group-move`) carried I1; `bemenu-themed` wrapper added in I3. |
| `tests/` | 0 | 441 | 0 | 281 | Test suite created in I1; expanded with theme-fidelity + installer coverage in I3. Largest sustained investment. |
| `planning/` | 764 | 554 | 729 | 212 | Plans/state dominate early intervals; decreases as execution closes out. |
| `docs/` (ADRs) | 0 | 149 | 0 | 89 | ADRs 0001–0003 in I1, ADR 0004 + index update in I3. |
| `README.md` | 107 | 35 | 124 | 10 | Rewritten progressively to match behavior; stabilized by I3. |
| `Makefile` | 31 | 24 | 0 | 8 | Static-string and fixture assertions added alongside features. |
| `AGENTS.md` | 0 | 43 | 0 | 1 | Onboarding guide added in I1. |
| `LICENSE` | 0 | 0 | 108 | 0 | Added in I2. |
| `.scratch/` | 0 | 91 | 0 | 0 | Tracked history-study artifacts from I1. |

## Feature development and architectural shifts

1. **Bootstrap + explicit planning** (`I0`, `fc2eaa7`, `1ff1db8`, `8796e88`): installer,
   plain/Lua bindings, Waybar and Quickshell artifacts, behavior documentation, and
   Plans 1–2. The whole project shape lands in one docs/feat pair.

2. **Context-aware group movement in an installed helper** (`I1`, `202f319`):
   `scripts/sway-group-move` is introduced, invoked from the Lua bindings, wired into
   the installer lifecycle, and covered by tests. ADR-0001 records the helper boundary,
   ADR-0002 the read-only probe, ADR-0003 the dispatch contract.

3. **Runtime dispatch corrected** (`I1`, `3a21f4a`, `fee8d2f`): bare Hyprland
   dispatcher strings fail under the Omarchy Lua runtime, which parses the argument as
   Lua. The helper switches to `hl.dsp.*` expressions and gains directional
   group-exit follow-ups.

4. **Command runner bound** (`I1`, `5bf87b5`): `SUPER+D` runs `bemenu-run`, kept
   deliberately separate from Omarchy's `SUPER+Space` app menu.

5. **Conservative pair reorientation + modal resize** (`I1`, `a3536c8`, `f84cd16`):
   the helper accepts a `lua|plain` mode and reasons about a *clear pair* — exactly two
   visible, mapped, ungrouped, non-floating tiled clients with unambiguous axis-aligned
   geometry. A cross-axis move reorients the pair and places the focused window on the
   requested side (placement, not swap); everything else fails closed to prior
   behavior. Plain-config parity is an explicit user-approved extension superseding
   ADR-0001's deferral. Resize becomes a modal `SUPER+r` submap in both paths (H/J/K/L +
   arrows, 20-px steps, Return/Escape), with Lua mode adopting Hyprland's
   `hl.define_submap`/`hl.dsp.submap` API.

6. **Plan 4 planning** (`I2`): LICENSE, README refresh, bemenu theming research, and
   Plan 4. The wrapper design (live-read palette, opt-in install, binding rewrite) is
   fully specified before any code.

7. **Themed launcher shipped and repaired** (`I3`, `0447230`, `d300358`, `196c96c`,
   `a322984`): `scripts/bemenu-themed` reads the live Omarchy palette and execs bemenu
   centered; `--enable-bemenu-themed` installs it to the user bin dir and rewrites the
   *copied* managed binding; theme-fidelity fixtures lock palette channel order and
   contrast. The hotfix `a322984` replaces the `[[ -t 0 ]]` mode check with
   `[[ -p /dev/stdin || -f /dev/stdin ]]` after Hyprland `exec_cmd` was found to provide
   `/dev/null` stdin, which had silently produced an empty menu.

## Convergence assessment

- **I1 is divergent, I2 is a planning interlude, I3 is stabilizing.** The heaviest
  feature and interface churn sits in I1; I2 adds no runtime code; I3 adds a
  self-contained feature plus its install path and tests.
- **Interfaces are converging.** Binding files (`config/hypr/*`) are untouched across
  I2–I3. The installer gained one additive opt-in flag and a `replace_line`/`replace_text`
  rewrite, not a redesign. The helper's mode/side contract is stable since `a3536c8`.
- **Validation is maturing.** `tests/` is the largest recurring subsystem (441 + 281
  lines). The progression `feat`/`fix`-heavy I1 → `test`+`docs` in I3 matches a
  stabilize-after-build pattern.
- **Still not fully converged at HEAD.** `a322984` is a genuine runtime-behavior fix
  landing at the tip, and `STATE_3` explicitly leaves plain-mode dispatch, same-axis
  behavior, and resize mode without live verification. Treat runtime claims as bounded
  by the recorded evidence.

## ADR-distillation feed

Records **already present** before this study: 0001 (installed helper boundary),
0002 (read-only client probes), 0003 (Omarchy Lua dispatch expressions), 0004
(live-read themed bemenu wrapper). Note that 0004 records how bemenu is *themed*; it
does not record the earlier choice *of* bemenu as the launcher. The candidates below
are the undocumented enduring decisions that survived the architecture-vs-churn filter.

### Candidate 0005 — Conservative clear-pair reorientation in both integrations

- **Evidence:** `a3536c8` (`feat: add directional pair reorientation and resize mode`)
  adds `lua|plain` mode handling and the clear-pair `jq` decision to
  `scripts/sway-group-move`, arrow aliases and `SUPER+r` to `config/hypr/binds_sway.conf`
  and `binds_sway.lua`, and boundary fixtures to `tests/test-sway-group-move.sh`.
  `f84cd16` documents the non-swap selected-side semantics and the live-test limits.
  `planning/EXECUTION_PLAN_3.md` (decision log 2026-10-14) records the user approvals.
- **Rationale:** general layout rearrangement is unsafe/ambiguous in Hyprland's tree;
  the helper acts only on an unambiguous two-window pair and fails closed otherwise.
- **Trade-off:** narrow behavior, no general rearrangement, and an extended plain-config
  scope that supersedes ADR-0001's deferral (cross-referenced, not superseding the ADR).

### Candidate 0006 — Choose bemenu-run as the `SUPER+D` command runner

- **Evidence:** `planning/RESEARCH_command-runner.md` surveys the candidates and
  recommends `fuzzel --dmenu`, names `bemenu-run` as the zero-glue alternative, and
  rejects `wofi --show drun` and X11 dmenu. `5bf87b5` (`feat: add bemenu command runner
  binding`) implements `bind = SUPER, d, exec, bemenu-run` and the Lua
  `hl.dsp.exec_cmd("bemenu-run")` binding, with the comment "Keep the arbitrary command
  runner separate from Omarchy's app menu on SUPER+SPACE", asserted in `Makefile` and
  `tests/test-sway-bindings.lua`.
- **Rationale:** a command runner is a distinct affordance from the `SUPER+Space` app
  menu; `bemenu-run` executes typed executables directly, whereas fuzzel's dmenu mode is
  a chooser needing glue; Wayland-native preferred over X11 dmenu.
- **Trade-off:** adopts `bemenu` as a runtime dependency and couples later work to its
  CLI surface (ADR-0004's theming wrapper is built on it).

### Candidate 0007 — Model modal keybindings as submaps in both integrations

- **Evidence:** `a3536c8` keeps the plain `submap = resize`/`submap = reset` block in
  `config/hypr/binds_sway.conf` and introduces the reusable Lua shape
  `hl.define_submap("resize", function() ... end)` + `hl.dsp.submap("reset")` in
  `config/hypr/binds_sway.lua`, replacing the earlier non-modal `SUPER+CTRL` resize
  chords. `tests/test-sway-bindings.lua` asserts submap registration, in-mode bindings,
  and exits generically.
- **Rationale:** a project-local `o.bind` submap option was rejected in favor of the
  runtime's own modal API, and a standing convention means the next modal mode (move,
  launch, selector) does not reinvent the mechanism. It is pattern-setting infrastructure,
  not just the resize feature.
- **Trade-off:** Lua correctness is coupled to Hyprland's Lua submap API, and runtime
  resize behavior was not live-tested; the convention mandates explicit Return/Escape
  exits so a mode cannot strand the user.

### Explicitly filtered out (evaluated, not minted)

- **`bemenu-themed` stdin-type dispatch fix** (`a322984`). Rejected as a standalone ADR:
  it is a correctness fix to ADR-0004's wrapper mechanism, not a new decision. Captured
  as a note in ADR-0006's outcome and in `planning/STATE_4.md`.
- Task/state micro-plans (`planning/tasks/*.todo.md`, `STATE_N.md`) and plan-file
  creation — process artifacts, not architecture.
- Shellcheck cleanup (`ae4492b`), LICENSE addition (`97088df`), README edits, and the
  tracked `.scratch/` history-study artifacts.
- Test-run logs, contrast ratios, and live-test geometry captures in `STATE_3`/`STATE_4`
  — evidence, not decisions.
