#!/usr/bin/env bash
# Inspiziert Open WebUI DB-Schema um API-Key-Tabelle zu finden
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/create_api_key.py"
CONTAINER="${OWUI_CONTAINER:-open-webui}"

echo "Kopiere Inspect-Script in Container..."
docker cp "$PY_SCRIPT" "$CONTAINER:/tmp/create_api_key.py"

echo ""
echo "--- Schema-Analyse ---"
docker exec "$CONTAINER" python3 /tmp/create_api_key.py 2>&1 || true
