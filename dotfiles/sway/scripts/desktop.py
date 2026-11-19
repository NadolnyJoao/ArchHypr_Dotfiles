#!/usr/bin/env python3
"""Navegação numérica pelos workspaces, inclusive os vazios."""
import json
import subprocess
import sys

if sys.argv[1:] not in (["workspace", "next"], ["workspace", "prev"]):
    sys.exit(2)
workspaces = json.loads(subprocess.check_output(["swaymsg", "-t", "get_workspaces"]))
focused = next(ws for ws in workspaces if ws["focused"])
number = focused["num"] if focused["num"] > 0 else 1
number = max(1, number + (1 if sys.argv[-1] == "next" else -1))
subprocess.run(["swaymsg", f"workspace number {number}"], check=True)
