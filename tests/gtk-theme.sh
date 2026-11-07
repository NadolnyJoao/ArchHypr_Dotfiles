#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export HOME="$temp/home" XDG_DATA_DIRS="$temp/system"
export XDG_DATA_HOME="$temp/data" XDG_CONFIG_HOME="$PWD/dotfiles" PATH="$temp:$PATH"
printf '#!/bin/sh\nprintf "%%s\\n" "$*"\n' > "$temp/gsettings"
chmod +x "$temp/gsettings"
result=$(bash dotfiles/hypr/scripts/gtk-theme.sh gruvbox)
[[ $result == $'set org.gnome.desktop.interface gtk-theme Rice-Arch-gruvbox\nset org.gnome.desktop.interface color-scheme prefer-dark' ]]
grep -q '#c7a77a' "$XDG_DATA_HOME/themes/Rice-Arch-gruvbox/gtk-3.0/gtk.css"


# Os ícones da paleta são selecionados também quando o GTK usa o Nordic pronto.
places="$temp/system/icons/Papirus/48x48/places"
mkdir -p "$places" "$XDG_DATA_HOME/themes/Nordic/gtk-3.0"
touch "$XDG_DATA_HOME/themes/Nordic/gtk-3.0/gtk.css" "$places/folder.svg"
for pair in nord:nordic gruvbox:palebrown catppuccin:violet solitude:grey; do
    palette=${pair%:*}
    color=${pair#*:}
    touch "$places/folder-$color.svg"
    result=$(bash dotfiles/hypr/scripts/gtk-theme.sh "$palette")
    [[ $result == *"icon-theme Rice-Arch-Icons-$palette"* ]]
    [[ -L $XDG_DATA_HOME/icons/Rice-Arch-Icons-$palette/scalable/places/folder.svg ]]
done
result=$(bash dotfiles/hypr/scripts/gtk-theme.sh nord)
[[ $result == *"gtk-theme Nordic"* ]]
