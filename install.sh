#!/usr/bin/env bash
# Ponto de entrada. Cada função de instalação mora em lib/.
set -uo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
source "$project_dir/lib/steps.sh"
source "$project_dir/lib/packages.sh"
source "$project_dir/lib/neovim.sh"
source "$project_dir/lib/dotfiles.sh"
source "$project_dir/lib/wallpapers.sh"
source "$project_dir/lib/sddm.sh"
source "$project_dir/lib/finish.sh"

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/rice-arch
wallpaper_url=https://github.com/NadolnyJoao/Wallpapers_Pack.git
wallpaper_dir=${XDG_DATA_HOME:-$HOME/.local/share}/rice-arch/Wallpapers_Pack
neovim_url=https://github.com/NadolnyJoao/Neovim-IDE.git
mapfile -t neovim_packages < "$project_dir/packages/neovim.txt" || exit 1
mapfile -t packages < "$project_dir/packages/desktop.txt" || exit 1
for package in "${neovim_packages[@]}"; do
    if [[ " ${packages[*]} " != *" $package "* ]]; then
        packages+=("$package")
    fi
done

case "${1:-}" in
    --dry-run)
        printf 'Pacotes planejados:\n'
        printf '  %s\n' "${packages[@]}"
        printf 'Flatpak: app.ytmdesktop.ytmdesktop\nNeovim: %s → %s/nvim\n' "$neovim_url" "$config_dir"
        printf 'Dotfiles: %s/hypr (Lua, inatividade e filtro noturno)\n' "$config_dir"
        printf 'Wallpapers: %s → %s\n' "$wallpaper_url" "$wallpaper_dir"
        exit 0 ;;
    --help)
        printf 'Uso: bash install.sh [--dry-run]\n'
        exit 0 ;;
    '') ;;
    *) printf 'Opção desconhecida. Consulte --help.\n' >&2; exit 2 ;;
esac

if (( EUID == 0 )) || ! command -v pacman >/dev/null; then
    printf 'Execute como usuário comum em um Arch com pacman.\n' >&2
    exit 1
fi

# Protege o relatório e evita duas execuções simultâneas para o mesmo usuário.
umask 077
mkdir -p -- "$state_dir" || exit 1
exec 9>"$state_dir/install.lock" || exit 1
flock -n 9 || { printf 'Já há uma instalação em andamento.\n' >&2; exit 1; }
report_dir=$(mktemp -d -- "$state_dir/instalacao.XXXXXXXX") || exit 1
printf 'STATUS\tETAPA\tDETALHE\n' > "$report_dir/resumo.tsv" || exit 1
trap 'printf "\nRelatório: %s/resumo.tsv\n" "$report_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Renova a autorização no terminal antes que a saída dos comandos vá para o log.
if sudo -v; then
    record_step sudo OK "Autorização disponível."
else
    record_step sudo FALHOU "Não foi possível autorizar a instalação."
    exit 1
fi

install_arch_packages "${packages[@]}"
run_step youtube-music 'pacote-flatpak' install_youtube_music

neovim_dependencies=()
for package in "${neovim_packages[@]}"; do
    neovim_dependencies+=("pacote-$package")
done
run_step neovim-config "${neovim_dependencies[*]}" install_neovim_config "$neovim_url" "$config_dir/nvim"

run_step hypridle-config 'pacote-hypridle' install_hyprland_dotfiles "$config_dir" \
    hypr/scripts/idle-brightness.sh hypr/hypridle.conf
run_step hyprsunset-config 'pacote-hyprsunset' install_hyprland_dotfiles "$config_dir" \
    hypr/hyprsunset.conf
run_step desktop-config 'pacote-hyprland pacote-waybar pacote-rofi pacote-swaync pacote-kitty' install_desktop_dotfiles "$config_dir"
run_step wallpaper-pack 'pacote-git' install_wallpaper_pack "$wallpaper_url" "$wallpaper_dir"
run_step wallpaper-config 'pacote-hyprpaper wallpaper-pack' install_hyprland_dotfiles "$config_dir" \
    hypr/scripts/wallpaper.sh hypr/hyprpaper.conf
run_step lock-config 'pacote-hyprlock desktop-config' install_hyprland_dotfiles "$config_dir" hypr/scripts/lock.sh
run_step thinkpad-config 'pacote-python pacote-libxkbcommon' install_hyprland_dotfiles "$config_dir" \
    hypr/scripts/thinkpad-remap.sh hypr/scripts/remap-keymap.py
run_step hyprland-config 'pacote-hyprland pacote-kitty pacote-rofi' install_hyprland_dotfiles "$config_dir" \
    hypr/modules/appearance.lua hypr/modules/bindings.lua hypr/modules/session.lua hypr/modules/input.lua hypr/hyprland.lua

run_step sddm-tema 'pacote-sddm pacote-qt6-svg pacote-qt6-virtualkeyboard pacote-qt6-multimedia-ffmpeg pacote-xorg-server wallpaper-pack' \
    install_astronaut "$wallpaper_dir/wallpapers/arch-nord-dark.png"
run_step sddm-servico 'sddm-tema hyprland-config' enable_rice_sddm

run_step firefox-padrao 'pacote-firefox pacote-xdg-utils' set_default_firefox
finish_interactive

(( failed_steps == 0 ))
