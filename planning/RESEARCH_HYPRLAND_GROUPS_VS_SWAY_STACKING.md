# Hyprland groups vs. Sway stacking

## Summary

Hyprland window groups are a useful **tabbed-window approximation**, not a direct equivalent of Sway's `layout stacking`. Sway stacking is a container layout that shows one child at a time with its title bar in a vertical stack; Hyprland groups group individual windows and expose tab/group controls. A `SUPER+w` group toggle could fit the muscle memory better, but on this Omarchy install that key currently closes the active window, so that default must be explicitly unbound/reassigned before using it.

## Behavior comparison

- **Sway stacking:** The Sway project manual describes `stacking` as a container layout where only the focused child is shown, with the child title bars arranged one below another. This is a layout applied to a container's children. [Sway `sway(5)` source, `layout` section](https://github.com/swaywm/sway/blob/master/sway/sway.5.scd)
- **Hyprland groups:** Hyprland documents groups as collections of windows with one active member and group-bar/tab controls. Its group actions include `togglegroup`, `changegroupactive`, `moveintogroup`, and `moveoutofgroup`. This changes group membership and active group member; it does not switch a Sway container or workspace into a stacking layout. [Hyprland Groups](https://wiki.hypr.land/Configuring/Groups/); [Hyprland Dispatchers, group section](https://wiki.hypr.land/Configuring/Dispatchers/#group)
- **Closest fit:** `togglegroup` is a convenient way to group/ungroup the focused window. To include a neighboring window in an existing group, use `moveintogroup` with a direction. `changegroupactive` cycles the active member within that group; it does not move focus through arbitrary workspace containers. These are tabbed-group behaviors, not an exact Sway stacking implementation. [Hyprland Dispatchers, group section](https://wiki.hypr.land/Configuring/Dispatchers/#group)

## Omarchy keybinding evidence

- This machine's Omarchy default binds `SUPER + W` to close the active window: `/usr/share/omarchy/default/hypr/bindings/tiling.lua:1` (`o.bind("SUPER + W", "Close window", hl.dsp.window.close())`).
- Omarchy's own group examples use `hl.dsp.group.toggle()`, `.next()`, and `.prev()` in `/usr/share/omarchy/default/hypr/bindings/tiling.lua:73,81-82`; the dispatcher wrapper is used with `o.bind`.
- The project plain-config template instead assigns `SUPER+q` and `SUPER+SHIFT+q` to close: `config/hypr/binds_sway.conf`. The live Omarchy default and project template therefore differ; do not infer one from the other.

## Recommendation

If the goal is an i3/Sway-like tabbed stack, a close approximation is:

1. Assign `SUPER+w` to Hyprland group toggle, after explicitly unbinding Omarchy's close action.
2. Provide a distinct binding to move the focused window into an adjacent group (directional `moveintogroup`) and bindings to cycle group members (`changegroupactive` forward/backward).
3. Keep window close on an agreed key such as `SUPER+q` (after checking for conflicts).

This approximates tabbed presentation and per-group cycling. It does **not** apply Sway's stacking layout to a container, and grouping behavior/appearance should be tested on the installed Hyprland version before treating it as equivalent.

## Sources

- Sway project source manual: [`sway/sway.5.scd`](https://github.com/swaywm/sway/blob/master/sway/sway.5.scd), `layout` command.
- Hyprland official docs: [Groups](https://wiki.hypr.land/Configuring/Groups/) and [Dispatchers](https://wiki.hypr.land/Configuring/Dispatchers/#group).
- Installed Omarchy source: `/usr/share/omarchy/default/hypr/bindings/tiling.lua` (local bindings/actions cited above); `/usr/share/omarchy/default/hypr/helpers.lua:92-106` (`o.bind` delegates to `hl.bind`). These are read-only system references.
- Project source: `config/hypr/binds_sway.conf`.
