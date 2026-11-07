#!/usr/bin/env bash

set_default_firefox() {
    local browser
    browser=$(xdg-settings get default-web-browser) || return 1
    [[ $browser == firefox.desktop ]] && return 10
    xdg-settings set default-web-browser firefox.desktop || return 1
    xdg-settings check default-web-browser firefox.desktop | grep -Fxq yes
}

configure_git_identity() {
    local name=$1 email=$2
    [[ -n $name && $email == ?*@?* ]] || return 1
    if [[ $(git config --global --get user.name) == "$name" &&
          $(git config --global --get user.email) == "$email" ]]; then
        return 10
    fi
    git config --global user.name "$name" && git config --global user.email "$email"
}

# Execute com terminal disponível: ssh-keygen pede a frase secreta diretamente.
prepare_github_key() {
    local key=$1 email=$2
    if [[ -f $key && -f $key.pub ]]; then
        ssh-keygen -l -f "$key.pub" >/dev/null || return 1
        return 10
    fi
    # Preserve pares incompletos e links existentes.
    if [[ -e $key || -L $key || -e $key.pub || -L $key.pub ]]; then
        printf 'Par de chaves incompleto em %s. Confira os arquivos existentes.\n' "$key" >&2
        return 1
    fi
    mkdir -p -m 700 -- "$(dirname -- "$key")" || return 1
    ssh-keygen -t ed25519 -C "$email" -f "$key" || return 1
    [[ -f $key && -f $key.pub ]]
}

finish_interactive() {
    local name='' email='' answer='' key=$HOME/.ssh/id_ed25519 result
    if [[ ! -t 0 ]]; then
        record_step git-identidade PULADO 'Requer terminal interativo.'
        record_step github-chave PULADO 'Requer terminal interativo.'
        return 0
    fi
    if [[ ${step_status[pacote-git]:-} == OK || ${step_status[pacote-git]:-} == JA_PRONTO ]]; then
        local current_name current_email
        current_name=$(git config --global --get user.name) || current_name=
        current_email=$(git config --global --get user.email) || current_email=
        read -r -p "Nome do Git [$current_name]: " name || name=
        read -r -p "E-mail do Git [$current_email]: " email || email=
        name=${name:-$current_name}
        email=${email:-$current_email}
        if [[ -n $name && -n $email ]]; then
            run_step git-identidade pacote-git configure_git_identity "$name" "$email"
        else
            record_step git-identidade PULADO 'Nome ou e-mail não informado.'
        fi
    else
        record_step git-identidade PULADO 'Git indisponível.'
    fi
    case ${step_status[pacote-openssh]:-} in
        OK|JA_PRONTO)
            if [[ -z $email && ! -f $key.pub ]]; then
                read -r -p "E-mail para identificar a chave SSH (Enter para pular): " email || email=
            fi
            if [[ -z $email && ! -f $key.pub ]]; then
                record_step github-chave PULADO 'E-mail não informado.'
            else
                prepare_github_key "$key" "$email"
                result=$?
                case $result in
                    0) record_step github-chave OK 'Chave pública criada.' ;;
                    10) record_step github-chave JA_PRONTO 'Chave existente reaproveitada.' ;;
                    *) failed_steps=$((failed_steps + 1))
                       record_step github-chave FALHOU 'Confira a mensagem do ssh-keygen acima.' ;;
                esac
                if (( result == 0 || result == 10 )); then
                    printf '\nCopie esta chave pública para https://github.com/settings/keys\n\n'
                    cat -- "$key.pub"
                    printf '\nDepois do cadastro, teste com: ssh -T git@github.com\n'
                fi
            fi ;;
        *) record_step github-chave PULADO 'OpenSSH indisponível.' ;;
    esac

    printf '\nRelatório: %s/resumo.tsv\n' "$report_dir"
    if (( failed_steps > 0 || skipped_steps > 0 )); then
        printf 'Instalação incompleta. Resolva as falhas/etapas puladas antes de reiniciar.\n'
        return 0
    fi
    read -r -p 'Reiniciar agora? [s/N] ' answer || return 0
    case "$answer" in
        s|S|sim|Sim|SIM)
            run_step reinicio '' systemctl reboot ;;
    esac
}
