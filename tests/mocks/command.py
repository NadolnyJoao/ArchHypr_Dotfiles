#!/usr/bin/env python3
"""Comandos simulados para executar o instalador inteiro em uma pasta temporária."""
import json
import os
from pathlib import Path
import subprocess
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
home = Path(os.environ["HOME"])
state = home / "mock"
state.mkdir(exist_ok=True)


def fail(code=1):
    sys.exit(code)


def load():
    path = state / (name + ".json")
    return json.loads(path.read_text()) if path.exists() else {}


def save(values):
    (state / (name + ".json")).write_text(json.dumps(values))


def execute(command):
    sys.exit(subprocess.call(command))


if name == "sudo":
    if args in (["-v"], ["-n", "-v"]):
        fail(0)
    command = args[1:] if args[0] == "-n" else args
    if (os.environ.get("MOCK_FAIL_SDDM_PUBLISH") == "1" and command[0] == "mv"
            and Path(command[-2]).name.startswith(".rice-arch.")):
        fail()
    execute(command)
elif name == "pacman":
    packages = state / "packages"
    packages.mkdir(exist_ok=True)
    if args[0] == "-Q":
        package = args[-1]
        if not (packages / package).exists():
            fail()
        print(package, "0.57.1-1" if package == "hyprland" else "1.0-1")
    elif args[0] == "-S":
        package = args[-1]
        if os.environ.get("MOCK_FAIL_PACKAGE") == package:
            fail()
        (packages / package).touch()
    elif args[0] != "-Syu":
        fail()
elif name == "vercmp":
    print(1)
elif name == "git":
    if args[0] != "clone":
        execute(["/usr/bin/git", *args])
    url, destination = args[-2:]
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    if "Wallpapers_Pack" in url:
        (destination / "wallpapers").mkdir()
        (destination / "wallpapers/613342.jpg").write_text("imagem de teste")
    elif "Neovim-IDE" in url:
        (destination / "init.lua").write_text("-- fixture")
    elif "Nordic" in url:
        (destination / "gtk-3.0").mkdir()
        (destination / "gtk-3.0/gtk.css").write_text("/* fixture */")
    elif "sddm-astronaut" in url:
        (destination / "Themes").mkdir()
        (destination / "Fonts").mkdir()
        (destination / "Fonts/test.ttf").write_text("fixture")
        (destination / "Main.qml").write_text("// fixture")
        (destination / "metadata.desktop").write_text("ConfigFile=Themes/astronaut.conf\n")
        (destination / "Themes/japanese_aesthetic.conf").write_text(
            '[General]\nBackground="old.jpg"\nHeaderTextColor="#000000"\n'
        )
    else:
        fail()
    subprocess.run(["/usr/bin/git", "init", "-q", str(destination)], check=True)
    subprocess.run(["/usr/bin/git", "-C", str(destination), "remote", "add", "origin", url], check=True)
    subprocess.run(["/usr/bin/git", "-C", str(destination), "add", "."], check=True)
    subprocess.run([
        "/usr/bin/git", "-C", str(destination), "-c", "user.name=Teste",
        "-c", "user.email=teste@example.invalid", "commit", "-qm", "fixture"
    ], check=True)
elif name == "keyd":
    if args[0] not in ("check", "reload"):
        fail()
elif name == "systemctl":
    if "reboot" in args:
        fail(99)
    if args[0] == "is-enabled":
        fail(0 if (state / "sddm-enabled").exists() else 1)
    if args[:2] == ["enable", "sddm.service"]:
        (state / "sddm-enabled").touch()
elif name in ("gsettings", "xdg-settings", "xdg-mime", "xfconf-query", "flatpak"):
    values = load()
    if name == "gsettings":
        values[args[1] + "/" + args[2]] = args[3]
    elif name == "xdg-settings":
        if args[0] == "get":
            print(values.get(args[1], ""))
        elif args[0] == "check":
            print("yes" if values.get(args[1]) == args[2] else "no")
        else:
            values[args[1]] = args[2]
    elif name == "xdg-mime":
        if args[:2] == ["query", "default"]:
            print(values.get(args[2], ""))
        else:
            values[args[2]] = args[1]
    elif name == "xfconf-query":
        if "-s" in args:
            values["thumbnail"] = args[args.index("-s") + 1]
        elif "thumbnail" in values:
            print(values["thumbnail"])
        else:
            fail()
    elif name == "flatpak":
        if args[0] == "info":
            fail(0 if values.get("installed") else 1)
        if args[0] == "install":
            values["installed"] = True
    save(values)
elif name == "update-desktop-database":
    fail(0)
else:
    fail(98)
