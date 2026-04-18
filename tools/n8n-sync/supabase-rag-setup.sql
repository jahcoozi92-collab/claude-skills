-- =============================================================
-- Supabase RAG Setup fuer Claude Skills
-- =============================================================
-- Führt aus in: Supabase Dashboard → SQL Editor → New Query → Run
--
-- Erstellt:
--   1. Extensions (vector, pg_trgm fuer FTS)
--   2. Tabelle rag_chunks (fuer Vektor + Metadata)
--   3. Trigger: embedding (vector 3072) → embedding_half (halfvec 3072)
--   4. Indizes: HNSW auf halfvec, GIN auf metadata, FTS auf content
--   5. RPC-Funktion match_qm_chunks (Hybrid-Search mit Boost-System)
--
-- Kompatibel mit:
--   - OpenAI text-embedding-3-large (3072 Dimensionen)
--   - n8n Supabase Vector Store Node
--   - Memory-Boosts: source=system_reference (+0.20), priority=critical (+0.15), quality=high (+0.05)
-- =============================================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 2. Tabelle rag_chunks
CREATE TABLE IF NOT EXISTS public.rag_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector(3072),
    embedding_half halfvec(3072),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Trigger: synchronisiert embedding → embedding_half automatisch
--    (halfvec hat 16-bit statt 32-bit → HNSW-Index unter 2000-Dim-Limit moeglich)
CREATE OR REPLACE FUNCTION sync_embedding_to_half()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.embedding IS NOT NULL THEN
        NEW.embedding_half := NEW.embedding::halfvec(3072);
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_embedding_half ON public.rag_chunks;
CREATE TRIGGER trg_sync_embedding_half
    BEFORE INSERT OR UPDATE ON public.rag_chunks
    FOR EACH ROW
    EXECUTE FUNCTION sync_embedding_to_half();

-- 4. Indizes
-- HNSW auf halfvec (cosine similarity)
CREATE INDEX IF NOT EXISTS idx_rag_chunks_embedding_half_hnsw
    ON public.rag_chunks
    USING hnsw (embedding_half halfvec_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- GIN auf metadata JSONB (fuer schnelle Filter nach source/priority etc)
CREATE INDEX IF NOT EXISTS idx_rag_chunks_metadata
    ON public.rag_chunks
    USING gin (metadata);

-- FTS: Full-Text Search auf content (deutsch + englisch)
CREATE INDEX IF NOT EXISTS idx_rag_chunks_content_fts_de
    ON public.rag_chunks
    USING gin (to_tsvector('german', content));

CREATE INDEX IF NOT EXISTS idx_rag_chunks_content_trgm
    ON public.rag_chunks
    USING gin (content gin_trgm_ops);

-- 5. RPC-Funktion: match_qm_chunks (Hybrid-Search mit Boost-System)
CREATE OR REPLACE FUNCTION match_qm_chunks(
    query_embedding vector(3072),
    match_count INT DEFAULT 12,
    filter JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        rc.id,
        rc.content,
        rc.metadata,
        (
            -- Basis: Cosine-Similarity (1 - distance)
            (1 - (rc.embedding_half <=> query_embedding::halfvec(3072)))
            -- Boosts
            + CASE WHEN rc.metadata->>'source' = 'system_reference' THEN 0.20 ELSE 0 END
            + CASE WHEN rc.metadata->>'priority' = 'critical' THEN 0.15 ELSE 0 END
            + CASE WHEN rc.metadata->>'quality' = 'high' THEN 0.05 ELSE 0 END
            + CASE WHEN rc.metadata->>'source' = 'manual_enrichment' THEN 0.03 ELSE 0 END
        )::FLOAT AS similarity
    FROM public.rag_chunks rc
    WHERE rc.embedding_half IS NOT NULL
      AND (filter = '{}'::jsonb OR rc.metadata @> filter)
    ORDER BY similarity DESC
    LIMIT match_count;
END;
$$;

-- 6. RLS: Zunaechst permissive fuer Service-Role (n8n nutzt Service-Role)
--    Fuer anonymen Zugriff: eigene Policies erstellen
ALTER TABLE public.rag_chunks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_role_all" ON public.rag_chunks;
CREATE POLICY "service_role_all" ON public.rag_chunks
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Authenticated users: nur lesen
DROP POLICY IF EXISTS "authenticated_read" ON public.rag_chunks;
CREATE POLICY "authenticated_read" ON public.rag_chunks
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- =============================================================
-- Fertig. Teste mit:
--   SELECT count(*) FROM rag_chunks;
--   SELECT match_qm_chunks(array_fill(0.0, ARRAY[3072])::vector(3072), 5);
-- =============================================================
