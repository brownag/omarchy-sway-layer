# State 2 — Context-aware Omarchy window grouping

## Baseline checklist

- [x] Repo path confirmed: `/home/andrew/workspace/omarchy-sway-layer`; branch `master`.
- [x] Next orchestration confirmed: Plan 1 exists; no Plan 2 artifacts existed before drafting.
- [x] Repo-root conventions checked: no `AGENTS.md` or `CONTRIBUTING.md`.
- [x] Existing task/research notes read: Plan 1 artifacts, root `TODO.md`, and `planning/RESEARCH_HYPRLAND_GROUPS_VS_SWAY_STACKING.md`.
- [x] Entry-point sizes recorded in `planning/EXECUTION_PLAN_2.md`; no oversized target file.
- [x] Baseline `luac -p config/hypr/binds_sway.lua`, `jq empty config/waybar/config.jsonc`, and Bash syntax checks passed.
- [x] Baseline `make test` is blocked by missing `shellcheck`; `jq`, `luac`, and `hyprctl` are available.
- [x] Live target identified: Hyprland 0.56.2, Omarchy Lua engine enabled; baseline bindings captured in Plan 2 recon.
- [x] `hyprctl activewindow -j` and `hyprctl clients -j` expose group-related state fields; current active sample has no group.
- [x] Worktree status checked: project and Plan 1 files are untracked; preserve existing untracked artifacts and avoid worktree isolation.

## Wave board

| Wave | Task | Title | Status | Dependencies |
| --- | --- | --- | --- | --- |
| 1 | 2.1.1 | Context-aware Omarchy Lua grouping | pending | none |
| 2 | 2.2.1 | Document group-aware Omarchy behavior | pending | 2.1.1 |

## Worker reports

_No worker reports yet._

## Orchestration status

Plan 2 is drafted and independently reviewed on spec and standards axes. The standards review's helper-lifecycle test gap was fixed and re-reviewed. Awaiting user approval; no implementation tasks have started.
