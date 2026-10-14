-- Omarchy Lua-engine bindings for the Sway/i3-style keymap.
-- Uses Omarchy's `o.bind` / `hl.dsp` API; the plain Hyprland path is in
-- binds_sway.conf.

local function bind(keys, description, dispatcher)
    hl.unbind(keys)
    o.bind(keys, description, dispatcher)
end

local config_home = os.getenv("XDG_CONFIG_HOME")
if not config_home or config_home == "" then
    config_home = (os.getenv("HOME") or "") .. "/.config"
end

local function context_move(direction)
    return hl.dsp.exec_cmd(o.shell_quote(config_home .. "/hypr/sway-group-move") .. " " .. direction)
end

local directions = {
    { key = "H", direction = "l", arrow = "LEFT" },
    { key = "J", direction = "d", arrow = "DOWN" },
    { key = "K", direction = "u", arrow = "UP" },
    { key = "L", direction = "r", arrow = "RIGHT" },
}

for _, item in ipairs(directions) do
    bind("SUPER + " .. item.key, "Focus " .. item.direction, hl.dsp.focus({ direction = item.direction }))
    bind("SUPER + SHIFT + " .. item.key, "Move or group window " .. item.direction, context_move(item.direction))
    bind("SUPER + SHIFT + " .. item.arrow, "Move or group window " .. item.direction, context_move(item.direction))
end

-- Omarchy exposes a layout toggle without an explicit horizontal/vertical option.
bind("SUPER + B", "Toggle horizontal split", hl.dsp.layout("togglesplit"))
bind("SUPER + V", "Toggle vertical split", hl.dsp.layout("togglesplit"))
bind("SUPER + E", "Toggle split layout", hl.dsp.layout("togglesplit"))

for workspace = 1, 10 do
    local key = workspace == 10 and "0" or tostring(workspace)
    bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
    bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

hl.unbind("SUPER + Q")
bind("SUPER + W", "Toggle window grouping", hl.dsp.group.toggle())
bind("SUPER + SHIFT + Q", "Close window", hl.dsp.window.close())
bind("SUPER + SHIFT + SPACE", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + SHIFT + MINUS", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
bind("SUPER + MINUS", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))

-- Omarchy's Lua binding API has no documented submap option. Keep resizing
-- available with dedicated chords; the plain-config variant retains SUPER+R mode.
local resize = {
    { key = "H", x = -20, y = 0 },
    { key = "J", x = 0, y = 20 },
    { key = "K", x = 0, y = -20 },
    { key = "L", x = 20, y = 0 },
}
for _, item in ipairs(resize) do
    bind("SUPER + CTRL + " .. item.key, "Resize window", hl.dsp.window.resize({ x = item.x, y = item.y, relative = true }))
end
