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
| 1 | 2.1.1 | Context-aware Omarchy Lua grouping | complete (static and isolated validation; no deployment) | none |
| 2 | 2.2.1 | Document group-aware Omarchy behavior | complete | 2.1.1 |

## Worker reports

### Task 2.1.1 — implementation report

- Implemented one installed helper for contextual movement: grouped focus moves out; otherwise a geometrically nearest directional neighbor in the same workspace is inspected from `hyprctl -j clients`; grouped neighbor joins, ungrouped neighbor swaps, and no neighbor does nothing. Probe queries do not dispatch focus, so they cannot leave focus changed. Query failure uses ordinary swap when active-window data remains available.
- Added both HJKL and arrow aliases, `SUPER+w` group toggle, and only `SUPER+SHIFT+q` managed close. Existing Omarchy group aliases remain unmodified. Managed helper lifecycle is covered by isolated dry-run/install/uninstall tests.
- Verified installed non-focus-changing probe surface on Hyprland 0.56.2: `activewindow -j` and `clients -j` expose address, geometry, workspace, and group membership without dispatching focus. No live configuration was changed; deployment and manual behavior validation remain unauthorized/pending.
- Targeted syntax and isolated tests passed; `make test` passed including ShellCheck. No staged files; pre-existing/unrelated untracked planning artifacts were preserved.

### Task 2.2.1 — documentation report

- Updated README keybinding table and Omarchy Lua mode section to describe `SUPER+w`, `SUPER+SHIFT+q`, both shifted direction families, contextual move/swap/join/leave behavior, and retained Omarchy aliases.
- Clarified that behavior applies only to Omarchy Lua mode; plain-config path remains unchanged and deferred, and Hyprland groups approximate rather than reproduce Sway stacking.
- Acceptance grep command passed (exit 0); `git diff --check` passed. No deviations; live behavior is not claimed.

## Orchestration status

Plan 2 implementation, static/isolated validation, and documentation tasks are complete. Live deployment and manual behavior validation remain pending separate explicit authorization.
