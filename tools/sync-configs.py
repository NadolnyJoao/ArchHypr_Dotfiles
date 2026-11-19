#!/usr/bin/env python3
"""Coleta ou aplica os arquivos portáveis do rice, com backup por execução."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
DATA = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "rice-arch"
GENERATED = {
    "hypr/current-theme", "hypr/modules/colors.lua", "waybar/colors.css",
    "swaync/colors.css", "rofi/colors.rasi", "kitty/colors.conf",
    "sway/current-theme", "sway/colors.lua", "sway/config.d/colors.conf",
    "sway/waybar/colors.css", "sway/rofi/colors.rasi", "sway/kitty/colors.conf",
}
LOCAL = {"hypr/modules/input.lua", "hypr/modules/monitors.local.lua",
         "sway/local.conf", "sway/config.d/input.conf"}


def files():
    for path in sorted((REPO / "dotfiles").rglob("*")):
        if path.is_file() and not path.is_symlink() and "__pycache__" not in path.parts:
            relative = str(path.relative_to(REPO / "dotfiles"))
            if relative not in GENERATED and relative != "sway/local.conf":
                yield relative, path


def portable(relative, text):
    if relative == "sway/config":
        text = re.sub(r"(?m)^set \$root .*$", "set $root @SWAY_ROOT@", text)
        if "include config.d/preferences.conf" not in text:
            text = text.replace("include local.conf", "include config.d/preferences.conf\ninclude local.conf")
    if relative.endswith("/gtk-theme.sh"):
        text = re.sub(r'(?m)^python3 .* --apply "\$theme"$',
                      'python3 "${XDG_DATA_HOME:-$HOME/.local/share}/rice-ark/configurar-ark.py" --apply "$theme"', text)
        # O helper já sabe qual sessão disparou a atualização de tema.
    return text


def collect(apply):
    changes = []
    for relative, destination in files():
        if relative in LOCAL or relative == "sway/config.d/preferences.conf":
            continue
        source = (DATA if relative.startswith("applications/") else CONFIG) / relative
        if not source.is_file() or source.is_symlink():
            continue
        text = portable(relative, source.read_text())
        if destination.read_text() != text:
            changes.append((destination, text.encode()))
    # As margens/bordas de local.conf tornam-se preferências compartilhadas.
    local = CONFIG / "sway/local.conf"
    if local.is_file():
        preferences = []
        for line in local.read_text().splitlines():
            if re.match(r"^\s*(gaps|default_border|default_floating_border|font|focus_follows_mouse|hide_edge_borders|smart_borders|smart_gaps|titlebar_border_thickness|titlebar_padding)\s", line):
                preferences.append(line.strip())
        if preferences:
            destination = REPO / "dotfiles/sway/config.d/preferences.conf"
            text = "# Preferências visuais coletadas de local.conf.\n" + "\n".join(preferences) + "\n"
            if destination.read_text() != text:
                changes.append((destination, text.encode()))
    for destination, _ in changes:
        print(f"[COLETAR] {destination.relative_to(REPO)}")
    if apply:
        for destination, content in changes:
            destination.write_bytes(content)
    return [str(path.relative_to(REPO)) for path, _ in changes]


def profiles(desktop):
    if desktop == "both":
        return ["hypr", "sway"]
    if desktop != "auto":
        return ["hypr" if desktop == "hyprland" else desktop]
    result = []
    if (CONFIG / "hypr/hyprland.lua").exists():
        result.append("hypr")
    if (CONFIG / "sway/config").exists() or os.environ.get("SWAYSOCK"):
        result.append("sway")
    return result or ["hypr"]


def package_list(selected):
    names = ["desktop", "neovim"] if "hypr" in selected else []
    if "sway" in selected:
        names.extend(["sway", "neovim"])
    packages = {"ark", "qt6ct", "desktop-file-utils"}
    for name in names:
        for line in (REPO / f"packages/{name}.txt").read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                packages.add(line.split()[0])
    return sorted(packages)


def apply_configs(selected, apply):
    with tempfile.TemporaryDirectory(prefix="rice-preparacao-") as temporary:
        stage = Path(temporary) / "config"
        stage.mkdir()
        changes = []
        for relative, source in files():
            is_sway = relative.startswith("sway/") or relative.endswith("/sway-portals.conf")
            if is_sway and "sway" not in selected:
                continue
            if not is_sway and relative.startswith("hypr/") and "hypr" not in selected:
                continue
            target = (DATA if relative.startswith("applications/") else CONFIG) / relative
            if relative in LOCAL and target.exists():
                print(f"[LOCAL] {target}")
                continue
            content = source.read_bytes()
            if relative == "sway/config":
                content = source.read_text().replace("@SWAY_ROOT@", json.dumps(str(CONFIG / "sway"))).encode()
            if target.is_symlink():
                print(f"[LINK PRESERVADO] {target}")
                continue
            changes.append((target, content, relative))
            if not relative.startswith("applications/"):
                staged = stage / relative
                staged.parent.mkdir(parents=True, exist_ok=True)
                staged.write_bytes(content)

        # As preferências de teclado e monitor locais precisam existir na validação.
        for relative in ("hypr/modules/input.lua", "hypr/modules/monitors.local.lua",
                         "sway/local.conf", "sway/config.d/input.conf"):
            source = CONFIG / relative
            target = stage / relative
            if source.is_file():
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.read_bytes())
        if "sway" in selected:
            (stage / "sway/local.conf").touch(exist_ok=True)
            if not (CONFIG / "sway/local.conf").exists():
                changes.append((CONFIG / "sway/local.conf", "# Preferências locais desta máquina.\n".encode(), "sway/local.conf"))

        # Preserve o tema de cada sessão e gere as cores antes de publicá-las.
        for profile in selected:
            current = CONFIG / profile / "current-theme"
            theme = current.read_text().strip() if current.exists() else "nord"
            if profile == "hypr":
                for directory in ("waybar", "swaync", "rofi", "kitty", "hypr/modules"):
                    (stage / directory).mkdir(parents=True, exist_ok=True)
                env = {**os.environ, "XDG_CONFIG_HOME": str(stage)}
                subprocess.run(["bash", str(stage / "hypr/scripts/theme.sh"), theme, "--offline"], env=env, check=True)
                generated = [path for path in GENERATED if not path.startswith("sway/")]
            else:
                env = {**os.environ, "SWAY_SETUP_ROOT": str(stage / "sway")}
                subprocess.run(["python3", str(stage / "sway/scripts/theme.py"), theme, "--offline"], env=env, check=True)
                generated = [path for path in GENERATED if path.startswith("sway/")]
            for relative in generated:
                source = stage / relative
                target = CONFIG / relative
                if source.is_file() and not target.is_symlink():
                    changes.append((target, source.read_bytes(), relative))

        helper = DATA / "rice-ark/configurar-ark.py"
        changes.append((helper, (REPO / "tools/configurar-ark.py").read_bytes(), "data/rice-ark/configurar-ark.py"))
        changes = [(p, data, rel) for p, data, rel in changes if not p.is_file() or p.read_bytes() != data]
        for target, _, _ in changes:
            print(f"[ATUALIZAR] {target}")
        if not apply:
            return

        # O parser nativo confere a configuração montada antes de escrever no usuário.
        if "sway" in selected:
            subprocess.run(["sway", "--validate", "--config", str(stage / "sway/config")], check=True)
        STATE.mkdir(parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix="atualizacao-", dir=STATE))
        print(f"Backup e relatório em {backup}")
        # Arquivos que o helper do Ark gera também precisam de backup.
        ark_paths = ["arkrc", "kdeglobals", "qt6ct/qt6ct.conf", "qt6ct/colors/rice-ark.conf",
                     "hypr/modules/appearance.lua", "hypr/scripts/gtk-theme.sh",
                     "sway/config.d/appearance.conf", "sway/scripts/gtk-theme.sh"]
        extra_targets = [(CONFIG / relative, relative) for relative in ark_paths]
        extra_targets.extend([(DATA / "applications/org.kde.ark.desktop", "data/applications/org.kde.ark.desktop"),
                              (DATA / "color-schemes/RiceArk.colors", "data/color-schemes/RiceArk.colors")])
        snapshots = {}
        for target, relative in [(p, rel) for p, _, rel in changes] + extra_targets:
            if target in snapshots:
                continue
            snapshots[target] = (target.read_bytes(), target.is_symlink(), os.readlink(target) if target.is_symlink() else None) if target.is_file() else None
            if target.is_file():
                saved = backup / relative
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(target, saved, follow_symlinks=True)
        try:
            for target, content, _ in changes:
                target.parent.mkdir(parents=True, exist_ok=True)
                temp = target.with_name(target.name + ".rice-next")
                temp.write_bytes(content)
                temp.replace(target)
            env = {**os.environ, "RICE_DESKTOP": "sway" if "sway" in selected and (os.environ.get("SWAYSOCK") or "hypr" not in selected) else "hypr"}
            subprocess.run(["python3", str(helper), "--setup"], env=env, check=True)
        except BaseException:
            for target, snapshot in snapshots.items():
                if snapshot is None:
                    target.unlink(missing_ok=True)
                elif snapshot[1]:
                    target.unlink(missing_ok=True)
                    target.symlink_to(snapshot[2])
                else:
                    target.write_bytes(snapshot[0])
            raise
        (backup / "versao.txt").write_text(subprocess.check_output(["git", "-C", str(REPO), "rev-parse", "HEAD"], text=True))
        print("Atualizado. Feche e reabra Ark. Entre novamente na sessão para carregar os processos atualizados.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("collect", "apply", "packages"))
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--desktop", choices=("auto", "hyprland", "sway", "both"), default="auto")
    args = parser.parse_args()
    if args.action == "collect":
        collect(args.apply)
    else:
        selected = profiles(args.desktop)
        if args.action == "packages":
            print("\n".join(package_list(selected)))
        else:
            apply_configs(selected, args.apply)
