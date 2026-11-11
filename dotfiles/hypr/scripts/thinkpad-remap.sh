#!/usr/bin/env bash
set -euo pipefail
config=${XDG_CONFIG_HOME:-$HOME/.config}/hypr
runtime=${XDG_RUNTIME_DIR:?Execute no Hyprland}
instance=${HYPRLAND_INSTANCE_SIGNATURE:?Execute no Hyprland}
map="$runtime/rice-thinkpad-$instance.xkb"

build_map() {
    local work
    work=$(mktemp -d -- "$map.XXXXXXXX") || return 1
    (
        trap 'rm -rf -- "$work"' EXIT
        # Algumas sessões só entregam o mapa quando uma janela recebe o foco.
        if timeout 5 xkbcli dump-keymap-wayland > "$work/original.xkb" &&
           validate_map "$work"; then
            mv -fT -- "$work/remap.xkb" "$map"
            exit $?
        fi

        if ! command -v wev >/dev/null; then
            printf 'A captura automática falhou. Instale o pacote wev e tente novamente.\n' >&2
            exit 1
        fi
        rm -f -- "$work/original.xkb"
        printf 'Clique na janela do wev, pressione Ctrl direito e feche com Super + Q.\n' >&2
        wev -f wl_keyboard:key -M "$work/original.xkb" || true
        if ! validate_map "$work"; then
            printf 'Não foi possível capturar e validar o mapa pelo wev.\n' >&2
            exit 1
        fi
        mv -fT -- "$work/remap.xkb" "$map"
    )
}

validate_map() {
    local work=$1
    [[ -s $work/original.xkb ]] || return 1
    # O arquivo entregue pelo Wayland pode terminar em NUL.
    tr -d '\000' < "$work/original.xkb" |
        python3 "$config/scripts/remap-keymap.py" > "$work/remap.xkb" || return 1
    xkbcli compile-keymap --from-xkb < "$work/remap.xkb" >/dev/null
}

case "${1:-}" in
    on)
        [[ -s $map ]] || build_map
        # Aplique também quando o módulo de teclado local não carrega kb_file.
        hyprctl -r eval "hl.config({ input = { kb_file = \"$map\" } })"
        ;;
    off)
        rm -f -- "$map"
        hyprctl reload
        ;;
    *) printf 'Uso: %s on|off\n' "$0" >&2; exit 2 ;;
esac
