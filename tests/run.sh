#!/usr/bin/env bash
# Retorna erro se qualquer teste falhar. Funciona quando chamado a partir do Fish.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

while IFS= read -r -d '' script; do
    bash -n "$script"
done < <(find lib dotfiles tests -name '*.sh' -print0)
bash -n install.sh

total=0
for test in tests/*.sh; do
    [[ $test != tests/run.sh ]] || continue
    printf 'Executando %s\n' "$test"
    bash "$test"
    total=$((total + 1))
done
python3 tests/configs.py
printf '\n%s testes Bash e validação Lua/Waybar concluídos.\n' "$total"
