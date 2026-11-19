#!/usr/bin/env bash
set -uo pipefail
root="${XDG_CONFIG_HOME:-$HOME/.config}/sway"
runtime="$XDG_RUNTIME_DIR/rice-sway-$WAYLAND_DISPLAY"
mkdir -p -m 700 "$runtime"
exec 8>"$runtime/session.lock"
flock -n 8 || exit 0
pids=()
cleanup() {
    for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
    wait || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT

# Registre apenas os processos iniciados por esta sessão.
bash "$root/scripts/gtk-theme.sh" "$(cat "$root/current-theme")"
if ! pgrep -u "$UID" -x swaync >/dev/null; then
    swaync & pids+=("$!")
fi
if ! pgrep -u "$UID" -x swayosd-server >/dev/null; then
    swayosd-server & pids+=("$!")
fi
wl-paste --watch cliphist store & pids+=("$!")
waybar -c "$root/waybar/config.jsonc" -s "$root/waybar/style.css" &
pids+=("$!")
printf '%s\n' "$!" > "$runtime/waybar.pid"
gammastep -c "$root/gammastep.ini" & pids+=("$!")
bash "$root/scripts/idle.sh" & pids+=("$!")
python3 "$root/scripts/wallpaper.py" --disable
python3 "$root/scripts/wallpaper.py" loop & pids+=("$!")

# Quando o compositor termina, encerre os processos desta sessão.
swaymsg -m -t subscribe '["shutdown"]' >/dev/null
