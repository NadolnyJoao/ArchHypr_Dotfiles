local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local palette = loadfile(config .. "/hypr/modules/colors.lua")
if palette then
    local colors = palette()
    hl.config({ general = { ["col.active_border"] = "rgba(" .. colors.accent .. "ff)" } })
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.layer_rule({
    name = "disable-waybar-blur",
    match = { namespace = "waybar" },
    blur = false,
})

hl.config({
    decoration = {
        wobble = {
            enabled = true,
            intensity = 0.3,
            stiffness = 200,
            damping = 12,
            mass = 1,
            mesh = 12,
        },
    },
})
