#!/usr/bin/env python3
"""Configura Ark para a paleta do rice e adiciona a regra de janela flutuante."""
import configparser
import fcntl
import io
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
DATA = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
HELPER = DATA / "rice-ark/configurar-ark.py"
MARKER = "# Tema Qt/KDE sincronizado pelo configurar-ark.py."


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + ".next")
    temp.write_text(text)
    temp.replace(path)


def update_ini(path, sections):
    # Preserve todas as opções existentes, com a grafia usada por Qt/KDE.
    parser = configparser.RawConfigParser(strict=False)
    parser.optionxform = str
    if path.exists():
        parser.read(path)
    for section, values in sections.items():
        if not parser.has_section(section):
            parser.add_section(section)
        for key, value in values.items():
            parser.set(section, key, value)
    output = io.StringIO()
    parser.write(output, space_around_delimiters=False)
    write(path, output.getvalue())


def apply_theme(requested=None):
    HELPER.parent.mkdir(parents=True, exist_ok=True)
    with (HELPER.parent / "theme.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        _apply_theme(requested)


def _apply_theme(requested=None):
    profile = os.environ.get("RICE_DESKTOP") or ("sway" if os.environ.get("SWAYSOCK") else "hypr")
    root = CONFIG / profile
    theme = requested or (root / "current-theme").read_text().strip()
    if theme not in ("nord", "gruvbox", "catppuccin", "solitude"):
        raise ValueError("Tema desconhecido")
    base, text, accent = (root / "themes" / theme).read_text().splitlines()[0].split()
    if not all(re.fullmatch(r"[0-9a-fA-F]{6}", c) for c in (base, text, accent)):
        raise ValueError("Paleta inválida")
    # Ordem dos papéis de QPalette, incluindo Accent do Qt 6.
    colors = [text, base, base, base, base, base, text, text, text,
              base, base, base, accent, base, accent, accent, base,
              text, base, text, text, accent]
    palette = ",".join("#ff" + color for color in colors)
    muted = "".join(f"{round(int(text[i:i+2], 16) * 0.45 + int(base[i:i+2], 16) * 0.55):02x}" for i in (0, 2, 4))
    disabled = colors.copy()
    for index in (0, 6, 8, 20):
        disabled[index] = muted
    palette_file = CONFIG / "qt6ct/colors/rice-ark.conf"
    update_ini(palette_file, {"ColorScheme": {"active_colors": palette, "inactive_colors": palette,
                                               "disabled_colors": ",".join("#ff" + c for c in disabled)}})
    icons = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
                           capture_output=True, text=True)
    icon_theme = icons.stdout.strip().strip("'") if icons.returncode == 0 else "Papirus-Dark"
    update_ini(CONFIG / "qt6ct/qt6ct.conf", {"Appearance": {
        "style": "Fusion", "custom_palette": "true", "color_scheme_path": str(palette_file),
        "icon_theme": icon_theme or "Papirus-Dark"}})
    # Os componentes KDE também consultam as cores do kdeglobals.
    rgb = lambda value: ",".join(str(int(value[i:i+2], 16)) for i in (0, 2, 4))
    groups = {}
    for name in ("View", "Window", "Button", "Tooltip", "Complementary", "Header", "Selection"):
        selected = name == "Selection"
        groups[f"Colors:{name}"] = {
            "BackgroundNormal": rgb(accent if selected else base),
            "BackgroundAlternate": rgb(accent if selected else base),
            "ForegroundNormal": rgb(base if selected else text),
            "ForegroundInactive": rgb(base if selected else muted),
            "ForegroundLink": rgb(base if selected else accent),
            "ForegroundVisited": rgb(base if selected else accent),
            "DecorationFocus": rgb(accent), "DecorationHover": rgb(accent)}
    groups["General"] = {"ColorScheme": "RiceArk", "Name": "RiceArk"}
    groups["Icons"] = {"Theme": icon_theme or "Papirus-Dark"}
    update_ini(CONFIG / "kdeglobals", groups)

    # Registre um esquema nomeado, para o Ark selecionar a mesma paleta.
    groups["General"] = {"Name": "Rice Ark"}
    update_ini(DATA / "color-schemes/RiceArk.colors", groups)
    update_ini(CONFIG / "arkrc", {"UiSettings": {"ColorScheme": "RiceArk"}})


def install(packages=True):
    if os.geteuid() == 0:
        sys.exit("Execute como usuário comum.")
    if packages:
        subprocess.run(["sudo", "pacman", "-Syu", "--needed", "ark", "qt6ct", "desktop-file-utils"], check=True)
    state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "rice-ark"
    state.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix=datetime.now().strftime("%Y%m%d-%H%M%S-"), dir=state))
    paths = ["arkrc", "kdeglobals", "qt6ct/qt6ct.conf", "qt6ct/colors/rice-ark.conf",
             "hypr/modules/appearance.lua", "hypr/scripts/gtk-theme.sh",
             "sway/config.d/appearance.conf", "sway/scripts/gtk-theme.sh"]
    for name in paths:
        path = CONFIG / name
        if path.is_file():
            destination = backup / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, destination)

    HELPER.parent.mkdir(parents=True, exist_ok=True)
    if Path(__file__).resolve() != HELPER.resolve():
        shutil.copy2(__file__, HELPER)
    apply_theme()
    hypr = CONFIG / "hypr/modules/appearance.lua"
    if hypr.is_file() and "rice-ark-floating" not in hypr.read_text():
        with hypr.open("a") as file:
            file.write("""
-- Ark abre como os demais gerenciadores.
hl.window_rule({
    name = "rice-ark-floating",
    match = { class = "^(org[.]kde[.]ark|ark)$" },
    float = true,
    center = true,
    size = { "monitor_w*0.70", "monitor_h*0.65" },
    suppress_event = "maximize",
})
""")
    sway = CONFIG / "sway/config.d/appearance.conf"
    if sway.is_file() and "# rice-ark-floating" not in sway.read_text():
        with sway.open("a") as file:
            file.write("""
# rice-ark-floating
for_window [app_id="^(org[.]kde[.]ark|ark)$"] floating enable, resize set width 70 ppt height 65 ppt, move position center
for_window [class="(?i)^(org[.]kde[.]ark|ark)$"] floating enable, resize set width 70 ppt height 65 ppt, move position center
""")
    # Integre com os seletores de tema já usados no Hyprland e no Sway.
    for relative in ("hypr/scripts/gtk-theme.sh", "sway/scripts/gtk-theme.sh"):
        path = CONFIG / relative
        if not path.is_file():
            continue
        source = path.read_text()
        if MARKER in source:
            source = re.sub(r"(?m)^python3 .* --apply \"\$theme\"$", 'python3 "${XDG_DATA_HOME:-$HOME/.local/share}/rice-ark/configurar-ark.py" --apply "$theme"', source)
            write(path, source)
            continue
        anchor = 'data=${XDG_DATA_HOME:-$HOME/.local/share}'
        if source.count(anchor) != 1:
            print(f"Confira a integração de temas em {path}.")
            continue
        hook = f'\n{MARKER}\npython3 "${{XDG_DATA_HOME:-$HOME/.local/share}}/rice-ark/configurar-ark.py" --apply "$theme"\n'
        write(path, source.replace(anchor, anchor + hook, 1))

    # Substitua apenas a entrada local do Ark, conservando os tipos de arquivo e ações.
    desktop = DATA / "applications/org.kde.ark.desktop"
    desktop.parent.mkdir(parents=True, exist_ok=True)
    if desktop.exists():
        shutil.copy2(desktop, backup / "org.kde.ark.desktop")
    source = Path("/usr/share/applications/org.kde.ark.desktop").read_text()
    launcher = '"' + str(HELPER).replace("\\", "\\\\").replace('"', '\\"').replace("%", "%%") + '"'
    source, count = re.subn(r"(?m)^Exec=ark(?=\s|$)", "Exec=python3 " + launcher + " --launch", source)
    if count == 0:
        raise RuntimeError("A entrada desktop do Ark tem um formato diferente do esperado.")
    source = re.sub(r"(?m)^DBusActivatable=.*$", "DBusActivatable=false", source)
    write(desktop, source)
    subprocess.run(["update-desktop-database", str(desktop.parent)], check=False)
    print(f"Configurado. Backup em {backup}")
    print("Feche o Ark e abra novamente pelo Rofi ou pelo Thunar.")
    print("As cores Qt/KDE também podem afetar outros aplicativos do usuário.")


if __name__ == "__main__":
    if sys.argv[1:2] == ["--apply"]:
        apply_theme(sys.argv[2] if len(sys.argv) > 2 else None)
    elif sys.argv[1:2] == ["--launch"]:
        apply_theme()
        environment = os.environ.copy()
        environment["QT_QPA_PLATFORMTHEME"] = "qt6ct"
        environment.pop("QT_STYLE_OVERRIDE", None)
        os.execve("/usr/bin/ark", ["ark", *sys.argv[2:]], environment)
    elif sys.argv[1:] == ["--setup"]:
        install(packages=False)
    elif not sys.argv[1:]:
        install()
    else:
        sys.exit("Uso: python3 configurar-ark.py")
