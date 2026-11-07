-- Leia o layout X11 do sistema, quando configurado por localectl.
-- Os dados são lidos a cada recarga e não viram um perfil de hardware no repo.
local input = {}
local fields = {
    ["Layout"] = "kb_layout",
    ["Model"] = "kb_model",
    ["Variant"] = "kb_variant",
    ["Options"] = "kb_options",
}
local status = io.popen("LC_ALL=C localectl status --no-pager 2>/dev/null")
if status then
    for line in status:lines() do
        local field, value = line:match("^%s*X11 (%a+):%s*(.-)%s*$")
        if fields[field] and value ~= "" and value ~= "n/a" then
            input[fields[field]] = value
        end
    end
    status:close()
end
if input.kb_layout then
    hl.config({ input = input })
end

-- Remapeamento opcional, restrito à instância atual do Hyprland.
local runtime = os.getenv("XDG_RUNTIME_DIR")
local instance = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
hl.config({ input = { kb_file = "" } })
if runtime and instance then
    local keymap = runtime .. "/rice-thinkpad-" .. instance .. ".xkb"
    local file = io.open(keymap, "r")
    if file then
        file:close()
        hl.config({ input = { kb_file = keymap } })
    end
end
