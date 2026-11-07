#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
project_dir=$PWD
source lib/steps.sh
source lib/dotfiles.sh
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export XDG_CONFIG_HOME="$temp/config"
report_dir=$temp/report
mkdir -p "$report_dir" "$XDG_CONFIG_HOME/kitty"
printf 'anterior\n' > "$XDG_CONFIG_HOME/kitty/colors.conf"
run_step desktop '' install_desktop_dotfiles "$XDG_CONFIG_HOME"
[[ ${step_status[desktop]} == OK ]]
[[ $(cat "$report_dir/backup/kitty/colors.conf") == anterior ]]
theme_script="$XDG_CONFIG_HOME/hypr/scripts/theme.sh"
for palette in nord gruvbox catppuccin solitude; do
    bash "$theme_script" "$palette" --offline
    read -r base text accent < "$XDG_CONFIG_HOME/hypr/themes/$palette"
    grep -q "#$base" "$XDG_CONFIG_HOME/waybar/colors.css"
    grep -q "#$text" "$XDG_CONFIG_HOME/swaync/colors.css"
    grep -q "#$accent" "$XDG_CONFIG_HOME/rofi/colors.rasi"
    grep -q "#$base" "$XDG_CONFIG_HOME/kitty/colors.conf"
    grep -q "$accent" "$XDG_CONFIG_HOME/hypr/modules/colors.lua"
    grep -Fq "panel: #${base}d6;" "$XDG_CONFIG_HOME/rofi/colors.rasi"
    [[ $(grep -c '^color[0-9]\+ #' "$XDG_CONFIG_HOME/kitty/colors.conf") == 16 ]]
    grep -Fxq "active_tab_background #$accent" "$XDG_CONFIG_HOME/kitty/colors.conf"
done
if bash "$theme_script" desconhecido --offline; then exit 1; fi
run_step reexecucao '' install_desktop_dotfiles "$XDG_CONFIG_HOME"
[[ ${step_status[reexecucao]} == JA_PRONTO ]]
[[ $(cat "$XDG_CONFIG_HOME/hypr/current-theme") == solitude ]]
