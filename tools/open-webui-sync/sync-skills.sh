#!/usr/bin/env bash
# Open WebUI Skills Sync
# Nutzt API-Token aus ~/.openclaw/.env.owui um alle SKILL.md Dateien
# als Knowledge Collection "Claude Skills" hochzuladen.
#
# Idempotent: Loescht vorhandene Collection gleichen Namens und legt sie neu an.
# Das vermeidet Duplikate und haelt Inhalt aktuell zu ~/.claude/skills/.

set -euo pipefail

# --- Konfiguration ---
BASE_URL="${OWUI_BASE_URL:-https://chat.forensikzentrum.com}"
COLLECTION_NAME="${OWUI_COLLECTION:-Claude Skills}"
COLLECTION_DESC="Automatisch synchronisierte Skills aus ~/.claude/skills/ (github: jahcoozi92-collab/claude-skills)"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"
ENV_FILE="${OWUI_ENV_FILE:-$HOME/.openclaw/.env.owui}"

# --- Token laden ---
if [[ ! -f "$ENV_FILE" ]]; then
    echo "FEHLER: $ENV_FILE existiert nicht. Anleitung:" >&2
    echo "  echo 'OWUI_TOKEN=sk-xxxx' > $ENV_FILE" >&2
    echo "  chmod 600 $ENV_FILE" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"
if [[ -z "${OWUI_TOKEN:-}" ]]; then
    echo "FEHLER: OWUI_TOKEN nicht gesetzt in $ENV_FILE" >&2
    exit 1
fi

AUTH="Authorization: Bearer $OWUI_TOKEN"

api() {
    # api METHOD PATH [DATA_JSON] [EXTRA_CURL_ARGS...]
    local method="$1" path="$2" data="${3:-}"
    shift 3 2>/dev/null || shift 2
    if [[ -n "$data" ]]; then
        curl -sS -X "$method" "$BASE_URL$path" \
            -H "$AUTH" -H "Content-Type: application/json" \
            -d "$data" "$@"
    else
        curl -sS -X "$method" "$BASE_URL$path" -H "$AUTH" "$@"
    fi
}

echo "[1/5] Teste Auth..."
test_code=$(curl -sS -o /tmp/owui_auth_test.json -w "%{http_code}" \
    -H "$AUTH" "$BASE_URL/api/v1/knowledge/")
if [[ "$test_code" != "200" ]]; then
    echo "FEHLER: Token ungueltig oder abgelaufen (HTTP $test_code)" >&2
    cat /tmp/owui_auth_test.json >&2 2>/dev/null || true
    exit 1
fi
echo "  → Auth OK (HTTP 200)"

echo "[2/5] Alte Collection '$COLLECTION_NAME' loeschen (falls existiert)..."
collections=$(api GET /api/v1/knowledge/)
old_id=$(echo "$collections" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data:
    if c.get('name') == '$COLLECTION_NAME':
        print(c['id']); break
" 2>/dev/null || true)

if [[ -n "$old_id" ]]; then
    api DELETE "/api/v1/knowledge/$old_id/delete" > /dev/null
    echo "  → Alte Collection $old_id geloescht"
fi

echo "[3/5] Neue Collection anlegen..."
new_coll=$(api POST /api/v1/knowledge/create "$(python3 -c "
import json
print(json.dumps({
    'name': '$COLLECTION_NAME',
    'description': '''$COLLECTION_DESC''',
    'data': {},
    'access_control': None
}))")")

COLL_ID=$(echo "$new_coll" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "  → Collection ID: $COLL_ID"

echo "[4/5] SKILL.md Dateien hochladen..."
count=0; failed=0
while IFS= read -r skill_file; do
    name=$(basename "$(dirname "$skill_file")")
    fname=$(basename "$skill_file")
    label="${name}__${fname}"

    # File upload
    file_resp=$(curl -sS -X POST "$BASE_URL/api/v1/files/" \
        -H "$AUTH" \
        -F "file=@$skill_file;filename=$label")
    file_id=$(echo "$file_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)

    if [[ -z "$file_id" ]]; then
        echo "  ✗ $label (Upload-Fehler)"
        failed=$((failed+1))
        continue
    fi

    # Add file to collection
    add_resp=$(api POST "/api/v1/knowledge/$COLL_ID/file/add" "$(python3 -c "
import json; print(json.dumps({'file_id': '$file_id'}))")")

    echo "  ✓ $label"
    count=$((count+1))
done < <(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL*.md" -type f | sort)

echo "[5/5] Fertig."
echo "  Hochgeladen: $count"
echo "  Fehler:      $failed"
echo "  Collection:  $BASE_URL → Workspace → Knowledge → '$COLLECTION_NAME'"
