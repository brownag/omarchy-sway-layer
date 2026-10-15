---
id: "0005"
title: "Reorient Only a Clear Two-Window Pair, and Fail Closed Otherwise"
status: "Accepted"
date: 2026-10-14
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "planning/EXECUTION_PLAN_3.md; commits a3536c8 and f84cd16"
---

# 5. Reorient Only a Clear Two-Window Pair, and Fail Closed Otherwise

## Context and Problem Statement

Sway/i3 users expect a directional move across the current split axis of a two-window
layout to rearrange the two windows so the focused one lands on the requested side.
Hyprland does not expose Sway's container tree directly, and a geometric neighbor is not
necessarily the sibling in Hyprland's internal layout tree. Reorienting on a guessed
neighbor would mutate unrelated layouts and could move the wrong window.

The behavior is shared by the plain Hyprland configuration and the Omarchy Lua
integration. ADR-0001 originally scoped the installed-helper movement logic to Lua mode
and deferred plain-config parity; `planning/EXECUTION_PLAN_3.md` records explicit user
approval to extend the helper to the plain path.

## Decision Drivers

- Never rearrange a layout that is not unambiguously a two-window pair.
- Preserve the focused window's identity and place it on the requested side.
- Keep group semantics (`SUPER+SHIFT` join/leave) intact alongside pair behavior.
- Provide H/J/K/L and arrow aliases consistently across both integrations.
- Avoid introducing a new dependency; reuse the existing helper and `jq` probe.

## Considered Options

1. General layout rearrangement: infer and rewrite Hyprland's layout tree for any window
   count. Rejected: Hyprland does not expose a stable, documented tree, and ambiguous or
   multi-window layouts cannot be rearranged safely.
2. Treat any geometric neighbor as the pair partner. Rejected: a geometric neighbor may
   not be the layout sibling, so a reorientation could move the wrong windows.
3. Act only on a *clear pair* and fail closed otherwise. Chosen: exactly two visible,
   mapped, ungrouped, non-floating tiled clients on the workspace with unambiguous
   axis-aligned geometry; anything else retains prior behavior.

## Decision Outcome

`scripts/sway-group-move` accepts a `lua|plain` mode plus a direction. When the active
window and the workspace form a clear two-window tiled pair, a move that crosses the
pair's split axis reorients the pair and places the focused window on the requested side
(down below, up above, right to the right, left to the left). This is placement, not a
swap. The transition toggles the pair split and then applies a mode-appropriate
directional swap only if needed, verifying orientation, side, and focus identity.

The clear-pair condition is conservative: exactly two tiled clients on the workspace,
all mapped and visible, none grouped and none floating, with geometry that is
axis-aligned on exactly one axis. Any additional, hidden, unmapped, grouped, floating,
or ambiguous tiled state fails closed to the pre-existing mode-specific path (Lua group
join/leave/swap, plain native `movewindow`). Same-axis moves never reorient. H/J/K/L and
arrow keys are equivalent for focus and movement in both integrations.

By explicit user approval this extension applies to the plain Hyprland path as well,
superseding ADR-0001's plain-config deferral while preserving ADR-0001's installed-helper
boundary and ADR-0002/ADR-0003's probe and dispatch contracts.

### Consequences

- **Positive:** Predictable, non-destructive behavior: only an unambiguous pair is
  rearranged, and the focused window always ends on the requested side.
- **Positive:** Group join/leave semantics and same-axis movement are unchanged.
- **Negative:** No general layout rearrangement; layouts beyond a clear pair (including
  three or more tiled windows) keep their previous behavior and may not match Sway.
- **Negative:** The heuristic is coupled to the observed Hyprland client JSON shape
  (`at`, `size`, `workspace.id`, `grouped`, `mapped`, `hidden`, `floating`); runtime
  schema changes require compatibility work.

## Validation & Compliance

`a3536c8` implements the `lua|plain` mode and clear-pair decision in
`scripts/sway-group-move`, adds arrow aliases to `config/hypr/binds_sway.conf` and
`config/hypr/binds_sway.lua`, and adds boundary fixtures (all four cross-axis
transformations, same-axis/floating/grouped/multi-window/no-neighbor, query failures) to
`tests/test-sway-group-move.sh`. `f84cd16` documents the non-swap semantics and the
verification limits. `planning/STATE_3.md` records four authorized Lua-dispatch
cross-axis cases verified live on Hyprland 0.56.2 with disposable windows; plain-mode
dispatch, same-axis/non-pair behavior, and resize mode were not live-tested, and this
record does not claim universal Sway equivalence.
