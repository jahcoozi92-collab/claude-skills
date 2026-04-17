#!/usr/bin/env python3
"""
PREVIEW-Modus: Zeigt welche Modelle aktiv gelassen, welche deaktiviert wuerden.
Macht KEINE DB-Aenderungen. Druckt keine Secrets.
"""
import sqlite3
import re
import sys

DB_PATH = "/app/backend/data/webui.db"

# ID-Patterns die AKTIV bleiben sollen (Regex match auf model.id)
# Reihenfolge = Tier (Flagship zuerst)
KEEP = [
    # === ANTHROPIC (Flagship) ===
    (r"^claude-opus-4-?[6-9]", "Opus 4.6+"),
    (r"^claude-opus-4-?5", "Opus 4.5"),
    (r"^claude-sonnet-4-?[5-9]", "Sonnet 4.5+"),
    (r"^claude-sonnet-4-2025", "Sonnet 4"),
    (r"^claude-haiku-4", "Haiku 4"),
    (r"anthropic/claude-opus-4", "Opus via OpenRouter"),
    (r"anthropic/claude-sonnet-4", "Sonnet via OpenRouter"),
    # === OPENAI ===
    (r"^gpt-5-?mini$", "GPT-5 Mini"),
    (r"^gpt-5-?nano$", "GPT-5 Nano"),
    (r"^gpt-5$", "GPT-5"),
    (r"^gpt-4\.1$", "GPT-4.1 (Fallback)"),
    (r"^gpt-4\.1-mini$", "GPT-4.1 Mini"),
    (r"^o1$", "OpenAI o1"),
    # === GOOGLE ===
    (r"^gemini-2\.5-pro", "Gemini 2.5 Pro"),
    (r"^gemini-2\.5-flash", "Gemini 2.5 Flash"),
    (r"google/gemini-2\.5", "Gemini via OpenRouter"),
    # === DEEPSEEK ===
    (r"^deepseek-v3", "DeepSeek V3"),
    (r"^deepseek-r1$", "DeepSeek R1"),
    (r"deepseek/deepseek-v3", "DeepSeek V3 via OR"),
    (r"deepseek/deepseek-r1", "DeepSeek R1 via OR"),
    # === MISTRAL ===
    (r"^mistral-large", "Mistral Large"),
    (r"mistralai/mistral-large", "Mistral Large via OR"),
    (r"^codestral", "Codestral"),
    # === PERPLEXITY ===
    (r"perplexity/sonar-pro", "Perplexity Sonar Pro"),
    # === LOKAL (Ollama) ===
    (r"^qwen3:8b", "Qwen3 8B"),
    (r"^qwen3-coder:14b", "Qwen3 Coder"),
    (r"^qwen2\.5-coder:14b", "Qwen2.5 Coder (Fallback)"),
    (r"^gemma3:2?7b", "Gemma3 27B"),
    (r"^gemma3:12b", "Gemma3 12B"),
    (r"^deepseek-r1:14b", "DeepSeek R1 14B lokal"),
    (r"^llama3\.2-vision", "Llama Vision"),
    (r"^qwen2\.5-vl", "Qwen2.5 VL"),
    (r"^bge-m3", "bge-m3 Embedding"),
]

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("PRAGMA table_info(model)")
cols = [r[1] for r in cur.fetchall()]
id_i = cols.index("id")
name_i = cols.index("name")
active_i = cols.index("is_active")

cur.execute("SELECT id, name, is_active FROM model")
rows = cur.fetchall()

keep_set = []      # (mid, name, active_now, reason)
delete_set = []    # (mid, name, active_now)

for mid, name, active in rows:
    matched = None
    for pattern, reason in KEEP:
        if re.search(pattern, mid, re.IGNORECASE):
            matched = reason
            break
    if matched:
        keep_set.append((mid, name or "", active, matched))
    else:
        delete_set.append((mid, name or "", active))

print(f"=== BEHALTEN ({len(keep_set)} Modelle) ===", file=sys.stderr)
# Nach Aktiv-Status sortieren (aktive zuerst)
keep_set.sort(key=lambda x: (-x[2], x[3], x[0]))
for mid, name, active, reason in keep_set:
    flag = "✓" if active else "○"
    name_s = (name[:50] + "..") if len(name) > 50 else name
    print(f"  {flag} [{reason:25s}] {mid[:45]:45s} — {name_s}", file=sys.stderr)

print(f"\n=== DEAKTIVIEREN/LOESCHEN ({len(delete_set)} Modelle) ===", file=sys.stderr)
active_delete = [x for x in delete_set if x[2]]
print(f"  davon aktuell AKTIV: {len(active_delete)}", file=sys.stderr)
for mid, name, active in active_delete[:30]:
    name_s = (name[:50] + "..") if len(name) > 50 else name
    print(f"  ✗ {mid[:45]:45s} — {name_s}", file=sys.stderr)
if len(active_delete) > 30:
    print(f"  ... und {len(active_delete)-30} weitere aktive", file=sys.stderr)

print(f"\n=== ZUSAMMENFASSUNG ===", file=sys.stderr)
print(f"  Gesamt:     {len(rows)} Modelle", file=sys.stderr)
print(f"  Behalten:   {len(keep_set)}", file=sys.stderr)
print(f"  Entfernen:  {len(delete_set)}", file=sys.stderr)
print(f"  (davon aktuell aktiv: {len(active_delete)})", file=sys.stderr)

conn.close()
