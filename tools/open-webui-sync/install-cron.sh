#!/usr/bin/env bash
# Installiert Cronjob der taeglich 3:30 AM Skills → Open WebUI Collection synct.
# Idempotent: kann beliebig oft laufen (ueberschreibt vorhandenen Entry).
set -euo pipefail

SCRIPT_PATH="$HOME/.claude/skills/tools/open-webui-sync/update-all.sh"
LOG_DIR="$HOME/.cache/skill-sync"
mkdir -p "$LOG_DIR"

MARKER="# open-webui-skill-sync"
CRON_LINE="30 3 * * * bash $SCRIPT_PATH > $LOG_DIR/\$(date +\\%Y\\%m\\%d-\\%H\\%M).log 2>&1  $MARKER"

# Vorhandene crontab holen, unsere Zeilen entfernen (via MARKER), neue einfuegen
TMP=$(mktemp)
crontab -l 2>/dev/null | grep -v -F "$MARKER" > "$TMP" || true
echo "$CRON_LINE" >> "$TMP"
crontab "$TMP"
rm "$TMP"

echo "✓ Cronjob installiert:"
crontab -l | grep -F "$MARKER"
echo ""
echo "Runs: taeglich 3:30 AM"
echo "Logs: $LOG_DIR/YYYYMMDD-HHMM.log (letzte 10)"
echo ""
echo "Manuell jetzt triggern:"
echo "  bash $SCRIPT_PATH"
