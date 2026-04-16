#!/usr/bin/env bash
set -euo pipefail
source ~/.openclaw/.env.owui
echo "Token Laenge: ${#OWUI_TOKEN}"
echo "Token Prefix: ${OWUI_TOKEN:0:4}"
for path in "/api/v1/knowledge/" "/api/v1/models" "/api/v1/users/"; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 \
        -H "Authorization: Bearer $OWUI_TOKEN" \
        "https://chat.forensikzentrum.com${path}")
    echo "GET $path → HTTP $code"
done
