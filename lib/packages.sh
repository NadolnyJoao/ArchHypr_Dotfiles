#!/usr/bin/env bash
# Consulta primeiro o banco local. Uma atualização que falhou impede novas
# instalações via pacman, mas os pacotes já presentes podem ser aproveitados.
install_arch_package() {
    local package=$1 can_install=$2
    if pacman -Q -- "$package"; then
        return 10
    fi
    if [[ $can_install != OK ]]; then
        printf 'Pacote ausente e atualização do sistema indisponível.\n' >&2
        return 1
    fi
    sudo -n pacman -S --needed --noconfirm -- "$package" || return 1
    pacman -Q -- "$package" || return 1
}

# Registra cada pacote separadamente para que a falha de um não impeça os demais.
install_arch_packages() {
    local package
    run_step atualizacao '' sudo -n pacman -Syu --noconfirm
    for package in "$@"; do
        run_step "pacote-$package" '' install_arch_package "$package" "${step_status[atualizacao]}"
    done
}

install_youtube_music() {
    local app=app.ytmdesktop.ytmdesktop
    if flatpak info --user "$app"; then
        return 10
    fi
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || return 1
    flatpak install --user --noninteractive flathub "$app" || return 1
    flatpak info --user "$app" || return 1
}
