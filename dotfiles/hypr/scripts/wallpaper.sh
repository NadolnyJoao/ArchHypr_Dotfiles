#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}/hypr
pack=${XDG_DATA_HOME:-$HOME/.local/share}/rice-arch/Wallpapers_Pack/wallpapers
runtime=${XDG_RUNTIME_DIR:?}/rice-wallpaper-${HYPRLAND_INSTANCE_SIGNATURE:?}
interval=${RICE_WALLPAPER_INTERVAL:-3600}
[[ $interval =~ ^[1-9][0-9]*$ ]] || exit 2
mkdir -p -m 700 -- "$runtime"

list_images() {
  find "$1" "${@:2}" -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0
}

choose_wallpaper() {
  local image label selected
  local -a choices=()
  [[ -d $pack ]] || return 1
  mapfile -d '' -t choices < <(list_images "$pack" | sort -z)
  (("${#choices[@]}")) || return 1
  if ! selected=$(
    for image in "${choices[@]}"; do
      label=${image#"$pack/"}
      label=${label//[[:cntrl:]]/ }
      if [[ $image == *$'\n'* || $image == *$'\x1f'* ]]; then
        printf '%s\n' "$label"
      else
        printf '%s\0icon\x1f%s\n' "$label" "$image"
      fi
    done | rofi -dmenu -i -no-custom -show-icons -format i -p Wallpaper \
      -theme-str 'element-icon { size: 96px; } listview { lines: 5; }'
  ); then
    return 0
  fi
  [[ $selected =~ ^[0-9]+$ && $selected -lt ${#choices[@]} ]] || return 1
  rotate select "${choices[selected]}"
}

rotate() (
  local operation=${1:-next} selection=${2:-}
  local image previous='' candidate reply active attempt theme=nord source queue
  local cursor=-1 current_image='' index previous_source
  local -a images=() ordered=() saved=()
  local -A seen=()
  # Preserve a ordem dos bloqueios usada pela troca de tema.
  exec 7>"$config/.theme.lock"
  flock -s 7 || return 1
  exec 8>"$runtime/update.lock"
  flock 8 || return 1
  if [[ -f $config/current-theme ]]; then
    read -r theme <"$config/current-theme" || theme=nord
  fi
  case $theme in nord|gruvbox|catppuccin|solitude) ;; *) theme=nord ;; esac
  [[ -d $pack ]] || { printf 'Pasta de wallpapers ausente: %s\n' "$pack" >&2; return 1; }
  source="$pack/$theme"
  if [[ -d $source ]]; then
    mapfile -d '' -t images < <(list_images "$source" -maxdepth 1 | shuf -z)
  fi
  if ((${#images[@]} == 0)); then
    source=$pack
    mapfile -d '' -t images < <(list_images "$source" -maxdepth 1 | shuf -z)
  fi
  if [[ -f $runtime/current ]]; then read -r previous <"$runtime/current"; fi

  # Guarde a posição, a pasta padrão do tema e a ordem da sessão.
  queue="$runtime/playlist-$theme"
  if [[ -s $queue ]]; then
    mapfile -d '' -t saved <"$queue"
    index=${saved[0]}
    previous_source=${saved[1]}
    current_image=${saved[index + 2]}
    for image in "${saved[@]:2}"; do
      [[ -f $image ]] || continue
      # Se o tema ganhou uma pasta própria, deixe para trás o fallback da raiz.
      if [[ $previous_source == "$pack" && $source != "$pack" && ${image%/*} == "$pack" ]]; then
        continue
      fi
      seen[$image]=1
      if [[ $image == "$current_image" ]]; then cursor=${#ordered[@]}; fi
      ordered+=("$image")
    done
  fi
  for image in "${images[@]}"; do
    if [[ ! ${seen[$image]:-} ]]; then
      ordered+=("$image")
      seen[$image]=1
    fi
  done
  if [[ $operation == select ]]; then
    [[ $selection == "$pack/"* && -f $selection ]] || return 1
    if [[ ${seen[$selection]:-} ]]; then
      for index in "${!ordered[@]}"; do
        if [[ ${ordered[index]} == "$selection" ]]; then
          cursor=$index
          break
        fi
      done
    else
      # Uma escolha de outra pasta entra após a posição atual da fila.
      cursor=$((cursor + 1))
      ordered=("${ordered[@]:0:cursor}" "$selection" "${ordered[@]:cursor}")
    fi
  elif ((${#ordered[@]} == 0)); then
    printf 'Nenhuma imagem encontrada.\n' >&2
    return 1
  elif [[ $operation == prev ]]; then
    if ((cursor < 0)); then cursor=0; fi
    cursor=$(((cursor + ${#ordered[@]} - 1) % ${#ordered[@]}))
  else
    cursor=$(((cursor + 1) % ${#ordered[@]}))
  fi
  image=${ordered[cursor]}
  candidate=$(mktemp --suffix=".${image##*.}" "$runtime/image.XXXXXXXX") || return 1
  trap 'rm -f -- "$candidate" "$runtime/next"' EXIT
  cp -- "$image" "$candidate" || return 1
  # O protocolo usa vírgulas. Envie o caminho temporário em vez do nome do repo.
  reply=$(hyprctl hyprpaper wallpaper ",$candidate,cover") || return 1
  # Algumas versões respondem sem texto mesmo após aplicar a imagem.
  if [[ $reply != ok ]]; then
    for attempt in {1..10}; do
      active=$(hyprctl hyprpaper listactive) || return 1
      if cut -d ' ' -f2- <<<"$active" | grep -Fx -- "$candidate" >/dev/null; then
        break
      fi
      sleep 0.1
    done
    if ! cut -d ' ' -f2- <<<"$active" | grep -Fx -- "$candidate" >/dev/null; then
      printf 'Hyprpaper não confirmou a troca: %s\n' "$reply" >&2
      return 1
    fi
  fi
  # A imagem já está em uso. Preserve-a mesmo se uma escrita de estado falhar.
  trap - EXIT
  printf '%s\n' "$candidate" >"$runtime/next" || return 1
  mv -fT -- "$runtime/next" "$runtime/current" || return 1
  # Atualize a posição somente depois que o Hyprpaper confirmar a imagem.
  printf '%s\0' "$cursor" "$source" "${ordered[@]}" >"$runtime/playlist.next" || return 1
  mv -fT -- "$runtime/playlist.next" "$queue" || return 1
  if [[ $previous == "$runtime"/image.* ]]; then rm -f -- "$previous"; fi
)

case "${1:-}" in
once | next) rotate ;;
prev) rotate prev ;;
menu) choose_wallpaper ;;
loop)
  exec 9>"$runtime/rotation.lock"
  flock -n 9 || exit 0
  # Espere brevemente pelo IPC do Hyprpaper no início da sessão.
  for attempt in {1..10}; do
    if rotate; then break; fi
    sleep 1
  done
  while sleep "$interval"; do
    hyprctl -j monitors >/dev/null 2>&1 || exit 0
    rotate || printf 'Falha ao aplicar wallpaper; será tentado novamente.\n' >&2
  done
  ;;
*) exit 2 ;;
esac
