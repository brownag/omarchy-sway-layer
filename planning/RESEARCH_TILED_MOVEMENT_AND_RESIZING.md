# Research: Moving and resizing tiled windows in Sway vs Omarchy/Hyprland

## Summary

The described `Super+Shift+Down` action is **not a default binding established by this repository**. In its plain Hyprland configuration, `Super+Shift+j` (not Down) invokes `movewindow,d`, which moves the active window downward in the tiling tree; arrows have no such binding in that file. Omarchy Lua mode uses context-aware directional actions, so a downward move can become a rearrangement/swap or a group operation depending on the neighbor/group state—not a guarantee that a two-window vertical split flips to a horizontal split. For resizing, this repo defines a 20-pixel modal resize mode in plain config and 20-pixel Ctrl+direction chords in Lua mode.

## Findings

1. **Claim:** The repo's plain Hyprland bindings do not bind `Super+Shift+Down`; they bind `Super+Shift+j` to `movewindow,d`. `Super+h/j/k/l` changes focus; `Super+b/v` toggles split orientation, and `Super+e` sends `togglesplit`. **Sources:** [plain Hyprland bindings](../config/hypr/binds_sway.conf); [project README](../README.md#keybindings). **Support:** direct evidence. **Confidence:** high.
   - Thus, if the question refers to the project plain-config layer, the exact Down-arrow chord is not configured here. Changing a container's split orientation is a separate action, not an asserted side effect of `movewindow`.

2. **Claim:** In Omarchy Lua mode, the README documents `Super+Shift+h/j/k/l` and arrow equivalents as context-aware: when neither active window nor neighbor is grouped, the action moves or swaps the focused window in that direction; a grouped neighbor causes join behavior; a focused grouped window can be moved out of its group. **Sources:** [project README, Lua mode](../README.md#omarchy-lua-mode-groups-and-directional-actions); [Omarchy default tiling bindings](https://github.com/basecamp/omarchy/blob/master/default/hypr/bindings/tiling.lua). **Support:** README is direct evidence of this project's documented behavior; official upstream link provides primary-source follow-up. **Confidence:** medium (no local upstream Omarchy file or live session inspected).
   - **Interpretation:** The reported result—selected tile moves down and the visible arrangement becomes horizontal—may be a consequence of the current container tree and directional move/swap semantics, but this repo does not establish it as a universal “change split orientation” behavior. Do not equate movement with an explicit split toggle.

3. **Claim:** The recommended resize bindings in the project are `Super+r`, then `h/j/k/l` for 20-pixel steps in plain config, exiting with Return or Escape; Lua mode instead uses `Super+Ctrl+h/j/k/l` for 20-pixel resize steps and has no modal submap. **Sources:** [plain Hyprland bindings](../config/hypr/binds_sway.conf); [project README](../README.md#keybindings). **Support:** direct evidence. **Confidence:** high.
   - For a tiled pair, use the resize action/chord in the axis needed to adjust the boundary. Exact behavior depends on active window, layout, and Hyprland version; this repo does not claim live-session verification.

4. **Claim:** Sway distinguishes moving a window/container from changing layout; its manual documents `move [direction]` and `layout splith|splitv|tabbed|stacking`. Hyprland's official dispatcher reference documents `movewindow` separately from split/layout dispatchers; its resizing dispatcher is `resizeactive`. **Sources:** [Sway manual, `sway(5)`](https://github.com/swaywm/sway/blob/master/sway/sway.5.scd); [Hyprland dispatchers](https://wiki.hypr.land/Configuring/Dispatchers/). **Support:** official documentation references; not fetched/independently checked in this run. **Confidence:** medium.
   - These docs are useful primary references, but the precise outcome of a move in a particular two-tile tree should be verified against the installed compositor/version.

## Contradictions

None found in inspected repo materials. There is an important distinction between plain-config and Lua-mode bindings: README explicitly says the plain-config path is unchanged while Lua mode supplies the context-aware behavior. Treating the two as identical would be unsupported.

## Missing evidence

- No web-fetch/search tool was available and no live Sway or Omarchy/Hyprland session was run. Official documentation links above are follow-up references, not claims that their current wording was inspected in this run.
- The exact upstream default behavior for `Super+Shift+Down` on a particular Omarchy release is not verified. The repository README and binding file are project-layer evidence, not a snapshot of a machine's installed Omarchy defaults.
- Actual result depends on active layout/tree, installed Hyprland/Omarchy version, and user overrides.

## Sources

- Kept: [Project plain Hyprland bindings](../config/hypr/binds_sway.conf) — exact configured keys/actions and resize submap.
- Kept: [Project README](../README.md) — documents integration mode differences, Lua-mode directional behavior, and resize methods.
- Follow-up primary references: [Omarchy upstream tiling bindings](https://github.com/basecamp/omarchy/blob/master/default/hypr/bindings/tiling.lua), [Hyprland dispatchers](https://wiki.hypr.land/Configuring/Dispatchers/), [Sway manual source](https://github.com/swaywm/sway/blob/master/sway/sway.5.scd).
- Rejected/deprioritized: third-party explainers — omitted because repo configuration and official references are preferable, and no web search was available.

## Next steps

On the target machine, inspect loaded bindings and compositor versions, then test the Down action with two tiles in each relevant layout. Use the explicit split toggle if the goal is to change orientation; use the layer's resize binding when the goal is only to alter the boundary.
