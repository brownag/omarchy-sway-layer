local bindings, unbound, submaps = {}, {}, {}
local current_submap = "reset"
local function dispatcher(name)
    return function(options)
        return { name = name, options = options }
    end
end
hl = {
    unbind = function(key) unbound[key] = true end,
    bind = function(key, action, options)
        bindings[key] = { action = action, options = options, submap = current_submap }
    end,
    define_submap = function(name, reset_or_fn, fn)
        assert(type(name) == "string")
        local callback = type(reset_or_fn) == "function" and reset_or_fn or fn
        assert(type(callback) == "function", "submap callback must be provided")
        submaps[name] = true
        current_submap = name
        callback()
        current_submap = "reset"
    end,
    dsp = {
        focus = dispatcher("focus"), window = {
            swap = dispatcher("swap"), close = dispatcher("close"),
            float = dispatcher("float"), fullscreen = dispatcher("fullscreen"),
            move = dispatcher("move"), resize = dispatcher("resize"),
        },
        layout = function() return { name = "layout" } end,
        submap = dispatcher("submap"),
        workspace = { toggle_special = dispatcher("scratchpad") },
        group = { toggle = function() return { name = "group-toggle" } end },
        exec_cmd = function(command) return { name = "exec", command = command } end,
    },
}
o = {
    shell_quote = function(value) return "'" .. value .. "'" end,
    bind = function(key, description, action, options)
        hl.bind(key, action, options)
    end,
}
HOME = "/tmp/home"
dofile("config/hypr/binds_sway.lua")

for direction, keys in pairs({
    l = { "H", "LEFT" }, d = { "J", "DOWN" },
    u = { "K", "UP" }, r = { "L", "RIGHT" },
}) do
    local focus_key = bindings["SUPER + " .. keys[1]].action
    local focus_arrow = bindings["SUPER + " .. keys[2]].action
    assert(focus_key.name == "focus" and focus_arrow.name == "focus", "focus aliases must use directional focus")
    assert(focus_key.options.direction == direction and focus_arrow.options.direction == direction)

    local move_key = bindings["SUPER + SHIFT + " .. keys[1]].action
    local move_arrow = bindings["SUPER + SHIFT + " .. keys[2]].action
    assert(move_key.name == "exec" and move_arrow.name == "exec", "movement aliases must use context action")
    assert(move_key.command == move_arrow.command)
    assert(move_key.command:match("sway%-group%-move' lua " .. direction .. "$"))
end

assert(unbound["SUPER + Q"] and unbound["SUPER + W"])
assert(bindings["SUPER + D"].action.name == "exec")
assert(bindings["SUPER + D"].action.command == "bemenu-run")
assert(bindings["SUPER + W"].action.name == "group-toggle")
assert(bindings["SUPER + SHIFT + Q"].action.name == "close")
assert(bindings["SUPER + B"].action.name == "layout" and bindings["SUPER + V"].action.name == "layout")
assert(not bindings["SUPER + Q"])
assert(not unbound["SUPER + G"] and not unbound["SUPER + ALT + LEFT"])

assert(submaps.resize, "resize submap must be registered")
local entry = bindings["SUPER + R"]
assert(entry.action.name == "submap" and entry.action.options == "resize")
for direction, mapping in pairs({
    H = { arrow = "LEFT", x = -20, y = 0 },
    J = { arrow = "DOWN", x = 0, y = 20 },
    K = { arrow = "UP", x = 0, y = -20 },
    L = { arrow = "RIGHT", x = 20, y = 0 },
}) do
    local key = bindings[direction]
    local arrow = bindings[mapping.arrow]
    for _, item in ipairs({ key, arrow }) do
        assert(item.submap == "resize", "resize aliases must be registered inside resize mode")
        assert(item.action.name == "resize", "resize alias must dispatch resize")
        assert(item.action.options.x == mapping.x and item.action.options.y == mapping.y)
        assert(item.action.options.relative == true)
    end
end
for _, key in ipairs({ "RETURN", "ESCAPE" }) do
    local exit = bindings[key]
    assert(exit.submap == "resize" and exit.action.name == "submap")
    assert(exit.action.options == "reset")
end
for _, key in ipairs({ "SUPER + CTRL + H", "SUPER + CTRL + J", "SUPER + CTRL + K", "SUPER + CTRL + L" }) do
    assert(bindings[key] == nil, "obsolete direct-resize chord must be removed")
end
print("test-sway-bindings: passed")
