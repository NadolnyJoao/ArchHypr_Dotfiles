#!/usr/bin/env bash
install_wallpaper_pack() {
    local url=$1 destination=$2 stage origin
    if [[ -e $destination || -L $destination ]]; then
        origin=$(git -C "$destination" remote get-url origin 2>/dev/null) || return 1
        [[ $origin == "$url" && -d $destination/wallpapers ]] && return 10
        printf 'Destino ocupado por outro repositório: %s\n' "$destination" >&2
        return 1
    fi
    mkdir -p -- "$(dirname -- "$destination")" || return 1
    stage=$(mktemp -d -- "$(dirname -- "$destination")/.wallpapers.XXXXXXXX") || return 1
    if git clone -- "$url" "$stage" && [[ -d $stage/wallpapers ]] &&
        mv -nT -- "$stage" "$destination" && [[ ! -e $stage ]]; then
        return 0
    fi
    rm -rf -- "$stage"
    return 1
}
