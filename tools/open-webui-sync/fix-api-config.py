#!/usr/bin/env python3
"""
Setzt ENABLE_API_KEY = True direkt in der Open WebUI config-Tabelle.
Dient als Fallback wenn der Admin-Panel-Toggle nicht greift.
"""
import sqlite3
import json
import sys

DB_PATH = "/app/backend/data/webui.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. config Tabelle Schema
cur.execute("PRAGMA table_info(config)")
cols = [r[1] for r in cur.fetchall()]
print(f"config Spalten: {cols}", file=sys.stderr)

# 2. Aktuelle Config-Rows anzeigen
cur.execute("SELECT * FROM config")
rows = cur.fetchall()
print(f"config Zeilen: {len(rows)}", file=sys.stderr)

for row in rows:
    print(f"  Row: {row[:2]}...", file=sys.stderr)

# 3. Falls 'data' Spalte JSON-Blob enthaelt — parsen und inspizieren
if "data" in cols and rows:
    data_idx = cols.index("data")
    for i, row in enumerate(rows):
        try:
            blob = row[data_idx]
            if blob:
                d = json.loads(blob) if isinstance(blob, str) else blob
                # Suche nach api_key relevanten Keys (auch nested)
                def find_api_keys(obj, prefix=""):
                    found = {}
                    if isinstance(obj, dict):
                        for k, v in obj.items():
                            full = f"{prefix}.{k}" if prefix else k
                            if "api_key" in k.lower() or "enable_api" in k.lower():
                                found[full] = v
                            elif isinstance(v, (dict, list)):
                                found.update(find_api_keys(v, full))
                    return found
                hits = find_api_keys(d)
                if hits:
                    print(f"  Zeile {i}: API-Key relevante Settings:", file=sys.stderr)
                    for k, v in hits.items():
                        print(f"    {k} = {v}", file=sys.stderr)

                # Pruefe ob ENABLE_API_KEY gesetzt werden muss
                changed = False
                if isinstance(d, dict):
                    if "ui" in d and isinstance(d["ui"], dict):
                        if d["ui"].get("ENABLE_API_KEY") is not True:
                            d["ui"]["ENABLE_API_KEY"] = True
                            changed = True
                            print(f"  -> Setze ui.ENABLE_API_KEY = True", file=sys.stderr)
                    # Andere mögliche Pfade
                    for nested_key in ["api_key", "API_KEY", "ENABLE_API_KEY"]:
                        if nested_key in d and d[nested_key] is not True:
                            d[nested_key] = True
                            changed = True
                            print(f"  -> Setze {nested_key} = True", file=sys.stderr)
                    # auth dict
                    if "auth" in d and isinstance(d["auth"], dict):
                        if d["auth"].get("api_key", {}).get("enable") is not True:
                            if "api_key" not in d["auth"]:
                                d["auth"]["api_key"] = {}
                            d["auth"]["api_key"]["enable"] = True
                            d["auth"]["api_key"]["endpoint_restrictions"] = False
                            d["auth"]["api_key"]["allowed_endpoints"] = ""
                            changed = True
                            print(f"  -> Setze auth.api_key.enable = True", file=sys.stderr)

                if changed:
                    new_blob = json.dumps(d)
                    id_idx = cols.index("id")
                    cur.execute(f"UPDATE config SET data = ? WHERE id = ?", (new_blob, row[id_idx]))
                    print(f"  -> DB aktualisiert", file=sys.stderr)
        except Exception as e:
            print(f"  Parse-Fehler: {e}", file=sys.stderr)

conn.commit()
conn.close()
print("fertig", file=sys.stderr)
