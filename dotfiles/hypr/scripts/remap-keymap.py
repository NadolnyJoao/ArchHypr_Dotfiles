"""Replace right Control in a serialized XKB keymap from the current session."""
import re
import sys

keymap = sys.stdin.read()
keymap, count = re.subn(
    r"(?ms)^([ \t]*)key\s+<RCTL>\s*\{[^{}]*\};",
    r'\1key <RCTL> { type = "TWO_LEVEL", symbols[Group1] = [ slash, question ] };',
    keymap,
)
if count != 1:
    sys.exit("O mapa atual não contém uma definição única para <RCTL>.")


def without_right_ctrl(match):
    keys = [key.strip() for key in match[2].split(",") if key.strip() != "<RCTL>"]
    return f"{match[1]}{{ {', '.join(keys)} }};" if keys else ""


keymap = re.sub(r"(modifier_map\s+\w+\s*)\{([^{}]*)\};", without_right_ctrl, keymap)
sys.stdout.write(keymap)
