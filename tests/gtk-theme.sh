#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export XDG_DATA_HOME="$temp/data" XDG_CONFIG_HOME="$PWD/dotfiles" PATH="$temp:$PATH"
printf '#!/bin/sh\nprintf "%%s\\n" "$*"\n' > "$temp/gsettings"
chmod +x "$temp/gsettings"
result=$(bash dotfiles/hypr/scripts/gtk-theme.sh gruvbox)
[[ $result == 'set org.gnome.desktop.interface gtk-theme Rice-Arch-gruvbox' ]]
grep -q '#fabd2f' "$XDG_DATA_HOME/themes/Rice-Arch-gruvbox/gtk-3.0/gtk.css"
