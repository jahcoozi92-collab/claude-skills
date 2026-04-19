#!/usr/bin/env python3
"""
Debug: Prueft Open WebUI Knowledge Collection "Claude Skills"
- Collection-Details
- Anzahl Files
- Chunk-Anzahl (Embeddings-Status)
- RAG-Embeddings-Engine
Druckt keine Secrets.
"""
import sqlite3, json, sys

DB_PATH = "/app/backend/data/webui.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. Knowledge Collections
cur.execute("PRAGMA table_info(knowledge)")
k_cols = [r[1] for r in cur.fetchall()]
print(f"knowledge cols: {k_cols}", file=sys.stderr)

cur.execute("SELECT * FROM knowledge")
for row in cur.fetchall():
    d = dict(zip(k_cols, row))
    print(f"\nKnowledge: id={d.get('id','?')[:12]}..., name='{d.get('name','?')}'", file=sys.stderr)
    data = d.get('data')
    if data:
        try:
            dat = json.loads(data) if isinstance(data, str) else data
            file_ids = dat.get('file_ids', []) if isinstance(dat, dict) else []
            print(f"  Files in Collection: {len(file_ids)}", file=sys.stderr)
        except: pass

# 2. Files
cur.execute("PRAGMA table_info(file)")
f_cols = [r[1] for r in cur.fetchall()]
print(f"\nfile cols: {f_cols}", file=sys.stderr)

cur.execute("SELECT COUNT(*) FROM file")
file_count = cur.fetchone()[0]
print(f"Total files: {file_count}", file=sys.stderr)

# Sample files
cur.execute("SELECT id, filename FROM file LIMIT 30")
for fid, fn in cur.fetchall():
    print(f"  file {fid[:8]}...  {fn}", file=sys.stderr)

# 3. Check if chunks exist for files (knowledge_file table)
cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%chunk%'")
chunk_tables = [r[0] for r in cur.fetchall()]
print(f"\nChunk-verwandte Tabellen: {chunk_tables}", file=sys.stderr)

# knowledge_file
cur.execute("PRAGMA table_info(knowledge_file)")
kf_cols = [r[1] for r in cur.fetchall()]
print(f"knowledge_file cols: {kf_cols}", file=sys.stderr)
cur.execute("SELECT COUNT(*) FROM knowledge_file")
print(f"knowledge_file rows: {cur.fetchone()[0]}", file=sys.stderr)

# 4. RAG Config
cur.execute("SELECT data FROM config")
for (data,) in cur.fetchall():
    try:
        d = json.loads(data)
        rag = d.get("rag", {})
        # Nur strukturelle Info, keine Keys
        print(f"\nRAG Config:", file=sys.stderr)
        print(f"  embedding_engine: {rag.get('embedding_engine','?')}", file=sys.stderr)
        print(f"  embedding_model:  {rag.get('embedding_model','?')}", file=sys.stderr)
        print(f"  embedding_batch_size: {rag.get('embedding_batch_size','?')}", file=sys.stderr)
        print(f"  chunk_size: {rag.get('chunk_size','?')}", file=sys.stderr)
        print(f"  chunk_overlap: {rag.get('chunk_overlap','?')}", file=sys.stderr)
        print(f"  openai_api_key: {'<set>' if rag.get('openai_api_key') else '<empty>'}", file=sys.stderr)
        # Template / query params
        print(f"  template: {'<set>' if rag.get('template') else '<empty>'}", file=sys.stderr)
        print(f"  top_k: {rag.get('top_k','?')}", file=sys.stderr)
    except Exception as e:
        print(f"parse err: {e}", file=sys.stderr)

conn.close()
