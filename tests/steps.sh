#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source lib/steps.sh

temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
report_dir=$temp/report
mkdir -p "$report_dir" "$temp/config/hypr"
printf 'STATUS\tETAPA\tDETALHE\n' > "$report_dir/resumo.tsv"

run_step rede '' bash -c 'echo "erro simulado"; exit 42'
run_step wallpapers rede touch "$temp/executado"
run_step firefox '' true
run_step portal '' bash -c 'exit 10'
run_step apps portal true
[[ ${step_status[rede]} == FALHOU && $failed_steps == 1 ]]
[[ ${step_status[wallpapers]} == PULADO && ! -e $temp/executado ]]
[[ ${step_status[firefox]} == OK && ${step_status[apps]} == OK ]]
[[ ${step_status[portal]} == JA_PRONTO ]]
grep -q 'erro simulado' "$report_dir/rede.log"
grep -q 'Código 42' "$report_dir/resumo.tsv"

printf 'antigo\n' > "$temp/config/hypr/init.lua"
printf 'novo\n' > "$temp/init.lua"
run_step dotfiles '' deploy_file "$temp/init.lua" "$temp/config" hypr/init.lua
cmp "$temp/init.lua" "$temp/config/hypr/init.lua"
[[ $(cat "$report_dir/backup/hypr/init.lua") == antigo ]]
run_step reexecucao '' deploy_file "$temp/init.lua" "$temp/config" hypr/init.lua
[[ ${step_status[reexecucao]} == JA_PRONTO ]]
[[ $(cat "$report_dir/backup/hypr/init.lua") == antigo ]]
printf 'Testes do núcleo passaram.\n'
