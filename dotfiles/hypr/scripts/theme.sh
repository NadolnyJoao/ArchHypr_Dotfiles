#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}
theme=${1:-}
if [[ $theme == menu ]]; then
    theme=$(printf '%s\n' nord gruvbox catppuccin | rofi -dmenu -i -no-custom -p Tema) || exit 0
fi
case $theme in nord|gruvbox|catppuccin) ;; *) exit 2 ;; esac

read -r base text accent < "$config/hypr/themes/$theme"
for color in "$base" "$text" "$accent"; do
    [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1
done

# Escreve cada arquivo completo antes de substituir a paleta anterior.
write_colors() {
    local target=$1 temp
    temp=$(mktemp -- "${target}.XXXXXXXX")
    if ! cat > "$temp" || ! mv -fT -- "$temp" "$target"; then
        rm -f -- "$temp"
        return 1
    fi
}
exec 9>"$config/hypr/.theme.lock"
flock 9
for component in waybar swaync; do
    printf '@define-color base #%s;\n@define-color text #%s;\n@define-color accent #%s;\n' "$base" "$text" "$accent" |
        write_colors "$config/$component/colors.css"
done
printf '* { base: #%s; text: #%s; accent: #%s; background-color: transparent; text-color: @text; }\n' "$base" "$text" "$accent" |
    write_colors "$config/rofi/colors.rasi"
printf 'background #%s\nforeground #%s\nselection_background #%s\n' "$base" "$text" "$accent" |
    write_colors "$config/kitty/colors.conf"
printf 'return { base = "%s", text = "%s", accent = "%s" }\n' "$base" "$text" "$accent" |
    write_colors "$config/hypr/modules/colors.lua"
printf '%s\n' "$theme" | write_colors "$config/hypr/current-theme"

if [[ ${2:-} != --offline ]]; then
    if ! bash "$config/hypr/scripts/gtk-theme.sh" "$theme"; then
        printf "Não foi possível aplicar o tema GTK.\n" >&2
    fi
    hyprctl reload
    if pgrep -u "$UID" -x swaync >/dev/null; then swaync-client --reload-css; fi
    if pgrep -u "$UID" -x kitty >/dev/null; then pkill -USR1 -u "$UID" -x kitty; fi
fi
