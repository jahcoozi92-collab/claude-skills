# Open WebUI Skill

| name | description |
|------|-------------|
| open-webui | Konfiguration und Troubleshooting von Open WebUI - MCP-Server, Tools, Modelle, RAG. |

## Umgebung

- **URL extern:** https://chat.forensikzentrum.com
- **URL intern:** http://192.168.22.90:8080
- **Version:** v0.7.2
- **Datenbank:** SQLite (`/app/backend/data/webui.db`)
- **Tools-Verzeichnis:** `/volume1/docker/open-webui/tools/`

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
| Z.AI | zai | api.z.ai/api/paas/v4 |
| Anthropic | anthropic | api.anthropic.com |
| Google | - | generativelanguage.googleapis.com |
