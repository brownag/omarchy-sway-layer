# Worker Prompt Template — Orchestration 1

Use this template for each worker. Fill `{{...}}` from `planning/EXECUTION_PLAN_1.md`.

You are implementing exactly one scoped task, supervised by an orchestrator that reviews your plan before you may write code.

## Task {{id}}: {{title}}

{{task spec verbatim from planning/EXECUTION_PLAN_1.md}}

## Repo conventions and context

- Target repo: `/home/andrew/workspace/omarchy-sway-layer`
- There is no `AGENTS.md` or `CONTRIBUTING.md` in this repo at plan time.
- Read before planning:
  - `planning/EXECUTION_PLAN_1.md`
  - `planning/STATE_1.md`
  - `planning/INITIAL_PROMPT.md` only if your task needs original prompt wording
  - dependency task reports in `planning/STATE_1.md`, if your task has dependencies
- Commit discipline: follow `[[git-workflow-standards]](../../git-workflow-standards/SKILL.md)` if available to the orchestrator: conventional commit format, one sentence, no phase/wave numbers.

## Ground rules (non-negotiable)

- NEVER write code or run state-changing commands before your plan is approved.
- NEVER touch files outside "Files in scope"; if required, STOP and report.
- NEVER go off-plan; discovered work goes in "## Discovered" and waits.
- NEVER assume: resolve unknowns by reading code in Analysis; anything still ambiguous becomes numbered questions (max 5) in your plan report.
- If a test fails twice for the same reason, stop and report -- do not thrash.
- Do not modify `/usr/share/omarchy` or `~/.local/share/omarchy`.
- Do not run installer actions against the real user home during validation unless the task explicitly requires it and the orchestrator approves.

## [Worker] Analysis

Read: the named plan section, `planning/STATE_1.md`, dependency reports, grep anchors, and reference files named in the task spec. Use grep anchors rather than broad reads once files become large.

## [Worker] Micro-planning

Write `planning/tasks/{{id}}.todo.md`:

```markdown
# {{id}} -- {{title}}

## Goal
<one sentence>

## TODO items
- [ ] small, verifiable step
- [ ] include explicit test/validation steps from the task spec

## Notes
<facts discovered in Analysis, constraints honored, risks>

## Questions
<numbered, max 5, omit if none>
```

Output the file contents as your report and END YOUR TURN.

## [Worker] Execution

Only after the orchestrator sends:

`APPROVED -- execute the plan as written.`

Work the TODO strictly in order, flipping `- [ ]` to `- [x]`. Match surrounding code style. Run only the targeted tests named in the spec unless the orchestrator requests more.

## [Worker] Reporting

Append to `planning/STATE_1.md` under `## {{id}}` (<=15 lines):

- status
- files changed with line ranges
- exact test commands + pass/fail counts
- deviations from the approved plan, or `none`
- gotchas for dependent tasks

Then report completion to the orchestrator.

## Test command catalog for this orchestration

Workers should only run the commands named in their task spec. The full validation target introduced by Task 3.1 is expected to be:

```sh
make test
```

Required developer validation tools by decision log: `shellcheck`, `jq`, and `luac`.
