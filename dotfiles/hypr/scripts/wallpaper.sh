#!/usr/bin/env bash
set -euo pipefail
pack=${XDG_DATA_HOME:-$HOME/.local/share}/rice-arch/Wallpapers_Pack/wallpapers
runtime=${XDG_RUNTIME_DIR:?}/rice-wallpaper-${HYPRLAND_INSTANCE_SIGNATURE:?}
interval=${RICE_WALLPAPER_INTERVAL:-900}
[[ $interval =~ ^[1-9][0-9]*$ ]] || exit 2
mkdir -p -m 700 -- "$runtime"

rotate() (
    local image previous='' candidate reply
    local -a images=()
    exec 8>"$runtime/update.lock"
    flock 8 || return 1
    if [[ -f $runtime/current ]]; then read -r previous < "$runtime/current"; fi
    # Nomes com espaços e Unicode são preservados na seleção.
    mapfile -d '' -t images < <(find "$pack" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0)
    (( ${#images[@]} )) || return 1
    image=${images[RANDOM % ${#images[@]}]}
    candidate=$(mktemp --suffix=".${image##*.}" "$runtime/image.XXXXXXXX") || return 1
    trap 'rm -f -- "$candidate" "$runtime/next"' EXIT
    cp -- "$image" "$candidate" || return 1
    # O protocolo usa vírgulas. Envie o caminho temporário em vez do nome do repo.
    reply=$(hyprctl hyprpaper wallpaper ",$candidate,cover") || return 1
    [[ $reply == ok ]] || { printf '%s\n' "$reply" >&2; return 1; }
    printf '%s\n' "$candidate" > "$runtime/next" || return 1
    mv -fT -- "$runtime/next" "$runtime/current" || return 1
    trap - EXIT
    if [[ $previous == "$runtime"/image.* ]]; then rm -f -- "$previous"; fi
)

case "${1:-}" in
    once) rotate ;;
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
