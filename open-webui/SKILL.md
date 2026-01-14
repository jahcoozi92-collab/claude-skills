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

## Verfügbare MCP-Server

| Port | Service | Endpunkt |
|------|---------|----------|
| 8012 | mcp-proxy-custom | `/mcp` - Custom Tools (Zeit, Rechner, Netzwerk) |
| 8000 | mcp-proxy-server | `/mcp` - Time Server |

---

## Gelernte Lektionen

### 2026-01-14 - MCP Integration Session

- Native MCP-Integration in v0.7.x ist buggy → Python-Wrapper nutzen
- MCP-Config in DB darf kein `path` haben
- Tool-Registrierung erfordert `specs` JSON
- Lokale Modelle schlecht für Tool Calling
