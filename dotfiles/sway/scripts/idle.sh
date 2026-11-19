#!/usr/bin/env bash
set -euo pipefail
root="${XDG_CONFIG_HOME:-$HOME/.config}/sway"
# Notebook com painel interno segue o esquema de 5/10 minutos.
# Desktop recebe apenas o bloqueio antes de suspender.
if brightnessctl -c backlight get >/dev/null 2>&1; then
    exec swayidle -w \
        timeout 300 "bash \"$root/scripts/idle-brightness.sh\" dim" \
        resume "bash \"$root/scripts/idle-brightness.sh\" restore" \
        timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
        lock 'swaylock -f -c 000000' \
        before-sleep 'swaylock -f -c 000000' \
        after-resume 'swaymsg "output * power on"'
else
    exec swayidle -w lock 'swaylock -f -c 000000' before-sleep 'swaylock -f -c 000000'
fi
