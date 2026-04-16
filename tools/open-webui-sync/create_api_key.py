#!/usr/bin/env python3
"""
Open WebUI API-Key direkt in SQLite schreiben.
Im Container ausfuehren:
    docker exec -i open-webui python3 < create_api_key.py
oder via docker cp:
    docker cp create_api_key.py open-webui:/tmp/
    docker exec open-webui python3 /tmp/create_api_key.py
"""
import sqlite3
import secrets
import string
import sys

DB_PATH = "/app/backend/data/webui.db"
EMAIL = "diana.goebel@proton.me"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. Schema pruefen
cur.execute("PRAGMA table_info(user)")
cols = [r[1] for r in cur.fetchall()]
print("User-Tabelle Spalten:", cols, file=sys.stderr)

if "api_key" not in cols:
    print("FEHLER: Spalte 'api_key' existiert nicht in 'user'-Tabelle", file=sys.stderr)
    print("Verfuegbare Spalten:", cols, file=sys.stderr)
    sys.exit(1)

# 2. User suchen
cur.execute(f"SELECT id, email, role FROM user WHERE email = ?", (EMAIL,))
user = cur.fetchone()
if not user:
    print(f"FEHLER: User {EMAIL} nicht gefunden", file=sys.stderr)
    sys.exit(1)

print(f"User gefunden: id={user[0][:8]}..., role={user[2]}", file=sys.stderr)

# 3. Key generieren
alphabet = string.ascii_letters + string.digits
random_part = "".join(secrets.choice(alphabet) for _ in range(48))
key = f"sk-{random_part}"

# 4. In DB schreiben
cur.execute("UPDATE user SET api_key = ? WHERE email = ?", (key, EMAIL))
conn.commit()
print(f"DB aktualisiert: {cur.rowcount} Zeile(n)", file=sys.stderr)

# 5. Verifizieren
cur.execute("SELECT api_key FROM user WHERE email = ?", (EMAIL,))
saved = cur.fetchone()[0]
if saved == key:
    print("Verifikation erfolgreich: Key gespeichert", file=sys.stderr)
else:
    print(f"WARNUNG: DB zeigt anderen Key als erwartet", file=sys.stderr)

conn.close()

# 6. Key auf STDOUT (damit man es in eine Datei pipen kann)
print(key)
