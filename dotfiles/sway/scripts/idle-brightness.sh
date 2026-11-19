#!/usr/bin/env bash
# Diminui o brilho de um painel interno e restaura o valor anterior ao voltar.
set -uo pipefail
runtime_dir=${XDG_RUNTIME_DIR:?Sessão sem XDG_RUNTIME_DIR}
state="$runtime_dir/rice-arch-brightness-${HYPRLAND_INSTANCE_SIGNATURE:-session}"
exec 9>"$state.lock" || exit 1
flock 9 || exit 1

case "${1:-}" in
    dim)
        [[ ! -e $state ]] || exit 0
        current=$(brightnessctl -c backlight get 2>/dev/null) || exit 0
        maximum=$(brightnessctl -c backlight max 2>/dev/null) || exit 0
        [[ $current =~ ^[0-9]+$ && $maximum =~ ^[0-9]+$ ]] || exit 1
        # Um painel que já estiver abaixo de 20% não precisa ficar mais claro.
        (( current * 5 > maximum )) || exit 0
        printf '%s\n' "$current" > "$state" || exit 1
        if ! brightnessctl -c backlight set 20%; then
            rm -f -- "$state"
            exit 1
        fi
        ;;
    restore)
        [[ -f $state ]] || exit 0
        read -r previous < "$state" || exit 1
        [[ $previous =~ ^[0-9]+$ ]] || exit 1
        brightnessctl -c backlight set "$previous" && rm -f -- "$state"
        ;;
    *) exit 2 ;;
esac
