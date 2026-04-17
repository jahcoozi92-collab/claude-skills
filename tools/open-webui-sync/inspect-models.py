#!/usr/bin/env python3
"""
Inspiziert model-Tabelle in Open WebUI.
Gibt Schema + Anzahl aktiver/inaktiver Modelle + Sample-IDs aus.
Druckt KEINE Secrets.
"""
import sqlite3
import json
import sys
from collections import Counter

DB_PATH = "/app/backend/data/webui.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# Schema
cur.execute("PRAGMA table_info(model)")
cols = [r[1] for r in cur.fetchall()]
print(f"model Spalten: {cols}", file=sys.stderr)

# Gesamt-Count
cur.execute("SELECT COUNT(*) FROM model")
total = cur.fetchone()[0]
print(f"Gesamtzahl Modelle: {total}", file=sys.stderr)

# Active-Count
if "is_active" in cols:
    cur.execute("SELECT is_active, COUNT(*) FROM model GROUP BY is_active")
    for state, count in cur.fetchall():
        print(f"  is_active={state}: {count}", file=sys.stderr)

# Sample IDs + base_model
id_idx = cols.index("id") if "id" in cols else 0
base_idx = cols.index("base_model_id") if "base_model_id" in cols else None
name_idx = cols.index("name") if "name" in cols else None
active_idx = cols.index("is_active") if "is_active" in cols else None

cur.execute("SELECT * FROM model LIMIT 1000")
all_rows = cur.fetchall()

providers = Counter()
by_base = Counter()
sample_ids = []

for row in all_rows:
    mid = row[id_idx] if id_idx is not None else "?"
    base = row[base_idx] if base_idx is not None else "?"
    name = row[name_idx] if name_idx is not None else "?"
    active = row[active_idx] if active_idx is not None else "?"

    # Provider aus id extrahieren (vor erstem '/' oder '.')
    if isinstance(mid, str):
        if "/" in mid:
            provider = mid.split("/")[0]
        elif "." in mid:
            provider = mid.split(".")[0]
        elif mid.startswith("claude"):
            provider = "anthropic"
        elif mid.startswith("gpt") or mid.startswith("o1") or mid.startswith("o3"):
            provider = "openai"
        elif mid.startswith("gemini"):
            provider = "google"
        elif ":" in mid:
            provider = "ollama"
        else:
            provider = "other"
        providers[provider] += 1

    sample_ids.append((mid, base, name, active))

print(f"\nProvider-Verteilung:", file=sys.stderr)
for p, c in providers.most_common():
    print(f"  {p:20s}: {c}", file=sys.stderr)

print(f"\nSample 20 Eintraege (id, base_model_id, name, is_active):", file=sys.stderr)
for mid, base, name, active in sample_ids[:20]:
    # name kann langer sein, truncate
    name_s = (str(name)[:40] + "..") if name and len(str(name)) > 40 else name
    print(f"  [{active}] id={str(mid)[:40]:40s} base={str(base)[:30]:30s} name={name_s}", file=sys.stderr)

conn.close()
