#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker cp "$SCRIPT_DIR/plan-cleanup.py" open-webui:/tmp/plan-cleanup.py
docker exec open-webui python3 /tmp/plan-cleanup.py 2>&1
