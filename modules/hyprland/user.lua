-- Loaded last by the official Caelestia hyprland.lua; keybinds chosen to avoid every official bind.

hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.95", position = "auto-right", scale = 1 })

local layouts = { "dwindle", "scrolling", "master", "monocle" }

local function set_layout(name)
    hl.config({ general = { layout = name } })
    hl.notification.create({ text = "Layout: " .. name, duration = 1500 })
end

hl.bind("SUPER + SHIFT + Space", function()
    local current = hl.get_config("general.layout")
    local next_layout = layouts[1]
    for i, name in ipairs(layouts) do
        if name == current then
            next_layout = layouts[i % #layouts + 1]
        end
    end
    set_layout(next_layout)
end)

local scrolling = {
    ["SUPER + bracketleft"] = "colresize -conf",
    ["SUPER + bracketright"] = "colresize +conf",
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

hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("vpn-toggle"))
