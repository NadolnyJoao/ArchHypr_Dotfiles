#!/usr/bin/env bash
set -uo pipefail
choice=$(printf '%s\n' Bloquear Sair Reiniciar Desligar | rofi -dmenu -no-custom -p Energia) || exit 0
case "$choice" in
    Bloquear) exec bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/lock.sh" ;;
    Sair|Reiniciar|Desligar) ;;
    *) exit 0 ;;
esac
confirmation=$(printf '%s\n' Cancelar Confirmar | rofi -dmenu -no-custom -p "$choice?") || exit 0
[[ $confirmation == Confirmar ]] || exit 0
case "$choice" in
    Sair) hyprctl eval 'hl.dispatch(hl.dsp.exit())' ;;
    Reiniciar) systemctl reboot ;;
    Desligar) systemctl poweroff ;;
esac
