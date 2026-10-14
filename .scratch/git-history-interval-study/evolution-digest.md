# Git history evolution digest

## Scope and method

Studied `master` from initial commit `6347d96` through HEAD `3a21f4a`, using additions of `planning/EXECUTION_PLAN_*.md` as milestones. The sole plan-creation boundary is `8796e88` (2026-10-13). No tags or merge commits were present. Commit order is topological/reverse chronological within each interval; rename-aware diffs were checked. Detailed machine-readable records are in `interval-ledger.json`.

## Interval overview

| Interval | Commits | Churn | Readout |
|---|---:|---:|---|
| `6347d96..8796e88` | 3 | +1,575 / -0 across 23 files | Bootstrap: compatibility layer, behavior documentation, then two execution plans and supporting orchestration artifacts. Not meaningful to compare as a normal development interval. |
| `8796e88..3a21f4a` | 4 | +309 / -17 across 13 files | Refinement: shellcheck cleanup, contextual group movement/helper and tests, docs, then corrective Lua-dispatch fix. |

## Subsystem evolution

| Subsystem | Bootstrap interval | Follow-up interval | Interpretation |
|---|---:|---:|---|
| Application/configuration | 741 added | 111 changed lines | Core bindings and installer were established, then Lua bindings and installer integration were refined. |
| Planning | 730 added | 92 changed lines | Plan/state/task artifacts captured implementation and later recorded completion/validation status. |
| Scripts | 105 added | 49 changed lines | Installer/support scripts were supplemented by contextual group-movement helper and subsequently corrected. |
| Tests | None | 125 added | Follow-up introduced helper, binding-registration, and isolated installer tests; this is a substantial move toward validation. |

## Feature development and architectural shifts

1. **Compatibility layer established** (`fc2eaa7`): introduced the installer, Hyprland bindings, Waybar/Quickshell configuration and support scripts. `1ff1db8` documented intended Omarchy behavior and grouping semantics.
2. **Work made explicit and staged** (`8796e88`): added execution plans, task prompts, state tracking and research notes. This creates a traceable plan boundary but only one such boundary exists in history.
3. **Context-sensitive movement added** (`202f319`): shifted group movement into an installed helper, added HJKL and arrow aliases, adjusted close/toggle bindings, wired helper lifecycle into installation, and added tests. The helper uses JSON geometry/client state to choose between swap, group join, move-out, or no-op without focus-probing side effects.
4. **Runtime interface corrected** (`3a21f4a`): changed helper dispatches from plain Hyprland dispatcher text to Omarchy Lua dispatcher expressions after diagnostics identified that this runtime parses dispatch arguments as Lua. Added regression assertions and recorded live validation in `TODO.md`. This is an important implementation correction, not merely cleanup.

## Convergence assessment

The follow-up has much less raw churn than the initial repository bootstrap and adds automated coverage, suggesting progress toward stabilization. However, the implementation was still changing at HEAD: the latest commit fixes a runtime dispatch mismatch in the central movement helper. Thus the subsystem is **partially stabilizing, not converged**. Tests now cover key pathways, while any conclusions about long-term API stability would require additional history after this correction.

## ADR-distillation feed

### Candidate: isolate contextual group movement in an installed helper

- **Evidence:** `202f319` (`feat: add context-aware Omarchy group movement`) adds `scripts/sway-group-move`, calls it from Lua bindings, integrates copy/diff/uninstall lifecycle into `bin/apply-sway-layer`, and introduces helper/binding/installer tests.
- **Rationale visible in artifacts:** directional behavior depends on active-window and client geometry/group membership; the task report specifies avoiding focus-changing probes and preserving unrelated configuration. The helper also keeps runtime execution independent of the source checkout by installing under the user's Hyprland config directory.
- **Consequence:** clear separation between key registration and context-selection logic, at the cost of helper deployment/lifecycle and coupling to the installed Omarchy dispatcher API.

### Candidate: dispatch through Omarchy's Lua API, not bare Hyprland dispatcher strings

- **Evidence:** `3a21f4a` (`fix: use Lua dispatch for group movement`) changes helper calls to expressions such as `hl.dsp.window.swap({ direction = "l" })`, adjusts tests to assert those expressions and documents the observed parser behavior in `TODO.md`.
- **Rationale:** the deployed Omarchy Lua-enabled `hyprctl dispatch` interpreted the argument as Lua; plain strings failed and had been silently ignored.
- **Consequence:** helper correctness depends on the Omarchy Lua dispatcher surface. Regression tests now encode the required syntax; consider documenting/versioning this runtime assumption if support across Omarchy versions is needed.

## Caveats

The chronology provides only one plan-creation milestone, and the first interval combines all initial project creation with planning. Churn by directory is an approximate aggregation of line additions/deletions, not a semantic measure. Author dates are repository-provided and should not be treated as independent chronology verification.
