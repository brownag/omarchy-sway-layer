---
id: "0007"
title: "Model Modal Keybindings as Submaps in Both Integrations"
status: "Accepted"
date: 2026-10-14
authors:
  - "Andrew G. Brown"
supersedes: null
superseded_by: null
source_context: "planning/EXECUTION_PLAN_3.md; commit a3536c8"
---

# 7. Model Modal Keybindings as Submaps in Both Integrations

## Context and Problem Statement

Some actions need a modal key context: a chord enters a mode, plain keys do the action,
and Return/Escape leaves. The plain Hyprland configuration already models resize this way
with `bind = SUPER, r, submap, resize` between `submap = resize` and `submap = reset`
blocks. The Omarchy Lua integration had no equivalent: the project-local `o.bind` wrapper
has no documented submap option, so Lua mode used a different, non-modal resize gesture
(`SUPER+CTRL+h/j/k/l`).

Fixing only resize would leave the next modal mode — a move mode, a launch mode, a
scratchpad selector — to reinvent the mechanism. The question is therefore not "how do we
make resize modal?" but "what is the standing way to add a modal mode to this layer?".

## Decision Drivers

- One convention that any future modal mode can follow, in both integrations.
- Interaction parity between the plain config and Omarchy Lua mode.
- Explicit, discoverable exits: every mode must leave on Return and Escape.
- No reliance on undocumented behavior of the project-local `o.bind` wrapper, and no
  extension of it with a parallel submap concept.
- Keep mode definitions declarative and testable through the existing Lua harness.

## Considered Options

1. Keep non-modal direct chords (e.g. `SUPER+CTRL+...`) for Lua mode and accept a
   divergent interaction. Rejected: it forfeits parity and does not scale to modes that
   fundamentally need a context (there is no chord to hold while pressing arbitrary keys).
2. Extend the local `o.bind` wrapper with a `submap` option. Not chosen: it invents a
   project-specific shim over the runtime's own modal API and adds surface to maintain.
3. Adopt the runtime's submap facilities as the standard mechanism: `submap = <name>` /
   `submap = reset` in plain config, and `hl.define_submap` / `hl.dsp.submap` in Lua mode.
   Chosen.

## Decision Outcome

Modal keybinding modes are represented as submaps, using each integration's native
facility:

- **Plain config:** define `bind = <chord>, submap, <name>`, wrap the mode's bindings
  between `submap = <name>` and `submap = reset`, and bind `Return`/`Escape` to
  `submap, reset`.
- **Lua mode:** enter with `hl.dsp.submap("<name>")`, register the mode with
  `hl.define_submap("<name>", function() ... hl.bind(...) end)`, and leave with
  `hl.dsp.submap("reset")`.

Every submap must define explicit Return/Escape exit bindings, and its keys must be
registered only inside the submap so they are inert in the reset context. Dispatchers
invoked from inside a Lua-mode submap still follow the Lua-expression contract in
ADR-0003; the submap mechanism does not change that.

Modal resize is the first instance of the convention: `SUPER+r` enters the mode, H/J/K/L
and arrow keys resize by 20-pixel relative steps, and Return/Escape exit — in both
integrations. The Lua resize mode was previously a set of `SUPER+CTRL` direct chords; the
earlier project note that the Lua binding surface had no submap support is superseded by
this decision.

### Consequences

- **Positive:** A single, documented shape for any future modal mode, applied identically
  in plain and Lua integrations.
- **Positive:** Adopts the runtime's own modal API rather than a project-specific shim.
- **Positive:** The test harness can assert submap registration, in-mode bindings, and
  exits generically, so new modes get the same coverage cheaply.
- **Negative:** The Lua path is coupled to Hyprland's Lua submap API; runtime version
  drift requires compatibility work.
- **Negative:** Modal entry introduces state to enter and leave, and forgetting an exit
  binding can strand the user in a mode; the convention makes explicit exits mandatory.
- **Negative:** Runtime behavior of the Lua submap path was not live-tested (resize mode
  in particular); registration, mappings, and exits are covered by automated tests only.

## Validation & Compliance

`a3536c8` establishes the convention in `config/hypr/binds_sway.conf` (resize submap with
Return/Escape resets) and `config/hypr/binds_sway.lua` (`hl.define_submap("resize", ...)`
with `hl.dsp.submap("reset")` exits), and `tests/test-sway-bindings.lua` asserts submap
registration, in-mode alias bindings, and exits. `f84cd16` documents modal resize in both
integrations. `planning/STATE_3.md` records that resize mode was not live-tested; this
record claims automated coverage only, and does not assert submap behavior for runtime
versions other than the one observed. The convention is cross-referenced from
ADR-0003 (dispatch contract) and ADR-0001 (installed-helper boundary).
