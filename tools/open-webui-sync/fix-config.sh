#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker cp "$SCRIPT_DIR/fix-api-config.py" open-webui:/tmp/fix-api-config.py
docker exec open-webui python3 /tmp/fix-api-config.py 2>&1
echo "---"
echo "Container restart fuer Config-Reload..."
docker restart open-webui > /dev/null
echo "Warte 30s..."
sleep 30
echo "Teste Auth..."
bash "$SCRIPT_DIR/test-auth.sh"
