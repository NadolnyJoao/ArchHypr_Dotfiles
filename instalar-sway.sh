#!/usr/bin/env bash
# Instale a sessão Sway a partir da configuração versionada.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo/atualizar-dotfiles.sh" --local --desktop sway --apply
