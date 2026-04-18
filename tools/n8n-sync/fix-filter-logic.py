#!/usr/bin/env python3
"""
Fix Filter SKILL*.md Node im Claude-Skills RAG Workflow.
Aktueller Regex matcht 80/80 items (sollte ~24 matchen).
Ersetze Regex durch contains/endsWith + type=blob.
"""
import json, os, sys, urllib.request, urllib.error

WF_ID = os.environ.get("WF_ID", "ezzNsOqkfZ5p2FHQ")
N8N_URL = os.environ["N8N_API_URL"]
N8N_KEY = os.environ["N8N_API_KEY"]
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/122.0.0.0"
HEADERS = {"X-N8N-API-KEY": N8N_KEY, "Accept": "application/json", "User-Agent": UA}

req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{WF_ID}", headers=HEADERS)
with urllib.request.urlopen(req, timeout=15) as r:
    wf = json.load(r)

# Filter-Node fixen
for n in wf["nodes"]:
    if n.get("name") == "Filter SKILL*.md":
        n["parameters"] = {
            "conditions": {
                "options": {
                    "caseSensitive": True,
                    "leftValue": "",
                    "typeValidation": "loose",
                    "version": 2
                },
                "conditions": [
                    {
                        "id": "c1",
                        "leftValue": "={{ $json.path }}",
                        "rightValue": "SKILL",
                        "operator": {"type": "string", "operation": "contains"}
                    },
                    {
                        "id": "c2",
                        "leftValue": "={{ $json.path }}",
                        "rightValue": ".md",
                        "operator": {"type": "string", "operation": "endsWith"}
                    },
                    {
                        "id": "c3",
                        "leftValue": "={{ $json.type }}",
                        "rightValue": "blob",
                        "operator": {"type": "string", "operation": "equals"}
                    }
                ],
                "combinator": "and"
            },
            "options": {}
        }
        print(f"Filter-Logik aktualisiert: contains('SKILL') AND endsWith('.md') AND type=='blob'", file=sys.stderr)
        break

# Whitelist
allowed = {"name", "nodes", "connections", "settings"}
wf = {k: v for k, v in wf.items() if k in allowed}
wf["settings"] = {"executionOrder": "v1"}

# DELETE + POST
for h_req in [urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{WF_ID}", method="DELETE", headers=HEADERS)]:
    try: urllib.request.urlopen(h_req, timeout=10)
    except: pass

post_h = dict(HEADERS); post_h["Content-Type"] = "application/json"
req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows", data=json.dumps(wf).encode(), method="POST", headers=post_h)
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        result = json.load(r)
    new_id = result.get("id")
    print(f"Neue WF ID: {new_id}", file=sys.stderr)
    print(new_id)
    # Aktivieren
    a_req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{new_id}/activate", method="POST", headers=HEADERS)
    urllib.request.urlopen(a_req, timeout=10)
    print("Aktiviert.", file=sys.stderr)
except urllib.error.HTTPError as e:
    print(f"FEHLER {e.code}: {e.read().decode()[:300]}", file=sys.stderr)
    sys.exit(1)
