#!/usr/bin/env python3
"""Fundo preto por padrão. Menu e fila por tema com avanço e retrocesso."""
import fcntl
import json
import os
from pathlib import Path
import random
import subprocess
import sys
import time

ROOT = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "sway"
PACK = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "rice-arch/Wallpapers_Pack/wallpapers"
RUNTIME = Path(os.environ["XDG_RUNTIME_DIR"]) / f"rice-sway-{os.environ['WAYLAND_DISPLAY']}"
RUNTIME.mkdir(mode=0o700, exist_ok=True)
STATE = RUNTIME / "wallpapers.json"


def command(text):
    responses = json.loads(subprocess.check_output(["swaymsg", "-r", text]))
    if not all(item.get("success") for item in responses):
        raise RuntimeError(str(responses))


def theme_and_images():
    theme = (ROOT / "current-theme").read_text().strip()
    if theme not in ("nord", "gruvbox", "catppuccin", "solitude"):
        raise ValueError("Tema inválido")
    folder = PACK / theme
    images = sorted(str(p) for p in folder.glob("*") if p.is_file() and p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp"))
    return theme, images


def change(action, selected=None, selected_theme=None):
    with (RUNTIME / "wallpapers.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(STATE.read_text()) if STATE.exists() else {"enabled": False, "themes": {}}
        if action == "--disable":
            command("output * bg #000000 solid_color")
            state["enabled"] = False
        else:
            if action == "auto" and not state["enabled"]:
                return
            theme, images = theme_and_images()
            if selected_theme is not None and selected_theme != theme:
                raise ValueError("O tema mudou enquanto o menu estava aberto")
            if not images:
                subprocess.run(["notify-send", "Wallpapers", f"Nenhuma imagem em {PACK / theme}"])
                return
            queue = state["themes"].get(theme, {"order": [], "current": None})
            order = [p for p in queue["order"] if p in images]
            fresh = [p for p in images if p not in order]
            random.shuffle(fresh)
            order.extend(fresh)
            current = order.index(queue["current"]) if queue["current"] in order else -1
            if selected is not None:
                index = order.index(selected)
            elif action == "--enable":
                index = max(0, current)
            elif action == "prev":
                index = (max(0, current) - 1) % len(order)
            else:
                index = (current + 1) % len(order)
            # Um caminho enviado por IPC é escapado como string JSON.
            command(f"output * bg {json.dumps(order[index])} fill")
            state["themes"][theme] = {"order": order, "current": order[index]}
            state["enabled"] = True
        temporary = STATE.with_suffix(".next")
        temporary.write_text(json.dumps(state))
        temporary.replace(STATE)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "menu"
    if action == "menu":
        theme, images = theme_and_images()
        if not images:
            subprocess.run(["notify-send", "Wallpapers", f"Nenhuma imagem em {PACK / theme}"])
            return
        rows = []
        for path in images:
            label = "".join(" " if ord(c) < 32 else c for c in Path(path).name)
            icon = f"\0icon\x1f{path}" if "\n" not in path and "\x1f" not in path else ""
            rows.append(label + icon + "\n")
        result = subprocess.run(["rofi", "-config", str(ROOT / "rofi/config.rasi"), "-dmenu",
                                 "-i", "-no-custom", "-show-icons", "-format", "i", "-p", "Wallpaper",
                                 "-theme-str", "element-icon { size: 96px; } listview { lines: 5; }"],
                                input="".join(rows), capture_output=True, text=True)
        if result.returncode:
            return
        change("select", images[int(result.stdout.strip())], theme)
    elif action == "loop":
        with (RUNTIME / "rotation.lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return
            while True:
                time.sleep(3600)
                try:
                    change("auto")
                except subprocess.CalledProcessError:
                    return
    elif action in ("next", "prev", "--enable", "--disable"):
        change(action)
    else:
        sys.exit("Uso: wallpaper.py [menu|next|prev|--enable|--disable|loop]")


if __name__ == "__main__":
    main()
