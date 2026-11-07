#!/usr/bin/env bash
# Prepara os arquivos como usuário comum. A publicação só ocorre após a validação.
prepare_astronaut() {
    local theme=$1 wallpaper=$2 config
    config=$theme/Themes/japanese_aesthetic.conf
    [[ -f $theme/Main.qml && -f $theme/metadata.desktop && -f $config &&
       -d $theme/Fonts && -f $wallpaper ]] || return 1
    grep -q '^ConfigFile=' "$theme/metadata.desktop" || return 1
    grep -Eq '^[[:space:]]*Background[[:space:]]*=' "$config" || return 1
    install -D -m 644 -- "$wallpaper" "$theme/Backgrounds/arch-nord-dark.png" || return 1
    sed -i 's|^ConfigFile=.*|ConfigFile=Themes/japanese_aesthetic.conf|' "$theme/metadata.desktop" || return 1
    sed -Ei 's|^[[:space:]]*Background[[:space:]]*=.*|Background="Backgrounds/arch-nord-dark.png"|' "$config"
}

install_astronaut() (
    local wallpaper=$1 work theme config=/etc/sddm.conf.d/90-rice-arch.conf
    local target=/usr/share/sddm/themes/rice-arch-astronaut font_dir=/usr/share/fonts/rice-arch-astronaut
    [[ -f $wallpaper ]] || { printf 'Wallpaper do SDDM ausente: %s\n' "$wallpaper" >&2; return 1; }
    work=$(mktemp -d) || return 1
    trap 'rm -rf -- "$work"' EXIT
    theme=$work/theme
    git clone --depth 1 -- https://github.com/Keyitdev/sddm-astronaut-theme.git "$theme" || return 1
    git -C "$theme" rev-parse HEAD || return 1
    prepare_astronaut "$theme" "$wallpaper" || { echo 'Estrutura inesperada do tema Astronaut.' >&2; return 1; }
    # O greeter lê um arquivo de sistema; a imagem fica acessível antes do login.
    printf '[Theme]\nCurrent=rice-arch-astronaut\n' > "$work/sddm.conf" || return 1
    if [[ -e $config ]]; then
        mkdir -p -- "$report_dir/backup/etc/sddm.conf.d" || return 1
        cp -a -- "$config" "$report_dir/backup/etc/sddm.conf.d/" || return 1
    fi
    # Um diretório exclusivo permite substituir o tema sem tocar em temas de terceiros.
    rm -rf -- "$theme/.git" || return 1
    chmod -R a+rX -- "$theme" || return 1
    sudo -n install -d -m 755 -- "$target" "$font_dir" /etc/sddm.conf.d || return 1
    sudo -n cp -a --no-preserve=ownership -- "$theme/." "$target/" || return 1
    sudo -n cp -a --no-preserve=ownership -- "$theme/Fonts/." "$font_dir/" || return 1
    sudo -n install -m 644 -- "$work/sddm.conf" "$config"
)

enable_rice_sddm() {
    systemctl is-enabled --quiet sddm.service && return 10
    sudo -n systemctl enable sddm.service || return 1
    systemctl is-enabled --quiet sddm.service || return 1
}
