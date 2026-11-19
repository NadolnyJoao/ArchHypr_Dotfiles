#!/usr/bin/env bash
# Coleta as configurações em uso e publica por SSH.
set -euo pipefail
publish=false
for option in "$@"; do
    case "$option" in
        --publish) publish=true ;;
        --bluetooth) ;; # Compatibilidade com o publicador anterior.
        --help) printf 'Uso: bash publicar-dotfiles.sh [--publish]\n'; exit 0 ;;
        *) printf 'Opção desconhecida: %s\n' "$option" >&2; exit 2 ;;
    esac
done
repo=${ARCHHYPR_REPO:-$HOME/ArchHypr_Dotfiles}
cd -- "$repo"
[[ $(git branch --show-current) == main ]] || { printf 'Use a branch main.\n' >&2; exit 1; }
remote=git@github.com:NadolnyJoao/ArchHypr_Dotfiles.git
if ! "$publish"; then
    python3 tools/sync-configs.py collect
    git --no-pager diff --stat
    printf 'Use --publish para coletar, fazer commit e enviar.\n'
    exit 0
fi
git fetch --no-tags "$remote" refs/heads/main
if ! git merge-base --is-ancestor FETCH_HEAD HEAD; then
    printf 'Integre a main remota com git rebase FETCH_HEAD e rode novamente.\n' >&2
    exit 1
fi
state=${XDG_STATE_HOME:-$HOME/.local/state}/rice-arch
mkdir -p "$state"
exec 9>"$state/install.lock"
flock -n 9 || exit 1
python3 tools/sync-configs.py collect --apply
python3 -m py_compile tools/configurar-ark.py tools/sync-configs.py
git add -- dotfiles lib packages tests tools install.sh instalar-sway.sh \
    atualizar-dotfiles.sh publicar-dotfiles.sh README.md SWAY.md .gitignore \
    ':!dotfiles/hypr/modules/input.lua' ':!dotfiles/hypr/modules/monitors.local.lua' \
    ':!dotfiles/sway/local.conf' ':!dotfiles/sway/config.d/input.conf'
# Somente os caminhos portáveis entram no commit; outros arquivos no stage ficam intactos.
mapfile -d '' -t paths < <(git diff --cached --name-only -z -- dotfiles lib packages tests tools install.sh instalar-sway.sh atualizar-dotfiles.sh publicar-dotfiles.sh README.md SWAY.md .gitignore ':!dotfiles/hypr/modules/input.lua' ':!dotfiles/hypr/modules/monitors.local.lua' ':!dotfiles/sway/local.conf' ':!dotfiles/sway/config.d/input.conf')
if (( ${#paths[@]} )); then
    git diff --cached --check -- "${paths[@]}"
    git --no-pager diff --cached --stat -- "${paths[@]}"
    git commit --only -m "Sincroniza configurações do Hyprland, Sway e Ark" -- "${paths[@]}"
fi
git push "$remote" HEAD:refs/heads/main
