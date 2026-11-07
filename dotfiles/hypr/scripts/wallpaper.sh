#!/usr/bin/env bash
set -euo pipefail
pack=${XDG_DATA_HOME:-$HOME/.local/share}/rice-arch/Wallpapers_Pack/wallpapers
runtime=${XDG_RUNTIME_DIR:?}/rice-wallpaper-${HYPRLAND_INSTANCE_SIGNATURE:?}
interval=${RICE_WALLPAPER_INTERVAL:-3600}
[[ $interval =~ ^[1-9][0-9]*$ ]] || exit 2
mkdir -p -m 700 -- "$runtime"

rotate() (
  local image previous='' candidate reply active attempt
  local queue="$runtime/queue"
  local -a remaining=()
  local -a images=()
  exec 8>"$runtime/update.lock"
  flock 8 || return 1
  if [[ -f $runtime/current ]]; then read -r previous <"$runtime/current"; fi
  # Todos os caminhos são separados por NUL para preservar espaços e Unicode.
  # A fila só é refeita quando acaba. Arquivos removidos são descartados.
  if [[ -s $queue ]]; then
    mapfile -d '' -t images <"$queue"
    for image in "${images[@]}"; do
      [[ ! -f $image ]] || remaining+=("$image")
    done
  fi
  if ((${#remaining[@]} == 0)); then
    [[ -d $pack ]] || {
      printf 'Pasta de wallpapers ausente: %s\n' "$pack" >&2
      return 1
    }
    mapfile -d '' -t images < <(
      find "$pack" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0 |
        shuf -z
    )
    remaining=("${images[@]}")
  fi
  ((${#remaining[@]})) || {
    printf 'Nenhuma imagem encontrada.\n' >&2
    return 1
  }
  image=${remaining[0]}
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
  # Avança somente após confirmar e registrar a imagem aplicada.
  : >"$runtime/queue.next" || return 1
  if ((${#remaining[@]} > 1)); then
    printf '%s\0' "${remaining[@]:1}" >"$runtime/queue.next" || return 1
  fi
  mv -fT -- "$runtime/queue.next" "$queue" || return 1
  if [[ $previous == "$runtime"/image.* ]]; then rm -f -- "$previous"; fi
)

case "${1:-}" in
once | next) rotate ;;
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
