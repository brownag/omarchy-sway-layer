---
id: "0003"
title: "Use Omarchy Lua Expressions for Runtime Dispatch"
status: "Accepted"
date: 2026-10-13
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "commit 3a21f4ab11334af3cbb68affffa0fd88265e4354; planning/STATE_2.md"
---

# 3. Use Omarchy Lua Expressions for Runtime Dispatch

## Context and Problem Statement

The contextual movement helper initially invoked `hyprctl dispatch` with bare dispatcher arguments such as `swapwindow l`. On the target Omarchy Lua-enabled runtime, the dispatch interface parses its argument as a Lua expression. The plain strings failed to execute, and earlier error handling concealed the failure. The mismatch affected swap, group-join, and move-out operations.

Commit `3a21f4a` changed the helper to invoke Omarchy's `hl.dsp.window.*` API through Lua expressions; the diagnosis and correction are recorded in `TODO.md`.

## Decision Drivers

- Dispatch calls must match the actual runtime interface.
- Dispatch failures must remain observable rather than being silently treated as success.
- The syntax contract should be covered by regression tests.

## Considered Options

1. Continue sending bare Hyprland dispatcher strings. Rejected: the target Lua-enabled path parses the argument as Lua, so these strings fail.
2. Invoke the Omarchy Lua dispatcher API via Lua expressions. Chosen.
3. Suppress dispatch errors. Rejected because it masks runtime failures.

## Decision Outcome

For the Omarchy Lua path, helpers invoking `hyprctl dispatch` must pass Lua expressions that call Omarchy's dispatcher API. For example, a directional swap is expressed as `hl.dsp.window.swap({ direction = "l" })`. Dispatch failure must propagate as a nonzero result.

This contract is specific to the Omarchy Lua-enabled path; it does not establish syntax for the plain Hyprland configuration path or other Omarchy/runtime versions.

## Consequences

- **Positive:** Dispatch syntax matches the tested runtime API, and failures are visible to tests and callers.
- **Negative:** The helper is coupled to Omarchy's Lua dispatcher API; API changes require compatibility work and validation.
- **Negative:** Runtime-version differences remain possible; this decision does not claim universal support.

## Validation & Compliance

`3a21f4a` updates `scripts/sway-group-move` and `tests/test-sway-group-move.sh` to use and assert Lua dispatcher expressions. `TODO.md` records runtime diagnosis and behavior checks. The decision is limited to the Omarchy Lua dispatch path.
