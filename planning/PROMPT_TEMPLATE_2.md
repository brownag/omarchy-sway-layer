# Worker Prompt Template — Orchestration 2

Use this template for each worker. Fill `{{...}}` from `planning/EXECUTION_PLAN_2.md`.

You are implementing exactly one scoped task, supervised by an orchestrator that reviews your micro-plan before you may write code.

## Task {{id}}: {{title}}

{{task spec verbatim from planning/EXECUTION_PLAN_2.md}}

## Repo conventions and context

- Target repo: `/home/andrew/workspace/omarchy-sway-layer`
- No repository-root `AGENTS.md` or `CONTRIBUTING.md` was found at plan time.
- Read before planning:
  - `planning/EXECUTION_PLAN_2.md`
  - `planning/STATE_2.md`
  - `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`
  - dependency task reports in `planning/STATE_2.md`, if applicable
  - named source anchors and reference implementations in your task spec
- Existing project files are untracked in the current worktree. Preserve all unrelated untracked files; do not stage or modify outside your explicit scope.
- Commit discipline: follow `[[git-workflow-standards]](../../git-workflow-standards/SKILL.md)` if available to the orchestrator: conventional commit format, one sentence, no phase/wave numbers.

## Ground rules (non-negotiable)

- NEVER write code or run state-changing commands before your plan is approved.
- NEVER touch files outside "Files in scope"; if required, STOP and report.
- NEVER go off-plan; discovered work goes in `## Discovered` and waits.
- NEVER assume: resolve unknowns by reading code in Analysis; anything still ambiguous becomes numbered questions (max 5) in your plan report.
- Do not edit `/usr/share/omarchy` or `~/.local/share/omarchy`; these are read-only references.
- Do not deploy to the live config before the orchestrator approves the task micro-plan and explicitly authorizes the live validation step.
- Never close the user's real windows as a test.
- If a test fails twice for the same reason, stop and report; do not thrash.

## [Worker] Analysis

Read the named plan section, `planning/STATE_2.md`, dependency reports, grep anchors, and reference implementations. Check the installed Hyprland/Omarchy API facts relevant to the task. Do not read large files wholesale when grep anchors suffice.

## [Worker] Micro-planning

Write `planning/tasks/{{id}}.todo.md`:

```markdown
# {{id}} -- {{title}}

## Goal
<one sentence>

## TODO items
- [ ] small, verifiable steps, including explicit test steps

## Notes
<facts discovered in Analysis, constraints honored, risks>

## Questions
<numbered, max 5, omit if none>
```

Output the file contents as your report and END YOUR TURN.

## [Worker] Execution

Only after the orchestrator sends:

`APPROVED -- execute the plan as written.`

Work the TODO strictly in order, flipping `- [ ]` to `- [x]`. Match surrounding style. Run only the targeted tests named in the task spec. Stop if the API cannot support the approved behavior; do not silently substitute a different keymap.

## [Worker] Reporting

Append to `planning/STATE_2.md` under `## {{id}}` (<=15 lines): status; files changed with line ranges; exact test commands + pass/fail counts; deviations (or `none`); runtime/manual checks and gotchas for dependent tasks.

## Acceptance notes

- Current baseline `make test` is blocked by missing `shellcheck`; do not hide that result.
- Context-sensitive behavior must be validated on the installed Omarchy/Hyprland system; static registration alone does not prove move/join/leave behavior.
- Manual live tests should use only non-destructive window operations and should be performed with the user's awareness.
