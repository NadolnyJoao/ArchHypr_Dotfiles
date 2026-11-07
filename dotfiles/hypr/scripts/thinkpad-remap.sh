#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}/hypr
runtime=${XDG_RUNTIME_DIR:?Execute no Hyprland}
instance=${HYPRLAND_INSTANCE_SIGNATURE:?Execute no Hyprland}
map="$runtime/rice-thinkpad-$instance.xkb"
case "${1:-}" in
    on)
        [[ ! -f $map ]] || exit 0
        temp=$(mktemp -- "$map.XXXXXXXX")
        trap 'rm -f -- "$temp"' EXIT
        timeout 5 xkbcli dump-keymap-wayland | python "$config/scripts/remap-keymap.py" > "$temp"
        xkbcli compile-keymap --from-xkb < "$temp" >/dev/null
        mv -fT -- "$temp" "$map"
        if ! hyprctl reload; then
            rm -f -- "$map"
            exit 1
        fi
        ;;
    off)
        rm -f -- "$map"
        hyprctl reload
        ;;
    *) printf 'Uso: %s on|off\n' "$0" >&2; exit 2 ;;
esac
