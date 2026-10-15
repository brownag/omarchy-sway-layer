---
id: "0006"
title: "Use bemenu-run as the SUPER+D Command Runner"
status: "Accepted"
date: 2026-10-13
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "planning/RESEARCH_command-runner.md; commit 5bf87b5; hotfix a322984"
---

# 6. Use bemenu-run as the SUPER+D Command Runner

## Context and Problem Statement

The layer had no `SUPER+D` binding. Omarchy maps `SUPER+Space` to an application menu,
but this Sway-style layer also wants a launch prompt for arbitrary executables typed by
name — a dmenu-style command runner. Several launchers provide such a mode, and the
choice determines the runtime dependency, the binding shape, whether glue code is
needed, and what a later theming wrapper (ADR-0004) can be built on.

`planning/RESEARCH_command-runner.md` surveyed the candidates. The research recommended
`fuzzel --dmenu` as the practical default, named `bemenu-run` as a simpler alternative,
and rejected `wofi --show drun` for this purpose.

## Decision Drivers

- Provide a command runner, distinct from Omarchy's `SUPER+Space` application menu.
- Prefer a Wayland-native launcher over X11 `dmenu` in a Hyprland session.
- Minimize glue: the chosen tool should turn typed input into an executed command
  without a custom launcher helper.
- Keep the binding a single executable with no shell-string concatenation.
- Leave room for optional theming without repointing the default source binding.

## Considered Options

1. `fuzzel --dmenu`. Research-recommended default. Not chosen: dmenu mode is a
   chooser/selection protocol, not a runner — its output still needs a helper to
   capture and execute, adding glue and shell-semantics decisions for the runner path.
2. `wofi --show drun` / fuzzel's app launcher. Rejected: drun discovers desktop
   applications, duplicating the `SUPER+Space` app menu rather than running arbitrary
   executables.
3. X11 `dmenu` / `dmenu_run`. Rejected: X11 under a Wayland session; less appropriate
   for this environment.
4. `bemenu-run`. Chosen: a Wayland-native, dmenu-compatible runner that resolves and
   executes the typed executable directly, giving a zero-glue command-runner UX and a
   simple `exec` binding.

## Decision Outcome

`SUPER+D` runs `bemenu-run` as a standalone command runner. It is bound in both
integrations: `bind = SUPER, d, exec, bemenu-run` in `config/hypr/binds_sway.conf` and
`hl.dsp.exec_cmd("bemenu-run")` under the `SUPER + D` registration in
`config/hypr/binds_sway.lua`. The source and default bindings stay on `bemenu-run`.

The binding is intentionally separate from Omarchy's `SUPER+Space` application menu;
both affordances remain available, and the runner is not repointed at the app menu. The
optional themed wrapper (ADR-0004) repoints the *copied* managed binding at install time
for opted-in users; it does not change the source binding.

Because the runner is launched by Hyprland `exec_cmd`, which provides `/dev/null` stdin
(no TTY), any wrapper must select runner mode by stdin type rather than by
`[[ -t 0 ]]`; the `bemenu-themed` wrapper's contract is owned by ADR-0004.

### Consequences

- **Positive:** A zero-glue command runner: `bemenu-run` lists and executes commands
  directly, with no launcher helper or shell-evaluation glue.
- **Positive:** `SUPER+D` (command runner) and `SUPER+Space` (app menu) remain distinct.
- **Positive:** A Wayland-native dependency; the later theming wrapper builds on
  bemenu's flag surface without adding a second launcher.
- **Negative:** `bemenu` is now a runtime dependency; `bemenu-run` must be on the session
  `PATH`, and the installer warns when the wrapper's bin directory is not.
- **Trade-off:** `fuzzel --dmenu` offers a stronger fuzzy-selection UI, but only with a
  helper to execute the selection; `bemenu-run`'s direct runner behavior was judged the
  better fit for this layer.
- **Negative:** The binding and wrapper are coupled to bemenu's CLI surface; version or
  option changes on the target require compatibility work.

## Validation & Compliance

`5bf87b5` adds the binding to `config/hypr/binds_sway.conf` and
`config/hypr/binds_sway.lua` and asserts it in the `Makefile` test recipe and
`tests/test-sway-bindings.lua`. `planning/RESEARCH_command-runner.md` records the
candidate survey and the fuzzel/wofi/dmenu trade-offs. The ensuing theming work and the
`/dev/null`-stdin hotfix are recorded separately in ADR-0004 and `planning/STATE_4.md`.
No live compositor comparison of bemenu against the alternatives was performed; the
choice rests on the documented tool behavior and the zero-glue runner requirement.
