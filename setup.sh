#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Essentials Shell — Full Setup Script                           ║
# ║                                                                  ║
# ║  Usage:                                                          ║
# ║    ./setup.sh              — interactive full setup              ║
# ║    ./setup.sh --unattended — skip all prompts, use defaults      ║
# ║    ./setup.sh --update     — update binaries only, skip config   ║
# ║    ./setup.sh --uninstall  — remove everything                   ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────
R='\033[0;31m' Y='\033[0;33m' G='\033[0;32m'
B='\033[0;34m' C='\033[0;36m' M='\033[0;35m'
W='\033[1;37m' D='\033[2m'    RST='\033[0m'
BLD='\033[1m'

ok()     { echo -e "${G}  ✓${RST}  $*"; }
info()   { echo -e "${B}  →${RST}  $*"; }
warn()   { echo -e "${Y}  ⚠${RST}  $*"; }
err()    { echo -e "${R}  ✗${RST}  $*"; }
skip()   { echo -e "${D}  ~${RST}  $*"; }
section(){ echo -e "\n${BLD}${C}▶  $*${RST}"; }
banner() {
    echo -e "${M}"
    echo '  ███████╗███████╗███████╗███████╗███╗   ██╗████████╗██╗ █████╗ ██╗      ███████╗'
    echo '  ██╔════╝██╔════╝██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║██╔══██╗██║      ██╔════╝'
    echo '  █████╗  ███████╗███████╗█████╗  ██╔██╗ ██║   ██║   ██║███████║██║      ███████╗'
    echo '  ██╔══╝  ╚════██║╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██╔══██║██║      ╚════██║'
    echo '  ███████╗███████║███████║███████╗██║ ╚████║   ██║   ██║██║  ██║███████╗ ███████║'
    echo '  ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝ ╚══════╝'
    echo -e "${RST}${D}                           Wayland Desktop Shell${RST}"
    echo ""
}

# ── Argument parsing ──────────────────────────────────────────────
UNATTENDED=false
UPDATE_ONLY=false
UNINSTALL=false
for arg in "$@"; do
    case "$arg" in
        --unattended) UNATTENDED=true ;;
        --update)     UPDATE_ONLY=true ;;
        --uninstall)  UNINSTALL=true ;;
        --help|-h)
            echo "Usage: $0 [--unattended|--update|--uninstall]"
            exit 0 ;;
    esac
done

# ── Paths ─────────────────────────────────────────────────────────
DEST_BIN="$HOME/.local/bin"
DEST_CFG="$HOME/.config/essentials"
CACHE_DIR="$HOME/.cache/essentials"
AUTOSTART_DIR="$HOME/.config/autostart"
DONE_FLAG="$DEST_CFG/.wizard_done"

BINS=(
    essentials-bars essentials-cc essentials-detect
    essentials-launcher essentials-powermenu essentials-settings
    essentials-theme-apply essentials-config-writer
    essentials-osd essentials-wallpaper essentials-lockscreen
    essentials-widgets essentials-wizard
    essentials-dock essentials-idle essentials-clipboard essentials-weather
)

# ── Helpers ───────────────────────────────────────────────────────
ask() {
    # ask <prompt> <default y|n>
    local prompt="$1" default="${2:-y}"
    $UNATTENDED && { [[ "$default" == "y" ]] && return 0 || return 1; }
    local yn
    [[ "$default" == "y" ]] && yn="[Y/n]" || yn="[y/N]"
    echo -en "${W}  ?${RST}  $prompt $yn: "
    read -r reply
    reply="${reply:-$default}"
    [[ "${reply,,}" == "y" ]]
}

detect_wm() {
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && echo "hyprland" && return
    [[ -n "${NIRI_SOCKET:-}" ]]                 && echo "niri"      && return
    [[ -n "${SWAYSOCK:-}" ]]                    && echo "sway"      && return
    local procs
    procs=$(ps -A -o comm= 2>/dev/null | tr '[:upper:]' '[:lower:]')
    for wm in river labwc mangowc wayfire hikari; do
        echo "$procs" | grep -q "^$wm$" && echo "$wm" && return
    done
    echo "${XDG_CURRENT_DESKTOP:-generic}" | tr '[:upper:]' '[:lower:]'
}

detect_pkg_manager() {
    for pm in pacman apt dnf zypper; do
        command -v "$pm" &>/dev/null && echo "$pm" && return
    done
    echo "unknown"
}

install_pkgs() {
    local pm="$1"; shift
    local pkgs=("$@")
    case "$pm" in
        pacman) sudo pacman -S --needed --noconfirm "${pkgs[@]}" ;;
        apt)    sudo apt-get install -y "${pkgs[@]}" ;;
        dnf)    sudo dnf install -y "${pkgs[@]}" ;;
        zypper) sudo zypper install -y "${pkgs[@]}" ;;
    esac
}

pkg_name() {
    # Map generic name → distro package name
    local pm="$1" pkg="$2"
    case "$pm:$pkg" in
        pacman:python-gobject)  echo "python-gobject" ;;
        apt:python-gobject)     echo "python3-gi" ;;
        dnf:python-gobject)     echo "python3-gobject" ;;
        pacman:python-psutil)   echo "python-psutil" ;;
        apt:python-psutil)      echo "python3-psutil" ;;
        dnf:python-psutil)      echo "python3-psutil" ;;
        pacman:gtk-layer-shell) echo "gtk-layer-shell" ;;
        apt:gtk-layer-shell)    echo "libgtk-layer-shell-dev" ;;
        dnf:gtk-layer-shell)    echo "gtk-layer-shell" ;;
        pacman:python-pillow)   echo "python-pillow" ;;
        apt:python-pillow)      echo "python3-pil" ;;
        dnf:python-pillow)      echo "python3-pillow" ;;
        *) echo "$pkg" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════
banner

# ── Uninstall ─────────────────────────────────────────────────────
if $UNINSTALL; then
    section "Uninstalling Essentials Shell"
    for b in "${BINS[@]}" essentials_lib.py; do
        rm -f "$DEST_BIN/$b" && ok "$b" || true
    done
    rm -f "$AUTOSTART_DIR/essentials-bars.desktop"
    warn "Config kept at $DEST_CFG — remove manually if desired"
    ok "Uninstalled"
    exit 0
fi

# ── Update only ───────────────────────────────────────────────────
if $UPDATE_ONLY; then
    section "Updating Essentials Shell binaries"
    [[ -f "essentials-bars" ]] || { err "Run from the essentials-shell directory"; exit 1; }
    mkdir -p "$DEST_BIN"
    for b in "${BINS[@]}"; do
        [[ -f "$b" ]] || { warn "$b not found — skipping"; continue; }
        install -m755 "$b" "$DEST_BIN/$b" && ok "$b"
    done
    install -m644 essentials_lib.py "$DEST_BIN/essentials_lib.py"
    ok "Update complete — restart the bar:"
    echo "    python3 $DEST_BIN/essentials-theme-apply"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════
# Full setup
section "Checking environment"

# Must run from repo directory
[[ -f "essentials-bars" ]] || {
    err "Run this script from the essentials-shell directory"
    exit 1
}

WM=$(detect_wm)
PM=$(detect_pkg_manager)
ok "Compositor: $WM"
ok "Package manager: $PM"

# ── Python version ────────────────────────────────────────────────
section "Python"
PY=$(command -v python3 2>/dev/null) || { err "python3 not found"; exit 1; }
PY_VER=$("$PY" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
MAJOR=${PY_VER%%.*}; MINOR=${PY_VER##*.}
if [[ "$MAJOR" -ge 3 && "$MINOR" -ge 10 ]]; then
    ok "Python $PY_VER"
else
    err "Python 3.10+ required (found $PY_VER)"
    exit 1
fi

# ── Required Python packages ──────────────────────────────────────
section "Required packages"
MISSING_REQ=()
for pkg in python-gobject python-psutil gtk-layer-shell; do
    if "$PY" -c "
import sys
p = '$pkg'
try:
    if 'gobject' in p: import gi
    elif 'psutil' in p: import psutil
    elif 'layer' in p:
        import ctypes
        ctypes.CDLL('libgtk-layer-shell.so.0')
    sys.exit(0)
except: sys.exit(1)
" 2>/dev/null; then
        ok "$pkg"
    else
        err "$pkg missing"
        MISSING_REQ+=("$pkg")
    fi
done

if [[ ${#MISSING_REQ[@]} -gt 0 ]]; then
    if [[ "$PM" != "unknown" ]] && ask "Install missing required packages?" y; then
        PKGS=()
        for p in "${MISSING_REQ[@]}"; do
            PKGS+=("$(pkg_name "$PM" "$p")")
        done
        install_pkgs "$PM" "${PKGS[@]}" && ok "Installed required packages"
    else
        err "Required packages missing — install them and re-run"
        exit 1
    fi
fi

# ── Optional packages ─────────────────────────────────────────────
section "Optional packages"
declare -A OPT_PKGS=(
    [playerctl]="Media controls in bar"
    [wpctl]="Volume control (wireplumber)"
    [brightnessctl]="Brightness control"
    [nmcli]="WiFi management"
    [bluetoothctl]="Bluetooth toggle"
    [swaylock]="Lock screen"
    [swww]="Animated wallpaper"
    [swaybg]="Simple wallpaper setter"
    [fc-list]="Font picker"
    [xdg-mime]="Default apps"
)
MISSING_OPT=()
for cmd in "${!OPT_PKGS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd — ${OPT_PKGS[$cmd]}"
    else
        skip "$cmd missing  (${OPT_PKGS[$cmd]})"
        MISSING_OPT+=("$cmd")
    fi
done

if [[ ${#MISSING_OPT[@]} -gt 0 && "$PM" != "unknown" ]]; then
    if ask "Install optional packages? (recommended)" y; then
        declare -A PM_NAMES_pacman=(
            [playerctl]=playerctl [wpctl]=wireplumber
            [brightnessctl]=brightnessctl [nmcli]=networkmanager
            [bluetoothctl]=bluez-utils [swaylock]=swaylock
            [swww]=swww [swaybg]=swaybg [fc-list]=fontconfig
            [xdg-mime]=xdg-utils
        )
        declare -A PM_NAMES_apt=(
            [playerctl]=playerctl [wpctl]=wireplumber
            [brightnessctl]=brightnessctl [nmcli]=network-manager
            [bluetoothctl]=bluez [swaylock]=swaylock
            [swww]=swww [swaybg]=swaybg [fc-list]=fontconfig
            [xdg-mime]=xdg-utils
        )
        INSTALL_PKGS=()
        for cmd in "${MISSING_OPT[@]}"; do
            case "$PM" in
                pacman) n="${PM_NAMES_pacman[$cmd]:-$cmd}" ;;
                apt)    n="${PM_NAMES_apt[$cmd]:-$cmd}" ;;
                *)      n="$cmd" ;;
            esac
            INSTALL_PKGS+=("$n")
        done
        install_pkgs "$PM" "${INSTALL_PKGS[@]}" 2>/dev/null && ok "Optional packages installed" \
            || warn "Some optional packages could not be installed — skipping"
    fi
fi

# ── Pillow (wallpaper theme gen) ──────────────────────────────────
if ! "$PY" -c "import PIL" 2>/dev/null; then
    if ask "Install Pillow? (needed for wallpaper → colour theme generation)" y; then
        case "$PM" in
            pacman) install_pkgs pacman python-pillow ;;
            apt)    install_pkgs apt    python3-pil ;;
            *)      "$PY" -m pip install pillow --break-system-packages 2>/dev/null \
                    || warn "Could not install Pillow — install manually: pip install pillow" ;;
        esac
        "$PY" -c "import PIL" 2>/dev/null && ok "Pillow installed" || warn "Pillow not found"
    fi
fi

# ── Install binaries ──────────────────────────────────────────────
section "Installing binaries → $DEST_BIN"
mkdir -p "$DEST_BIN" "$DEST_CFG" "$CACHE_DIR/wallhaven" \
          "$DEST_CFG/wallpapers"

for b in "${BINS[@]}"; do
    [[ -f "$b" ]] || { warn "$b not found in current directory — skipping"; continue; }
    install -m755 "$b" "$DEST_BIN/$b" && ok "$b"
done
install -m644 essentials_lib.py "$DEST_BIN/essentials_lib.py" && ok "essentials_lib.py"

# ── Config files ──────────────────────────────────────────────────
section "Configuration"
if [[ ! -f "$DEST_CFG/themes.json" ]]; then
    install -m644 themes.json "$DEST_CFG/themes.json" && ok "themes.json installed"
else
    skip "themes.json already exists (kept)"
fi

# ── PATH check ────────────────────────────────────────────────────
section "PATH"
if echo "$PATH" | grep -q "$DEST_BIN"; then
    ok "$DEST_BIN is in PATH"
else
    warn "$DEST_BIN is NOT in PATH"
    # Detect shell and suggest fix
    SHELL_RC=""
    case "${SHELL##*/}" in
        bash)  SHELL_RC="$HOME/.bashrc" ;;
        zsh)   SHELL_RC="$HOME/.zshrc" ;;
        fish)  SHELL_RC="$HOME/.config/fish/config.fish" ;;
        *)     SHELL_RC="$HOME/.profile" ;;
    esac
    if ask "Add $DEST_BIN to PATH in $SHELL_RC?" y; then
        if [[ "${SHELL##*/}" == "fish" ]]; then
            echo "fish_add_path $DEST_BIN" >> "$SHELL_RC"
        else
            echo "" >> "$SHELL_RC"
            echo "# Essentials Shell" >> "$SHELL_RC"
            echo "export PATH=\"$DEST_BIN:\$PATH\"" >> "$SHELL_RC"
        fi
        ok "Added to $SHELL_RC — restart your shell or run: source $SHELL_RC"
    else
        info "Add manually: export PATH=\"$DEST_BIN:\$PATH\""
    fi
fi

# ── Autostart ─────────────────────────────────────────────────────
section "Autostart ($WM)"
_write_autostart() {
    local conf="$1" line="$2" comment="$3"
    if [[ -f "$conf" ]]; then
        if grep -q "essentials-bars" "$conf"; then
            skip "Autostart already in $conf"
        else
            printf "\n%s\n%s\n" "$comment" "$line" >> "$conf"
            ok "Added autostart to $conf"
        fi
    else
        warn "$conf not found — add manually: $line"
    fi
}

case "$WM" in
    hyprland)
        _write_autostart \
            "$HOME/.config/hypr/hyprland.conf" \
            "exec-once = $DEST_BIN/essentials-bars" \
            "# Essentials Shell" ;;
    niri)
        _write_autostart \
            "$HOME/.config/niri/config.kdl" \
            "spawn-at-startup \"$DEST_BIN/essentials-bars\"" \
            "// Essentials Shell" ;;
    sway)
        _write_autostart \
            "$HOME/.config/sway/config" \
            "exec $DEST_BIN/essentials-bars" \
            "# Essentials Shell" ;;
    river)
        _write_autostart \
            "$HOME/.config/river/init" \
            "$DEST_BIN/essentials-bars &" \
            "# Essentials Shell" ;;
    *)
        mkdir -p "$AUTOSTART_DIR"
        DESKTOP_FILE="$AUTOSTART_DIR/essentials-bars.desktop"
        if [[ ! -f "$DESKTOP_FILE" ]]; then
            cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Essentials Bar
Exec=$DEST_BIN/essentials-bars
X-GNOME-Autostart-enabled=true
EOF
            ok "XDG autostart entry created"
        else
            skip "XDG autostart already exists"
        fi ;;
esac

# ── OSD keybinds ──────────────────────────────────────────────────
section "OSD media key bindings"
_osd="$DEST_BIN/essentials-osd"

_hypr_binds() {
    cat << EOF

# Essentials OSD — media keys
bind = , XF86AudioRaiseVolume,  exec, $_osd volume up
bind = , XF86AudioLowerVolume,  exec, $_osd volume down
bind = , XF86AudioMute,         exec, $_osd volume mute
bind = , XF86MonBrightnessUp,   exec, $_osd bright up
bind = , XF86MonBrightnessDown, exec, $_osd bright down
bind = , XF86AudioPlay,         exec, playerctl play-pause
bind = , XF86AudioNext,         exec, playerctl next
bind = , XF86AudioPrev,         exec, playerctl previous
EOF
}

_sway_binds() {
    cat << EOF

# Essentials OSD — media keys
bindsym XF86AudioRaiseVolume  exec $_osd volume up
bindsym XF86AudioLowerVolume  exec $_osd volume down
bindsym XF86AudioMute         exec $_osd volume mute
bindsym XF86MonBrightnessUp   exec $_osd bright up
bindsym XF86MonBrightnessDown exec $_osd bright down
bindsym XF86AudioPlay  exec playerctl play-pause
bindsym XF86AudioNext  exec playerctl next
bindsym XF86AudioPrev  exec playerctl previous
EOF
}

_river_binds() {
    cat << EOF

# Essentials OSD — media keys
riverctl map normal None XF86AudioRaiseVolume  spawn "$_osd volume up"
riverctl map normal None XF86AudioLowerVolume  spawn "$_osd volume down"
riverctl map normal None XF86AudioMute         spawn "$_osd volume mute"
riverctl map normal None XF86MonBrightnessUp   spawn "$_osd bright up"
riverctl map normal None XF86MonBrightnessDown spawn "$_osd bright down"
EOF
}

_write_binds() {
    local conf="$1" binds="$2"
    if [[ -f "$conf" ]]; then
        if grep -q "essentials-osd" "$conf"; then
            skip "OSD binds already in $conf"
        else
            echo "$binds" >> "$conf"
            ok "OSD binds written to $conf"
        fi
    else
        warn "$conf not found — add OSD binds manually"
    fi
}

case "$WM" in
    hyprland)
        CONF="$HOME/.config/hypr/hyprland.conf"
        if ask "Write OSD media key binds to $CONF?" y; then
            _write_binds "$CONF" "$(_hypr_binds)"
        fi ;;
    sway)
        CONF="$HOME/.config/sway/config"
        if ask "Write OSD media key binds to $CONF?" y; then
            _write_binds "$CONF" "$(_sway_binds)"
        fi ;;
    river)
        CONF="$HOME/.config/river/init"
        if ask "Write OSD media key binds to $CONF?" y; then
            _write_binds "$CONF" "$(_river_binds)"
        fi ;;
    *)
        info "Add OSD binds manually — see README.md for your compositor" ;;
esac

# ── Lock screen ───────────────────────────────────────────────────
section "Lock screen"
LOCKER=""
for l in hyprlock swaylock waylock gtklock; do
    command -v "$l" &>/dev/null && LOCKER="$l" && break
done

if [[ -n "$LOCKER" ]]; then
    ok "Detected locker: $LOCKER"
    if [[ "$LOCKER" == "hyprlock" ]]; then
        HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
        if [[ ! -f "$HYPRLOCK_CONF" ]]; then
            warn "hyprlock.conf not found — essentials-lockscreen requires you to create it"
            info "See: https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/"
            info "Run: essentials-lockscreen --check   to verify setup"
        else
            if grep -q "input-field\|input_field" "$HYPRLOCK_CONF"; then
                ok "hyprlock.conf has input-field — safe to use"
            else
                warn "hyprlock.conf has no input-field block"
                warn "You will not be able to type your password when locked!"
                info "Add an input-field section to $HYPRLOCK_CONF"
            fi
        fi
    fi
else
    warn "No locker found — install swaylock, hyprlock, waylock, or gtklock"
    info "essentials-lockscreen will fall back to 'loginctl lock-session'"
fi

# ── Theme ─────────────────────────────────────────────────────────
section "Theme"
THEMES=(catppuccin gruvbox nord dracula rose-pine)
echo ""
for i in "${!THEMES[@]}"; do
    echo -e "    ${W}$((i+1))${RST}  ${THEMES[$i]}"
done
echo ""

CHOSEN_THEME="catppuccin"
if ! $UNATTENDED; then
    echo -en "${W}  ?${RST}  Choose a theme [1-${#THEMES[@]}] (default: 1): "
    read -r THEME_CHOICE
    THEME_IDX=$(( ${THEME_CHOICE:-1} - 1 ))
    if [[ "$THEME_IDX" -ge 0 && "$THEME_IDX" -lt "${#THEMES[@]}" ]]; then
        CHOSEN_THEME="${THEMES[$THEME_IDX]}"
    fi
fi

# Write current theme to themes.json
"$PY" << PYEOF
import json, os
path = os.path.expanduser("$DEST_CFG/themes.json")
try:
    with open(path) as f: data = json.load(f)
except:
    data = {}
data["current"] = "$CHOSEN_THEME"
with open(path,"w") as f: json.dump(data, f, indent=4)
print(f"  Theme set to: $CHOSEN_THEME")
PYEOF
ok "Theme: $CHOSEN_THEME"

# ── Bar style ─────────────────────────────────────────────────────
section "Bar style"
STYLES=(trilands islands still floating blocks)
STYLE_DESC=(
    "Three floating pills (default)"
    "Single compact centred pill"
    "Classic full-width flat bar"
    "Full-width floating with margins"
    "Rectangular blocks at the bottom"
)
echo ""
for i in "${!STYLES[@]}"; do
    echo -e "    ${W}$((i+1))${RST}  ${STYLES[$i]}  ${D}— ${STYLE_DESC[$i]}${RST}"
done
echo ""

CHOSEN_STYLE="trilands"
if ! $UNATTENDED; then
    echo -en "${W}  ?${RST}  Choose a bar style [1-${#STYLES[@]}] (default: 1): "
    read -r STYLE_CHOICE
    STYLE_IDX=$(( ${STYLE_CHOICE:-1} - 1 ))
    if [[ "$STYLE_IDX" -ge 0 && "$STYLE_IDX" -lt "${#STYLES[@]}" ]]; then
        CHOSEN_STYLE="${STYLES[$STYLE_IDX]}"
    fi
fi

"$PY" << PYEOF
import json, os
path = os.path.expanduser("$DEST_CFG/config.json")
try:
    with open(path) as f: data = json.load(f)
except:
    data = {}
data["bar_style"] = "$CHOSEN_STYLE"
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path,"w") as f: json.dump(data, f, indent=4)
PYEOF
ok "Bar style: $CHOSEN_STYLE"

# Auto-hide
if ask "Enable bar auto-hide? (slides offscreen when not hovered)" n; then
    "$PY" << PYEOF
import json, os
path = os.path.expanduser("$DEST_CFG/config.json")
try:
    with open(path) as f: data = json.load(f)
except: data = {}
data["bar_autohide"] = True
with open(path,"w") as f: json.dump(data, f, indent=4)
PYEOF
    ok "Auto-hide enabled"
fi

# ── Widgets ───────────────────────────────────────────────────────
section "Desktop widgets"
echo ""
echo -e "    Available: clock (top-left), sysinfo (bottom-left), media (bottom-right)"
echo ""

ENABLE_WIDGETS=false
if ask "Enable desktop widgets?" n; then
    ENABLE_WIDGETS=true
    WIDGET_LIST='["clock","sysinfo","media"]'
    if ! $UNATTENDED; then
        echo -en "${W}  ?${RST}  Which widgets? (c=clock, s=sysinfo, m=media, a=all) [a]: "
        read -r WC
        case "${WC:-a}" in
            c)  WIDGET_LIST='["clock"]' ;;
            s)  WIDGET_LIST='["sysinfo"]' ;;
            m)  WIDGET_LIST='["media"]' ;;
            cs) WIDGET_LIST='["clock","sysinfo"]' ;;
            cm) WIDGET_LIST='["clock","media"]' ;;
            sm) WIDGET_LIST='["sysinfo","media"]' ;;
            *)  WIDGET_LIST='["clock","sysinfo","media"]' ;;
        esac
    fi
    "$PY" << PYEOF
import json, os
path = os.path.expanduser("$DEST_CFG/config.json")
try:
    with open(path) as f: data = json.load(f)
except:
    data = {}
data.setdefault("widgets", {})["enabled"] = $WIDGET_LIST
with open(path,"w") as f: json.dump(data, f, indent=4)
PYEOF
    ok "Widgets enabled: $WIDGET_LIST"
fi

# ── Mark wizard done ──────────────────────────────────────────────
touch "$DONE_FLAG"

# ══════════════════════════════════════════════════════════════════
# Summary
echo ""
echo -e "${BLD}${G}╔══════════════════════════════════════════╗${RST}"
echo -e "${BLD}${G}║   Essentials Shell setup complete! 🎉   ║${RST}"
echo -e "${BLD}${G}╚══════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${W}Compositor${RST}  $WM"
echo -e "  ${W}Theme     ${RST}  $CHOSEN_THEME"
echo -e "  ${W}Bar style ${RST}  $CHOSEN_STYLE"
echo -e "  ${W}Widgets   ${RST}  $($ENABLE_WIDGETS && echo "enabled" || echo "disabled")"
echo -e "  ${W}Locker    ${RST}  ${LOCKER:-loginctl fallback}"
echo ""
echo -e "  ${C}Start the shell now:${RST}"
echo -e "    python3 $DEST_BIN/essentials-bars &"
$ENABLE_WIDGETS && echo -e "    python3 $DEST_BIN/essentials-widgets &"
echo ""
echo -e "  ${C}Or log out and back in — autostart is configured.${RST}"
echo ""
echo -e "  ${D}Settings:  python3 $DEST_BIN/essentials-settings${RST}"
echo -e "  ${D}Uninstall: $0 --uninstall${RST}"
echo ""
