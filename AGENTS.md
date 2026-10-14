# omarchy-sway-layer

## Quick Start

- `make test` — run shell syntax/lint checks, JSON and Lua validation, and installer/binding tests. Requires Bash, ShellCheck, `jq`, and Lua's `luac`/`lua`.
- `make install` — run the installer against the current user's configuration.
- `make uninstall` — remove managed files and integration lines from the current user's configuration.
- `./bin/apply-sway-layer --dry-run` — preview installer changes without writing files.

Run deployment commands only when you intend to change the active user's configuration. Source validation is `make test`.

## Find Things

- `bin/apply-sway-layer` — installer CLI: install, dry-run, uninstall, rollback, and help.
- `config/hypr/` — plain Hyprland bindings and the Lua binding module.
- `config/waybar/` — managed Waybar JSONC config and CSS.
- `config/quickshell/` — Quickshell override artifact.
- `scripts/` — Omarchy/config detection, backups, and Lua-mode group movement helper.
- `tests/` — shell installer/helper tests and Lua binding tests.
- `docs/decisions/` — architecture decision records.
- `planning/` — execution plans, task notes, research, and orchestration state.
- `README.md` — deployment behavior, keybindings, prerequisites, and verification details.
- `Makefile` — test, install, uninstall, and lint targets.

## Workflows

- Validate source changes with `make test`.
- Before installing, review `./bin/apply-sway-layer --dry-run`; install with `make install` only when targeting an Omarchy/Hyprland user configuration.
- The installer creates timestamped backups under `~/.config/omarchy-sway-backup/`. See `README.md` for rollback and uninstall behavior.
- Record enduring architectural decisions in `docs/decisions/`; use `planning/` for execution plans and task artifacts.

## Infrastructure

- Deployment targets files under `~/.config/`; the installer does not modify Omarchy upstream files in `/usr/share/omarchy` or `~/.local/share/omarchy`.
- Plain Hyprland integration sources `~/.config/hypr/binds_sway.conf`; Lua mode integrates through `~/.config/hypr/bindings.lua`.
- Waybar startup integration is opt-in via `./bin/apply-sway-layer --enable-waybar`.
- No build or dependency-install step is defined; the project is shell/Lua/config files validated by the Makefile.

## References

- `README.md` — full usage, operational behavior, and keybinding reference.
- `docs/decisions/README.md` — architecture decision record index.
- `Makefile` — authoritative validation commands.
