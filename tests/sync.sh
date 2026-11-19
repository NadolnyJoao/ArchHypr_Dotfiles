#!/usr/bin/env bash
# Integração isolada: coleta de preferências e implantação com caminhos de outro usuário.
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config" XDG_DATA_HOME="$work/home/.local/share" XDG_STATE_HOME="$work/home/.local/state"
mkdir -p "$work/repo" "$work/bin" "$XDG_CONFIG_HOME/sway" "$XDG_CONFIG_HOME/hypr/modules"
cp -r "$root/dotfiles" "$root/tools" "$root/packages" "$work/repo/"
git -C "$work/repo" init -q
git -C "$work/repo" -c user.name=Teste -c user.email=test@example.invalid commit --allow-empty -qm inicial
printf 'gaps inner 0\noutput eDP-1 scale 1.25\ninput * xkb_layout br\n' > "$XDG_CONFIG_HOME/sway/local.conf"
printf 'local_keyboard = true\n' > "$XDG_CONFIG_HOME/hypr/modules/input.lua"
printf 'set $root /home/outro/.config/sway\ninclude local.conf\n' > "$XDG_CONFIG_HOME/sway/config"
python3 "$work/repo/tools/sync-configs.py" collect --apply > "$work/collect.log"
grep -q '@SWAY_ROOT@' "$work/repo/dotfiles/sway/config"
grep -q 'gaps inner 0' "$work/repo/dotfiles/sway/config.d/preferences.conf"
! grep -q 'eDP-1\|xkb_layout' "$work/repo/dotfiles/sway/config.d/preferences.conf"
! grep -q local_keyboard "$work/repo/dotfiles/hypr/modules/input.lua"
# Restaure o config completo após o teste de normalização.
cp "$root/dotfiles/sway/config" "$work/repo/dotfiles/sway/config"
cat > "$work/bin/sway" <<'CMD'
#!/bin/sh
exit "${SWAY_TEST_FAILURE:-0}"
CMD
cat > "$work/bin/gsettings" <<'CMD'
#!/bin/sh
printf "'Papirus-Dark'\n"
CMD
cat > "$work/bin/update-desktop-database" <<'CMD'
#!/bin/sh
exit 0
CMD
chmod +x "$work/bin/"*
export PATH="$work/bin:$PATH"
# O helper de teste recebe um desktop isolado e pode executar em CI como root.
cat > "$work/ark.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Ark
Exec=ark %U
DBusActivatable=true
DESKTOP
python3 - "$work/repo/tools/configurar-ark.py" "$work/ark.desktop" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('if os.geteuid() == 0:', 'if False:')
s=s.replace('Path("/usr/share/applications/org.kde.ark.desktop")', 'Path('+repr(sys.argv[2])+')')
p.write_text(s)
PY
# Falha do parser deve parar antes de escrever a configuração principal.
SWAY_TEST_FAILURE=1 python3 "$work/repo/tools/sync-configs.py" apply --desktop sway --apply > "$work/failure.log" 2>&1 && exit 1
! test -f "$XDG_CONFIG_HOME/sway/scripts/theme.py"
python3 "$work/repo/tools/sync-configs.py" apply --desktop sway --apply > "$work/apply.log"
grep -q "$XDG_CONFIG_HOME/sway" "$XDG_CONFIG_HOME/sway/config"
grep -q 'gaps inner 0' "$XDG_CONFIG_HOME/sway/config.d/preferences.conf"
grep -q 'output eDP-1' "$XDG_CONFIG_HOME/sway/local.conf"
grep -q local_keyboard "$XDG_CONFIG_HOME/hypr/modules/input.lua"
grep -q 'rice-ark-floating' "$XDG_CONFIG_HOME/sway/config.d/appearance.conf"
grep -q 'rice-ark/configurar-ark.py' "$XDG_DATA_HOME/applications/org.kde.ark.desktop"
! grep -Rq '/home/outro' "$XDG_CONFIG_HOME"
python3 "$work/repo/tools/sync-configs.py" apply --desktop sway --apply > "$work/repeat.log"
test "$(grep -c '^# rice-ark-floating' "$XDG_CONFIG_HOME/sway/config.d/appearance.conf")" = 1
# Um erro posterior à cópia precisa restaurar os arquivos anteriores.
printf 'local-preservado\n' >> "$XDG_CONFIG_HOME/sway/config.d/preferences.conf"
printf '[Desktop Entry]\nExec=programa-incompativel\n' > "$work/ark.desktop"
python3 "$work/repo/tools/sync-configs.py" apply --desktop sway --apply > "$work/rollback.log" 2>&1 && exit 1
grep -q local-preservado "$XDG_CONFIG_HOME/sway/config.d/preferences.conf"
# A configuração padrão do Sway não pode depender do módulo do Hyprland.
python3 - "$root/dotfiles/sway/waybar/config.jsonc" <<'PYTEST'
import json, sys
config=json.load(open(sys.argv[1]))
assert "sway/workspaces" in config["modules-left"]
assert "hypr/scripts" not in config["custom/power"]["on-click"]
PYTEST
printf '[OK] coleta, exclusões locais, validação, Ark e reexecução\n'
