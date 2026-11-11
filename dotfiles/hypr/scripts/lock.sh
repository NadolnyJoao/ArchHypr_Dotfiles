#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}/hypr
runtime=${XDG_RUNTIME_DIR:?}/rice-wallpaper-${HYPRLAND_INSTANCE_SIGNATURE:?}
mkdir -p -m 700 -- "$runtime"
exec 9>"$runtime/screen-lock"
flock -n 9 || exit 0

work=$(mktemp -d "$runtime/lock.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
theme=nord
if [[ -f $config/current-theme ]]; then read -r theme <"$config/current-theme" || theme=nord; fi
case "$theme" in nord | gruvbox | catppuccin | solitude) ;; *) theme=nord ;; esac
read -r base text accent <"$config/themes/$theme"
for color in "$base" "$text" "$accent"; do [[ $color =~ ^[[:xdigit:]]{6}$ ]] || exit 1; done

# Copie a imagem enquanto a rotação está impedida de removê-la.
(
  exec 8>"$runtime/update.lock"
  flock 8
  if [[ -f $runtime/current ]] && read -r image <"$runtime/current" && [[ -f $image ]]; then
    cp -- "$image" "$work/wallpaper.${image##*.}"
  fi
)
images=("$work"/wallpaper.*)
{
  printf 'background {\n    monitor =\n    color = rgba(%sff)\n' "$base"
  if [[ -f ${images[0]} ]]; then
    printf '    path = %s\n    blur_passes = 2\n' "${images[0]}"
  fi
  printf '}\n'

  # As aspas simples deixam $TIME para o Hyprlock interpretar.
  printf 'label {
    monitor =
    text = $TIME
    color = rgba(%sff)
    font_size = 112
    font_family = Sans Bold
    position = 0, 100
    halign = center
    valign = center
}
' "$text"

  printf 'input-field {\n    monitor =\n    size = 260, 52\n    outline_thickness = 2\n    outer_color = rgba(%sff)\n    inner_color = rgba(%sff)\n    font_color = rgba(%sff)\n    position = 0, -80\n    halign = center\n    valign = center\n}\n' "$accent" "$base" "$text"
} >"$work/hyprlock.conf"
hyprlock --config "$work/hyprlock.conf"
