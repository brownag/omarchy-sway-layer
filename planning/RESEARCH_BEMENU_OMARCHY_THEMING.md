# Research: Theming and centering bemenu for Omarchy — validated

## Summary

"bmenu" is **`bemenu`** — a standalone Wayland dmenu clone, installed here as
`bemenu 0.6.23-1` (`/usr/bin/bemenu`, `/usr/bin/bemenu-run`). Omarchy does not ship
or theme it; Omarchy's own app menu (`SUPER+SPACE`) is a Quickshell plugin. This repo
already binds `SUPER+D` to `bemenu-run`
(`config/hypr/binds_sway.conf:23`, `config/hypr/binds_sway.lua:35`).

All of bemenu's appearance is CLI flags, and `-c/--center` centers it. Omarchy exposes
the live palette at a stable path with a resolver CLI, so the solution is a
**runtime wrapper** (`bemenu-themed`) that reads the current theme on every invocation
and `exec`s `bemenu`/`bemenu-run` with themed, centered flags. No template and no
theme-change hook are needed.

This document is the input to **plan-wave**. Every fact below is resolved against a
primary source (upstream bemenu source at a pinned commit, the installed man page, or
the installed Omarchy scripts); there is no open factual question. The only remaining
open items are **user decisions**, listed at the end.

### Sources and pins

- Upstream bemenu: `github.com/Cloudef/bemenu`, master commit
  `44b82f9f3fb9` (2025-08-29); release tag `0.6.23` = commit `6f0fd2ea4ce3`.
  The files cited below were fetched from raw.githubusercontent.com at that commit.
- Installed: `bemenu 0.6.23-1`, man page `/usr/share/man/man1/bemenu.1.gz`.
- Omarchy: scripts under `/usr/share/omarchy/bin/`, live theme under
  `~/.local/state/omarchy/current/theme/`.
- Repo: `/home/andrew/workspace/omarchy-sway-layer`.

Verified during backfill: the installed **0.6.23** styling/option surface is identical
to current master — `lib/menu.c` and `client/common/common.c` diff clean against tag
`0.6.23`, and the only man-page delta since the tag is the added `--counter`
documentation. There is no version drift to guard against.

---

## Validated facts

### A. bemenu styling surface (Wayland backend)

1. **Colors are CLI flags, `#RRGGBB` or `#RRGGBBAA`.** `bm_menu_set_color()`
   parses with `sscanf(nhex, "#%2x%2x%2x%2x", ...)` and accepts a match of 3 or 4
   pairs (`lib/menu.c:420-442`). Six-digit and eight-digit hex both work; Omarchy only
   emits six-digit hex, so its values pass through verbatim. bemenu stores the green
   and blue channels in swapped internal fields (`.b` receives the second pair, `.g`
   the third) and the cairo renderer swaps them back on draw
   (`cairo_set_source_rgba(cr, c.r, c.b, c.g, c.a)`, `lib/renderers/cairo_renderer.h`);
   both Wayland and X11 use that renderer. **Net: standard CSS hex renders correctly.**
   *Source:* upstream `lib/menu.c`, `lib/renderers/cairo_renderer.h`; man page
   ("Each takes an argument in the form of `#RGB[A]`").

2. **Color flags:** `--tb/--tf` title, `--fb/--ff` filter, `--cb/--cf` cursor,
   `--nb/--nf` normal, `--hb/--hf` highlighted, `--sb/--sf` selected, `--fbb/--fbf`
   feedback, `--ab/--af` alternating, `--scb/--scf` scrollbar, and `--bdr` border.
   *Source:* man page; `bemenu --help`.

3. **Other styling flags:** `--fn <name [size]>` (a Pango
   `pango_font_description_from_string` string, so quote the whole value),
   `-B/--border`, `-R/--border-radius`, `-H/--line-height`, `--hp` horizontal padding,
   `--ch/--cw`, `--scrollbar`, `--counter`, `--fixed-height`.
   *Source:* man page.

4. **`BEMENU_OPTS` is applied before argv; CLI wins.** `parse_args()` runs
   `do_getopt()` on `BEMENU_OPTS` first, then on the real `argv`
   (`client/common/common.c:550-558`); later options overwrite earlier ones. Quoting
   is supported (`tokenize_quoted_to_argv`). Consequently the wrapper's CLI flags
   override any user `BEMENU_OPTS` and no `unset` is required.
   *Source:* upstream `client/common/common.c`.

### B. Centering and geometry

5. **`-c/--center` centers on both axes.** `case 'c'` sets `client->center`, and
   `menu_with_options()` maps it to `bm_menu_set_align(menu, BM_ALIGN_CENTER)`
   (`client/common/common.c:598-604`). The Wayland renderer turns `BM_ALIGN_CENTER`
   into **no layer anchors at all** (`anchor = 0`,
   `lib/renderers/wayland/window.c:221-235`), which the layer-shell protocol centers
   horizontally and vertically on the output. `-b/--bottom` maps to `BM_ALIGN_BOTTOM`,
   otherwise `BM_ALIGN_TOP` is the default.
   *Source:* upstream `client/common/common.c`, `lib/renderers/wayland/window.c`.

6. **Default centering geometry.** Width = `output_width * width_factor` capped by
   the margin (`get_window_width`, `window.c:332-344`), with `width_factor` defaulting
   to 0 → treated as 1 (full output width) and margin defaulting to 0. Height is the
   content height unless `--fixed-height`. So bare `-c` yields a full-width menu
   centered vertically; add `-W` to narrow it.
   *Source:* upstream `lib/renderers/wayland/window.c`; `client/common/common.c` option
   handling.

7. **`-M/--margin` is a horizontal (left/right) inset.** It is stored as
   `hmargin_size` and applied as `width - 2 * hmargin_size`
   (`window.c:332-344`); the man page calls these the "vertical view borders". It
   reduces width symmetrically and, under center alignment, the menu stays centered.
   *Source:* upstream `lib/renderers/wayland/window.c`; man page.

8. **`-n/--no-overlap` makes bemenu avoid panels (it does *not* go on top of them).**
   `case 'n'` sets `no_overlap`, and `menu_with_options()` calls
   `bm_menu_set_panel_overlap(menu, !client->no_overlap)`
   (`client/common/common.c:426-427,590`). The Wayland renderer sets
   `exclusive_zone = overlap ? -1 : 0` (`window.c:418-425`): without `-n`,
   `exclusive_zone = -1` lets the menu ignore other panels; with `-n`,
   `exclusive_zone = 0` makes it respect their reserved zones. The installed
   `--help` text ("adjust geometry to not overlap with panels") is correct; the man
   page wording ("on top of any other panels") is **wrong**. The apparent
   contradiction is resolved in favour of the source and `--help`.
   *Source:* upstream `client/common/common.c`, `lib/renderers/wayland/window.c`;
   `bemenu --help`.

9. **`--fixed-height` prevents height changes while filtering.** `case 0x090` sets
   `client->fixed_height` (`client/common/common.c:381-382`); man page: "Prevent the
   display from changing height on filter." Use it so the centered menu does not jump
   between invocations with fewer results.
   *Source:* upstream `client/common/common.c`; man page.

10. **`-l/--list "<number> down|up"` sets visible rows and direction;**
    `-m/--monitor` selects the output (Wayland takes a monitor *name*; `-1`/`focused`
    is default, `-2`/`all` is all monitors).
    *Source:* man page.

### C. Omarchy theming pipeline

11. **Live palette path is stable.** `$HOME/.local/state/omarchy/current/theme/colors.toml`
    holds the active palette and `.../current/theme.name` holds the slug
    (`osaka-jade` here). `omarchy-theme-set` stages `next-theme` then swaps it in.
    *Source:* `/usr/share/omarchy/bin/omarchy-theme-set`; the live files.

12. **`omarchy-theme-color` resolves palette keys.** Usage:
    `omarchy-theme-color [--file <colors.toml>] (--all | --raw | <key> [fallback])`,
    defaulting to the live `colors.toml`; it resolves aliases and derived keys
    (`selection_background`, `selection_foreground`, `muted`, `dark_background`,
    `lighter_background`, `bright_*`, `color0..15`, …). Verified: `background` →
    `#111c18`, `selection_background` → `#32473B`, `accent` → `#509475`. It is marked
    `omarchy:hidden=true` (internal helper), so the wrapper keeps a direct-read
    fallback.
    *Source:* `/usr/share/omarchy/bin/omarchy-theme-color`; live invocation.

13. **User templates are rendered, but irrelevant here.** `omarchy-theme-set-templates`
    globs `~/.config/omarchy/themed/*.tpl` before the built-in templates and renders
    into the current theme dir, so a user `bemenu.tpl` *would* render. But it produces
    a static file inside the theme directory that bemenu never reads; a wrapper would
    still be required to consume it. The wrapper's live-read approach is simpler and
    has no staleness. No `bemenu.tpl` exists in Omarchy.
    *Source:* `/usr/share/omarchy/bin/omarchy-theme-set-templates`;
    `/usr/share/omarchy/default/themed/` (absence of `bemenu.tpl`).

14. **A theme-change hook exists if ever needed.** `omarchy-theme-set` runs
    `omarchy-hook theme-set "$THEME_NAME"` and `omarchy-hook` runs
    `~/.config/omarchy/hooks/<name>` plus `~/.config/omarchy/hooks/<name>.d/`. It fires
    on change only, not at login. The chosen solution does not need it.
    *Source:* `/usr/share/omarchy/bin/omarchy-theme-set`, `omarchy-hook`.

15. **Default mono font is `JetBrainsMono Nerd Font`** (Alacritty family; Ghostty
    family/size 12; shell base-size 12). Use `--fn "JetBrainsMono Nerd Font 12"`.
    *Source:* `~/.config/alacritty/alacritty.toml`, `~/.config/ghostty/config`,
    `~/.local/state/omarchy/current/theme/shell.toml`.

### D. Repo integration facts

16. **Binding sites (two, plus a Makefile assertion):**
    - `config/hypr/binds_sway.conf:23` — `bind = SUPER, d, exec, bemenu-run`
    - `config/hypr/binds_sway.lua:35` — `hl.dsp.exec_cmd("bemenu-run")`
    - `Makefile` test target asserts the literal
      `grep -Fq 'bind = SUPER, d, exec, bemenu-run' config/hypr/binds_sway.conf`,
      so changing the binding requires updating the Makefile assertion in the same
      task.
    *Source:* repo inspection.

17. **Installer writes only under `$CONFIG_HOME`.** `write_managed_files()` copies
    `binds_sway.*`, `sway-group-move`, Waybar and Quickshell files into
    `$CONFIG_HOME`; `show_managed_file_diffs()`, `uninstall_layer()` and
    `scripts/backup.sh` enumerate the same set. There is no `~/.local/bin` target
    today, and no `XDG_BIN_HOME` handling. Adding the wrapper there is new
    installer capability (uninstall, dry-run diff and backup must cover it).
    *Source:* `bin/apply-sway-layer`, `scripts/backup.sh`.

18. **`~/.local/bin` is on `PATH`** under Omarchy's env bootstrap.
    *Source:* `/usr/share/omarchy/default/bash/env-bootstrap`.

19. **Validation is `make test`** (bash -n, shellcheck, `jq` on Waybar JSON, `luac`
    on Lua, `bash tests/test-sway-group-move.sh`, `bash tests/test-sway-installer.sh`,
    `lua tests/test-sway-bindings.lua`, plus `grep` assertions). New shell artifacts
    must be added to the bash/shellcheck lists in the Makefile.
    *Source:* `Makefile`.

20. **Repo conventions:** ADRs live in `docs/decisions/` (0001–0003, all Accepted);
    wave plans use `planning/EXECUTION_PLAN_N.md`, `PROMPT_TEMPLATE_N.md`,
    `STATE_N.md` (next N is 4). Installer scripts define `fail()` and use
    `set -euo pipefail`.
    *Source:* `docs/decisions/README.md`, `planning/`.

---

## Solution design

A single self-contained wrapper `scripts/bemenu-themed`, installed to
`~/.local/bin/bemenu-themed`, resolves the live palette per invocation and execs
bemenu centered. Corrected fallback parser included (the earlier draft's `sed` could
not capture the leading `#`).

```sh
#!/usr/bin/env bash
# bemenu-themed — run bemenu/bemenu-run with the active Omarchy theme palette,
# centered. Resolves the live palette on every invocation; no hook or template.
set -euo pipefail

colors_file="${OMARCHY_THEME_COLORS:-$HOME/.local/state/omarchy/current/theme/colors.toml}"

omarchy_color() {
  local key="$1" fallback="${2:-}" value
  if command -v omarchy-theme-color >/dev/null 2>&1 \
     && value=$(omarchy-theme-color --file "$colors_file" "$key" "$fallback" 2>/dev/null) \
     && [[ -n $value ]]; then
    printf '%s' "$value"; return 0
  fi
  value=$(sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"?([^\"]*)\"?.*/\1/p" \
            "$colors_file" 2>/dev/null | head -n1)
  [[ -n $value ]] || value="$fallback"
  printf '%s' "$value"
}

bg=$(omarchy_color background '#111111')
fg=$(omarchy_color foreground '#dddddd')
accent=$(omarchy_color accent "$fg")
sel=$(omarchy_color selection_background "$accent")
muted=$(omarchy_color muted "$fg")
bright=$(omarchy_color bright_foreground "$fg")
lighter=$(omarchy_color lighter_background "$bg")
darker=$(omarchy_color darker_background "$bg")

font="${BEMENU_FONT:-JetBrainsMono Nerd Font 12}"

opts=(
  -c --fixed-height
  -l "${BEMENU_LINES:-10}"
  -W "${BEMENU_WIDTH:-0.4}"
  -M "${BEMENU_MARGIN:-8}"
  -B "${BEMENU_BORDER:-2}"
  -R "${BEMENU_RADIUS:-8}"
  -H "${BEMENU_LINE_HEIGHT:-26}"
  --fn "$font"
  --tb "$bg"      --tf "$fg"
  --fb "$bg"      --ff "$accent"
  --cb "$accent"  --cf "$bg"
  --nb "$bg"      --nf "$fg"
  --hb "$sel"     --hf "$bright"
  --sb "$sel"     --sf "$bright"
  --fbb "$bg"     --fbf "$muted"
  --ab "$lighter" --af "$muted"
  --scb "$darker" --scf "$muted"
)

# No piped stdin -> command runner (current SUPER+D behavior).
# Piped stdin    -> choose from the piped list.
if [[ -t 0 ]]; then
  exec bemenu-run "${opts[@]}" "$@"
else
  exec bemenu "${opts[@]}" "$@"
fi
```

Omarchy-key → bemenu-flag mapping: `--nb=background`, `--nf=foreground`,
`--hb/--sb=selection_background`, `--hf/--sf=bright_foreground`,
`--tb=background`, `--tf=foreground`, `--fb=background`, `--ff=accent`,
`--cb=accent`, `--cf=background`, `--fbb=background`, `--fbf=muted`,
`--ab=lighter_background`, `--af=muted`, `--scb=darker_background`, `--scf=muted`,
plus `--bdr` from `accent` if desired. Geometry defaults:
`-c -l 10 --fixed-height -W 0.4 -M 8 -B 2 -R 8 -H 26`.

---

## Proposed phases (workstreams for plan-wave)

These are the validated workstreams, with dependencies and acceptance. plan-wave
converts them into task specs and a wave table; file overlap is called out where it
forces serialization.

**W1 — Wrapper core (`scripts/bemenu-themed`).**
Implement the wrapper above: palette resolution with resolver + direct-read fallback,
flag assembly, stdin dispatch, `--` pass-through. No repo installer coupling.
*Depends on:* none. *Acceptance:* `bash -n` and `shellcheck` clean; a new
`tests/test-bemenu-themed.sh` exercises the color resolver and the `-t 0` vs piped
dispatch with a stub `bemenu`/`omarchy-theme-color` on `PATH`.
*Files:* `scripts/bemenu-themed`, `tests/test-bemenu-themed.sh`.

**W2 — Binding + docs.**
Repoint `SUPER+D` to `bemenu-themed` in `config/hypr/binds_sway.conf` and
`config/hypr/binds_sway.lua`; update `README.md:28`; update the Makefile grep
assertion to the new binding. *Depends on:* W1 (wrapper name/contract).
*Acceptance:* `make test` green; `grep` assertion matches `bemenu-themed`.
*Files:* `config/hypr/binds_sway.conf`, `config/hypr/binds_sway.lua`, `README.md`,
`Makefile`.

**W3 — Installer support for the wrapper.**
Add `~/.local/bin/bemenu-themed` (or an `$XDG_BIN_HOME`-aware path) as a managed
artifact: copy on install, diff on `--dry-run`, remove on `--uninstall`, include in
`scripts/backup.sh`. Decide default-on vs `--enable-bemenu-themed` opt-in (open
decision D1). *Depends on:* W1. *Acceptance:* `tests/test-sway-installer.sh`
covers install/dry-run/uninstall idempotency for the new target; `make test` green.
*Files:* `bin/apply-sway-layer`, `scripts/backup.sh`, `tests/test-sway-installer.sh`,
`Makefile`.
*Overlap hazard:* W2 and W3 both edit `Makefile`; keep them in different waves, or
assign all Makefile edits to one of them and have the other depend on it.

**W4 — Theme fidelity validation.**
Verify the rendered result under the current dark theme and one light theme
(`omarchy theme set`): confirm text/selection contrast (`--hf/--sf` =
`bright_foreground` on `selection_background`) and that a color value flows through
verbatim (guarding against any channel-order confusion). Record results in the task
report; no code change expected. *Depends on:* W1. *Could fold into W1's test* if a
light-theme palette can be sourced without changing the user's theme.
*Files:* none (report only), or `tests/test-bemenu-themed.sh` fixtures.

Suggested grouping if executed as one plan: **Wave 1 = W1; Wave 2 = W2 (or W3);
Wave 3 = W3 (or W2) and W4.** If the installer change is deemed optional, W1+W2+W4 is
a clean, self-contained first plan and W3 becomes a second plan — this is the
"one or more plans" split point.

---

## Open decisions (for plan-wave / user)

These are choices, not facts; each needs a user answer before the plan is final.

- **D1 — Install scope:** ship the wrapper and install it to `~/.local/bin`
  automatically, install it only under an opt-in flag
  (`--enable-bemenu-themed`), or document it and leave it user-managed? The repo's
  posture so far is opt-in for non-binding extras (`--enable-waybar`).
- **D2 — Default binding:** repoint `SUPER+D` from `bemenu-run` to `bemenu-themed`
  (recommended; the wrapper falls back to plain bemenu behavior if
  `omarchy-theme-color` is absent), or keep the plain binding and add a separate
  chord?
- **D3 — Path policy:** hardcode `~/.local/bin`, or honor `$XDG_BIN_HOME`/`PATH`?
- **D4 — Plan split:** one plan (W1–W4) or two (W1/W2/W4 now, W3 installer later)?
- **D5 — ADR:** is a decision record warranted for "theme bemenu with a live-read
  wrapper rather than a template/hook"? If yes, it would be `docs/decisions/0004-*`.

---

## Source appendix (primary)

Upstream (fetched, pinned to `44b82f9f3fb9`; tag `0.6.23` diffed clean for these):
- `lib/menu.c` — `bm_menu_set_color()` color format and channel storage.
- `lib/renderers/cairo_renderer.h` — channel reorder on draw (Wayland and X11).
- `client/common/common.c` — `parse_args()` (`BEMENU_OPTS` then argv), option cases
  `c`/`b`/`n`, align mapping, `bm_menu_set_panel_overlap`.
- `lib/renderers/wayland/window.c` — `get_align_anchor` (center → no anchors),
  `get_window_width` (width factor/margin), `bm_wl_window_set_overlap`
  (`exclusive_zone`), y-offset.
- `man/bemenu.1.scd.in` — option and color documentation (source of the man page).

Local:
- `/usr/share/man/man1/bemenu.1.gz`; `bemenu --help` (v0.6.23).
- `/usr/share/omarchy/bin/omarchy-theme-color`, `omarchy-theme-set`,
  `omarchy-theme-set-templates`, `omarchy-hook`.
- `/usr/share/omarchy/default/themed/` (no `bemenu.tpl`);
  `~/.local/state/omarchy/current/theme/{colors.toml,theme.name,shell.toml}`.
- `~/.config/alacritty/alacritty.toml`, `~/.config/ghostty/config`.
- Repo: `bin/apply-sway-layer`, `scripts/backup.sh`, `config/hypr/binds_sway.conf`,
  `config/hypr/binds_sway.lua`, `README.md`, `Makefile`, `docs/decisions/README.md`.
