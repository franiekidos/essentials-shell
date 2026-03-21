#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Essentials Shell — Launcher                                    ║
# ║                                                                  ║
# ║  Starts, stops, or restarts all shell components.               ║
# ║                                                                  ║
# ║  Usage:                                                          ║
# ║    ./launch.sh              — start everything                   ║
# ║    ./launch.sh stop         — stop everything                    ║
# ║    ./launch.sh restart      — restart everything                 ║
# ║    ./launch.sh status       — show what's running                ║
# ║    ./launch.sh --no-widgets — start without widgets              ║
# ║    ./launch.sh --no-wizard  — skip first-run wizard check        ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────
G='\033[0;32m' R='\033[0;31m' Y='\033[0;33m'
C='\033[0;36m' D='\033[2m'   RST='\033[0m' BLD='\033[1m'

ok()   { echo -e "${G}  ✓${RST}  $*"; }
fail() { echo -e "${R}  ✗${RST}  $*"; }
info() { echo -e "${C}  →${RST}  $*"; }
warn() { echo -e "${Y}  ⚠${RST}  $*"; }
dim()  { echo -e "${D}  ~${RST}  $*"; }

# ── Config ────────────────────────────────────────────────────────
BIN="$HOME/.local/bin"
CFG="$HOME/.config/essentials"
DONE_FLAG="$CFG/.wizard_done"
PY="python3"
PLUGIN_RUNNER="$BIN/essentials-plugin"

# Components and their process match strings
declare -A PROCS=(
    [bars]="essentials-bars"
    [widgets]="essentials-widgets"
)

# ── Argument parsing ──────────────────────────────────────────────
CMD="${1:-start}"
NO_WIDGETS=false
NO_WIZARD=false
for arg in "$@"; do
    case "$arg" in
        --no-widgets) NO_WIDGETS=true ;;
        --no-wizard)  NO_WIZARD=true ;;
    esac
done

# ── Helpers ───────────────────────────────────────────────────────
is_running() {
    pgrep -f "python3.*$1" > /dev/null 2>&1
}

kill_proc() {
    local name="$1"
    if pids=$(pgrep -f "python3.*$name" 2>/dev/null); then
        kill $pids 2>/dev/null && return 0
    fi
    return 1
}

wait_dead() {
    local name="$1" i=0
    while pgrep -f "python3.*$name" > /dev/null 2>&1; do
        sleep 0.1
        (( i++ > 20 )) && return 1
    done
    return 0
}

launch() {
    local name="$1" bin="$BIN/$1"
    if [[ ! -f "$bin" ]]; then
        fail "$name not found at $bin — run setup.sh first"
        return 1
    fi
    if is_running "$name"; then
        dim "$name already running"
        return 0
    fi
    $PY "$bin" > /tmp/essentials-${name##essentials-}.log 2>&1 &
    disown $!
    sleep 0.3
    if is_running "$name"; then
        ok "$name"
    else
        fail "$name failed to start — check /tmp/essentials-${name##essentials-}.log"
        return 1
    fi
}

detect_wm() {
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && echo "hyprland" && return
    [[ -n "${NIRI_SOCKET:-}" ]]                 && echo "niri" && return
    [[ -n "${SWAYSOCK:-}" ]]                    && echo "sway" && return
    echo "${XDG_CURRENT_DESKTOP:-generic}" | tr '[:upper:]' '[:lower:]'
}

run_plugins() {
    local event="$1" wm="$2"
    if [[ -x "$PLUGIN_RUNNER" ]]; then
        "$PY" "$PLUGIN_RUNNER" "$event" "$wm" >/tmp/essentials-plugins.log 2>&1 || true
        dim "Plugins: $event ($wm)"
    fi
}

# ── Read config ───────────────────────────────────────────────────
widgets_enabled() {
    $NO_WIDGETS && return 1
    "$PY" -c "
import json, os, sys
try:
    d = json.load(open(os.path.expanduser('$CFG/config.json')))
    sys.exit(0 if d.get('widgets',{}).get('enabled') else 1)
except: sys.exit(1)
" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════

case "$CMD" in

# ── start ─────────────────────────────────────────────────────────
start)
    echo -e "\n${BLD}${C}Essentials Shell${RST}\n"
    WM="$(detect_wm)"
    run_plugins "pre-start" "$WM"

    # First-run wizard
    if [[ ! -f "$DONE_FLAG" ]] && ! $NO_WIZARD; then
        info "First run detected — launching setup wizard"
        $PY "$BIN/essentials-wizard" &
        disown $!
        echo ""
        info "Complete the wizard to finish setup."
        info "The wizard will start the bar when done."
        exit 0
    fi

    # Restore wallpaper
    WALL=$("$PY" -c "
import json, os, sys
try:
    d = json.load(open(os.path.expanduser('$CFG/config.json')))
    w = d.get('wallpaper','')
    if w and os.path.exists(w): print(w)
except: pass
" 2>/dev/null || true)

    if [[ -n "$WALL" ]]; then
        for tool_cmd in \
            "swww img '$WALL' --transition-type fade" \
            "swaybg -i '$WALL' -m fill" \
            "feh --bg-fill '$WALL'" \
            "wbg '$WALL'"; do
            tool="${tool_cmd%% *}"
            if command -v "$tool" &>/dev/null; then
                eval "$tool_cmd" > /dev/null 2>&1 &
                disown $! 2>/dev/null || true
                dim "Wallpaper restored via $tool"
                break
            fi
        done
    fi

    # Bar
    launch essentials-bars

    # Widgets
    if widgets_enabled; then
        launch essentials-widgets
    else
        dim "Widgets disabled (use --no-widgets to suppress this, or enable in settings)"
    fi

    echo ""
    # Weather widget (background fetch / cache warmer)
    if python3 -c "import json,os; d=json.load(open(os.path.expanduser('$CFG/config.json'))); exit(0 if d.get('weather',{}).get('show_in_bar',False) else 1)" 2>/dev/null; then
        $PY "$BIN/essentials-weather" --fetch > /dev/null 2>&1 &
        disown $! 2>/dev/null || true
        dim "Weather cache primed"
    fi

    # Dock
    if python3 -c "import json,os; d=json.load(open(os.path.expanduser('$CFG/config.json'))); exit(0 if d.get('dock',{}).get('enabled',False) else 1)" 2>/dev/null; then
        launch essentials-dock
    fi

    # Idle daemon
    if python3 -c "import json,os; d=json.load(open(os.path.expanduser('$CFG/config.json'))); exit(0 if d.get('idle',{}).get('lock_after',0)>0 else 1)" 2>/dev/null; then
        launch essentials-idle
    fi
    run_plugins "post-start" "$WM"

    info "Shell running. Open the CC from the bar, or:"
    dim "  Settings:  $PY $BIN/essentials-settings"
    dim "  Stop:      $0 stop"
    echo ""
    ;;

# ── stop ──────────────────────────────────────────────────────────
stop)
    echo -e "\n${BLD}${C}Stopping Essentials Shell${RST}\n"
    WM="$(detect_wm)"
    run_plugins "pre-stop" "$WM"
    STOPPED=0
    for name in essentials-bars essentials-widgets essentials-cc \
                essentials-launcher essentials-powermenu essentials-wallpaper \
                essentials-settings essentials-wizard essentials-osd \
                essentials-dock essentials-idle essentials-clipboard; do
        if kill_proc "$name"; then
            wait_dead "$name"
            ok "$name"
            (( STOPPED++ ))
        fi
    done
    [[ "$STOPPED" -eq 0 ]] && dim "Nothing was running" || info "$STOPPED component(s) stopped"
    run_plugins "post-stop" "$WM"
    echo ""
    ;;

# ── restart ───────────────────────────────────────────────────────
restart)
    echo -e "\n${BLD}${C}Restarting Essentials Shell${RST}\n"
    # Stop quietly
    for name in essentials-bars essentials-widgets; do
        kill_proc "$name" 2>/dev/null || true
        wait_dead "$name" || true
    done
    sleep 0.3
    # Re-run start
    exec "$0" start "${@:2}"
    ;;

# ── status ────────────────────────────────────────────────────────
status)
    echo -e "\n${BLD}${C}Essentials Shell Status${RST}\n"
    WM="$(detect_wm)"

    declare -A ALL=(
        [essentials-bars]="Bar"
        [essentials-widgets]="Widgets"
        [essentials-dock]="Dock"
        [essentials-idle]="Idle Daemon"
        [essentials-cc]="Control Centre"
        [essentials-clipboard]="Clipboard"
        [essentials-settings]="Settings"
        [essentials-launcher]="Launcher"
        [essentials-powermenu]="Power Menu"
        [essentials-wallpaper]="Wallpaper Manager"
        [essentials-wizard]="Wizard"
    )

    RUNNING=0
    for proc in "${!ALL[@]}"; do
        label="${ALL[$proc]}"
        if is_running "$proc"; then
            pid=$(pgrep -f "python3.*$proc" | head -1)
            ok "$label  ${D}(pid $pid)${RST}"
            (( RUNNING++ ))
        else
            dim "$label  not running"
        fi
    done

    echo ""

    # Config summary
    echo -e "  ${BLD}Config${RST}"
    "$PY" << PYEOF
import json, os
cfg_path = os.path.expanduser("$CFG/config.json")
thm_path = os.path.expanduser("$CFG/themes.json")
try:
    cfg = json.load(open(cfg_path))
    print(f"    Bar style:  {cfg.get('bar_style','trilands')}  (autohide: {'on' if cfg.get('bar_autohide') else 'off'})")
    print(f"    Wallpaper:  {cfg.get('wallpaper','not set')}")
    w = cfg.get('widgets',{}).get('enabled',[])
    print(f"    Widgets:    {', '.join(w) if w else 'disabled'}")
except: print("    config.json not found")
try:
    thm = json.load(open(thm_path))
    print(f"    Theme:      {thm.get('current','?')}")
except: print("    themes.json not found")
PYEOF

    echo ""
    [[ "$RUNNING" -eq 0 ]] \
        && info "Shell is not running — start with: $0 start" \
        || info "$RUNNING component(s) running"
    run_plugins "status" "$WM"
    echo ""
    ;;

# ── help / unknown ────────────────────────────────────────────────
help|--help|-h)
    echo ""
    echo -e "  ${BLD}Usage:${RST} $0 <command> [options]"
    echo ""
    echo -e "  ${BLD}Commands:${RST}"
    echo "    start      Start bar and widgets (default)"
    echo "    stop       Stop all running components"
    echo "    restart    Stop then start"
    echo "    status     Show running components and config"
    echo "    help       Show this help"
    echo ""
    echo -e "  ${BLD}Options:${RST}"
    echo "    --no-widgets   Skip widgets even if configured"
    echo "    --no-wizard    Skip first-run wizard check"
    echo ""
    echo -e "  ${BLD}Logs:${RST}  /tmp/essentials-*.log"
    echo ""
    ;;

*)
    fail "Unknown command: $CMD"
    echo "  Run: $0 help"
    exit 1
    ;;
esac
