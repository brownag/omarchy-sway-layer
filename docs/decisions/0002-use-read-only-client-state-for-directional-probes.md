---
id: "0002"
title: "Use Read-Only Client State for Directional Probes"
status: "Accepted"
date: 2026-10-13
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "EXECUTION_PLAN_2; commit 202f3194fe4bfd2ced6a0ff046eece083dc29a61"
---

# 2. Use Read-Only Client State for Directional Probes

## Context and Problem Statement

Contextual directional movement must determine whether the active window has a grouped directional neighbor. A probe that changes focus before choosing an action risks leaving focus on the wrong window if the query, restoration, or later dispatch fails.

## Decision Drivers

- Neighbor inspection must not mutate active focus.
- Missing neighbors and query failures must not result in an unintended focus change.
- The selection logic should be testable against explicit client-state fixtures.

## Considered Options

1. Dispatch focus in the requested direction, inspect the newly focused client, then restore focus. Rejected because the probe and restoration are state mutations with failure modes.
2. Read active-window and client-list JSON, then compare workspace, geometry, and group state. Chosen because inspection does not dispatch focus changes.

## Decision Outcome

Determine the directional neighbor from read-only active-window/client-list state. Use the active client geometry and eligible clients on the same workspace to select a directional candidate and inspect its group membership. Do not use focus-changing dispatches as part of probing.

## Consequences

- **Positive:** Probing itself cannot move focus, avoiding focus-restoration hazards.
- **Positive:** The selector can be tested with fixed JSON fixtures.
- **Negative:** The implementation depends on the runtime client JSON fields and its geometry/group semantics; those assumptions need validation when supported runtime versions change.
- **Negative:** Geometric nearest-neighbor selection may not exactly match Hyprland's focus or Sway's container-navigation semantics.

## Validation & Compliance

`planning/STATE_2.md` records that the installed `activewindow -j` and `clients -j` queries expose the needed fields without dispatching focus. `scripts/sway-group-move` uses those queries; `tests/test-sway-group-move.sh` covers grouped/ungrouped neighbor selection and no-neighbor behavior.
