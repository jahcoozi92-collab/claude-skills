#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup DB
docker exec open-webui cp /app/backend/data/webui.db /app/backend/data/webui.db.backup.$(date +%s)
echo "DB Backup erstellt"

docker cp "$SCRIPT_DIR/link-files-to-collection.py" open-webui:/tmp/link-files.py
docker exec open-webui python3 /tmp/link-files.py 2>&1
docker restart open-webui > /dev/null
echo "Container restarted"
sleep 15
echo ""
echo "Verify: "
docker exec open-webui python3 -c "
import sqlite3
c = sqlite3.connect('/app/backend/data/webui.db').cursor()
c.execute('SELECT COUNT(*) FROM knowledge_file')
print(f'  knowledge_file rows: {c.fetchone()[0]}')
c.execute(\"SELECT name, length(json_extract(data, '\$.file_ids')) FROM knowledge\")
for n, l in c.fetchall(): print(f'  Collection \"{n}\" file_ids length: {l}')
"
