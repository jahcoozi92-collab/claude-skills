#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker cp "$SCRIPT_DIR/inspect-models.py" open-webui:/tmp/inspect-models.py
docker exec open-webui python3 /tmp/inspect-models.py 2>&1
