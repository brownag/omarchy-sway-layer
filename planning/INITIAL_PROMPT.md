# TASK: Build `omarchy-sway-layer` — Portable Sway/i3 Compatibility Layer for Omarchy

## Objective
Create an idempotent, self-contained CLI tool and dotfiles installer in this empty repository.
The goal is to translate and inject Sway/i3 workflows, keybindings, container management, and dense system status indicators into a target machine running Omarchy (Hyprland + Wayland stack), without modifying upstream `/usr/share/omarchy` or `~/.local/share/omarchy` system files.

---

## 1. Core Requirements & Architecture

### A. Repository Structure
Organize the repository cleanly:
```text
omarchy-sway-layer/
├── bin/
│   └── apply-sway-layer        # Main executable entrypoint (bash or python3)
├── config/
│   ├── hypr/
│   │   ├── binds_sway.conf     # Standard Hyprland config snippet
│   │   └── binds_sway.lua      # Lua binding table (for Omarchy v4+)
│   ├── waybar/
│   │   ├── config.jsonc        # Sway/i3-dense Waybar layout
│   │   └── style.css           # Minimalist compact i3-like CSS styling
│   └── quickshell/             # Fallback Omarchy bar override if Waybar is inactive
│       └── BarOverrides.qml
├── scripts/
│   ├── detect_omarchy.sh       # Detection for Omarchy version, config engine, and bar type
│   └── backup.sh               # Safe backup of ~/.config/hypr and ~/.config/waybar
├── Makefile                    # Targets: test, install, uninstall, lint
└── README.md                   # Installation, rollback, and verification guide

```

### B. Configuration Logic: Hyprland / Omarchy

The agent must support both Omarchy configuration models:

1. **Plain Hyprland Conf Model (`hyprland.conf`):**
* Inject `source = ~/.config/hypr/binds_sway.conf` into `~/.config/hypr/hyprland.conf` or `~/.config/hypr/user_custom.conf` without duplicates.


2. **Lua Dynamic Engine Model (`bindings.lua`):**
* Detect if Omarchy loads `bindings.lua` or `looknfeel.lua`. If present, write a clean Lua module `~/.config/hypr/sway_bindings.lua` and add `pcall(require, "sway_bindings")` cleanly to `bindings.lua`.



### C. Keybinding Specification (Strict Sway/i3 Translation)

The generated binds must implement:

* **Directional Focus (HJKL):** `SUPER + {h,j,k,l}` -> `movefocus {l,d,u,r}`
* **Move Container (HJKL):** `SUPER + SHIFT + {h,j,k,l}` -> `movewindow {l,d,u,r}`
* **Splits:** `SUPER + b` (split toggle/horizontal), `SUPER + v` (vertical split toggle), `SUPER + e` (layout toggle)
* **Workspaces:** `SUPER + [1-0]` -> workspace 1-10; `SUPER + SHIFT + [1-0]` -> movetoworkspace 1-10
* **Kill Window:** Both `SUPER + SHIFT + q` and `SUPER + q` -> `killactive`
* **Float & Fullscreen:** `SUPER + SHIFT + space` -> `togglefloating`; `SUPER + f` -> `fullscreen, 0`
* **Scratchpad:**
* `SUPER + SHIFT + minus` -> `movetoworkspacesilent, special:scratchpad`
* `SUPER + minus` -> `togglespecialworkspace, scratchpad`


* **Resize Submap (Modal):**
* Enter via `SUPER + r`.
* Keys `h, j, k, l` execute `resizeactive` by 20px increments.
* Exit via `Return` or `Escape`.



### D. Dense Status Bar (Waybar vs. Quickshell Strategy)

Omarchy's default Quickshell bar provides minimal aesthetic information. We need the dense information density typical of Sway/i3 setups (workspaces, active window, detailed CPU/RAM, disk `/` and `/home`, network IP/traffic, thermal sensors, battery, volume, and formatted date/time).

The installer must:

1. **Provide a full Waybar configuration (`config.jsonc` + `style.css`):**
* Compact height (24px to 26px), square edges, monospace font (`JetBrains Mono` or system mono), high-contrast badges.
* Modules left: `hyprland/workspaces` (numbered 1-10, urgent alerts), `hyprland/window` (compact title).
* Modules center: Minimal clock or scratchpad status.
* Modules right: `cpu` (load % + frequency), `memory` (used / total GiB), `disk` (free space), `temperature`, `network` (SSID/interface + down/up speeds), `pulseaudio` (volume + mute state), `battery`, `clock` (ISO or format with week number), `tray`.


2. **Handle Bar Execution:**
* Detect whether Omarchy is launching Quickshell or Waybar on startup.
* If Omarchy launches Quickshell, provide an optional switch: disable Quickshell bar service and enable `exec-once = waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css`.
* Provide an alternative Quickshell override for users who prefer to keep the native Omarchy bar process but inject dense monitoring widgets.



---

## 2. CLI Tool Requirements (`bin/apply-sway-layer`)

1. **Idempotency:** Running the script multiple times must never create duplicate configuration lines.
2. **Safety & Rollback:**
* Always create a timestamped backup directory at `~/.config/omarchy-sway-backup/<TIMESTAMP>/` before touching any file.
* Provide a `--rollback` or `--uninstall` flag that restores the pre-install state.


3. **Dry Run:** Support `-n` / `--dry-run` to print exact diffs before writing files.
4. **Non-Destructive Integration:** Never overwrite existing `hyprland.conf` directly; use dedicated `include` / `source` statements.
5. **Session Reload:** Attempt `hyprctl reload` and `killall -SIGUSR2 waybar` (or restart the bar process) if running under a live Hyprland session.

---

## 3. Deliverables

1. Complete shell/Python scripts with proper error handling (`set -euo pipefail` in Bash).
2. All configuration templates with no placeholders or missing sections.
3. A `Makefile` supporting:
* `make install` -> executes `./bin/apply-sway-layer`
* `make uninstall` -> executes `./bin/apply-sway-layer --uninstall`
* `make test` -> validates syntax of conf, jsonc, lua, and sh scripts.


4. A clear `README.md` explaining:
* How to build and test locally on Ubuntu Sway.
* How to deploy on the target Omarchy machine.
* Key differences between native Sway behavior and Hyprland's layout engine.



Begin implementation by initializing the directory tree and writing the core detection and backup logic.

```

