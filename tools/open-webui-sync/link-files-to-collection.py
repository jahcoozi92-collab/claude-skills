#!/usr/bin/env python3
"""
Verknuepft alle SKILL*.md Files mit Knowledge Collection 'Claude Skills'.
Fix fuer v0.8: /api/v1/knowledge/{id}/file/add (v0.7-Endpoint) funktioniert nicht mehr.
Direkt in DB:
  - INSERT INTO knowledge_file (id, user_id, knowledge_id, file_id, ...)
  - UPDATE knowledge.data.file_ids
  - Chunks werden bei Chat-Query automatisch generiert (lazy indexing)

Kein Secret-Leak.
"""
import sqlite3, json, sys, uuid, time

DB_PATH = "/app/backend/data/webui.db"
COLLECTION_NAME = "Claude Skills"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. Collection finden
cur.execute("SELECT id, user_id, data FROM knowledge WHERE name = ?", (COLLECTION_NAME,))
row = cur.fetchone()
if not row:
    print(f"FEHLER: Collection '{COLLECTION_NAME}' nicht gefunden", file=sys.stderr)
    sys.exit(1)
coll_id, coll_user_id, coll_data = row
print(f"Collection: {coll_id[:12]}...", file=sys.stderr)

# 2. Alle SKILL*.md Files finden (nur jüngste pro filename — Duplikate meiden)
cur.execute("""
    SELECT id, filename, created_at, user_id
    FROM file
    WHERE filename LIKE '%SKILL%.md'
    ORDER BY created_at DESC
""")
all_skill_files = cur.fetchall()

# Pro filename nur die neueste
seen = set()
skill_files = []
for fid, fn, ca, uid in all_skill_files:
    if fn not in seen:
        seen.add(fn)
        skill_files.append((fid, fn, ca, uid))

print(f"SKILL-Files: {len(skill_files)} unique (von {len(all_skill_files)} total)", file=sys.stderr)

# 3. Bestehende knowledge_file für diese Collection löschen
cur.execute("DELETE FROM knowledge_file WHERE knowledge_id = ?", (coll_id,))
print(f"Alte knowledge_file Zeilen geloescht: {cur.rowcount}", file=sys.stderr)

# 4. Neue Verknüpfungen einfügen
now = int(time.time())
file_ids = []
for fid, fn, _, _ in skill_files:
    kf_id = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO knowledge_file (id, user_id, knowledge_id, file_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (kf_id, coll_user_id, coll_id, fid, now, now))
    file_ids.append(fid)

print(f"Neue knowledge_file Zeilen: {cur.rowcount}", file=sys.stderr)

# 5. knowledge.data.file_ids aktualisieren
try:
    data = json.loads(coll_data) if coll_data else {}
except:
    data = {}
if not isinstance(data, dict):
    data = {}
data["file_ids"] = file_ids

cur.execute("UPDATE knowledge SET data = ?, updated_at = ? WHERE id = ?",
            (json.dumps(data), now, coll_id))
print(f"knowledge.data.file_ids: {len(file_ids)} files", file=sys.stderr)

conn.commit()
conn.close()
print("fertig", file=sys.stderr)
