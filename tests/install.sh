#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cp -a -- . "$temp/project"
rm -rf -- "$temp/project/.git"
mkdir -p "$temp/bin" "$temp/home"

python3 - "$temp" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
# O container de testes pode executar apenas como root. Desative o guard
# exclusivamente nesta cópia, cujos comandos e destinos estão isolados.
if __import__("os").geteuid() == 0:
    entry = root / "project/install.sh"
    entry.write_text(entry.read_text().replace("if (( EUID == 0 )) ||", "if false ||"))
for relative in ("lib/sddm.sh", "lib/check-sddm.py"):
    p = root / "project" / relative
    text = p.read_text()
    for path in ("/usr/share/sddm", "/usr/share/fonts", "/usr/lib/sddm", "/etc/sddm"):
        text = text.replace(path, str(root / "system") + path)
    p.write_text(text)
keyd_entry = root / "project/system/keyd/apply.sh"
keyd_text = keyd_entry.read_text().replace("/etc/keyd", str(root / "system/etc/keyd"))
if __import__("os").geteuid() != 0:
    keyd_text = keyd_text.replace("if (( EUID != 0 )); then", "if false; then")
keyd_entry.write_text(keyd_text)
for name in ("keyd", "sudo", "pacman", "vercmp", "git", "systemctl", "gsettings", "xdg-settings",
             "xdg-mime", "xfconf-query", "flatpak", "update-desktop-database"):
    (root / "bin" / name).symlink_to(root / "project/tests/mocks/command.py")
PY
chmod +x "$temp/project/tests/mocks/command.py"
chmod 755 "$temp"


run_installer() {
    local expected=$1 failure=$2 code=0
    env HOME="$temp/home" PATH="$temp/bin:$PATH" \
        XDG_CONFIG_HOME="$temp/home/.config" XDG_DATA_HOME="$temp/home/.local/share" \
        XDG_STATE_HOME="$temp/home/.local/state" XDG_DATA_DIRS="$temp/home/empty" \
        MOCK_FAIL_PACKAGE="$failure" \
        bash "$temp/project/install.sh" </dev/null >"$temp/output.log" 2>&1 || code=$?
    if (( code != expected )); then
        cat "$temp/output.log"
        printf 'Código inesperado: %s, esperado: %s\n' "$code" "$expected" >&2
        return 1
    fi
}

# Sem terminal, nome/e-mail e chave SSH são pulados e a saída é parcial (2).
run_installer 2 ''
report=$(find "$temp/home/.local/state" -name resumo.tsv -print -quit)
! grep -q '^FALHOU' "$report"
for step in hyprland-config desktop-config nordic-tema neovim-associacoes \
    thunar-miniaturas gtk-preferencias portais-config audio-servicos sddm-servico keyd-servico; do
    grep -Eq "^(OK|JA_PRONTO)[[:space:]]+$step[[:space:]]" "$report"
done
cmp system/keyd/default.conf "$temp/system/etc/keyd/default.conf"
[[ -f $temp/home/.config/fish/conf.d/rice-arch.fish ]]
[[ -f $temp/home/.local/share/themes/Nordic/gtk-3.0/gtk.css ]]
[[ -f $temp/home/.local/share/applications/rice-arch-neovim.desktop ]]
grep -q '#ffffff' "$temp/system/usr/share/sddm/themes/rice-arch-astronaut/Themes/japanese_aesthetic.conf"

# A reexecução preserva um arranjo local de monitores e o conteúdo do Neovim.
printf '%s\n' '-- monitor local' > "$temp/home/.config/hypr/modules/monitors.local.lua"
printf '%s\n' '-- minha edição' > "$temp/home/.config/nvim/init.lua"
run_installer 2 ''
grep -q 'minha edição' "$temp/home/.config/nvim/init.lua"
grep -q 'monitor local' "$temp/home/.config/hypr/modules/monitors.local.lua"

# Se a publicação falhar, a versão anterior do tema deve ser restaurada.
printf 'preservar\n' > "$temp/system/usr/share/sddm/themes/rice-arch-astronaut/sentinel"
export MOCK_FAIL_SDDM_PUBLISH=1
run_installer 1 ''
unset MOCK_FAIL_SDDM_PUBLISH
grep -q preservar "$temp/system/usr/share/sddm/themes/rice-arch-astronaut/sentinel"

# Uma nova instalação com falha no Rofi continua com componentes independentes.
rm -rf -- "$temp/home" "$temp/system"
mkdir "$temp/home"
run_installer 1 rofi
report=$(find "$temp/home/.local/state" -name resumo.tsv -print -quit)
grep -Eq '^FALHOU[[:space:]]+pacote-rofi[[:space:]]' "$report"
grep -Eq '^PULADO[[:space:]]+hyprland-config[[:space:]]' "$report"
grep -Eq '^(OK|JA_PRONTO)[[:space:]]+neovim-associacoes[[:space:]]' "$report"
grep -Eq '^PULADO[[:space:]]+sddm-servico[[:space:]]' "$report"

# Falhas em componentes chamados pela sessão não podem publicar uma entrada nova.
for failure in hyprpaper hyprlock grim; do
    rm -rf -- "$temp/home" "$temp/system"
    mkdir -p "$temp/home/.config/hypr"
    printf 'configuração anterior\n' > "$temp/home/.config/hypr/hyprland.lua"
    run_installer 1 "$failure"
    report=$(find "$temp/home/.local/state" -name resumo.tsv -print -quit)
    grep -Eq '^PULADO[[:space:]]+hyprland-config[[:space:]]' "$report"
    grep -Eq '^PULADO[[:space:]]+sddm-servico[[:space:]]' "$report"
    grep -Fxq 'configuração anterior' "$temp/home/.config/hypr/hyprland.lua"
done

# O arquivo legado tem prioridade sobre nosso drop-in: detectar conflito.
rm -rf -- "$temp/home" "$temp/system"
mkdir -p "$temp/home" "$temp/system/etc"
printf '[Theme]\nCurrent=outro-tema\n' > "$temp/system/etc/sddm.conf"
run_installer 1 ''
report=$(find "$temp/home/.local/state" -name resumo.tsv -print -quit)
grep -Eq '^FALHOU[[:space:]]+sddm-tema[[:space:]]' "$report"
grep -Eq '^PULADO[[:space:]]+sddm-servico[[:space:]]' "$report"
grep -Fxq 'Current=outro-tema' "$temp/system/etc/sddm.conf"
