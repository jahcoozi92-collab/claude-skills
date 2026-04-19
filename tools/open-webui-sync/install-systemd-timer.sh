#!/usr/bin/env bash
# Installiert einen systemd --user Timer der taeglich 3:30 AM
# update-all.sh ausfuehrt (kein sudo/root noetig).
set -euo pipefail

SCRIPT_PATH="$HOME/.claude/skills/tools/open-webui-sync/update-all.sh"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
LOG_DIR="$HOME/.cache/skill-sync"
mkdir -p "$SYSTEMD_USER_DIR" "$LOG_DIR"

# Service-Unit
cat > "$SYSTEMD_USER_DIR/skill-sync.service" <<EOF
[Unit]
Description=Open WebUI Skills Knowledge Collection Sync
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '$SCRIPT_PATH > $LOG_DIR/\$(date +\\%Y\\%m\\%d-\\%H\\%M).log 2>&1'
StandardOutput=journal
StandardError=journal
EOF

# Timer-Unit (taeglich 3:30)
cat > "$SYSTEMD_USER_DIR/skill-sync.timer" <<EOF
[Unit]
Description=Daily Skills Sync (03:30 AM)
Requires=skill-sync.service

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF

# Aktivieren
systemctl --user daemon-reload
systemctl --user enable --now skill-sync.timer

echo "✓ systemd Timer installiert:"
systemctl --user status skill-sync.timer --no-pager | head -8
echo ""
echo "Naechster Lauf:"
systemctl --user list-timers skill-sync.timer --no-pager
echo ""
echo "Manuell jetzt triggern:"
echo "  systemctl --user start skill-sync.service"
echo "Status pruefen:"
echo "  journalctl --user -u skill-sync.service -n 50"
echo "Deaktivieren:"
echo "  systemctl --user disable --now skill-sync.timer"

# Linger aktivieren damit Timer auch laeuft wenn User nicht eingeloggt ist
if ! loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
    echo ""
    echo "⚠ Linger nicht aktiv — Timer laeuft nur bei aktiver Session."
    echo "  Fuer permanente Ausfuehrung einmalig als Admin:"
    echo "  sudo loginctl enable-linger $USER"
fi
