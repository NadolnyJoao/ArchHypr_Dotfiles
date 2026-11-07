-- Caminhos absolutos também funcionam quando o Hyprland inicia pelo SDDM.
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local root = config .. "/hypr/"

for _, name in ipairs({ "appearance", "bindings", "input", "session" }) do
    dofile(root .. "modules/" .. name .. ".lua")
end

-- Opcional. Este arquivo pertence à máquina e é ignorado pelo Git.
local monitors = root .. "modules/monitors.local.lua"
local file = io.open(monitors, "r")
if file then
    file:close()
    dofile(monitors)
end
