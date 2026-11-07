#!/usr/bin/env bash
# Instala os módulos primeiro. O arquivo carregado pelo Hyprland só é
# substituído quando todos os módulos obrigatórios estiverem disponíveis.
install_hyprland_dotfiles() {
    local root=$1 relative result changed=10
    shift
    for relative in "$@"; do
        if deploy_file "$project_dir/dotfiles/$relative" "$root" "$relative"; then
            changed=0
        else
            result=$?
            (( result == 10 )) || return "$result"
        fi
    done
    return "$changed"
}

install_desktop_dotfiles() {
    local root=$1 result changed=10 theme=nord
    mkdir -p -- "$root/hypr/modules" || return 1
    if install_hyprland_dotfiles "$root" \
        hypr/themes/nord hypr/themes/gruvbox hypr/themes/catppuccin hypr/themes/solitude \
        hypr/scripts/theme.sh hypr/scripts/power-menu.sh \
        hypr/scripts/gtk-theme.sh \
        fish/conf.d/rice-arch.fish \
        waybar/config.jsonc waybar/style.css swaync/style.css rofi/config.rasi kitty/kitty.conf; then
        changed=0
    else
        result=$?
        (( result == 10 )) || return "$result"
    fi
    if [[ -f $root/hypr/current-theme ]]; then
        read -r theme < "$root/hypr/current-theme" || return 1
    fi
    if (( changed == 10 )) && [[ -f $root/hypr/modules/colors.lua && -f $root/waybar/colors.css &&
        -f $root/swaync/colors.css && -f $root/rofi/colors.rasi && -f $root/kitty/colors.conf ]]; then
        return 10
    fi
    # Preserve arquivos gerados que já existiam antes desta execução.
    local relative backup
    for relative in waybar/colors.css swaync/colors.css rofi/colors.rasi kitty/colors.conf \
        hypr/modules/colors.lua hypr/current-theme; do
        if [[ -e $root/$relative || -L $root/$relative ]]; then
            backup=$report_dir/backup/$relative
            mkdir -p -- "$(dirname -- "$backup")" || return 1
            cp -a -- "$root/$relative" "$backup" || return 1
        fi
    done
    XDG_CONFIG_HOME="$root" bash "$root/hypr/scripts/theme.sh" "$theme" --offline
}
