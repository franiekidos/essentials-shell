# Maintainer: Your Name <your@email.com>
pkgname=essentials-shell
pkgver=1.0.0
pkgrel=1
pkgdesc="Lightweight compositor-agnostic Wayland desktop shell"
arch=('any')
url="https://github.com/yourname/essentials-shell"
license=('MIT')
depends=(
    'python>=3.10'
    'python-gobject'
    'python-psutil'
    'gtk3'
    'gtk-layer-shell'
)
optdepends=(
    'python-pillow: wallpaper colour theme generation'
    'swww: animated wallpaper transitions'
    'swaybg: simple wallpaper setter'
    'playerctl: media controls in bar'
    'wireplumber: volume control (wpctl)'
    'brightnessctl: brightness control'
    'networkmanager: WiFi management (nmcli)'
    'bluez-utils: Bluetooth toggle (bluetoothctl)'
    'mako: notification history (makoctl)'
    'dunst: notification history (dunstctl)'
    'swaylock: lock screen'
    'hyprlock: Hyprland native lock screen'
    'fontconfig: font picker (fc-list)'
    'xdg-utils: default app management (xdg-mime)'
    'wlr-randr: monitor control on River/Labwc/MangoWC'
    'hyprpm: Hyprland plugin manager'
)
source=("$pkgname-$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$srcdir/$pkgname-$pkgver"

    install -d "$pkgdir/usr/lib/essentials"
    install -d "$pkgdir/usr/share/essentials"
    install -d "$pkgdir/usr/bin"

    # Binaries
    for f in essentials-bars essentials-cc essentials-detect \
              essentials-launcher essentials-powermenu essentials-settings \
              essentials-theme-apply essentials-config-writer \
              essentials-osd essentials-wallpaper essentials-lockscreen \
              essentials-widgets essentials-wizard; do
        install -Dm755 "$f" "$pkgdir/usr/lib/essentials/$f"
        ln -s "/usr/lib/essentials/$f" "$pkgdir/usr/bin/$f"
    done

    # Library
    install -Dm644 essentials_lib.py "$pkgdir/usr/lib/essentials/essentials_lib.py"

    # Default config
    install -Dm644 themes.json "$pkgdir/usr/share/essentials/themes.json"

    # License
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

post_install() {
    echo "Essentials Shell installed."
    echo "Start with: essentials-wizard"
    echo "Or: essentials-bars &"
    echo ""
    echo "Add to your compositor config:"
    echo "  Hyprland:  exec-once = essentials-bars"
    echo "  Sway:      exec essentials-bars"
    echo "  Niri:      spawn-at-startup \"essentials-bars\""
}
