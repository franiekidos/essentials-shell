#!/usr/bin/env python3
"""
essentials_lib.py — Shared foundation for all Essentials Shell components.

Every component imports from here to guarantee consistent:
  - Config loading  (CFG, THEME_PATH, CONFIG_PATH)
  - Theme loading   (T — active theme dict)
  - Subprocess helper (_run, _run_ok, _popen)
  - Component launching (launch_component)
  - GTK base class  (EssentialsBase)
"""
import gi, json, os, subprocess, importlib.util

# ── Paths ─────────────────────────────────────────────────────────────────────
THEME_PATH  = os.path.expanduser("~/.config/essentials/themes.json")
CONFIG_PATH = os.path.expanduser("~/.config/essentials/config.json")
BIN         = os.path.expanduser("~/.local/bin")

# ── Config & theme loaders ────────────────────────────────────────────────────
def load_config() -> dict:
    try:
        with open(CONFIG_PATH) as f:
            return json.load(f)
    except Exception:
        return {}

def save_config(data: dict) -> None:
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(data, f, indent=4)

def update_config(updates: dict) -> None:
    data = load_config()
    data.update(updates)
    save_config(data)

def load_theme() -> dict:
    try:
        data    = json.load(open(THEME_PATH))
        current = data.get("current", "catppuccin")
        return data.get(current, data.get("catppuccin", {}))
    except Exception:
        return {
            "bg":     "rgba(17,17,27,0.92)",
            "accent": "#cba6f7",
            "text":   "#cdd6f4",
            "radius": "12px",
            "font":   "JetBrainsMono Nerd Font",
        }

def load_themes() -> dict:
    try:
        return json.load(open(THEME_PATH))
    except Exception:
        return {"current": "catppuccin"}

def save_themes(data: dict) -> None:
    os.makedirs(os.path.dirname(THEME_PATH), exist_ok=True)
    with open(THEME_PATH, "w") as f:
        json.dump(data, f, indent=4)

# ── Subprocess helpers ────────────────────────────────────────────────────────
def _run(*cmd, fallback: str = "") -> str:
    """Run a command, return stdout as str, return fallback on any error."""
    try:
        return subprocess.check_output(
            list(cmd), text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return fallback

def _run_ok(*cmd) -> bool:
    """Run a command, return True if exit code is 0."""
    try:
        return subprocess.run(
            list(cmd), stderr=subprocess.DEVNULL).returncode == 0
    except Exception:
        return False

def _popen(*cmd) -> None:
    """Fire-and-forget Popen, logging errors to stderr."""
    try:
        subprocess.Popen(list(cmd), stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"[essentials] launch failed {cmd[0]}: {e}")

# ── Component launcher ────────────────────────────────────────────────────────
def launch(component: str, *args) -> None:
    """Launch an Essentials component by short name (e.g. 'cc', 'settings')."""
    path = os.path.join(BIN, f"essentials-{component}")
    if os.path.exists(path):
        _popen("python3", path, *args)
    else:
        print(f"[essentials] component not found: {path}")

def is_running(component: str) -> bool:
    """Return True if the named component process is running."""
    try:
        subprocess.check_output(
            ["pgrep", "-f", f"essentials-{component}"],
            stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def kill_component(component: str) -> bool:
    """Send SIGTERM to all instances of a component. Returns True if any killed."""
    try:
        pids = subprocess.check_output(
            ["pgrep", "-f", f"essentials-{component}"],
            text=True, stderr=subprocess.DEVNULL).split()
        for pid in pids:
            os.kill(int(pid), 15)  # SIGTERM
        return bool(pids)
    except Exception:
        return False

# ── Compositor loader ─────────────────────────────────────────────────────────
def load_wm():
    """Load and return the Compositor abstraction object from essentials-detect."""
    path = os.path.join(BIN, "essentials-detect")
    if os.path.exists(path):
        try:
            loader = importlib.machinery.SourceFileLoader("essentials_detect", path)
            spec   = importlib.util.spec_from_loader("essentials_detect", loader)
            mod    = importlib.util.module_from_spec(spec)
            loader.exec_module(mod)
            return mod.detect()
        except Exception as e:
            print(f"[essentials] detect failed: {e}")

    class _Fallback:
        name = "generic"
        def get_active_workspace(self): return 1
        def get_workspace_count(self):  return 4
        def get_monitors(self):         return []
        def get_input_devices(self):    return []
        def get_config_path(self):      return None
        def reload_config(self):        return False
        def supports_plugins(self):     return False

    return _Fallback()

# ── CSS helpers ───────────────────────────────────────────────────────────────
def apply_css(css_string: str, priority: int = 600) -> object:
    """Load CSS and apply it screen-wide. Returns the provider."""
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk
    provider = Gtk.CssProvider()
    provider.load_from_data(css_string.encode() if isinstance(css_string, str) else css_string)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, priority)
    return provider

def remove_css(provider: object) -> None:
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk
    Gtk.StyleContext.remove_provider_for_screen(Gdk.Screen.get_default(), provider)

# ── Layer-shell window base ───────────────────────────────────────────────────
def _gtk_imports():
    gi.require_version("Gtk",           "3.0")
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import Gtk, GtkLayerShell, Gdk
    return Gtk, GtkLayerShell, Gdk

class EssentialsBase:
    """Lazy base — subclass and call _init_window() inside your __init__."""
    # Note: actual Gtk.Window subclassing still done in each component directly
    # This class provides the shared setup helpers.
    """
    Base class for all Essentials layer-shell windows.
    Subclass and call super().__init__() to get:
      - GtkLayerShell initialisation
      - self.T   — active theme dict
      - self.CFG — config dict
      - self.WM  — compositor abstraction
      - Escape key closes window
    """
    def _init_window(self, layer_str="OVERLAY", keyboard_str="ON_DEMAND"):
        Gtk, GtkLayerShell, Gdk = _gtk_imports()
        self.T   = load_theme()
        self.CFG = load_config()
        self.WM  = load_wm()
        self._css_providers = []
        layer    = getattr(GtkLayerShell.Layer,    layer_str)
        keyboard = getattr(GtkLayerShell.KeyboardMode, keyboard_str)
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, layer)
        GtkLayerShell.set_keyboard_mode(self, keyboard)
        self.connect("key-press-event",
                     lambda w, e: (self.destroy(), Gtk.main_quit())
                     if e.keyval == Gdk.KEY_Escape else None)

    def apply_style(self, css_string: str) -> object:
        """Apply CSS, removing any previously applied style from this window."""
        for p in self._css_providers:
            remove_css(p)
        self._css_providers.clear()
        provider = apply_css(css_string)
        self._css_providers.append(provider)
        return provider
