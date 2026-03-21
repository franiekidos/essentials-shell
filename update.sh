#!/usr/bin/env bash
# essentials-shell update — copies files to ~/.local/bin, no sudo needed
set -euo pipefail

G='\033[0;32m' R='\033[0;31m' C='\033[0;36m' Y='\033[0;33m' RST='\033[0m'
ok()   { echo -e "${G}  ✓${RST}  $*"; }
fail() { echo -e "${R}  ✗${RST}  $*"; }
info() { echo -e "${C}  →${RST}  $*"; }
warn() { echo -e "${Y}  ⚠${RST}  $*"; }

DEST="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BINS=(
    essentials-bars
    essentials-cc
    essentials-detect
    essentials-launcher
    essentials-powermenu
    essentials-settings
    essentials-theme-apply
    essentials-config-writer
    essentials-osd
    essentials-wallpaper
    essentials-lockscreen
    essentials-widgets
    essentials-wizard
    essentials-dock
    essentials-idle
    essentials-clipboard
    essentials-weather
)

# ── Check for root-owned files (the usual culprit) ────────────────────────────
BAD=()
for b in "${BINS[@]}" essentials_lib.py; do
    f="$DEST/$b"
    [[ -f "$f" ]] || continue
    owner=$(stat -c '%U' "$f" 2>/dev/null || stat -f '%Su' "$f" 2>/dev/null)
    [[ "$owner" != "$USER" ]] && BAD+=("$f (owned by $owner)")
done

if [[ ${#BAD[@]} -gt 0 ]]; then
    warn "These files are not owned by you — fixing with sudo chown:"
    for f in "${BAD[@]}"; do echo "    $f"; done
    sudo chown "$USER":"$USER" "${BAD[@]%%\ *}"
    ok "Ownership fixed"
fi

# ── Ensure dest dir exists and is owned by us ─────────────────────────────────
if [[ ! -d "$DEST" ]]; then
    mkdir -p "$DEST"
    ok "Created $DEST"
elif [[ "$(stat -c '%U' "$DEST" 2>/dev/null || stat -f '%Su' "$DEST")" != "$USER" ]]; then
    warn "$DEST owned by root — fixing"
    sudo chown "$USER":"$USER" "$DEST"
    ok "Fixed $DEST ownership"
fi

# ── Copy files ────────────────────────────────────────────────────────────────
info "Installing to $DEST ..."

for b in "${BINS[@]}"; do
    src="$SCRIPT_DIR/$b"
    if [[ -f "$src" ]]; then
        cp "$src" "$DEST/$b"
        chmod 755 "$DEST/$b"
        ok "$b"
    else
        warn "$b not found in $SCRIPT_DIR — skipping"
    fi
done

if [[ -f "$SCRIPT_DIR/essentials_lib.py" ]]; then
    cp "$SCRIPT_DIR/essentials_lib.py" "$DEST/essentials_lib.py"
    chmod 644 "$DEST/essentials_lib.py"
    ok "essentials_lib.py"
fi

# ── PATH check ────────────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$DEST"; then
    warn "$DEST is not in PATH"
    info "Add to your shell RC:  export PATH=\"$DEST:\$PATH\""
fi

# ── Restart bar ───────────────────────────────────────────────────────────────
echo ""
info "Restarting bar..."
pkill -f "python3.*essentials-bars" 2>/dev/null || true
pkill -f "python3.*essentials-widgets" 2>/dev/null || true
pkill -f "python3.*essentials-dock" 2>/dev/null || true
sleep 0.5

python3 "$DEST/essentials-bars" > /tmp/essentials-bars.log 2>&1 &
disown $!
sleep 0.4

if pgrep -f "essentials-bars" > /dev/null; then
    ok "Bar started"
else
    fail "Bar failed to start — check /tmp/essentials-bars.log"
    tail -5 /tmp/essentials-bars.log
fi
echo ""
