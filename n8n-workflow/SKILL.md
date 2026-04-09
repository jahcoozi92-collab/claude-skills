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

9. **NIEMALS** nur `workflow_entity` aktualisieren bei SQLite-Aenderungen!
   ```
   ❌ FALSCH: UPDATE workflow_entity SET nodes=... WHERE id='...'
      → n8n liest aktive Workflows aus workflow_history!
      → Aenderung hat KEINE Wirkung!

   ❌ AUCH FALSCH: Nur activeVersionId in workflow_history updaten
      → API activate Endpoint waehlt EIGENE Version aus history!
      → Kann eine AELTERE Version aktivieren!

   ✅ RICHTIG: ALLE History-Versionen + workflow_entity synchron aktualisieren:
      1. UPDATE workflow_entity SET nodes=..., connections=... WHERE id='...'
      2. UPDATE workflow_history SET nodes=..., connections=...
         WHERE workflowId='...'   -- ALLE Versionen!
      3. docker restart n8n-n8n-1
   ```
   → `workflow_history` ist die Source of Truth fuer aktive Workflows
   → API activate kann JEDE History-Version waehlen (nicht vorhersagbar)
   → Sicherste Loesung: ALLE Versionen auf denselben Stand bringen

10. **NIEMALS** API-Keys ohne Format-Validierung speichern!
    ```
    ❌ FALSCH: key = user_input  → direkt speichern
       → Doppeltes Prefix "sk-ant-api03-sk-ant-api03-" → 401 Fehler

    ✅ RICHTIG: Key-Format pruefen
       Anthropic: sk-ant-api03-{random} (genau EIN Prefix)
       OpenAI: sk-proj-{random} oder sk-{random}
    ```

11. **NIEMALS** PG executeQuery in einer Serienkette vor Daten-Nodes!
    ```
    ❌ FALSCH: Kosten Tracken → PG INSERT → JSON Validieren
       → PG INSERT gibt {success:true} zurueck → JSON Validieren bekommt KEINE LLM-Daten!
       → Gleich wie Supabase Delete (Regel #6) - alle DB-Write-Nodes brechen den Datenfluss!

    ✅ RICHTIG: Fan-out Pattern (parallel statt seriell)
       Kosten Tracken → [JSON Validieren, PG INSERT]  (gleichzeitig)
       n8n Connection: {"main": [[{"node":"A"},{"node":"B"}]]} = Fan-out
    ```
    → Gilt fuer ALLE Postgres/Supabase INSERT/UPDATE/DELETE Nodes
    → executeQuery gibt Query-Ergebnis zurueck, NICHT die Eingangsdaten

12. **NIEMALS** LLM-Output direkt in SQL-Expressions ohne Escaping!
    ```
    ❌ FALSCH: VALUES ('{{ $json.llm_text }}')
       → LLM schreibt "it's important" → SQL bricht: VALUES ('it's important')

    ✅ RICHTIG: Im Code Node VOR dem PG Node escapen:
       function sqlEscape(s) { return String(s).replace(/'/g, "''"); }
       return [{ json: { _sql: `INSERT INTO ... VALUES ('${sqlEscape(text)}')` } }];
       → PG Node: query = {{ $json._sql }}
    ```

13. **NIEMALS** .toFixed() auf PG NUMERIC-Werte ohne Number()-Cast!
    ```
    ❌ FALSCH: budget.tages_limit.toFixed(2)
       → PG gibt NUMERIC als String zurueck → "toFixed is not a function"

    ✅ RICHTIG: Number(budget.tages_limit).toFixed(2)
    ```

14. **NIEMALS** erwarten dass API PUT allein Webhooks aktualisiert!
    ```
    ❌ FALSCH: PUT /api/v1/workflows/{id} → Webhook liefert sofort neues HTML
       → n8n cached Webhook-Handler im Speicher!
       → Webhook liefert weiterhin ALTE Version!

    ✅ RICHTIG: Nach API PUT zusätzlich:
       1. POST /api/v1/workflows/{id}/deactivate
       2. POST /api/v1/workflows/{id}/activate
       3. Falls immer noch alt: docker restart n8n-n8n-1
    ```
    → API PUT aktualisiert nur die DB, nicht den laufenden Webhook-Handler
    → Deactivate/Activate erzwingt Neu-Registrierung der Webhooks
    → Container-Restart ist der sichere Fallback

15. **NIEMALS** chatTrigger mit respondToWebhook kombinieren!
    ```
    ❌ FALSCH: Chat-Trigger → Agent → ... → Respond to Webhook
       → chatTrigger erwartet output vom LETZTEN Node
       → respondToWebhook gibt NICHTS zurück → "No response" im Chat-UI!

    ✅ RICHTIG: Routing per Trigger-Typ nach dem Agent:
       Agent → Trigger_Router (Code) → Ist_Webhook? (IF)
         TRUE  → Respond to Webhook (für API-Webhook-Pfad)
         FALSE → Chat_Antwort (Set: {output: $json.output})
    ```
    - chatTrigger liest `output` Feld vom letzten ausgeführten Node
    - respondToWebhook sendet HTTP-Response, gibt aber KEIN output weiter
    - Trigger-Erkennung: `try { $('Format Chat Input').first(); } catch(e) {}`

16. **NIEMALS** zusätzliche Felder in n8n API PUT /workflows settings!
    ```
    ❌ FALSCH: settings: { executionOrder, timezone, callerPolicy, ... }
       → "request/body/settings must NOT have additional properties"

    ✅ RICHTIG: settings: { executionOrder: "v1" }
       → NUR executionOrder wird akzeptiert
    ```

17. **NIEMALS** annehmen dass Python/pip/apk im n8n Container verfuegbar sind!
    ```
    ❌ FALSCH: docker exec n8n-n8n-1 pip install python-docx
       → n8n Docker Image (v2.7.4+) ist "Hardened Alpine"
       → apk, pip, Python sind ENTFERNT!

    ✅ RICHTIG: Node.js-Alternativen nutzen:
       - DOCX-Parsing: mammoth.js (npm install mammoth --prefix /home/node/.n8n)
       - File-Watching: scheduleTrigger (Polling) statt localFileTrigger
       - localFileTrigger Node existiert NICHT im Hardened Image!
    ```

18. **NIEMALS** fs.renameSync() zwischen separaten Docker-Mounts!
    ```
    ❌ FALSCH: fs.renameSync('/datenbank/eingang/file.txt', '/datenbank/verarbeitet/file.txt')
       → EXDEV: cross-device link not permitted
       → eingang/ und verarbeitet/ sind SEPARATE Docker-Volume-Mounts!

    ✅ RICHTIG: Copy + Delete statt Rename:
       fs.copyFileSync(srcPath, dstPath);
       fs.unlinkSync(srcPath);
    ```
    → Gilt fuer ALLE Faelle wo Quell- und Zielverzeichnis verschiedene Mounts sind

19. **NIEMALS** Binary-Daten via `item.binary.file.data` in Code Nodes lesen!
    ```
    ❌ FALSCH: Buffer.from(item.binary.file.data, 'base64')
       → n8n v2.8+ nutzt "filesystem-v2" Storage
       → item.binary.file.data gibt den String "filesystem-v2" zurueck, NICHT base64!
       → Buffer.from("filesystem-v2", "base64") = Muell-Bytes!

    ✅ RICHTIG: n8n Helper-Funktion nutzen:
       const buffer = await this.helpers.getBinaryDataBuffer(0, 'file');
       // 0 = itemIndex, 'file' = binary property name
       // Funktioniert mit BEIDEN Storage-Backends (inline + filesystem-v2)

    Fuer PDF-base64 (z.B. Claude Document API):
       const buffer = await this.helpers.getBinaryDataBuffer(0, 'file');
       const base64 = buffer.toString('base64');
       return [{ json: { ...item.json, pdfBase64: base64 } }];
       // NICHT binary weiterreichen - base64 als JSON-Feld!
    ```
    → Betrifft ALLE Code Nodes die Binary-Daten lesen (Extract, Convert, etc.)

20. **NIEMALS** chatTrigger ohne `public: true` fuer Production-Webhooks deployen!
    ```
    ❌ FALSCH: chatTrigger mit { "options": {} }
       → Webhook wird NICHT registriert!
       → /webhook/{webhookId}/chat gibt 404
       → Nur im n8n Editor als Test-Webhook erreichbar

    ✅ RICHTIG: chatTrigger mit { "public": true, "options": {} }
       → Production-Webhook wird registriert
       → /webhook/{webhookId}/chat erreichbar (GET=Chat-Widget, POST=API)
    ```
    → Ohne `public: true` funktioniert NUR der Test-Modus im Editor
    → Nach API PUT: deactivate/activate noetig fuer Webhook-Registrierung

21. **NIEMALS** toolHttpRequest Node-Namen mit Sonderzeichen! (v2.9+)
    ```
    ❌ FALSCH: "Web Search (SerpAPI)" oder "Suche & Analyse"
       → "The name of this tool is not a valid alphanumeric string"
       → Agent kann das Tool nicht aufrufen!

    ✅ RICHTIG: "web_search" oder "suche_analyse"
       → Nur [a-zA-Z0-9_], NICHT mit Zahl anfangend
    ```
    → Gilt fuer ALLE Langchain Tool-Nodes (toolHttpRequest, postgresTool, etc.)
    → Der Node-Name wird als Tool-Name an den LLM-Agent uebergeben

22. **NIEMALS** placeholderDefinitions UND $fromAI() gleichzeitig in toolHttpRequest!
    ```
    ❌ FALSCH:
       url: "=https://api.example.com?q={{ $fromAI('query', 'desc', 'string') }}"
       placeholderDefinitions: { values: [{ name: "query", ... }] }
       → "Misconfigured placeholder 'query'"

    ✅ RICHTIG (Option A - bevorzugt): Nur $fromAI() im URL
       url: "=https://api.example.com?q={{ $fromAI('query', 'The search query', 'string') }}"
       // KEINE placeholderDefinitions!

    ✅ RICHTIG (Option B): Nur placeholderDefinitions
       url: "=https://api.example.com?q={query}"
       placeholderDefinitions: { values: [{ name: "query", ... }] }
       // KEIN $fromAI() im URL!
    ```
    → $fromAI() und placeholderDefinitions sind ALTERNATIVE Methoden
    → Beide zusammen verursachen "Misconfigured placeholder" Error
    ```
    ❌ FALSCH: Buffer.from(item.binary.file.data, 'base64')
       → n8n v2.8+ nutzt "filesystem-v2" Storage
       → item.binary.file.data gibt den String "filesystem-v2" zurueck, NICHT base64!
       → Buffer.from("filesystem-v2", "base64") = Muell-Bytes!

    ✅ RICHTIG: n8n Helper-Funktion nutzen:
       const buffer = await this.helpers.getBinaryDataBuffer(0, 'file');
       // 0 = itemIndex, 'file' = binary property name
       // Funktioniert mit BEIDEN Storage-Backends (inline + filesystem-v2)

    Fuer PDF-base64 (z.B. Claude Document API):
       const buffer = await this.helpers.getBinaryDataBuffer(0, 'file');
       const base64 = buffer.toString('base64');
       return [{ json: { ...item.json, pdfBase64: base64 } }];
       // NICHT binary weiterreichen - base64 als JSON-Feld!
    ```
    → Betrifft ALLE Code Nodes die Binary-Daten lesen (Extract, Convert, etc.)


23. **NIEMALS** IF-Node v2 mit `typeValidation: "strict"` wenn der leftValue aus einer Expression kommt!
    ```
    ❌ FALSCH:
       conditions.options.typeValidation: "strict"
       leftValue: "={{ $json._rateLimited }}"
       → "Wrong type: 'true' is a string but was expecting a boolean"
       → Expressions liefern IMMER Strings, nicht native Booleans!

    ✅ RICHTIG:
       conditions.options.typeValidation: "loose"
       → Aktiviert "Convert types where required" im IF-Node
       → String "true" wird automatisch zu Boolean true konvertiert
    ```
    → Gilt fuer ALLE IF-Node Conditions mit Expression-basierten Werten
    → In der n8n UI heisst die Option "Convert types where required"

24. **NIEMALS** nach API PUT ohne Container-Restart testen!
    ```
    ❌ FALSCH:
       POST /deactivate → PUT workflow → POST /activate → "fertig, teste"
       → Webhook-Cache: alte Version wird weiter ausgeliefert!

    ✅ RICHTIG:
       POST /deactivate → PUT workflow → POST /activate → docker restart n8n-n8n-1
       → DANN erst testen. Ohne Restart bleiben Webhooks auf altem Stand.
    ```
    → Ergaenzt NIEMALS #14 (Webhook-Cache)
    → Betrifft: Form Triggers, Webhook Nodes, Chat Triggers
    → Nach Restart ~10s warten bis n8n alle Workflows re-aktiviert hat

25. **NIEMALS** `$(nodeName).all()` in Code-Nodes fuer Agent-Sub-Nodes aufrufen!
    ```
    ❌ FALSCH (in Grounding_Verifier oder aehnlichen Post-Agent-Nodes):
       const data = $('Supabase Vector Store').all();
       const data2 = $('Klickpfad_Suche').all();
       → Agent-Tool-Nodes laufen in einem SEPARATEN Ausfuehrungskontext!
       → $(toolNode).all() wartet ENDLOS auf Daten → DEADLOCK/HANG!

    ✅ RICHTIG: Nur $json verwenden (enthaelt Agent-Output + intermediateSteps):
       const steps = $json.intermediateSteps || [];
       const context = JSON.stringify($json).substring(0, 50000);
    ```
    → Gilt fuer ALLE Nodes die NACH einem Agent-Node laufen
    → Agent-Tool-Nodes (Vector Store, HTTP Tools) sind NICHT ueber $() erreichbar

26. **NIEMALS** Anthropic API direkt nutzen — kein Guthaben!
    ```
    ❌ FALSCH: fetch('https://api.anthropic.com/v1/messages', { headers: { 'x-api-key': key } })
       → Anthropic Credential 8vuwy9VrY5EheWYB hat KEIN Guthaben → 402 Error

    ✅ RICHTIG: OpenRouter nutzen:
       fetch('https://openrouter.ai/api/v1/chat/completions', {
         headers: { 'Authorization': 'Bearer ' + openRouterKey }
       })
       → Modell-ID Kurzform: 'anthropic/claude-sonnet-4.5' (NICHT '...-20250929')
       → OpenRouter Credential: JDjnOpGlLzqfePON
    ```
    → Gilt auch fuer Supabase Edge Functions (vision-analyzer etc.)
    → OpenRouter Key im Supabase Vault: rpc('get_secret', {secret_name: 'OPENROUTER_API_KEY'})

27. **NIEMALS** SQLite-Workflow-Aenderungen ohne sauberen Restart-Zyklus!
    ```
    ❌ FALSCH: SQLite update → docker restart → Test
       → Haengende Executions blockieren Workflow-Aktivierung!
       → "Execution is already being resumed by another process"

    ✅ RICHTIG (Reihenfolge entscheidend!):
       1. POST /deactivate (stoppt laufende Executions)
       2. SQLite-Aenderung (workflow_entity + workflow_history)
       3. docker restart n8n-n8n-1
       4. 10s warten
       5. POST /activate (registriert Webhooks neu)
       6. Erst DANN testen
    ```

### 🟡 BEVORZUGT

1. **Error Workflow** einrichten für Fehlerbenachrichtigung
2. **Sticky Notes** für Dokumentation im Workflow
3. **Versionen** in Workflow-Namen (v1, v2, ...)
4. **Test zuerst** mit Manual Trigger vor Webhook
5. **Fan-out fuer DB-Writes** neben der Hauptkette (nicht seriell!)
6. **OpenRouter HTTP Request**: `specifyBody: "string"`, `contentType: "raw"`, `rawContentType: "application/json"`, body mit `JSON.stringify` (NICHT `specifyBody: "json"` - bricht bei Sonderzeichen in Prompts)
7. **Deploy-Pattern**: deactivate → PUT (interne API) → activate
8. **n8n Timezone beachten**: Ohne `GENERIC_TIMEZONE` env = UTC. Alle Crons in UTC!
9. **Activation API (v2.7.4+)**: `active` ist read-only in PUT → `POST /workflows/{id}/activate` und `/deactivate`
10. **mammoth.js in Code Nodes**: `npm install mammoth --prefix /home/node/.n8n` (persistiert im gemounteten Volume). Env: `NODE_FUNCTION_ALLOW_EXTERNAL=mammoth`. Import: `const mammoth = require('mammoth');`
11. **Anthropic API direkt aus n8n**: Gleiche Config wie OpenRouter (#6): `specifyBody: "string"`, `contentType: "raw"`, `rawContentType: "application/json"`. Auth: `x-api-key` Header mit `{{ $env.ANTHROPIC_API_KEY }}`. `max_tokens: 16384` fuer grosse Dokumente.
12. **Claude max_tokens Truncation Recovery**: Wenn `stop_reason === 'max_tokens'`: JSON ist abgeschnitten. Letzte vollstaendige `},` finden, offene Brackets/Braces schliessen, `JSON.parse()` versuchen.
13. **responseMode "lastNode" statt "responseNode"** fuer Webhook-Responses (v2.8+):
    - `"responseNode"` ist unzuverlaessig: gibt manchmal `{"myField":"value"}` sofort zurueck
    - `"lastNode"` wartet auf Execution-Ende und gibt Output des letzten Nodes als JSON zurueck
    - Nachteil: Immer HTTP 200 (kein Custom-Statuscode moeglich)
    - Keine `respondToWebhook` Nodes noetig - Terminal-Nodes (Save, Error) liefern direkt
14. **Sticky Notes via API** fuer Workflow-Dokumentation:
    - Node-Typ: `n8n-nodes-base.stickyNote`, typeVersion 1
    - Farben: 2=rot, 3=gelb, 4=blau, 5=lila, 6=gruen
    - Parameter: `content` (Markdown), `width`, `height`
    - Position relativ zu den Nodes die sie dokumentieren
    - Werden bei API PUT als normale Nodes im nodes-Array mitgeschickt
15. **API-Keys via httpQueryAuth Credential** statt URL-Klartext in toolHttpRequest:
    - API: `POST /credentials { name: "...", type: "httpQueryAuth", data: { name: "api_key", value: "..." } }`
    - Node: `authentication: "genericCredentialType"`, `genericAuthType: "httpQueryAuth"`
    - Key taucht nicht in Logs/Execution-Daten auf
    - User kann Key spaeter ueber n8n UI aendern

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

### 2026-03-27 - OpenRouter Model-IDs + Anthropic Credits + Anthropic Node Format

**🔴 OpenRouter Model-IDs: provider/model-name Format!**
- OpenRouter nutzt `provider/model-name`, NICHT das native API-Format
- `anthropic/claude-sonnet-4.6` (RICHTIG) vs `claude-sonnet-4-5-20250929` (FALSCH)
- Verfuegbare Sonnet-Modelle: `anthropic/claude-sonnet-4.6`, `anthropic/claude-sonnet-4.5`, `anthropic/claude-sonnet-4`
- Preis Sonnet 4.6: $3/$15 pro M Tokens

**🔴 Anthropic-Konto hat KEIN Guthaben:**
- Credential `8vuwy9VrY5EheWYB` (Anthropic account) → "credit balance too low"
- IMMER OpenRouter (Credential `JDjnOpGlLzqfePON`) fuer Claude-Modelle verwenden
- OpenRouter-Node-Type: `@n8n/n8n-nodes-langchain.lmChatOpenRouter` (typeVersion: 1)

**🟡 Anthropic Node v1.3 Resource Locator Format:**
- Anthropic-Node (`lmChatAnthropic`) typeVersion 1.3 braucht Resource Locator:
  ```json
  "model": {"__rl": true, "mode": "id", "value": "claude-sonnet-4-5-20250929"}
  ```
- NICHT plain string: `"model": "claude-sonnet-4-5-20250929"` → "Could not get parameter"

**🔵 Execution-Daten bei Webhook-Mode:**
- `GET /api/v1/executions/{id}` gibt bei Webhook-Executions KEIN runData zurueck
- Fix: `?includeData=true` Parameter an die URL anhaengen

### 2026-03-24 - RAG Workflow Deep-Repair + Agent v3 Upgrade

**🔴 Agent Node v2 → v3 (Pflicht fuer neue Modelle):**
- Agent v2 (`@n8n/n8n-nodes-langchain.agent` typeVersion=2) unterstuetzt GPT 5.4 NICHT
- Fehlermeldung: "This model is not supported in 2 version of the Agent node"
- Fix: `typeVersion: 3` im Workflow-JSON setzen via API PUT
- OpenAI Chat Model ebenfalls upgraden: typeVersion 1.3 → 1.6

**🔴 Alle 4 Vector Store Nodes IMMER zusammen aendern:**
- RAG_Masterclass_Chat_hybrid hat 4 vectorStoreSupabase Nodes:
  - Supabase Vector Store_Upload (Text/CSV Pfad)
  - Supabase Vector Store_upload (OCR Pfad)
  - Form Vector Store (Formular-Upload)
  - Supabase - Vector Store_Abruf (Chat-Query)
- ALLE muessen gleiche tableName + queryName haben
- Tabelle: `rag_chunks` (NICHT `documents`), Query: `match_qm_chunks`

**🔴 Datei_inhalt Tool SQL aktualisieren bei Tabellenwechsel:**
- PostgresTool `Datei_inhalt` hatte SQL: `SELECT ... FROM documents WHERE ...`
- documents-Tabelle war leer → Tool gab IMMER nichts zurueck
- Fix: SQL auf `rag_chunks` umstellen + title/url Fallback-Suche

**🟡 Schedule Trigger → Manueller Trigger (Diana-Praeferenz):**
- Diana will keinen automatischen 6h-Trigger fuer Reindexierung
- Fix: Schedule Trigger Node entfernen, Manueller Start behalten
- API: Node aus `nodes[]` Array entfernen + Connection loeschen + PUT

**🟡 Log_Answer_Trace Modell-Name anpassen:**
- Hardcoded `claude-sonnet-4-5-20250929` → `gpt-5.4` nach Modellwechsel
- Sonst falsche Eintraege in answer_traces Tabelle

**🔵 n8n-hybrid Edge Function (TODO):**
- Supabase Edge Function `n8n-hybrid` sucht noch in `documents` mit `trust_level` Filter
- Gibt 0 Ergebnisse → nicht kritisch (Vector Store uebernimmt)
- Muss im Supabase Dashboard aktualisiert werden

---

### 2026-03-15 - Anthropic API Billing + Credential-Divergenz

**🔴 "Bad request" maskiert oft Billing-Probleme:**
- Anthropic API gibt `Bad request - please check your parameters` zurück, wenn das Guthaben leer ist
- NICHT sofort Modellnamen oder Parameter debuggen → ZUERST Guthaben prüfen auf console.anthropic.com
- Fehlerkette: `credit balance too low` → n8n zeigt nur `Bad request`

**🔴 n8n Credentials ≠ .env Keys (ZWEI getrennte Welten):**
- `/volume1/docker/n8n/.env` enthält `ANTHROPIC_API_KEY` → wird von Scripts genutzt
- n8n Credential DB (verschlüsselt, AES) enthält eigenen Key → wird von Workflow-Nodes genutzt
- Diese Keys sind NICHT synchron und können unterschiedliche Accounts/Guthaben haben
- Debugging: Immer in **n8n UI → Settings → Credentials** prüfen, nicht in `.env`
- Key-Ende-Vergleich hilft: `grep ANTHROPIC_API_KEY ... | sed 's/=.*\(.\{4\}\)$/=...\1/'`

**🟡 Modell-Referenz aktualisiert:**
- RAG_Masterclass_Chat_hybrid nutzt `claude-sonnet-4-5-20250929` (Anthropic Chat Model Node)
- Credential-ID: `8vuwy9VrY5EheWYB` ("Anthropic account")

---

### 2026-02-08 - workflow_history + Credential Encryption + Chat-Frontend

**🔴 workflow_history ist Source of Truth:**
- n8n speichert aktive Workflows in `workflow_history` (nicht nur `workflow_entity`)
- `activeVersionId` verweist auf den History-Eintrag
- Bei SQLite-Aenderungen IMMER beide Tabellen updaten + restart

**n8n Credential Encryption (CryptoJS AES):**
```python
# Format: Base64("Salted__" + 8-byte salt + AES-256-CBC encrypted data)
# Key derivation: EVP_BytesToKey mit MD5 (passphrase = N8N_ENCRYPTION_KEY)
# Plaintext: JSON z.B. {"apiKey": "sk-ant-api03-..."}
# Python: cryptography lib + custom EVP_BytesToKey
```

**Chat-Frontend (Respond to Webhook Node):**
- HTML liegt in `responseBody` Parameter des `Respond to Webhook` Nodes
- `formatMessage()` nutzt **marked.js** (CDN) fuer Markdown-Rendering (seit 2026-02-10)
- CSS Styles inline im selben HTML-String
- Aenderungen via API PUT + deactivate/activate (oder Container-Restart)

**n8n API Key Standort:**
- NICHT in `.env` gespeichert!
- Liegt hardcoded in Workflow-Scripts: `workflows/test-n8n.sh`, `deploy-n8n-mcp.sh`, `import-workflow.sh`

---

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
   - Lightrag KI-Agent: Claude Sonnet 4.5 (`claude-sonnet-4-5-20250929`) + 879 Zeichen System Prompt
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
- **Aktuell (2026-02-10)**: Plus Jakarta Sans + JetBrains Mono, Teal/Cyan (#14b8a6)
- Vorher: Inter Font, Indigo/Purple (#6366f1) - komplett migriert
- Animationen: hover-lift (`translateY(-2px)`), pop-effekt, fade-in
- Glass morphism, gradient top-lines, SVG icons, staggered card entrances

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

### 2026-02-12 - Agent System Health Check: PG Data Flow, Fan-out, SQL Escape

**🔴 PG executeQuery bricht Datenfluss (Generalisierung von Regel #6):**
- ALLE DB-Write-Nodes (INSERT/UPDATE/DELETE) geben ihr EIGENES Ergebnis zurueck
- `{success: true}` oder Query-Result - NICHT die Eingangsdaten!
- Betrifft: Postgres, Supabase, MySQL - alle DB-Nodes mit executeQuery
- Fix: Fan-out Pattern oder Node am Ende der Kette platzieren

**🔴 Fan-out Pattern fuer parallele DB-Writes:**
```
// n8n Connection JSON - ein Output an mehrere Targets:
"Kosten Tracken": {
    "main": [[
        {"node": "JSON Validieren", "type": "main", "index": 0},
        {"node": "Kosten Loggen", "type": "main", "index": 0}
    ]]
}
// → Beide Nodes erhalten die GLEICHEN Eingangsdaten von Kosten Tracken
```

**🔴 SQL-Injection durch LLM-Output:**
- LLM-generierter Text enthaelt Apostrophe, Anfuehrungszeichen, Sonderzeichen
- In n8n Expression `{{ $json.llm_text }}` direkt in SQL = Injection-Risiko
- Fix: Code Node baut escaped SQL, PG Node fuehrt `{{ $json._sql }}` aus
- Escape-Funktion: `String(s).replace(/'/g, "''")`

**🔴 PG NUMERIC → String in n8n:**
- PostgreSQL NUMERIC-Spalten kommen als String an (z.B. `"1.50"` statt `1.50`)
- `.toFixed()` auf String = TypeError
- IMMER `Number()` wrappen: `Number(budget.tages_limit).toFixed(2)`

**🟡 OpenRouter HTTP Request Config:**
```
specifyBody: "string"          // NICHT "json"!
contentType: "raw"
rawContentType: "application/json"
body: "={{ JSON.stringify({ model: '...', messages: [...] }) }}"
```
- `specifyBody: "json"` bricht wenn Prompts Sonderzeichen enthalten
- `specifyBody: "string"` mit manueller Serialisierung ist sicher

**🟡 n8n Timezone:**
- Container laeuft UTC (kein `GENERIC_TIMEZONE` gesetzt)
- Alle Cron-Expressions sind UTC-basiert
- 08:00 UTC = 09:00 CET (Winter) / 10:00 CEST (Sommer)

**🟡 Agent System Credentials:**
| Credential | ID | Zweck |
|------------|-----|-------|
| postgres-local | LYUdGid4dzQwI8iP | n8n_agents DB (Port 5435) |
| OpenRouter | JDjnOpGlLzqfePON | LLM API |
| Telegram | V5Uu10rEX9pFxQr2 | Chat-ID 2061281331 |
| SerpAPI | Wf09NDPygzEeQhYT | Web-Suche |

---

### 2026-02-19 - Formular Konverter: Hardened Image, EXDEV, mammoth.js, Claude API

**🔴 n8n Docker Image ist Hardened Alpine:**
- `apk`, `pip`, `python3` sind ENTFERNT - keine Installation moeglich
- `localFileTrigger` Node existiert NICHT
- Workaround DOCX: `mammoth.js` (npm) statt `python-docx`
- Workaround File-Watch: `scheduleTrigger` v1.2 (Polling alle 5 Min)
- npm install persistiert: `npm install mammoth --prefix /home/node/.n8n`
- Env: `NODE_FUNCTION_ALLOW_EXTERNAL=mammoth` in docker-compose.yml

**🔴 EXDEV: cross-device link not permitted:**
- Docker-Volumes fuer `/datenbank/eingang/` und `/datenbank/verarbeitet/` sind SEPARATE Host-Mounts
- `fs.renameSync()` zwischen Mounts → EXDEV Error
- Fix: `fs.copyFileSync(src, dst); fs.unlinkSync(src);`

**🟡 Anthropic API direkt aus n8n HTTP Request:**
```
specifyBody: "string"
contentType: "raw"
rawContentType: "application/json"
Header: x-api-key = {{ $env.ANTHROPIC_API_KEY }}
Body: JSON.stringify({ model: "claude-sonnet-4-5-20250929", max_tokens: 16384, ... })
```
- Gleiche Config wie OpenRouter (BEVORZUGT #6)
- `max_tokens: 16384` fuer grosse Dokumente (Standard 8192 reicht nicht fuer 60+ Felder)

**🟡 Claude max_tokens Truncation Recovery:**
```javascript
// Wenn stop_reason === 'max_tokens':
const lastComplete = jsonStr.lastIndexOf('},');
if (lastComplete > 0) {
  let repaired = jsonStr.substring(0, lastComplete + 1);
  // Offene Brackets/Braces zaehlen und schliessen
  const openBrackets = (repaired.match(/\[/g) || []).length - (repaired.match(/\]/g) || []).length;
  const openBraces = (repaired.match(/\{/g) || []).length - (repaired.match(/\}/g) || []).length;
  repaired += ']'.repeat(Math.max(0, openBrackets));
  repaired += '}'.repeat(Math.max(0, openBraces));
  return JSON.parse(repaired);
}
```

**🔵 n8n API JSON-Serialisierung Bug:**
- `GET /api/v1/workflows` (ohne limit oder limit>1) gibt manchmal 400 zurueck
- "Bad escaped character in JSON at position 294"
- Ein Workflow in der DB hat problematische Zeichen
- Workaround: Direkt per ID abfragen (`/workflows/{id}`) oder `?limit=1` paginieren

**Formular Konverter Workflow (Referenz):**
- ID: `Vj3rTvIoy7pmdTPY`, 17 Nodes, aktiv
- Zwei-Pass Claude: Konvertierung + KI-Validierung
- Webhook Upload: `POST /webhook/formular-konverter` (lastNode mode, webhookId: `formular-konverter-upload`)
- Manual Trigger: Dateien aus `/datenbank/eingang/`
- Binary: `this.helpers.getBinaryDataBuffer()` fuer v2.8+ filesystem-v2
- Pipeline: Upload/Scan → Extract → Claude → Validate → `/datenbank/verarbeitet/`
- Kosten: ~$0.02-0.10 pro Dokument

---

### 2026-02-20 - n8n v2.8.3: Binary Storage, Webhook Paths, lastNode Mode

**🔴 filesystem-v2 Binary Storage (v2.8+):**
- `item.binary.file.data` gibt `"filesystem-v2"` zurueck, NICHT base64!
- `Buffer.from("filesystem-v2", "base64")` erzeugt Muell-Bytes (`~)^+-zo`)
- Fix: `await this.helpers.getBinaryDataBuffer(itemIndex, 'propertyName')`
- Fuer PDF→Claude: Buffer extrahieren, `.toString('base64')`, als JSON-Feld weiterreichen

**🔴 Webhook Path Format (v2.8+):**
- Ohne `webhookId` auf Webhook-Node: Pfad wird `{workflowId}/{nodeNameEncoded}/{path}`
- Fix: `"webhookId": "my-simple-id"` auf dem Webhook-Node setzen
- Dann wird der Pfad einfach `/webhook/{path}`

**🔴 responseMode "responseNode" unzuverlaessig (v2.8+):**
- Gibt manchmal `{"myField":"value"}` sofort zurueck statt auf respondToWebhook zu warten
- Fix: `"responseMode": "lastNode"` - wartet auf Execution-Ende
- Output des letzten ausgefuehrten Nodes wird als HTTP-Response zurueckgegeben
- Keine respondToWebhook Nodes noetig - Terminal-Nodes liefern direkt

**🔴 workflow_history: ALLE Versionen updaten!**
- API activate waehlt EIGENE Version aus History (nicht vorhersagbar)
- Nur activeVersionId updaten reicht NICHT
- Fix: `UPDATE workflow_history SET nodes=..., connections=... WHERE workflowId='...'` (alle!)

**🟡 execution_data Format:**
- Tabelle `execution_data` (nicht `execution_entity`) enthaelt Execution-Daten
- Format: flatted/devalue (Array mit nummerierten Referenzen), NICHT plain JSON
- Fuer Debugging: Indizes manuell aufloesen oder n8n UI nutzen

---

### 2026-02-14 - chatTrigger Routing, API Settings, Trigger Detection

**🔴 chatTrigger + respondToWebhook = "No response"!**

```
Chat-Trigger → Agent → Grounding_Verifier → respondToWebhook
                                              ↑ gibt NICHTS zurück!
                                              → chatTrigger bekommt kein output
                                              → "No response. Make sure the last node outputs the content to display."
```

**Fix: Routing nach Trigger-Typ**
```
Agent → Grounding_Verifier → Trigger_Router (Code) → Ist_Webhook? (IF)
  TRUE  → Check Agent Error → Respond Chat API (respondToWebhook)
  FALSE → Chat_Antwort (Set: { output: $json.output })
```

**Trigger-Erkennung Pattern:**
```javascript
// In Code Node nach dem Agent:
let isApiWebhook = false;
try {
  const fci = $('Format Chat Input').first();
  if (fci && fci.json) isApiWebhook = true;
} catch(e) {
  isApiWebhook = false;
}
return { json: { ...$json, _isApiWebhook: isApiWebhook } };
```

**🔴 n8n API PUT settings: NUR executionOrder!**
```python
# Alle anderen Felder (timezone, callerPolicy, timeSavedMode, availableInMCP)
# verursachen Validation Error!
put_payload = {
    "nodes": wf['nodes'],
    "connections": wf['connections'],
    "settings": {"executionOrder": "v1"},  # NUR das!
    "name": wf['name']
}
```

**🟡 API Update-Zyklus für Webhook-Re-Registrierung:**
```bash
# 1. PUT workflow update
# 2. POST /workflows/{id}/deactivate
# 3. sleep 2
# 4. POST /workflows/{id}/activate
# → Webhooks werden erst nach Deaktivierung/Aktivierung re-registriert
```

---

### 2026-02-24 - Security Hardening: chatTrigger public, toolName, placeholders, Sticky Notes

**🔴 chatTrigger braucht `public: true` fuer Production-Webhooks:**
- Ohne `public: true` wird KEIN Production-Webhook registriert
- Workflow zeigt `active: true` aber `/webhook/{id}/chat` gibt 404
- Symptom: "The requested webhook is not registered" trotz Aktivierung
- Entdeckt bei: AI Research Agent v3 (4OlKW72H47VEXV0i)
- Vergleich: NASDAQ-Workflow (v1.1, public:true) → HTTP 200, unserer (v1.1, ohne) → 404

**🔴 toolHttpRequest Node-Namen muessen alphanumerisch sein (v2.9+):**
- "Web Search (SerpAPI)" → "The name of this tool is not a valid alphanumeric string"
- Fix: `web_search` (nur `[a-zA-Z_][a-zA-Z0-9_]*`)
- Der Node-Name wird 1:1 als Tool-Name an den Agent uebergeben
- Agent versucht Tool mit dem Node-Namen aufzurufen

**🔴 placeholderDefinitions + $fromAI() = Konflikt:**
- "Misconfigured placeholder 'query'" wenn beides gesetzt
- Fix: `placeholderDefinitions` entfernen, nur `$fromAI()` im URL nutzen
- Alternativ: nur `placeholderDefinitions` mit `{query}` Syntax (ohne $fromAI)

**🟡 Sticky Notes via API (programmatisch):**
```json
{
  "type": "n8n-nodes-base.stickyNote",
  "typeVersion": 1,
  "parameters": {
    "content": "## Titel\nMarkdown-Inhalt",
    "width": 300,
    "height": 200,
    "color": 4
  },
  "position": [x, y]
}
```
- Farben: 2=rot, 3=gelb, 4=blau, 5=lila, 6=gruen
- Werden als normale Nodes im PUT payload mitgeschickt

**🟡 httpQueryAuth Credential fuer API-Keys in toolHttpRequest:**
- `POST /api/v1/credentials` mit `type: "httpQueryAuth"`, `data: { name: "api_key", value: "..." }`
- n8n API verschluesselt die Credentials korrekt (CryptoJS AES)
- Node-Config: `authentication: "genericCredentialType"`, `genericAuthType: "httpQueryAuth"`
- Entfernt API-Keys aus URL-Klartext (A02:2021 Cryptographic Failures)

**🟡 CWE-918 SSRF Mitigation in Input Validation:**
```javascript
// Vor dem Agent: URLs und Expressions aus User-Input strippen
const sanitized = msg.trim()
  .replace(/https?:\/\/[^\s]+/gi, '[URL entfernt]')
  .replace(/\{\{.*?\}\}/g, '')           // n8n Expression-Syntax
  .replace(/\$fromAI\(.*?\)/g, '');      // $fromAI() Injection
```

**n8n Version: 2.9.2** (nicht 2.8.3 wie zuvor dokumentiert)

---

## Nützliche Links

- n8n Dokumentation: https://docs.n8n.io
- Diana's n8n-Instanz: http://192.168.22.90:5678 (intern)
- Workflow-Backups: NextCloud/n8n-backups/
