#!/usr/bin/env python3
"""Aplica a paleta compartilhada aos componentes específicos da sessão Sway."""
import fcntl
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(os.environ["SWAY_SETUP_ROOT"]) if "SWAY_SETUP_ROOT" in os.environ else Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "sway"
THEMES = ("nord", "gruvbox", "catppuccin", "solitude")


def write(path, text):
    temporary = path.with_name(path.name + ".next")
    temporary.write_text(text)
    temporary.replace(path)


def apply(theme, live=True):
    if theme not in THEMES:
        raise ValueError("Tema desconhecido")
    lines = (ROOT / "themes" / theme).read_text().splitlines()
    base, text, accent = lines[0].split()
    ansi = lines[1].split() if len(lines) > 1 else []
    if not all(re.fullmatch(r"[0-9a-fA-F]{6}", c) for c in [base, text, accent, *ansi]):
        raise ValueError("Paleta inválida")
    if ansi and len(ansi) != 16:
        raise ValueError("A paleta ANSI precisa de 16 cores")
    css = f"@define-color base #{base};\n@define-color text #{text};\n@define-color accent #{accent};\n"
    write(ROOT / "waybar/colors.css", css)
    write(ROOT / "rofi/colors.rasi", f"* {{ base: #{base}; text: #{text}; accent: #{accent}; panel: #{base}d6; background-color: transparent; text-color: @text; }}\n")
    kitty = f"background #{base}\nforeground #{text}\nselection_background #{accent}\nselection_foreground #{base}\ncursor #{accent}\n"
    kitty += "".join(f"color{i} #{color}\n" for i, color in enumerate(ansi))
    write(ROOT / "kitty/colors.conf", kitty)
    write(ROOT / "config.d/colors.conf",
          f"client.focused #{accent} #{base} #{text} #{accent} #{accent}\n"
          f"client.unfocused #{base} #{base} #{text} #{base} #{base}\n"
          f"client.focused_inactive #{base} #{base} #{text} #{base} #{base}\n")
    write(ROOT / "current-theme", theme + "\n")
    if live:
        subprocess.run(["bash", str(ROOT / "scripts/gtk-theme.sh"), theme], check=True)
        subprocess.run(["swaymsg", "reload"], check=True)
        pid_file = Path(os.environ["XDG_RUNTIME_DIR"]) / f"rice-sway-{os.environ['WAYLAND_DISPLAY']}/waybar.pid"
        if pid_file.is_file():
            try:
                os.kill(int(pid_file.read_text()), __import__("signal").SIGUSR2)
            except ProcessLookupError:
                pass
        # Kitty recarrega sua configuração no próximo lançamento.
        subprocess.run(["notify-send", "Tema aplicado", "Abra uma nova janela do Kitty para carregar as cores."])


if __name__ == "__main__":
    theme = sys.argv[1] if len(sys.argv) > 1 else "menu"
    if theme == "menu":
        result = subprocess.run(["rofi", "-config", str(ROOT / "rofi/config.rasi"),
                                 "-dmenu", "-i", "-no-custom", "-p", "Tema"],
                                input="\n".join(THEMES), capture_output=True, text=True)
        if result.returncode:
            sys.exit(0)
        theme = result.stdout.strip()
    with (ROOT / ".theme.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        apply(theme, live="--offline" not in sys.argv)
