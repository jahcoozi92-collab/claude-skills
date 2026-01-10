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

3. **NIEMALS** sensible Patientendaten in Embeddings speichern
   - Anonymisieren BEVOR Embedding erstellt wird

4. **NIEMALS** zu kleine Chunks ohne Overlap
   - Kontext geht sonst verloren

### 🟡 BEVORZUGT

1. **Chunk-Größe:** 500-1000 Tokens
2. **Overlap:** 100-200 Tokens (damit Kontext nicht abreißt)
3. **Embedding-Modell:** nomic-embed-text (768 Dimensionen)
4. **Similarity Threshold:** 0.7 (nicht zu niedrig!)

### 🟢 GUT ZU WISSEN

1. Diana's Supabase-Projekt: wfklkrgeblwdzyhuyjrv
2. Ollama läuft auf NAS Port 11434
3. Medifox-Dokumente in NextCloud gespeichert

---

## Embedding-Modelle im Vergleich

| Modell | Dimensionen | Qualität | Geschwindigkeit |
|--------|-------------|----------|-----------------|
| **nomic-embed-text** | 768 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **mxbai-embed-large** | 1024 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **all-minilm** | 384 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Diana's Wahl:** nomic-embed-text (guter Kompromiss)

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

### Problem: Langsame Suche

**Optimierungen:**
1. IVFFlat-Index erstellen (siehe SQL oben)
2. Anzahl der Listen im Index erhöhen
3. Weniger Dimensionen (kleineres Modell)

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

### Session-Learnings:

*Noch keine Learnings erfasst. Führe `/reflect rag-system` nach einer Session aus!*

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
