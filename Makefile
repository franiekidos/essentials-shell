# ┌──────────────────────────────────────────────────────────┐
# │  Essentials Shell — Makefile                             │
# │  make install   → install to ~/.local                    │
# │  make uninstall → remove from ~/.local                   │
# │  make update    → reinstall over existing                │
# └──────────────────────────────────────────────────────────┘

PREFIX   ?= $(HOME)/.local
BINDIR    = $(PREFIX)/bin
CFGDIR    = $(HOME)/.config/essentials

BINS = essentials-bars essentials-cc essentials-detect essentials-launcher \
       essentials-powermenu essentials-settings essentials-theme-apply \
       essentials-config-writer essentials-osd essentials-wallpaper \
       essentials-lockscreen essentials-widgets essentials-wizard

.PHONY: all install uninstall update check

all:
	@echo "Run 'make install' to install Essentials Shell."

install: check
	@echo "Installing to $(BINDIR)..."
	@mkdir -p $(BINDIR) $(CFGDIR)
	@for f in $(BINS); do \
		install -m 755 $$f $(BINDIR)/$$f; \
		echo "  ✓ $$f"; \
	done
	@install -m 644 essentials_lib.py $(BINDIR)/essentials_lib.py
	@if [ ! -f $(CFGDIR)/themes.json ]; then \
		install -m 644 themes.json $(CFGDIR)/themes.json; \
		echo "  ✓ themes.json (default)"; \
	else \
		echo "  ~ themes.json already exists (kept)"; \
	fi
	@echo ""
	@$(MAKE) --no-print-directory _path_check
	@$(MAKE) --no-print-directory _autostart
	@echo ""
	@echo "✓ Essentials Shell installed."
	@echo "  Start:    python3 $(BINDIR)/essentials-wizard"
	@echo "  Or jump straight in: python3 $(BINDIR)/essentials-bars"

update:
	@echo "Updating Essentials Shell..."
	@mkdir -p $(BINDIR)
	@for f in $(BINS); do \
		install -m 755 $$f $(BINDIR)/$$f; \
	done
	@install -m 644 essentials_lib.py $(BINDIR)/essentials_lib.py
	@echo "✓ Updated. Restart the bar to apply changes."
	@echo "  python3 $(BINDIR)/essentials-theme-apply"

uninstall:
	@echo "Removing Essentials Shell from $(BINDIR)..."
	@for f in $(BINS) essentials_lib.py; do \
		rm -f $(BINDIR)/$$f && echo "  ✗ $$f"; \
	done
	@echo "  Config kept at $(CFGDIR) — remove manually if desired."
	@echo "✓ Uninstalled."

check:
	@echo "Checking Python..."
	@python3 -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" || \
		(echo "✗ Python 3.10+ required"; exit 1)
	@python3 -c "import gi" 2>/dev/null && echo "  ✓ python-gobject" || \
		echo "  ✗ python-gobject missing (install python3-gobject)"
	@python3 -c "import psutil" 2>/dev/null && echo "  ✓ psutil" || \
		echo "  ✗ psutil missing (install python3-psutil)"
	@python3 -c "import PIL" 2>/dev/null && echo "  ✓ Pillow" || \
		echo "  ~ Pillow missing (optional, needed for wallpaper theme gen)"

_path_check:
	@echo "PATH check:"
	@echo "$(PATH)" | grep -q "$(BINDIR)" && \
		echo "  ✓ $(BINDIR) is in PATH" || \
		(echo "  ⚠ $(BINDIR) is NOT in PATH"; \
		 echo "    Add to your shell RC: export PATH=\"$(BINDIR):\$$PATH\"")

_autostart:
	@echo "Autostart:"
	@if echo "$$HYPRLAND_INSTANCE_SIGNATURE" | grep -q .; then \
		CONF="$$HOME/.config/hypr/hyprland.conf"; \
		if [ -f "$$CONF" ] && grep -q "essentials-bars" "$$CONF"; then \
			echo "  ✓ Hyprland autostart already configured"; \
		elif [ -f "$$CONF" ]; then \
			printf "\n# Essentials Shell\nexec-once = python3 $(BINDIR)/essentials-bars\n" >> "$$CONF"; \
			echo "  ✓ Added exec-once to $$CONF"; \
		else \
			echo "  ~ hyprland.conf not found — add manually:"; \
			echo "    exec-once = python3 $(BINDIR)/essentials-bars"; \
		fi; \
	elif echo "$$NIRI_SOCKET" | grep -q .; then \
		CONF="$$HOME/.config/niri/config.kdl"; \
		if [ -f "$$CONF" ] && grep -q "essentials-bars" "$$CONF"; then \
			echo "  ✓ Niri autostart already configured"; \
		elif [ -f "$$CONF" ]; then \
			printf "\nspawn-at-startup \"python3\" \"$(BINDIR)/essentials-bars\"\n" >> "$$CONF"; \
			echo "  ✓ Added spawn-at-startup to $$CONF"; \
		fi; \
	elif echo "$$SWAYSOCK" | grep -q .; then \
		CONF="$$HOME/.config/sway/config"; \
		if [ -f "$$CONF" ] && grep -q "essentials-bars" "$$CONF"; then \
			echo "  ✓ Sway autostart already configured"; \
		elif [ -f "$$CONF" ]; then \
			printf "\nexec python3 $(BINDIR)/essentials-bars\n" >> "$$CONF"; \
			echo "  ✓ Added exec to $$CONF"; \
		fi; \
	else \
		echo "  ~ No running compositor detected — add autostart manually"; \
	fi
