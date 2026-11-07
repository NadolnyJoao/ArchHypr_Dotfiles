#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source lib/steps.sh
source lib/neovim.sh

temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
report_dir=$temp/report
destination=$temp/config/nvim
mkdir -p "$report_dir" "$destination"
printf 'original\n' > "$destination/init.lua"

git init -q "$temp/repo"
printf 'novo\n' > "$temp/repo/init.lua"
git -C "$temp/repo" add init.lua
git -C "$temp/repo" -c user.name=Teste -c user.email=teste@example.invalid commit -qm inicial

run_step clone_invalido '' install_neovim_config "$temp/inexistente" "$destination"
[[ ${step_status[clone_invalido]} == FALHOU ]]
[[ $(cat "$destination/init.lua") == original ]]
run_step clone_valido '' install_neovim_config "$temp/repo" "$destination"
[[ ${step_status[clone_valido]} == OK ]]
[[ $(cat "$destination/init.lua") == novo ]]
[[ $(cat "$report_dir/backup/nvim/init.lua") == original ]]
printf 'minha edição\n' > "$destination/init.lua"
run_step reexecucao '' install_neovim_config "$temp/repo" "$destination"
[[ ${step_status[reexecucao]} == JA_PRONTO ]]
[[ $(cat "$destination/init.lua") == 'minha edição' ]]
