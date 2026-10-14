---
id: "0001"
title: "Implement Contextual Group Movement in an Installed Omarchy Helper"
status: "Accepted"
date: 2026-10-13
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "EXECUTION_PLAN_2; commits 202f3194fe4bfd2ced6a0ff046eece083dc29a61 and 3a21f4ab11334af3cbb68affffa0fd88265e4354"
---

# 1. Implement Contextual Group Movement in an Installed Omarchy Helper

## Context and Problem Statement

The Omarchy Lua binding layer needs contextual directional movement, but the implementation should remain independent of the repository checkout after installation and testable apart from key registration.

Commit `202f319` introduced `scripts/sway-group-move`, invoked it from the Lua bindings, and added it to the managed install/dry-run/uninstall lifecycle. The plan explicitly targeted Omarchy Lua mode and deferred the plain-config path (`planning/EXECUTION_PLAN_2.md`). Neighbor inspection and dispatch interface decisions are recorded separately in ADR-0002 and ADR-0003.

## Decision Drivers

- Runtime behavior must work when installed independently of the source checkout.
- Key registration should stay in the Omarchy Lua configuration while context selection remains separately testable.
- Installation, dry-run, and uninstall should consistently manage the helper.

## Considered Options

1. Bind a single fixed Hyprland dispatcher for all directional key events. Rejected because the intended action depends on group and neighbor state.
2. Put all state inspection and branching directly in Lua bindings. Not chosen; a separate executable helper provides a clear test and deployment boundary for this stateful logic.
3. Install and invoke a standalone helper from the managed Omarchy Lua bindings. Chosen. Query client geometry/group state and select the contextual action.
4. Keep the helper in the source checkout and reference it at runtime. Rejected because the installed layer should work independently of the checkout.

## Decision Outcome

Contextual directional movement is implemented in a separately testable helper installed under the user's Hyprland configuration directory and invoked by Omarchy Lua bindings. The helper owns contextual action selection; the neighbor-inspection approach is recorded in ADR-0002, and dispatch calls follow ADR-0003.

By explicit user approval in Execution Plan 3, the helper also supports conservative cross-axis reorientation for a clear two-window tiled pair when invoked from the plain Hyprland bindings. This approved extension supersedes the earlier deferral of plain-config parity. It does not broaden the helper into general layout rearrangement: same-axis moves and arrangements that do not meet the clear-pair condition retain their mode-specific fallback behavior.

### Consequences

- **Positive:** Context-selection logic can be tested independently; runtime use does not depend on source-tree paths; helper install/dry-run/uninstall are part of the managed lifecycle.
- **Negative:** The solution has an additional installed executable and its lifecycle must remain synchronized with the binding configuration.
- **Negative:** The helper is coupled to the observed Hyprland client JSON shape; changes to that runtime surface require compatibility work and validation.
- **Trade-off:** The original Lua-only scope has been extended by explicit user approval to include plain-config cross-axis pair reorientation. The separately installed helper remains the contextual-action boundary; this limited parity does not provide general layout rearrangement or exact Sway container semantics.

## Validation & Compliance

The decision is reflected in `config/hypr/binds_sway.lua`, `config/hypr/binds_sway.conf`, `scripts/sway-group-move`, and `bin/apply-sway-layer`. `tests/test-sway-installer.sh` covers the managed helper lifecycle; movement behavior is covered by `tests/test-sway-group-move.sh`. Task 3.1.1 live verification covered four Lua-dispatch pair transformations only; plain dispatch, same-axis/non-pair behavior, and resize mode were not live-tested. This ADR records the helper boundary and approved scope extension, not a claim of universal compatibility across Omarchy/Hyprland versions.
