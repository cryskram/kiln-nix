-- Loaded last by hyprland.lua. Super+[ / Super+] keep Dux's dwindle preselect and resize columns in scrolling.

local layouts = { "dwindle", "scrolling", "master", "monocle" }

hl.bind("SUPER + SHIFT + Space", function()
    local current = hl.get_config("general.layout")
    local next_layout = layouts[1]
    for i, name in ipairs(layouts) do
        if name == current then
            next_layout = layouts[i % #layouts + 1]
        end
    end
    hl.config({ general = { layout = next_layout } })
    hl.notification.create({ text = "Layout: " .. next_layout, duration = 1500 })
end)

local function per_layout(key, actions)
    hl.bind(key, function()
        local workspace = hl.get_active_workspace()
        local action = actions[workspace and workspace.tiled_layout] or actions.default
        if action then
            hl.dispatch(action)
        end
    end)
end

per_layout("SUPER + bracketleft", {
    scrolling = hl.dsp.layout("colresize -conf"),
    default = hl.dsp.layout("preselect l"),
})
per_layout("SUPER + bracketright", {
    scrolling = hl.dsp.layout("colresize +conf"),
    default = hl.dsp.layout("preselect r"),
})

local scrolling = {
    ["SUPER + SHIFT + bracketleft"] = "swapcol l",
    ["SUPER + SHIFT + bracketright"] = "swapcol r",
    ["SUPER + CTRL + bracketleft"] = "consume_or_expel prev",
    ["SUPER + CTRL + bracketright"] = "consume_or_expel next",
    ["SUPER + backslash"] = "fit visible",
    ["SUPER + SHIFT + backslash"] = "promote",
}

for key, message in pairs(scrolling) do
    hl.bind(key, hl.dsp.layout(message))
end

hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("vpn-toggle"))
