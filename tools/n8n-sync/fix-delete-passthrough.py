#!/usr/bin/env python3
"""
Fix: Delete Node returns 0 items → Vector Insert wird nie erreicht.
Loesung:
- Delete Old Chunks: alwaysOutputData=True (gibt immer min 1 item)
- Neuer Code Node 'Restore Metadata' dazwischen, returned Prepare-Metadata items
- Connections neu: Prepare Metadata → Delete → Restore → Vector Insert
"""
import json, os, sys, urllib.request, urllib.error

WF_ID = os.environ.get("WF_ID", "CW3eSYS3On3mxH2K")
N8N_URL = os.environ["N8N_API_URL"]
N8N_KEY = os.environ["N8N_API_KEY"]
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
HEADERS = {"X-N8N-API-KEY": N8N_KEY, "Accept": "application/json", "User-Agent": UA}

# Existing creds (aus RAG_Masterclass_Chat_hybrid)
CRED_OPENAI = {"id": "QtmiduKKAgX93kQP", "name": "OpenAi account _ RAG_Masterclass"}
# User's neuer Supabase Credential (vom User per UI angelegt)
CRED_SUPABASE_NEW = {"id": "CoyX7juKq0AGEqqC", "name": "Supabase account"}

# Get existing
req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{WF_ID}", headers=HEADERS)
with urllib.request.urlopen(req, timeout=15) as r:
    wf = json.load(r)

# IMMER den neuen User-Credential verwenden (alter ist tot)
sb_cred = CRED_SUPABASE_NEW
print(f"Supabase Credential: {sb_cred['id']} ({sb_cred['name']})", file=sys.stderr)

# Fix nodes
fixes = 0
for node in wf["nodes"]:
    t = node.get("type", "")
    nm = node.get("name", "")

    # Credentials IMMER setzen/ueberschreiben (nicht von altem Workflow uebernehmen)
    if t == "n8n-nodes-base.supabase":
        node["credentials"] = {"supabaseApi": sb_cred}
        print(f"  cred: {nm} → {sb_cred['name']}", file=sys.stderr); fixes += 1
    if t == "@n8n/n8n-nodes-langchain.vectorStoreSupabase":
        node["credentials"] = {"supabaseApi": sb_cred}
        print(f"  cred: {nm} → {sb_cred['name']}", file=sys.stderr); fixes += 1
    if t == "@n8n/n8n-nodes-langchain.embeddingsOpenAi":
        node["credentials"] = {"openAiApi": CRED_OPENAI}
        print(f"  cred: {nm} → {CRED_OPENAI['name']}", file=sys.stderr); fixes += 1

    # Delete: alwaysOutputData
    if nm == "Delete Old Chunks":
        node["alwaysOutputData"] = True
        fixes += 1

    # Splitter: chunkSize
    if t == "@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter":
        p = node.setdefault("parameters", {})
        p["chunkSize"] = 1000
        p["chunkOverlap"] = 200
        fixes += 1

    # Loader: dataType + jsonData
    if t == "@n8n/n8n-nodes-langchain.documentDefaultDataLoader":
        p = node.setdefault("parameters", {})
        p["dataType"] = "json"
        p["jsonMode"] = "expressionData"
        # $json = item das im aktuellen Pipeline-Step durchgereicht wird
        # Restore Metadata gibt Prepare Metadata items weiter, also $json.content passt
        p["jsonData"] = "={{ $json.content }}"
        # Metadata-Werte auch: $json.xxx statt $('Prepare Metadata').item.json.xxx
        if "options" in p and "metadata" in p["options"]:
            for mv in p["options"]["metadata"].get("metadataValues", []):
                val = mv.get("value", "")
                if "$('Prepare Metadata').item.json." in val:
                    field = val.split(".")[-1].rstrip(" }")
                    mv["value"] = "={{ $json." + field + " }}"
        fixes += 1

print(f"Bestehende Nodes gefixt: {fixes}", file=sys.stderr)

# Neuer Code-Node: Restore Metadata
restore_node = {
    "id": "restore-metadata",
    "name": "Restore Metadata",
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [1792, 384],
    "parameters": {
        "jsCode": "// Delete Node gibt 0 items zurueck. Wir brauchen die Items\n// vom Prepare-Metadata Node fuer den folgenden Vector-Insert.\nreturn $items('Prepare Metadata').map(i => ({ json: i.json }));"
    },
    "alwaysOutputData": True,
    "executeOnce": True
}

# Add if not present
if not any(n.get("name") == "Restore Metadata" for n in wf["nodes"]):
    wf["nodes"].append(restore_node)
    print("Code-Node 'Restore Metadata' hinzugefuegt", file=sys.stderr)

# Connections: Delete → Restore → Vector Insert
wf["connections"]["Delete Old Chunks"] = {
    "main": [[{"node": "Restore Metadata", "type": "main", "index": 0}]]
}
wf["connections"]["Restore Metadata"] = {
    "main": [[{"node": "Supabase Vector Insert", "type": "main", "index": 0}]]
}
print("Connections aktualisiert: Delete → Restore → Vector Insert", file=sys.stderr)

# Whitelist POST-fields
allowed = {"name", "nodes", "connections", "settings"}
wf = {k: v for k, v in wf.items() if k in allowed}

# settings darf nur executionOrder enthalten (n8n API Schema)
wf["settings"] = {"executionOrder": "v1"}

# DELETE + POST
del_req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows/{WF_ID}", method="DELETE", headers=HEADERS)
try:
    urllib.request.urlopen(del_req, timeout=10)
except Exception as e:
    print(f"DELETE-Warn: {e}", file=sys.stderr)

post_headers = dict(HEADERS)
post_headers["Content-Type"] = "application/json"
payload = json.dumps(wf).encode()
req = urllib.request.Request(f"{N8N_URL}/api/v1/workflows", data=payload, method="POST", headers=post_headers)
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        result = json.load(r)
    new_id = result.get("id", "?")
    print(f"\n✓ Neue Workflow-ID: {new_id}", file=sys.stderr)
    print(f"  URL: {N8N_URL}/workflow/{new_id}", file=sys.stderr)
    print(new_id)
except urllib.error.HTTPError as e:
    print(f"FEHLER {e.code}: {e.read().decode()[:500]}", file=sys.stderr)
    sys.exit(1)
