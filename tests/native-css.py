"""Feed generated CSS and its imports to GTK3, without starting any panel."""
import ctypes
import ctypes.util
import sys

gtk = ctypes.CDLL(ctypes.util.find_library("gtk-3") or "libgtk-3.so.0")
gobject = ctypes.CDLL(ctypes.util.find_library("gobject-2.0") or "libgobject-2.0.so.0")


class GError(ctypes.Structure):
    _fields_ = [("domain", ctypes.c_uint), ("code", ctypes.c_int), ("message", ctypes.c_char_p)]


gtk.gtk_init_check.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
gtk.gtk_init_check(None, None)
gtk.gtk_css_provider_new.restype = ctypes.c_void_p
gtk.gtk_css_provider_load_from_path.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.POINTER(ctypes.POINTER(GError))]
gobject.g_object_unref.argtypes = [ctypes.c_void_p]
for path in sys.argv[1:]:
    provider = gtk.gtk_css_provider_new()
    error = ctypes.POINTER(GError)()
    ok = gtk.gtk_css_provider_load_from_path(provider, path.encode(), ctypes.byref(error))
    gobject.g_object_unref(provider)
    if not ok:
        raise SystemExit(f"CSS inválido em {path}: {error.contents.message.decode()}")
