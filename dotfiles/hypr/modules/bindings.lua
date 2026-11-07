local function command(keys, action, description)
    hl.bind(keys, hl.dsp.exec_cmd(action), { description = description })
end

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
command("SUPER + E", "thunar", "Abrir arquivos")
command("SUPER + Return", "kitty", "Abrir terminal")
command("SUPER + Space", "rofi -show drun", "Abrir aplicativos")
command("SUPER + SHIFT + Space", [[bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/theme.sh" menu]], "Escolher tema")
command("SUPER + SHIFT + Return", [[browser=$(xdg-settings get default-web-browser); [ -n "$browser" ] && gtk-launch "$browser"]], "Abrir navegador padrão")
command("SUPER + L", [[bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/lock.sh"]], "Bloquear sessão")

command("SUPER + SHIFT + S", [[
    region=$(slurp) && [ -n "$region" ] &&
    bash -o pipefail -c 'grim -g "$1" - | wl-copy' -- "$region" &&
    notify-send "Captura de tela" "Região copiada para a área de transferência"
]], "Capturar região")

for _, key in ipairs({ "Left", "Right", "Up", "Down" }) do
    local direction = key:lower()
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 9 do
    local key = tostring(workspace)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = key }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
end

command("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Aumentar volume")
command("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Diminuir volume")
command("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "Silenciar áudio")
command("XF86MonBrightnessUp", "brightnessctl -c backlight set 5%+", "Aumentar brilho")
command("XF86MonBrightnessDown", "brightnessctl -c backlight set 5%-", "Diminuir brilho")
