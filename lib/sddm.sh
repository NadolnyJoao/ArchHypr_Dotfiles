#!/usr/bin/env bash
# Prepara os arquivos como usuário comum. A publicação só ocorre após a validação.
prepare_astronaut() {
    local theme=$1 wallpaper=$2 config
    config=$theme/Themes/japanese_aesthetic.conf
    [[ -f $theme/Main.qml && -f $theme/metadata.desktop && -f $config &&
       -d $theme/Fonts && -f $wallpaper ]] || return 1
    grep -q '^ConfigFile=' "$theme/metadata.desktop" || return 1
    grep -Eq '^[[:space:]]*Background[[:space:]]*=' "$config" || return 1
    install -D -m 644 -- "$wallpaper" "$theme/Backgrounds/613342.jpg" || return 1
    sed -i 's|^ConfigFile=.*|ConfigFile=Themes/japanese_aesthetic.conf|' "$theme/metadata.desktop" || return 1
    sed -Ei 's|^[[:space:]]*Background[[:space:]]*=.*|Background="Backgrounds/613342.jpg"|' "$config" || return 1
    # Mantém os textos brancos, incluindo os campos e estados de destaque.
    sed -Ei 's/^([[:space:]]*[[:alnum:]_]*TextColor[[:space:]]*=[[:space:]]*).*/\1"#ffffff"/' "$config"
}

install_astronaut() (
    local wallpaper=$1 work theme published_stage= old_theme=
    local config=/etc/sddm.conf.d/90-rice-arch.conf
    local target=/usr/share/sddm/themes/rice-arch-astronaut font_dir=/usr/share/fonts/rice-arch-astronaut
    [[ -f $wallpaper ]] || { printf 'Wallpaper do SDDM ausente: %s\n' "$wallpaper" >&2; return 1; }
    work=$(mktemp -d) || return 1
    cleanup_sddm() {
        rm -rf -- "$work"
        if [[ -n $old_theme && ! -e $target && ! -L $target ]]; then
            sudo -n mv -T -- "$old_theme" "$target" || printf 'Restaure o backup em %s\n' "$old_theme" >&2
        fi
        if [[ -n $published_stage ]]; then sudo -n rm -rf -- "$published_stage"; fi
    }
    trap cleanup_sddm EXIT
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
    sudo -n install -d -m 755 -- /usr/share/sddm/themes "$font_dir" /etc/sddm.conf.d || return 1
    published_stage=$(sudo -n mktemp -d /usr/share/sddm/themes/.rice-arch.XXXXXXXX) || return 1
    sudo -n cp -a --no-preserve=ownership -- "$theme/." "$published_stage/" || return 1
    sudo -n chmod 755 "$published_stage" || return 1
    sudo -n cp -a --no-preserve=ownership -- "$theme/Fonts/." "$font_dir/" || return 1

    # Publica o diretório completo. Em reexecuções, preserva a versão anterior.
    if [[ -e $target || -L $target ]]; then
        old_theme="$target.backup.${report_dir##*/}"
        [[ ! -e $old_theme && ! -L $old_theme ]] || return 1
        sudo -n mv -T -- "$target" "$old_theme" || return 1
        printf 'Tema anterior salvo em %s\n' "$old_theme"
    fi
    if ! sudo -n mv -T -- "$published_stage" "$target"; then
        if [[ -n $old_theme ]]; then sudo -n mv -T -- "$old_theme" "$target"; fi
        return 1
    fi
    published_stage=
    sudo -n install -m 644 -- "$work/sddm.conf" "$config" || return 1
    # sddm.conf tem precedência sobre todos os drop-ins. Não anuncie sucesso
    # se outra configuração selecionar um tema ou diretório diferente.
    python "$project_dir/lib/check-sddm.py" /usr/lib/sddm/sddm.conf.d \
        /etc/sddm.conf.d /etc/sddm.conf "${target%/*}"
)

enable_rice_sddm() {
    systemctl is-enabled --quiet sddm.service && return 10
    sudo -n systemctl enable sddm.service || return 1
    systemctl is-enabled --quiet sddm.service || return 1
}
