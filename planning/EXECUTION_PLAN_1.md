# Execution Plan 1 — Build `omarchy-sway-layer`

## Goal & Scope

### Goal
Create an idempotent, self-contained CLI tool and dotfiles installer in this empty repository. The goal is to translate and inject Sway/i3 workflows, keybindings, container management, and dense system status indicators into a target machine running Omarchy (Hyprland + Wayland stack), without modifying upstream `/usr/share/omarchy` or `~/.local/share/omarchy` system files.

### In scope
- Repository structure exactly covering `bin/`, `config/hypr/`, `config/waybar/`, `config/quickshell/`, `scripts/`, `Makefile`, and `README.md`.
- Bash implementation of `bin/apply-sway-layer`.
- Omarchy/Hyprland detection helpers for plain conf and Lua dynamic engine models.
- Safe backup, uninstall, rollback, dry-run, idempotent integration, and live-session reload behavior.
- Sway/i3 keybinding translation for focus, moving containers, splits/layout, workspaces, kill, float/fullscreen, scratchpad, and resize submap.
- Dense Waybar configuration and compact styling.
- Quickshell fallback override artifact.
- Developer validation through `make test`.
- README installation, rollback, local testing, deployment, and Sway-vs-Hyprland behavior notes.

### Out of scope
- Modifying upstream `/usr/share/omarchy` or `~/.local/share/omarchy` files.
- Shipping a daemon or service manager unit beyond optional managed `exec-once` Waybar integration in user Hyprland config.
- Implementing a full Quickshell replacement bar; only a fallback override artifact is required.
- Guaranteeing exact Sway split/container semantics where Hyprland lacks direct equivalents; document differences and use best-effort Hyprland dispatchers.
- Running live Hyprland/Omarchy integration tests in this repo; tests validate syntax and static behavior only.

### Verbatim constraints from input
- "Create an idempotent, self-contained CLI tool and dotfiles installer in this empty repository."
- "without modifying upstream `/usr/share/omarchy` or `~/.local/share/omarchy` system files."
- "Inject `source = ~/.config/hypr/binds_sway.conf` into `~/.config/hypr/hyprland.conf` or `~/.config/hypr/user_custom.conf` without duplicates."
- "Detect if Omarchy loads `bindings.lua` or `looknfeel.lua`. If present, write a clean Lua module `~/.config/hypr/sway_bindings.lua` and add `pcall(require, "sway_bindings")` cleanly to `bindings.lua`."
- "The generated binds must implement" the listed Sway/i3 keybindings, workspace bindings, scratchpad bindings, and resize submap.
- "Provide a full Waybar configuration (`config.jsonc` + `style.css`)."
- "Detect whether Omarchy is launching Quickshell or Waybar on startup."
- "If Omarchy launches Quickshell, provide an optional switch: disable Quickshell bar service and enable `exec-once = waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css`."
- "Idempotency: Running the script multiple times must never create duplicate configuration lines."
- "Always create a timestamped backup directory at `~/.config/omarchy-sway-backup/<TIMESTAMP>/` before touching any file."
- "Provide a `--rollback` or `--uninstall` flag that restores the pre-install state."
- "Dry Run: Support `-n` / `--dry-run` to print exact diffs before writing files."
- "Non-Destructive Integration: Never overwrite existing `hyprland.conf` directly; use dedicated `include` / `source` statements."
- "Session Reload: Attempt `hyprctl reload` and `killall -SIGUSR2 waybar` (or restart the bar process) if running under a live Hyprland session."
- "Complete shell/Python scripts with proper error handling (`set -euo pipefail` in Bash)."
- "All configuration templates with no placeholders or missing sections."
- "A `Makefile` supporting: `make install`, `make uninstall`, `make test`."
- "Begin implementation by initializing the directory tree and writing the core detection and backup logic."

## Recon log

- Repo root: `/home/andrew/workspace/omarchy-sway-layer`.
- Current tracked content is effectively empty: only `planning/INITIAL_PROMPT.md` exists outside `.git`.
- Entry-point file inventory: `planning/INITIAL_PROMPT.md` — 125 lines.
- No `AGENTS.md`, `CONTRIBUTING.md`, source files, Makefile, test suite, prior execution plans, or state files exist in this repo.
- Git branch: `master`; latest commit: `6347d96 Initial plan`.
- Test baseline: no runnable tests yet. Pre-wave baseline is therefore file inventory + `git status`; `make test` is introduced by this orchestration.
- No oversized code files exist; grep anchors below target new file paths/functions rather than large-file offsets.

## Decision log

- 2026-10-13 — CLI implementation language: Bash.
- 2026-10-13 — Bar behavior: install both Waybar and Quickshell config artifacts; default install does not switch bars; switching to Waybar requires explicit `--enable-waybar`.
- 2026-10-13 — Rollback model: implement both `--uninstall` for managed cleanup and `--rollback latest|TIMESTAMP` for backup restoration.
- 2026-10-13 — Developer validation may require `shellcheck`, `jq`, and `luac`; `make test` should use those tools and fail clearly when missing.
- 2026-10-13 — Lua integration edge case: if `looknfeel.lua` exists but `bindings.lua` does not, create `~/.config/hypr/bindings.lua` containing the `pcall(require, "sway_bindings")` integration line.

## Hazard notes

- The repo has no existing conventions; tasks must keep implementation simple and self-contained.
- Multiple tasks must not edit the same file in the same wave. Wave table below keeps file scopes disjoint.
- Live Omarchy paths are user-machine paths; static tests must not write to `$HOME` except through temporary directories.
- `hyprland.conf` must never be overwritten. The CLI may append managed source/exec lines idempotently or prefer `user_custom.conf` when present.
- JSONC is not strict JSON; validation should strip comments or use a supported preprocessing path before `jq`.
- Lua module loading with `require` depends on Omarchy's Lua path. The generated install target is `~/.config/hypr/sway_bindings.lua` because the prompt requires it.
- Waybar switching must be opt-in through `--enable-waybar`; default install must not disable Quickshell.

## Wave table

| Wave | Tasks | Purpose | Dependencies | Parallelism notes |
| --- | --- | --- | --- | --- |
| 1 | 1.1, 1.2 | Create static building blocks: config templates and helper scripts | none | Disjoint file scopes: `config/**` vs `scripts/**` |
| 2 | 2.1 | Implement main installer CLI | 1.1, 1.2 | Single task because install, uninstall, rollback, dry-run, backup, and detection are tightly coupled in one entrypoint |
| 3 | 3.1, 3.2 | Add validation workflow and documentation | 2.1 | Disjoint file scopes: `Makefile` vs `README.md` |

## Task specs

### Task 1.1 — Static configuration templates

- **id:** `1.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `config/hypr/binds_sway.conf`
    - `config/hypr/binds_sway.lua`
    - `config/waybar/config.jsonc`
    - `config/waybar/style.css`
    - `config/quickshell/BarOverrides.qml`
  - Can create: parent directories under `config/`.
  - Temp/scratch: `.development/task-1.1/` only, if needed.
- **depends-on:** none
- **spec:** Create complete, placeholder-free config templates. Hyprland conf and Lua templates must implement the required Sway/i3 translation: HJKL focus, HJKL move, split/layout bindings, workspaces 1-10 and move-to-workspace 1-10, `SUPER+q` and `SUPER+SHIFT+q` kill, float/fullscreen, scratchpad, and resize submap entered with `SUPER+r` and exited by Return/Escape. Waybar JSONC must be dense and compact with left/center/right modules requested in the input. CSS must be compact, square-edged, monospace-friendly. Quickshell override must be a valid QML artifact that is safe as a fallback override and documents, in comments, that it is intentionally minimal.
- **constraints / do not touch:** Do not create `bin/`, `scripts/`, `Makefile`, or `README.md`. Do not encode host-specific paths except `~/.config/...` where required by Omarchy/Hyprland conventions.
- **grep anchors:**
  - `bind = SUPER, h, movefocus, l`
  - `bind = SUPER SHIFT, minus, movetoworkspacesilent, special:scratchpad`
  - `submap = resize`
  - `hyprland/workspaces`
  - `modules-right`
  - `sway_bindings`
- **reference implementations:** Hyprland dispatcher syntax from generated `binds_sway.conf`; Lua table mirrors the same dispatcher/action set.
- **acceptance + targeted test command:**
  - `test -s config/hypr/binds_sway.conf && test -s config/hypr/binds_sway.lua && test -s config/waybar/config.jsonc && test -s config/waybar/style.css && test -s config/quickshell/BarOverrides.qml`
  - `grep -q 'bind = SUPER, h, movefocus, l' config/hypr/binds_sway.conf`
  - `grep -q 'submap = resize' config/hypr/binds_sway.conf`
  - `grep -q 'hyprland/workspaces' config/waybar/config.jsonc`

### Task 1.2 — Detection and backup helper scripts

- **id:** `1.2`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `scripts/detect_omarchy.sh`
    - `scripts/backup.sh`
  - Can create: parent directory `scripts/`.
  - Temp/scratch: `.development/task-1.2/` only, if needed.
- **depends-on:** none
- **spec:** Write Bash helper scripts with `set -euo pipefail`. `detect_omarchy.sh` should report facts useful to the installer: whether Hyprland config exists, whether `user_custom.conf` exists, whether Lua engine files `bindings.lua`/`looknfeel.lua` exist, whether Quickshell/Waybar launch strings are present in user config, and whether runtime commands (`hyprctl`, `waybar`, `quickshell`) are available. Output should be stable `KEY=value` lines so the CLI can source or parse it. `backup.sh` should create timestamped backups under `~/.config/omarchy-sway-backup/<TIMESTAMP>/`, copy relevant existing files/directories (`~/.config/hypr`, `~/.config/waybar`, likely Quickshell config path) without failing if absent, and write a manifest.
- **constraints / do not touch:** Do not implement the main installer. Do not edit user home during tests except when invoked with explicit env vars or temp HOME. Keep helpers callable from the CLI and directly by users.
- **grep anchors:**
  - `set -euo pipefail`
  - `OMARCHY_SWAY_BACKUP_ROOT`
  - `detect_lua_engine`
  - `write_manifest`
- **reference implementations:** No existing repo code. Use straightforward Bash functions and `printf 'KEY=%s\n'` style output.
- **acceptance + targeted test command:**
  - `bash -n scripts/detect_omarchy.sh scripts/backup.sh`
  - `grep -q 'set -euo pipefail' scripts/detect_omarchy.sh scripts/backup.sh`
  - `grep -q 'OMARCHY_SWAY_BACKUP_ROOT' scripts/backup.sh`

### Task 2.1 — Main installer CLI

- **id:** `2.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `bin/apply-sway-layer`
  - May read but must not edit:
    - `scripts/detect_omarchy.sh`
    - `scripts/backup.sh`
    - `config/hypr/binds_sway.conf`
    - `config/hypr/binds_sway.lua`
    - `config/waybar/config.jsonc`
    - `config/waybar/style.css`
    - `config/quickshell/BarOverrides.qml`
  - Can create: parent directory `bin/`.
  - Temp/scratch: `.development/task-2.1/` only, if needed.
- **depends-on:** 1.1, 1.2
- **spec:** Implement Bash CLI with `set -euo pipefail`. Support default install, `--enable-waybar`, `--uninstall`, `--rollback latest|TIMESTAMP`, `-n`/`--dry-run`, and `-h`/`--help`. Default install must create a backup before touching files; install managed config files to `~/.config/hypr/binds_sway.conf`, `~/.config/hypr/sway_bindings.lua`, `~/.config/waybar/sway-dense.jsonc`, `~/.config/waybar/sway-dense.css`, and an appropriate Quickshell override path. Plain conf integration must idempotently add `source = ~/.config/hypr/binds_sway.conf` to `user_custom.conf` if present, otherwise `hyprland.conf`, without duplicate lines and without overwriting the whole config. Lua integration must detect `bindings.lua` or `looknfeel.lua`; write `sway_bindings.lua`; add `pcall(require, "sway_bindings")` to `bindings.lua` idempotently; if only `looknfeel.lua` exists, create `bindings.lua` with that line. `--enable-waybar` must idempotently add a managed `exec-once = waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css` line and avoid disabling Quickshell unless implemented as a clearly managed user-config line/comment. `--uninstall` removes managed files and managed lines only. `--rollback` restores from backup snapshot. Dry-run prints exact intended file diffs/actions and writes nothing. If under live Hyprland, attempt `hyprctl reload` and signal/restart Waybar best-effort without failing installation.
- **constraints / do not touch:** Do not modify `/usr/share/omarchy` or `~/.local/share/omarchy`. Do not overwrite `hyprland.conf`; append/remove managed lines only. Do not duplicate managed lines on repeated runs. Do not switch to Waybar unless `--enable-waybar` is provided. Do not require root.
- **grep anchors:**
  - `set -euo pipefail`
  - `usage()`
  - `DRY_RUN=`
  - `ENABLE_WAYBAR=`
  - `install_layer()`
  - `uninstall_layer()`
  - `rollback_layer()`
  - `pcall(require, "sway_bindings")`
  - `source = ~/.config/hypr/binds_sway.conf`
  - `waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css`
- **reference implementations:** Use helper behavior from `scripts/detect_omarchy.sh` and `scripts/backup.sh`; copy templates from `config/**`.
- **acceptance + targeted test command:**
  - `bash -n bin/apply-sway-layer`
  - `grep -q 'install_layer()' bin/apply-sway-layer`
  - `grep -q 'rollback_layer()' bin/apply-sway-layer`
  - `grep -q 'DRY_RUN=' bin/apply-sway-layer`
  - Optional static temp-HOME smoke test if implemented by worker: `HOME=$(mktemp -d) ./bin/apply-sway-layer --dry-run`

### Task 3.1 — Makefile validation workflow

- **id:** `3.1`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `Makefile`
  - May read but must not edit: `bin/**`, `scripts/**`, `config/**`.
  - Temp/scratch: `.development/task-3.1/` only, if needed.
- **depends-on:** 2.1
- **spec:** Create `Makefile` with `install`, `uninstall`, `test`, and `lint` targets. `install` runs `./bin/apply-sway-layer`; `uninstall` runs `./bin/apply-sway-layer --uninstall`; `lint` can alias `test` or run static validation. `test` must fail clearly if `shellcheck`, `jq`, or `luac` is missing. It must run `bash -n` on shell files, `shellcheck` on shell files, preprocess JSONC to strict JSON and validate with `jq`, run `luac -p` on Lua files, and include simple grep/static checks for key required bindings and managed CLI strings.
- **constraints / do not touch:** Do not edit code/config files to make tests pass. Do not invoke live install against the real user home in `make test`.
- **grep anchors:**
  - `.PHONY: install uninstall test lint`
  - `shellcheck`
  - `jq`
  - `luac -p`
  - `bash -n`
- **reference implementations:** Validate files created by tasks 1.1, 1.2, and 2.1.
- **acceptance + targeted test command:**
  - `make -n install uninstall test lint`
  - `grep -q 'shellcheck' Makefile && grep -q 'jq' Makefile && grep -q 'luac -p' Makefile`

### Task 3.2 — README documentation

- **id:** `3.2`
- **repo:** `/home/andrew/workspace/omarchy-sway-layer`
- **files in scope:**
  - Must create/edit:
    - `README.md`
  - May read but must not edit: all project files.
  - Temp/scratch: `.development/task-3.2/` only, if needed.
- **depends-on:** 2.1
- **spec:** Write a clear README covering project purpose, repository layout, prerequisites, local build/test on Ubuntu Sway or a non-Omarchy machine, deployment on target Omarchy, default install behavior, `--enable-waybar`, dry-run, uninstall, rollback, verification commands, and key differences between native Sway/i3 and Hyprland layout semantics. Document that upstream Omarchy system files are never modified. Include a concise keybinding table matching the implemented bindings.
- **constraints / do not touch:** Do not claim live Omarchy behavior was tested in this repo. Do not document unsupported flags. Do not edit `Makefile` or code.
- **grep anchors:**
  - `--enable-waybar`
  - `--rollback latest`
  - `Native Sway/i3 vs Hyprland`
  - `SUPER + h/j/k/l`
  - `/usr/share/omarchy`
- **reference implementations:** CLI flags and behavior from `bin/apply-sway-layer`; config content from `config/**`.
- **acceptance + targeted test command:**
  - `test -s README.md`
  - `grep -q -- '--enable-waybar' README.md`
  - `grep -q -- '--rollback latest' README.md`
  - `grep -q 'Native Sway/i3 vs Hyprland' README.md`

## Plan review notes

### Spec-axis review
- Every requirement in `planning/INITIAL_PROMPT.md` maps to Task 1.1, 1.2, 2.1, 3.1, or 3.2, or to explicit out-of-scope notes.
- User decisions are honored: Bash CLI, Waybar opt-in, both uninstall and rollback, strict dev validation dependencies, and `bindings.lua` creation when only `looknfeel.lua` exists.
- No extra feature work beyond the prompt is required; optional live integration is limited to best-effort reload/signaling.

### Standards-axis review
- Tasks are right-sized and have explicit file scopes.
- Same-wave tasks touch disjoint files.
- Acceptance commands are mechanically checkable and targeted.
- Large-file grep-anchor rule is not a concern because the repo has no large files; anchors still name exact symbols/strings.
- Wave 2 is serial because main CLI integration is tightly coupled.
- Wave 3 documentation and Makefile can run in parallel after CLI exists.
