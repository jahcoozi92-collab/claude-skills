#!/usr/bin/env python3
"""
Setzt auth.jwt_expiry von -1 (nie) auf 7d (7 Tage).
Direkt im Open WebUI config.data JSON.
Druckt keine Secrets.
"""
import sqlite3, json, sys

DB_PATH = "/app/backend/data/webui.db"
NEW_EXPIRY = "7d"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("PRAGMA table_info(config)")
cols = [r[1] for r in cur.fetchall()]
data_idx = cols.index("data")
id_idx = cols.index("id")

cur.execute("SELECT * FROM config")
rows = cur.fetchall()

for row in rows:
    blob = row[data_idx]
    if not blob: continue
    try:
        d = json.loads(blob) if isinstance(blob, str) else blob
    except Exception as e:
        print(f"Parse-Fehler: {e}", file=sys.stderr); continue

    if "auth" not in d or not isinstance(d["auth"], dict):
        d["auth"] = {}
    old = d["auth"].get("jwt_expiry", "?")
    d["auth"]["jwt_expiry"] = NEW_EXPIRY
    print(f"jwt_expiry: '{old}' → '{NEW_EXPIRY}'", file=sys.stderr)

    cur.execute("UPDATE config SET data = ? WHERE id = ?", (json.dumps(d), row[id_idx]))

conn.commit()
conn.close()
print("fertig", file=sys.stderr)
