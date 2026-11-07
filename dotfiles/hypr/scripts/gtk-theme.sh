#!/usr/bin/env bash
# Seleciona um tema GTK3 pelo GSettings da sessão Wayland.
set -euo pipefail
case "${1:-}" in nord|gruvbox|catppuccin) theme=$1 ;; *) exit 2 ;; esac
config=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}

# Prefira um tema GTK3 completo, quando instalado para a paleta ativa.
case "$theme" in
    nord) ready_theme=Nordic; folder_color=nordic ;;
    gruvbox) ready_theme=Rice-Gruvbox; folder_color=paleorange ;;
    catppuccin) ready_theme=Rice-Catppuccin-Mocha; folder_color=violet ;;
esac

# Os ícones coloridos são links para o Papirus instalado pelo pacman.
# O restante do conjunto vem do Papirus-Dark por herança.
apply_icon_theme() {
    local root places='' icon filename generic
    local -a roots
    local icon_theme="Rice-Arch-Icons-$theme"
    local destination="$data/icons/$icon_theme"

    IFS=: read -r -a roots <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for root in "${roots[@]}"; do
        if [[ $root == /* && -f $root/icons/Papirus/48x48/places/folder-$folder_color.svg ]]; then
            places="$root/icons/Papirus/48x48/places"
            break
        fi
    done
    [[ -n $places ]] || return 0

    mkdir -p -- "$destination/scalable/places" || return 1
    for icon in "$places/folder-$folder_color.svg" "$places/folder-$folder_color-"*.svg; do
        [[ -f $icon ]] || continue
        filename=${icon##*/}
        generic=${filename/folder-$folder_color/folder}
        [[ -f $places/$generic ]] || continue
        ln -sfn -- "$icon" "$destination/scalable/places/$generic" || return 1
    done
    cat > "$destination/index.theme" <<ICONS || return 1
[Icon Theme]
Name=$icon_theme
Comment=Papirus com pastas da paleta $theme
Inherits=Papirus-Dark,hicolor
Directories=scalable/places

[scalable/places]
Size=48
MinSize=8
MaxSize=512
Type=Scalable
Context=Places
ICONS
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
}

if ! apply_icon_theme; then
    printf 'Não foi possível trocar o tema de ícones.\n' >&2
fi

for theme_root in "$data/themes" "$HOME/.themes" /usr/share/themes; do
    if [[ -f $theme_root/$ready_theme/gtk-3.0/gtk.css ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$ready_theme"
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        exit 0
    fi
done

read -r base text accent < "$config/hypr/themes/$theme"
for color in "$base" "$text" "$accent"; do [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1; done

name="Rice-Arch-$theme"
dir="$data/themes/$name/gtk-3.0"
mkdir -p -- "$dir"
temp=$(mktemp -- "$dir/.gtk.XXXXXXXX")
trap 'rm -f -- "$temp"' EXIT
cat > "$temp" <<CSS
@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");

@define-color theme_bg_color #$base;
@define-color theme_fg_color #$text;
@define-color theme_base_color #$base;
@define-color theme_text_color #$text;
@define-color theme_selected_bg_color #$accent;
@define-color theme_selected_fg_color #$base;
window, dialog, headerbar, toolbar, treeview.view, iconview.view, menu {
    background-color: @theme_bg_color;
    color: @theme_fg_color;
}
treeview.view:selected, iconview.view:selected, menuitem:hover {
    background-color: @theme_selected_bg_color;
    color: @theme_selected_fg_color;
}

/* Menus GTK3. Os menus de contexto também usam estes seletores. */
menubar {
    background-color: @theme_bg_color;
    border-bottom: 1px solid mix(@theme_bg_color, @theme_fg_color, 0.24);
    padding: 3px 6px;
}
menubar > menuitem,
menu > menuitem {
    border-radius: 6px;
    padding: 5px 9px;
}
menu {
    border: 1px solid mix(@theme_bg_color, @theme_fg_color, 0.26);
    border-radius: 8px;
    padding: 5px;
}
menu > separator,
menu > menuitem.separator {
    background-color: mix(@theme_bg_color, @theme_fg_color, 0.32);
    min-height: 1px;
    margin: 5px 6px;
    padding: 0;
}

/* Thunar: barra e navegação com o mesmo destaque da Waybar e do Rofi. */
.thunar .sidebar {
    background-color: mix(@theme_bg_color, @theme_fg_color, 0.06);
    border-right: 1px solid mix(@theme_bg_color, @theme_fg_color, 0.16);
}
.thunar .sidebar treeview.view {
    background-color: transparent;
}
.thunar toolbar {
    padding: 5px 8px;
    background-color: mix(@theme_bg_color, @theme_fg_color, 0.06);
    border-bottom: 1px solid mix(@theme_bg_color, @theme_fg_color, 0.16);
}
.thunar toolbar button,
.thunar toolbar entry,
.thunar notebook tab {
    border-radius: 8px;
}
.thunar toolbar button:hover,
.thunar notebook tab:hover {
    background-color: mix(@theme_bg_color, @theme_fg_color, 0.13);
}
.thunar notebook tab:checked {
    color: @theme_selected_bg_color;
    box-shadow: inset 0 -2px @theme_selected_bg_color;
}
.thunar .sidebar treeview.view:selected,
.thunar treeview.view:selected,
.thunar iconview.view:selected {
    background-color: @theme_selected_bg_color;
    color: @theme_selected_fg_color;
}
CSS
mv -fT -- "$temp" "$dir/gtk.css"
gsettings set org.gnome.desktop.interface gtk-theme "$name"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
