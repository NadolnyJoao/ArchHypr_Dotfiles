#!/usr/bin/env bash
# Seleciona um tema GTK3 pelo GSettings da sessão Wayland.
set -euo pipefail
case "${1:-}" in nord|gruvbox|catppuccin) theme=$1 ;; *) exit 2 ;; esac
config=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}
read -r base text accent < "$config/hypr/themes/$theme"
for color in "$base" "$text" "$accent"; do [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1; done

name="Rice-Arch-$theme"
dir="$data/themes/$name/gtk-3.0"
mkdir -p -- "$dir"
temp=$(mktemp -- "$dir/.gtk.XXXXXXXX")
trap 'rm -f -- "$temp"' EXIT
cat > "$temp" <<CSS
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
CSS
mv -fT -- "$temp" "$dir/gtk.css"
gsettings set org.gnome.desktop.interface gtk-theme "$name"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
