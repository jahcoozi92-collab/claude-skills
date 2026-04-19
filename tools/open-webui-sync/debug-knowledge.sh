#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker cp "$SCRIPT_DIR/debug-knowledge.py" open-webui:/tmp/debug-knowledge.py
docker exec open-webui python3 /tmp/debug-knowledge.py 2>&1
