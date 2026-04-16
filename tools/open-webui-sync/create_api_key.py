#!/usr/bin/env python3
"""
Open WebUI API-Key in separate api_key Tabelle schreiben (v0.8+).
Schema: api_key(id, user_id, key, data, expires_at, last_used_at, created_at, updated_at)
"""
import sqlite3
import secrets
import string
import sys
import time
import json
import uuid

DB_PATH = "/app/backend/data/webui.db"
EMAIL = "diana.goebel@proton.me"
KEY_NAME = "claude-skills-sync"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. User finden
cur.execute("SELECT id, email, role FROM user WHERE email = ?", (EMAIL,))
user = cur.fetchone()
if not user:
    print(f"FEHLER: User {EMAIL} nicht gefunden", file=sys.stderr)
    sys.exit(1)
user_id, user_email, user_role = user
print(f"User gefunden: id={user_id[:12]}..., role={user_role}", file=sys.stderr)

# 2. api_key Schema holen
cur.execute("PRAGMA table_info(api_key)")
api_key_cols = [r[1] for r in cur.fetchall()]
print(f"api_key Spalten: {api_key_cols}", file=sys.stderr)

# 3. Alte Keys dieses Users (optional loeschen um sauber zu bleiben)
cur.execute("SELECT id, key FROM api_key WHERE user_id = ?", (user_id,))
old_keys = cur.fetchall()
if old_keys:
    print(f"Gefunden {len(old_keys)} alte Keys fuer User — loesche sie", file=sys.stderr)
    cur.execute("DELETE FROM api_key WHERE user_id = ?", (user_id,))

# 4. Neuen Key generieren
alphabet = string.ascii_letters + string.digits
random_part = "".join(secrets.choice(alphabet) for _ in range(48))
key = f"sk-{random_part}"

# 5. Insert
key_id = str(uuid.uuid4())
now = int(time.time())
data_blob = json.dumps({"name": KEY_NAME, "scopes": []})

cur.execute("""
    INSERT INTO api_key (id, user_id, key, data, expires_at, last_used_at, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
""", (key_id, user_id, key, data_blob, None, None, now, now))

conn.commit()
print(f"Key eingefuegt: id={key_id}, user_id={user_id[:12]}...", file=sys.stderr)

# 6. Verifizieren
cur.execute("SELECT COUNT(*) FROM api_key WHERE user_id = ?", (user_id,))
count = cur.fetchone()[0]
print(f"Aktive Keys fuer User: {count}", file=sys.stderr)

conn.close()
print(key)
