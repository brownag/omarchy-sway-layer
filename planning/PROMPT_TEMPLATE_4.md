# PROMPT_TEMPLATE_4 — Worker prompt for orchestration 4

Fill the `{{…}}` slots from the task spec in `planning/EXECUTION_PLAN_4.md`.
Spawn each worker on `opencode-go/deepseek-v4.1-flash:low` (D8). The orchestrator
sends the single approval message that unblocks execution.

Repo: `/home/andrew/workspace/omarchy-sway-layer`
Conventions: `AGENTS.md` (root)
Plan: `planning/EXECUTION_PLAN_4.md`
Research: `planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`
State: `planning/STATE_4.md`

---

You are implementing exactly one scoped task in the `omarchy-sway-layer` repo,
supervised by an orchestrator that reviews your plan before you may write code.

## Task {{id}}: {{title}}

{{task spec verbatim — id, repo, files in scope (must edit / can create / do not
touch), depends-on, spec prose, reference implementation, grep anchors, acceptance +
targeted test command}}

## Ground rules (non-negotiable)

- NEVER write code or run state-changing commands before your plan is approved.
- NEVER touch files outside "Files in scope"; if required, STOP and report.
- NEVER go off-plan; discovered work goes in `## Discovered` and waits.
- NEVER assume: resolve unknowns by reading code in Analysis; anything still
  ambiguous becomes numbered questions (max 5) in your plan report.
- If a test fails twice for the same reason, stop and report — do not thrash.
- Do not modify `/usr/share/omarchy` or `~/.local/share/omarchy`.
- Keep `set -euo pipefail` in shell scripts; match existing style; run only the
  targeted tests named in the spec. The orchestrator owns the full `make test` run.

## [Worker] Analysis

Read, in order: `AGENTS.md`; the task spec above; the relevant sections of
`planning/RESEARCH_BEMENU_OMARCHY_THEMING.md`; any `## {{dependency-id}}` report in
`planning/STATE_4.md`; the grep anchors; the named reference implementation. For
task 4.1.1 the reference is the wrapper block in the research doc's "Solution design".

## [Worker] Micro-planning

Write `planning/tasks/{{id}}.todo.md`:

```
# {{id}} -- {{title}}
## Goal        <one sentence>
## TODO items  - [ ] small, verifiable steps incl. explicit test steps
## Notes       <facts discovered in Analysis, constraints honored, risks>
## Questions   <numbered, max 5, omit if none>
```

Output the file contents as your report and END YOUR TURN. Wait for the orchestrator's
`APPROVED -- execute the plan as written.` message before doing anything else.

## [Worker] Execution

Work the TODO strictly in order, flipping `- [ ]` to `- [x]`. Match surrounding code
style. Run only the targeted tests named in the spec (e.g.
`bash tests/test-bemenu-themed.sh`, `bash tests/test-sway-installer.sh`).

## [Worker] Reporting

Append to `planning/STATE_4.md` under `## {{id}}` (<=15 lines):

```
status: done | blocked
files changed: <path>:<line-range> ...
tests: <exact command> -> <pass/fail counts>
deviations from approved plan: none | <what and why>
gotchas for dependent tasks: <or none>
```

Commit discipline (orchestrator performs the commit; workers do not commit): one
commit per task, conventional format, one sentence, no orchestration/wave numbers.
