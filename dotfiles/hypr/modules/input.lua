-- The optional keymap exists only inside this Hyprland instance's runtime.
local runtime = os.getenv("XDG_RUNTIME_DIR")
local instance = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
if runtime and instance then
    local keymap = runtime .. "/rice-thinkpad-" .. instance .. ".xkb"
    local file = io.open(keymap, "r")
    if file then
        file:close()
        hl.config({ input = { kb_file = keymap } })
    end
end
