#!/usr/bin/env python3
"""
Erstellt einen n8n-Workflow der Skills aus GitHub in Supabase RAG indexiert.
Nutzt bestehende Credentials vom RAG_Masterclass_Chat_hybrid Workflow.
"""
import json
import os
import sys
import urllib.request
import urllib.error

# Credentials aus bestehendem RAG Workflow
CRED_OPENAI = {"id": "QtmiduKKAgX93kQP", "name": "OpenAi account _ RAG_Masterclass"}
CRED_SUPABASE = {"id": "xG3IsdqbYMiWY8oP", "name": "RAG_Masterclass"}

# GitHub Config
GITHUB_OWNER = "jahcoozi92-collab"
GITHUB_REPO = "claude-skills"
GITHUB_BRANCH = "main"

# Supabase Config (aus bestehender Struktur)
SUPABASE_TABLE = "rag_chunks"
SUPABASE_QUERY = "match_qm_chunks"

# Build workflow JSON
workflow = {
    "name": "Claude Skills → Supabase RAG (Auto-Sync)",
    "nodes": [
        # 1. Manual Trigger
        {
            "id": "trigger-manual",
            "name": "Manual Trigger",
            "type": "n8n-nodes-base.manualTrigger",
            "typeVersion": 1,
            "position": [240, 300],
            "parameters": {}
        },
        # 2. Schedule Trigger — täglich 3 AM
        {
            "id": "trigger-schedule",
            "name": "Schedule Trigger",
            "type": "n8n-nodes-base.scheduleTrigger",
            "typeVersion": 1.2,
            "position": [240, 460],
            "parameters": {
                "rule": {
                    "interval": [
                        {"field": "cronExpression", "expression": "0 3 * * *"}
                    ]
                }
            }
        },
        # 3. HTTP Request — Git tree rekursiv
        {
            "id": "github-tree",
            "name": "GitHub: Get Tree",
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4.2,
            "position": [460, 380],
            "parameters": {
                "url": f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/git/trees/{GITHUB_BRANCH}",
                "sendQuery": True,
                "queryParameters": {
                    "parameters": [
                        {"name": "recursive", "value": "1"}
                    ]
                },
                "options": {}
            }
        },
        # 4. Split Out — jeden Tree-Item einzeln
        {
            "id": "split-tree",
            "name": "Split Tree Entries",
            "type": "n8n-nodes-base.splitOut",
            "typeVersion": 1,
            "position": [680, 380],
            "parameters": {
                "fieldToSplitOut": "tree",
                "options": {}
            }
        },
        # 5. Filter — nur SKILL*.md
        {
            "id": "filter-skills",
            "name": "Filter SKILL*.md",
            "type": "n8n-nodes-base.filter",
            "typeVersion": 2.2,
            "position": [900, 380],
            "parameters": {
                "conditions": {
                    "options": {"caseSensitive": True, "leftValue": "", "typeValidation": "strict"},
                    "conditions": [
                        {
                            "id": "c1",
                            "leftValue": "={{ $json.path }}",
                            "rightValue": "^[^/]+/SKILL[^/]*\\.md$",
                            "operator": {"type": "string", "operation": "regex"}
                        }
                    ],
                    "combinator": "and"
                },
                "options": {}
            }
        },
        # 6. HTTP Request — Raw content holen
        {
            "id": "fetch-raw",
            "name": "Fetch Raw Content",
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4.2,
            "position": [1120, 380],
            "parameters": {
                "url": "=https://raw.githubusercontent.com/" + GITHUB_OWNER + "/" + GITHUB_REPO + "/" + GITHUB_BRANCH + "/{{ $json.path }}",
                "options": {"response": {"response": {"responseFormat": "text"}}}
            }
        },
        # 7. Set Metadata
        {
            "id": "set-metadata",
            "name": "Prepare Metadata",
            "type": "n8n-nodes-base.set",
            "typeVersion": 3.4,
            "position": [1340, 380],
            "parameters": {
                "assignments": {
                    "assignments": [
                        {
                            "id": "m1",
                            "name": "file_id",
                            "value": "=claude_skills__{{ $json.path.replace('/', '__').replace(/[^a-zA-Z0-9._-]/g, '_') }}",
                            "type": "string"
                        },
                        {
                            "id": "m2",
                            "name": "source",
                            "value": "system_reference",
                            "type": "string"
                        },
                        {
                            "id": "m3",
                            "name": "priority",
                            "value": "critical",
                            "type": "string"
                        },
                        {
                            "id": "m4",
                            "name": "quality",
                            "value": "high",
                            "type": "string"
                        },
                        {
                            "id": "m5",
                            "name": "skill_path",
                            "value": "={{ $json.path }}",
                            "type": "string"
                        },
                        {
                            "id": "m6",
                            "name": "content",
                            "value": "={{ $json.data }}",
                            "type": "string"
                        },
                        {
                            "id": "m7",
                            "name": "document_type",
                            "value": "skill_definition",
                            "type": "string"
                        }
                    ]
                },
                "options": {}
            }
        },
        # 8. Delete alte Chunks
        {
            "id": "delete-old",
            "name": "Delete Old Chunks",
            "type": "n8n-nodes-base.supabase",
            "typeVersion": 1,
            "position": [1560, 380],
            "parameters": {
                "operation": "delete",
                "tableId": SUPABASE_TABLE,
                "filterType": "string",
                "filterString": "=metadata->>file_id=eq.{{ $json.file_id }}"
            },
            "credentials": {
                "supabaseApi": CRED_SUPABASE
            }
        },
        # 9. Document Loader
        {
            "id": "doc-loader",
            "name": "Document Loader",
            "type": "@n8n/n8n-nodes-langchain.documentDefaultDataLoader",
            "typeVersion": 1,
            "position": [1780, 540],
            "parameters": {
                "dataType": "json",
                "options": {
                    "metadata": {
                        "metadataValues": [
                            {"name": "file_id", "value": "={{ $json.file_id }}"},
                            {"name": "source", "value": "={{ $json.source }}"},
                            {"name": "priority", "value": "={{ $json.priority }}"},
                            {"name": "quality", "value": "={{ $json.quality }}"},
                            {"name": "skill_path", "value": "={{ $json.skill_path }}"},
                            {"name": "document_type", "value": "={{ $json.document_type }}"}
                        ]
                    },
                    "jsonData": "={{ $json.content }}",
                    "jsonMode": "expressionData"
                }
            }
        },
        # 10. Text Splitter
        {
            "id": "text-splitter",
            "name": "Recursive Splitter",
            "type": "@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter",
            "typeVersion": 1,
            "position": [1780, 700],
            "parameters": {
                "chunkSize": 1000,
                "chunkOverlap": 200
            }
        },
        # 11. Embeddings
        {
            "id": "embeddings",
            "name": "Embeddings OpenAI",
            "type": "@n8n/n8n-nodes-langchain.embeddingsOpenAi",
            "typeVersion": 1.2,
            "position": [1780, 860],
            "parameters": {
                "model": "text-embedding-3-large",
                "options": {"dimensions": 3072}
            },
            "credentials": {
                "openAiApi": CRED_OPENAI
            }
        },
        # 12. Vector Store Insert
        {
            "id": "vector-insert",
            "name": "Supabase Vector Insert",
            "type": "@n8n/n8n-nodes-langchain.vectorStoreSupabase",
            "typeVersion": 1.1,
            "position": [2000, 380],
            "parameters": {
                "mode": "insert",
                "tableName": {
                    "__rl": True,
                    "value": SUPABASE_TABLE,
                    "mode": "list",
                    "cachedResultName": SUPABASE_TABLE
                },
                "options": {"queryName": SUPABASE_QUERY}
            },
            "credentials": {
                "supabaseApi": CRED_SUPABASE
            }
        }
    ],
    "connections": {
        "Manual Trigger": {
            "main": [[{"node": "GitHub: Get Tree", "type": "main", "index": 0}]]
        },
        "Schedule Trigger": {
            "main": [[{"node": "GitHub: Get Tree", "type": "main", "index": 0}]]
        },
        "GitHub: Get Tree": {
            "main": [[{"node": "Split Tree Entries", "type": "main", "index": 0}]]
        },
        "Split Tree Entries": {
            "main": [[{"node": "Filter SKILL*.md", "type": "main", "index": 0}]]
        },
        "Filter SKILL*.md": {
            "main": [[{"node": "Fetch Raw Content", "type": "main", "index": 0}]]
        },
        "Fetch Raw Content": {
            "main": [[{"node": "Prepare Metadata", "type": "main", "index": 0}]]
        },
        "Prepare Metadata": {
            "main": [[{"node": "Delete Old Chunks", "type": "main", "index": 0}]]
        },
        "Delete Old Chunks": {
            "main": [[{"node": "Supabase Vector Insert", "type": "main", "index": 0}]]
        },
        "Document Loader": {
            "ai_document": [[{"node": "Supabase Vector Insert", "type": "ai_document", "index": 0}]]
        },
        "Recursive Splitter": {
            "ai_textSplitter": [[{"node": "Document Loader", "type": "ai_textSplitter", "index": 0}]]
        },
        "Embeddings OpenAI": {
            "ai_embedding": [[{"node": "Supabase Vector Insert", "type": "ai_embedding", "index": 0}]]
        }
    },
    "settings": {
        "executionOrder": "v1",
        "saveManualExecutions": True,
        "saveDataErrorExecution": "all",
        "saveDataSuccessExecution": "all",
        "executionTimeout": 600
    }
}

# POST to n8n
N8N_URL = os.environ.get("N8N_API_URL", "https://n8n.forensikzentrum.com")
N8N_KEY = os.environ.get("N8N_API_KEY", "")

if not N8N_KEY:
    print("FEHLER: N8N_API_KEY nicht gesetzt", file=sys.stderr)
    sys.exit(1)

# User-Agent setzen — Cloudflare blockt Python-urllib standardmaessig
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
HEADERS = {"X-N8N-API-KEY": N8N_KEY, "Accept": "application/json", "User-Agent": UA}

# Check ob schon existiert
existing_id = None
try:
    req = urllib.request.Request(
        f"{N8N_URL}/api/v1/workflows?limit=200",
        headers=HEADERS
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.load(r)
    for wf in data.get("data", []):
        if wf.get("name") == workflow["name"]:
            existing_id = wf["id"]
            print(f"Existierender Workflow gefunden: {existing_id}", file=sys.stderr)
            break
except Exception as e:
    print(f"Warnung: Workflow-Liste nicht lesbar: {e}", file=sys.stderr)

# Create or update
payload = json.dumps(workflow).encode()

if existing_id:
    print(f"Update existing workflow {existing_id}...", file=sys.stderr)
    del_req = urllib.request.Request(
        f"{N8N_URL}/api/v1/workflows/{existing_id}",
        method="DELETE",
        headers=HEADERS
    )
    try:
        urllib.request.urlopen(del_req, timeout=10)
        print(f"  Alter Workflow {existing_id} geloescht", file=sys.stderr)
    except Exception as e:
        print(f"  Delete-Warnung: {e}", file=sys.stderr)

print("POST neuer Workflow...", file=sys.stderr)
post_headers = dict(HEADERS)
post_headers["Content-Type"] = "application/json"
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
    print(f"\n✓ Workflow erstellt: {new_id}", file=sys.stderr)
    print(f"  Name: {result.get('name')}", file=sys.stderr)
    print(f"  URL:  {N8N_URL}/workflow/{new_id}", file=sys.stderr)
    print(new_id)
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8', errors='replace')
    print(f"\nFEHLER {e.code}: {body[:800]}", file=sys.stderr)
    sys.exit(1)
