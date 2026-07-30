#!/usr/bin/env bash
# setup-whisrs-system.sh — System-Voraussetzungen für whisrs (Wayland) einrichten.
#
# Muss einmalig mit sudo ausgeführt werden:
#   sudo ~/.cargo/bin/../setup-whisrs-system.sh
#
# Was passiert:
# 1. User wird zur input-Gruppe hinzugefügt (Hotkey-Erkennung via evdev)
# 2. uinput udev-rule wird angelegt (Text-Eingabe via ydotool)
# 3. ydotool systemd Service wird aktiviert
set -euo pipefail

echo "═══════════════════════════════════════════"
echo "  whisrs System-Setup"
echo "═══════════════════════════════════════════"

# 1. User zur input-Gruppe hinzufügen
echo ""
echo "── 1. input-Gruppe ──"
if groups "$USER" | grep -qw input; then
    echo "  User $USER ist bereits in der input-Gruppe"
else
    sudo usermod -aG input "$USER"
    echo "  User $USER zur input-Gruppe hinzugefügt"
    echo "  ⚠️  Bitte neu einloggen für die Gruppen-Änderung!"
fi

# 2. uinput udev-rule
echo ""
echo "── 2. uinput udev-rule ──"
UDEV_RULE="/etc/udev/rules.d/99-uinput.rules"
if [ -f "$UDEV_RULE" ]; then
    echo "  $UDEV_RULE existiert bereits"
else
    echo 'KERNEL=="uinput", MODE="0660", GROUP="input"' | sudo tee "$UDEV_RULE" > /dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "  $UDEV_RULE angelegt und geladen"
fi

# 3. ydotool Service
echo ""
echo "── 3. ydotool Service ──"
if systemctl --user is-enabled ydotool.service &>/dev/null; then
    echo "  ydotool.service ist bereits aktiv"
else
    systemctl --user enable --now ydotool.service 2>/dev/null || true
    echo "  ydotool.service aktiviert"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  Fertig!"
echo "  • Bei Gruppen-Änderung: neu einloggen"
echo "  • Danach: whisrs starten"
echo "═══════════════════════════════════════════"
