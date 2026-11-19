#!/usr/bin/env bash
set -euo pipefail
root="${XDG_CONFIG_HOME:-$HOME/.config}/sway"
case "${1:-}" in
    browser)
        browser=$(xdg-settings get default-web-browser)
        if [[ -n $browser ]]; then exec gtk-launch "$browser"; fi
        exec firefox ;;
    screenshot)
        region=$(slurp) || exit 0
        [[ -n $region ]] || exit 0
        grim -g "$region" - | wl-copy
        notify-send "Captura de tela" "Região copiada para a área de transferência" ;;
    clipboard)
        selection=$(cliphist list | rofi -config "$root/rofi/config.rasi" -dmenu -i -no-custom -p 'Histórico de cópia') || exit 0
        [[ -n $selection ]] || exit 0
        printf '%s\n' "$selection" | cliphist decode | wl-copy ;;
    power)
        choice=$(printf '%s\n' Bloquear Sair Reiniciar Desligar |
            rofi -config "$root/rofi/config.rasi" -dmenu -no-custom -p Energia) || exit 0
        if [[ $choice == Bloquear ]]; then exec swaylock -f -c 000000; fi
        confirm=$(printf '%s\n' Cancelar Confirmar | rofi -config "$root/rofi/config.rasi" -dmenu -no-custom -p "$choice?") || exit 0
        [[ $confirm == Confirmar ]] || exit 0
        case "$choice" in
            Sair) swaymsg exit ;;
            Reiniciar) systemctl reboot ;;
            Desligar) systemctl poweroff ;;
        esac ;;
    *) exit 2 ;;
esac
