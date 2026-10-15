---
id: "0004"
title: "Theme bemenu with a Live-Read Runtime Wrapper"
status: "Accepted"
date: 2026-10-15
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "planning/EXECUTION_PLAN_4.md; planning/RESEARCH_BEMENU_OMARCHY_THEMING.md"
---

# 4. Theme bemenu with a Live-Read Runtime Wrapper

## Context and Problem Statement

Omarchy users of this Sway-style Hyprland layer run `SUPER+D` to launch a bemenu
launcher. Omarchy themes the rest of the desktop from a palette, but bemenu has no
config file: its colors, geometry, and font are command-line flags. The launcher
therefore does not follow the active Omarchy theme, and the unmodified `bemenu-run`
menu is not centered. The question is how to give the launcher theme-matched colors
and centered geometry without introducing staleness or a maintenance hook.

Two alternative mechanisms exist in the Omarchy theming pipeline. `omarchy-theme-set`
renders user templates from `~/.config/omarchy/themed/*.tpl` into the current theme
directory, and it fires `omarchy-hook theme-set`. Research (`planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`, facts C11–C14) shows the live palette lives at
`~/.local/state/omarchy/current/theme/colors.toml`, that a rendered `bemenu.tpl` would
be a static file inside the theme directory that bemenu never reads, and that a
`theme-set` hook fires only on change, not at login.

## Decision Drivers

- The launcher must reflect the active palette on every invocation, including login
  and theme changes, without staleness.
- Installation must not write outside the user's bin and config directories.
- The change should be opt-in, mirroring the existing `--enable-waybar` posture, and
  must leave default installs and the source binding untouched.
- The mechanism should avoid adding a hook or state that can drift from the palette.

## Considered Options

1. Render a `themed/bemenu.tpl` template at theme-set time. Rejected: bemenu reads no
   config file, so a rendered static file would still require a wrapper to consume it,
   and the rendered values could go stale between renders.
2. Install a `theme-set` hook that rewrites bemenu arguments on theme change. Rejected:
   it adds state that can drift, fires only on change (not at login), and writes
   outside the user bin/config directories.
3. Install a self-contained runtime wrapper that reads the live palette on each
   invocation and execs bemenu centered. Chosen.

## Decision Outcome

bemenu is themed by a live-read runtime wrapper rather than a `themed/*.tpl` template
or a `theme-set` hook. The wrapper resolves the palette from
`${OMARCHY_THEME_COLORS:-$HOME/.local/state/omarchy/current/theme/colors.toml}` on
every invocation, maps Omarchy palette keys to bemenu color flags, and applies centered
geometry and the default mono font before execing `bemenu-run` (TTY stdin) or `bemenu`.

Installation is opt-in via `--enable-bemenu-themed`. When set, the installer copies the
wrapper to `${XDG_BIN_HOME:-$HOME/.local/bin}/bemenu-themed` and rewrites the *copied*
managed binding to invoke it. The source binding and the default install keep
`bemenu-run`; the binding is repointed only at install time, for opted-in users. The
wrapper is removed by `--uninstall`.

## Consequences

- **Positive:** No staleness — each invocation reads the current palette, so theme
  changes need no hook and no re-render.
- **Positive:** No write outside the user bin directory and the managed config files;
  no Omarchy upstream file is touched.
- **Positive:** Default installs and the source `bemenu-run` binding are unchanged; the
  change is opt-in and reversible through `--uninstall` and rollback.
- **Negative:** The wrapper depends on the live palette path and `omarchy-theme-color`,
  so palette-layout or helper changes require compatibility work. A direct `sed`
  fallback covers a missing `omarchy-theme-color`.
- **Negative:** The managed binding is rewritten at install time, so the wrapper and
  binding lifecycle must stay synchronized.

## Validation & Compliance

`scripts/bemenu-themed` implements the live-read wrapper and `tests/test-bemenu-themed.sh`
covers palette mapping, the direct-read fallback, and TTY/piped dispatch.
`bin/apply-sway-layer` implements the opt-in install, binding rewrite, `PATH` warning,
dry-run preview, and uninstall removal, covered by `tests/test-sway-installer.sh`;
`scripts/backup.sh` snapshots the installed wrapper for rollback. The `make test`
recipe keeps asserting the source binding literal `bind = SUPER, d, exec, bemenu-run`.
Rendered appearance is environment-dependent and is recorded as a manual check in
`planning/STATE_4.md`, not gated by the automated tests.
