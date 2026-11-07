#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}
theme=${1:-}
if [[ $theme == menu ]]; then
    theme=$(printf '%s\n' nord gruvbox catppuccin solitude | rofi -dmenu -i -no-custom -p Tema) || exit 0
fi
case $theme in nord|gruvbox|catppuccin|solitude) ;; *) exit 2 ;; esac

read -r base text accent < "$config/hypr/themes/$theme"
for color in "$base" "$text" "$accent"; do
    [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1
done

# A segunda linha, quando presente, define as 16 cores ANSI do Kitty.
ansi_colors=()
{
    read -r _
    read -r -a ansi_colors || true
} < "$config/hypr/themes/$theme"
if (( ${#ansi_colors[@]} )); then
    (( ${#ansi_colors[@]} == 16 )) || exit 1
    for color in "${ansi_colors[@]}"; do
        [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1
    done
fi

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
printf '* { base: #%s; text: #%s; accent: #%s; panel: #%sd6; background-color: transparent; text-color: @text; }\n' "$base" "$text" "$accent" "$base" |
    write_colors "$config/rofi/colors.rasi"
{
    printf 'background #%s\nforeground #%s\nselection_background #%s\n' "$base" "$text" "$accent"
    printf 'selection_foreground #%s\ncursor #%s\ncursor_text_color #%s\n' "$base" "$accent" "$base"
    printf 'tab_bar_background #%s\ninactive_tab_background #%s\ninactive_tab_foreground #%s\n' "$base" "$base" "$text"
    printf 'active_tab_background #%s\nactive_tab_foreground #%s\n' "$accent" "$base"
    if (( ${#ansi_colors[@]} )); then
        for index in "${!ansi_colors[@]}"; do
            printf 'color%s #%s\n' "$index" "${ansi_colors[index]}"
        done
    fi
} | write_colors "$config/kitty/colors.conf"
printf 'return { base = "%s", text = "%s", accent = "%s" }\n' "$base" "$text" "$accent" |
    write_colors "$config/hypr/modules/colors.lua"
printf '%s\n' "$theme" | write_colors "$config/hypr/current-theme"

if [[ ${2:-} != --offline ]]; then
    if ! bash "$config/hypr/scripts/gtk-theme.sh" "$theme"; then
        printf "Não foi possível aplicar o tema GTK.\n" >&2
    fi
    # Libera a paleta antes de pedir à rotação que leia o tema publicado.
    flock -u 9
    if ! bash "$config/hypr/scripts/wallpaper.sh" next; then
        printf 'Não foi possível aplicar o wallpaper do tema.\n' >&2
    fi
    hyprctl reload
    if pgrep -u "$UID" -x swaync >/dev/null; then swaync-client --reload-css; fi
    if pgrep -u "$UID" -x kitty >/dev/null; then pkill -USR1 -u "$UID" -x kitty; fi
fi

exit 0
