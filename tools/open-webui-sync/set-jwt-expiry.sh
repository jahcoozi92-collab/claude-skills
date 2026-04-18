#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker cp "$SCRIPT_DIR/set-jwt-expiry.py" open-webui:/tmp/set-jwt-expiry.py
docker exec open-webui python3 /tmp/set-jwt-expiry.py 2>&1
docker restart open-webui > /dev/null
echo "Container restarted"
