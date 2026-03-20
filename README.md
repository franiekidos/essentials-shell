<div align="center">

# 🪟 Essentials Shell

**A lightweight, compositor-agnostic Wayland desktop shell built with GTK3 + GtkLayerShell**

[![License: MIT](https://img.shields.io/badge/License-MIT-cba6f7.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10+-89b4fa.svg)](https://python.org)
[![GTK3](https://img.shields.io/badge/GTK-3-a6e3a1.svg)](https://gtk.org)
[![Wayland](https://img.shields.io/badge/Wayland-GtkLayerShell-f9e2af.svg)](https://wayland.freedesktop.org)

</div>

---

## ✨ Features

- 🪟 **Native support** for Hyprland, Niri, Sway, River, Labwc and MangoWC
- 🎨 **Extensive theming** — 5 built-in schemes + automatic colour generation from your wallpaper
- 🖼️ **Wallpaper manager** with Wallhaven integration and thumbnail browser
- 🔔 **Notification centre** with history and Do Not Disturb toggle
- 🖥️ **Multi-monitor support** with per-compositor IPC and `wlr-randr` fallback
- 🔒 **Lock screen** launcher (hyprlock / swaylock / waylock / gtklock)
- 🧩 **Desktop widgets** — clock, sysinfo, media player (rendered on wallpaper layer)
- 💡 **OSD** for volume and brightness (bind to media keys)
- 🎛️ **Bar layouts** — Trilands, Islands, Still, Floating, Blocks
- 🖱️ **Input settings** written to compositor config, applied live via IPC
- 🪄 **Setup wizard** for first-time configuration
- 🔌 **Plugin manager** for Hyprland (via `hyprpm`)

---

## 🖼️ Bar Styles

| Style | Description |
|-------|-------------|
| **Trilands** | Three separate floating pills *(default)* |
| **Islands** | Single compact centred pill — all sections merged |
| **Still** | Full-width flat bar flush to the screen edge |
| **Floating** | Full-width floating bar with side margins |
| **Blocks** | Three rectangular windows at the bottom of the screen |

---

## 🪟 Compositor Support

| | Hyprland | Niri | Sway | River | Labwc | MangoWC |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Bar | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Workspaces | ✅ | ✅ | ✅ | — | — | — |
| Monitor IPC | ✅ | ✅ | ✅ | wlr-randr | wlr-randr | wlr-randr |
| Input IPC | ✅ | — | ✅ | — | — | — |
| Keybind editor | ✅ | open file | ✅ | ✅ | open file | open file |
| Border theming | ✅ live | config | ✅ live | ✅ live | rc.xml | config |
| Plugin manager | hyprpm | — | — | — | — | — |

---

## 📦 Components

| File | Lines | Description |
|------|------:|-------------|
| `essentials-bars` | 536 | Bar (5 styles, widget factory, layout from config) |
| `essentials-cc` | 800 | Control Centre — stats, sliders, WiFi, BT, media, DND |
| `essentials-settings` | 1882 | Settings panel — 12 tabs |
| `essentials-launcher` | 177 | App launcher with icon grid and search |
| `essentials-powermenu` | 213 | Power OSD — shutdown, reboot, suspend, lock, logout |
| `essentials-osd` | 173 | Volume / brightness OSD (bind to media keys) |
| `essentials-wallpaper` | 560 | Wallpaper manager + Wallhaven search |
| `essentials-lockscreen` | 176 | Safe lock screen launcher |
| `essentials-widgets` | 234 | Desktop widgets (clock, sysinfo, media) |
| `essentials-wizard` | 413 | First-time setup wizard |
| `essentials-detect` | 282 | Compositor abstraction layer (importable module) |
| `essentials-config-writer` | 604 | Config file read/write for all compositors |
| `essentials-theme-apply` | 89 | Hot-reload bar + widgets + WM borders on theme change |
| `essentials_lib.py` | — | Shared GTK3 base class |
| `themes.json` | — | Theme definitions |

---

## 🚀 Installation

### Quick install (recommended)

```bash
git clone https://github.com/yourname/essentials-shell
cd essentials-shell
sh install.sh
```

### Arch Linux / AUR

```bash
git clone https://github.com/yourname/essentials-shell
cd essentials-shell
makepkg -si
```

### Manual

```bash
git clone https://github.com/yourname/essentials-shell
cd essentials-shell
chmod +x essentials-*
cp essentials-* essentials_lib.py ~/.local/bin/
mkdir -p ~/.config/essentials
cp themes.json ~/.config/essentials/
```

---

## ⚙️ Dependencies

### Required

```
python >= 3.10
python-gobject     (PyGObject / gi)
python-psutil
gtk3
gtk-layer-shell
```

### Optional (features degrade gracefully)

| Package | Feature |
|---------|---------|
| `playerctl` | Media controls in bar + CC |
| `wireplumber` / `pipewire-pulse` | Volume slider (`wpctl`) |
| `brightnessctl` | Brightness slider |
| `networkmanager` | WiFi toggle + network tab (`nmcli`) |
| `bluez-utils` | Bluetooth toggle (`bluetoothctl`) |
| `mako` or `dunst` | Notification history + DND |
| `swww` / `swaybg` / `hyprpaper` | Wallpaper setter |
| `swaylock` / `hyprlock` / `waylock` | Lock screen |
| `python-pillow` | Wallpaper → colour theme generation |
| `fontconfig` | Font picker (`fc-list`) |
| `xdg-utils` | Default apps (`xdg-mime`) |
| `wlr-randr` | Monitor control on River / Labwc / MangoWC |
| `hyprpm` | Hyprland plugin manager |

---

## 🎨 Theming

### Built-in themes

| Theme | Accent |
|-------|--------|
| Catppuccin Mocha | `#cba6f7` |
| Gruvbox | `#fabd2f` |
| Nord | `#88c0d0` |
| Dracula | `#bd93f9` |
| Rosé Pine | `#c4a7e7` |

### Custom theme

Add to `~/.config/essentials/themes.json`:

```json
{
    "current": "my-theme",
    "my-theme": {
        "bg":     "rgba(20, 20, 30, 0.92)",
        "accent": "#ff79c6",
        "text":   "#f8f8f2",
        "radius": "12px",
        "font":   "JetBrainsMono Nerd Font"
    }
}
```

Switch via **Settings → Appearance**. WM borders update live.

### Generate from wallpaper

**Settings → Wallpaper → Generate Theme** — extracts the dominant colour from your wallpaper using PIL, derives a full palette, saves as the `"wallpaper"` theme and switches to it immediately.

---

## 💡 OSD Key Bindings

Add to your compositor config after running the wizard (or manually):

**Hyprland** (`~/.config/hypr/hyprland.conf`):
```
bind = , XF86AudioRaiseVolume,  exec, essentials-osd volume up
bind = , XF86AudioLowerVolume,  exec, essentials-osd volume down
bind = , XF86AudioMute,         exec, essentials-osd volume mute
bind = , XF86MonBrightnessUp,   exec, essentials-osd bright up
bind = , XF86MonBrightnessDown, exec, essentials-osd bright down
bind = , XF86AudioPlay,         exec, playerctl play-pause
bind = , XF86AudioNext,         exec, playerctl next
bind = , XF86AudioPrev,         exec, playerctl previous
```

**Sway** (`~/.config/sway/config`):
```
bindsym XF86AudioRaiseVolume  exec essentials-osd volume up
bindsym XF86AudioLowerVolume  exec essentials-osd volume down
bindsym XF86AudioMute         exec essentials-osd volume mute
bindsym XF86MonBrightnessUp   exec essentials-osd bright up
bindsym XF86MonBrightnessDown exec essentials-osd bright down
```

---

## 🔒 Lock Screen

Essentials **never auto-generates** locker configs to avoid lockouts. Set up your locker first:

- **swaylock** — works out of the box if installed with PAM support
- **hyprlock** — create `~/.config/hypr/hyprlock.conf` with an `input-field` block first ([docs](https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/))
- **waylock** / **gtklock** — work out of the box

Check which locker would be used:
```bash
essentials-lockscreen --check
```

---

## 🧩 Desktop Widgets

Configure in `~/.config/essentials/config.json`:

```json
{
    "widgets": {
        "enabled": ["clock", "sysinfo", "media"],
        "clock":   {"corner": "top-left",     "margin": 48},
        "sysinfo": {"corner": "bottom-left",  "margin": 48},
        "media":   {"corner": "bottom-right", "margin": 48}
    }
}
```

Corners: `top-left` · `top-right` · `bottom-left` · `bottom-right` · `center`

Start widgets: `essentials-widgets &`

---

## 🛠️ Compositor Abstraction API

Every component imports `essentials-detect` via `importlib`:

```python
import importlib.util, os

spec = importlib.util.spec_from_file_location(
    "essentials_detect",
    os.path.expanduser("~/.local/bin/essentials-detect"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
WM = mod.detect()

WM.name                          # → "hyprland"
WM.get_active_workspace()        # → 2
WM.get_monitors()                # → [{name, width, height, modes, ...}]
WM.set_monitor("eDP-1", "1920x1080@60Hz", scale=1.0)
WM.get_input_devices()           # → [{name, type, accel, tap, ...}]
WM.set_input("device-id", "pointer_speed", 0.3)
WM.get_config_path()             # → "~/.config/hypr/hyprland.conf"
WM.reload_config()
WM.get_plugins()                 # Hyprland + hyprpm only
```

Run directly:
```bash
essentials-detect          # prints: hyprland
essentials-detect --json   # prints: {"name":"hyprland","config":"...","plugins":true}
```

---

## 📁 Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/essentials/config.json` | Bar layout, style, widgets, wallpaper, locker |
| `~/.config/essentials/themes.json` | Theme definitions |
| `~/.config/essentials/wallpapers/` | Downloaded wallpapers |
| `~/.cache/essentials/wallhaven/` | Wallhaven thumbnail cache |
| `~/.config/essentials/.wizard_done` | Wizard completion flag |

---

## 🤝 Contributing

Contributions welcome. Please open an issue before a large PR to discuss the approach.

```bash
git clone https://github.com/yourname/essentials-shell
cd essentials-shell
# make your changes
python3 -c "import ast; ast.parse(open('essentials-bars').read())"  # syntax check
make install  # test locally
```

---

## 📄 License

[MIT](LICENSE)
