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
hl.window_rule({
	name = "kitty-floating",
	match = { class = "^kitty$" },
	float = true,
	center = true,
	size = { "monitor_w*0.70", "monitor_h*0.65" },
	suppress_event = "maximize",
})
hl.config({
	general = {
		gaps_in = 6, -- Espaço entre janelas lado a lado.
		gaps_out = 12, -- Espaço entre as janelas e a borda da tela.
	},
})
