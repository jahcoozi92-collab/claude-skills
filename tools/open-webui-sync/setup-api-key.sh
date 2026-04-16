#!/usr/bin/env bash
# Setup API-Key fuer Open WebUI:
# 1. Kopiert Python-Script in Container
# 2. Fuehrt es aus
# 3. Schreibt Key in ~/.openclaw/.env.owui
# 4. Restartet Container
#
# Nutzung auf NAS:
#   bash ~/.claude/skills/tools/open-webui-sync/setup-api-key.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/create_api_key.py"
CONTAINER="${OWUI_CONTAINER:-open-webui}"
KEY_FILE="${OWUI_KEY_FILE:-$HOME/.openclaw/.env.owui}"
LOG_FILE="$HOME/owui-keygen.log"
KEY_TMP="$HOME/owui-keygen.tmp"

if [[ ! -f "$PY_SCRIPT" ]]; then
    echo "FEHLER: $PY_SCRIPT nicht gefunden" >&2
    exit 1
fi

echo "[1/4] Kopiere Script in Container '$CONTAINER'..."
docker cp "$PY_SCRIPT" "$CONTAINER:/tmp/create_api_key.py"

echo "[2/4] Fuehre Script im Container aus..."
docker exec "$CONTAINER" python3 /tmp/create_api_key.py > "$KEY_TMP" 2> "$LOG_FILE"

echo "--- Log ---"
cat "$LOG_FILE"
echo "-----------"

if [[ ! -s "$KEY_TMP" ]]; then
    echo "FEHLER: Kein Key generiert" >&2
    exit 1
fi

KEY=$(cat "$KEY_TMP")
rm -f "$KEY_TMP"
docker exec "$CONTAINER" rm -f /tmp/create_api_key.py

echo "[3/4] Schreibe Key in $KEY_FILE..."
mkdir -p "$(dirname "$KEY_FILE")"
echo "OWUI_TOKEN=$KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
echo "  Laenge: ${#KEY}"
echo "  Prefix: ${KEY:0:4}..."

echo "[4/4] Container restart..."
docker restart "$CONTAINER" > /dev/null
echo "  Gestartet — warte 8s..."
sleep 8

echo ""
echo "Auth-Test..."
source "$KEY_FILE"
code=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 \
    -H "Authorization: Bearer $OWUI_TOKEN" \
    "https://chat.forensikzentrum.com/api/v1/knowledge/")
echo "  GET /api/v1/knowledge/ → HTTP $code"

if [[ "$code" == "200" ]]; then
    echo ""
    echo "✓ Fertig. API-Key funktioniert. Weiter mit sync-skills.sh"
else
    echo ""
    echo "✗ Auth klappt noch nicht (HTTP $code). Pruefe Admin-Settings:"
    echo "  → 'API-Schluessel aktivieren' muss ON sein"
    echo "  → 'Erlaubte Endpunkte' muss leer sein"
fi
