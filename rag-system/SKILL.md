# RAG-System Skill – Retrieval Augmented Generation für Diana

| name | description |
|------|-------------|
| rag-system | Hilft beim Aufbau und Betrieb von RAG-Pipelines mit Supabase, Ollama und n8n. Optimiert für Dokumenten-Verarbeitung und semantische Suche. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**

Stell dir vor, du hast eine riesige Bibliothek mit 1000 Büchern. Jemand fragt dich: "Was steht über Dinosaurier in den Büchern?"

**Ohne RAG:**
Die KI kennt nur das, was sie in der Schule gelernt hat (Training). Sie weiß nichts über DEINE speziellen Bücher.

**Mit RAG:**
1. **R**etrieval (Abrufen): Du suchst erst die relevanten Bücher raus
2. **A**ugmented (Erweitert): Du gibst diese Bücher der KI
3. **G**eneration (Erzeugen): Die KI antwortet basierend auf DEINEN Büchern

**Ergebnis:** Die KI kann jetzt über DEINE Dokumente sprechen – zum Beispiel über Medifox-Anleitungen!

---

## Diana's RAG-Setup

### Komponenten-Übersicht

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  NextCloud  │────▶│    n8n      │────▶│  Supabase   │
│  (Dokumente)│     │ (Verarbeit.)│     │ (Vektoren)  │
└─────────────┘     └──────┬──────┘     └──────┬──────┘
                          │                    │
                    ┌─────▼─────┐              │
                    │  Ollama   │              │
                    │(Embeddings)│             │
                    └───────────┘              │
                                               │
┌─────────────┐     ┌─────────────┐            │
│   Benutzer  │────▶│  Claude/    │◀───────────┘
│   (Frage)   │     │  Open-WebUI │
└─────────────┘     └─────────────┘
```

### Technische Details

| Komponente | Technologie | Zweck |
|------------|-------------|-------|
| **Dokumenten-Quelle** | NextCloud auf NAS | PDFs, Docs speichern |
| **Orchestrierung** | n8n Workflows | Automatische Verarbeitung |
| **Embedding-Modell** | Ollama (nomic-embed-text) | Text → Vektoren |
| **Vektor-Datenbank** | Supabase pgvector | Speicher + Suche |
| **LLM** | Claude / Ollama | Antworten generieren |

---

## Was sind Vektoren und Embeddings?

**Für 12-Jährige:**

Stell dir vor, du willst ähnliche Bücher finden. Du könntest:
- Nach Titel suchen → Findet nur exakte Wörter
- Nach Kategorie suchen → Zu ungenau

**Embeddings** sind wie eine magische Übersetzung:
- Jeder Text wird zu einer langen Zahlenliste (z.B. 768 Zahlen)
- Ähnliche Texte haben ähnliche Zahlen
- "Hund" und "Welpe" haben ähnliche Zahlen
- "Hund" und "Mathematik" haben sehr unterschiedliche Zahlen

**Vektor-Suche:**
Du gibst eine Frage ein → wird zu Zahlen → findet ähnliche Zahlen → gibt passende Texte zurück

---

## Supabase-Setup für RAG

### Tabellen-Struktur

```sql
-- Dokumente-Tabelle mit Vektoren
CREATE TABLE documents (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  metadata JSONB,
  embedding VECTOR(768),  -- Für nomic-embed-text
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für schnelle Vektor-Suche
CREATE INDEX ON documents 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

### Similarity-Search Funktion

```sql
-- Funktion für semantische Suche
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding VECTOR(768),
  match_threshold FLOAT DEFAULT 0.7,
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  id BIGINT,
  content TEXT,
  metadata JSONB,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) AS similarity
  FROM documents
  WHERE 1 - (documents.embedding <=> query_embedding) > match_threshold
  ORDER BY documents.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

---

## RAG-Pipeline in n8n

### Schritt 1: Dokument einlesen

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Webhook  │────▶│ NextCloud│────▶│ PDF      │
│ /ingest  │     │ Download │     │ Extract  │
└──────────┘     └──────────┘     └──────────┘
```

### Schritt 2: Text aufteilen (Chunking)

```
┌────────────────────────────────────────────────────────┐
│                    WARUM CHUNKING?                      │
├────────────────────────────────────────────────────────┤
│ Problem: Ein ganzes Buch ist zu groß für Embeddings    │
│ Lösung:  In kleine Stücke (Chunks) aufteilen           │
│                                                         │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Ganzes Dokument (50 Seiten)                      │   │
│ └──────────────────────────────────────────────────┘   │
│                        ↓                               │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │Chunk1│ │Chunk2│ │Chunk3│ │Chunk4│ │ ...  │         │
│ │500 W │ │500 W │ │500 W │ │500 W │ │      │         │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘         │
└────────────────────────────────────────────────────────┘
```

**Optimale Chunk-Größe:**
- Zu klein (100 Wörter): Kontext geht verloren
- Zu groß (2000 Wörter): Zu unspezifisch
- **Empfohlen: 500-1000 Tokens mit 100-200 Overlap**

### Schritt 3: Embeddings erstellen

```javascript
// In n8n Code-Node
const chunks = $input.all();

// Für jeden Chunk Embedding erstellen
const results = [];
for (const chunk of chunks) {
  const response = await fetch('http://192.168.22.90:11434/api/embeddings', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'nomic-embed-text',
      prompt: chunk.json.text
    })
  });
  
  const data = await response.json();
  results.push({
    json: {
      content: chunk.json.text,
      embedding: data.embedding,
      metadata: chunk.json.metadata
    }
  });
}

return results;
```

### Schritt 4: In Supabase speichern

```javascript
// Supabase Insert
// Nutze den Supabase-Node mit:
// - Table: documents
// - Columns: content, embedding, metadata
```

---

## RAG-Abfrage (Retrieval)

### Der Ablauf einer Frage

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Benutzer  │────▶│  Embedding  │────▶│  Supabase   │
│   "Was ist  │     │  der Frage  │     │  Similarity │
│    SIS?"    │     │  erstellen  │     │  Search     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
┌─────────────┐     ┌─────────────┐            │
│   Antwort   │◀────│    LLM      │◀───────────┘
│  "SIS ist   │     │  mit Kontext│     (Top 5 Chunks)
│   die..."   │     │             │
└─────────────┘     └─────────────┘
```

### Supabase RPC-Aufruf

```javascript
// Frage → Embedding → Suche
const queryEmbedding = await getEmbedding(userQuestion);

const { data: relevantDocs } = await supabase.rpc('match_documents', {
  query_embedding: queryEmbedding,
  match_threshold: 0.7,
  match_count: 5
});

// Kontext für LLM zusammenstellen
const context = relevantDocs
  .map(doc => doc.content)
  .join('\n\n---\n\n');
```

### Prompt-Template für LLM

```
Du bist ein Assistent für Pflegedokumentation.
Beantworte die Frage NUR basierend auf dem folgenden Kontext.
Wenn die Antwort nicht im Kontext steht, sage "Das kann ich aus den 
vorliegenden Dokumenten nicht beantworten."

KONTEXT:
{context}

FRAGE:
{user_question}

ANTWORT:
```

---

## Constraints – Was ich IMMER beachten muss

### 🔴 NIEMALS

0. **NIEMALS** nur eine Suchfunktion optimieren!
   ```
   ❌ Nur fast_search_text optimiert → match_documents vergessen
   ✅ ALLE Suchfunktionen prüfen: match_documents, fast_search_text,
      hybrid_search_v2, hybrid_search
   ```

0b. **NIEMALS** hardcoded Werte in n8n AI-Tools
   ```
   ❌ "value": "KI für Medifox stationär"  // Statisch!
   ✅ "value": "={{ $fromAI('searchQuery', 'Suchanfrage', 'string') }}"
   ```

0c. **NIEMALS** annehmen welcher Workflow aktiv ist
   ```
   ❌ "Ich optimiere RAG_enhanced_v3.json"
   ✅ "Welcher Workflow wird aktiv genutzt?" → Benutzer fragen!
   ```

1. **NIEMALS** Antworten ohne Quellenangabe bei wichtigen Fakten
   ```
   ✅ "Laut dem Medifox-Handbuch (S. 42) ist SIS..."
   ❌ "SIS ist..." (ohne Quelle)
   ```

2. **NIEMALS** halluzinieren wenn keine relevanten Chunks gefunden
   ```
   ✅ "Zu dieser Frage habe ich keine Informationen in den Dokumenten."
   ❌ "Ich denke, es könnte so sein..." (erfunden)
   ```

3. **NIEMALS** Menüpfade ohne Quellenangabe erfinden!
   ```
   ❌ "Menüpfad: Verwaltung → Bewohnerverwaltung → Bewohnercode"
      (OHNE [Quelle:Seite] = HALLUZINIERT = VERBOTEN!)
   ✅ "Menüpfad: Pflege/Betreuung → Dokumentation [Handbuch:S.45]"
   ✅ "Für diese Funktion habe ich keinen dokumentierten Menüpfad gefunden."
   ```
   → Bei fehlender Dokumentation: `Wissensluecke_melden` Tool nutzen!

4. **NIEMALS** Feature-Unterschiede zwischen n8n-Chat und externer Chat-Seite!
   ```
   ❌ n8n Chat: Screenshots/Bilder, Vision → Chat-Seite: Keine Bilder
      (Feature-Parität MUSS gewährleistet sein!)
   ✅ Beide Oberflächen: Gleiche Features, gleiche Antwortqualität
   ```

   **Aktueller Status (2026-01-27):**
   | Feature | n8n Chat | Chat-Seite |
   |---------|----------|------------|
   | Text-Chat | ✅ | ✅ |
   | Screenshots/Bilder | ✅ allowFileUploads=true | ✅ Implementiert |
   | Vision/OCR | ✅ Claude Sonnet 4.5 Vision | ✅ Claude Sonnet 4.5 Vision |
   | Clipboard Paste (Ctrl+V) | ❌ | ✅ Implementiert |
   | Drag & Drop Upload | ✅ | ✅ Implementiert |
   | EXIF-Stripping | ❌ | ✅ Implementiert |

5. **NIEMALS** sensible Patientendaten in Embeddings speichern
   - Anonymisieren BEVOR Embedding erstellt wird

6. **NIEMALS** zu kleine Chunks ohne Overlap
   - Kontext geht sonst verloren

7. **NIEMALS** pgvector HNSW/IVFFlat Index für >2000 Dimensionen
   ```
   ❌ CREATE INDEX ON docs USING hnsw (embedding vector_cosine_ops)
      -- Fehler bei 3072 dims!
   ✅ Text-Vorfilterung nutzen, dann Vektor-Vergleich auf Subset
   ```

8. **NIEMALS** Embedding als JSON Array an Supabase RPC übergeben
   ```
   ❌ supabase.rpc('search', { embedding: [0.1, 0.2, ...] })
   ✅ supabase.rpc('search', { embedding_text: '[0.1,0.2,...]' })
   ```

9. **NIEMALS** n8n Workflow-HTML nur in einer Tabelle updaten!
   ```
   ❌ UPDATE workflow_entity SET nodes = ...
      (Workflow läuft weiter mit alter Version!)
   ✅ BEIDE Tabellen aktualisieren:
      - workflow_entity (Editor-Version)
      - workflow_history (Runtime-Version - diese wird serviert!)
   ```
   → n8n lädt aktive Workflows aus `workflow_history`, nicht `workflow_entity`!

10. **NIEMALS** localStorage ohne try-catch in n8n Webhook-HTML!
    ```
    ❌ const saved = localStorage.getItem('theme');
       (SecurityError: sandboxed document)
    ✅ try { const saved = localStorage.getItem('theme'); } catch(e) {}
    ```
    → n8n Webhooks können in sandboxed context laufen (origin: null)

13. **NIEMALS** CORS auf spezifische Domain setzen bei n8n Webhook-HTML!
    ```
    ❌ access-control-allow-origin: https://n8n.forensikzentrum.com
       → n8n setzt CSP: sandbox (OHNE allow-same-origin)
       → Browser-Origin wird "null" → CORS-Mismatch → fetch blocked!

    ✅ access-control-allow-origin: *
       → Einzige Option weil sandbox-CSP Origin auf "null" erzwingt
    ```
    → Betrifft ALLE Webhook-Responses (HTML UND JSON-API!)
    → n8n's sandbox-CSP ist NICHT konfigurierbar

11. **NIEMALS** Clipboard nur mit `clipboardData.items` prüfen (Linux/GNOME)!
    ```
    ❌ for (item of e.clipboardData.items) { ... }
       (Funktioniert nicht auf Linux/GNOME!)
    ✅ // Erst files prüfen (Linux/GNOME), dann items
       if (e.clipboardData?.files?.length > 0) { ... }
       else if (e.clipboardData?.items) { ... }
    ```

12. **NIEMALS** generische toolDescription für Vector Store Tools!
    ```
    ❌ "Nutze dieses Tool, um Wissen über MediFox zu erhalten"
       → Agent ruft Tool NICHT auf, antwortet aus eigenem Wissen!

    ✅ "IMMER nutzen für JEDE Frage über MediFox!
       Enthält: Installation, CarePad, App, Smartphone, Handy,
       Dokumentation, Klickpfade, Wunden, SIS, Pflege, Abrechnung...
       MUSS bei JEDER Benutzerfrage aufgerufen werden!"
    ```
    - Bei `mode: "retrieve-as-tool"` → Agent MUSS Tool aktiv aufrufen
    - Ohne Schlüsselwörter in toolDescription → Agent ignoriert Tool
    - System Prompt verstärken: "BEVOR du antwortest, MUSST du Tool aufrufen!"
    - Diagnose: Wenn Agent aus eigenem Wissen antwortet → toolDescription prüfen!

### 🟡 BEVORZUGT

1. **Chunk-Größe:** 500-1000 Tokens
2. **Overlap:** 100-200 Tokens (damit Kontext nicht abreißt)
3. **Embedding-Modell:** nomic-embed-text (768 Dimensionen)
4. **Similarity Threshold:** 0.7 (nicht zu niedrig!)

### 🟢 GUT ZU WISSEN

1. Diana's Supabase-Projekt: wfklkrgeblwdzyhuyjrv
2. Ollama läuft auf NAS Port 11434
3. Medifox-Dokumente in NextCloud gespeichert
4. **Aktiver Chat-Workflow:** SJ47UX9mv8wh1Wwy (RAG_Masterclass_Chat_hybrid)
5. **n8n HTML-Architektur:**
   - n8n serviert NICHT aus Dateien!
   - Inline-HTML liegt in "Respond to Webhook" Node
   - Runtime liest aus `workflow_history` Tabelle
   - DB: `/volume1/docker/n8n/data/database.sqlite`
6. **Cloudflare Errors ignorierbar:**
   - `/cdn-cgi/speculation` - Prefetch-Optimierung
   - `/cdn-cgi/rum` - Real User Monitoring
   - Verursachen "origin null" Fehler, aber harmlos

---

## Quality-Boost für MediFox-Dokumente

Alle Suchfunktionen müssen diesen Boost implementieren:

```sql
-- Quality-Boost Logik (in ALLEN Suchfunktionen!)
CASE
  WHEN metadata->>'source' = 'wissen.medifoxdan.de' THEN 0.15  -- +15%
  WHEN metadata->>'quality' = 'high' THEN 0.10                 -- +10%
  ELSE 0
END AS quality_boost
```

**Betroffene Funktionen:**
| Funktion | Nutzer | Quality-Boost |
|----------|--------|---------------|
| `match_documents` | n8n Supabase Vector Store | ✅ Ja |
| `fast_search_text` | n8n-hybrid Edge Function | ✅ Ja |
| `hybrid_search_v2` | Direkter RPC-Aufruf | ✅ Ja |

---

## Feedback-System (Benutzer-Korrekturen & Wissenslücken)

### Tabellen

| Tabelle | Zweck |
|---------|-------|
| `term_synonyms` | Begriffszuordnungen (z.B. Pseudonym → Bewohnercode) |
| `knowledge_gaps` | Unbeantwortete Fragen zur Nachbearbeitung |
| `user_corrections` | Audit-Trail für Benutzer-Korrekturen |

### SQL-Funktionen

```sql
-- Synonym-Lookup (automatisch in Suchfunktionen)
SELECT resolve_synonym('Pseudonymisierungsliste');  -- → 'Bewohnercode'

-- Query-Transformation (ersetzt alle bekannten Synonyme)
SELECT transform_query_with_synonyms('Pseudonymisierungsliste drucken');
-- → 'Bewohnercode drucken'

-- Benutzer-Synonym hinzufügen
SELECT add_user_synonym('Pseudonym', 'Bewohnercode', 'QPR', 'chat_user');

-- Wissenslücke melden
SELECT report_knowledge_gap('Wie drucke ich Bewohnercode-Liste?', 0.0, 0, 'Keine Doku');
```

### Edge Function: `feedback-processor`

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/feedback-processor`

| Action | Beschreibung |
|--------|--------------|
| `process_message` | Analysiert Chat-Nachricht auf Korrekturen |
| `add_synonym` | Synonym manuell hinzufügen |
| `report_gap` | Wissenslücke melden |
| `get_synonyms` | Alle Synonyme abrufen |

### Workflow-Tools

| Tool | Wann nutzen |
|------|-------------|
| `Feedback_Tool` | Wenn Benutzer sagt "Das heißt X, nicht Y" |
| `Wissensluecke_melden` | Wenn keine passende Antwort gefunden |

### Admin-Abfragen

```sql
-- Offene Wissenslücken (nach Priorität)
SELECT query, occurrence_count, priority, user_feedback
FROM knowledge_gaps WHERE status = 'open'
ORDER BY priority DESC;

-- Meistgenutzte Synonyme
SELECT user_term, canonical_term, usage_count
FROM term_synonyms ORDER BY usage_count DESC;
```

---

## Screenshot-Learning für MediFox Klickpfade (GEPLANT)

### Vision & Use Case

**Problem:** MediFox-Handbücher beschreiben Klickpfade nur textlich. Benutzer schicken Screenshots mit der Frage "Wo muss ich hier klicken?"

**Ziel:** Aufbau einer visuellen Wissensbasis für MediFox-Klickpfade:
1. Benutzer lädt Screenshot hoch
2. Vision-Modell (Claude Sonnet 4.5) analysiert den Screenshot
3. OCR extrahiert sichtbare Texte/Menüs
4. System findet dokumentierte Klickpfade basierend auf erkannten Elementen
5. Bei neuen Pfaden: Benutzer kann annotieren → Learning

### Architektur-Entwurf

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Chat-Seite  │────▶│  n8n oder   │────▶│ Vision-API  │
│ Screenshot  │     │ Edge Func.  │     │ Claude      │
│ Ctrl+V/Drop │     │             │     │ Sonnet 4.5  │
└─────────────┘     └──────┬──────┘     └──────┬──────┘
                          │                    │
                    ┌─────▼─────┐        ┌─────▼─────┐
                    │   OCR     │        │  Analyse  │
                    │ Textextr. │        │ "Was ist  │
                    └─────┬─────┘        │  sichtbar"│
                          │              └─────┬─────┘
                          └──────┬─────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  click_paths Tabelle    │
                    │  screen_region → Pfad   │
                    └─────────────────────────┘
```

### Phase 2 Tabellen (IMPLEMENTIERT 2026-01-27)

```sql
-- UI-Elemente Registry (erkannte Menüs, Buttons, etc.)
CREATE TABLE ui_elements (
  id BIGSERIAL PRIMARY KEY,
  element_name TEXT NOT NULL,       -- "Verwaltung"
  element_type TEXT,                -- "menu", "button", "tab"
  parent_module TEXT,               -- "Hauptmenü"
  keywords TEXT[],                  -- Synonyme/Tags
  embedding VECTOR(1536),           -- text-embedding-3-small
  occurrence_count INT DEFAULT 1,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Klickpfade mit strukturierten Schritten
CREATE TABLE click_paths (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,              -- "Bewohnercode drucken"
  goal TEXT,                        -- "Pseudonymisierungsliste für QPR"
  steps JSONB NOT NULL,             -- [{element, action, screenshot_hash?}]
  tags TEXT[],                      -- ["qpr", "drucken", "bewohner"]
  embedding VECTOR(1536),           -- Für semantische Suche
  helpful_votes INT DEFAULT 0,
  unhelpful_votes INT DEFAULT 0,
  verified BOOLEAN DEFAULT FALSE,
  source_doc TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Benutzer-Annotationen auf Screenshots
CREATE TABLE screenshot_annotations (
  id BIGSERIAL PRIMARY KEY,
  screenshot_hash TEXT NOT NULL,    -- SHA-256 für Deduplizierung
  annotations JSONB NOT NULL,       -- [{type, coords, label, color}]
  context TEXT,                     -- Beschreibung
  click_path_id BIGINT REFERENCES click_paths(id),
  is_public BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Navigation-Graph (Markov-Chain für Pfad-Vorhersage)
CREATE TABLE element_transitions (
  id BIGSERIAL PRIMARY KEY,
  from_element_id BIGINT REFERENCES ui_elements(id),
  to_element_id BIGINT REFERENCES ui_elements(id),
  action_type TEXT,                 -- "click", "hover", "scroll"
  frequency INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### RPC-Funktionen für Klickpfad-Suche

```sql
-- Semantische Klickpfad-Suche
SELECT * FROM match_click_paths(
  query_embedding := '[0.1,0.2,...]'::vector(1536),
  match_threshold := 0.5,
  match_count := 10
);

-- UI-Element-Suche
SELECT * FROM match_ui_elements(
  query_embedding := '[...]'::vector(1536),
  match_threshold := 0.6,
  match_count := 5
);

-- Vote-Increment (Atomic)
SELECT increment_vote(p_path_id := 1, p_column := 'helpful_votes');

-- Verwandte Pfade (gleiche Tags)
SELECT * FROM get_related_paths(p_path_id := 1, limit_count := 5);
```

### Privacy-Anforderungen

| Anforderung | Beschreibung |
|-------------|--------------|
| EXIF-Entfernung | Metadaten vor Speicherung entfernen |
| Keine Raw-Images | Nur Hashes/OCR-Text speichern, keine Bilder |
| Tenant-Isolation | Mandantentrennung bei Multi-Tenant |
| DSGVO-konform | Keine personenbezogenen Daten aus Screenshots |

### UX-Anforderungen

| Feature | Status |
|---------|--------|
| Clipboard Paste (Ctrl+V) | ✅ Implementiert |
| Drag & Drop | ✅ Implementiert |
| File-Button Upload | ✅ Implementiert |
| Auto-Detection "ist Screenshot" | ✅ Implementiert |
| EXIF-Stripping (Privacy) | ✅ Implementiert |
| Image Preview | ✅ Implementiert |

### Implementierungsstatus

**Phase 1 (ABGESCHLOSSEN):**
1. ✅ Chat-Seite: Bild-Upload (Clipboard Ctrl+V, Drag&Drop, File-Button)
2. ✅ EXIF-Strip im Browser via Canvas (keine Metadaten übertragen)
3. ✅ Vision-API: `vision-analyzer` Edge Function (v2: Claude Sonnet 4.5, war GPT-4o)
4. ✅ OCR + Screenshot-Analyse via Claude Vision
5. ✅ Kombination: Vision-Analyse + Benutzer-Frage → RAG-Agent

**Phase 2 (ABGESCHLOSSEN - 2026-01-27):**
6. ✅ click_paths Tabelle + Suche (+ ui_elements, element_transitions)
7. ✅ clickpath-store + clickpath-search Edge Functions
8. ✅ screenshot_annotations Tabelle + Canvas-Annotation UI

**Phase 3 (ABGESCHLOSSEN - 2026-01-27):**
9. ✅ Admin-Panel für Klickpfad-Review (medifox-admin.html)
10. ✅ DSGVO Edge Functions (gdpr-handler, admin-moderation)

### Edge Function: `vision-analyzer` (v2)

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/vision-analyzer`
**Modell:** Claude Sonnet 4.5 (`claude-sonnet-4-5-20250929`) - seit 2026-02-08 (war GPT-4o)
**API-Key:** Liest aus `ANTHROPIC_API_KEY` env var, Fallback: Supabase Vault via `get_secret()`

```json
// Request
{
  "image": "data:image/jpeg;base64,...",
  "query": "Wo muss ich klicken?",
  "context": "MediFox Screenshot"
}

// Response
{
  "success": true,
  "description": "Der Screenshot zeigt das Hauptmenü...",
  "extracted_text": "Verwaltung, Pflege, Dokumentation",
  "ui_elements": ["Tab", "Menü", "Button"],
  "suggested_action": "Klicken Sie auf Pflege/Betreuung"
}
```

### Edge Function: `admin-moderation` (Phase 3)

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/admin-moderation`

| Action | Beschreibung |
|--------|--------------|
| `get_stats` | Dashboard-Statistiken (Pfade, Votes, Queue) |
| `get_paths` | Pfade mit Filter abrufen |
| `verify_path` | Pfad genehmigen + Audit-Log |
| `reject_path` | Pfad ablehnen mit Begründung |
| `edit_path` | Pfad bearbeiten |
| `delete_path` | Pfad löschen |
| `merge_paths` | Duplicate Pfade zusammenführen |
| `bulk_verify` | Mehrere Pfade auf einmal genehmigen |
| `get_audit_log` | Audit-Log abrufen |

**Wichtig:** `verify_jwt: true` - Erfordert Supabase Auth Token!

### Edge Function: `gdpr-handler` (Phase 3)

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/gdpr-handler`

| Action | DSGVO-Artikel | Beschreibung |
|--------|---------------|--------------|
| `export_user_data` | Art. 15 | Alle Daten eines Users als JSON exportieren |
| `delete_user_data` | Art. 17 | Right to be forgotten - Daten löschen |
| `anonymize_user_data` | - | Alternative: Daten anonymisieren statt löschen |
| `get_request_status` | - | Status einer DSGVO-Anfrage prüfen |
| `get_user_requests` | - | Alle Anfragen eines Users |

**Wichtig:** `verify_jwt: true` - Erfordert Supabase Auth Token!

### Phase 3 Governance-Tabellen

```sql
-- Audit-Log für DSGVO-Nachweispflicht
audit_log (action, entity_type, entity_id, actor, old_data, new_data, reason, ip_address)

-- Moderation Queue für Review-Workflow
moderation_queue (entity_type, entity_id, status, priority, assigned_to, notes)

-- DSGVO Lösch-Requests
deletion_requests (request_type, requester_identifier, status, data_scope, processed_items)
```

### Admin-Panel

**Datei:** `/volume1/docker/n8n/medifox-admin.html`

Features:
- Dashboard mit Statistiken (Pfade, Votes, Aktivitäten)
- Klickpfad-Verwaltung (Approve/Reject/Edit/Delete)
- Filter nach Status (pending/approved/rejected)
- Audit-Log Einsicht
- DSGVO-Verwaltung (Export/Löschen/Anonymisieren)

---

### Edge Function: `clickpath-store` (Phase 2)

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/clickpath-store`

| Action | Beschreibung |
|--------|--------------|
| `store_path` | Speichert Klickpfad mit Schritten + generiert Embedding |
| `store_annotation` | Speichert Screenshot-Annotation (Hash-basiert) |
| `vote` | Helpful/Unhelpful Vote für einen Pfad |

```json
// store_path Request
{
  "action": "store_path",
  "title": "Bewohnercode drucken",
  "goal": "Pseudonymisierungsliste für QPR generieren",
  "steps": [
    {"element": "Menü Verwaltung", "action": "click"},
    {"element": "Bewohnerverwaltung", "action": "click"},
    {"element": "Bewohnercode", "action": "click"},
    {"element": "Drucken-Button", "action": "click"}
  ],
  "tags": ["bewohnercode", "drucken", "qpr"]
}
```

### Edge Function: `clickpath-search` (Phase 2)

**URL:** `https://wfklkrgeblwdzyhuyjrv.supabase.co/functions/v1/clickpath-search`

- Unterstützt GET (`?q=suchbegriff`) und POST
- Semantische Suche mit OpenAI text-embedding-3-small (1536 dims)
- Fallback auf FTS bei RPC-Fehlern

```json
// Response
{
  "success": true,
  "results": [
    {
      "id": 1,
      "title": "Bewohnercode drucken",
      "goal": "...",
      "steps": [...],
      "similarity": 0.87,
      "helpful_votes": 5,
      "unhelpful_votes": 0
    }
  ]
}
```

---

## Diagnose-Checklist: RAG-Qualitätsprobleme

Wenn Antworten schlecht sind, prüfe in dieser Reihenfolge:

```
□ 1. Welcher Workflow ist AKTIV? (nicht annehmen!)
     docker exec n8n-n8n-1 n8n list:workflow --active=true

□ 2. Welche Suchfunktion wird aufgerufen?
     - n8n Vector Store → match_documents
     - n8n-hybrid Edge Function → fast_search_text
     - Direkter HTTP → hybrid_search_v2

□ 3. Hat diese Funktion Quality-Boost?
     SELECT pg_get_functiondef(oid) FROM pg_proc
     WHERE proname = 'FUNKTIONSNAME';

□ 4. Wird die Benutzerfrage dynamisch übergeben?
     Suche nach: "KI für Medifox" (hardcoded = FALSCH!)
     Korrekt: $fromAI('searchQuery', ...)

□ 5. Haben alle Dokumente Embeddings?
     SELECT COUNT(*) FROM documents WHERE embedding IS NULL;

□ 6. Funktioniert die Suche überhaupt?
     curl -X POST "https://...functions.supabase.co/n8n-hybrid" \
       -d '{"query": "Dienstplan", "match_count": 3}'

□ 7. RUFT der Agent das Vector Store Tool überhaupt auf?
     Symptom: Agent antwortet generisch aus eigenem Wissen
     Ursache: toolDescription zu generisch!

     Prüfe im Workflow:
     - Vector Store Node → parameters.toolDescription
     - Muss SCHLÜSSELWÖRTER enthalten (App, Smartphone, etc.)
     - Muss explizit sagen: "MUSS aufgerufen werden!"

     Fix:
     "IMMER nutzen für JEDE Frage! Enthält: [alle Themen]..."
```

---

## Embedding-Modelle im Vergleich

| Modell | Dimensionen | Qualität | Geschwindigkeit | pgvector Index |
|--------|-------------|----------|-----------------|----------------|
| **nomic-embed-text** | 768 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Ja |
| **mxbai-embed-large** | 1024 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ Ja |
| **all-minilm** | 384 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Ja |
| **text-embedding-3-small** | 1536 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Ja |
| **text-embedding-3-large** | 3072 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ Nein! |

**Diana's Setup:**
- **n8n Workflow:** text-embedding-3-large (3072 dims) - beste Qualität
- **LightRAG:** text-embedding-3-small (1536 dims) - mit Index möglich

⚠️ **WICHTIG:** Bei >2000 Dimensionen ist kein pgvector HNSW/IVFFlat Index möglich!
Workaround 1: Text-Vorfilterung vor Vektor-Vergleich (siehe `fast_search_text`)
Workaround 2: `halfvec(3072)` mit HNSW-Index (aktuelle Lösung, `embedding_half` Spalte)

---

## LightRAG Integration

Diana nutzt **LightRAG** für Knowledge-Graph-basierte RAG zusätzlich zu reiner Vektor-Suche.

### LightRAG vs. Standard RAG

| Aspekt | Standard RAG | LightRAG |
|--------|--------------|----------|
| Suche | Nur Vektoren | Vektoren + Knowledge Graph |
| Kontext | Chunks | Entitäten + Relationen |
| Ergebnis | Ähnliche Texte | Vernetzte Informationen |

### LightRAG Authentifizierung

```bash
# WICHTIG: LightRAG nutzt JWT Token, NICHT API Key!
TOKEN=$(curl -s -X POST "http://localhost:9621/login" \
  -d "username=admin&password=PASSWORT" | jq -r '.access_token')

# Dann für Anfragen:
curl -H "Authorization: Bearer $TOKEN" http://localhost:9621/query
```

### LightRAG Endpoints

| Endpoint | Methode | Beschreibung |
|----------|---------|--------------|
| `/login` | POST | JWT Token holen (Form-Data!) |
| `/query` | POST | RAG-Anfrage stellen |
| `/documents/scan` | POST | Dokumente indexieren |
| `/documents/pipeline_status` | GET | Indexierungs-Status |
| `/health` | GET | Status + pipeline_busy |

---

## SQL: fast_search_text (für große Embeddings)

Bei >2000 Dimensionen kein Index möglich. Diese Funktion nutzt Text-Vorfilterung:

```sql
CREATE OR REPLACE FUNCTION fast_search_text(
  query_text text,
  query_embedding_text text,  -- STRING Format: '[0.1,0.2,...]'
  match_count integer DEFAULT 10
)
RETURNS TABLE (id bigint, content text, metadata jsonb, similarity double precision)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  query_vec vector(3072);
BEGIN
  -- String zu Vector konvertieren
  query_vec := query_embedding_text::vector(3072);

  RETURN QUERY
  WITH text_filtered AS (
    -- Erst Text-Suche (schnell via GIN Index)
    SELECT d.id, d.content, d.metadata, d.embedding
    FROM documents d
    WHERE d.embedding IS NOT NULL
      AND d.content IS NOT NULL
      AND length(d.content) > 150
      AND (
        to_tsvector('german', d.content) @@ websearch_to_tsquery('german', query_text)
        OR d.content ILIKE '%' || split_part(query_text, ' ', 1) || '%'
      )
    LIMIT 200  -- Maximal 200 Kandidaten
  )
  -- Dann Vektor-Vergleich nur auf gefilterte Menge
  SELECT tf.id, tf.content, tf.metadata,
         1 - (tf.embedding <=> query_vec) as similarity
  FROM text_filtered tf
  ORDER BY tf.embedding <=> query_vec
  LIMIT match_count;
END;
$$;
```

---

## Troubleshooting

### Problem: Keine relevanten Ergebnisse

**Mögliche Ursachen:**
1. Threshold zu hoch → Auf 0.5 senken zum Testen
2. Chunks zu groß → Kleiner machen
3. Falsches Embedding-Modell → Konsistent bleiben!

### Problem: Falsche Ergebnisse

**Mögliche Ursachen:**
1. Chunks ohne Kontext → Overlap erhöhen
2. Zu viele irrelevante Dokumente → Metadaten-Filter nutzen
3. Schlechte Chunk-Grenzen → Auf Absätze/Kapitel achten

### Problem: Langsame Suche / Statement Timeout

**Optimierungen:**
1. IVFFlat-Index erstellen (NUR bei ≤2000 Dimensionen!)
2. Bei >2000 dims: `fast_search_text` mit Text-Vorfilterung nutzen
3. Anzahl der Listen im Index erhöhen
4. Weniger Dimensionen (kleineres Modell)

### Problem: Supabase RPC gibt leere Ergebnisse

**Ursache:** Embedding als JSON Array statt String übergeben

```javascript
// ❌ FALSCH - gibt leere Ergebnisse!
const { data } = await supabase.rpc('search', {
  query_embedding: embedding  // Array [0.1, 0.2, ...]
});

// ✅ RICHTIG - zu String konvertieren
const embeddingString = '[' + embedding.join(',') + ']';
const { data } = await supabase.rpc('fast_search_text', {
  query_embedding_text: embeddingString
});
```

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

### 2026-02-10 - marked.js + MediFox Wunddoku + Service-Key Pattern

**Chat-Frontend: marked.js ersetzt Custom-Parser:**
- Vorher (2026-02-08): Custom `formatMessage()` mit manuellen Regex-Regeln
- Problem: Text in schmalen Spalten, Code-Blöcke/Tabellen/Blockquotes nicht unterstützt
- Nachher: **marked.js** (CDN) für professionelles Markdown-Rendering
- Fallback: Simpler Inline-Parser falls CDN nicht erreichbar
- CSS: Vollständige Styles für h1-h4, ul/ol, blockquote, pre/code, table, a, hr
- Clickpath-Visualisierung bleibt erhalten (Placeholder-Extraktion vor marked.parse)

**System-Prompt: Formatierungsanleitung hinzugefügt:**
- Explizite Markdown-Struktur für Anleitungen vs. Wissensfragen
- `##` Hauptabschnitte, nummerierte Listen für Schritte, `**fett**` für UI-Elemente
- Menüpfade immer als: **Reiter → Menüpunkt → Untermenü → Aktion**

**MediFox Wunddokumentation in RAG eingepflegt:**
- 3 neue manual_enrichment Dokumente (IDs: 368702, 368703, 368704):
  - "Ärztliche Verordnung mit Wunddokumentation verknüpfen"
  - "Wunddokumentation in MediFox stationär"
  - "Verordnungsmanagement in MediFox stationär"
- Embeddings via `generate-embeddings` Edge Function generiert
- Quellen: wissen.medifoxdan.de, MediFox Blog, Connect-Handbuch

**Supabase Service-Role Key Pattern:**
- Anon-Key aus HTML-Config kann ungültig/expired sein!
- Service-Role Key aus n8n Credential entschlüsseln:
  ```python
  # 1. Credential aus credentials_entity lesen (id = 'xG3IsdqbYMiWY8oP')
  # 2. Mit N8N_ENCRYPTION_KEY (EVP_BytesToKey + AES-256-CBC) entschlüsseln
  # 3. JSON parsen → creds['serviceRole']
  ```
- Service-Role Key umgeht RLS → für Inserts/Updates nutzen

**generate-embeddings Edge Function direkt aufrufbar:**
```bash
curl -X POST "$SUPABASE_URL/functions/v1/generate-embeddings" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -d '{"document_ids": [368702, 368703, 368704], "batch_size": 3}'
# → {"message":"Processed 3 documents","successful":3,"failed":0}
```

**Webhook-Cache nach API PUT:**
- n8n cached Webhook-Handler im Speicher
- Nach API PUT: deactivate + activate ODER docker restart nötig
- Ohne dies liefert Webhook weiterhin alte HTML-Version

---

### 2026-02-08 - Claude Sonnet 4.5 Migration + Chat-Frontend

**GPT-4o Ersatz (Deprecation 2026-02-13):**
- Chat-Modell: `gpt-4o` → `claude-sonnet-4-5-20250929` (Anthropic Chat Model Node)
- vision-analyzer Edge Function: GPT-4o Vision → Claude Sonnet 4.5 Messages API (v2)
- Embeddings (`text-embedding-3-large`) NICHT betroffen

**Anthropic API-Key Storage:**
- n8n: Credential `8vuwy9VrY5EheWYB` (AES-256-CBC verschluesselt, CryptoJS Format)
- Supabase: Vault Secret `ANTHROPIC_API_KEY` + `get_secret()` RPC-Funktion (SECURITY DEFINER)

**Chat-Frontend formatMessage() v1 (Custom-Parser, ERSETZT durch marked.js am 2026-02-10):**
- Nummerierte Listen (`msg-ol`), verschachtelte Listen, Abschnitts-Cards, `hr`
- CSS: `.msg-ol` mit Counter-Kreisen, `.msg-section` mit Background, `.msg-hr`
- Problem: Text in schmalen Spalten bei komplexem Markdown → durch marked.js gefixt

**API-Key Validierung:**
- IMMER pruefen ob Key doppeltes Prefix hat (z.B. `sk-ant-api03-sk-ant-api03-`)
- Anthropic Key Format: `sk-ant-api03-{random}-{suffix}` (genau EIN Prefix)

---

### 2026-02-08 - Level 2 Deep-Audit: Bulk-Insert Pipeline + Embedding-Generation

**🔴 KRITISCH: RLS blockiert REST API Inserts mit anon key!**

Supabase `documents` Tabelle hat RLS. POST via anon key → HTTP 401.

**Lösung: SECURITY DEFINER Funktion + RPC**

```sql
-- 1. Funktion erstellen (MCP SQL Tool = privilegiert)
CREATE OR REPLACE FUNCTION bulk_insert_documents(docs jsonb)
RETURNS TABLE(id bigint) AS $$
BEGIN
  RETURN QUERY
  INSERT INTO documents (content, metadata)
  SELECT d->>'content', (d->'metadata')::jsonb
  FROM jsonb_array_elements(docs) AS d
  RETURNING documents.id;
END;
$$ LANGUAGE plpgsql;

-- 2. SECURITY DEFINER setzen (bypassed RLS)
ALTER FUNCTION bulk_insert_documents(jsonb) SECURITY DEFINER;

-- 3. Via REST API aufrufen (Python urllib)
-- POST /rest/v1/rpc/bulk_insert_documents
-- Body: {"docs": [{"content": "...", "metadata": {...}}, ...]}

-- 4. SOFORT nach Gebrauch entfernen!
DROP FUNCTION bulk_insert_documents(jsonb);
```

**🔴 NIEMALS SQL Content manuell kürzen!**

```
❌ Batch-SQL von Hand an MCP Tool übergeben → Content wird gekürzt
❌ Manuelles Copy-Paste großer SQL-Strings → Datenverlust

✅ Python json.dumps() für korrektes JSON-Escaping
✅ Dollar-Quoting ($tag$...$tag$) für SQL-Strings
✅ Automatisiertes Script für Batch-Verarbeitung
```

**🟢 Embedding-Generation via Edge Function**

```python
# generate-embeddings Edge Function
# - batch_size=20 (optimal)
# - ~2 Sekunden pro Call (20 docs = 20 OpenAI API calls)
# - 201 Docs = 12 Calls, 0 Fehler
# - text-embedding-3-large, 3072 Dimensionen
# - embedding_half (halfvec) wird automatisch via Trigger synchronisiert
```

**🟢 Confluence Wiki Scraping Pattern**

```bash
# MediFox Wiki API (öffentlich, kein Auth nötig)
GET https://wissen.medifoxdan.de/rest/api/content/{PAGE_ID}?expand=body.storage
# → title, body.storage.value (HTML)

# Inventar aller Seiten:
GET https://wissen.medifoxdan.de/rest/api/content?spaceKey=MSKB&limit=500
```

**DB-Status nach Deep-Audit (2026-02-08):**

| Quelle | Docs | Embeddings |
|---|---|---|
| blob | 1033 | 100% |
| wissen.medifoxdan.de | 247 | 100% |
| manual_enrichment | 88 | 100% |
| system_reference | 1 | 100% |
| **Total** | **1369** | **100%** |

---

### 2026-02-07 - Form Upload Fix, Sandbox-CORS, Delete-Dataflow

**🔴 CORS in n8n Webhook-HTML: Immer `*` verwenden!**

n8n setzt `Content-Security-Policy: sandbox` (ohne `allow-same-origin`) auf ALLE Webhook-Responses. Das macht die Seiten-Origin zu `null`. Spezifische CORS-Domains (`https://domain.com`) matchen niemals `null` → fetch schlägt fehl.

**🔴 Supabase Delete/Update Nodes zerstören Datenfluss!**

```
FormTrigger → Delete → SetNode($json.field)  ← $json.field = null!
```

Delete/Update-Nodes geben `{}` zurück — JSON UND Binary gehen verloren.

**Fix:** Code-Node mit expliziter Referenz auf Upstream:
```javascript
const formData = $('On form submission').first();
return { json: {...formData.json}, binary: formData.binary };
```

**🔴 n8n Form Trigger URLs:**
- Form-URL: `/form/{webhookId}` — NICHT `/form/{workflowId}`!
- HTML-Feldnamen: `field-0`, `field-1` etc. — NICHT die Label-Namen!

---

### 2026-01-30 - Feedback Auto-Apply & Cloudflare Info

**🔴 Präferenz: User Feedback IMMER automatisch übernehmen!**

Diana möchte KEINE manuelle Review von Benutzer-Korrekturen.

**Altes Verhalten:**
```
user_corrections.applied = false  # Wartet auf Review
```

**Neues Verhalten (feedback-processor v3):**
```javascript
// Korrektur erkannt → SOFORT übernehmen
await supabase.from('user_corrections').insert({
  ...correction,
  applied: true  // DIREKT als applied markieren
});

// Synonym einfügen (Original + Lowercase)
await supabase.from('term_synonyms').upsert([
  { user_term: correction.userTerm, canonical_term: correction.canonicalTerm, ... },
  { user_term: correction.userTerm.toLowerCase(), ... }
]);
```

**Benutzer-Nachricht:** "Danke! Ich merke mir: X = Y"

---

**🔵 Cloudflare CDN CORS-Fehler ignorieren**

Diese Fehler in der Browser-Konsole sind **HARMLOS**:
- `/cdn-cgi/speculation` - Cloudflare Speculation Rules (Pre-Loading)
- `/cdn-cgi/rum` - Cloudflare Real User Monitoring

**Ursache:** Origin ist `null` bei bestimmten Konstellationen.
**Auswirkung:** KEINE - Chat-Funktionalität ist nicht betroffen.

---

### 2026-01-27 - Phase 3: Admin-Panel + DSGVO implementiert

**Neue Komponenten:**

| Komponente | Beschreibung |
|------------|--------------|
| `audit_log` Tabelle | Alle Admin-Aktionen für DSGVO-Nachweis |
| `moderation_queue` Tabelle | Review-Workflow für Pfade |
| `deletion_requests` Tabelle | DSGVO-Anfragen tracking |
| `admin-moderation` Edge Function | Verify/Reject/Edit/Merge/Delete |
| `gdpr-handler` Edge Function | Export/Delete/Anonymize |
| `medifox-admin.html` | Admin-Panel UI |

**DSGVO-Compliance:**
- Art. 15 (Auskunftsrecht): `export_user_data` exportiert alle Daten als JSON
- Art. 17 (Recht auf Löschung): `delete_user_data` löscht alle personenbezogenen Daten
- Anonymisierung als Alternative zur Löschung (für statistische Zwecke)
- Audit-Log dokumentiert alle Änderungen (Wer, Wann, Was, IP)

**Admin-Workflow:**
```
Neuer Pfad eingereicht → moderation_queue (pending)
    ↓
Admin prüft im Admin-Panel
    ↓
Approve → verified=true, audit_log Eintrag
Reject → rejected_reason, audit_log Eintrag
```

---

### 2026-01-27 - Phase 2: Klickpfad-Wissensbasis implementiert

**Neue Komponenten:**

| Komponente | Beschreibung |
|------------|--------------|
| `ui_elements` Tabelle | Registry aller erkannten MediFox UI-Elemente |
| `click_paths` Tabelle | Strukturierte Klickpfade mit JSONB-Steps |
| `screenshot_annotations` | Canvas-Annotationen auf Screenshots |
| `element_transitions` | Markov-Chain für Navigation-Vorhersage |
| `clickpath-store` Edge Function | Store + Vote für Pfade |
| `clickpath-search` Edge Function | Semantische Suche mit OpenAI |

**Architektur-Entscheidungen:**

1. **1536 dims (text-embedding-3-small)** statt 3072 → pgvector HNSW-Index möglich
2. **JSONB für Steps** → Flexible Struktur, jeder Step kann eigenen screenshot_hash haben
3. **SHA-256 Image Hash** → Deduplizierung ohne Bilder zu speichern (Privacy)
4. **Canvas-basierte Annotation** → Rects, Circles, Arrows, Text direkt im Browser
5. **RLS: public read, service write** → Jeder kann lesen, nur Edge Functions schreiben

**Canvas-Annotation-Tools implementiert:**
- `rect` - Rechteck zeichnen
- `circle` - Kreis zeichnen
- `arrow` - Pfeil zeichnen
- `text` - Text-Label platzieren
- 5 Farben: Rot, Blau, Grün, Gelb, Lila

**Touch-Support:** Annotation funktioniert auch auf Mobile (touchstart/touchmove/touchend)

---

### 2026-01-27 - n8n DB-Architektur & Linux/GNOME Fixes

**🔴 KRITISCH: n8n hat ZWEI Workflow-Tabellen!**

```
workflow_entity   → Editor-Version (was du im UI siehst)
workflow_history  → Runtime-Version (was tatsächlich ausgeführt wird!)
```

**Problem:** Database-Update ohne Effekt
- `workflow_entity` aktualisiert → ✅
- n8n neugestartet → Alte Version wird serviert! ❌

**Ursache:** n8n lädt aktive Workflows aus `workflow_history`

**Lösung:**
```python
# BEIDE Tabellen updaten!
cursor.execute("UPDATE workflow_entity SET nodes = ? WHERE id = ?", ...)
cursor.execute("UPDATE workflow_history SET nodes = ? WHERE versionId = ?", ...)
```

---

**🔴 KRITISCH: localStorage in n8n Webhooks**

n8n Webhook-HTML kann in sandboxed context laufen (`origin: null`).

```javascript
// ❌ Fehler: SecurityError: sandboxed document
const saved = localStorage.getItem('theme');

// ✅ Korrekt: Mit try-catch
try { const saved = localStorage.getItem('theme'); } catch(e) {}
```

---

**🟡 Linux/GNOME Clipboard-Fix**

`clipboardData.items` funktioniert nicht zuverlässig auf Linux/GNOME.

```javascript
// ✅ Erst files prüfen (Linux/GNOME), dann items (Windows/Mac)
if (e.clipboardData?.files?.length > 0) {
  for (const file of e.clipboardData.files) { ... }
} else if (e.clipboardData?.items) {
  for (const item of e.clipboardData.items) { ... }
}
```

---

### 2026-01-27 - Vision-Parität & Screenshot-Learning

**🔴 KRITISCH: Feature-Gap zwischen n8n Chat und Chat-Seite!**

| Feature | n8n Chat | Chat-Seite |
|---------|----------|------------|
| Bilder/Screenshots | ✅ allowFileUploads=true | ❌ Fehlt |
| Vision/OCR | ✅ Claude Sonnet 4.5 Vision | ✅ Claude Sonnet 4.5 Vision |

**Neue Anforderung: Screenshot-Learning für MediFox**

Benutzer möchten Screenshots hochladen und fragen: "Wo muss ich hier klicken?"
→ Braucht: Clipboard Paste (Ctrl+V), Drag&Drop, Vision-API

**Architektur dokumentiert:**
- `click_paths` Tabelle für gelernte Klickpfade
- EXIF-Removal für Privacy (keine Metadaten speichern)
- OCR + Keyword-Extraktion aus Screenshots
- Kein Raw-Image Storage (nur Hashes/OCR-Text)

**Implementierungs-Checklist erstellt** (7 Schritte in SKILL.md)

---

### 2026-01-27 - Feedback-System & Anti-Halluzination

**🔴 KRITISCH: Bot halluzinierte Menüpfad!**

Benutzer fragte: "Wie drucke ich eine Pseudonymisierungsliste?"
Bot antwortete mit ERFUNDENEM Pfad: "Verwaltung → Bewohnerverwaltung → Bewohnercode"
→ Dieser Pfad existiert NICHT in der Dokumentation!

**Ursache:**
- Kein Dokument zum Drucken von Bewohnercode-Listen vorhanden
- System-Prompt war nicht streng genug gegen Halluzinationen

**Lösung:**
1. Anti-Halluzinations-Regeln im System-Prompt verschärft
2. `Wissensluecke_melden` Tool hinzugefügt
3. Bei fehlendem Content: Ehrlich antworten statt erfinden

**Feedback-System implementiert:**

```
Benutzer: "Das heißt Bewohnercode, nicht Pseudonym"
         ↓
feedback-processor Edge Function
         ↓
term_synonyms: Pseudonym → Bewohnercode
         ↓
Nächste Suche nutzt automatisch "Bewohnercode"
```

**Neue Komponenten:**
- `term_synonyms` Tabelle (Begriffszuordnungen)
- `knowledge_gaps` Tabelle (Wissenslücken-Tracking)
- `feedback-processor` Edge Function
- `Feedback_Tool` + `Wissensluecke_melden` im Workflow

**Erste Synonyme eingetragen:**
- Pseudonymisierungsliste → Bewohnercode
- Pseudonymisierung → Bewohnercode
- Pseudonym → Bewohnercode

---

### 2026-01-26 - Batch Re-Indexing 503 URL-only Dokumente

**URL-only Dokumente erkennen und fixen:**
```sql
-- PATTERN: Dokumente die nur eine URL enthalten (kein echter Content)
SELECT id, content, metadata->>'source' as source
FROM documents
WHERE content LIKE 'https://nextcloud%'
  AND LENGTH(content) < 300;

-- Ergebnis: 503 Dokumente hatten nur URL statt Volltext
```

**Batch-Update mit Dollar-Quoting (Spezialzeichen-sicher):**
```sql
-- PATTERN: Sichere Updates für Content mit Sonderzeichen
UPDATE documents SET
  content = $c$# Dokumenttitel

**Quelle:** MediFox Stationär Wissensdatenbank
**ID:** 590767

---

[Strukturierter Inhalt mit ## Headers, Aufzählungen, **Keywords**]

**Tags:** tag1, tag2, tag3$c$,
  fts = to_tsvector('german', 'keyword1 keyword2 keyword3')
WHERE id = 347453;

-- ✅ $c$...$c$ verhindert SQL-Injection bei Anführungszeichen, Backslashes etc.
```

**NextCloud WebDAV Download-Pattern:**
```bash
# Korrektes URL-Format für NextCloud WebDAV
NC_USER="diana.goebel@proton.me"
NC_PASS="MCPServer2024Secure"
BASE="https://nextcloud.forensikzentrum.com/remote.php/dav/files/nextcloud/RAG_Masterclass"

# Parallel-Downloads für Batch-Verarbeitung
curl -s -u "$NC_USER:$NC_PASS" "$BASE/filename.md" > /tmp/batch/id.md &
wait  # Warte auf alle parallelen Downloads
```

**🔴 KRITISCH - URL-Fehler beheben:**
```bash
# Malformed: nextcloudRAG_Masterclass (fehlender Slash)
# Korrekt:   nextcloud/RAG_Masterclass

sed 's|/nextcloudRAG_Masterclass/|/nextcloud/RAG_Masterclass/|g'
```

**Ergebnis:** 100 von 503 Dokumenten erfolgreich re-indexiert (20%), weitere 403 pending.

---

### 2026-01-26 - RAG_Masterclass_Chat_hybrid Enhancement

**FTS-Lücke entdeckt und behoben:**
```sql
-- PRÜFEN: Wie viele Dokumente haben keine FTS-Vektoren?
SELECT COUNT(*) FROM documents WHERE fts IS NULL;

-- FIX: FTS für alle Dokumente regenerieren
UPDATE documents
SET fts = to_tsvector('german', COALESCE(content, ''))
WHERE fts IS NULL;
```

**🔴 KRITISCH: FTS kann fehlen bei:**
- Bulk-Imports ohne Trigger
- Alten Dokumenten vor FTS-Einführung
- Dokument-Updates ohne FTS-Regenerierung

**Inventory-Funktionen erstellt:**
```sql
-- Statistiken für Meta-Fragen
SELECT * FROM get_inventory_stats();
-- Liefert: total_chunks, total_files, file_types, avg_length, etc.

SELECT * FROM get_inventory_summary();
-- Liefert: Tabelle mit file_type, count, latest_update
```

**Hybrid-Search Funktion verbessert:**
```sql
-- fast_search_text war zu aggressiv
-- Geändert: length(content) > 10 (statt 150)
-- Geändert: LIMIT 500 (statt 200)
```

**Intent-Klassifizierung im System Prompt:**
- Template A: Inventar/Meta-Fragen ("Was ist in der DB?")
- Template B: Standard RAG-Fragen (Fachfragen)
- Template C: Navigation/Klickpfad-Fragen

**Zitationsformat (VERPFLICHTEND):**
```
[DOKUMENT:S.X-Y §Abschnitt]
Beispiel: [QM-Handbuch:S.45 §Bezugspflege]
```

---

### 2026-01-21 - Supabase Hybrid Search + LightRAG Indexierung

**Probleme gelöst:**

1. **Edge Function gab leere Ergebnisse zurück**
   - Ursache: Supabase RPC erwartet vector als String, nicht JSON Array
   - Lösung: `'[0.1,0.2,...]'` statt `[0.1, 0.2, ...]`

2. **Statement Timeout bei 20.000+ Dokumenten**
   - Ursache: 3072-dim Vektoren können kein HNSW/IVFFlat Index haben
   - Lösung: `fast_search_text` mit Text-Vorfilterung (GIN Index)

3. **LightRAG API "Invalid token"**
   - Ursache: LightRAG erwartet JWT Token, nicht API Key
   - Lösung: Erst `/login` mit Form-Data, dann Bearer Token nutzen

**Erfolge:**
- n8n-hybrid Edge Function v11 funktioniert
- LightRAG indexierte 252 Dokumente erfolgreich
- Knowledge Graph: 4000+ Nodes, 6600+ Edges

**Technische Details:**
- pgvector Index max: 2000 Dimensionen
- text-embedding-3-large: 3072 dims (kein Index!)
- text-embedding-3-small: 1536 dims (Index möglich)
- Deutsche Textsuche: `to_tsvector('german', content)`

---

## Checkliste: Neues Dokument hinzufügen

```
□ 1. Dokument in NextCloud hochladen
□ 2. n8n Webhook triggern (oder manuell)
□ 3. Logs prüfen: PDF extrahiert?
□ 4. Logs prüfen: Chunks erstellt?
□ 5. Logs prüfen: Embeddings generiert?
□ 6. Supabase prüfen: Einträge vorhanden?
□ 7. Test-Abfrage: Relevante Ergebnisse?
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│                   RAG QUICK REFERENCE                   │
├────────────────────────────────────────────────────────┤
│ Embedding-Modell:  text-embedding-3-large (3072 dim)   │
│ Halfvec-Index:     HNSW auf embedding_half (halfvec)   │
│ Chunk-Größe:       1500 chars, 350 overlap             │
│ Similarity:        > 0.7 (Threshold)                   │
│ Top-K:             5 (Anzahl Ergebnisse)               │
├────────────────────────────────────────────────────────┤
│ Supabase:          wfklkrgeblwdzyhuyjrv                │
│ Total Docs:        1372 (247 Wiki, 91 ME, 1033 Blob)  │
│ Embeddings:        100% Abdeckung                      │
│ Ollama-API:        http://192.168.22.90:11434          │
└────────────────────────────────────────────────────────┘
```
