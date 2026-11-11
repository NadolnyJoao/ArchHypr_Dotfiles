"""Valida Lua e as conexões entre os arquivos do rice sem iniciar o compositor."""
import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
library = None
for name in ("lua5.4", "lua-5.4", "lua", "liblua5.4.so.0"):
    path = ctypes.util.find_library(name) or name
    try:
        library = ctypes.CDLL(path)
        break
    except OSError:
        continue
if library is None:
    raise SystemExit("Instale Lua para validar os módulos: sudo pacman -S lua")

library.luaL_newstate.restype = ctypes.c_void_p
library.luaL_openlibs.argtypes = [ctypes.c_void_p]
library.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
library.lua_pcallk.argtypes = [
    ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int,
    ctypes.c_longlong, ctypes.c_void_p,
]
library.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
library.lua_tolstring.restype = ctypes.c_char_p
library.lua_close.argtypes = [ctypes.c_void_p]

# A API simulada verifica binds duplicados e executa de fato o arquivo principal.
prelude = """
local seen = {}
hl = {
    config = function(settings) end,
    gesture = function(settings) end,
    monitor = function(settings) end,
    layer_rule = function(settings) end,
    window_rule = function(settings) end,
    on = function(event, callback) end,
    bind = function(keys, dispatcher, flags)
        keys = string.lower(keys)
        assert(not seen[keys], "Atalho duplicado: " .. keys)
        seen[keys] = true
    end,
    dsp = {
        exec_cmd = function(command) return command end,
        focus = function(settings) return settings end,
        window = {
            close = function() end,
            float = function(settings) end,
            fullscreen = function(settings) end,
            move = function(settings) end,
            drag = function() end,
            resize = function() end,
        }
    }
}
"""
with tempfile.TemporaryDirectory() as temporary:
    os.environ["XDG_CONFIG_HOME"] = str(root / "dotfiles")
    for with_local in (False, True):
        script = prelude
        if with_local:
            # O dofile do main deve carregar o arquivo local depois do automático.
            script += """
local original_open = io.open
io.open = function(path, mode)
    if string.match(path, "monitors.local.lua$") then
        return { close = function() end }
    end
    return original_open(path, mode)
end
local original_dofile = dofile
dofile = function(path)
    if string.match(path, "monitors.local.lua$") then
        _G.monitor_local_loaded = true
        return
    end
    return original_dofile(path)
end
"""
        script += 'dofile(' + json.dumps(str(root / "dotfiles/hypr/hyprland.lua")) + ')\n'
        if with_local:
            script += 'assert(monitor_local_loaded, "Perfil local não foi carregado")\n'
        state = library.luaL_newstate()
        library.luaL_openlibs(state)
        result = library.luaL_loadstring(state, script.encode())
        if result == 0:
            result = library.lua_pcallk(state, 0, 0, 0, 0, None)
        error = library.lua_tolstring(state, -1, None) if result else None
        library.lua_close(state)
        assert result == 0, error

waybar = json.loads((root / "dotfiles/waybar/config.jsonc").read_text())
power = waybar["custom/power"]["on-click"]
assert '\\"' not in power
assert "NetworkManager" in waybar["network"]["on-click"]
assert waybar["clock"]["format"] == "{:%H:%M}"
subprocess.run(["bash", "-n", "-c", power], check=True)
assert "next" in (root / "dotfiles/hypr/modules/bindings.lua").read_text()
print("Lua carregado sem atalhos duplicados; perfil local e Waybar validados.")
