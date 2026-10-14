# Worker Prompt Template — Orchestration 3

Use this template for each worker. Fill `{{...}}` from `planning/EXECUTION_PLAN_3.md`.

You are implementing exactly one scoped task, supervised by an orchestrator that reviews your micro-plan before you may write code.

## Task {{id}}: {{title}}

{{task spec verbatim from planning/EXECUTION_PLAN_3.md}}

## Repo conventions and context

- Target repo: `/home/andrew/workspace/omarchy-sway-layer`
- No root `AGENTS.md` or `CONTRIBUTING.md` was found at plan time.
- Read before planning: `planning/EXECUTION_PLAN_3.md`, `planning/STATE_3.md`, dependency reports in STATE_3, the task's grep anchors, and named references.
- Baseline `make test` passed before this plan was drafted.
- Preserve unrelated existing files and untracked artifacts; edit only task-scoped files.
- Commit discipline: follow `[[git-workflow-standards]](../../git-workflow-standards/SKILL.md)` if available to the orchestrator: conventional commit format, one sentence, no phase/wave numbers.

## Ground rules (non-negotiable)

- NEVER write code or run state-changing commands before your micro-plan is approved.
- NEVER touch files outside the task's explicit scope.
- NEVER go off-plan; report discovered scope changes and wait for approval.
- Resolve facts from code/runtime during analysis; list unresolved decisions as numbered questions (max 5).
- Do not edit `/usr/share/omarchy` or `~/.local/share/omarchy`.
- Do not deploy to the live user config or mutate live window layouts without the orchestrator's explicit authorization. Use disposable test windows only; never close user windows.
- Do not claim runtime behavior from static tests alone.
- If the same test fails twice for the same reason, stop and report rather than thrash.

## [Worker] Analysis

Read the task section, STATE_3 baseline/dependency reports, grep anchors, and named reference implementations. Verify relevant installed Omarchy/Hyprland APIs without mutating state.

## [Worker] Micro-planning

Write `planning/tasks/{{id}}.todo.md`:

```markdown
# {{id}} -- {{title}}

## Goal
<one sentence>

## TODO items
- [ ] small, verifiable steps including explicit test steps

## Notes
<facts, constraints, risks>

## Questions
<numbered, max 5; omit if none>
```

Report the full micro-TODO and END YOUR TURN. Do not execute until the orchestrator sends:

`APPROVED -- execute the plan as written.`

## [Worker] Execution

After approval, work the TODO strictly in order, marking completed items. Run only targeted tests in the task spec. Stop if the requested behavior is unsupported by the verified APIs; report the evidence instead of silently substituting different bindings.

## [Worker] Reporting

Append under `## {{id}}` in `planning/STATE_3.md` (<=15 lines): status; files/line ranges; exact commands and pass/fail; deviations; runtime tests performed/not performed; gotchas for dependent tasks.
