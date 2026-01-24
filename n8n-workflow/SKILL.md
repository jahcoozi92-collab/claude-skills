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

## Nützliche Links

- n8n Dokumentation: https://docs.n8n.io
- Diana's n8n-Instanz: http://192.168.22.90:5678 (intern)
- Workflow-Backups: NextCloud/n8n-backups/
