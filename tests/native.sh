#!/usr/bin/env bash
# Parsers reais; habilite explicitamente em um Arch com os pacotes instalados.
set -euo pipefail
[[ ${RICE_NATIVE_TESTS:-0} == 1 ]] || {
    printf 'Parsers nativos: habilite com RICE_NATIVE_TESTS=1.\n'
    exit 0
}
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
for tool in Hyprland kitty fish desktop-file-validate python3 xkbcli; do
    command -v "$tool" >/dev/null || { printf 'Dependência de teste ausente: %s\n' "$tool" >&2; exit 1; }
done
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cp -a dotfiles "$temp/config"
mkdir -m 700 "$temp/runtime" "$temp/home"
export XDG_CONFIG_HOME="$temp/config" XDG_RUNTIME_DIR="$temp/runtime" HOME="$temp/home"
export XDG_CACHE_HOME="$temp/cache" XDG_DATA_HOME="$temp/data" XDG_STATE_HOME="$temp/state"
unset HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY DISPLAY
fish --no-config -n dotfiles/fish/conf.d/rice-arch.fish
desktop-file-validate dotfiles/applications/rice-arch-neovim.desktop
# Compile mapas completos, incluindo o layout brasileiro, sem acessar o teclado.
for layout in us br; do
    xkbcli compile-keymap --layout "$layout" > "$temp/keymap.xkb"
    python3 dotfiles/hypr/scripts/remap-keymap.py < "$temp/keymap.xkb" > "$temp/remapped.xkb"
    xkbcli compile-keymap --from-xkb "$temp/remapped.xkb" --test
    printf 'Mapa XKB real: %s OK\n' "$layout"
done
for palette in nord gruvbox catppuccin solitude; do
    bash "$XDG_CONFIG_HOME/hypr/scripts/theme.sh" "$palette" --offline
    # --verify-config não abre sessão e não dispara o autostart.
    if ! Hyprland --verify-config --config "$XDG_CONFIG_HOME/hypr/hyprland.lua" >"$temp/hyprland.log" 2>&1; then
        cat "$temp/hyprland.log"
        exit 1
    fi
    grep -Fq 'config ok' "$temp/hyprland.log" || { cat "$temp/hyprland.log"; exit 1; }
    kitty +runpy 'import os; from kitty.config import load_config; bad=[]; load_config(os.environ["XDG_CONFIG_HOME"]+"/kitty/kitty.conf", accumulate_bad_lines=bad); assert not bad, bad'
    # GSettings é substituído só para gerar GTK sem mudar a sessão do usuário.
    mkdir -p "$temp/bin"
    printf '#!/bin/sh\nexit 0\n' > "$temp/bin/gsettings"
    chmod +x "$temp/bin/gsettings"
    PATH="$temp/bin:$PATH" bash "$XDG_CONFIG_HOME/hypr/scripts/gtk-theme.sh" "$palette"
    gtk_css="$XDG_DATA_HOME/themes/Rice-Arch-$palette/gtk-3.0/gtk.css"
    if [[ $palette == nord && -f /usr/share/themes/Nordic/gtk-3.0/gtk.css ]]; then
        gtk_css=/usr/share/themes/Nordic/gtk-3.0/gtk.css
    fi
    python3 tests/native-css.py "$XDG_CONFIG_HOME/waybar/style.css" \
        "$XDG_CONFIG_HOME/swaync/style.css" "$gtk_css"
    printf 'Parsers Hyprland, Kitty e GTK3: %s OK\n' "$palette"
done
