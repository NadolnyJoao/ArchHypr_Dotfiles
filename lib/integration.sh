#!/usr/bin/env bash
# Componentes cuja instalação envolve dados e preferências além dos dotfiles.

install_nordic_theme() (
    local destination=${XDG_DATA_HOME:-$HOME/.local/share}/themes/Nordic
    local url=https://github.com/EliverLara/Nordic.git stage origin
    if [[ -d $destination/.git && ! -L $destination ]]; then
        origin=$(git -C "$destination" remote get-url origin) || return 1
        if [[ $origin == "$url" && -f $destination/gtk-3.0/gtk.css ]]; then
            git -C "$destination" rev-parse HEAD || return 1
            return 10
        fi
    fi
    mkdir -p -- "$(dirname -- "$destination")" || return 1
    stage=$(mktemp -d -- "$(dirname -- "$destination")/.nordic.XXXXXXXX") || return 1
    trap 'rm -rf -- "$stage"' EXIT
    git clone --depth 1 -- "$url" "$stage" || return 1
    [[ -f $stage/gtk-3.0/gtk.css ]] || return 1
    git -C "$stage" rev-parse HEAD || return 1
    if [[ -e $destination || -L $destination ]]; then
        [[ ! -e $report_dir/backup/Nordic ]] || return 1
        mkdir -p -- "$report_dir/backup" || return 1
        cp -a -- "$destination" "$report_dir/backup/Nordic" || return 1
        rm -rf -- "$destination" || return 1
    fi
    mv -T -- "$stage" "$destination"
)

configure_thunar() {
    local current
    current=$(xfconf-query -c thunar -p /misc-thumbnail-mode 2>/dev/null) || current=
    [[ $current == THUNAR_THUMBNAIL_MODE_ALWAYS ]] && return 10
    xfconf-query -c thunar -p /misc-thumbnail-mode -n -t string -s THUNAR_THUMBNAIL_MODE_ALWAYS || return 1
    [[ $(xfconf-query -c thunar -p /misc-thumbnail-mode) == THUNAR_THUMBNAIL_MODE_ALWAYS ]]
}

install_neovim_associations() {
    local id=rice-arch-neovim.desktop data=${XDG_DATA_HOME:-$HOME/.local/share}
    local result mime changed=10 current
    if deploy_file "$project_dir/dotfiles/applications/$id" "$data" "applications/$id"; then
        changed=0
    else
        result=$?
        (( result == 10 )) || return "$result"
    fi
    update-desktop-database "$data/applications" || return 1
    # Preserve o padrão dos arquivos .txt. Eles recebem apenas a opção "Abrir com".
    for mime in text/x-lua text/x-csrc text/x-chdr text/x-c++src text/x-c++hdr text/x-python application/x-shellscript; do
        current=$(xdg-mime query default "$mime") || return 1
        [[ $current == "$id" ]] && continue
        if [[ -f $config_dir/mimeapps.list && ! -e $report_dir/backup/mimeapps.list ]]; then
            mkdir -p -- "$report_dir/backup" || return 1
            cp -L -- "$config_dir/mimeapps.list" "$report_dir/backup/mimeapps.list" || return 1
        fi
        xdg-mime default "$id" "$mime" || return 1
        [[ $(xdg-mime query default "$mime") == "$id" ]] || return 1
        changed=0
    done
    return "$changed"
}

activate_desktop_theme() {
    local theme
    read -r theme < "$config_dir/hypr/current-theme" || return 1
    # Aplica GTK/ícones agora. A próxima sessão também reaplica a preferência.
    bash "$config_dir/hypr/scripts/gtk-theme.sh" "$theme"
}

check_hyprland_version() {
    local version
    version=$(pacman -Q hyprland) || return 1
    version=${version#hyprland }
    printf 'Hyprland instalado: %s\n' "$version"
    [[ $(vercmp "$version" 0.57.0) -ge 0 ]] || {
        printf 'Este rice requer Hyprland 0.57 ou superior para Lua e wobble.\n' >&2
        return 1
    }
}
