#!/usr/bin/env bash
# O chamador fornece report_dir. Cada etapa registra um resultado verificável.
declare -A step_status=()
failed_steps=0
skipped_steps=0

record_step() {
    local name=$1 status=$2 detail=$3
    step_status[$name]=$status
    if [[ $status == PULADO ]]; then
        skipped_steps=$((skipped_steps + 1))
    fi
    printf '%s\t%s\t%s\n' "$status" "$name" "$detail" >> "$report_dir/resumo.tsv"
    printf '[%s] %s\n' "$status" "$name"
}

# Sintaxe: run_step nome "dependência1 dependência2" comando [argumentos].
# Códigos das etapas: 0 concluído, 10 já pronto, demais falha.
run_step() {
    local name=$1 dependencies=$2 dependency result
    shift 2
    for dependency in $dependencies; do
        case ${step_status[$dependency]:-} in
            OK|JA_PRONTO) ;;
            *)
                record_step "$name" PULADO "Dependência indisponível: $dependency"
                return 0
                ;;
        esac
    done

    # Reautentique no terminal se downloads longos expirarem o cache do sudo.
    # O prompt fica visível, mesmo que os comandos da etapa sejam enviados ao log.
    if [[ ${sudo_authorized:-0} == 1 ]] && ! sudo -n -v >/dev/null 2>&1; then
        if [[ ! -t 0 ]] || ! sudo -v </dev/tty >/dev/tty 2>&1; then
            failed_steps=$((failed_steps + 1))
            record_step "$name" FALHOU 'Autorização sudo indisponível.'
            return 0
        fi
    fi
    if ( "$@" ) > "$report_dir/$name.log" 2>&1; then
        record_step "$name" OK "$name.log"
    else
        result=$?
        if (( result == 10 )); then
            record_step "$name" JA_PRONTO "$name.log"
        else
            failed_steps=$((failed_steps + 1))
            record_step "$name" FALHOU "Código $result. Consulte $name.log"
        fi
    fi
}

# Mantém o destino original até que a nova cópia esteja pronta.
deploy_file() {
    local source=$1
    local destination=$2/$3 backup=$report_dir/backup/$3 temporary

    [[ -f $source ]] || return 1
    if [[ -f $destination && ! -L $destination ]] && cmp -s -- "$source" "$destination"; then
        return 10
    fi
    if [[ -e $destination || -L $destination ]]; then
        [[ -f $destination || -L $destination ]] || return 1
        mkdir -p -- "$(dirname -- "$backup")" || return
        cp -a -- "$destination" "$backup" || return
    fi
    mkdir -p -- "$(dirname -- "$destination")" || return
    temporary=$(mktemp -- "$(dirname -- "$destination")/.rice.XXXXXXXX") || return
    if install -m 644 -- "$source" "$temporary" && mv -fT -- "$temporary" "$destination"; then
        return 0
    fi
    rm -f -- "$temporary"
    return 1
}
