#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
    printf 'Execute com sudo.\n' >&2
    exit 1
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_config=$source_dir/default.conf
destination=/etc/keyd/default.conf

if [[ -e $destination || -L $destination ]]; then
    # Aceita a configuração manual equivalente, inclusive comentários.
    if [[ ! -f $destination ]] ||
       ! diff -q <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]*=[[:space:]]*/=/g; /^$/d' "$destination") \
                 <(sed -E 's/[[:space:]]*=[[:space:]]*/=/g; /^$/d' "$source_config") >/dev/null; then
        printf 'Configuração existente em %s. Integre as regras manualmente.\n' "$destination" >&2
        exit 1
    fi
else
    keyd check "$source_config"
    install -D -m 644 -- "$source_config" "$destination"
fi

keyd check
systemctl enable --now keyd.service
keyd reload
