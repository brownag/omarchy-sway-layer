local bindings, unbound = {}, {}
local function dispatcher(name)
    return function(options)
        return { name = name, options = options }
    end
end
hl = {
    unbind = function(key) unbound[key] = true end,
    dsp = {
        focus = dispatcher("focus"), window = {
            swap = dispatcher("swap"), close = dispatcher("close"),
            float = dispatcher("float"), fullscreen = dispatcher("fullscreen"),
            move = dispatcher("move"), resize = dispatcher("resize"),
        },
        layout = function() return { name = "layout" } end,
        workspace = { toggle_special = dispatcher("scratchpad") },
        group = { toggle = function() return { name = "group-toggle" } end },
        exec_cmd = function(command) return { name = "exec", command = command } end,
    },
}
o = {
    shell_quote = function(value) return "'" .. value .. "'" end,
    bind = function(key, description, action)
        bindings[key] = { description = description, action = action }
    end,
}
HOME = "/tmp/home"
dofile("config/hypr/binds_sway.lua")

for direction, keys in pairs({
    l = { "H", "LEFT" }, d = { "J", "DOWN" },
    u = { "K", "UP" }, r = { "L", "RIGHT" },
}) do
    local a = bindings["SUPER + SHIFT + " .. keys[1]].action
    local b = bindings["SUPER + SHIFT + " .. keys[2]].action
    assert(a.name == "exec" and b.name == "exec", "aliases must use context action")
    assert(a.command == b.command and a.command:match("sway%-group%-move' " .. direction .. "$"))
end
assert(unbound["SUPER + Q"] and unbound["SUPER + W"])
assert(bindings["SUPER + W"].action.name == "group-toggle")
assert(bindings["SUPER + SHIFT + Q"].action.name == "close")
assert(not bindings["SUPER + Q"])
assert(not unbound["SUPER + G"] and not unbound["SUPER + ALT + LEFT"])
print("test-sway-bindings: passed")
