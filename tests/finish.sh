#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source lib/finish.sh
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export GIT_CONFIG_GLOBAL="$temp/gitconfig"
configure_git_identity 'Pessoa Teste' 'teste@example.invalid'
[[ $(git config --global --get user.name) == 'Pessoa Teste' ]]
[[ $(git config --global --get user.email) == 'teste@example.invalid' ]]
if configure_git_identity '' invalid; then exit 1; fi

mock_browser=other.desktop
xdg-settings() {
    case "$1" in
        get) printf '%s\n' "$mock_browser" ;;
        set) mock_browser=$3 ;;
        check) [[ $mock_browser == "$3" ]] && echo yes ;;
    esac
}
set_default_firefox
[[ $mock_browser == firefox.desktop ]]
result=0
set_default_firefox || result=$?
[[ $result == 10 ]]

mkdir "$temp/ssh"
printf 'preservar\n' > "$temp/ssh/id_ed25519"
if prepare_github_key "$temp/ssh/id_ed25519" teste@example.invalid; then exit 1; fi
[[ $(cat "$temp/ssh/id_ed25519") == preservar ]]
ssh-keygen -q -t ed25519 -N '' -f "$temp/ssh/existing"
result=0
prepare_github_key "$temp/ssh/existing" teste@example.invalid || result=$?
[[ $result == 10 ]]
