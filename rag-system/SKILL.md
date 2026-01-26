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

4. **NIEMALS** sensible Patientendaten in Embeddings speichern
   - Anonymisieren BEVOR Embedding erstellt wird

5. **NIEMALS** zu kleine Chunks ohne Overlap
   - Kontext geht sonst verloren

6. **NIEMALS** pgvector HNSW/IVFFlat Index für >2000 Dimensionen
   ```
   ❌ CREATE INDEX ON docs USING hnsw (embedding vector_cosine_ops)
      -- Fehler bei 3072 dims!
   ✅ Text-Vorfilterung nutzen, dann Vektor-Vergleich auf Subset
   ```

7. **NIEMALS** Embedding als JSON Array an Supabase RPC übergeben
   ```
   ❌ supabase.rpc('search', { embedding: [0.1, 0.2, ...] })
   ✅ supabase.rpc('search', { embedding_text: '[0.1,0.2,...]' })
   ```

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
Workaround: Text-Vorfilterung vor Vektor-Vergleich (siehe `fast_search_text`)

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
│ Embedding-Modell:  nomic-embed-text (768 dim)          │
│ Chunk-Größe:       500-1000 Tokens                     │
│ Chunk-Overlap:     100-200 Tokens                      │
│ Similarity:        > 0.7 (Threshold)                   │
│ Top-K:             5 (Anzahl Ergebnisse)               │
├────────────────────────────────────────────────────────┤
│ Ollama-API:        http://192.168.22.90:11434          │
│ Supabase:          wfklkrgeblwdzyhuyjrv                │
│ Dokumente:         NextCloud auf NAS                   │
└────────────────────────────────────────────────────────┘
```
