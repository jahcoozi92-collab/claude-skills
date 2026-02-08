# n8n-Workflow Skill – Automatisierung für Diana

| name | description |
|------|-------------|
| n8n-workflow | Hilft bei der Erstellung, Debugging und Optimierung von n8n-Workflows. Optimiert für Diana's Setup mit NAS, Supabase, NextCloud und RAG-Systemen. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Stell dir vor, du musst jeden Tag die gleichen Aufgaben machen:
1. Email checken
2. Wenn wichtige Email → in Ordner speichern
3. Chef benachrichtigen

Das ist langweilig und du könntest Fehler machen. n8n ist wie ein Roboter, der diese Aufgaben automatisch für dich erledigt. Du sagst ihm einmal, was er tun soll, und er macht es immer wieder – ohne müde zu werden!

---

## Diana's n8n-Setup

### Server-Informationen

| Eigenschaft | Wert |
|-------------|------|
| **Host** | NAS @ 192.168.22.90 |
| **Port** | Standard n8n Port |
| **Läuft in** | Docker Container |
| **Webhook-Domain** | Muss konfiguriert sein |

### Verbundene Systeme

| System | Credential-Name | Zweck |
|--------|-----------------|-------|
| **Supabase** | `supabaseApi` | Datenbank + Vektoren |
| **NextCloud** | `nextCloudApi` | Dateispeicher |
| **OpenAI** | `openAiApi` | Embeddings + Chat |
| **Anthropic** | `anthropicApi` | Claude LLMs |
| **Cohere** | `cohereApi` | Reranking |
| **Mistral** | `mistralCloudApi` | OCR + LLM |
| **PostgreSQL** | `postgres` | Direkter DB-Zugriff |

### n8n API-Zugriff

```bash
# API-Anfragen an n8n
curl -H "X-N8N-API-KEY: <jwt-token>" \
  "http://localhost:5678/api/v1/workflows"

# Workflow-Details abrufen
curl -H "X-N8N-API-KEY: <jwt-token>" \
  "http://localhost:5678/api/v1/workflows/<workflow-id>"

# Executions abfragen
curl -H "X-N8N-API-KEY: <jwt-token>" \
  "http://localhost:5678/api/v1/executions?workflowId=<id>&limit=10"
```

---

## Workflow-Grundlagen (für Anfänger)

### Was ist ein Workflow?

**Analogie:**
Ein Workflow ist wie ein Dominosteine-Parcours:
- Du stößt den ersten Stein an (Trigger)
- Jeder Stein stößt den nächsten an (Nodes)
- Am Ende passiert etwas Cooles (Ergebnis)

### Die wichtigsten Begriffe

| Begriff | Bedeutung | Beispiel |
|---------|-----------|----------|
| **Trigger** | Der Auslöser | "Wenn eine Email kommt..." |
| **Node** | Ein Arbeitsschritt | "...extrahiere den Text..." |
| **Connection** | Verbindung zwischen Nodes | "...und speichere es..." |
| **Execution** | Eine Ausführung | "...in der Datenbank" |
| **Credential** | Zugangsdaten | API-Keys, Passwörter |

---

## Trigger-Typen

### 1. Webhook (empfängt Daten von außen)

**Für 12-Jährige:**
Wie eine Türklingel. Wenn jemand klingelt (Daten sendet), startet der Workflow.

```
┌─────────────────┐
│  Webhook Node   │ ← Andere Systeme senden hierher
│  /webhook/xyz   │
└────────┬────────┘
         ↓
    [Verarbeitung]
```

**🔴 WICHTIG für Diana:**
- Nutze **Webhook Node**, NICHT HTTP Request für eingehende Daten
- HTTP Request ist für ausgehende Anfragen

### 2. Schedule (zeitgesteuert)

**Für 12-Jährige:**
Wie ein Wecker. Jeden Tag um 8 Uhr morgens startet der Workflow.

```
┌─────────────────┐
│  Schedule Node  │ ← "Jeden Tag um 8:00"
│  Cron: 0 8 * *  │
└────────┬────────┘
         ↓
    [Verarbeitung]
```

### 3. Manuell (zum Testen)

```
┌─────────────────┐
│  Manual Trigger │ ← Du klickst "Execute"
└────────┬────────┘
         ↓
    [Verarbeitung]
```

### 4. Chat-Trigger (für KI-Agenten)

```
┌─────────────────┐
│  Chat Trigger   │ ← Benutzer sendet Nachricht
│  (LangChain)    │
└────────┬────────┘
         ↓
    [KI-Agent]
```

### 5. Webhook mit HTML-UI Response

**Pattern:** Webhook liefert vollständige Chat-Oberfläche

```
┌─────────────────┐     ┌─────────────────┐
│     Webhook     │────▶│ Respond to      │
│ responseMode:   │     │ Webhook (HTML)  │
│ responseNode    │     │                 │
└─────────────────┘     └─────────────────┘
```

**Beispiel:** `/webhook/medifox-chat` liefert komplette Chat-UI

---

## KI-Agent Pattern (LangChain)

### Architektur eines KI-Agenten in n8n

```
┌─────────────────────────────────────────────────────────┐
│                      KI-AGENT                           │
│  ┌─────────────┐                                        │
│  │ Chat Model  │ (GPT-4o, Claude Sonnet, etc.)          │
│  └──────┬──────┘                                        │
│         │                                               │
│  ┌──────┴──────┐                                        │
│  │    Agent    │◀──────────────────────────┐            │
│  └──────┬──────┘                           │            │
│         │                                  │            │
│  ┌──────┴──────────────────────────────────┴──────┐     │
│  │                    TOOLS                        │     │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────────────┐   │     │
│  │  │Postgres │ │HTTP Req │ │Vector Store     │   │     │
│  │  │Tool     │ │Tool     │ │(retrieve-as-tool)│  │     │
│  │  └─────────┘ └─────────┘ └────────┬────────┘   │     │
│  └───────────────────────────────────┼────────────┘     │
│                                      │                  │
│                               ┌──────┴──────┐           │
│                               │  Reranker   │           │
│                               │  (Cohere)   │           │
│                               └──────┬──────┘           │
│                                      │                  │
│                               ┌──────┴──────┐           │
│                               │  Embeddings │           │
│                               │  (OpenAI)   │           │
│                               └─────────────┘           │
└─────────────────────────────────────────────────────────┘
```

### Komponenten

| Komponente | Node-Typ | Funktion |
|------------|----------|----------|
| **Chat Model** | lmChatOpenAi / lmChatAnthropic | LLM für Antworten |
| **Agent** | agent (LangChain) | Orchestriert Tools |
| **Tools** | postgresTool, httpRequestTool | Aktionen ausführen |
| **Vector Store** | vectorStoreSupabase | RAG-Retrieval |
| **Reranker** | rerankerCohere | Ergebnisse sortieren |
| **Embeddings** | embeddingsOpenAi | Text → Vektoren |
| **Memory** | memoryBufferWindow | Konversations-History |

---

## Diana's Standard-Workflows

### 1. PDF zu RAG Pipeline

**Zweck:** PDFs aus NextCloud verarbeiten und in Supabase speichern

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ Webhook  │──▶│ NextCloud│──▶│ PDF      │──▶│ Text     │
│ (trigger)│   │ Download │   │ Extract  │   │ Splitter │
└──────────┘   └──────────┘   └──────────┘   └────┬─────┘
                                                  │
┌──────────┐   ┌──────────┐   ┌──────────┐       │
│ Supabase │◀──│ Embedding│◀──│ Ollama   │◀──────┘
│ Insert   │   │ Store    │   │ Embeddings│
└──────────┘   └──────────┘   └──────────┘
```

**Nodes im Detail:**

1. **Webhook** (Trigger)
   - Method: POST
   - Path: `/process-pdf`
   
2. **NextCloud Node**
   - Credential: `nextcloud-nas`
   - Operation: Download File
   
3. **Extract from File**
   - Operation: PDF to Text
   
4. **Text Splitter**
   - Chunk Size: 1000
   - Chunk Overlap: 200
   
5. **Embeddings Ollama**
   - Model: nomic-embed-text (oder mxbai-embed-large)
   
6. **Supabase**
   - Credential: `supabase-prod`
   - Operation: Insert
   - Table: documents

### 2. Automatische Dokumenten-Klassifizierung

**Zweck:** Neue Dokumente in NextCloud kategorisieren

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ Schedule │──▶│ NextCloud│──▶│ IF Empty │──▶│ AI       │
│ (1x/Std) │   │ List New │   │ → Stop   │   │ Classify │
└──────────┘   └──────────┘   └──────────┘   └────┬─────┘
                                                  │
┌──────────┐   ┌──────────┐                       │
│ NextCloud│◀──│ Move to  │◀──────────────────────┘
│ Move     │   │ Folder   │
└──────────┘   └──────────┘
```

---

## Constraints – Was ich IMMER beachten muss

### 🔴 NIEMALS (Aus Fehlern gelernt)

1. **NIEMALS** HTTP Request Node für eingehende Daten
   - ✅ Richtig: Webhook Node
   - ❌ Falsch: HTTP Request Node

2. **NIEMALS** Credentials erraten
   - ✅ Richtig: `supabase-prod`, `nextcloud-nas`
   - ❌ Falsch: `Supabase`, `NextCloud`

3. **NIEMALS** Credentials im Workflow-JSON speichern
   - Immer Credential-Referenzen nutzen

4. **NIEMALS** synchrone Verarbeitung für große Dateien
   - Nutze Batch-Processing oder Queues

5. **NIEMALS** CORS auf eine spezifische Domain setzen bei n8n Webhook-HTML!
   ```
   ❌ FALSCH: access-control-allow-origin: https://n8n.forensikzentrum.com
      → n8n setzt Content-Security-Policy: sandbox (OHNE allow-same-origin)
      → Seiten-Origin wird zu "null" → CORS-Mismatch → fetch schlägt fehl!

   ✅ RICHTIG: access-control-allow-origin: *
      → Einzige Option weil sandbox-CSP die Origin immer auf "null" setzt
      → n8n's sandbox-CSP ist nicht konfigurierbar
   ```

6. **NIEMALS** annehmen dass Supabase Delete-Nodes Daten weiterreichen!
   ```
   ❌ FALSCH: FormTrigger → Delete → SetNode($json.field)
      → Delete gibt {} zurück → $json.field = null!

   ✅ RICHTIG: FormTrigger → Delete → CodeNode($('FormTrigger').first())
      return { json: {...}, binary: $('FormTrigger').first().binary }
   ```
   → Delete/Update-Nodes von Supabase, PostgreSQL etc. geben EIGENE Ausgabe
   → JSON UND Binary gehen verloren
   → Fix: Code-Node mit expliziter Referenz auf Upstream-Node

7. **NIEMALS** Fehler als "Platform-Bug" abtun ohne Root-Cause-Analyse!
   ```
   ❌ FALSCH: "SQLITE_ERROR ist bekannter n8n-Bug" → nächstes Thema
   ✅ RICHTIG: Tief graben → war falsche URL + Daten-Flow-Problem
   ```

8. **NIEMALS** generische Tool-Beschreibungen für Vector Store!
   ```
   ❌ FALSCH: "Nutze dieses Tool, um Wissen über MediFox zu erhalten"
      → Agent ruft Tool NICHT auf, antwortet aus eigenem Wissen!

   ✅ RICHTIG: "IMMER nutzen für JEDE Frage über MediFox!
      Enthält: Installation, CarePad, App, Smartphone, Handy,
      Dokumentation, Klickpfade, Wunden, SIS, Pflege...
      MUSS bei JEDER Benutzerfrage aufgerufen werden!"
   ```
   - Bei `mode: "retrieve-as-tool"` MUSS Agent das Tool aktiv aufrufen
   - Ohne explizite Schlüsselwörter in toolDescription → Agent ignoriert Tool
   - System Prompt allein reicht NICHT - toolDescription ist entscheidend!

### 🟡 BEVORZUGT

1. **Error Workflow** einrichten für Fehlerbenachrichtigung
2. **Sticky Notes** für Dokumentation im Workflow
3. **Versionen** in Workflow-Namen (v1, v2, ...)
4. **Test zuerst** mit Manual Trigger vor Webhook

### 🟢 GUT ZU WISSEN

1. Diana nutzt deutsche Node-Beschriftungen
2. Workflows werden in NextCloud gesichert
3. Komplexe Workflows in Sub-Workflows aufteilen

---

## Form-Security Best Practices

### Input-Validierung bei File-Uploads

```javascript
// In einem Code Node nach Form Trigger
const input = $input.item.json;

// 1. Path Traversal blockieren
if (input.Dokument && input.Dokument[0]) {
  const filename = input.Dokument[0].filename || '';

  // Blockiere gefährliche Zeichen
  if (filename.includes('..') ||
      filename.includes('/') ||
      filename.includes('\\')) {
    throw new Error('Ungültiger Dateiname: Path Traversal erkannt');
  }

  // 2. Nur erlaubte Zeichen (Sanitization)
  const sanitized = filename.replace(/[^a-zA-Z0-9._-]/g, '_');
  input.Dokument[0].filename = sanitized;
}

return input;
```

### Security-Checkliste für Forms

| Check | Schutz vor |
|-------|------------|
| `..` blockieren | Path Traversal |
| `/` blockieren | Directory Escape (Unix) |
| `\\` blockieren | Directory Escape (Windows) |
| Regex Sanitization | Injection-Angriffe |
| Dateityp validieren | Malicious Uploads |
| Größenlimit setzen | DoS-Angriffe |

---

## Debugging-Checkliste

Wenn ein Workflow nicht funktioniert:

### 1. Ist der Workflow aktiv?
```
Toggle oben rechts → Muss "Active" sein
```

### 2. Webhook-URL korrekt?
```
Produktion: https://deine-domain.de/webhook/xyz
Test:       http://localhost:5678/webhook-test/xyz
```

### 3. Credentials verbunden?
```
Jeder Node mit 🔑 Symbol braucht Credentials
```

### 4. Daten fließen richtig?
```
Klick auf Execution → Sieh dir jeden Node an
```

### 5. Fehler-Details?
```
Bei rotem Node → Hover für Error Message
```

---

## Code-Snippets für n8n

### JSON parsen in Function Node

```javascript
// Eingehende Daten
const items = $input.all();

// Verarbeiten
const result = items.map(item => {
  return {
    json: {
      processed: true,
      originalData: item.json,
      timestamp: new Date().toISOString()
    }
  };
});

return result;
```

### Supabase Vektor-Suche

```javascript
// In einem Code Node nach Embedding
const embedding = $input.first().json.embedding;

// RPC-Aufruf für Similarity Search
return [{
  json: {
    query: 'match_documents',
    params: {
      query_embedding: embedding,
      match_threshold: 0.7,
      match_count: 5
    }
  }
}];
```

---

## Typische Fehler und Lösungen

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| "Webhook not found" | Workflow nicht aktiv | Aktivieren |
| "Credential not found" | Falsche ID | In Credentials prüfen |
| "CORS error" | Browser blockiert | Über Server testen |
| "Timeout" | Zu langsam | Batch-Size reduzieren |
| "Memory exceeded" | Zu große Daten | Chunking einführen |

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

### 2026-02-07 - Form Upload Fix, Sandbox-CORS, Delete-Dataflow

**🔴 n8n Form Trigger URLs:**
- Form-URL: `/form/{webhookId}` — NICHT `/form/{workflowId}`!
- HTML-Feldnamen: `field-0`, `field-1` etc. — NICHT die Label-Namen!
- POST geht an dieselbe URL wie GET (nicht `/form-waiting/`)

**🔴 Supabase Delete/Update Nodes zerstören Datenfluss!**
- Output ist `{}` — JSON UND Binary gehen verloren
- Fix: Code-Node mit `$('UpstreamNode').first()` statt `$json.field`
- Pattern: `return { json: {...}, binary: $('FormTrigger').first().binary }`

**🔴 n8n Sandbox-CSP macht CORS mit spezifischer Domain unmöglich:**
- `Content-Security-Policy: sandbox` (ohne `allow-same-origin`) → Origin = `null`
- `access-control-allow-origin: https://domain.com` ≠ `null` → CORS blocked
- Fix: Immer `access-control-allow-origin: *` verwenden

**🔴 Fehler nie als "Platform-Bug" abtun!**
- SQLITE_ERROR NaN war KEIN n8n-Bug → falsche URL + Daten-Flow-Problem
- Immer Root-Cause-Analyse machen, auch wenn es wie ein Plattform-Fehler aussieht

---

### 2026-01-26 - n8n CLI Import NICHT ZUVERLÄSSIG

**🔴 KRITISCH: n8n CLI Import funktioniert oft NICHT!**

Symptome:
- `n8n import:workflow` gibt "Success" aber Änderungen fehlen
- EISDIR Fehler bei Datei-Import
- UI-Import zeigt keine Änderungen

**✅ LÖSUNG: Direkt in SQLite-Datenbank schreiben**

```bash
# Workflow aus SQLite exportieren
docker exec n8n-n8n-1 sqlite3 /home/node/.n8n/database.sqlite \
  "SELECT nodes FROM workflow_entity WHERE id='SJ47UX9mv8wh1Wwy'" > nodes.json

# Workflow in SQLite updaten (Python-Beispiel)
import sqlite3
import json

conn = sqlite3.connect('/volume1/docker/n8n/data/database.sqlite')
cursor = conn.cursor()

# Nodes JSON modifizieren
cursor.execute("SELECT nodes FROM workflow_entity WHERE id=?", (workflow_id,))
nodes = json.loads(cursor.fetchone()[0])

# Änderungen anwenden...
nodes_json = json.dumps(nodes)
cursor.execute("UPDATE workflow_entity SET nodes=? WHERE id=?", (nodes_json, workflow_id))

conn.commit()
conn.close()
```

**🔴 NACH DATENBANK-UPDATE IMMER:**
```bash
docker restart n8n-n8n-1
```
Ohne Restart werden Änderungen NICHT geladen!

**Wichtige Pfade:**
- SQLite: `/volume1/docker/n8n/data/database.sqlite`
- Im Container: `/home/node/.n8n/database.sqlite`
- Workflows-Tabelle: `workflow_entity`
- Spalten: `id`, `name`, `active`, `nodes`, `connections`, `settings`

**RAG_Masterclass_Chat_hybrid:**
- Workflow ID: `SJ47UX9mv8wh1Wwy`
- 74+ Nodes
- Supabase KI-Agent mit erweitertem System Prompt

---

### 2026-01-24 - Workflow Audit Session

**Audit-Workflow Pattern:**
```
Export → Analyze → Backup → Fix → Import → Verify

# Export
docker exec n8n-n8n-1 n8n export:workflow --id=<ID> --output=/workflows/backup.json

# Import (aus Verzeichnis, nicht Datei!)
docker exec n8n-n8n-1 n8n import:workflow --separate --input=/workflows/import_dir/

# Aktivieren nach Import
docker exec n8n-n8n-1 n8n update:workflow --active=true --id=<ID>
docker restart n8n-n8n-1  # Änderungen werden erst nach Restart aktiv!
```

**🔴 KRITISCH: Trigger-Verbindungen prüfen**
- Schedule Trigger MUSS Ausgangsverbindung haben
- Ohne Verbindung läuft der Trigger, tut aber NICHTS
- Symptom: Workflow "erfolgreich" mit nur 1 Node executed

**🔴 Error Handling Standard:**
- HTTP Request Nodes: `onError: continueErrorOutput`
- Database Nodes: `onError: continueErrorOutput`
- Verhindert Workflow-Abbruch bei transienten Fehlern

**🟡 Orphaned Node Detection:**
```
LEGITIM verwaist (AI-Subkomponenten):
- Embeddings Nodes → verbunden via ai_embedding
- Chat Models → verbunden via ai_languageModel
- Memory Nodes → verbunden via ai_memory
- Tool Nodes → verbunden via ai_tool
- Reranker → verbunden via ai_reranker

PROBLEMATISCH verwaist (entfernen):
- Nodes OHNE jegliche Verbindung UND leere Parameter
- Beispiele: leere Function Nodes, leere PostgreSQL Queries
```

**🟡 CLI Import Limitationen:**
- `retryOnFail`, `maxTries`, `waitBetweenTries` persistieren NICHT
- Muss via n8n UI konfiguriert werden

**Embedding Konsistenz:**
- Alle Embedding-Nodes: `text-embedding-3-large`, `dimensions: 3072`
- Inkonsistente Modelle → Dimension Mismatch Fehler

---

### 2026-01-24 - Deduplication & OCR Pipeline

**🔴 Deduplication Pattern:**
```
Schedule Trigger ──┬──→ NextCloud List ──→ Merge ──→ Filter ──→ Process
                   └──→ Get Existing IDs ────────↗
                        (Supabase RPC)
```

**Merge Node Modes:**
| Mode | Verwendung |
|------|------------|
| `append` | Zwei Listen zusammenführen (unabhängige Items) |
| `combine` | Items matchen nach Feld (erfordert `fieldsToMatch`) |

**🔴 Filter Code für Deduplication:**
```javascript
const allItems = $input.all();
const existingFileIds = new Set();
const newFiles = [];

for (const item of allItems) {
  const json = item.json;
  // Supabase rows: haben file_id aber KEIN path
  if (json.file_id && !json.path) {
    existingFileIds.add(json.file_id);
  }
  // NextCloud files: haben path UND contentType
  else if (json.path && json.contentType) {
    newFiles.push(item);
  }
}

return newFiles.filter(item => !existingFileIds.has(item.json.path));
```

**🔴 Download Node nach PostgreSQL:**
- Nach PostgreSQL-Nodes ändert sich die Datenstruktur
- `$json.field` funktioniert NICHT mehr
- ✅ Richtig: `$('NodeName').item.json.field`
- Für URL-encodierte Pfade: `decodeURIComponent()`

```
path = {{ '/' + decodeURIComponent($('Überblick').item.json.file_id) }}
```

**🔴 LangChain AI Nodes (Audit False Positives):**
- AI-Subkomponenten haben KEINE `main` Connections
- Nutzen spezielle `ai_*` Connection-Typen
- NICHT als "unconnected" entfernen!

| Node-Typ | Connection-Type |
|----------|-----------------|
| Embeddings | `ai_embedding` |
| Chat Model | `ai_languageModel` |
| Memory | `ai_memory` |
| Tool | `ai_tool` |
| Reranker | `ai_retriever` |
| Vector Store | `ai_vectorStore` |

**🟡 Mistral OCR API (aktuell 2026):**
```
Endpoint: POST /v1/ocr/process
Content-Type: application/json

Body:
{
  "model": "mistral-ocr-latest",
  "document": {
    "type": "document_url",
    "document_url": "https://..."
  },
  "include_image_base64": false
}
```

**🔴 NICHT mehr funktional:**
- ~~`/v1/ocr`~~ (alter Endpoint)
- ~~`multipart/form-data`~~ (alte Format)

**Supabase Deduplication Functions:**
```sql
-- Alle existierenden file_ids abrufen
CREATE OR REPLACE FUNCTION get_existing_file_ids()
RETURNS TABLE (file_id TEXT)
LANGUAGE sql STABLE AS $$
  SELECT DISTINCT metadata->>'file_id' as file_id
  FROM documents
  WHERE metadata->>'file_id' IS NOT NULL;
$$;

-- Einzeldatei prüfen (mit optionalem Löschen)
CREATE OR REPLACE FUNCTION check_file_exists(
  p_file_id TEXT,
  p_delete_if_exists BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  exists_in_db BOOLEAN,
  chunk_count INT,
  action_taken TEXT
);
```

---

### 2026-01-21 - RAG_Masterclass_Chat_hybrid Analyse

**Workflow-Struktur analysiert:**
- 73 Nodes, 5 Trigger (Chat, Form, Webhook, Schedule, Manual)
- Schedule Trigger: alle 6 Stunden
- 20/20 Executions erfolgreich

**Neue Patterns entdeckt:**

1. **Chat-UI via Webhook**
   - `/webhook/medifox-chat` liefert vollständige HTML-Chat-Oberfläche
   - responseMode: responseNode für HTML-Response

2. **KI-Agent Architektur**
   - Supabase KI-Agent: GPT-4o + 4889 Zeichen System Prompt
   - Lightrag KI-Agent: Claude Sonnet 4.5 + 879 Zeichen System Prompt
   - Tools: Datei_inhalt, Query_tabellen_daten, Alle_dateien

3. **Reranker-Integration**
   - Cohere Reranker zwischen Vector Store und Agent
   - Verbessert RAG-Ergebnisqualität

4. **File-Routing via Switch**
   - 4 Outputs: CSV, Excel_neu, Excel_alt, PDF
   - Mistral OCR für PDF-Verarbeitung (mistral-ocr-latest)

**API-Zugriff:**
- Header: `X-N8N-API-KEY: <jwt-token>`
- Endpoints: `/api/v1/workflows`, `/api/v1/executions`

---

### 2026-01-25 - Vision Integration & Workflow Fixes

**🔴 Expression-Syntax KRITISCH:**
```javascript
// ❌ FALSCH - doppelte Anführungszeichen
"value": "=\"={{ $('Node').item.json.field }}\""

// ✅ RICHTIG - einfache Expression
"value": "={{ $('Node').item.json.field }}"
```

**🔴 Filter/Switch für optionale Arrays:**
```javascript
// ❌ FALSCH - crasht wenn $json.files leerer String ist
$json.files → notEmpty (type: array)

// ✅ RICHTIG - explizite Array-Prüfung
Array.isArray($json.files) && $json.files.length > 0 → equals true
```

**🔴 Filter für null-Werte (z.B. base64):**
```javascript
// ❌ UNZUVERLÄSSIG
$json.base_64 → isNotEmpty / notEmpty

// ✅ ZUVERLÄSSIG - Präfix-Check (JPEG beginnt mit "/")
$json.base_64 → startsWith "/" (type: string)
```

**🔴 Workflow-Versionierung nach Import:**
```
PROBLEM: "Active version not found for workflow"
URSACHE: Import erstellt keine "publizierte Version"
LÖSUNG:
  1. Workflow in UI öffnen
  2. Kleine Änderung machen (Node verschieben)
  3. Ctrl+S (Speichern)
  → Erstellt neue aktive Version
```

**🔴 Import deaktiviert IMMER Workflows:**
```bash
# Nach jedem Import:
docker exec n8n-n8n-1 n8n import:workflow --input=/path/
# → "Deactivating workflow... Remember to activate later."

# Lösung: Manuell in UI aktivieren (Toggle)
# CLI-Aktivierung funktioniert NICHT zuverlässig
```

**🟡 Mistral OCR - include_image_base64:**
```javascript
// Wenn Bilder verarbeitet werden sollen:
{
  "model": "mistral-ocr-latest",
  "document": { "file_id": "..." },
  "include_image_base64": true  // ← WICHTIG!
}
// Sonst: alle image_base64 Felder = null
```

**🟡 Node-Referenzen nach Workflow-Umbau:**
```javascript
// Nach Entfernen/Umgehen eines Nodes:
// ALLE $('OldNode') Referenzen suchen und ersetzen!

// Beispiel: OCR_results umgangen → Upload_Mistral direkt
$('OCR_results').item.json.pages  // ❌ Fehler
$('Upload_Mistral').item.json.pages  // ✅ Korrekt
```

**🔵 Audit-Tool False Positives:**
```
Workflow-Auditor prüft nur 'main' Connections.
'ai_*' Connections werden IGNORIERT:
  - ai_languageModel (LLM → Agent)
  - ai_memory (Memory → Agent)
  - ai_tool (Tool → Agent)
  - ai_embedding (Embeddings → VectorStore)
  - ai_reranker (Reranker → VectorStore)

→ "Unverbundene Nodes" können FALSE POSITIVES sein!
```

**🔵 Vision-Integration Pattern:**
```
Chat-Trigger (allowFileUploads: true)
      │
      ▼
Switch: Array.isArray($json.files) && length > 0
      │
   ┌──┴──┐
   │     │
   ▼     ▼
Vision  RAG
(GPT-4o) (Agent)
```

---

### 2026-01-30 - Multi-Respond-Node Workflow Pattern

**🔴 KRITISCH: Unterscheide Respond-Nodes nach Funktion!**

Bei Workflows mit mehreren `respondToWebhook` Nodes:
- **"Respond to Webhook"** → HTML-UI (Chat-Oberfläche)
- **"Respond Chat API"** → JSON-Response (API-Antwort)

**Problem entdeckt:**
Python-Skript aktualisierte ALLE `respondToWebhook` Nodes mit HTML.
→ Chat-API gab plötzlich HTML statt JSON zurück!

**Lösung:**
```python
for node in workflow.get('nodes', []):
    if node.get('name') == 'Respond to Webhook':
        # NUR diesen Node mit HTML updaten
        node['parameters']['responseBody'] = html_content
    elif node.get('name') == 'Respond Chat API':
        # JSON-Response BEHALTEN!
        pass  # Nicht ändern
```

**🔴 NIEMALS alle Respond-Nodes gleich behandeln!**

---

### 2026-01-30 - Workflow Update Pattern (CLI)

**Standard-Pattern für Workflow-Änderungen:**

```bash
# 1. Workflow-JSON vorbereiten (lokal)
# 2. In Container kopieren
docker cp /tmp/workflow.json n8n-n8n-1:/tmp/workflow_to_import.json

# 3. Importieren (deaktiviert automatisch!)
docker exec n8n-n8n-1 n8n import:workflow --input=/tmp/workflow_to_import.json

# 4. Aktivieren
docker exec n8n-n8n-1 n8n update:workflow --id=<WORKFLOW_ID> --active=true

# 5. IMMER Restart (n8n cacht Workflows im Memory!)
docker restart n8n-n8n-1

# 6. Verifizieren
docker logs n8n-n8n-1 --tail 10 | grep "Activated workflow"
```

**🔴 Ohne Restart werden Änderungen NICHT geladen!**

---

### 2026-01-28 - MediFox Chat UI (Webhook HTML Response)

**🔴 UI Design-Qualität ("Level 2"):**
- Standard-Design = "Level 1" (generisch, Bootstrap-look)
- Diana erwartet "Level 2" = Premium, professionell
- Inter Font für professionelle UIs
- Animationen: hover-lift (`translateY(-2px)`), pop-effekt, fade-in

**🔴 DRY-Prinzip für UI:**
```
❌ FALSCH: Quick Actions + Tips mit gleicher Funktion
   - Button: "Screenshot hochladen"
   - Tip: "Screenshots teilen" ← REDUNDANT, entfernen!

✅ RICHTIG: Eine Interaktionsart pro Funktion
   - Nur Quick Actions ODER nur Tips
```

**🔴 Keine fiktiven Domain-Beispiele:**
```
❌ FALSCH: Quick Action "Bericht erstellen" (ohne Backend-Wissen)
✅ RICHTIG: Nur echte Funktionen anbieten (Screenshot, Teach, Frage)
```

**🟡 Clickpath-Visualisierung (Auto-Breadcrumbs):**
```javascript
// Pfade wie "Dokumentation → Bewohner → Verlauf" erkennen
// und als visuelle Breadcrumbs mit Nummern darstellen

function formatClickpaths(text) {
  const pathPattern = /(?:Pfad:?\s*)?([\w]+)\s*[→>]\s*([\w]+(?:\s*[→>]\s*[\w]+)+)/gi;
  return text.replace(pathPattern, (match, first, rest) => {
    const steps = [first, ...rest.split(/\s*[→>]\s*/)];
    return steps.map((s, i) => `<span class="step">${i+1}. ${s}</span>`).join(' → ');
  });
}
```

**🟡 Feedback-Buttons bei JEDER Bot-Antwort:**
```
Nicht nur bei "Ich weiß es nicht" → IMMER anzeigen!

┌─────────────────────────────────────────┐
│ [Bot-Antwort]                           │
│                                         │
│ War das hilfreich?                      │
│ [👍 Ja] [❌ Falsch] [💡 Ergänzen]       │
└─────────────────────────────────────────┘

"Falsch" → öffnet Teach-Modal automatisch
"Ja" → animiertes Checkmark + Danke-Nachricht
```

**🔵 CSS-Patterns für Chat-UI:**
```css
/* Hover-Lift für Buttons */
.btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }

/* Pop-Animation bei Selektion */
@keyframes selectPop { 50% { transform: scale(1.1); } }

/* Schrittweise Einblendung */
.step:nth-child(1) { animation-delay: 0ms; }
.step:nth-child(2) { animation-delay: 50ms; }
/* ... */
```

---

## Nützliche Links

- n8n Dokumentation: https://docs.n8n.io
- Diana's n8n-Instanz: http://192.168.22.90:5678 (intern)
- Workflow-Backups: NextCloud/n8n-backups/
