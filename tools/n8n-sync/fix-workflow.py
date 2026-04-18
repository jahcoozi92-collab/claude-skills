#!/usr/bin/env python3
"""
Fix existing Skills-RAG workflow:
- Set credentials on nodes (API-created workflows lose creds)
- Add missing chunkSize on text splitter
- Add dataType+jsonData on document loader
"""
import json
import os
import sys
import urllib.request
import urllib.error

WF_ID = os.environ.get("WF_ID", "2UlTY8pBaNSOMba4")
N8N_URL = os.environ["N8N_API_URL"]
N8N_KEY = os.environ["N8N_API_KEY"]

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
HEADERS = {"X-N8N-API-KEY": N8N_KEY, "Accept": "application/json", "User-Agent": UA}

CRED_OPENAI = {"id": "QtmiduKKAgX93kQP", "name": "OpenAi account _ RAG_Masterclass"}
CRED_SUPABASE = {"id": "xG3IsdqbYMiWY8oP", "name": "RAG_Masterclass"}

# GET current workflow
req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{WF_ID}", headers=HEADERS)
with urllib.request.urlopen(req, timeout=15) as r:
    wf = json.load(r)

print(f"Loaded: {wf['name']} ({len(wf['nodes'])} nodes)", file=sys.stderr)

# Fix nodes
fixes = 0
for node in wf["nodes"]:
    ntype = node.get("type", "")
    nname = node.get("name", "")

    if ntype == "n8n-nodes-base.supabase":
        node["credentials"] = {"supabaseApi": CRED_SUPABASE}
        print(f"  ✓ Creds: {nname} → Supabase", file=sys.stderr); fixes += 1

    elif ntype == "@n8n/n8n-nodes-langchain.vectorStoreSupabase":
        node["credentials"] = {"supabaseApi": CRED_SUPABASE}
        print(f"  ✓ Creds: {nname} → Supabase", file=sys.stderr); fixes += 1

    elif ntype == "@n8n/n8n-nodes-langchain.embeddingsOpenAi":
        node["credentials"] = {"openAiApi": CRED_OPENAI}
        print(f"  ✓ Creds: {nname} → OpenAI", file=sys.stderr); fixes += 1

    elif ntype == "@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter":
        node.setdefault("parameters", {})["chunkSize"] = 1000
        node["parameters"]["chunkOverlap"] = 200
        print(f"  ✓ Splitter: chunkSize=1000, overlap=200", file=sys.stderr); fixes += 1

    elif ntype == "@n8n/n8n-nodes-langchain.documentDefaultDataLoader":
        p = node.setdefault("parameters", {})
        p["dataType"] = "json"
        p["jsonMode"] = "expressionData"
        p["jsonData"] = "={{ $json.content }}"
        print(f"  ✓ Loader: dataType=json, jsonData set", file=sys.stderr); fixes += 1

print(f"Fixes: {fixes}", file=sys.stderr)

# Felder fuer POST (active/id/createdAt etc. entfernen)
for k in ["id", "active", "isArchived", "createdAt", "updatedAt", "versionId",
          "activeVersionId", "versionCounter", "triggerCount", "shared", "tags",
          "activeVersion", "staticData", "description"]:
    wf.pop(k, None)

# Whitelist: nur Felder die n8n API beim POST erlaubt
allowed = {"name", "nodes", "connections", "settings"}
wf = {k: v for k, v in wf.items() if k in allowed}

# DELETE + POST
print("DELETE + neu POST...", file=sys.stderr)
del_req = urllib.request.Request(
    f"{N8N_URL}/api/v1/workflows/{WF_ID}",
    method="DELETE",
    headers=HEADERS
)
try:
    urllib.request.urlopen(del_req, timeout=10)
except Exception as e:
    print(f"  Delete-Warnung: {e}", file=sys.stderr)

post_headers = dict(HEADERS)
post_headers["Content-Type"] = "application/json"
payload = json.dumps(wf).encode()
req = urllib.request.Request(
    f"{N8N_URL}/api/v1/workflows",
    data=payload,
    method="POST",
    headers=post_headers
)
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        result = json.load(r)
    new_id = result.get("id", "?")
    print(f"\n✓ Workflow neu erstellt: {new_id}", file=sys.stderr)
    print(f"  URL: {N8N_URL}/workflow/{new_id}", file=sys.stderr)
    print(new_id)
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8', errors='replace')
    print(f"FEHLER {e.code}: {body[:500]}", file=sys.stderr)
    sys.exit(1)
