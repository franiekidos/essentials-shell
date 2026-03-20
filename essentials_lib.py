"""
essentials_lib.py – shared GTK3 base for Essentials shell components.

Rewritten from PyQt6 → GTK3/GLib to match the rest of the codebase.
Any component can subclass EssentialsBase instead of Gtk.Window directly
to get automatic config loading and a consistent stylesheet helper.
"""
import gi, json, os
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GtkLayerShell, Gdk

THEME_PATH  = os.path.expanduser("~/.config/essentials/themes.json")
CONFIG_PATH = os.path.expanduser("~/.config/essentials/config.json")

_FALLBACK_THEME = {
    "bg":     "rgba(30, 30, 46, 0.92)",
    "accent": "#cba6f7",
    "text":   "#cdd6f4",
    "radius": "12px",
    "font":   "JetBrainsMono Nerd Font",
}


def load_theme() -> dict:
    """Return the active theme dict from themes.json, or the built-in fallback."""
    try:
        with open(THEME_PATH, "r") as f:
            data    = json.load(f)
            current = data.get("current", "catppuccin")
            return data.get(current, _FALLBACK_THEME)
    except Exception:
        return _FALLBACK_THEME


def load_config() -> dict:
    """Return the general config dict from config.json."""
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except Exception:
        return {}


class EssentialsBase(Gtk.Window):
    """
    Thin base class for Essentials GTK3 overlay windows.

    Subclasses get:
      - self.theme  – active theme dict
      - self.config – general config dict
      - layer-shell boilerplate already applied (OVERLAY, keyboard ON_DEMAND)
      - apply_base_style() – injects a minimal consistent stylesheet
    """

    def __init__(self, obj_name: str = "essentials-window"):
        super().__init__()
        self.set_name(obj_name)

        self.theme  = load_theme()
        self.config = load_config()

        # Layer-shell setup common to all overlay windows
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        # Close on Escape by default
        self.connect("key-press-event", self._on_key)

    def _on_key(self, _w, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

    def apply_base_style(self, extra_css: str = ""):
        """
        Apply a stylesheet derived from the active theme.
        Pass additional CSS rules via *extra_css* to extend it per-component.
        """
        t   = self.theme
        css = Gtk.CssProvider()
        base = f"""
            window {{
                background:    {t['bg']};
                border:        1px solid {t['accent']};
                border-radius: {t['radius']};
            }}
            label, button, entry {{
                color:       {t['text']};
                font-family: '{t['font']}';
                font-size:   14px;
            }}
            button {{
                background:    transparent;
                border:        none;
                border-radius: 8px;
                padding:       6px 12px;
            }}
            button:hover {{
                background: rgba(255,255,255,0.08);
            }}
        """
        css.load_from_data((base + extra_css).encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
