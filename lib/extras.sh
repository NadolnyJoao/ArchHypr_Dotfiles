#!/usr/bin/env bash
# O helper gera caminhos e cores na máquina de destino.
install_ark_config() {
    local data=${XDG_DATA_HOME:-$HOME/.local/share} result
    if deploy_file "$project_dir/tools/configurar-ark.py" "$data" rice-ark/configurar-ark.py; then
        :
    else
        result=$?
        (( result == 10 )) || return "$result"
    fi
    RICE_DESKTOP=hypr python3 "$data/rice-ark/configurar-ark.py" --setup
}
