#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source lib/steps.sh
source lib/packages.sh

temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
report_dir=$temp/report
mkdir -p "$report_dir"
touch "$temp/git"

pacman() {
    [[ $1 == -Q && -f $temp/$3 ]]
}
sudo() {
    [[ $1 == -n && $2 == pacman ]] || return 1
    if [[ $3 == -Syu ]]; then
        [[ ${update_fails:-0} == 0 ]]
    else
        local package=${!#}
        [[ $package != discord ]] && touch "$temp/$package"
    fi
}

install_arch_packages git discord firefox
[[ ${step_status[pacote-git]} == JA_PRONTO ]]
[[ ${step_status[pacote-discord]} == FALHOU ]]
[[ ${step_status[pacote-firefox]} == OK && -f $temp/firefox ]]

update_fails=1
install_arch_packages firefox kitty
[[ ${step_status[atualizacao]} == FALHOU ]]
[[ ${step_status[pacote-firefox]} == JA_PRONTO ]]
[[ ${step_status[pacote-kitty]} == FALHOU && ! -e $temp/kitty ]]

plan=$(XDG_CONFIG_HOME="$temp/config" XDG_STATE_HOME="$temp/state" bash install.sh --dry-run)
[[ $plan == *"app.ytmdesktop.ytmdesktop"* && $plan == *"$temp/config/nvim"* ]]
[[ ! -e $temp/state && ! -e $temp/config ]]
[[ $(printf '%s\n' "$plan" | grep -c '^  wl-clipboard$') == 1 ]]
