# Open WebUI Skill

| name | description |
|------|-------------|
| open-webui | Konfiguration und Troubleshooting von Open WebUI - MCP-Server, Tools, Modelle, RAG. |

## Umgebung

- **URL extern:** https://chat.forensikzentrum.com
- **URL intern:** http://192.168.22.90:8080
- **Version:** v0.9.6 (Juni 2026, Image gepinnt)
- **Datenbank:** SQLite (`/app/backend/data/webui.db`)
- **Tools-Verzeichnis:** `/volume1/docker/open-webui/tools/`
- **Compose (aktiv!):** `/volume1/docker/open-webui/docker-compose.yml` (NICHT die `docker-compose.production.yml` im Home-Verzeichnis)
- **Host-Datenpfad:** `/volume1/docker/open-webui/` = `/app/backend/data` (komplettes data-dir gemountet)

---

## MCP-Server Integration

### Konfigurationspfad (WICHTIG!)

```
Admin Settings → External Tools → + (Add Server)
```

**NICHT:** "Admin Panel → Settings → Tools" (das ist falsch!)

### MCP-Server hinzufügen

| Feld | Wert |
|------|------|
| **ID** | z.B. `mcp-custom-tools` |
| **Name** | z.B. `Custom Tools` |
| **Type** | `MCP (Streamable HTTP)` ← WICHTIG! |
| **URL** | `http://192.168.22.90:PORT/mcp` |
| **Auth** | `None` (für lokale Server) |

### Constraints

- **NIEMALS** Type "OpenAPI" für MCP-Server wählen → verursacht Crashes
- **NIEMALS** `/sse` als Endpunkt nutzen → Open WebUI braucht `/mcp`
- **NIEMALS** `path` in der DB-Config setzen für MCP-Server (nur für OpenAPI)

### Bekannte Bugs (v0.7.x)

1. **MCP-Client RuntimeError:** `Attempted to exit cancel scope in a different task`
   - Ursache: Bug im anyio TaskGroup Handling
   - Workaround: Python-Tool als HTTP-Wrapper erstellen (siehe unten)

2. **"'NoneType' object has no attribute 'get'"**
   - Ursache: Falsche MCP-Konfiguration in DB (`path: "openapi.json"`)
   - Fix: `path` auf leer setzen in der config-Tabelle

---

## Workaround: Python-Tool als MCP-Wrapper

Falls native MCP-Integration nicht funktioniert, erstelle ein Python-Tool:

```python
"""
title: MCP Custom Tools
author: Forensikzentrum
version: 1.0
requirements: requests
"""
import requests
import json
from pydantic import Field, BaseModel

class Tools:
    class Valves(BaseModel):
        MCP_SERVER_URL: str = Field(default="http://192.168.22.90:8012/mcp")

    def __init__(self):
        self.valves = self.Valves()
        self._session_id = None

    def _call_mcp(self, method: str, params: dict = None) -> dict:
        headers = {
            "Content-Type": "application/json",
            "Accept": "text/event-stream, application/json"
        }
        # Session initialisieren
        if not self._session_id:
            init = {"jsonrpc": "2.0", "method": "initialize",
                    "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                              "clientInfo": {"name": "openwebui", "version": "1.0"}}, "id": 1}
            resp = requests.post(self.valves.MCP_SERVER_URL, json=init, headers=headers)
            self._session_id = resp.headers.get("mcp-session-id")

        headers["mcp-session-id"] = self._session_id
        payload = {"jsonrpc": "2.0", "method": method, "params": params or {}, "id": 2}
        resp = requests.post(self.valves.MCP_SERVER_URL, json=payload, headers=headers)
        return resp.json()

    def example_tool(self, param: str) -> str:
        result = self._call_mcp("tools/call", {"name": "tool_name", "arguments": {"param": param}})
        # Parse result...
        return str(result)
```

---

## Tool-Registrierung

Tools müssen in der `tool`-Tabelle registriert werden mit:

| Feld | Beschreibung |
|------|--------------|
| `id` | Eindeutige ID (z.B. `mcp_tools`) |
| `name` | Anzeigename |
| `content` | Python-Code |
| `specs` | JSON mit Funktionsdefinitionen für LLM |
| `meta` | Beschreibung und Manifest |

**specs Format:**
```json
[{
  "name": "function_name",
  "description": "Was macht die Funktion",
  "parameters": {
    "type": "object",
    "properties": {
      "param1": {"type": "string", "description": "..."}
    },
    "required": ["param1"]
  }
}]
```

---

## Tool Calling - Modell-Empfehlungen

| Modell | Tool Calling |
|--------|--------------|
| **gpt-4o-mini** | ✅ Stabil, empfohlen |
| **gpt-4o** | ✅ Sehr gut |
| **claude-sonnet-4** | ✅ Sehr gut |
| **qwen2.5:7b** | ⚠️ Instabil |
| **deepseek-coder** | ⚠️ Instabil |

**Empfehlung:** Für Tool Calling immer Cloud-Modelle bevorzugen.

---

## Nützliche Befehle

```bash
# Container Status
docker ps --format "table {{.Names}}\t{{.Status}}" | grep open-webui

# Logs prüfen
docker logs open-webui --tail 50 2>&1 | grep -i -E "(error|mcp|tool)"

# Neustart
docker restart open-webui

# DB-Config prüfen (Python)
python3 << 'EOF'
import sqlite3, json
conn = sqlite3.connect('/volume1/docker/open-webui/webui.db')
cursor = conn.cursor()
cursor.execute("SELECT data FROM config LIMIT 1")
data = json.loads(cursor.fetchone()[0])
print(json.dumps(data.get('tool_server'), indent=2))
EOF
```

---

## Tool-Aktivierung im Chat

So aktivierst du Tools für einen Chat:

1. Öffne einen **neuen Chat**
2. Klicke auf das **⚙️ Zahnrad-Symbol** neben dem Eingabefeld
3. Scrolle zu **Tools**
4. Aktiviere die gewünschten Tools (z.B. "MCP Custom Tools")
5. Wähle ein geeignetes Modell (gpt-4o-mini empfohlen)

**Hinweis:** Tools müssen pro Chat aktiviert werden!

---

## Verfügbare MCP-Server

| Port | Service | Endpunkt |
|------|---------|----------|
| 8012 | mcp-proxy-custom | `/mcp` - Custom Tools (Zeit, Rechner, Netzwerk) |
| 8000 | mcp-proxy-server | `/mcp` - Time Server |

---

## Lokale Audio-Services (TTS/STT)

Diese Services können in Open WebUI als Alternative zu Cloud-Diensten genutzt werden:

| Port | Service | Beschreibung | API |
|------|---------|--------------|-----|
| 8006 | openapi-speechreader | Multi-Provider TTS/STT (Edge, OpenAI, ElevenLabs) | `/api/v2/tts/synthesize` |
| 8007 | faster-whisper | Lokales Whisper large-v3 (STT) | `/v1/audio/transcriptions` |
| 10201 | coqui-tts (piper) | Deutsches TTS (Thorsten) | `/api/tts?text=...` |

### Konfiguration in Open WebUI

**Speech-to-Text (lokal):**
```
Admin Settings → Audio → STT Engine: OpenAI
STT Base URL: http://192.168.22.90:8007/v1
```

**Text-to-Speech (lokal):**
```
Admin Settings → Audio → TTS Engine: OpenAI
TTS Base URL: http://192.168.22.90:8006/api/v2
```

---

## Gelernte Lektionen

### 2026-01-14 - MCP Integration Session

- Native MCP-Integration in v0.7.x ist buggy → Python-Wrapper nutzen
- MCP-Config in DB darf kein `path` haben
- Tool-Registrierung erfordert `specs` JSON
- Lokale Modelle schlecht für Tool Calling

### 2026-02-04 - Moonshot API & SQLite Config-Struktur

**Moonshot (Kimi K2.5) als OpenAI-kompatible Verbindung hinzufügen:**
- Moonshot API ist OpenAI-kompatibel: `https://api.moonshot.cn/v1`
- Liegt NICHT in separater Tabelle, sondern in `config.data.openai`
- Format: `api_base_urls` + `api_keys` als parallele Arrays
- `api_configs` enthält pro Index: `enable`, `prefix_id`, `tags`

**SQLite-Manipulation für neue API-Verbindung:**
```python
import sqlite3, json
conn = sqlite3.connect('/volume1/docker/open-webui/webui.db')
cur = conn.cursor()
cur.execute('SELECT data FROM config WHERE id=1')
data = json.loads(cur.fetchone()[0])

# Neue Verbindung hinzufügen
openai = data.get('openai', {})
openai['api_base_urls'].append("https://api.moonshot.cn/v1")
openai['api_keys'].append("sk-xxx")
idx = str(len(openai['api_base_urls']) - 1)
openai['api_configs'][idx] = {"enable": True, "prefix_id": "moonshot", "tags": []}
data['openai'] = openai

cur.execute('UPDATE config SET data=? WHERE id=1', (json.dumps(data),))
conn.commit()
```

**models.json ist Referenz-Dokument:**
- Wird NICHT von Open WebUI gelesen
- Dient zur Dokumentation: lokale vs. externe Modelle
- Enthält Benchmarks, Pricing, Context-Länge
- Format: `{"models": {"local": [...], "external": [...]}}`

**Kimi K2.5 Spezifikationen:**
- 1T Parameter (MoE), 32B aktiv
- Context: 262K tokens, Output: 33K tokens
- Benchmarks: MMLU 92%, HumanEval 99%, MATH 98%
- Pricing: $0.60/$2.50 per 1M tokens
- Features: Agent Swarm (100 parallele Sub-Agents), Thinking-Mode

### 2026-02-05 - Z.AI Provider + API-Präferenz

**Z.AI (Zhipu AI) als neuer Provider:**
- API-Base: `https://api.z.ai/api/paas/v4`
- OpenAI-kompatibel → gleiche SQLite-Struktur wie Moonshot
- Prefix: `zai`

**GLM-Modelle über Z.AI:**
| Modell | Preis | Context | Besonderheit |
|--------|-------|---------|--------------|
| GLM-4.7-Flash | **KOSTENLOS** | 200K | Empfohlen für Tests |
| GLM-4.7-FlashX | $0.07/$0.40 | 200K | Schneller |
| GLM-4.7 | $0.60/$2.20 | 200K | Flagship |

**Präferenz: API statt Lokal bei großen Modellen:**
- Modelle >10GB auf CPU-only NAS sind zu langsam (~4-5 tok/s)
- GLM-4.7-Flash lokal (19GB): ~4 tok/s ❌
- GLM-4.7-Flash API: sofort ✅
- **Faustregel:** Alles >8GB → API nutzen

**Aktive API-Provider (Stand 02/2026):**
| Provider | Prefix | API-Base |
|----------|--------|----------|
| OpenAI | - | api.openai.com/v1 |
| Moonshot | moonshot | api.moonshot.cn/v1 |
| Z.AI | zai | open.bigmodel.cn/api/paas/v4 |
| OpenRouter | openrouter | openrouter.ai/api/v1 |
| Anthropic | anthropic | api.anthropic.com |
| Google | - | generativelanguage.googleapis.com |

### 2026-04-01 - Kimi-free-api als lokale OpenAI Connection

**Kimi-free-api hinzugefügt (Index 4):**
- URL: `http://192.168.22.90:8011/v1`
- Prefix: `kimi-local`
- Braucht refresh_token von kimi.ai Browser (JWT, nicht sk-Key)
- GET auf `/v1` liefert Fehler `-1000` — ist normal, nur POST-Endpoints aktiv
- `/v1/models` funktioniert korrekt (5 Modelle: moonshot-v1, -8k, -32k, -128k, -vision)

**DB-Config für OpenAI Connections (sqlite3 Kurzform):**
```bash
# Alle OpenAI-Connections anzeigen
sqlite3 /volume1/docker/open-webui/webui.db \
  "SELECT json_extract(data, '$.openai.api_base_urls') FROM config WHERE id=1;"

# Neue Connection per json_set hinzufügen
sqlite3 /volume1/docker/open-webui/webui.db \
  "UPDATE config SET data = json_set(data, '$.openai', json('...')) WHERE id=1;"
```

**VOR dem Hinzufügen neuer Connections IMMER prüfen ob bereits konfiguriert!**
Moonshot war z.B. schon als Index 1 vorhanden.

### 2026-02-05 - Ollama API & OpenRouter Setup

**Ollama API-Endpunkte (WICHTIG!):**
```
❌ /models         → 404 Not Found
✅ /api/tags       → Model-Liste
✅ /api/chat       → Chat-Anfragen
✅ /               → Health-Check ("Ollama is running")
```

**Zhipu AI (GLM) funktioniert NICHT für Deutschland:**
- open.bigmodel.cn erfordert chinesische Telefonnummer/Zahlung
- **Alternative: OpenRouter** (openrouter.ai)
- Zahlung mit Kreditkarte/PayPal möglich
- Hat GLM-4 und 200+ andere Modelle

**OpenRouter Konfiguration:**
```python
# In Open WebUI SQLite config hinzufügen:
openai['api_base_urls'].append('https://openrouter.ai/api/v1')
openai['api_keys'].append('sk-or-v1-...')
openai['api_configs'][str(idx)] = {
    "enable": True,
    "prefix_id": "openrouter",
    "tags": [],
    "connection_type": "external"
}
```

**OpenRouter Model-Namen:**
- `openrouter.openai/gpt-4o-mini`
- `openrouter.anthropic/claude-3.5-sonnet`
- `openrouter.thudm/glm-4-plus` (GLM-4!)
- `openrouter.google/gemini-2.0-flash-001`

**Zhipu Model-Namen Mapping (falls Guthaben vorhanden):**
| Open WebUI | Zhipu API (echt) |
|------------|------------------|
| zai.glm-4.7 | glm-4-plus |
| zai.glm-4.6 | glm-4-0520 |
| zai.glm-4.5-air | glm-4-air |

**Browser-Warnungen ignorieren:**
- `ResponseMessage.svelte passive event listener` = Frontend-Code
- Nicht konfigurierbar, keine Funktionsstörung

---

### 2026-04-19 — API-Keys Setup + Modell-Bereinigung via DB (v0.8.12)

**API-Key 403-Bug (KRITISCH):**
- `auth.api_key.enable=true` UND `auth.api_key.endpoint_restrictions=false`
- Wenn `endpoint_restrictions=true` + `allowed_endpoints=""` → ALLE Endpoints geben 403 (nicht nur die eingeschränkten)
- Check im Admin Panel: Settings → General → „API-Schluessel aktivieren" ON + „Erlaubte Endpunkte" LEER
- Notfall-Fix direkt in DB: `config.data` JSON patchen (siehe `fix-api-config.py` im Repo)

**api_key Tabelle (v0.8+):**
- Nicht mehr in `user`-Tabelle — eigene `api_key` Tabelle
- Schema: `id, user_id, key, data, expires_at, last_used_at, created_at, updated_at`
- data = JSON mit `{name, scopes}`
- Insert via: UUID id, user.id von email-lookup, `sk-<48 random>`-Key

**JWT-Ablauf `-1` (SECURITY-RISIKO):**
- Default in v0.8.12 = JWTs laufen NIE ab
- Admin Panel: JWT-Ablauf auf `7d` oder `24h` setzen
- Secret-Key Rotation invalidiert alle JWTs: `docker exec open-webui rm /app/backend/data/webui_secret_key && docker restart open-webui`

**sqlite3 fehlt im Container:**
- `docker exec open-webui sqlite3` → not found
- Nutze Python built-in: `docker exec open-webui python3 -c "import sqlite3; ..."`
- Script via `docker cp` rein, dann `docker exec python3 /tmp/script.py`

**Modell-Bereinigung via DB:**
- `model`-Tabelle Spalten: `id, user_id, base_model_id, name, meta, params, created_at, updated_at, is_active`
- `is_active` = 0/1 (Integer, nicht Boolean)
- Bulk-Update: `UPDATE model SET is_active=0` dann selektiv `is_active=1` fuer KEEP-Liste
- Model-Card meta JSON: `{description, capabilities:{vision,usage,citations}, tags:[{name}], suggestion_prompts:[{content}]}`
- Name mit Icon + Vergleichs-Hinweis: `"✦ Claude Opus 4.7"`

**Modell-IDs (April 2026):**
- Anthropic: `claude-opus-4.5`, `claude-sonnet-4.6`, `claude-haiku-4.5` (direct)
- OR-Proxy: `openrouter.anthropic/claude-opus-4.7` (neueste)
- OpenAI: `gpt-5`, `gpt-5-mini`, `gpt-5-nano`, `o1`
- Google: `openrouter.google/gemini-2.5-pro-preview` (1M Kontext)

**Knowledge Collection via API:**
- POST `/api/v1/files/` (multipart) → file_id
- POST `/api/v1/knowledge/{id}/file/add` mit `{file_id}`
- Auth-Check: GET `/api/v1/knowledge/` (NICHT `/api/v1/auths/` — die ignoriert Bearer-Auth)

**DB-Backup vor Bulk-Changes:**
```bash
docker exec open-webui cp /app/backend/data/webui.db /app/backend/data/webui.db.backup.$(date +%s)
```

### 2026-04-19 — Knowledge-File API-Bug in v0.8 (KRITISCH)

**Problem:**
- `POST /api/v1/knowledge/{coll_id}/file/add` mit `{file_id}` → returns 200
- ABER: `knowledge_file` Tabelle bleibt LEER → Files werden im Chat nicht eingebunden
- Symptom: Collection zeigt "25 Files" aber Chat findet nichts, weil RAG-Lookup ueber knowledge_file geht

**Lösung: Direkte DB-Manipulation**
```python
# 1. Bestehende Links loeschen
cur.execute("DELETE FROM knowledge_file WHERE knowledge_id = ?", (coll_id,))
# 2. Neu einfuegen
for fid in file_ids:
    cur.execute("""
        INSERT INTO knowledge_file (id, user_id, knowledge_id, file_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (str(uuid.uuid4()), coll_user_id, coll_id, fid, now, now))
# 3. knowledge.data.file_ids synchron halten
data["file_ids"] = file_ids
cur.execute("UPDATE knowledge SET data = ? WHERE id = ?", (json.dumps(data), coll_id))
```
Script: `tools/open-webui-sync/link-files-to-collection.py` im claude-skills Repo.

**File-Deduplication:**
- Multiple Uploads gleicher filename → mehrere `file` rows (eindeutige IDs)
- Pro filename nur die juengste nehmen: `ORDER BY created_at DESC` + `seen = set()`
- Sonst wird Content mehrfach indiziert

**RAG-Engine Check:**
- Embedding Engine = `ollama` mit `bge-m3:latest` (NICHT SentenceTransformers default!)
- `openai_api_key` ist gesetzt (wird aber nicht genutzt wenn engine=ollama)
- Chunks werden LAZY beim ersten Chat-Query generiert — Erstabruf dauert 10-30s

**Knowledge im Chat aktivieren:**
- Per Chat: `+`-Icon → "Knowledge" → Collection waehlen
- Besser: Custom Model mit `Knowledge: Claude Skills` verknuepfen → automatisch bei jedem Chat
- `#Collection-Name` Syntax funktioniert nur wenn Knowledge bereits im aktuellen Chat aktiv ist

**Erfolg-Check via DB:**
```sql
SELECT COUNT(*) FROM knowledge_file;          -- > 0 = Files verknuepft
SELECT name, json_array_length(json_extract(data, '$.file_ids')) FROM knowledge;  -- Anzahl IDs pro Collection
```

---

## 2026-05-17 — Empfohlene OpenAPI-Tools für Sprachabfragen

Diese FastAPI-Services laufen bereits auf der NAS und eignen sich direkt als External Tool in Open WebUI:

| Service | URL | Hauptzweck |
|---|---|---|
| **openapi-docker-health** | `http://192.168.22.90:8009` | `/containers/health` liefert `{up, total, problems[]}` — ideal für Sprachabfragen „Läuft alles?", „Welche Container haben Probleme?" |
| openapi-weather | `http://192.168.22.90:8005` | Wetter |
| openapi-filesystem | `http://192.168.22.90:8003` | Dateisystem-Zugriff |
| openapi-memory | `http://192.168.22.90:8004` | Chat-Memory |
| openapi-speechreader | `http://192.168.22.90:8006` | TTS via SpeechReader |
| fem-pipeline | `http://192.168.22.90:8746` | PPTX→Video-Pipeline (Pflege-Lehre) |
| pptx-audio-service | `http://192.168.22.90:8745` | PPTX-Text/Audio-Embed |

**Wichtig:** Alle haben **keine Root-Route** (`GET /` → 404). Das ist normal und KEIN Bug — Open WebUI registriert die Tools über `/openapi.json`. Manuell prüfen: `curl http://.../openapi.json | jq .paths`.

**Registrierungs-Pattern:**
```
Admin Settings → External Tools → + (Add Server)
  Type: OpenAPI         ← NICHT MCP!
  URL:  http://192.168.22.90:PORT
  Auth: None
```

---

### 2026-06-29 — Full-Config-Review: Reboot-Port-Leak, DB-Cleanup, Modernisierung (v0.9.6)

**Reboot-Port-Leak (KRITISCH, wiederkehrend):**
- Nach NAS-Reboot hingen `ollama` (`created`) und `searxng` (`exited 255`) → `Bind for 0.0.0.0:PORT failed: port is already allocated`.
- Folge: RAG-Embeddings (bge-m3), lokale Modelle UND Websuche komplett tot — OWUI selbst war `healthy`, Fehler nur in den Backends.
- Diagnose: `docker inspect <c> --format '{{.State.Error}}'`; `sudo ss -tlnp | grep :PORT` zeigt verwaisten `docker-proxy`.
- Fix: verwaisten Proxy `sudo kill <pid>` + `docker start <c>`. Hält der Daemon die Allokation trotz freiem Port (überlebt `compose down/up`!) → Host-Port im Compose ummappen (searxng 8081→8087) ODER Daemon-Neustart.
- **Wichtig:** OWUI erreicht ollama/searxng nur über das Docker-Netz (`ollama:11434`, `searxng:8080`), NICHT über den Host-Port → Host-Port-Remap bricht die Funktion nicht.

**DB-Bloat-Quelle = Chat-Verlauf mit Inline-Bildern:**
- `webui.db` war 198 MB; `dbstat` zeigte: `chat` 76 MB + `chat_message` 38 MB (base64-DALL-E-Bilder inline), NICHT `model` (473 Zeilen = nur 0,2 MB, davon 19 aktiv → UI bleibt sauber, kein Cleanup nötig).
- VACUUM (Container stoppen!) → 198 → 122 MB. WAL vorher checkpointen: `PRAGMA wal_checkpoint(TRUNCATE)`.
- Tabellen-Größen messen: `SELECT name, SUM(pgsize) FROM dbstat GROUP BY name ORDER BY 2 DESC`.

**Backup-Müll im Live-data-dir:**
- `/app/backend/data/backups/` hatte 2,4 GB alte DB-Snapshots + 3 alte `webui.db.backup.*/.bak` (387 MB) im Root. Insgesamt ~2,8 GB. Vor dem Löschen 1 frische Kopie AUSSERHALB des data-dir ablegen (sonst scannt OWUI sie wieder mit).

**Tote OpenAI-Connections entfernen (Index-Reindex beachten!):**
- `zai` (open.bigmodel.cn — geht aus DE nicht) und `kimi-local` (8011, Container down) entfernt.
- Beim Löschen aus `config.data.openai`: `api_base_urls`, `api_keys` UND `api_configs` (dict mit String-Keys) parallel neu aufbauen und durchnummerieren — sonst zeigen die `api_configs`-Indizes auf falsche URLs. Script: scratchpad `owui_dbfix.py`-Muster.

**Modernisierung Juni 2026 (Keys können es):**
- OpenAI-Key: bis `gpt-5.4` (März 2026). Anthropic-Key: `claude-opus-4-8`, `claude-sonnet-4-6`, `claude-haiku-4-5`, `claude-fable-5`.
- Verfügbare Modelle prüfen: `curl -s https://api.openai.com/v1/models -H "Authorization: Bearer $(cat /run/secrets/openai_api_key)"` (im Container).
- Compose angepasst: `DEFAULT_MODELS` gpt-4.1→`gpt-5`, `TASK_MODEL_EXTERNAL` gpt-4.1-mini→`gpt-5-nano`, `TASK_MODEL` qwen2.5:14b→`qwen3:4b`, `ENABLE_FOLLOW_UP_GENERATION=true`.
- **Image pinnen:** `:latest`→`:v0.9.6` (kein Auto-Pull-Risiko).
- `DEFAULT_MODELS` muss auf ein **aktives** Modell zeigen (sonst keine Vorauswahl).

**ENV vs DB — Drift-Falle:**
- Nach dem ersten Boot gewinnt die DB-Config, ENV-Werte werden ignoriert → ENV kann irreführend sein (`WEB_SEARCH_RESULT_COUNT=8` in ENV, aber DB=3 aktiv). Echte Werte immer in der `config`-Tabelle prüfen, nicht im `env`.
- Veraltete Leftover-ENV entfernt: `USER_AGENT=OpenWebUI/0.8.2`. `SEARXNG_QUERY_URL` braucht `&format=json`.

**SAFE_MODE vs Functions:**
- `SAFE_MODE=true` deaktiviert die Ausführung von Pipe/Filter-Functions. Hier unkritisch, weil alle 4 Functions ohnehin `is_active=0` sind. Wenn Functions genutzt werden sollen → `SAFE_MODE=false`.

---

### 2026-06-29 — n8n-Pipe als Modell, RBAC (access_grant), Provider-Health (v0.9.6)

**Function/Pipe aktivieren — `SAFE_MODE` ist der erste Blocker:**
- `SAFE_MODE=true` (Compose) deaktiviert beim Start **ALLE** Functions/Pipes (Banner „SAFE MODE ENABLED", setzt `function.is_active=0`). Für n8n-Pipe/AutoTool zwingend `SAFE_MODE=false`. Vertretbar nur bei Single-Admin + Signup aus.

**n8n-Pipe (owndev v2.0.0) als Chat-Modell anbinden — die 4 Stolpersteine:**
1. SAFE_MODE (s.o.).
2. Valves zeigten auf **Test-Webhook** (`/webhook-test/<id>`, feuert nur 1× pro Listen-Klick) → auf **Production** `/webhook/<path>` umstellen. Workflow muss in n8n `active` sein.
3. Single-Pipe (keine `pipes()`-Methode) → Modell-ID = **Function-ID** (`n8n_pipeline`), Name = Function-Name. Wird in `get_function_models()` mit `owned_by:'openai'` gebaut.
4. **KRITISCH & nicht offensichtlich:** existiert in der `model`-Tabelle eine Zeile mit derselben ID auf `is_active=0` (z.B. Altlast aus Modell-Bereinigung), wird das Pipe-Modell **unterdrückt** und taucht NICHT in `/api/models` auf — trotz aktiver Function. Fix: `UPDATE model SET is_active=1, name='…' WHERE id='<function_id>'`.
- Contract-Check des n8n-Webhooks ist Pflicht: `responseMode=responseNode` + Respond-Node der `{output}` liefert + liest `chatInput`/`message`. Nur dann passt das Pipe-Default (`INPUT_FIELD=chatInput`, `RESPONSE_FIELD=output`). HTML- oder `lastNode`-Workflows sind NICHT chat-förmig.
- Medifox-Chat-Endpoint: `https://n8n.forensikzentrum.com/webhook/rag-chat-api` (Guard-Key `x-rag-key` leer = offen). End-to-end via `/api/chat/completions` mit `model=n8n_pipeline` testen.

**RBAC in v0.9.6 = Tabelle `access_grant` (NICHT mehr `model.access_control`!):**
- Spalten: `resource_type, resource_id, principal_type, principal_id, permission`. `principal_type='user', principal_id='*'` = alle User (öffentlich). Kein Grant + nicht Owner/Admin = unsichtbar.
- Gruppen: Tabelle `"group"` (kein `user_ids`-Feld!) + Mitgliedschaft in `group_member` (group_id/user_id).
- **Achtung:** Berechtigungs-/Grant-Änderungen werden vom Auto-Mode-Klassifizierer geblockt → vorher explizit freigeben lassen.

**Provider-Health & Default-Modell:**
- `ui.default_models` in der DB-`config` **überschreibt** das ENV `DEFAULT_MODELS` (Drift). Default war `qwen2.5:7b` (nicht mal gepullt). Echten Default in der DB setzen.
- Key-Status live prüfen (im Container, Secrets aus `/run/secrets/...`): OpenAI `/v1/models` listet auch ohne Guthaben — echter Quota-Test nur über `/v1/embeddings` oder `/v1/chat/completions` (Fehler `insufficient_quota`).
- Claude-Modelle laufen hier über **OpenRouter** (`openrouter.anthropic/claude-*`), nicht über die native Anthropic-Function (die ist inaktiv). OpenRouter-Test-ID: `anthropic/claude-sonnet-4.6`.

**Document Extraction:**
- `content_extraction` stand bereits auf **`mistral_ocr`** (nicht Default-pypdf!) — für gescannte Pflege-Docs besser als Tika. NICHT blind auf Tika wechseln. Mistral-Key-Health separat prüfen.

**num_ctx-Falle:** lokale Ollama-Modell-Cards hatten leere `params` → Default-Kontext 2048 schneidet RAG/Websuche lautlos ab. `params.num_ctx=8192` pro Modell setzen.

---

### 2026-06-29 — STT/TTS komplett lokal (speaches :8007) + RBAC-Pending (v0.9.6)

**`speaches`-Server auf :8007 ist OpenAI-kompatibel für BEIDES (STT *und* TTS):**
- Ein einziger Base-URL deckt alles: `http://192.168.22.90:8007/v1` (von OWUI-Container aus erreichbar via Host-IP — getestet, NICHT über Docker-Netz nötig).
- STT: `POST /v1/audio/transcriptions` (Modell `Systran/faster-whisper-large-v3`, geladen). TTS: `POST /v1/audio/speech` (OpenAI-Schema `{model,input,voice,response_format}`).
- Modelle on-demand laden: `POST /v1/models/{model_id}` — **Slash im model_id URL-encoden** (`%2F`). Liste: `GET /v1/registry?task=text-to-speech` (146 TTS-Einträge), geladene Stimmen: `GET /v1/audio/voices`.
- **Deutsche TTS = Piper**, nicht Kokoro (Kokoro kann KEIN Deutsch — nur en/es/fr/it/pt/ja/zh/hi). Installiert: `speaches-ai/piper-de_DE-thorsten-medium` → Stimme `thorsten`. Weitere DE: thorsten-high, `ufozone/piper-de_DE-jarvis-high`, eva_k, kerstin, ramona.
- `openapi-speechreader` :8006 hat zwar exzellente Edge-TTS-DE-Stimmen (Katja/Conrad…), ist aber NICHT OpenAI-kompatibel (`/api/v2/...`, kein `/audio/speech`) → von OWUIs `openai`-Engine nicht direkt nutzbar.

**OWUI-Audio-Config (DB `config.data.audio`) für lokal:**
```
stt: engine='openai', model='Systran/faster-whisper-large-v3',
     openai.api_base_url='http://192.168.22.90:8007/v1', openai.api_key='local'
tts: engine='openai', model='speaches-ai/piper-de_DE-thorsten-medium', voice='thorsten',
     openai.api_base_url='http://192.168.22.90:8007/v1', openai.api_key='local'
```
- OWUI hängt bei `openai`-Engine selbst `/audio/transcriptions` bzw. `/audio/speech` an die Base-URL an → Base muss auf `…/v1` enden.
- **Klartext-OpenAI-Key lag in `audio.stt/tts.openai.api_key`** (DB) — beim Umstieg durch `'local'` ersetzen.
- End-to-End-Test durch OWUI: API-Key aus Tabelle `api_key` holen, `POST /api/v1/audio/speech` (TTS) + `POST /api/v1/audio/transcriptions` (STT, multipart `file=@…;type=audio/mpeg`).

**DB-Edit-Race (KRITISCH, kostet sonst Stunden):**
- `webui.db` editieren während der Container LÄUFT → OWUI flusht beim Neustart seine In-Memory-`PersistentConfig` ZURÜCK über den Edit → Änderung weg.
- Richtiger Ablauf IMMER: `docker stop open-webui` → `PRAGMA wal_checkpoint(TRUNCATE)` + Edit der Host-DB (`/volume1/docker/open-webui/webui.db`) → `docker start`. Host-DB ist chmod 777, direkt mit Host-`python3` editierbar.

**Heredoc-Falle in dieser Umgebung:**
- `docker exec open-webui python3 - <<'EOF'` schluckt den **stdout** (kein Output, obwohl Script läuft). Für Diagnose `docker exec open-webui python3 -c "…"` nutzen; für Host-Edits `python3 - <<PY` (Host, nicht via docker exec) funktioniert.

**RBAC-Pending — exakter Key:**
- Pending-Freigabe = `ui.enable_signup=true` + **`ui.default_user_role='pending'`** (NICHT `user.default_role` — das ist leer/irreführend). Neue Signups landen in Rolle `pending`, sehen nichts bis Admin sie auf `user` hebt.
- Pending-User-Begrüßung: `ui.pending_user_overlay_title` / `ui.pending_user_overlay_content` — standardmäßig LEER → neu Registrierte sehen blanken Screen. Mit Text füllen.
- Modell-Sichtbarkeit = Tabelle `access_grant` (`model/user/*/read` = öffentlich); hier bewusst für alle gelassen (6 lokal + 14 paid Cloud). Grant-Änderungen brauchen explizite Freigabe (Auto-Mode blockt).
