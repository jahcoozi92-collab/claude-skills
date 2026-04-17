#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Backup DB ==="
docker exec open-webui cp /app/backend/data/webui.db /app/backend/data/webui.db.backup.$(date +%s)
echo "  Backup erstellt"

echo ""
echo "=== Modell-Bereinigung ==="
docker cp "$SCRIPT_DIR/apply-cleanup.py" open-webui:/tmp/apply-cleanup.py
docker exec open-webui python3 /tmp/apply-cleanup.py 2>&1

echo ""
echo "=== Container restart ==="
docker restart open-webui > /dev/null
sleep 20
echo "  Gestartet"

echo ""
echo "=== Aktive Modelle nach Bereinigung ==="
docker exec open-webui python3 -c "
import sqlite3
c = sqlite3.connect('/app/backend/data/webui.db').cursor()
c.execute('SELECT id, name FROM model WHERE is_active = 1 ORDER BY name')
rows = c.fetchall()
print(f'Total aktiv: {len(rows)}')
for mid, name in rows:
    print(f'  {name}')
"
