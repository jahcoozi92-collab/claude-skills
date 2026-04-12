# Skill: clawdbot-admin

| name | description |
|------|-------------|
| clawdbot-admin | Verwaltung der Clawbot VM-Instanz (192.168.22.206): CLAUDE.md, Architektur-Locks, Agent-Guardrails, System-Hardening. Nicht fuer NAS, Yoga7 oder andere Maschinen. |

## Scope — NUR Clawbot VM

Diese Skill gilt **ausschliesslich** fuer:
- **Host:** ugreen-gateway / Clawbot VM (Debian 13, 192.168.22.206)
- **User:** moltbotadmin
- **Home:** /home/moltbotadmin
- **Zweck:** Clawdbot Gateway + Claude Code Instanz

**Nicht** fuer:
- NAS (192.168.22.90, User: Jahcoozi)
- Yoga7 (Dianas Laptop)
- Windows-Systeme
- exe.dev VMs
- Andere Maschinen im Netzwerk

---

## Verwaltete Dateien

### Geschuetzte Dateien (immutable)
| Datei | Schutz | Zweck |
|-------|--------|-------|
| `~/CLAUDE.md` | `chattr +i` (immutable) | System-Router fuer Claude Code |
| `~/architecture/ARCHITECTURE_LOCK.md` | — | Architektur-Constraints |

### Konfiguration
| Datei | Zweck |
|-------|-------|
| `~/.openclaw/openclaw.json` | Gateway-Runtime-Config (aktiv, v2026.3+) |
| `~/.openclaw/clawdbot.json` | Legacy-Config (wird noch gelesen, aber openclaw.json hat Vorrang) |
| `~/.openclaw/.env` | Secrets (chmod 600) |
| `~/.claude/settings.local.json` | Claude Code Permissions |
| `~/.claude/projects/-home-moltbotadmin/memory/MEMORY.md` | Auto-Memory |

**Rebrand-Mapping (clawdbot → openclaw):**
| Alt | Neu |
|-----|-----|
| `~/.clawdbot/` | `~/.openclaw/` (Symlink, gleicher Ordner) |
| `clawdbot.json` | `openclaw.json` |
| `clawdbot-gateway.service` | `openclaw-gateway.service` |
| `CLAWDBOT_*` env vars | `OPENCLAW_*` (legacy vars werden ignoriert mit Warnung) |

**Rebrand-Regel fuer Dokumentation:** CLI-Befehle in CLAUDE.md/Docs IMMER als `openclaw` schreiben (nicht `clawdbot`). Shell-Aliase (`clawdbot-use-*`, `clawdbot-model-*`) behalten ihren Namen — das sind Benutzerfunktionen, kein offizielles CLI.

---

## Architektur-Constraints

Die folgenden Strukturen sind gelockt (siehe `~/architecture/ARCHITECTURE_LOCK.md`):

```
Root CLAUDE.md        = System Router (Ueberblick + Navigation)
clawd/CLAUDE.md       = Agent Workspace (Persoenlichkeit, Memory, Skills)
clawdbot-src/AGENTS.md = Development Protocol (Code-Regeln, PRs, Tests)
```

**Message Flow (nicht aendern ohne Freigabe):**
```
User → Channel → Routing → Gateway → Agent → Provider → LLM → Response
```

---

## Schutz-Operationen

### CLAUDE.md entsperren (fuer Updates)
```bash
sudo chattr -i ~/CLAUDE.md
# ... Aenderungen vornehmen ...
sudo chattr +i ~/CLAUDE.md
```

**WICHTIG:** Claude Code kann `sudo` nicht ausfuehren (kein interaktives Terminal fuer Passwort-Eingabe). Der User muss per SSH selbst entsperren/sperren.

**Workflow (lsattr-first!):**
1. **IMMER ZUERST** `lsattr ~/CLAUDE.md` pruefen — BEVOR ein Edit versucht wird
2. Wenn `i`-Flag gesetzt: User auffordern `sudo chattr -i ~/CLAUDE.md` per SSH auszufuehren
3. Nach Bestaetigung erneut `lsattr` pruefen — erst dann editieren
4. Nach Edits: User auffordern zu sperren (`sudo chattr +i ~/CLAUDE.md`)

### Schutz pruefen
```bash
lsattr ~/CLAUDE.md
# Erwartet: ----i---------e------- /home/moltbotadmin/CLAUDE.md
```

### Neue Datei schuetzen
```bash
chmod 444 <datei>              # Basis-Schutz (Owner kann umgehen)
sudo chattr +i <datei>         # Immutable (nur root kann aufheben)
```

---

## Drei-Stufen CLAUDE.md Hierarchie

| Ebene | Datei | Rolle | Inhalt |
|-------|-------|-------|--------|
| 1 | `~/CLAUDE.md` | System-Router | Architektur-Ueberblick, Message-Flow, Commands |
| 2 | `clawd/CLAUDE.md` | Workspace-Guide | Agent-Memory-System, Session-Typen, Safety |
| 3 | `clawdbot-src/AGENTS.md` | Dev-Protocol | Code-Style, PRs, Multi-Agent, Tool-Schemas |

**Regel:** Keine Duplikation zwischen Ebenen. Jede Ebene verweist nach unten, wiederholt aber nicht.

---

## Secrets-Management

**Regel: Keine API-Keys in `openclaw.json`, `clawdbot.json` oder `.bashrc`!** Alle Secrets gehoeren in `~/.openclaw/.env` (chmod 600). Shell-Umgebung laedt Keys via `set -a; source ~/.openclaw/.env; set +a` in `.bashrc` — NIEMALS Keys direkt in `.bashrc` hardcoden.

**✅ ERLEDIGT (2026-03-12):** Alle Plaintext-Keys aus `openclaw.json` entfernt. OpenRouter-apiKey und Telegram-botToken entfernt (Auto-Fill). Gateway/Hooks-Token, alle Skill-Keys auf `${VAR}` umgestellt. `GITHUB_PAT` und `SAG_API_KEY` zu `.env` hinzugefuegt.

OpenClaw kennt drei Secret-Mechanismen:

| Mechanismus | Wann nutzen | Beispiel |
|-------------|-------------|---------|
| **Auto-Fill** | Provider-Keys, Channel-Tokens | `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN` — einfach Feld weglassen |
| **`${VAR}` Interpolation** | Gateway-Token, Hooks, Skills | `"token": "${CLAWDBOT_GATEWAY_TOKEN}"` |
| **`env.vars` Block** | Sonderfaelle | Setzt env vars beim Config-Laden |

**Auto-Fill Env-Variablen (kein Feld in JSON noetig):**
`OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENAI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `DISCORD_BOT_TOKEN`, `CLAWDBOT_GATEWAY_TOKEN`

**Externe Service-Tokens (in `.env`, genutzt von MCP-Servern/Tools):**
`CLOUDFLARE_API_TOKEN` (cfut_-Prefix, User API Token mit Scope-Beschraenkung)

### Skill Env-Injection Prioritaetskette

`.env` ALLEIN reicht NICHT fuer Skill-Keys! Der Agent bekommt den Key nur, wenn er auch in der Skill-Config steht. Prioritaet (niedrig → hoch):

| Ebene | Quelle | Wann geladen |
|-------|--------|-------------|
| 1 | `~/.openclaw/.env` | Boot (dotenv, override: false) |
| 2 | `openclaw.json: env.vars.*` | Config-Load |
| 3 | `skills.entries.{key}.env` | Agent-Run Start |
| 4 | `skills.entries.{key}.apiKey` | Agent-Run Start (hoechste Prio) |

**Pflicht bei neuen Skill-Keys:** IMMER auf Ebene 1 (.env) UND Ebene 4 (config apiKey) setzen:
```bash
echo 'NEW_KEY=value' >> ~/.openclaw/.env
cd ~/clawdbot-src && pnpm openclaw config set 'skills.entries.{slug}.apiKey' 'value'
```

---

## ClawdHub Skill-Installation

### Slug-Format
ClawdHub-Slugs sind **FLACH** (kein Author-Prefix):
- URL: `clawhub.ai/jaaneek/x-search` → Slug: `x-search` (NICHT `jaaneek/x-search`)

### Vollstaendiges Install-Rezept
```bash
# 1. Inspizieren (Security!)
clawhub inspect <slug>

# 2. Installieren in Agent-Workspace
clawhub install <slug> --workdir ~/clawd

# 3. Security Audit
cd ~/clawdbot-src && pnpm openclaw security audit --deep

# 4. Key setzen (BEIDE Ebenen!)
echo 'KEY_NAME=value' >> ~/.openclaw/.env
pnpm openclaw config set 'skills.entries.<slug>.apiKey' 'value'

# 5. Aktivieren
pnpm openclaw config set 'skills.entries.<slug>.enabled' true

# 6. Gateway restart
systemctl --user restart openclaw-gateway.service

# 7. Verifizieren
pnpm openclaw skills info <slug>   # → "Ready"
```

### Post-Install Checkliste (NACH Installation — PFLICHT)
1. `.claude/` Ordner im Skill entfernen falls vorhanden (`rm -rf ~/clawd/skills/<slug>/.claude`) — ClawdHub-Skills sollen KEINE Claude Code Permissions mitliefern
2. `name:` in SKILL.md Frontmatter MUSS mit dem Ordnernamen uebereinstimmen — sonst ist der Skill unsichtbar fuer OpenClaw
3. `openclaw skills info <slug>` → muss "Ready" zeigen
4. Falls `--force` noetig war (VirusTotal-Warnung): haeufigstes False-Positive ist eine mitgelieferte `.claude/settings.local.json`

### Security-Checkliste (VOR Installation)
- `clawhub inspect <slug>` — Metadata + Owner pruefen
- SKILL.md lesen — welche Binaries, welche env vars, welche URLs?
- Python/Shell-Scripts manuell pruefen — keine base64, keine verdaechtigen URLs
- NACH Install: `openclaw security audit --deep`
- Bekannte Malware: `coding-agent-g7z` (base64-Payload → curl 91.92.242.30)
- Bekanntes False-Positive: `.claude/settings.local.json` mit Git/Bash Permissions → entfernen

### Installierte ClawdHub-Skills (Inventar)
| Skill | Zweck | Key noetig | Datum |
|-------|-------|-----------|-------|
| `x-search` | X/Twitter-Suche via xAI Grok API | XAI_API_KEY ($5 Guthaben) | 2026-03-25 |
| `news-feed` | RSS-Nachrichten (BBC, Reuters, AP, Guardian, NPR) | Nein | 2026-03-26 |
| `ocr-local` | Texterkennung aus Bildern (Tesseract.js, lokal) | Nein | 2026-03-26 |

**Hinweis:** DW-Feed (`rss.dw.com/rss/en/top`) liefert 404 — ggf. URL in `news-feed/scripts/news.py` aktualisieren.

---

## SSH-Selbsterkennung

**Wir SIND die Clawbot VM (192.168.22.206, User: moltbotadmin).** Befehle die auf dieser Maschine laufen sollen (z.B. Ontology-Updates) DIREKT ausfuehren — NICHT per `ssh moltbotadmin@192.168.22.206`. SSH nur fuer andere Maschinen (NAS: 192.168.22.90, etc.).

---

## Config-Optimierung Checkliste

### Level 1 — Sicherheit & Korrektheit
- [ ] Alle Secrets in `.env` ausgelagert (keine Klartext-Keys in JSON)
- [ ] `.env` hat `chmod 600`
- [ ] Model-Parameter stimmen mit Intention ueberein (thinking, maxTokens)
- [ ] Tote Eintraege entfernt (leere Objekte, deaktivierte Plugins, unreferenzierte Modelle)
- [ ] `plugins.allow` hat keinen Leerstring
- [ ] `gateway.auth.rateLimit` konfiguriert (10/60s, 5min Lockout)
- [ ] `hooks.defaultSessionKey` gesetzt (z.B. "hook:ingress")
- [ ] `hooks.allowedAgentIds` auf bekannte Agenten beschraenkt
- [ ] `tools.exec.security` auf "allowlist" (NICHT "full"!)
- [ ] safeBins: Keine Interpreter (awk, sed, jq) — koennen beliebigen Code ausfuehren
- [ ] `openclaw security audit` hat keine CRITICAL-Findings

### Level 2 — UX & Performance
- [ ] `typingMode: "instant"` — sofortiger Typing-Indicator
- [ ] `ackReaction` + `removeAckAfterReply` — visuelles Feedback
- [ ] `queue.mode: "collect"` + `debounceMs: 1500` — Schnellnachrichten buendeln
- [ ] `session.reset.mode: "idle"` + `idleMinutes` — stale Sessions vermeiden
- [ ] `userTimezone` + `timeFormat: "24"` — Zeitbewusstsein
- [ ] Fallback-Kette (kosten-optimiert): Sonnet primary → DeepSeek → Gemini Flash → Opus → Qwen3 local
- [ ] **Cron-Jobs NICHT auf Gemini Free** — 20 req/Tag global geteilt, 429-Errors bei >2 Jobs. DeepSeek ($0.25/M) fuer alle automatisierten Tasks.
- [ ] `contextPruning.keepLastAssistants: 3` — schuetzt letzte Antworten
- [ ] `heartbeat.activeHours` — nur waehrend Wachzeiten
- [ ] Telegram: `linkPreview: false`, `markdown.tables: "code"`, `dmHistoryLimit: 50`

### Level 3 — Features
- [ ] TTS: `messages.tts.auto: "inbound"` + Edge TTS (kostenlos, kein API-Key)
- [ ] Deutsche Stimmen: `de-DE-ConradNeural` (aktuell konfiguriert) oder `de-DE-KatjaNeural`

---

## Gateway-Schnellreferenz

```bash
systemctl --user restart openclaw-gateway.service
systemctl --user status openclaw-gateway.service
journalctl --user -u openclaw-gateway.service -f
openclaw doctor
```

### Gateway-Architektur (Stand 2026-04-09)

Ein Gateway auf ugreen-gateway (192.168.22.206), erreichbar ueber Cloudflare Tunnel:

| Komponente | Host | Details |
|------------|------|---------|
| **Gateway** | 192.168.22.206:18789 | npm v2026.4.9, systemd user-service |
| **Cloudflare Tunnel** | NAS (192.168.22.90) | Remote-managed, Container `cloudflared` |
| **SSH-Forward** | NAS → ugreen | systemd `ssh-openclaw-forward.service` (18790→18789) |

**Routing:** `openclaw.forensikzentrum.com` → Cloudflare (TLS) → NAS Tunnel-Connector → SSH-Forward (:18790) → ugreen Gateway (:18789)

**Warum SSH-Forward?** Proxmox VM-Firewall blockiert Port 18789 von der NAS. SSH (Port 22) funktioniert. Der Forward laeuft als systemd-Service auf der NAS.

**Cloudflare Tunnel ist REMOTE-MANAGED:**
- Lokale `config.yml` auf NAS wird IGNORIERT
- Aenderungen NUR ueber Cloudflare API (PUT /configurations)
- Tunnel-ID: `d770b289-dc1b-498e-9387-dff9edbea572`
- Account-ID: `fe9ccc0b8c75b763124554a9f0bab48c`
- API-Token: `CLOUDFLARE_API_TOKEN` in `~/.openclaw/.env`
```bash
# Tunnel-Config lesen:
CF_TOKEN=$(grep CLOUDFLARE_API_TOKEN ~/.openclaw/.env | cut -d= -f2)
curl -s "https://api.cloudflare.com/client/v4/accounts/fe9ccc0b8c75b763124554a9f0bab48c/cfd_tunnel/d770b289-dc1b-498e-9387-dff9edbea572/configurations" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -m json.tool
```

**NAS-Gateway wurde entfernt (2026-04-09):** Docker-Container v0.2.18 und nativer Prozess gestoppt. NAS dient nur noch als Tunnel-Connector und Node-Host.

**UGOS Home-Dir Warnung:** UGOS setzt `/home/Jahcoozi/` auf 777. Nach NAS-Updates pruefen:
```bash
ssh Jahcoozi@192.168.22.90 "ls -ld /home/Jahcoozi/"  # muss 755 sein
```

**WebSocket ueber Cloudflare:** Funktioniert jetzt (nach SSH-Forward Fix). Bei device_token_mismatch: Browser LocalStorage fuer openclaw.forensikzentrum.com loeschen.

**Memory-Plugins:** `memory-lancedb` (Vektor-Suche) aktiv, `memory-core` (Dreaming) deaktiviert. Slots sind exklusiv — nur ein Plugin kann den memory-Slot halten. "dreaming not supported" Warnung in Control UI ist kosmetisch.

### Gateway npm-Install (aktueller Zustand, seit 2026-04-09)

Der Gateway laeuft auf dem **npm-Paket** (nicht mehr lokalem Build). Extensions sind im Paket gebundelt.

| Parameter | Wert |
|-----------|------|
| ExecStart | `/usr/bin/node ~/.npm-global/lib/node_modules/openclaw/dist/entry.js gateway --port 18789` |
| bind | `"lan"` (in openclaw.json) |
| `plugins.load.paths` | `[]` (leer — Extensions im npm-Paket gebundelt) |

**Update-Workflow:**
```bash
npm install -g openclaw@latest    # npm-Paket aktualisieren
openclaw --version                # Pruefen
systemctl --user restart openclaw-gateway.service   # Gateway neustarten
```

**CLI-Wrapper:** `~/.local/bin/openclaw` zeigt auf npm-Paket (nicht mehr clawdbot-src).

**Device Pairing:** Tokens in `~/.openclaw/devices/paired.json`. Revoked Devices (mit `revokedAtMs`) koennen entfernt werden.

**`--bind` Werte:** `loopback`, `lan`, `tailnet`, `auto`, `custom` (keine IP-Adressen)

### Remote Nodes

Nodes sind Remote-Maschinen, die sich beim Gateway registrieren und Exec-Befehle entgegennehmen.

| Node | Host | Service | Verbindung |
|------|------|---------|------------|
| NAS-DXP4800 | 192.168.22.90 | `systemd /etc/systemd/system/openclaw-node.service` | wss://openclaw.forensikzentrum.com |
| yoga7-kali | 192.168.22.86 | `systemd --user openclaw-node.service` | wss://openclaw.forensikzentrum.com |

**Pairing-Flow:**
1. Node startet: `openclaw node run --host openclaw.forensikzentrum.com --port 443 --tls`
2. Braucht `OPENCLAW_GATEWAY_TOKEN` als env var
3. Gateway zeigt Pairing-Request: `openclaw nodes approve <request-id>`
4. Token wird in `~/.openclaw/node.json` auf dem Node gespeichert
5. ACHTUNG: Token muss ggf. manuell in `node.json` eingetragen werden (Bug: nicht immer automatisch)

**Node-Befehle testen:**
```bash
openclaw nodes list                    # Alle Nodes + Status
openclaw nodes invoke --node NAS-DXP4800 --command system.which --params '{"bins":["docker","git"]}'
```
`system.run` (Shell-Exec) ist NUR fuer den Agent via exec-Tool verfuegbar, nicht direkt via CLI.

### Security-Haertung (2026-04-09)

| Einstellung | Wert | Zweck |
|-------------|------|-------|
| `tools.exec.security` | `"allowlist"` | Nur safeBins ohne Approve |
| `tools.exec.ask` | `"on-miss"` | Nicht-Allowlist-Befehle brauchen /approve |
| `hooks.allowedAgentIds` | 5 Agenten | Nur bekannte Agents ueber Hooks |
| `hooks.allowedSessionKeyPrefixes` | `["hook:","cron:"]` | Session-Scope begrenzt |
| `hooks.defaultSessionKey` | `"hook:ingress"` | Kein Session-Sprawl |
| `gateway.auth.rateLimit` | 10/60s, 5min Lockout | Brute-Force-Schutz |

**safeBins — erlaubt ohne Approve:**
Diagnose (ps, ss, df, ...), Datei-Lesen (cat, head, grep, ...), Git, Python3, Node, Bun, SSH/SCP, Datei-Ops (mkdir, cp, mv, touch), Text-Utils (wc, sort, uniq, tr, cut, diff, xargs, tee)

**Nicht in safeBins (brauchen /approve):** rm, docker, systemctl, chmod, chown, awk, sed, jq — diese koennen destruktiv sein oder beliebigen Code ausfuehren.

### Model-Aliases (`~/.clawdbot-model-aliases.sh`)

Schnelles Model-Switching per Shell-Funktion. Wird in `.bashrc` gesourced.

**`openclaw` Binary:** Wrapper-Script in `~/.local/bin/openclaw` (exec node npm-global entry.js). Aliases nutzen `OPENCLAW_CLI` Variable:
```bash
OPENCLAW_CLI="/usr/bin/node /home/moltbotadmin/.npm-global/lib/node_modules/openclaw/dist/entry.js"
```

| Alias | Modell | Kosten |
|-------|--------|--------|
| `clawdbot-use-free` | Gemini 2.0 Flash | FREE |
| `clawdbot-use-cheap` | DeepSeek V3.2 | $0.25/$0.38 |
| `clawdbot-use-gpt` | GPT-5.4 (OpenAI) | $$ |
| `clawdbot-use-balanced` | Sonnet 4 | $3/$15 | ← **aktuell Primary** |
| `clawdbot-use-premium` | Opus 4.6 | $15/$75 |

**Aktuelles Primary Model (Stand 2026-04-08):** `anthropic/claude-sonnet-4-6` ($3/$15)
- Vorher: OpenAI GPT-4.1 Mini → umgestellt auf Anthropic Sonnet 4.6
- Coder-Agent: `anthropic/claude-opus-4-6` ($15/$75) — staerkeres Modell fuer Code
- Alle anderen Agenten (main/researcher/organizer/searcher): `anthropic/claude-sonnet-4-6`
- Cron + Heartbeat: `openai/gpt-4.1-mini` ($0.40/$1.60)
- Fallback: GPT-4.1 → Gemini 2.5 Flash (Google) → Ollama Qwen 2.5 (lokal)

### Ontology Knowledge Graph

| Zugriff | Pfad/URL |
|---------|----------|
| CLI | `cd ~/clawd && python3 skills/ontology/scripts/ontology.py <cmd>` |
| Graph-Daten | `~/clawd/memory/ontology/graph.jsonl` (append-only JSONL) |
| Statische HTML | `~/clawd/canvas/ontology.html` (muss nach Aenderungen regeneriert werden) |
| Live-Server | Port 8090 (SSE, auto-update aus graph.jsonl) |
| HTML-Export | `python3 ~/clawd/skills/ontology/scripts/export_html.py` |

**Cron: Ontology Daily Update** (ID: `0fe558a6`, 23:00 Berlin, DeepSeek):
Analysiert taeglich Memory-Files + Git-Commits, erstellt Entities, regeneriert HTML.

**HTML-Regeneration** (Regex-Replace, da kein Placeholder):
```python
cd ~/clawd && python3 -c "import json,re;from pathlib import Path; ..."
# Ersetzt 'const graphData = {...};' mit aktuellem graph.jsonl Inhalt
```

### Troubleshooting

**502 von Cloudflare:**
1. `systemctl --user status openclaw-gateway.service` — laeuft der Gateway?
2. `curl -sI http://127.0.0.1:18789/` — antwortet er lokal?
3. `ssh Jahcoozi@192.168.22.90 "sudo systemctl status ssh-openclaw-forward.service"` — SSH-Forward aktiv?
4. `ssh Jahcoozi@192.168.22.90 "curl -sI http://127.0.0.1:18790/ --max-time 3"` — Forward funktioniert?
5. `ssh Jahcoozi@192.168.22.90 "docker logs cloudflared --tail 5"` — Tunnel-Connector OK?
6. **Tunnel-Config pruefen** (remote-managed!):
   ```bash
   CF_TOKEN=$(grep CLOUDFLARE_API_TOKEN ~/.openclaw/.env | cut -d= -f2)
   curl -s "https://api.cloudflare.com/client/v4/accounts/fe9ccc0b8c75b763124554a9f0bab48c/cfd_tunnel/d770b289-dc1b-498e-9387-dff9edbea572/configurations" \
     -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
   import json,sys; [print(f'{r.get(\"hostname\",\"catch-all\")} -> {r[\"service\"]}')
     for r in json.load(sys.stdin)['result']['config']['ingress']
     if 'openclaw' in str(r)]"
   ```

**WebSocket "device_token_mismatch" — Vollstaendiger Workflow:**

⚠️ **REIHENFOLGE KRITISCH** — Browser-Tab IMMER ZUERST schliessen, DANN serverseitige Aenderungen!
Sonst: Browser retried aggressiv → Rate-Limit (10 Versuche/60s, 5min Lockout) → Alles blockiert.

Zwei Auth-Schichten beachten:
1. **Gateway-Token** (`CLAWDBOT_GATEWAY_TOKEN` aus `.env`) — authentifiziert Client gegen Gateway
2. **Device-Token** — pro-Geraet, wird beim Pairing ausgehandelt

**Empfohlener Fix (sauberster Weg):**
```bash
# 1. User: Browser-Tab SCHLIESSEN (stoppt Retry-Loop!)

# 2. Altes Device entfernen (ID aus paired.json oder `openclaw devices list`)
openclaw devices remove <deviceId>

# 3. Falls Rate-Limited: Gateway neustarten (cleart In-Memory-Counter)
systemctl --user restart openclaw-gateway.service

# 4. User: Browser oeffnen, LocalStorage loeschen (F12 → Application → Local Storage → Clear)

# 5. User: Seite neu laden → Gateway-Token eingeben (aus ~/.openclaw/.env: CLAWDBOT_GATEWAY_TOKEN)

# 6. Browser sendet Pairing-Request → genehmigen:
openclaw devices approve <requestId>
# oder: openclaw devices approve --latest
```

**NICHT empfohlen:** `openclaw devices rotate` bei Browser-Clients — der Browser erfaehrt den neuen Token nicht automatisch, schickt weiter den alten und triggert Rate-Limits.

**Duplikat-Erkennung:** Mehrere Devices mit gleicher IP = doppeltes Pairing. Aelteres entfernen (`createdAtMs` in `paired.json` vergleichen).

**Context Overflow / "prompt too large for the model":**
- Symptom: Bot antwortet nicht, Eingaben werden "verschluckt"
- Logs zeigen: `embedded run timeout` alle 10min + `timed out during compaction`
- Ursache: Session-JSONL ist zu gross fuer Kompaktierung (Kompaktierung braucht selbst LLM-Call → scheitert ebenfalls am Kontextlimit → Endlosschleife)
- **Gateway-Restart allein reicht NICHT** — die Session-Datei wird beim Start wieder geladen
- Fix:
  ```bash
  # 1. Session archivieren (nicht loeschen!)
  mv ~/.openclaw/agents/main/sessions/<session-id>.jsonl \
     ~/.openclaw/agents/main/sessions/<session-id>.jsonl.reset.$(date -u +%Y-%m-%dT%H-%M-%S)Z
  rm -f ~/.openclaw/agents/main/sessions/<session-id>.jsonl.lock
  # 2. Gateway neustarten
  systemctl --user restart openclaw-gateway.service
  ```
- Session-ID finden: `journalctl --user -u openclaw-gateway.service | grep "embedded run timeout"` → `sessionId=...`
- Praeventiv: Aufgaben mit grossen Tool-Outputs (FFmpeg-Metadaten, Datei-Listings) koennen Sessions schnell aufblaehenhen

**Sicherheit: .env Datei lesen:**
- NIEMALS `cat` oder `Read` auf `~/.openclaw/.env` — zeigt alle API-Keys im Klartext
- Stattdessen: `grep -c "KEY_NAME" ~/.openclaw/.env` (prueft Existenz ohne Wert anzuzeigen)
- Oder: `grep "^[A-Z_]*=" ~/.openclaw/.env | cut -d= -f1` (zeigt nur Schluessel-Namen)

---

## Gelernte Lektionen

### 2026-02-08 — Initiale Einrichtung

**CLAUDE.md Rewrite:**
- Alte Version hatte 20-Zeilen Modul-Tabelle die 14 von 48 Verzeichnissen fehlte
- Coverage-Threshold war falsch dokumentiert (55% statt 70%)
- Neuer Ansatz: Message-Flow-Diagramm statt Modul-Liste (zeigt Beziehungen, nicht nur Namen)
- Workspace-Sektion ergaenzt (Memory-Konzept war nirgends erklaert)

**Schutz-Eskalation:**
- `chmod 444` reicht nicht — Agent mit Shell-Zugang kann `chmod u+w` ausfuehren
- `chattr +i` erfordert sudo zum Aufheben — sicherer Guardrail fuer AI-Agenten
- Architecture Lock Pattern: Absicht dokumentieren + Dateisystem-Schutz kombinieren

**Token-Optimierung (aus vorheriger Session 2026-02-07):**
- Workspace-Dateien dedupliziert (USER.md/TOOLS.md/MEMORY.md hatten 3x gleiche Daten)
- AGENTS.md von 7.8KB auf 3.9KB gekuerzt
- settings.local.json: 92 auf 34 Permission-Eintraege (Secrets entfernt)

### 2026-02-12 — Config-Tiefenoptimierung

**Secrets-Management:**
- 6+ API-Keys/Tokens standen im Klartext in `clawdbot.json` — alle in `~/.clawdbot/.env` ausgelagert
- Provider-Keys (OpenRouter, Gemini) brauchen kein `apiKey`-Feld — Auto-Fill ueber Env-Vars
- Channel-Tokens (Telegram) ebenso — `TELEGRAM_BOT_TOKEN` wird automatisch erkannt
- Gateway/Hooks/Skill-Keys ueber `${VAR}` Interpolation (funktioniert in allen String-Werten)

**UX-Optimierung (Level 2):**
- Fallback-Kette neu geordnet: DeepSeek → Gemini Free → Sonnet → Opus (spart bis $60/M bei Ausfall)
- `typingMode: "instant"` + `ackReaction: "👀"` + `removeAckAfterReply` = sofortiges Feedback
- `queue.mode: "collect"` + `debounceMs: 1500` buendelt Schnellnachrichten
- `session.reset.mode: "idle"` + 120min verhindert stale Kontext
- Telegram: `markdown.tables: "code"` (lesbar), `linkPreview: false` (weniger Rauschen)

**Edge TTS aktiviert:**
- `messages.tts.auto: "inbound"` — antwortet per Audio wenn User Sprachnachricht schickt
- Provider: Edge TTS (kostenlos, kein API-Key, <1s Latenz)
- Stimme: `de-DE-ConradNeural` (Stand 2026-03-12, vorher FlorianMultilingualNeural)
- Voice-Samples generieren: `cd ~/clawdbot-src && node /tmp/voice-test.mjs`

**Preis-Korrektur:**
- DeepSeek V3.2 kostet $0.25/$0.38 pro 1M Tokens (nicht $0.14/$0.28 wie vorher notiert)

**Systemd-Hinweis:**
- Service-Datei hat noch hardcodierte API-Keys — werden durch `.env` ueberdeckt
- Beim naechsten `clawdbot wizard` Run sollten die bereinigt werden

### 2026-02-25 — CLAUDE.md /init Verbesserung

**Hostname:**
- Tatsaechlicher Hostname ist `ugreen-gateway` — in CLAUDE.md und Skill korrigiert
- `/etc/hosts` fehlte `127.0.0.1 ugreen-gateway` — ergaenzt (sudo-Warnung behoben)
- Achtung: Doppelter Eintrag in `/etc/hosts` (harmlos, aber unsauber)

**CLAUDE.md Erweiterungen (via /init):**
- Workspace Packages Sektion: ui/, extensions/ (32+), apps/ios, apps/android
- Pre-commit hooks: `prek` dokumentiert
- ACP (Agent Client Protocol): IDE-Bridge-Sektion ergaenzt
- Docker Tests: test:docker:onboard hinzugefuegt
- Zusaetzliche Dev-Scripts: tui, rpc, plugins:sync, release:check, docs:dev

**Preis-Diskrepanz:**
- CLAUDE.md sagte $0.14/$0.28, MEMORY.md sagte $0.25/$0.38 — korrigiert auf $0.25/$0.38

### 2026-02-27 — Config-Audit + Secrets-Bereinigung

**Secrets final bereinigt:**
- 3 Skill-API-Keys waren noch im Klartext in `clawdbot.json` (bei Feb-12 Auslagerung uebersehen)
- `nano-banana-pro` nutzt `${GEMINI_API_KEY}` (identischer Key)
- `openai-image-gen` → `${OPENAI_IMAGE_GEN_KEY}`, `openai-whisper-api` → `${OPENAI_WHISPER_KEY}`
- Gateway-Token war Platzhalter ("ein-langer-zufaelliger-string...") → `${CLAWDBOT_GATEWAY_TOKEN}`
- Hooks-Token war Klartext → `${CLAWDBOT_HOOKS_TOKEN}`

**Rebrand clawdbot → openclaw:**
- Service: `openclaw-gateway.service` (nicht `clawdbot-gateway.service`)
- Binary: `/home/moltbotadmin/.npm-global/lib/node_modules/openclaw/dist/index.js`
- CLI-Alias: `clawdbot` (noch alter Name)
- Config: `clawdbot.json` (noch alter Name)
- Env-Vars in systemd: `OPENCLAW_*` Prefix
- Env-Vars in .env: `CLAWDBOT_*` Prefix (Mischung!)
- CLAUDE.md + MEMORY.md: alle Service-Referenzen auf `openclaw-gateway` korrigiert

**SSH-Befehle fuer User — Constraints:**
- Befehle KURZ halten (<80 Zeichen pro Zeile), Terminal-Zeilenumbruch korrumpiert Copy-Paste
- Komplexe Operationen: mehrzeilig oder als Script-Datei
- NIEMALS kombiniertes `sed` mit `$a` (append) fuer /etc/hosts — unzuverlaessig
- Stattdessen: `grep -v > /tmp/h && echo >> /tmp/h && mv /tmp/h original`
- Nach jeder /etc/hosts Aenderung sofort verifizieren mit `cat /etc/hosts`

**/etc/hosts bereinigt:**
- Doppelter `ugreen-gateway` Eintrag → auf genau einen reduziert
- `127.0.1.1 moltbot` bleibt (alter Hostname, harmlos)

### 2026-03-10 — Sub-Agenten, Cron, Feedback-Loop + Workarounds

**Neue Features konfiguriert:**
- Sub-Agenten in `openclaw.json`: `researcher` (DeepSeek), `coder` (Opus), `organizer` (DeepSeek)
- Subagent-Config: allowAgents, maxSpawnDepth: 2, maxChildrenPerAgent: 5, archiveAfterMinutes: 60
- Kompaktierung erweitert: qualityGuard (enabled, maxRetries: 1), identifierPolicy: strict
- Cron-Jobs in `~/.openclaw/cron/jobs.json`: Morgenbriefing (07:30), Woechentlicher Review (So 10:00)
- Governance in `clawd/AGENTS.md`: Sub-Agent-Regeln, Feedback & Lernintegration
- Learnings-Review in `clawd/HEARTBEAT.md`: 5 Review-Kriterien (Kontext-Erhalt, Wiederholungsfehler, Korrektur-Reaktionszeit, Skill-Nutzung, Eigeninitiative-Balance)
- CLAUDE.md: 4 neue Sektionen (Sub-Agenten, Autonome Workflows, Kompaktierung, Selbstverbesserung)

**CLI-Workaround (VERALTET — seit 2026-03-24 behoben):**
- `openclaw` Binary jetzt verfuegbar via Wrapper-Script in `~/.local/bin/openclaw`
- Cron-Jobs koennen per CLI oder direkt in `~/.openclaw/cron/jobs.json` editiert werden
- Gateway erkennt viele Config-Aenderungen dynamisch (hot-reload), manche erfordern Restart

**CLAUDE.md immutable — Lesson:**
- 3 fehlgeschlagene Edit-Versuche bevor `lsattr` geprueft wurde
- Neuer Workflow: IMMER `lsattr` zuerst, dann entsperren lassen, dann editieren

### 2026-03-08 — Gateway Crash-Loop + pnpm-Inkompatibilitaet

**Symptom:** openclaw.forensikzentrum.com liefert HTTP 502, Gateway in Crash-Loop (22+ Restarts)

**Ursache (mehrstufig):**
1. `plugins.entries.*.path` Keys in `openclaw.json` — v2026.3+ kennt dieses Feld nicht mehr (strict schema)
2. Nach Entfernung: "unsafe plugin manifest path" fuer ALLE gebundelten Extensions
3. Grund: pnpm Content-Addressable-Store nutzt Hardlinks, die `openBoundaryFileSync` als Boundary-Escape erkennt
4. `doctor --fix` konnte die path-Keys nicht entfernen (brach bei Plugin-Manifest-Validierung ab)

**Fix-Kette:**
1. `path`-Keys manuell per Python-Script aus `openclaw.json` entfernt
2. `pnpm build` → lokaler Build v2026.3.3 (Source neuer als npm v2026.3.1)
3. Service-Datei umgestellt: ExecStart auf `dist/entry.js` (kein --bind Flag, Config nutzt `"bind": "lan"`)
4. `OPENCLAW_BUNDLED_PLUGINS_DIR=/home/moltbotadmin/clawdbot-src/extensions` in systemd-Unit
5. `plugins.load.paths` in `openclaw.json` auf Extensions-Verzeichnis gesetzt

**Erkenntnisse:**
- `resolveBundledPluginsDir()` in `src/plugins/bundled-dir.ts` geht von `import.meta.url` aufwaerts und sucht `extensions/` — im pnpm-Store findet es die falschen
- `OPENCLAW_BUNDLED_PLUGINS_DIR` env var uebersteuert die Pfadaufloesung komplett
- Cloudflare-Tunnel (`cloudflared`) laeuft als System-Service, nicht als user-unit
- `~/.openclaw/` und `~/.clawdbot/` sind derselbe Ordner (Symlink vom Rebrand)

### 2026-03-10 — GPT-5.4 Provider + Model-Aliases Fix

**OpenAI GPT-5.4 als Primary konfiguriert:**
- `openai/gpt-5.4` als `agents.defaults.model.primary` gesetzt
- DeepSeek auf Fallback 1 verschoben (war Primary)
- OpenAI ist Built-in Provider — kein Eintrag in `models.providers` noetig
- API-Key per Auto-Fill aus `OPENAI_API_KEY` (bereits in `.env`)

**Model-Aliases Rebrand-Fix (`.clawdbot-model-aliases.sh`):**
- Alle Funktionen nutzten `clawdbot` CLI-Command → existiert nicht nach Rebrand
- Service-Name war `clawdbot-gateway.service` → `openclaw-gateway.service`
- Fix: `OPENCLAW_CLI` und `OPENCLAW_SERVICE` Variablen am Anfang des Scripts
- `OPENCLAW_CLI="/usr/bin/node /home/moltbotadmin/clawdbot-src/dist/entry.js"`
- Neuer Alias: `clawdbot-use-gpt` fuer GPT-5.4 Switching
- Nach Aenderung: `source ~/.clawdbot-model-aliases.sh` noetig (bestehende SSH-Sessions haben alte Version gecached)

### 2026-03-12 — Grosses Config-Update (Guide-basiert)

**Secrets-Migration ABGESCHLOSSEN:**
- Alle 9 Plaintext-Keys aus `openclaw.json` entfernt
- OpenRouter-apiKey + Telegram-botToken: komplett entfernt (Auto-Fill)
- Gateway/Hooks-Token: `${CLAWDBOT_GATEWAY_TOKEN}` / `${CLAWDBOT_HOOKS_TOKEN}`
- Skill-Keys: `${GEMINI_API_KEY}`, `${OPENAI_IMAGE_GEN_KEY}`, `${OPENAI_WHISPER_KEY}`, `${GITHUB_PAT}`, `${SAG_API_KEY}`
- Achtung: Skill-Keys in openclaw.json hatten ANDERE Werte als in .env (openai-image-gen, openai-whisper) — .env-Werte sind die aktuellen

**Primary Model: GPT-5.4 → Sonnet:**
- `anthropic/claude-sonnet-4-20250514` als `agents.defaults.model.primary`
- Vorteil: natives Anthropic-Format → Prompt Caching (spart ~90% bei wiederholten Workspace-Dateien)
- Main/Coder bleiben Opus (explizit in agents.list)
- GPT-5.4 Alias bleibt nutzbar (`clawdbot-use-gpt`)

**Cron-Job Telegram-Delivery Fix:**
- `delivery.to: "2061281331"` fehlte in beiden Cron-Jobs (morning-briefing + weekly-review)
- Ohne `to` Feld: "Delivering to Telegram requires target <chatId>" Fehler
- Die chatId ist identisch mit der Telegram-User-ID aus `channels.telegram.allowFrom`

**Governance-Regeln erweitert:**
- AGENTS.md: Operative Limits (Fehlerlimit 3x, Zeitlimit 10min, Netzwerk-Genehmigung, Prompt Injection Schutz)
- AGENTS.md: Model Routing Tabelle (dokumentiert welches Modell wofuer)
- SOUL.md: Anti-Exfiltration (keine Offenlegung interner Dateien), Anti-Jailbreak (Instruktions-Overrides ignorieren)

**Edge TTS Stimme geaendert:**
- `de-DE-ConradNeural` statt `de-DE-FlorianMultilingualNeural` (User-Praeferenz)

**Backup-System eingerichtet:**
- Script: `~/bin/openclaw-backup.sh`
- Cron: alle 5 Tage 03:00 Uhr (`0 3 */5 * *`)
- Inhalt: openclaw.json, .env, cron/, clawd/ (ohne canvas/ und .git/)
- Ziel: lokal ~/backups/ + NAS (Jahcoozi@192.168.22.90:/volume1/backups/openclaw/)
- Rotation: max 2 Backups behalten, aelteste werden nach Erstellung geloescht
- Pattern: `ls -1t | tail -n +3 | xargs rm` (zaehlt Dateien, nicht Alter — zuverlaessiger als `find -mtime`)

**OPENCLAW_BUNDLED_PLUGINS_DIR:**
- Fehlte in systemd-Unit nach v2026.3.11 Update (war in .bak aber nicht in aktueller Unit)
- Wieder hinzugefuegt — verhindert "unsafe plugin manifest path" Crash-Loops

**Source-Build Update-Workflow (bewaehrt):**
```bash
cd ~/clawdbot-src
git fetch origin --tags
git pull --rebase origin main
pnpm install
pnpm build
pnpm ui:build
# systemd-Unit Version + BUNDLED_PLUGINS_DIR pruefen!
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway.service
```

### 2026-03-14 — Ontology Skill + ClawHub Workflow

**ClawHub Skill-Management (Workflow):**
1. URL-Slug (`oswalpalash/ontology`) ≠ CLI-Slug (`ontology`) — CLI nutzt nur den Skill-Namen
2. IMMER zuerst in Temp-Verzeichnis inspizieren: `clawhub install <slug> --workdir /tmp/skill-inspect --no-input`
3. Dateien lesen (SKILL.md + scripts/) — auf Malware pruefen (curl, eval, base64, subprocess)
4. Wenn sauber: `clawhub install <slug> --workdir ~/clawd --no-input`
5. ClawHub CLI Flags: `--no-input` fuer install, `--yes` fuer uninstall (inkonsistent!)
6. Rate Limiting: bei Fehler kurz warten und erneut versuchen

**Malware-Bereinigung:**
- `coding-agent-g7z` war noch in ClawHub-Lockfile (Ordner laengst geloescht)
- `clawhub uninstall coding-agent-g7z --workdir ~/clawd --yes` entfernt Lockfile-Eintrag

**Ontology Knowledge Graph installiert (v1.0.4):**
- Skill: `~/clawd/skills/ontology/` (SKILL.md + scripts/ontology.py + references/)
- Storage: `~/clawd/memory/ontology/graph.jsonl` (append-only JSONL)
- Schema: `~/clawd/memory/ontology/schema.yaml` (Typ-Constraints, Relationen, Kardinalitaet)
- **CWD muss `~/clawd/` sein** beim Ausfuehren (Path-Traversal-Schutz im Script)
- Aufruf: `cd ~/clawd && python3 skills/ontology/scripts/ontology.py <command>`
- Commands: create, get, query, list, update, delete, relate, related, validate, schema-append
- Abhaengigkeit: PyYAML (nur fuer Schema-Ops, CRUD geht ohne)
- Initialisiert mit 9 Entitaeten (Person, 2x Device, 3x Project, 3x Account) + 10 Relationen
- Schema-Typen: Person, Device, Project, Task, Account, Credential (mit forbidden_properties)

**Python-Dependencies auf Debian 13:**
- PEP 668 blockiert `pip3 install` und `pip3 install --user`
- `python3-venv` Paket nicht installiert, `pipx` nicht vorhanden
- Fallback: `pip3 install --break-system-packages <paket>` (funktioniert, aber nicht ideal)
- Besser (wenn sudo verfuegbar): `sudo apt install python3-<paket>`

**Ontology Live-Visualisierung (Deepen.AI-Style):**
- Live-Server: `skills/ontology/scripts/live_server.py` (SSE + HTTP, Port 8090)
- Template: `skills/ontology/scripts/live_template.html`
- systemd-Unit: `ontology-live.service` (enabled, auto-restart)
- URL: `http://192.168.22.206:8090/`
- Daten-Refresh: `cd ~/clawd && python3 -c "..."` (re-embed Script, siehe live_template.html)
- Cron-Job `self-improve` triggert Agent 3x taeglich (09:00, 14:00, 19:00), loggt in Ontology

**KRITISCH — Live-Viz Lessons Learned:**
- SSE fuer Initial-Load verursacht Standbild im Browser → Daten IMMER inline einbetten, SSE nur fuer nachtraegliche Live-Updates
- Canvas `wheel`-Events brauchen `addEventListener('wheel', fn, {passive:false})` — `onwheel` + `preventDefault()` wird von Chrome/Firefox ignoriert
- Python `http.server` ist single-threaded — SSE-Handler blockiert alle anderen Requests waehrend der Verbindung
- Sichtbarkeits-Default viel zu niedrig: Opacity-Werte fuer Edges/Nodes/Glows muessen bei 0.7-1.0 starten, nicht bei 0.1-0.3. User musste 4x "heller" sagen
- ES5-kompatibler Code (var, function) als sicherer Fallback — Template-Literals und Arrow-Functions koennen in manchen Browser-Setups Probleme machen
- Zweite Canvas mit `mix-blend-mode: screen` crashte die Animation — einfache Single-Canvas-Loesung ist stabiler

### 2026-03-15 — Context Overflow + Session-Reset + Anthropic Auth

**Symptom:** Bot antwortet nicht, Eingaben werden "verschluckt", Log zeigt `embedded run timeout` alle 10min

**Ursache (mehrstufig):**
1. Session akkumulierte grosse Tool-Outputs (FFmpeg-Analyse, Bild-Metadaten) → 3.5 MB JSONL
2. Kompaktierung scheiterte am Kontextlimit (braucht selbst LLM-Call) → Endlosschleife
3. Gateway-Restart reichte nicht — Session wird von Disk neu geladen
4. Anthropic-Auth fehlte: `ANTHROPIC_API_KEY` war nicht in `.env` → Fallback auf DeepSeek (kleineres Kontextfenster)

**Fix-Kette:**
1. `ANTHROPIC_API_KEY` in `~/.openclaw/.env` eingetragen (Auto-Fill, kein Feld in JSON noetig)
2. Session archiviert: `mv <id>.jsonl <id>.jsonl.reset.<ts>` + Lock entfernt
3. Gateway neugestartet → frische Session, kein Overflow

**Erkenntnisse:**
- `auth-profiles.json` hatte Key unter `anthropic:manual`, System suchte `anthropic:default` → Env-Var ist zuverlaessiger (provider-weit)
- Session-Dateien: `~/.openclaw/agents/main/sessions/<uuid>.jsonl` (+ `.lock`)
- Archivierte Sessions bekommen `.reset.TIMESTAMP` Suffix (OpenClaw-Konvention)
- Memory-Verbrauch als Indikator: 750MB (stuck) vs 300MB (frisch) — grosser Sprung deutet auf festgefahrene Session
- `.env` nie mit Read/cat anzeigen — nur Key-Namen pruefen

### 2026-03-16 — Ontology Template Update-Workflow + Viz-Praeferenzen

**Ontology Live-Template aktualisieren (Schritt-fuer-Schritt):**
1. Graph-Daten aus JSONL exportieren:
   ```python
   # ACHTUNG: create-Ops haben entity-Wrapper!
   e = obj.get('entity', obj)  # NICHT obj direkt
   ```
2. JSON in `live_template.html` ersetzen: `var DATA={...};`
3. `systemctl --user restart ontology-live.service`

**JSONL-Format Gotcha:**
- `{"op":"create","entity":{"id":"...","type":"...","properties":{...}}}`
- Das `entity`-Feld umschliesst die eigentlichen Daten — direkter Zugriff auf `obj['id']` gibt KeyError
- Relationen haben KEIN entity-Wrapper: `{"op":"relate","from":"...","rel":"...","to":"..."}`

**Visualisierungs-Praeferenzen (Diana):**
- Atome muessen GROSS sein — 2x Vergroesserung war "nicht genug", erst ~3.5x war akzeptabel
- Aktuelle Werte: Pattern/Device=38, Project=44, Software=34, Account=30, Task/Cred=26, Note=22
- Labels: 18px bold 700, Typ-Badge: 16px bold, Edge-Labels: 14px
- Repulsion: 15000 (proportional zu Atom-Groesse, sonst Ueberlappung)
- Faustregel: Bei Atom-Groessen-Aenderung auch Repulsion, Label-Offset und Badge-Font anpassen

**Sicherheitslektion (.env Exposition):**
- In dieser Session wurden API-Keys versehentlich durch `Read` auf `~/.openclaw/.env` im Klartext angezeigt
- IMMER stattdessen: `grep "^[A-Z_]*=" ~/.openclaw/.env | cut -d= -f1` (nur Key-Namen)
- Oder: `grep -c "ANTHROPIC_API_KEY" ~/.openclaw/.env` (Existenz-Check)

### 2026-03-16 — UI-Lokalisierung + Cron-Fixes

**localStorage ueberschreibt Code-Defaults bei Web-Apps:**
- `resolveNavigatorLocale()` Fallback auf "de" aendern reichte NICHT — Browser hatte `openclaw.i18n.locale=en` in localStorage gespeichert
- `resolveInitialLocale()` liest localStorage ZUERST, Code-Default wird nie erreicht
- Fix: localStorage-Wert "en" explizit ignorieren wenn Deutsch-Default gewuenscht
- **Regel:** Bei Locale-/Settings-Aenderungen IMMER beide Pfade behandeln: Erstbesucher (kein localStorage) UND Rueckkehrer (gespeicherter Wert)

**Build-Performance — UI vs Backend:**
- `pnpm ui:build` = ~3 Sekunden (nur Vite, nur Frontend)
- `pnpm openclaw <cmd>` = ~50 Sekunden Full-Rebuild wenn dist stale (tsdown, alle Plugins)
- Bei reinen UI-Aenderungen: NUR `pnpm ui:build` + Gateway-Restart
- Fuer schnelle Cron-/Config-Queries: Dateien direkt lesen (`~/.openclaw/cron/jobs.json`) statt CLI

**Cron-Job-Prompts — Zustellungs-Anweisungen vermeiden:**
- "Liefere per Telegram" im Prompt verwirrte Gemini Flash (dachte es muss manuell senden)
- Zustellung wird automatisch durch `delivery`-Config im Job gehandhabt
- Prompt soll NUR den Inhalt beschreiben, NICHT den Zustellungsweg

**de.ts (UI-Uebersetzung) vervollstaendigt:**
- Von ~130 auf ~380 Zeilen (alle Sektionen: overview, login, cron komplett)
- Hardcodierte Strings in command-palette.ts, bottom-tabs.ts, config.ts, skills-grouping.ts sind noch NICHT i18n'd
- i18n-System: Lit Web Components + Lazy Loading, localStorage-Persistenz, Fallback auf Englisch

### 2026-03-16 — Tiefenoptimierung (Level 1–Godmode)

**Plugin-Config-Architektur (KRITISCH):**
- `plugins.entries.<id>` Core-Schema erlaubt NUR: `enabled`, `hooks`, `config`
- Plugin-spezifische Keys (embedding, autoRecall, etc.) gehoeren in `plugins.entries.<id>.config` (Passthrough)
- Keys direkt auf Entry-Ebene verursachen Validierungsfehler und Gateway-Crash
- Schema-Referenz: `src/config/types.plugins.ts` Zeile 7: `config?: Record<string, unknown>`

**LanceDB Semantisches Gedaechtnis aktiviert:**
- Slot: `plugins.slots.memory = "memory-lancedb"` (vorher: memory-core/SQLite)
- Config: `plugins.entries.memory-lancedb.config.embedding.apiKey = "${OPENAI_API_KEY}"`
- Model: `text-embedding-3-small` (1536 Dim, ~$0.02/1M Tokens)
- `autoRecall: true` — injiziert relevante Erinnerungen vor jedem Response
- `autoCapture: true` — speichert wichtige Infos nach jedem Gespraech
- DB-Pfad: `~/.openclaw/memory/lancedb/` (lazy init beim ersten Zugriff)
- OPENAI_API_KEY war bereits in .env (fuer Whisper/Image-Gen), wird jetzt auch fuer Embeddings genutzt

**Bash-Gotcha: set -e + (( var++ )):**
- `(( 0++ ))` evaluiert zu 0 (falsy) → `set -e` bricht Script ab
- Fix: `var=$((var + 1))` statt `(( var++ ))`
- Betrifft NUR den Fall var=0, ab var=1 funktioniert `(( var++ ))` korrekt
- Gleiches Problem bei `(( total++ ))`, `(( errors++ ))` etc.

**Glob-Pattern: *.jsonl matcht auch *.jsonl.reset.*:**
- `find -name "*.jsonl"` matcht auch archivierte Dateien wie `session.jsonl.reset.2026-03-16`
- Fix: IMMER `-not -name "*.reset.*"` hinzufuegen
- Oder: `-print0` + `while IFS= read -r -d '' f` (mit `|| true` am done wegen set -e)

**Session-Management (Overflow-Praevention):**
- `session.maintenance.mode: "enforce"` — aktive Durchsetzung
- `session.maintenance.maxEntries: 300`, `pruneAfter: "14d"`, `rotateBytes: "5mb"`, `maxDiskBytes: "200mb"`
- `compaction.recentTurnsPreserve: 4` — schuetzt letzte 4 Turns
- `compaction.memoryFlush.forceFlushTranscriptBytes: "1mb"` — fruehzeitiger Memory-Flush
- 5 uebergrosse Sessions (2.3MB, 789K, 625K, 503K, 433K) archiviert

**Neue Monitoring-Scripts:**
- `~/bin/session-health-guard.sh` — Auto-Archivierung bei >2MB, Telegram-Alert, alle 15min via Watchdog-Timer
- `~/bin/system-digest.sh` — Taeglicher Bericht (07:00): Gateway, Sessions, Cron, LanceDB, Kosten, Disk
- Crontab: `0 7 * * *` system-digest, `0 3 * * *` backup (bestehend)
- Watchdog erweitert: `ExecStartPost=-session-health-guard.sh`

**Fallback-Kette korrigiert (2026-03-16):**
- Vorher: Sonnet → DeepSeek → Opus → Gemini → Qwen
- Nachher: Sonnet → **Opus** → DeepSeek → Gemini → Qwen (bestes Modell zuerst als Fallback)
- **Erneut korrigiert (2026-03-24):** Sonnet → DeepSeek → Gemini → Opus → Qwen (kosten-optimiert: guenstig vor teuer)

**Sonnet Thinking aktiviert:**
- `thinking: "low"` + `maxTokens: 16384` fuer Primary Model
- Verbessert Reasoning-Qualitaet bei minimalem Kosten-Overhead

**Gemini Flash contextWindow korrigiert:**
- Von 32768 auf 1048576 (1M Tokens) — Gateway kuerzte Kontext unnoetig

**Workspace-Audit im Weekly Review:**
- Cron-Prompt erweitert um automatische Konsistenzpruefung
- Prueft: Redundanz, Owner-Verletzungen, Widersprueche, Secrets, stale Dateien

### 2026-03-16 — Godmode-II + Voice-Call Setup

**Godmode-II Config-Keys (alle validiert, keine Schema-Fehler):**
- `tools.loopDetection`: enabled, warn@8, stop@15, history 30 — verhindert endlose Tool-Schleifen
- `contextPruning.softTrim`: maxChars 8000, head/tail 2000 — kuerzt grosse Tool-Outputs (erhoeht von 500, 2026-04-05)
- `compaction.postCompactionSections`: ["Session Startup", "Red Lines"] — re-injiziert nach Komprimierung
- `messages.statusReactions.enabled`: true — visuelles Feedback (Denken/Tool/Web)
- `session.typingMode`: "instant" — sofortiger Typing-Indicator
- `agents.defaults.thinkingDefault`: "off" — Standard-Thinking deaktiviert (Token-Sparen)
- `agents.defaults.envelopeTimezone`: "user", `timeFormat`: "24" — konsistente Timestamps
- `tools.web.search.provider`: "gemini" mit GEMINI_API_KEY — kostenlose Web-Suche
- `tools.web.fetch.timeoutSeconds`: 30, `maxChars`: 30000 — Fetch-Limits
- `tools.exec.timeoutSec`: 120, `backgroundMs`: 3000 — Exec-Hardening
- `logging.level`: "info", `redactSensitive`: "tools" — strukturierte Logs
- `plugins.allow`: + "llm-task" — Background-LLM-Aufgaben
- `hooks.internal.entries.boot-md.enabled`: true — Startup-Validierung
- `heartbeat.lightContext`: true — schnellere Heartbeats
- `channels.telegram.replyToMode`: "first" — Thread-Antworten
- `channels.telegram.reactionLevel`: "minimal" — reichere Reaktionen

**Voice-Call System (Twilio):**
- Account: Trial mit $15.50 Guthaben
- Nummer: +17712532921 (Washington DC, US) — $1.15/Monat
- Deutsche Nummern brauchen registrierte Adresse (AddressSid) — US-Nummern nicht
- Credentials in `~/.openclaw/.env`: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_API_KEY_SID, TWILIO_API_KEY_SECRET, TWILIO_PHONE_NUMBER
- Config: `plugins.entries.voice-call.config` (Provider, TTS, Inbound-Policy)
- Webhook: `http://127.0.0.1:3334/voice/webhook` (eigenstaendiger HTTP-Server)
- publicUrl: `https://voice.forensikzentrum.com/voice/webhook`
- **OFFEN: Cloudflare Tunnel-Route** `voice.forensikzentrum.com → localhost:3334` im Dashboard anlegen
- TTS: OpenAI `nova` Voice (besser fuer Deutsch als alloy; nicht Edge TTS — Telefonie braucht 8kHz mu-law)
- Response-Model: openai/gpt-4.1-mini (voller Workspace-Zugriff inkl. Tools)
- Inbound: allowlist (leer = niemand kann anrufen, Nummern hinzufuegen fuer Zugang)
- Outbound: conversation-Modus (interaktiv, nicht nur Durchsage)
- Kosten: ~$0.02/Min US, ~$0.10/Min nach DE + OpenAI TTS ~$0.015/1K Zeichen
- ngrok installiert (~/bin/ngrok v3.37.2) als Fallback-Tunnel falls Cloudflare nicht geht

**Webhook-Security Fix (KRITISCH):**
- Cloudflare Tunnel strippt den `X-Twilio-Signature` Header → alle Webhooks gaben 401
- Symptom: Calls werden initiiert (Status: queued), aber sofort beendet (Duration: 0s)
- Log: `[voice-call] Webhook verification failed: Missing X-Twilio-Signature header`
- Fix: `webhookSecurity.trustForwardingHeaders: true` + `trustedProxyIPs: ["127.0.0.1", "::1"]`
- Nach Fix: Calls verbinden korrekt (Duration: 13s+)

**Twilio Trial-Account Limits:**
- Trial kann nur an verifizierte Nummern anrufen
- Verifizierung neuer Nummern braucht Full Account (Upgrade mit Zahlungsmethode)
- Die Registrierungs-Nummer (+491736075456) ist automatisch verifiziert
- Upgrade-URL: https://www.twilio.com/console/billing/upgrade

**Zweiter Cloudflare Tunnel (lokal konfiguriert):**
- Tunnel 688f91d0 hat lokale Config: `~/.cloudflared/kanban-config.yml`
- Service: `cloudflared-local.service` (systemd user, enabled, auto-start)
- Ingress: kanban.forensikzentrum.com → :3847, voice.forensikzentrum.com → :3334
- Neue Routes: einfach YAML-Datei editieren + Service neustarten
- DNS-Route anlegen: `cloudflared tunnel route dns --overwrite-dns 688f91d0 subdomain.forensikzentrum.com`

**Cloudflare Tunnel API Referenz (Token-basierter Tunnel `backup-yoga7`):**
- Account-ID: `fe9ccc0b8c75b763124554a9f0bab48c`
- Tunnel-ID: `d770b289-dc1b-498e-9387-dff9edbea572`
- API-Token: `CLOUDFLARE_API_TOKEN` aus `~/.openclaw/.env`
- Config lesen: `GET /accounts/{account}/cfd_tunnel/{tunnel}/configurations`
- Config schreiben: `PUT /accounts/{account}/cfd_tunnel/{tunnel}/configurations` mit Body `{"config": {...}}`
- **WICHTIG:** PUT ersetzt die GESAMTE Config — immer zuerst GET, Feld aendern, dann PUT mit vollem Payload
- Token-basierte Tunnels haben KEINE lokale Config-Datei — Ingress-Regeln liegen ausschliesslich in der Cloudflare-API/Dashboard

**Voice-Call Testing:**
- NICHT per manuellen Twilio API curl-Calls testen — das Plugin braucht interne callId-Parameter
- IMMER ueber das `voice_call` Tool des Agents testen (via Telegram: "Ruf mich an")
- Manuelle API-Calls erzeugen Calls die das Plugin nicht zuordnen kann

### 2026-03-24 — pnpm-Symlink Crash + post-merge Hook

**Gateway Crash-Loop (11920 Restarts!):**
- Symptom: `ERR_MODULE_NOT_FOUND: Cannot find package 'chalk'` in `dist/subsystem-DVwhOlEq.js`
- Ursache: `pnpm-lock.yaml` hatte overrides-Mismatch → `node_modules/chalk` Symlink fehlte
- `pnpm install --frozen-lockfile` schlug fehl (overrides geaendert) → musste ohne `--frozen-lockfile` laufen
- Paket `chalk@5.6.2` war im pnpm-Store (`node_modules/.pnpm/chalk@5.6.2/`) vorhanden, nur der Symlink fehlte

**Gateway-Restart Falle:**
- Nach cleanem SIGTERM (Exit Code 0) und `systemctl stop`: systemd startet NICHT automatisch neu (obwohl `Restart=always`)
- `systemctl stop` setzt internen "stop requested" State → blockiert auto-restart
- Fix: `systemctl --user start` (nicht restart) noetig

**post-merge Hook eingerichtet:**
- Datei: `~/clawdbot-src/.git/hooks/post-merge` (chmod +x)
- Nutzt `git diff-tree ORIG_HEAD HEAD` um geaenderte Dateien zu ermitteln
- Triggert `pnpm install` + Gateway-Restart NUR wenn `pnpm-lock.yaml` oder `package.json` betroffen
- Liegt in `.git/hooks/` → wird NICHT ins Repo committed → bei Neuklonen manuell einrichten
- Praevention: Szenario von heute (git pull ohne pnpm install) kann nicht mehr passieren

**Build vs Install Klarstellung:**
- `pnpm install` (Dependency-Aenderungen): kein Rebuild (`pnpm build`) noetig — nur Gateway-Restart
- `pnpm build` nur noetig nach Source-Code-Aenderungen oder Version-Updates

### 2026-03-24 — Secrets-Hygiene + Rebrand-Konsistenz

**API Key aus .bashrc entfernt:**
- `OPENAI_API_KEY` stand als Klartext-String in `~/.bashrc` Zeile 124 — seit Ersteinrichtung
- Key war bereits korrekt in `~/.openclaw/.env` vorhanden (doppelt!)
- Ersetzt durch: `set -a; source ~/.openclaw/.env; set +a` — laedt ALLE Keys aus .env
- Vorteil `set -a` Pattern: neue Keys in .env werden automatisch als Env-Vars exportiert, ohne .bashrc anzufassen
- ACHTUNG: Key koennte in `.bash_history` sichtbar sein falls er jemals manuell eingegeben wurde

**CLAUDE.md Rebrand-Bereinigung:**
- 5x `clawdbot` CLI-Aufrufe in Root-CLAUDE.md durch `openclaw` ersetzt (Gateway Mgmt, ACP, Troubleshooting)
- `claude-skills/` zur Directory-Tabelle hinzugefuegt (20+ Claude Code Skills, war nicht dokumentiert)
- Gateway-Sektion: Hinweis auf lokalen Build + `OPENCLAW_BUNDLED_PLUGINS_DIR`
- Model-Sektion: Shell-Alias-Namen und Quelldatei explizit dokumentiert
- `clawd/CLAUDE.md` aktualisiert: "Clawdbot" → "OpenClaw", Config-Pfade korrigiert
- `CLAUDE.md.proposed` geloescht (veraltet, noch alte Clawdbot-Referenzen)

**Erkenntnisse:**
- Bei /init auf bestehendem CLAUDE.md: Review+Improve statt Neuanlage (war korrekt)
- README.md im Home-Dir gehoert zu `sag` (Go TTS-Tool) — nicht zum moltbot-System
- Shell-Aliase (`clawdbot-use-*`) behalten ihren Namen — das sind Benutzerfunktionen, kein offizielles CLI

### 2026-03-24 — Log-Analyse, safeBinProfiles, Tool-Deny, Symlink-Sicherheit

**openclaw Binary erstellt:**
- Wrapper-Script `~/.local/bin/openclaw` (exec node ~/clawdbot-src/dist/entry.js "$@")
- Agent konnte `openclaw` nicht ausfuehren — war nicht im PATH
- Wrapper-Ansatz besser als Symlink, da Node-Interpreter explizit gesetzt wird

**safeBinProfiles — PFLICHT fuer alle safeBins:**
- Bins OHNE Profil werden IGNORIERT (nicht nur Warnung, sondern tatsaechlich deaktiviert)
- 26 Bins waren betroffen: ps, netstat, ss, lsof, top, htop, df, du, free, uptime, whoami, id, pwd, ls, cat, find, which, curl, wget, ping, dig, nslookup, journalctl
- Auch Built-in-Profile (grep, head, tail) brauchen Custom-Eintraege fuer sauberen Doctor-Output
- Profil-Konzept: `maxPositional` (verhindert Datei-Argumente), `deniedFlags` (blockiert gefaehrliche Flags), `allowedValueFlags` (Whitelist)
- Kritische deniedFlags: `find -exec/-delete`, `curl -o/--upload-file`, `wget -O/--post-data`
- Config-Pfad: `tools.exec.safeBinProfiles.<bin>` in `openclaw.json`

**Fallback-Kette kosten-optimiert:**
- Alt: Sonnet → Opus ($15/$75) → DeepSeek → Gemini → Qwen
- Neu: Sonnet → DeepSeek ($0.25) → Gemini (guenstig) → Opus ($15/$75) → Qwen (lokal)
- Opus wird jetzt nur noch als letzter Cloud-Fallback genutzt

**Per-Agent Tool-Deny Pattern (Least Privilege):**
- `gateway` Tool nur fuer main + coder verfuegbar
- researcher, organizer, searcher: `"tools": { "deny": ["gateway"] }` in agents.list
- Spawned Sub-Agenten: `tools.subagents.tools.deny: ["gateway"]` (global)
- Hintergrund: Schwaecher Modelle (DeepSeek, Gemini Flash) generieren fehlerhafte config.apply Calls (fehlender `raw`-Parameter → "Rohdaten erforderlich" Fehler)
- gateway Tool umfasst: config.get, config.schema.lookup, config.apply, config.patch, restart, update.run

**Symlink-Sicherheit (Skills):**
- OpenClaw lehnt Skills ab deren aufgeloester Pfad ausserhalb des konfigurierten Skill-Root liegt
- Beispiel: `clawd/skills/claude-learnings` → `~/.claude/skills` → `~/claude-skills` → aufgeloest ausserhalb `~/clawd/skills/`
- Warnung: "Ueberspringe den Skill-Pfad, der ausserhalb seines konfigurierten Verzeichnisses aufgeloest wird"
- Fix: Symlink entfernt (war fehlkonfiguriert, zeigte auf Claude Code Skills statt auf einen OpenClaw-Skill)

**Telegram Adressierung:**
- Agent versuchte Telefonnummer (+491736075456) statt Chat-ID (2061281331) zu nutzen
- Hinweis in AGENTS.md ergaenzt: "Immer numerische Chat-IDs, nie Telefonnummern"
- Cron-Jobs waren korrekt konfiguriert — Fehler kam aus einem Agent-Tool-Call

**discovery.wideArea deaktiviert:**
- `enabled: true` ohne `domain` erzeugt Warnung bei jedem Start
- Deaktiviert bis eine Domain konfiguriert wird (Unicast-DNS-SD)

### 2026-03-24 — Tunnel Port-Mismatch (openclaw.forensikzentrum.com 502)

**Symptom:** openclaw.forensikzentrum.com liefert HTTP 502, Gateway laeuft aber lokal einwandfrei (HTTP 200 auf :18789)

**Ursache:** Cloudflare-Tunnel Ingress-Regel fuer `openclaw.forensikzentrum.com` zeigte auf `http://127.0.0.1:18790` — Port 18790 existiert nicht. Gateway lauscht auf 18789.

**Diagnose-Pfad:**
1. DNS OK (Cloudflare-IPs), curl → 502, Gateway lokal → 200, cloudflared laeuft
2. Tunnel-Config via API abgefragt (`GET .../configurations`) → falscher Port entdeckt
3. Vergleich: `moltbot.forensikzentrum.com` → `:18789` (korrekt), `openclaw.*` → `:18790` (falsch)

**Fix:** Tunnel-Config via API PUT korrigiert: `:18790` → `:18789`. Sofort wirksam (kein Tunnel-Restart noetig).

**Erkenntnisse:**
- Token-basierte Tunnel-Configs sind anfaellig fuer "stille" Port-Drift — keine lokale Datei zum Pruefen
- Bei wiederholtem 502: IMMER zuerst Ingress-Port via API pruefen (Schritt 5 im Troubleshooting)
- Cloudflare API PUT ersetzt die GESAMTE Config → GET-modify-PUT Workflow zwingend
- Tunnel-Config-Aenderungen sind sofort wirksam, kein cloudflared-Restart noetig

### 2026-04-05 — Config-Hygiene (8-Punkte-Audit)

**Provider models:[] Problem:**
- Google-Provider hatte `models: []` — Fallback `google/gemini-2.5-flash` funktionierte via Auto-Discovery, aber ohne Kosten-Tracking, Token-Limits und Alias-Aufloesung
- Fix: Explizite Modell-Definition mit Kosten ($0.15/$0.60 pro 1M Tokens), contextWindow 1M, maxTokens 65536
- Regel: Jedes Modell in einer Fallback-Kette braucht einen expliziten Provider-Eintrag

**reasoning:true + thinking:"off" Konflikt:**
- DeepSeek und Gemini Flash (OpenRouter) hatten `reasoning: true` obwohl `thinking: "off"` gesetzt war
- Manche Provider senden bei `reasoning: true` automatisch Thinking-Token-Anfragen — verschwendet Tokens
- Fix: `reasoning: false` gesetzt, Name "DeepSeek V3.2 (Thinking)" → "DeepSeek V3.2"

**maxSpawnDepth Drift:**
- Config hatte `maxSpawnDepth: 3`, CLAUDE.md und Memory sagten 2
- Bei Tiefe 3 kann Sub-Sub-Sub-Agent kaum noch Kontext haben — Token-Verschwendung
- Fix: Auf 2 korrigiert

**ackReactionScope bei DM-only Setup:**
- `"group-mentions"` triggert nur bei @mentions in Gruppen — bei reinem DM-Setup nie
- Fix: `"all"` — jetzt 👀 auf jede Nachricht

**softTrim zu aggressiv:**
- head/tail 500/500 = nur 1000 Zeichen von grossen Tool-Outputs (Web-Fetches, Code)
- Fix: head/tail 2000/2000 = 4000 Zeichen bleiben, 4x mehr Kontext

**Voice-Call TTS Stimme:**
- `alloy` ist Englisch-optimiert, Greeting und Agent sprechen aber Deutsch
- Fix: `nova` — beste multilingual-Stimme bei OpenAI TTS-1
- Alternative falls nova nicht ueberzeugt: `shimmer` oder Wechsel auf Edge TTS `de-DE-KatjaNeural`

**OpenRouter Bereinigung:**
- 3 tote Modell-Definitionen im Provider (Credits leer) → `models: []`
- 4 tote Modell-Parameter-Eintraege (openrouter/*) → entfernt
- `google/gemini-2.5-flash` Param-Eintrag ersetzt `openrouter/google/gemini-2.5-flash`
- Provider-Skeleton bleibt erhalten fuer spaeteres Credit-Aufladen

**Slug-Generator (kein Fix noetig):**
- `src/hooks/llm-slug-generator.ts` nutzt bereits `resolveAgentEffectiveModelPrimary()` (Zeile 48)
- Erbt automatisch das Agent-Default-Modell (openai/gpt-4.1-mini)
- Alte Sonnet/OpenRouter-Fehler in Logs stammen von vor diesem Fix

### 2026-04-05 — OpenAI-Migration + Deep System Audit

**Provider-Wechsel: OpenRouter → OpenAI als Dauerprovider:**
- Primary: `openai/gpt-4.1-mini` ($0.40/$1.60) — guenstiger Alltagsbegleiter
- Coder-Agent: `openai/gpt-4.1` ($2/$8) — staerker fuer Code-Aufgaben
- Fallback-Kette: GPT-4.1 → Gemini 2.5 Flash (Google direkt) → Ollama Qwen 2.5 (lokal)
- OpenAI Provider in `models.providers.openai` konfiguriert (baseUrl, 2 Modelle, Kosten)
- Model-Params: `thinking: "off"`, `maxTokens: 16384` fuer beide GPT-Modelle

**Config-Migration Checkliste (KRITISCH — 3 Ebenen!):**
Bei jedem Model-Wechsel muessen DREI Stellen aktualisiert werden:
1. `openclaw.json` — agents.defaults.model + agents.list[].model + heartbeat/subagents/voice
2. `auth-profiles.json` — pro Agent unter `~/.openclaw/agents/<id>/agent/auth-profiles.json`
3. Cron-Job Payloads — eigene `model`-Felder, aenderbar via `openclaw cron edit <id> --model <m>`
Wenn nur Ebene 1 geaendert wird, laufen Cron-Jobs und Fallbacks weiter mit den alten Modellen!

**Systemd-Unit: EnvironmentFile statt Einzelzeilen:**
- 18 `Environment=` Zeilen mit Klartext-Secrets → eine `EnvironmentFile=/home/moltbotadmin/.openclaw/.env`
- Nicht-Secret Environment= Zeilen (HOME, PATH, TMPDIR, OPENCLAW_*) bleiben einzeln
- Vorteil: Secrets an einer Stelle (.env), Unit-Datei kann versioniert werden

**Cron-Job delivery.to MUSS numerische Telegram Chat-ID sein:**
- FALSCH: `"+491736075456"` (Telefonnummer) → Fehler "Telegram recipient must be a numeric chat ID"
- RICHTIG: `"2061281331"` (numerische Chat-ID = Telegram User-ID aus allowFrom)
- Telefonnummern funktionieren NUR fuer Voice-Call-Plugin, nicht fuer Telegram-Delivery

**Ollama braucht Auth-Profile trotz keyless:**
- Fehler: "No API key found for provider 'ollama'" — obwohl Ollama kein Auth braucht
- Ursache: Runtime prueft auth-profiles.json VOR der Provider-Config (apiKey: "ollama-local")
- Fix: Dummy-Eintrag `ollama:default` mit `apiKey: "ollama-local"` in auth-profiles.json

**Nasdaq-Tracker: Von 4 Spam-Jobs auf 2 gehaltvolle Briefings:**
- ENTFERNT: 1%-Alert (stuendlich), Events-Check (4x/Tag), Daily Update (2x/Tag)
- NEU: Morgen-Briefing (07:00) mit Kurs + Termine + Wachsam-Zeiten (MESZ)
- NEU: Abend-Zusammenfassung (22:00 Mo-Fr) mit Tagesergebnis + Treiber + Vorschau
- User-Praeferenz: "Weniger Alerts mit mehr verstaendlichen Inhalten, deutsche Uhrzeiten,
  wann wachsam sein wegen Bekanntgaben, Pressekonferenzen, Trump-Aktionen etc."

**Ontology Daily Update Cron geloescht:**
- Timeout-Probleme (300s nicht ausreichend) + zu komplexer Inline-Python im Cron-Prompt
- User entschied: komplett entfernen statt reparieren

**Weather-Skill erstellt:**
- `~/clawd/skills/weather/` mit SKILL.md (Berlin Default, lang=de) + scripts/weather.sh
- Einzelner JSON-Fetch (`?format=j1`) statt 8 einzelne curl-Aufrufe
- Python-Parser fuer strukturierte Ausgabe (je eine Zeile pro Info)

**System-Gesundheit:**
- /tmp: 954 stale openclaw-* Temp-Dirs bereinigt (1042→119 Dirs)
- Swap: 96% belegt → User fuehrte `swapoff -a && swapon -a` aus → 0B
- 14 Skill-Scripts ohne +x Bit → alle gefixt (besonders self-improving-agent .sh Scripts)
- Stale LanceDB temp-Datei (Feb 2026) entfernt
- SQLite constraint error im Cron-Ledger (errcode 1299) — Code-Bug, kein Config-Fix moeglich

**Provider-Diversifizierung (Pattern):**
- Nie alle Modelle ueber einen einzelnen Provider routen → Single Point of Failure
- Vorher: 5/5 Fallbacks ueber OpenRouter → alle tot bei leeren Credits
- Nachher: OpenAI (primaer) + Google (Backup) + Ollama (Notfall) = 3 unabhaengige Provider
- OpenRouter bleibt konfiguriert als optionaler Zusatz-Provider

### 2026-04-08 — Anthropic-Migration + Voice-Transkription + Model-Tiering

**Anthropic Plugin vs. models.providers (KRITISCH):**
- NIEMALS manuellen Eintrag in `models.providers.anthropic` anlegen!
- Das `anthropic`-Plugin (`extensions/anthropic/`) registriert sich selbst via `api.registerProvider()`
- Es verwaltet baseUrl, Modellkatalog, Auth und API-Format eigenstaendig
- Ein manueller Provider-Eintrag kollidiert: Config-Validation erwartet `baseUrl` als String, aber Plugin ueberschreibt den Eintrag → "received undefined"
- Korrekt: Nur `plugins.allow` + `plugins.entries.anthropic.enabled: true` setzen, Modelle per ID referenzieren (`anthropic/claude-opus-4-6`)
- ANTHROPIC_API_KEY in `.env` reicht — Auto-Fill via auth-profiles

**extensions/ != Plugins (KRITISCH):**
- Nicht jedes Verzeichnis in `extensions/` ist ein ladbares Plugin
- VOR dem Hinzufuegen zu `plugins.allow`/`plugins.entries` IMMER pruefen: existiert `openclaw.plugin.json`?
- `media-understanding-core` und `speech-core` haben KEIN Manifest → sind Core-Module, keine Plugins
- Stale Plugin-Eintraege erzeugen Config-Warnings aber keinen Crash

**tools.media Schema:**
- `tools.media` hat KEIN top-level `enabled`-Feld → Validation-Error "Unrecognized key"
- Nur Sub-Keys wie `tools.media.audio.enabled` oder `tools.media.audio.models` sind gueltig
- Funktionierender Minimal-Eintrag:
  ```json
  "media": { "audio": { "models": [{ "provider": "openai", "model": "whisper-1" }] } }
  ```
- Audio-Transkription nutzt den OpenAI-Provider aus `models.providers.openai` (gleicher API-Key)

**Kosten-bewusstes Model-Tiering (User-Praeferenz):**
- Standard-Tasks auf guenstigstem Claude-Modell (Sonnet 4.6, $3/$15)
- Opus 4.6 ($15/$75) fuer Deep-Work-Agent und DSGVO-Pflege (komplexe Aufgaben)
- MiniMax M2.7 via OpenRouter ($0.30/$1.20) als guenstiger Fallback #1 (SWE-bench ~78%, 42 tok/s, 204K ctx, verbos)
- Heartbeat/Cron: GPT-4.1 Mini ($0.40/$1.60) — einfache, haeufige Tasks
- Prompt Caching: `cacheRetention: "long"` (Opus UND Sonnet seit 2026-04-10) — spart 90% auf wiederholtem System-Prompt

**Aktuelle Modell-Zuweisungen (2026-04-10):**
| Agent | Modell | Kosten |
|-------|--------|--------|
| sonnet (default) | anthropic/claude-sonnet-4-6 | $3/$15 |
| opus | anthropic/claude-opus-4-6 | $15/$75 |
| pflege | anthropic/claude-sonnet-4-6 | $3/$15 |
| pflege-eu | anthropic/claude-opus-4-6 | $15/$75 |
| subagents | anthropic/claude-sonnet-4-6 | $3/$15 |
| heartbeat | openai/gpt-4.1-mini | $0.40/$1.60 |
| voice-call | anthropic/claude-sonnet-4-6 | $3/$15 |

**Fallback-Kette:** Sonnet → MiniMax M2.7 (OR) → Opus → GPT-5.4 → GPT-4.1 → Gemini Flash → Ollama Qwen 2.5

**Routing (2026-04-10):**
- Telegram → sonnet (via `openclaw agents bind`)
- WebChat → Default-Agent (nicht bindbar, manuell via `/@opus`)
- pflege/pflege-eu via `/@pflege` / `/@pflege-eu` im Chat

**Voice-Transkription aktiviert:**
- `tools.media.audio.models` mit OpenAI Whisper-1
- Telegram-Sprachnachrichten werden jetzt transkribiert bevor Mention-Logik greift
- Lokales Whisper CLI auch installiert (`~/.local/bin/whisper`, Python 3.13) als Fallback

### 2026-04-10 — 4-Agent-Topologie + Multi-Provider-Fallback

**Routing via CLI, NICHT via JSON (KRITISCH):**
- NIEMALS `routing`, `bindings` oder aehnliche Keys in `openclaw.json` schreiben — sie existieren NICHT im Schema und verursachen "Config invalid" + Gateway-Crash
- Routing NUR via CLI: `openclaw agents bind --agent <id> --bind <channel>`
- Unbind: `openclaw agents unbind --agent <id> --bind <channel>`
- Auflisten: `openclaw agents bindings`
- webchat ist NICHT bindbar — nutzt immer den Default-Agent. Manueller Wechsel via `/@opus` im Chat.

**agentDir muss pro Agent eindeutig sein (KRITISCH):**
- NIEMALS mehrere Agenten auf dasselbe `agentDir` zeigen lassen
- OpenClaw validiert Eindeutigkeit: "Duplicate agentDir detected" → Gateway startet nicht
- Jeder Agent braucht: `~/.openclaw/agents/<agent-id>/agent/`
- Auth-Profile (auth-profiles.json) muessen in jedes agentDir kopiert werden
- Erstellen: `mkdir -p ~/.openclaw/agents/<id>/agent && cp ~/.openclaw/agents/main/agent/auth-profiles.json ~/.openclaw/agents/<id>/agent/`

**IMMER `openclaw config set` statt direkter JSON-Edits:**
- `config set` macht automatisches SHA256-Backup + Schema-Validierung
- Direkte JSON-Edits fuehrten in dieser Session zu 3 Gateway-Fehlstarts durch unbekannte Keys
- Ausnahme: Initiales Erstellen neuer Agenten via `openclaw agents add`

**OpenRouter vs Anthropic Model-IDs (KRITISCH):**
- OpenRouter Anthropic-Modelle nutzen PUNKTE: `openrouter/anthropic/claude-opus-4.6`
- Anthropic direkt nutzt BINDESTRICHE: `anthropic/claude-opus-4-6`
- Verwechslung = "Model not found" ohne hilfreiche Fehlermeldung
- IMMER gegen Live-Registry verifizieren: `openclaw models list --all --json | grep <pattern>`

**Unbekannte Config-Keys = harter Crash:**
- `model_overrides` existiert nicht → per-Agent Fallback-Override ist ueber diesen Key nicht moeglich
- Per-Agent Modell nur ueber das `model` Feld in `agents.list[]` konfigurierbar (String, nicht Objekt)
- Vor dem Verwenden neuer Config-Keys: `openclaw doctor` oder `openclaw config set` testen

**CF AI Gateway ist KEIN Provider in v2026.4.9:**
- Kein `cloudflare-ai-gateway` Prefix in der Model-Registry
- Vorhandene Gateway-Provider: `vercel-ai-gateway`, `amazon-bedrock` — aber kein Cloudflare
- Falls CF-Caching gewuenscht: Custom-Provider mit `baseUrl` einrichten (nicht offiziell unterstuetzt)

**MiniMax M2.7 als Fallback (verifiziert 2026-04-10):**
- OpenRouter ID: `openrouter/minimax/minimax-m2.7`
- Kosten: $0.30/M input, $1.20/M output (10x guenstiger als Sonnet)
- Benchmarks: SWE-bench ~78% (vs Opus ~81%, Sonnet ~80%)
- Schwaechen: Langsam (~42 tok/s), sehr verbos (frisst Preisvorteil teils auf), kein Thinking-Mode
- Staerken: 131K max output, 204K context, starkes agentisches Coding

**Free OpenRouter Models: Keine brauchbaren Kandidaten (2026-04-10):**
- `openclaw models scan --max-age-days 180 --min-params 8` fand 15 Free-Modelle
- Alle ohne Tool-Support (metadata "fail") → fuer OpenClaw-Agenten unbrauchbar
- Kein kostenloser Notfall-Fallback moeglich

**4-Agent-Topologie:**
| Agent | Modell | Zweck | Tools |
|-------|--------|-------|-------|
| sonnet (default) | claude-sonnet-4-6 | Workhorse, Telegram | alle |
| opus | claude-opus-4-6 | Deep Work, context1m | alle |
| pflege | claude-sonnet-4-6 | DSGVO Quick-QM | restriktiv |
| pflege-eu | claude-opus-4-6 | DSGVO Deep-Analysis | restriktiv |

**OpenAI Key-Rotation (2026-04-10):**
- Alter Key in .env und auth-profiles.json war unterschiedlich → memory-lancedb 401-Fehler
- Neuer Key einheitlich an BEIDEN Stellen: `~/.openclaw/.env` UND `~/.openclaw/agents/*/agent/auth-profiles.json`
- PFLICHT bei Key-Rotation: beide Dateien updaten, nicht nur eine
