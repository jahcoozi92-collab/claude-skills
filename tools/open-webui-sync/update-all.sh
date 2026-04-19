#!/usr/bin/env bash
# Orchestriert komplettes Skills-Update fuer Open WebUI Knowledge Collection.
# Idempotent: kann beliebig oft laufen.
# Log-Rotation: nur letzte 10 Runs behalten.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.cache/skill-sync"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "Skill-Sync start: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# 1. Git pull
cd ~/.claude/skills
git pull --quiet --rebase || { echo "git pull failed"; exit 1; }
echo "Git: $(git log -1 --format='%h %s')"

# 2. Sync-Skills → Open WebUI Files + Collection
echo ""
bash "$SCRIPT_DIR/sync-skills.sh"

# 3. Link (Fix fuer v0.8 API-Bug)
echo ""
bash "$SCRIPT_DIR/link-files-to-collection.sh"

echo ""
echo "=========================================="
echo "Skill-Sync fertig: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Log rotation: nur letzte 10 Logs behalten
find "$LOG_DIR" -name "*.log" -type f | sort -r | tail -n +11 | xargs -r rm
