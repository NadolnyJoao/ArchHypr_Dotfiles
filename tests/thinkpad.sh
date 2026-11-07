#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
result=$(python3 dotfiles/hypr/scripts/remap-keymap.py <<'MAP'
xkb_symbols {
    key <LCTL> { [ Control_L ] };
    key <RCTL> {
        [ Control_R ]
    };
    modifier_map Control { <LCTL>, <RCTL> };
};
MAP
)
[[ $result == *'[ slash, question ]'* ]]
[[ $result == *'modifier_map Control { <LCTL> };'* ]]
[[ $result != *Control_R* ]]
if printf 'mapa inválido\n' | python3 dotfiles/hypr/scripts/remap-keymap.py; then exit 1; fi
