-- Atalhos que executam um comando externo.
local function command(keys, action, description)
	hl.bind(keys, hl.dsp.exec_cmd(action), { description = description })
end

-- Janelas
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Use as setas para mudar o foco. Com Shift, mova a janela.
for _, key in ipairs({ "Left", "Right", "Up", "Down" }) do
	local direction = key:lower()
	hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

-- Super + número troca de workspace. Com Shift, envia a janela para ele.
for workspace = 1, 9 do
	local key = tostring(workspace)
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = key }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
end

-- Deslize três dedos para trocar de workspace, incluindo os vazios.
hl.config({
    gestures = {
        workspace_swipe_use_r = true,
        workspace_swipe_distance = 160,
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Mouse. Segure Super e arraste com o botão esquerdo ou direito.
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {
	mouse = true,
	description = "Mover janela com o mouse",
})

hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {
	mouse = true,
	description = "Redimensionar janela com o mouse",
})

-- Aplicativos
command("SUPER + E", "thunar", "Abrir arquivos")
command("SUPER + Return", "kitty", "Abrir terminal")
command("SUPER + Space", "rofi -show drun", "Abrir aplicativos")

command(
	"SUPER + SHIFT + Return",
	[[browser=$(xdg-settings get default-web-browser); [ -n "$browser" ] && gtk-launch "$browser"]],
	"Abrir navegador padrão"
)

-- Temas. Neste teclado, use o Shift direito para essa combinação.
command(
    "SUPER + SHIFT + Space",
    [[bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/theme.sh" menu]],
    "Escolher tema"
)

command("SUPER + L", [[bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/lock.sh"]], "Bloquear sessão")

-- Captura de tela
-- O slurp seleciona a região. O aviso só aparece se a captura e a cópia funcionarem.
command(
	"SUPER + SHIFT + S",
	[[
		region=$(slurp) && [ -n "$region" ] &&
		bash -o pipefail -c 'grim -g "$1" - | wl-copy' -- "$region" &&
		notify-send "Captura de tela" "Região copiada para a área de transferência"
	]],
	"Capturar região"
)

-- Avança na fila compartilhada com a troca automática.
command(
	"SUPER + SHIFT + W",
	[[bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/wallpaper.sh" next]],
	"Próximo wallpaper"
)

-- Escolhe um item e o coloca na área de transferência para colar com Ctrl + V.
command("SUPER + V", [[
    selection=$(cliphist list | rofi -dmenu -i -no-custom -p 'Histórico de cópia') &&
    [ -n "$selection" ] && printf '%s\n' "$selection" | cliphist decode | wl-copy
]], "Histórico de cópia")

-- Teclas físicas de áudio e brilho
command("XF86AudioRaiseVolume", "swayosd-client --output-volume raise --max-volume 100 || wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Aumentar volume")
command("XF86AudioLowerVolume", "swayosd-client --output-volume lower || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Diminuir volume")
command("XF86AudioMute", "swayosd-client --output-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "Silenciar áudio")
command("XF86MonBrightnessUp", "swayosd-client --brightness +5 || brightnessctl -c backlight set 5%+", "Aumentar brilho")
command("XF86MonBrightnessDown", "swayosd-client --brightness -5 || brightnessctl -c backlight set 5%-", "Diminuir brilho")
