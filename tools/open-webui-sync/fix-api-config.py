#!/usr/bin/env python3
"""
Setzt auth.api_key.enable=True + endpoint_restrictions=False in Open WebUI config.
Druckt NIEMALS API-Key-Werte — nur Strukturinfo.
"""
import sqlite3
import json
import sys

DB_PATH = "/app/backend/data/webui.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("PRAGMA table_info(config)")
cols = [r[1] for r in cur.fetchall()]

cur.execute("SELECT * FROM config")
rows = cur.fetchall()
print(f"config Zeilen: {len(rows)}", file=sys.stderr)

if "data" not in cols or not rows:
    print("FEHLER: config.data nicht gefunden", file=sys.stderr)
    sys.exit(1)

data_idx = cols.index("data")
id_idx = cols.index("id")

for i, row in enumerate(rows):
    blob = row[data_idx]
    if not blob:
        continue
    try:
        d = json.loads(blob) if isinstance(blob, str) else blob
    except Exception as e:
        print(f"Zeile {i}: Parse-Fehler: {e}", file=sys.stderr)
        continue

    changed = False

    # Fix 1: auth.api_key
    if "auth" in d and isinstance(d["auth"], dict):
        if "api_key" not in d["auth"] or not isinstance(d["auth"]["api_key"], dict):
            d["auth"]["api_key"] = {}
        before = dict(d["auth"]["api_key"])
        d["auth"]["api_key"]["enable"] = True
        d["auth"]["api_key"]["endpoint_restrictions"] = False
        d["auth"]["api_key"]["allowed_endpoints"] = ""
        if before != d["auth"]["api_key"]:
            # Namen der geaenderten Felder zeigen, keine Werte
            changed_fields = [k for k in d["auth"]["api_key"] if before.get(k) != d["auth"]["api_key"][k]]
            print(f"Zeile {i}: auth.api_key geandert: {changed_fields}", file=sys.stderr)
            changed = True

        # enable_api_keys (auf auth-Ebene)
        if d["auth"].get("enable_api_keys") is not True:
            d["auth"]["enable_api_keys"] = True
            print(f"Zeile {i}: auth.enable_api_keys = True gesetzt", file=sys.stderr)
            changed = True

    # Fix 2: ui.ENABLE_API_KEY (fuer aeltere Versionen)
    if "ui" in d and isinstance(d["ui"], dict):
        if d["ui"].get("ENABLE_API_KEY") is not True:
            d["ui"]["ENABLE_API_KEY"] = True
            print(f"Zeile {i}: ui.ENABLE_API_KEY = True gesetzt", file=sys.stderr)
            changed = True

    if changed:
        new_blob = json.dumps(d)
        cur.execute("UPDATE config SET data = ? WHERE id = ?", (new_blob, row[id_idx]))
        print(f"Zeile {i}: DB-Update erfolgreich", file=sys.stderr)
    else:
        print(f"Zeile {i}: keine Aenderung noetig", file=sys.stderr)

conn.commit()
conn.close()
print("fertig", file=sys.stderr)
