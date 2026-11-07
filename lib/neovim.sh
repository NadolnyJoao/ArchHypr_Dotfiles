#!/usr/bin/env bash
# Instala a configuração. O bootstrap dos plugins acontece ao abrir o nvim.
install_neovim_config() {
    local url=$1 destination=$2 origin staging backup
    backup=$report_dir/backup/nvim
    if [[ -d $destination/.git && ! -L $destination ]]; then
        origin=$(git -C "$destination" remote get-url origin 2>/dev/null) || origin=
        if [[ $origin == "$url" && -f $destination/init.lua ]]; then
            return 10
        fi
    fi

    mkdir -p -- "$(dirname -- "$destination")" || return 1
    staging=$(mktemp -d -- "$(dirname -- "$destination")/.nvim.XXXXXXXX") || return 1
    if ! git clone -- "$url" "$staging" || [[ ! -f $staging/init.lua ]]; then
        rm -rf -- "$staging"
        printf 'Não foi possível preparar um clone com init.lua.\n' >&2
        return 1
    fi

    if [[ -e $destination || -L $destination ]]; then
        if ! mkdir -p -- "$(dirname -- "$backup")" || [[ -e $backup || -L $backup ]] ||
            ! mv -T -- "$destination" "$backup"; then
            rm -rf -- "$staging"
            return 1
        fi
    fi
    if ! mv -T -- "$staging" "$destination"; then
        rm -rf -- "$staging"
        if [[ -e $backup || -L $backup ]]; then
            mv -T -- "$backup" "$destination" || printf 'Backup disponível em %s\n' "$backup" >&2
        fi
        return 1
    fi
}
