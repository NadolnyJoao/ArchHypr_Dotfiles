#!/usr/bin/env bash
# Baixe a main e compare com a máquina. --apply instala pacotes e aplica o plano.
set -euo pipefail
apply=false
local_repo=false
desktop=auto
while (( $# )); do
    case "$1" in
        --apply) apply=true ;;
        --local) local_repo=true ;;
        --desktop)
            shift
            desktop=${1:?Use auto, sway, hyprland ou both} ;;
        --help)
            printf 'Uso: bash atualizar-dotfiles.sh [--apply] [--desktop auto|sway|hyprland|both] [--local]\n'
            exit 0 ;;
        *) printf 'Opção desconhecida: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done
if (( EUID == 0 )) || ! command -v pacman >/dev/null; then
    printf 'Execute como usuário comum no Arch.\n' >&2
    exit 1
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
if "$local_repo"; then
    repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
else
    repo=$work/repo
    git clone --quiet --depth 1 --branch main https://github.com/NadolnyJoao/ArchHypr_Dotfiles.git "$repo"
fi
state=${XDG_STATE_HOME:-$HOME/.local/state}/rice-arch
mkdir -p "$state"
exec 9>"$state/install.lock"
flock -n 9 || { printf 'Outra instalação está em andamento.\n' >&2; exit 1; }
python3 "$repo/tools/sync-configs.py" packages --desktop "$desktop" > "$work/packages"
pacman -Qq > "$work/installed"
missing=()
while IFS= read -r package; do
    if ! grep -Fxq "$package" "$work/installed"; then
        missing+=("$package")
        printf '[PACOTE AUSENTE] %s\n' "$package"
    fi
done < "$work/packages"
if "$apply"; then
    if (( ${#missing[@]} )); then
        sudo pacman -Syu --needed -- "${missing[@]}"
        pacman -Q -- "${missing[@]}" >/dev/null
    fi
    python3 "$repo/tools/sync-configs.py" apply --desktop "$desktop" --apply
else
    python3 "$repo/tools/sync-configs.py" apply --desktop "$desktop"
    printf 'Prévia concluída. Use --apply para aplicar.\n'
fi
