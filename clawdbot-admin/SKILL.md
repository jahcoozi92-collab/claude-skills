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
| ExecStart | `/usr/bin/node ~/.local/lib/node_modules/openclaw/dist/index.js gateway --port 18789` (seit Konsolidierung 2026-04-28; vor `index.js` war es `entry.js`, beide existieren) |
| EnvironmentFile | `-/home/moltbotadmin/.openclaw/gateway.systemd.env` (optional via `-` Prefix) |
| bind | `"lan"` (in openclaw.json) |
| `plugins.load.paths` | `[]` (leer — Extensions im npm-Paket gebundelt) |

**Update-Workflow:**
```bash
npm install -g --prefix ~/.local openclaw@latest    # explizit .local (XDG-konform; npm config get prefix = .local)
openclaw --version                                  # Pruefen
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

**`openclaw` Binary:** Wrapper-Script in `~/.local/bin/openclaw` (exec node .local-Paket). Aliases nutzen `OPENCLAW_CLI` Variable:
```bash
OPENCLAW_CLI="/usr/bin/node /home/moltbotadmin/.local/lib/node_modules/openclaw/dist/entry.js"
```
> **Pfad-Hinweis (seit 2026-04-28):** Vor der npm-Prefix-Konsolidierung lag das openclaw-Paket unter `~/.npm-global/.../dist/entry.js`. Falls Aliases noch auf den alten Pfad zeigen, in `~/.clawdbot-model-aliases.sh` aktualisieren.

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
   - Bei `activating (auto-restart)` + hohem Restart-Counter: `sudo journalctl -u ssh-openclaw-forward.service -n 30` lesen
   - Haeufige Ursache: Key-Permissions zu offen (`Permissions 0750 for '.ssh/id_ed25519' are too open`)
   - Fix: `ssh Jahcoozi@192.168.22.90 "chmod 600 ~/.ssh/id_ed25519" && ssh ... "sudo systemctl restart ssh-openclaw-forward.service"`
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
- Binary: `/home/moltbotadmin/.local/lib/node_modules/openclaw/dist/index.js` (seit Konsolidierung 2026-04-28; war vorher `~/.npm-global/...`)
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

### 2026-04-20 — SSH-Key-Permission crasht Tunnel-Backend

**Symptom:** `openclaw.forensikzentrum.com` liefert HTTP 502, Gateway lokal OK (HTTP 200 auf :18789), cloudflared laeuft. SSH-Forward-Service auf NAS im Crash-Loop mit Restart-Counter 1097 (exit 255).

**Ursache:** Private-Key `/home/Jahcoozi/.ssh/id_ed25519` hatte Permissions `0750` (group/other readable). OpenSSH-Client lehnt den Key hart ab (`Permissions ... are too open. This private key will be ignored.`) → Authentication faellt auf Password zurueck → `Permission denied (publickey,password)` → Forward kann Port 18790 nicht oeffnen → cloudflared-Ingress `:18790` ohne Backend → **502**.

**Diagnose-Pfad:**
1. DNS OK, curl → 502 (Remote: Cloudflare-IP) → Problem liegt hinter Cloudflare
2. `systemctl --user is-active openclaw-gateway.service` auf ugreen → `active`, HTTP 200 lokal → Gateway OK
3. `sudo systemctl status ssh-openclaw-forward.service` auf NAS → `activating (auto-restart)`, Restart-Counter 1097
4. `sudo journalctl -u ssh-openclaw-forward.service -n 30` → `Permissions 0750 ... are too open`

**Fix (eine Zeile):**
```bash
ssh Jahcoozi@192.168.22.90 "chmod 600 ~/.ssh/id_ed25519 && sudo systemctl restart ssh-openclaw-forward.service"
```

**Erkenntnisse:**
- **Restart-Counter ist stilles Fruehwarnsignal** — 1097 Restarts = Service seit Wochen defekt, aber kein Alert. Monitoring-Luecke: Prometheus-Textfile-Collector oder einfacher Cron-Check auf `systemctl is-failed / ActiveState=activating` auf NAS waere angebracht.
- **SSH-Tunnel als Cloudflare-Origin ist fragil** — bricht bei Key-Rotation, Perm-Aenderung, Netz-Hiccup. Robustere Alternativen:
  - `cloudflared` direkt auf ugreen (kein Hop ueber NAS, Proxmox-Firewall muesste aber Outbound zu `*.cfargotunnel.com` erlauben)
  - WireGuard-Link NAS↔ugreen statt SSH (persistente Verbindung, bessere Reconnect-Semantik)
- **Diagnose-Heuristik bei 502:** DNS → lokaler Gateway → SSH-Forward-Status + Restart-Counter → Forward-Backend (`curl :18790`) → Tunnel-Config. Restart-Counter sofort lesen, nicht erst nach Port-Checks.
- **Key-Permissions-Regel:** Jeder SSH-Client-Key MUSS `0600` (oder `0400`) sein. Bei Key-Provisioning via `scp`/`rsync` ohne `-p` oder aus Backup-Restores kann das kippen.

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

### 2026-04-12 — Weekly-Review Blind Spots + Memory-Archivierung

**Cron-Review-Prompt muss EXPLIZIT alle Dateitypen auflisten:**
- GPT-4.1-mini (~20k Input-Tokens) liest NUR was der Prompt explizit nennt
- Alter Prompt: "Analysiere .learnings/ (ERRORS.md, LEARNINGS.md, FEATURE_REQUESTS.md)" — uebersah 3 separate `LRN-*.md` Dateien
- Neuer Prompt: Enthält jetzt `ls .learnings/LRN-*.md` Anweisung + `find memory/ -maxdepth 1 -name "*.md" -mtime +30`
- Regel: Bei kleinen Modellen KEINE impliziten Erwartungen — alles explizit formulieren

**Cron-Jobs nach Agent-Umbau validieren (CHECKLISTE):**
- Bei jeder Agent-Topologie-Aenderung: `openclaw cron list` → alle Agent-IDs pruefen
- `weekly-review` hatte noch `organizer` referenziert (Agent existierte nicht mehr, fiel auf Default zurueck)
- Fix: `openclaw cron edit <id> --agent <neuer-agent>`
- Validierung: In der `cron list` Ausgabe muss die Agent-Spalte einen existierenden Agenten zeigen

**Memory-Archivierung ist NICHT automatisch:**
- Cron-Review behauptete faelschlich "keine Dateien >30 Tage" — 4 Dateien lagen noch im Root
- Archivierungs-Befehl: `find ~/clawd/memory/ -maxdepth 1 -name "2026-*.md" -mtime +30 -exec mv {} ~/clawd/memory/archive/ \;`
- Wird jetzt vom Weekly-Review-Cron mitgeprueft (aber nicht automatisch verschoben — nur gemeldet)

**Weekly-Review-Ergebnis MUSS persistiert werden:**
- Alter Cron schrieb NUR eine Telegram-Nachricht, keine Datei
- Neuer Prompt fordert: `.learnings/weekly_review_YYYYMMDD.txt` schreiben
- Ermoeglicht Vergleich ueber Wochen und Nachvollziehbarkeit

### 2026-04-19 — Push-Blocker, Bulk-Rebase-Pattern, FAST_COMMIT Escape

**Push-Authentifizierung blockiert (CRITICAL):**
- Gespeicherte Git-Credentials authentifizieren als `jahcoozi92-collab` — ein reiner Collaborator-Account mit Read-only-Rechten
- `git push` scheitert mit 403 sowohl auf `clawdbot/clawdbot.git` als auch `openclaw/openclaw.git`
- `gh` ist zusätzlich nicht authentifiziert — der Credential-Helper liefert den PAT, nicht `gh auth`
- Vor jedem Push-Versuch: Diana fragen, ob lokal gearbeitet werden soll oder erst Credentials geklaert werden (z.B. Haupt-Account `jahcoozi92` oder Fork)
- Nicht als Fehler reporten, sondern als bekannten Zustand kommunizieren

**Repo-Migration `clawdbot/clawdbot` → `openclaw/openclaw`:**
- Kanonisches Repo laut `~/clawdbot-src/CLAUDE.md`: `openclaw/openclaw` (nicht mehr `clawdbot/clawdbot`)
- Lokales Remote in `~/clawdbot-src` kann noch auf alten Namen zeigen
- Git-History ist identisch (Commit-Hashes matchen 1:1 zwischen beiden Repos — reine Umbenennung)
- Umstellung: `git remote set-url origin https://github.com/openclaw/openclaw.git`
- WICHTIG: Umstellung alleine loest Push-Problem nicht — Write-Auth fehlt auf beiden Repos

**Bulk-Rebase-Pattern bei grosser Divergenz (>1000 Commits hinterher):**
- NICHT `git rebase origin/main` direkt — Konflikt-Kaskade unausweichlich
- Stattdessen Cherry-Pick-Strategie:
  1. WIP in atomaren Commits sichern (`scripts/committer "<msg>" <file...>`, scoped Staging)
  2. Backup: `git branch backup/main-pre-rebase-YYYY-MM-DD && git tag backup-main-YYYY-MM-DD` (beide, falls Branch versehentlich geloescht wird)
  3. Redundanz-Check: `git cherry -v origin/main main` (zeigt Patch-ID-Duplikate, NICHT Konflikte)
  4. Neuer Branch: `git checkout -b rebase/YYYY-MM-DD origin/main`
  5. Commits einzeln cherry-picken mit `-x` (Flag hinterlaesst Origin-Hash im Commit-Message fuer Traceability)
  6. Bei Konflikt: inspect → `--skip` (redundant/obsolet) oder manuell resolven + `--continue`
  7. `main` unberuehrt lassen, bis Verifikation komplett (Option B in Phase 3)
- Erwartungskalibrierung: ~20% Skip/Conflict-Rate bei mehreren Monaten Divergenz
- Praxis-Beispiel (2026-04-19): 17 Commits → 14 gelandet, 3 uebersprungen (1 selbst-kaputt, 1 upstream-dupliziert, 1 in upstream entfernter Code)

**FAST_COMMIT=1 als legitimer Escape:**
- Pre-commit-Hook ruft `pnpm check` repo-weit auf (tsgo + oxlint + format)
- Scheitert regelmaessig an pre-existenten TS-Fehlern in unverwandtem Code (z.B. `extensions/qa-lab/src/providers/aimock/server.ts`)
- `FAST_COMMIT=1` ueberspringt den repo-weiten Check — legitim laut `~/clawdbot-src/CLAUDE.md`
- Vorbedingung: Die touched surface MUSS separat verifiziert sein (`pnpm test -- <file>`)
- Kein Default, nur bei bekanntem Fremd-Breakage — IMMER erwaehnen warum genutzt
- Funktioniert auch bei `git cherry-pick --continue` (`FAST_COMMIT=1 git cherry-pick --continue`)

**Cherry-Pick-Konflikt-Typologie:**
- `add/add`: beide Seiten haben dieselbe Datei → meist `--skip` (upstream hat eigene Version)
- `content`: Zeilen kollidieren → manuell `git checkout --ours <file>` oder `--theirs <file>` + `git add` + `--continue`
- gelöschte Ziel-Funktion (upstream refactored komplett): unser Fix ist obsolet → `--skip`
- `git cherry -v` erkennt nur Patch-ID-Duplikate, NICHT obige Konflikte — Cherry-Pick-Ausfaelle einplanen

**Laien-Erklaerungs-Modus:**
- Diana fragt gelegentlich "erklaere fuer 12-Jaehrige" → Analogien statt Code-Snippets
- Bewaehrte Metaphern: Rezeptbuch fuer Rebase, Notizbuch fuer Branch, Klebezettel fuer Commits, Foto fuer Backup-Tag
- Bild > Syntax, Metapher > Fachbegriff
- Funktioniert auch als Validierung des eigenen Verstaendnisses — wenn keine Metapher moeglich, fehlt Tiefe

### 2026-04-20 — Codex-Sprache, safeBinProfiles, main/-Default-Verhalten

**Codex-CLI auf Deutsch via `~/.codex/AGENTS.md` (CRITICAL):**
- Codex-CLI hat KEINE `~/.codex/config.toml` fuer Soft-Settings (Sprache/Stil) — Konvention ist `~/.codex/AGENTS.md`, wird automatisch in jede Codex-Session als System-Prompt-Erweiterung injiziert
- Plugin-Cache (`~/.claude/plugins/cache/openai-codex/codex/<version>/`) wird bei Updates ueberschrieben — `~/.codex/AGENTS.md` liegt ausserhalb und ueberlebt Plugin-Upgrades
- Inhalt: "Antworte immer auf Deutsch — Code-Identifier, Pfade, CLI-Kommandos, Strukturmarker (`[P1]`, `Target:`) bleiben englisch; nur Fliesstext ist deutsch."
- Trigger: Wenn `/codex:review` o.ae. auf Englisch antwortet trotz deutscher Userpraeferenz
- Analog zu Claude Code: Bei Codex ist es eine workspace-globale Datei statt User-Prompt-Sprachblock

**`agents/main/` NIEMALS loeschen — Plugin-Default-Pfad (CRITICAL):**
- `paths-CZMxg3hs.js:resolveStorePath` nutzt hardcoded `agentId = opts?.agentId ?? "main"` als Default
- Telegram-Plugin (`extensions/telegram/send-DlzbQJQs.js:resolveSentMessageStorePath`) ruft `resolveStorePath` ohne `agentId` auf → globaler Sent-Message-Store landet in `agents/main/sessions/sessions.json.telegram-sent-messages.json`
- `agents/main/agent/models.json` ist ebenfalls aktiver Models-Cache (auto-generiert)
- Symptom: doctor warnt "Found 1 agent directory on disk without a matching agents.list entry — Examples: main" — false-positive, Architektur-bedingt
- Loeschen → Verzeichnis legt sich sofort neu an, Telegram-Dedup-State (Edit-Tracking, TTL) geht verloren
- Migration-Schuld vom Sub-Agent-Umbau 2026-04-10 (main → sonnet/opus/pflege/pflege-eu): Plugin-SDK wurde gebaut als es nur "main" gab, globaler Store-Default nicht mitgezogen

**Sub-Agent-Umbauten: Symlinks pruefen:**
- Beim Umbau `main` → `sonnet/opus/pflege/pflege-eu` blieb `agents/sonnet/agent` als Symlink → `agents/main/agent`
- Nach manueller Archivierung von `agents/main/` (`_archive_main-searcher_*.tar.gz`) zeigte der Symlink ins Leere
- Symptom: Cron-Job-Fehler `ENOENT: no such file or directory, mkdir '~/.openclaw/agents/sonnet/agent'`
- Fix: `rm sonnet/agent && mkdir sonnet/agent && tar -xzf _archive_*.tar.gz -C /tmp main/agent/auth-profiles.json … && cp /tmp/main/agent/*.json sonnet/agent/ && chmod 600 sonnet/agent/*.json`
- Auth-Profile aus Archiv wiederherstellen lohnt sich (Anthropic-OAuth-State spart Re-Login)
- Praeventiv vor jedem Sub-Agent-Umbau: `find ~/.openclaw/agents -type l` listet alle Symlinks auf

**safeBinProfiles fuer Interpreter sind PFLICHT (Sandbox-Escape):**
- `python3`/`node`/`bun` in `tools.exec.safeBins` ohne Profile → Sandbox-Escape moeglich via `python3 -c "import os; os.system(...)"` bzw. `node -e "..."`/`bun --eval`
- Built-in `SAFE_BIN_PROFILES` (`paths-CZMxg3hs.js`) decken nur jq/cut/sort/uniq/head/tail/tr/wc — Interpreter NICHT
- Loesung: explizite `safeBinProfiles`-Eintraege mit `deniedFlags`:
  ```json
  "python3": { "deniedFlags": ["-c","-m","-i","-W","--command"], "allowedValueFlags": ["--type","--props","--where","--id","--from","--rel","--to"] },
  "node":    { "deniedFlags": ["-e","-p","--eval","--print","--input-type","-i","--interactive"] },
  "bun":     { "deniedFlags": ["-e","--eval","--inspect","--inspect-brk","--inspect-wait"] }
  ```
- `allowedValueFlags` muss alle in Cron-Jobs genutzten long-flags enthalten (sonst `validateSafeBinArgv` lehnt unbekannte long-flags ab → Crons brechen, koennen interaktiv kein Approval geben)
- `python3.allowedValueFlags` enthaelt alle ontology.py CLI-Flags (`--type/--props/--where/--id/--from/--rel/--to`)
- `isSafeLiteralToken` blockt Glob-Patterns (`*?[]`) und Pfad-Prefixes (`./`/`../`/`~`/`/`) — relative Pfade ohne Prefix wie `skills/ontology/scripts/ontology.py` und JSON-Werte wie `'{"status":"open"}'` gehen durch
- `safeBinProfiles` orthogonal zu `exec-approvals.json`: Profile = "vertraue ich diesem Pattern blind?", approvals = "hat User dieses spezifische Kommando freigegeben?"

**`safeBinTrustedDirs` fuer npm-global Installs:**
- Default: `["/bin","/usr/bin"]` (siehe `DEFAULT_SAFE_BIN_TRUSTED_DIRS` in `exec-safe-bin-trust-BcrCYHRC.js`)
- Doctor-Warning "openclaw resolves outside trusted safe-bin dirs" entsteht weil `~/.local/bin/openclaw` (npm-global Wrapper) ausserhalb liegt
- Fix in `tools.exec`:
  ```json
  "safeBinTrustedDirs": ["/home/moltbotadmin/.local/bin", "/home/moltbotadmin/.npm-global/bin"]
  ```
- Undokumentiert in der Config-Schema-Uebersicht — Hinweis kommt nur via doctor

**Backup-Pattern vor riskanten Config-Edits:**
- IMMER vor Edit an `~/.openclaw/openclaw.json`: `cp openclaw.json openclaw.json.pre-<reason>-<YYYY-MM-DD>`
- Beispiel-Backups: `openclaw.json.pre-allowlist-fix` (2026-04-20), `openclaw.json.pre-optimize-2026-04-20`
- Rollback: `cp openclaw.json.pre-<reason>-<date> openclaw.json && systemctl --user restart openclaw-gateway.service`
- Backup-Naming nach Grund, nicht nur Datum — Datum allein ist mehrdeutig wenn mehrere Edits am gleichen Tag

**Doctor false-positive Klassifizierung:**
- "Claude-CLI auth profile missing (anthropic:claude-cli)": IRRELEVANT wenn Anthropic-API direkt genutzt wird (nicht Headless-CLI als Provider)
- "Found 1 agent directory on disk without matching agents.list entry — Examples: main": Architektur-bedingt (siehe oben)
- "memory-lancedb still uses legacy before_agent_start": nur via Plugin-Maintainer-Update behebbar — keine User-Action
- "Gateway bound to lan (0.0.0.0) (network-accessible)": bewusst (LAN 192.168.22.206:18789), nicht "fix"
- Prinzip: Vor jedem doctor-fix die Warnung verstehen statt blind zu folgen — manche sind Architektur-Statements, kein Defekt

**Bonjour-Watchdog Race nach Restart:**
- `openclaw doctor` direkt nach `systemctl --user restart openclaw-gateway.service` kann mit "gateway timeout after 10000ms" scheitern
- Ursache: Bonjour-Service-Advertiser haengt manchmal in `announcing` State (>10s), `[ws] closed before connect`-Logs
- Recovered automatisch nach `restarting advertiser`, Gateway dann gesund
- Vor Doctor-Lauf nach Restart: 5-6 Sekunden warten, oder `curl -s http://127.0.0.1:18789/healthz` als Smoke-Test

### 2026-04-22 — OpenClaw-Limits erkannt: Voice ist separater Stack

**Architektur-Prinzip (wichtigste Lektion der Session):**
**OpenClaw ist Langform-Backend, KEIN Universal-Backend.** Voice-Assist und Event-Monitoring gehoeren in spezialisierte, unabhaengige Services. OpenClaw bleibt fuer Telegram, komplexe Dialoge, Memory-basierte Konversation. Dieses Prinzip praegt kuenftige Architektur-Entscheidungen.
- Voice-Stack → HA+OpenAI-Conversation-Integration direkt (siehe `project_voice_assistant.md`)
- Event-Monitoring (z.B. NAS100-News) → `~/market-monitor/` standalone Node-Service
- OpenClaw-CLI NIEMALS als Voice-Backend aufrufen

**OpenClaw-CLI-Latenz: 30-45s pro Turn (live gemessen 2026-04-22):**
- Full-Workspace-Bootstrap laedt 38.473 Input-Tokens bei jedem Aufruf (SOUL + AGENTS + MEMORY + TOOLS + 14 Packages Memory-History)
- `--session-id <id>` hilft NICHT (48s Latenz trotz Session-Reuse — Gateway pool-waermt Sessions nicht fragment-fein)
- `--local` embedded mode hilft NICHT (44s — Bootstrap unveraendert, nur Gateway-Bypass)
- Konsequenz: CLI ist fuer Langform-Tasks (Cron-Jobs, Telegram-Dialog), NICHT fuer Request/Response unter 10s

**Anthropic-API-Key tot (HTTP 401 invalid x-api-key):**
- Direktcall `POST https://api.anthropic.com/v1/messages` mit Key aus `.env` schlaegt mit `authentication_error` fehl
- Betrifft ALLE 4 Agents (sonnet, opus, pflege, pflege-eu) — alle nutzen `anthropic/claude-sonnet-4-6` oder `anthropic/claude-opus-4-6`
- Fallback-Kette greift silent: OpenRouter → `minimax/minimax-m2.7`
- Qualitativ ein spuerbarer Downgrade (MiniMax hat schwaeches Tool-Calling, langsamer)
- **Fix:** Neuen Key via https://console.anthropic.com/settings/keys, in `~/.openclaw/.env` als `ANTHROPIC_API_KEY` eintragen, `systemctl --user restart openclaw-gateway.service`
- **Verifikation:** `curl -s -o /dev/null -w "%{http_code}\n" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" https://api.anthropic.com/v1/messages -d '{"model":"claude-sonnet-4-6","max_tokens":10,"messages":[{"role":"user","content":"ping"}]}'` → muss `200` zurueckgeben

**Fallback-Kette laeuft silent — Debug via `result.meta.agentMeta.model`:**
- Wenn Primary-Provider tot → Gateway schaltet ohne sichtbaren Fehler auf naechstes Modell
- User-Wahrnehmung: "Agent versteht mich ploetzlich nicht mehr gut" obwohl Config unveraendert
- Debug-Pfad: `openclaw agent --json --message "ping"` → `result.meta.agentMeta.model` zeigt TATSAECHLICH genutztes Modell
- Bei `minimax/*` oder `openrouter/*` als Ausgabe obwohl Agent auf `anthropic/*` konfiguriert → Primary-Provider tot

**Existierende HA-Bridge auf Port 18790 ist Push-only:**
- Script: `~/bin/openclaw-ha-bridge.py` (Python stdlib HTTP-Server)
- POST-Endpoint nimmt `{message, deliver:true}`, started Subprocess-Thread mit `openclaw agent --channel telegram --deliver`, antwortet sofort `{status:"queued"}`
- **KEINE Request/Response-Semantik** — die Agent-Antwort landet via Telegram, nicht im HTTP-Response
- Rolle: Webhook fuer HA-Automationen ("Tuer auf → OpenClaw schickt Push-Benachrichtigung")
- **NICHT umbaubar zu Voice-Backend** ohne Full-Rewrite — selbst dann leidet die Latenz-Erwartung (wegen CLI-Bootstrap)

**OpenClaw-Gateway auf Port 18789 ist KEIN programmatischer API-Endpoint:**
- `/` → Control-Panel-HTML (Theme claw/knot/dash)
- `/v1/chat/completions` → HTTP 404
- `/v1/models` → HTTP 200 aber HTML-Response (Catch-All fuer unbekannte Routes)
- Gateway hat **kein** OpenAI-kompatibles Interface — Extended OpenAI Conversation kann hier nicht andocken
- Extern sichtbar unter `openclaw.forensikzentrum.com` (via Cloudflare-Tunnel) — ebenfalls nur UI, keine programmatische API

**`openclaw agent --json` — strukturiertes Output-Format:**
```json
{
  "runId": "uuid",
  "status": "ok",
  "result": {
    "payloads": [{"text": "Antwort", "mediaUrl": null}],
    "meta": {
      "durationMs": 11707,
      "agentMeta": {
        "sessionId": "uuid",
        "provider": "openrouter|anthropic|openai",
        "model": "minimax/minimax-m2.7|...",
        "usage": {"input":..., "output":..., "total":...}
      }
    }
  }
}
```
- `--timeout <seconds>` Override des Config-Defaults (600s)
- `--deliver` schickt Antwort via Channel; ohne `--deliver` bleibt Antwort nur im JSON
- Praxis: `--json --timeout 60` fuer programmatische Nutzung; NIE fuer Voice (Latenz-Problem)

### 2026-04-23 — Claude Cowork for Linux auf moltbot installiert

**Repo:** `https://github.com/johnzfitch/claude-cowork-linux` (v4.0.0, unofficial)

**Was ist Cowork?** Claude-Desktop-Feature das einen Folder als Sandbox nutzt und Dateien lokal liest/schreibt. Normalerweise macOS-only (mit Linux-Sandbox-VM darunter); dieses Repo ersetzt die macOS-nativen Module (`@ant/claude-swift`, `@ant/claude-native`) durch JS-Stubs und uebersetzt VM-Pfade auf Host-Pfade, sodass Cowork direkt auf Linux x86_64 laeuft — ohne VM, ohne macOS.

**KRITISCH — Kommunikations-Regel bei Dritt-Repos mit mehrdeutigen Namen:**
- IMMER im ersten Antwort-Satz nach `git clone` benennen was installiert wird und was es NICHT ist
- Grund (2026-04-23): User fragte nach komplettem Install "claude cowork will ich installieren", weil ich nie sagte "dieses Repo = Claude Cowork (nicht der regulaere Claude Desktop)"
- Pattern: "Dieses Repo installiert X (nicht Y). Unterschied: ..."

**Install-Pfade (moltbot):**
- App: `~/.local/share/claude-desktop/` (enthaelt `linux-app-extracted/` mit entpacktem macOS-App-Bundle + JS-Stubs)
- Launcher: `~/.local/bin/claude-desktop`, `~/.local/bin/claude-cowork` (Symlink auf ersteren — **beide sind dasselbe Binary**, Cowork-Feature ist via `enable-cowork.py`-Patch in der `app.asar` aktiviert)
- Sessions-Symlink: `/sessions → ~/.config/Claude/local-agent-mode-sessions/sessions` (Root-Symlink, braucht sudo)
- Logs: `~/.local/state/claude-cowork/logs/startup.log` (Launcher started nohup detached — Shell kehrt sofort zurueck, Fenster oeffnet asynchron)

**Abhaengigkeiten (bereits auf moltbot):**
- System: `git`, `7z` (p7zip-full), `node` v22, `npm`, `bwrap` (bubblewrap) — alle via apt
- npm-global: `electron` (v41.3), `@electron/asar` (v4.2) — `npm install -g electron @electron/asar`
- DMG-Download: `fetch-dmg.js` zieht den macOS-DMG (~200MB) direkt vom Anthropic-CDN — KEIN macOS-Host noetig

**Doctor-Check:** `claude-desktop --doctor` oder `bash ~/claude-cowork-linux/install.sh --doctor` (17 Checks, muss 17/17 OK zeigen)

**`/sessions`-Symlink-Falle (Session-Erkenntnis 2026-04-23):**
- `install.sh` scheitert bei `sudo ln -s` wenn der Symlink bereits existiert — **auch wenn er auf einen fremden User zeigt**
- Auf moltbot gesehen: `/sessions → /home/yoga7/.config/Claude/...` (vermutlich aus frueherem yoga7-User-Versuch hier auf der Box)
- **Fix:** `readlink /sessions` pruefen, dann `sudo ln -sfn "$HOME/.config/Claude/local-agent-mode-sessions/sessions" /sessions` (`-sfn`: force + no-deref, ueberschreibt Directory-Symlink korrekt)

**Headless-VM + Electron-GUI:**
- `claude-desktop` ist eine Electron-App (kein CLI) — braucht `$DISPLAY` oder `$WAYLAND_DISPLAY`
- moltbot ist headless → Start nur via X11-Forwarding (`ssh -X moltbotadmin@192.168.22.206`), VNC/RDP oder angeschlossenem Monitor
- Alternative: Cowork nicht auf moltbot betreiben, sondern auf einem Desktop-Host (yoga7 Kali WSL hat Display)

**Non-interaktives sudo in Claude-Code-Sessions:**
- `install.sh` faellt still zurueck wenn `sudo` ohne TTY gerufen wird (`sudo: Zum Lesen des Passworts ist ein Terminal erforderlich`) — das Script logged einen `log_warn` mit dem manuellen Command
- Funktionierendes Pattern: User tippt `! <command>` am Claude-Code-Prompt — der `!`-Prefix hebt den Befehl in eine interaktive Subshell und liefert Output zurueck in die Session
- Anwendung: Alle sudo-Schritte explizit als `! sudo ...` formulieren, nicht versuchen sie ueber Bash-Tool auszufuehren

### 2026-04-25 — Self-Improve Cron-Optimierung + Modell-Limits + Tool-Sandbox

Ausgangsbefund (Gateway-Log): self-improve Cron-Job zeigt seit Wochen `stuck session` Warnings (5+ Minuten processing-Zeit, queueDepth=0), ENOENT-Halluzinationen auf `memory/YYYY-MM-DD.md`, INFO-Spam wegen group-writable bin-Dirs. Drei Fixes umgesetzt; sechs Lektionen extrahiert.

**KRITISCH — `code_execution`-Tool ist sandboxed-remote, KEIN Workspace-FS-Zugriff:**
- Tool-Policy registriert es als "Run sandboxed remote analysis" (siehe `~/.npm-global/lib/node_modules/openclaw/dist/tool-policy-*.js`)
- Jeder Versuch `open("/home/moltbotadmin/clawd/...")` aus code_execution scheitert mit "Datei nicht gefunden"
- **Konsequenz fuer Cron-Prompts:** Fuer File-IO immer `read`/`edit`/`write` in der Tools-Allowlist, NIEMALS `code_execution` als File-Tool einplanen
- Test-Run-Symptom: Job laeuft sauber durch, status=ok, aber inhaltlich gescheitert — Mini halluziniert "Datei nicht gefunden" obwohl sie existiert (aus seiner Sandbox-Sicht stimmt das)

**KRITISCH — gpt-4.1-mini ungeeignet fuer Append-via-edit-Pattern:**
- Mini kann lange JSONL-Zeilen mit Escapes und Anfuehrungszeichen NICHT byte-genau zwischen Read-Call und Edit-Call reproduzieren
- Halluzinations-Failure-Mode: erfindet Datei-Namen ("Append-File", "delta.jsonl") statt edit-Fehler zu melden, behauptet false-positive Erfolg
- Anti-Halluzinations-Klauseln im Prompt ("NIEMALS halluzinieren") werden ignoriert — Trainings-Bias dominiert
- **Loesung:** Sonnet 4.6 mit `--thinking low --timeout-seconds 180` fuer Cron-Jobs die strukturierte File-Mutation brauchen
- Mini eignet sich fuer reine Lese/Klassifikations-Workflows, nicht fuer File-Append mit String-Reproduktion

**KRITISCH — Cron-Status `ok` ist semantik-frei:**
- `lastRunStatus: ok` und `lastDeliveryStatus: delivered` messen NUR "Job getriggert + Telegram-Nachricht raus", nicht "Task korrekt erledigt"
- Inhaltliche Fehlschlaege (edit failed, halluzinierter Erfolg) gehen als `ok` durch — der User glaubt es lief alles
- **Validierungs-Pflicht:** Bei Cron-Audit immer `~/.openclaw/cron/runs/<job-id>.jsonl` letzten Eintrag anschauen (`tail -1 | python3 -m json.tool`), nicht nur `cron list`-Status. Felder die zaehlen: `status`, `error`, `summary` und ECHTE Mutation der Ziel-Datei verifizieren (`wc -l` vor/nach)

**OpenClaw-Cron ist Agent-Scheduler, kein Shell-Cron:**
- `openclaw cron add` kennt nur `--message` (LLM-Prompt) und `--system-event`, KEIN `--command`/`--target system`
- Reine File-Operationen (touch, cleanup, backup) gehoeren in **systemd-User-Timer**, sonst zahlt man LLM-Kosten + 30s+ Laufzeit fuer eine 0.001s-Operation
- **Pattern:** `~/.config/systemd/user/<job>.{service,timer}` mit `Type=oneshot` + `Persistent=true` (holt verpasste Runs nach Reboot/Suspend nach)
- Beispiel umgesetzt: `clawd-daily-log.{service,timer}` legt taeglich 00:05 das `clawd/memory/$(date +%Y-%m-%d).md` an (idempotent via `touch -a`)

**Sonnet 4.6 mit Prompt-Caching: ~$0.035/Run statt $0.30:**
- Anthropic-Cache hat 5min-TTL, `--thinking off`/`low` reicht fuer strukturierte Workflows
- Bei Cache-Hit fuer 5k-Char-System-Prompt: `input_tokens: 8` (real) — nur Output zaehlt voll
- Macht Sonnet 4.6 fuer stabile Cron-Workflows kosteneffektiv genug, dass Modell-Downgrade nicht noetig ist
- Bei 3 Runs/Tag = ~$3/Monat fuer den Self-Improve-Sprint — kein wirtschaftlicher Druck mehr

**`safeBinTrustedDirs`-Permissions tighten:**
- Default-Setup hat `~/.local/bin` und `~/.npm-global/bin` als 775 (group-writable) → Gateway-INFO-Spam bei jedem Start
- Fix: `chmod 755` auf beide Dirs entfernt Warnung ohne Funktionsverlust (single-user host, gruppe nur theoretisch ein Vektor)
- Wichtig: NICHT aus `safeBinTrustedDirs` entfernen — sonst meldet doctor "openclaw resolves outside trusted safe-bin dirs" weil das CLI in einem davon liegt

**Codex Stop-Hook als Prompt-Review-Layer:**
- Codex-Plugin prueft nach `Stop` automatisch ob Aenderungen sinnvoll/konsistent sind
- Hat in dieser Session V2-Prompt blockiert ("Prompt ist in sich widersprüchlich") — fand `max 3 reads` + halluzinierte Tool-API "read gibt total lines zurueck"
- Wertvoll als Review-Layer wenn ich (Claude) selbst Prompts schreibe — fange Halluzinationen ab bevor sie ans LLM gehen
- Aktivierbar via `/setup` (Codex-Plugin)

**Ergebnis-Vergleich (6 Iterationen, 1 Sieger):**

| Version | Modell | Dauer | Status | Append | Notiz |
|---------|--------|-------|--------|--------|-------|
| V1 (alt) | Sonnet | 195s | ok | unklar | Original-Prompt mit edit-Halluzinationen |
| V2 | Mini+code_exec | 72s | ok* | ✗ | Sandbox-Fail |
| V3 | Mini+read | 17s | ok* | ✗ | fragt zurueck statt zu handeln |
| V4 | Mini+ActionBias | 39s | error | ✗ | edit failed, halluziniert Erfolg |
| V5 | Mini+Hardened | 45s | error | ✗ | gleicher Fehler |
| **V6** | **Sonnet+V5-Prompt** | **50s** | **ok** | **✓** | **graph.jsonl 138→140** |

*ok trotz inhaltlichem Fehlschlag — siehe "Cron-Status semantik-frei"

**Backup alter Cron-Job:** `~/.openclaw/cron-self-improve.pre-2026-04-25.json`

### 2026-04-28 — openclaw Update + Plugin-Cleanup + Bin-Prefix-Konsolidierung

**openclaw-Service-Stack auf der VM (Stand 2026-04-28):**
| Unit | Typ | Funktion |
|---|---|---|
| `openclaw-gateway.service` | systemd --user | Node-Prozess `/usr/bin/node ~/.local/lib/node_modules/openclaw/dist/index.js gateway --port 18789` |
| `openclaw-ha-bridge.service` | systemd --user | Python-Bridge `~/bin/openclaw-ha-bridge.py` (ruft `node ~/.local/lib/node_modules/openclaw/dist/entry.js` auf, Port 18790) |
| `openclaw-gateway-watchdog.service` + `.timer` | systemd --user | alle 15 min `is-active`-Check, startet bei Ausfall neu |
| `openclaw-runtime-cleanup.service` + `.timer` | systemd --user | täglich 04:00, behält nur aktuelle Plugin-Runtime-Version (siehe unten); seit 2026-04-28 dedupliziert auch innerhalb derselben Version (jüngster Hash gewinnt) |
| `disk-watchdog.service` + `.timer` | systemd --user | alle 30min, alarmiert via Telegram bei `/`-Use% ≥85% (WARN) / ≥92% (CRIT), 6h Cooldown, all-clear bei Recovery (`~/bin/disk-watchdog.sh`) |
| `memory-drift-audit.service` + `.timer` | systemd --user | wöchentlich Sonntag 09:00, grep-basierter Audit (kein LLM) auf veraltete Pfade/Agent-IDs/Versionen/Default-Modell in MEMORY/SKILL/AGENTS-Files (`~/bin/memory-drift-audit.sh --quiet`) |
| `openclaw-backup.sh` | crontab | alle 5d 03:00, `tar -czf ~/backups/openclaw-$DATE.tar.gz` von `.openclaw/openclaw.json + .env + cron/ + clawd/`, scp auf NAS, MAX_BACKUPS=2 |

**Standard-Update-Pattern (getestet 25→26):**
```bash
ssh moltbotadmin@192.168.22.206 '
  # [0] Backup-First mit Verifikation
  bash ~/bin/openclaw-backup.sh
  BFILE="$HOME/backups/openclaw-$(date +%Y-%m-%d).tar.gz"
  sha256sum "$BFILE" > "${BFILE}.sha256"
  tar -tzf "$BFILE" >/dev/null  # integrity check
  # [1] Update auf den Prefix den die Service-Unit lädt (~/.local nach Konsolidierung)
  npm install -g --prefix ~/.local openclaw@<version>
  # [2] Restart
  systemctl --user restart openclaw-gateway.service
  # [3] Health
  sleep 30  # Plugin-Staging dauert 10–25s
  systemctl --user is-active openclaw-gateway.service
  ss -tlnp | grep ":18789"
  journalctl --user -u openclaw-gateway.service --since "2 min ago" | tail -10
'
```

**Bin-Konflikt-Falle (zwei npm-Prefixes):**
- VM hatte historisch ZWEI npm-Prefixes konfiguriert: `~/.npm-global` (legacy) + `~/.local` (npm config get prefix).
- npm legt Bins automatisch in den Prefix aus `npm config get prefix` → bei `npm install -g` landet alles in `.local`, ABER die Service-Unit lud aus `.npm-global` → Update wirkungslos.
- Zusätzliche Falle: alter Wrapper-Bash-Script unter `~/.local/bin/openclaw` blockiert npm-Install mit `EEXIST` — npm akzeptiert keinen Force-Override ohne `--force`.
- **Konsolidierung erfolgt:** `prefix=~/.local` (XDG-konform), Service-Unit auf `.local/.../dist/index.js` umgebogen, HA-Bridge-Skript ebenso, `.bashrc` PATH-Eintrag für `.npm-global/bin` entfernt. `.npm-global` enthält noch andere Pakete (clawdhub, electron, pm2, mcporter, @anthropic-ai, @google, @openai, @steipete) — bleiben dort, nur openclaw konsolidiert.
- **Backups vor Konsolidierung:** `*.pre-prefix-consolidation.bak` neben jeder geänderten Datei.

**Plugin-Runtime-Wachstum (kritisch wenn Disk knapp):**
- openclaw stagged jede Version separat in `~/.openclaw/plugin-runtime-deps/openclaw-<version>-<hash>/` (Größe ~1.2 GB pro Version).
- Ohne Cleanup geht 55 GB-VM voll — VM hatte vor dem Cleanup `Use% 100%`.
- **Lösung:** systemd --user Timer `openclaw-runtime-cleanup.timer` (täglich 04:00, `Persistent=true`) ruft `~/bin/openclaw-runtime-cleanup.sh` auf; Skript liest aktuelle Version aus `~/.local/lib/node_modules/openclaw/package.json` und löscht alle anderen `openclaw-*-*`-Ordner (inkl. `openclaw-unknown-*`). Race-Condition-Guard: skippt wenn `SubState=activating` (Plugin-Staging läuft).

**systemd --user .service+.timer als persönliches Cron-Replacement:**
- Vorteile gegenüber user-cron: `journalctl --user -u <unit>` für Logs pro Job, `Persistent=true` holt verpasste Runs nach (Reboot/Suspend), Race-Guards via `ExecCondition` oder Skript-Check, atomare deps via `After=` und `Wants=`.
- Pattern für Wartungs-Skripte:
  ```ini
  # ~/.config/systemd/user/<job>.service
  [Unit]
  Description=...
  After=openclaw-gateway.service

  [Service]
  Type=oneshot
  ExecStart=%h/bin/<script>.sh
  StandardOutput=journal
  StandardError=journal

  # ~/.config/systemd/user/<job>.timer
  [Unit]
  Description=...

  [Timer]
  OnCalendar=*-*-* 04:00:00
  Persistent=true
  Unit=<job>.service

  [Install]
  WantedBy=timers.target
  ```
  Aktivierung: `systemctl --user daemon-reload && systemctl --user enable --now <job>.timer`. Test-Run: `systemctl --user start <job>.service && journalctl --user -u <job>.service --since "1 min ago"`.

**Service-Unit-Description ist kosmetisch:**
- `Description=OpenClaw Gateway (v2026.4.21)` ist hardcoded in der `.service`-Datei — bleibt nach `npm install`-Updates statisch falsch. Funktional egal, aber irritiert beim Debug. Aus `journalctl --user -u openclaw-gateway` zeigt sich die Description; echte Version aus `package.json` lesen.

**Disk-Kritikalitäts-Warnung:**
- VM-Root-FS war vor Cleanup bei 100% Use% (0 verfügbar). openclaw selbst loggte `[plugins] amazon-bedrock: Low disk space ... 921 MiB available; bundled plugin runtime dependency staging may fail.` — das ist ein Hard-Fail-Signal.
- Backup-Rotation MAX_BACKUPS=2 ist knapp für tägliche Backups (2 Tage Retention). Bei Update-Vorab-Backup + 1 Daily-Backup besteht Risiko, dass das Vorab-Backup beim nächsten Cron rotiert wird. Empfehlung bei Major-Updates: explizit als `~/backups/openclaw-PRE-UPDATE-<version>.tar.gz` ablegen statt nur Daily.

### 2026-04-28 — OpenClaw Modell-Switch-Pattern + Hot-Reload + DeepSeek-Hardware-Realitaet

**3-Stellen-Regel fuer Modell-Wechsel** (KRITISCH — sonst wirkt Aenderung nicht):
Bei einem echten Default-Modell-Wechsel muessen DREI Stellen in `~/.openclaw/openclaw.json` synchron sein:
1. `agents.defaults.model.primary` — globaler Default (Cron, embedded-fallback, Defaults-Erbschaft)
2. `agents.list[<id>].model` — **harter Override** pro Agent. Wenn gesetzt, ignoriert er den Default komplett. Aktuell sind sowohl `sonnet` als auch `opus` mit hartcodiertem `model:` definiert.
3. `agents.defaults.model.fallbacks` — Reihenfolge anpassen: das frueher-primaere Modell sollte als #1 Fallback rein (Sicherheitsnetz fuer Tool-Use-Issues)

**Wenn nur (1) geaendert wird, passiert NICHTS** — `openclaw agents list` zeigt weiter das alte Modell, Logs zeigen weiter `agent model: <alt>`. Verifikation per Smoke-Test + Log-Grep ist Pflicht.

**Hot-Reload-Verhalten** (verifiziert per Log `config hot reload applied`):
- `agents.defaults.model.{primary,fallbacks}` → **hot reload, kein Restart noetig**
- `agents.list[].model` → braucht Gateway-Restart
- Hot-Reload zeigt in Log-Zeile: `config change detected; evaluating reload (agents.defaults.model.primary, agents.defaults.model.fallbacks)` gefolgt von `config hot reload applied`

**Smoke-Test-Trick: Modell glaubt sich falsch**
Beim Verifikations-Test nicht der Modell-Selbstauskunft trauen — DeepSeek-V3.1 antwortete auf "Welches Modell bist du?" mit `minimax-m2.7` (= Halluzination). **Wahrheit nur in Gateway-Logs**: `grep "agent model:" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -3`.

**Agent-Liste IMMER live verifizieren** (Memory ist veraltungs-anfaellig):
Vor dem Referenzieren von Agent-IDs `openclaw agents list` ausfuehren. Dieses MEMORY und Skill-Stand 2026-04-10 sagten "4 Agenten: sonnet/opus/pflege/pflege-eu" — Realitaet 2026-04-28: nur `sonnet` (default) und `opus` existieren. pflege/pflege-eu wurden zwischenzeitlich entfernt. Memory in `~/.claude/projects/-home-moltbotadmin/memory/MEMORY.md` entsprechend korrigiert.

**DeepSeek-V4-Hardware-Realitaet** (Self-Host vs. Cloud entscheiden):
| Modell | Params | RAM Q4_K_M | RAM Q3_K_M | moltbot (9.7GB) | NAS DXP4800 (~32GB max) | Mac Studio M4 Ultra 128GB |
|---|---|---|---|---|---|---|
| DeepSeek V4-Flash | 158B (MoE) | ~95 GB | ~75 GB | ❌ | ❌ | ✅ |
| DeepSeek V4-Pro | groesser | >150 GB | ~120 GB | ❌ | ❌ | ⚠ |
| DeepSeek V3.1 | 671B | ~400 GB+ | ~280 GB | ❌ | ❌ | ❌ |
| Qwen 2.5 14B | 14B | ~9 GB | ~7 GB | ⚠ knapp | ✅ | ✅ |
| DeepSeek-R1 14B | 14B | ~9 GB | ~7 GB | ⚠ knapp | ✅ | ✅ |

V4-Weights sind **frei verfuegbar** (MIT, `deepseek-ai/DeepSeek-V4-Flash` auf HF, GGUF via `tecaprovn/deepseek-v4-flash-gguf`) — Blocker ist rein Hardware. Self-Host ist Mac-Studio-Klasse.

**`:cloud`-Tags sind NICHT lokal** (DSGVO-relevant!):
NAS-Ollama (192.168.22.90:11436) listet `:cloud`-Modelle wie `deepseek-v3.1:671b-cloud`, `gpt-oss:120b-cloud` etc. — die werden aber von Ollamas USA-Servern bedient. NAS-Ollama proxiert nur. Fuer DSGVO-sensible Agents (z.B. Pflege) NIE `:cloud`-Tags nutzen.

**Aktueller Default** (umgestellt 2026-04-28):
- Primary: `ollama/deepseek-v3.1:671b-cloud` (FREE, ~800ms direkt / ~75s via Agent wegen Workspace-Loading)
- Fallback #1: `anthropic/claude-sonnet-4-6` (Sicherheitsnetz)
- Backup: `~/.openclaw/openclaw.json.pre-deepseek-primary-2026-04-28`
- Rollback: `cp <backup> ~/.openclaw/openclaw.json` (Hot-Reload macht den Rest)

**Disk-Voll-Warnung im Log** (96% Belegung auf `/`, 2.1GB frei): Erkennbar an Log-Eintrag `startup model warmup failed for ...: Error: ENOSPC: no space left on device, write` — separates Aufraeumen noetig (alte LanceDB-Memory, npm-Caches, Logs). **Cross-Reference:** Siehe Plugin-Cleanup-Sektion oben — die `openclaw-runtime-cleanup.timer` (taeglich 04:00) ist die strukturelle Loesung dafuer (Plugin-Runtime-Verzeichnisse waren der Hauptverbraucher, ~1.2 GB pro Version).

### 2026-04-27/28 — Outcome-First Cron-Audit + Browser-Relay-Limits + systemd-Timer-Pattern

**Outcome-First Cron-Audit-Methode:**
Pro Job genau 1 Frage stellen: *"Was waere konkret schlechter wenn dieser Job nicht liefe?"* — Diana antwortet ehrlich, dann fliegen meist 60-80% raus. 2026-04-27-Audit: 7 LLM-Crons → 2 (5 weg/ersetzt). Faustregel: **Reduzieren > Optimieren**.

**KRITISCH — Cron-Audit IMMER den Prompt anschauen, nicht nur Job-Namen:**
- "Nasdaq NQ Schnell-Check" sah nach Routine-Briefing aus, war aber **persoenlicher Margin-Call-Waechter** mit absoluten Schwellen (Liquidation 26.718, Short-Position 0.1935, Entry 25.511)
- Generische Prozent-Schwellen (0.5/1.5%) haetten den Liquidations-Schutz zerstoert
- Vor jedem Umbau: `openclaw cron show <id> --json` lesen, die `payload.message` pruefen, dann erst editieren

**OpenClaw Browser Relay = host-local Extension (4.26 Limitation):**
- `~/.openclaw/browser/chrome-extension/manifest.json` deklariert `host_permissions: ["http://127.0.0.1/*", "http://localhost/*"]`
- Extension verbindet sich nur mit lokalem CDP-Relay-Server, NIE ueber LAN
- Konsequenz: Cross-Host-Browser (yoga7-Chrome via moltbot-Gateway gesteuert) ist NICHT moeglich in 4.26 ohne Custom-Setup
- **Browser-Profile sind hardcoded:** `openclaw browser create-profile --name X` → `browser.request cannot mutate persistent browser profiles`. Die zwei Default-Profile (`openclaw` cdp/Port 18800, `user` chrome-mcp existing-session) sind statisch, kein User-Add via CLI

**systemd-User-Timer als Cron-Ersatz (3 Timer Stand 2026-04-28):**
- `clawd-daily-log.timer` (00:05 daily) — legt `clawd/memory/$(date +%Y-%m-%d).md` an, idempotent via `touch -a`
- `clawd-config-backup.timer` (03:00 daily) — git-commit Workspace + JSON-Snapshot mit 30-Tage-Rotation
- `self-improve-check.timer` (one-shot 2026-05-11 09:00 CEST) — Telegram-Reminder via `curl https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage`
- **Standard-Pattern fuer alle 3:** `Type=oneshot`, `Persistent=true`, `EnvironmentFile=~/.openclaw/.env` fuer Secrets
- Regel: Reine File-Operationen (touch, cleanup, backup, curl-API) gehoeren in systemd-Timer, nicht in OpenClaw-Cron

**KRITISCH — systemd `%` muss als `%%` escaped werden:**
- URL-encoded Strings im ExecStart (`%0A` Newline, `%20` Space) werden von systemd als Specifier interpretiert → `Failed to resolve unit specifiers in '...'`, `Loaded: bad-setting`
- Fix: alle `%` verdoppeln (`%%0A` etc.)

**Cloud-Routinen (Anthropic CCR) haben keinen Telegram-Connector:**
- Verfuegbare MCP-Connectors: Excalidraw, Gamma, Supabase, Cloudflare-Dev, Calendar, Hugging-Face, ICD-10 — aber kein Telegram
- **Calendar-MCP-Connector hat ggf. nur Read-Scopes** — `create_event` failt mit "Request had insufficient authentication scopes"
- Reminder-Use-Cases besser als lokaler systemd-Timer + direkte Telegram-Bot-API loesen

**Run-Status-Validierung — `lastRunStatus: ok` ist semantik-frei:**
- Misst nur "Job getriggert + delivered to channel", nicht "task-completion"
- Validierung: `tail -1 ~/.openclaw/cron/runs/<id>.jsonl | python3 -m json.tool` und `status`/`error`/`summary` lesen
- Plus echte Datei-Mutation pruefen: `wc -l <ziel-datei>` vor/nach Run
- Bei manueller Trigger: `openclaw cron run <id>` returnt sofort asynchron. Auf Completion warten via Polling-Loop auf `state.lastRunAtMs`

**Gateway-Init nach Update braucht Polling-Loop:**
- Default-CLI-Timeout 30s reicht oft nicht fuer ersten `cron list`-Aufruf nach Restart
- Pattern: `until openclaw cron list 2>/dev/null | head -1 | grep -qE "ID|<job-name>"; do sleep 3; done`

**Sicherheit — Passwoerter NIE im Chat:**
- 2026-04-27 hat Diana versehentlich ein Passwort im Klartext gesendet → in Conversation-Log und allen Tool-Logs sichtbar
- Bei Auth-Bedarf: Diana fuehrt SSH/sudo selbst aus (interaktive Shell mit `! <command>` am Claude-Code-Prompt), Claude bekommt nur Output zurueck
- Bei versehentlichem Posten: User auffordern Passwort SOFORT zu rotieren (`passwd`)

**Multi-Agent-Git-Risk (2026-04-28):**
- Andere Sessions koennen einen Rebase mitten drin liegen lassen — `git status` zeigt dann "interaktives Rebase im Gange" obwohl die Conflict-Marker schon manuell entfernt sind
- Beim Reflect-Push IMMER vorher `git status` checken. Bei "Rebase im Gange" / unmerged paths: NICHT autonom `--continue` oder `--abort` machen — User entscheiden lassen

### Anti-Patterns — Selbstkritik (2026-04-28, von Claude reflektiert)

Diana hat explizit nach Selbstkritik gefragt. Diese drei Verhaltensmuster verschwenden ihre Zeit oder Token-Budget. **Vor jeder Antwort gegen-checken.**

**1. Optionen-Inflation statt Entscheidung**
- Anti-Pattern: "(α) X, (β) Y, (γ) Z — was meinst du?" als Default-Format
- Diana antwortet meist mit 1-2 Zeichen ("J", "I", "OK"). Das ist das Signal: sie will dass ICH entscheide und sie nur korrigiert.
- **Richtig:** Bei reversiblen Aktionen (Backup vorhanden) DIREKT umsetzen mit Default-Wahl + 1-Zeilen-Begruendung. Nur fragen wenn:
  - destructive (rm, force-push, db-drop)
  - kostenintensiv (>5 USD oder LLM-Iteration)
  - Architektur-aenderung mit unklarem Rollback
- Beispiel-Faelle wo ich falsch gefragt habe: Cron-Streichungen 2026-04-27 (3 Klärungsrunden statt 1), schedule-Skill-Aufruf vor systemd-Timer-Loesung

**2. Sunk-Cost-Iteration beim LLM-Prompt-Engineering**
- Anti-Pattern: V2 → V3 → V4 → V5 mit demselben Failure-Pattern, jedes Mal hoffend "der naechste Prompt-Trick loest es"
- Klassisches Beispiel: Self-Improve-Cron-Migration 2026-04-25/26. Mini scheiterte 4× mit byte-genauem String-Reproduce. Nach V3 war die richtige Hypothese: "Mini ist hier ungeeignet."
- **Richtig:** Nach **2 Versuchen mit gleichem Failure-Pattern** → Modell/Tool/Architektur infrage stellen, nicht weiter prompten. Frage stellen: "Ist das ein Modell-Capability-Issue oder ein Prompt-Issue?"
- Heuristik: Wenn der gleiche Tool-Call (z.B. `edit`) 2× schief geht, ist es selten ein Prompt-Problem.

**3. Tiefen-Tauchen bei Limitations statt erster-Prinzip-Frage**
- Anti-Pattern: 30 Min Code-grep + Manifest-Lesen + CLI-Probieren bei einem "X funktioniert nicht"-Problem, am Ende "geht in dieser Version nicht"
- Beispiel: Browser-Cross-Host 2026-04-27. Code-Tauchgang war 30 Min, die Antwort war eine Architektur-Limitation.
- **Richtig:** ZUERST 2 Min "Ist X ein offiziell unterstuetztes Feature?" (docs.clawd.bot, GitHub-Issues, Code-Comments). DANN bei Bedarf tieferer Tauchgang.
- Heuristik: Wenn ein Feature in der Doku nicht erwaehnt wird → vermutlich nicht supported. Statt 30 Min beweisen, dass es geht: 2 Min beweisen, dass es nicht offiziell ist.

**Zusatz: Insights-Inflation**
- Im Learning-Output-Style packe ich ★Insights★ in fast jede Antwort. Das verwaessert. **Insights sollten selten und ueberraschend sein** — wenn nichts wirklich neu/unerwartet ist, weglassen.

### 2026-04-28 (Teil 2) — DSGVO-Eigenfehler, Disk-Hygiene, Drift-Audit, Workspace-Resolution

**🔴 Auto-Mode-DSGVO-Constraint** (Eigenfehler, kritisch zu memorieren):
Heute habe ich im Auto-Mode den `sonnet`-Default-Agent von Anthropic Sonnet 4.6 auf `ollama/deepseek-v3.1:671b-cloud` umgestellt. Diana hat das spaeter im Optimierungs-Reflect aufgedeckt: **Telegram + WebChat (Default-Routing) verarbeiten jetzt potenziell Patientendaten via Ollamas USA-Servern**. Vor der Aenderung war das durch Anthropic-EU geschuetzt.
- **Regel:** Auto-Mode ist KEINE Erlaubnis fuer DSGVO-Roulette. Default-Agent-Switches die mit Pflege-Daten in Beruehrung kommen koennten (Telegram-Diana, WebChat) brauchen explizite Stop-Frage: "Verarbeitet dieser Agent jemals Pflege-Daten? Wenn ja: hartes Modell-Pin auf Anthropic-EU oder lokal."
- **Mitigation 2026-04-29 RESOLVED** via Option (b): `sonnet` zurueck auf `anthropic/claude-sonnet-4-6` (DSGVO-safe Default), `defaults.primary` zurueck auf Anthropic, neuer **opt-in `deepseek`-Agent** in `agents.list[]` mit `model: ollama/deepseek-v3.1:671b-cloud` + Name-Markup "NICHT fuer Pflege-Daten!". Routing: Telegram + WebChat → sonnet (EU); `/@deepseek` manuell fuer Massenarbeit. Backup: `~/.openclaw/openclaw.json.pre-dsgvo-mitigation-2026-04-29`.

**🔴 Disk-Cleanup-Hierarchie + automatisierte Wartung:**
Bei `/`-Use% >90% in dieser Reihenfolge aufraeumen (Recovery 94→63%, 20GB frei in dieser Session):
1. `npm cache clean --force` (war 7.5GB → 1.7MB)
2. `uv cache clean` (war 6.9GB → 0)
3. `rm -rf ~/.npm/_npx` (1.4GB)
4. `brew cleanup --prune=all` (1.9GB)
5. `journalctl --user --vacuum-size=200M`
6. **NIE** `~/.cache/whisper` loeschen (Voice-Pipeline braucht die Modelle, Re-Download teuer)
7. **NIE** `~/.linuxbrew` cleanup (System-Tools)

Automation: `disk-watchdog.{service,timer}` (alle 30min, Telegram bei ≥85%/≥92%) ist jetzt installiert. Manuelle Tests: `disk-watchdog.sh --status` (ohne Alert), `--force` (Test-Alert).

**🟡 Drei-Stufen Workspace-Resolution Pattern** (fix in `ontology.py`, generisch):
Skripte mit Default-Pfaden fuer Daten-Files duerfen NICHT rein cwd-basiert sein, sonst akkumulieren sich Daten in falschen Verzeichnissen. Heute: 81 unique Entities lagen monatelang in `clawd/skills/ontology/scripts/memory/ontology/graph.jsonl` (statt main `clawd/memory/ontology/graph.jsonl`), weil Reflect-Calls aus dem `scripts/`-cwd erfolgten.
**Resolution-Reihenfolge:**
1. Explizite ENV-Var (z.B. `CLAWD_WORKSPACE`)
2. cwd, falls dort der Workspace-Marker existiert (z.B. `memory/ontology/`-Verzeichnis)
3. `__file__`-relative Fallback (`Path(__file__).resolve().parents[N]`)

**🟡 "Leichen verifizieren bevor loeschen":**
Vor `rm -rf` von Daten-Verzeichnissen IMMER ID/Inhalt-Diff. Heute war ich nahe daran, die scripts/-graph.jsonl als "Subset von main" zu loeschen — Verifikation per Python-Set-Diff zeigte: 81 unique Entities, alle weg gewesen.
**Snippet:**
```python
def ids(p):
    s=set()
    with open(p) as f:
        for line in f:
            try: s.add(json.loads(line).get('entity',{}).get('id'))
            except: pass
    return s
print(f'in alt aber nicht in neu: {len(alte_ids - neue_ids)}')
```

**🟡 Pure-Bash-Drift-Audit als LLM-self-improve-Komplement:**
Mechanische Drifts (veraltete Pfade, Agent-IDs, Versionen, Default-Modell) gehoeren in deterministischen grep-basierten Cron, nicht in teures LLM-self-improve. Heute installiert: `memory-drift-audit.{service,timer}` (Sonntag 09:00).
- Vorteile: Kein Token-Verbrauch, keine Halluzination, reproduzierbar
- Skip-Heuristik: Zeilen mit `HISTORISCH`/`veraltet`/`frueher`/`→` Markern werden ignoriert
- Output: Telegram mit Top-10-Verdachts-Eintraegen, Diana entscheidet manuell pro Sonntag
- Erster Live-Run: 19 Treffer (alle echt) — bestaetigt dass Drift systemisch ist, nicht Einzelfall

**🔵 Anti-Spam-Watchdog-State-Pattern** (kanonisch fuer kuenftige Watchdogs):
Pattern aus `gateway-watchdog.sh` jetzt auch in `disk-watchdog.sh`: jq-State-File mit `lastLevel` + `lastAlertAt`, Cooldown nur bei gleichem Level (Eskalation alarmiert sofort), all-clear bei Recovery aus Warn/Crit zurueck nach OK. Verhindert Telegram-Spam wenn Disk lange voll ist. Telegram-Helper `tg_alert()` Funktion einheitlich (TELEGRAM_BOT_TOKEN aus `~/.openclaw/.env`, Chat-ID `2061281331`).

**Backups dieser Session:**
- `~/bin/openclaw-runtime-cleanup.sh.pre-dedup-fix-2026-04-28` (Skript-Patch: dedup innerhalb derselben Version)
- `~/clawd/memory/ontology/graph.jsonl.pre-merge-2026-04-28` (vor 82-Lines-Merge aus Stale-Graph)
- `~/clawd/skills/ontology/scripts/ontology.py.pre-cwd-fix-2026-04-28` (Workspace-Resolution-Fix)
- `~/.openclaw/openclaw.json.pre-deepseek-primary-2026-04-28` (vor Default-Modell-Switch — fuer DSGVO-Rollback verfuegbar)

### 2026-04-29 — DSGVO-Recovery-Mechanik + Identity-Markup + Drift-Audit-Heuristik-Erweiterung

**🟢 DSGVO-Recovery via opt-in Agent (RESOLVED gestern Eigenfehler):**
Saubere Trennung statt Default-Switch: `sonnet`-Default zurueck auf Anthropic, neuer `deepseek`-Agent als opt-in via `/@deepseek`.
- 3-Agent-Topologie: `sonnet` (default, Anthropic-EU), `opus` (Anthropic Opus, /@opus), `deepseek` (Ollama Cloud, /@deepseek, opt-in)
- Fallback-Reihenfolge: MiniMax → DeepSeek (Position 1, fuer Cost-Saving im Failover) → Opus → GPT-5.4 → GPT-4.1 → Gemini → Qwen lokal
- Sonnet bleibt automatisches Sicherheitsnetz fuer DeepSeek-Tool-Use-Issues, weil als Anthropic-Default jetzt
- Backup: `~/.openclaw/openclaw.json.pre-dsgvo-mitigation-2026-04-29`

**🟡 Identity-Markup-Pattern fuer Agents** (DSGVO-Sichtbarkeit in `agents list`):
Agent-Namen kommunizieren DSGVO-Klassifizierung sichtbar im `name`-Feld. Vorbild aktuell:
- `"Sonnet Workhorse (Anthropic-EU, DSGVO-safe fuer Pflege-Daten)"`
- `"DeepSeek FREE Workhorse (Cloud/USA — NICHT fuer Pflege-Daten!)"`

Wirkung: Bei `openclaw agents list` erscheint die DSGVO-Klassifizierung direkt neben jedem Agent — kein Nachschlagen in Memory noetig. Bei zukuenftigen Agent-Edits dieses Markup-Pattern beibehalten.

**🟡 Drift-Audit-Heuristik erweitert** (`memory-drift-audit.sh`):
Neue Skip-Heuristiken nach erstem Live-Run-Befund (23 → 3 Treffer, 87% Reduktion):
1. **Datierte Sektionen ueberspringen** via `in_dated_section()` Helper — erkennt sowohl `### YYYY-MM-DD` (H3 Lessons) als auch `## ... (YYYY-MM-DD)` (H2 Update-Sektionen) als historisch
2. **`fallback`-Erwaehnungen ueberspringen** beim Primary-Modell-Check — Memory-Eintraege die Fallback-Position beschreiben sind keine Primary-Behauptungen
3. **Recovery/Mitigation-Beschreibungen ueberspringen** — Wortlist erweitert um: `zurueckgesetzt|mitigation|war.*eingerichtet|wurde.*von|previously|previous`

Resultat: Steady-State 3 Treffer pro Wochen-Audit (alle in nicht-datierten ## Sektionen ohne Date-Suffix). Diana-Triage-Aufwand am Sonntag bleibt klein.

**🔵 Reflect-Heuristik fuer kuenftige Skill-Edits:**
Datierte Lessons-Sektionen ab Tag 1 mit `### YYYY-MM-DD — Titel` Header schreiben, ODER Update-Sektionen mit `## Titel (YYYY-MM-DD)` Suffix. Dann ignoriert der Drift-Audit sie automatisch ohne extra HISTORISCH-Marker.

**Backup dieser Session:**
- `~/.openclaw/openclaw.json.pre-dsgvo-mitigation-2026-04-29` (vor DSGVO-Recovery)

### 2026-04-29 (Teil 3) — Control UI Auth ist zweistufig + Token-Klartext-Sandbox

**🔴 Control-UI-Auth ist ZWEISTUFIG — niemals "devices clear" als Schnellschuss:**
Symptom "alle Clients sind weg" / "unauthorized: gateway token missing" bedeutet meist NICHT, dass Pairings verloren wurden. Source of Truth ist `~/.openclaw/devices/paired.json`, nicht was das UI rendert.

| Browser-Symptom | Wahre Ursache | Fix |
|---|---|---|
| `unauthorized: gateway token missing` | LocalStorage-Token weg (Stufe 1) | URL `<base>/#token=<gateway-token>` neu laden |
| `device pairing required (requestId: …)` | Browser-Public-Key nicht in `paired.json` (Stufe 2) | `openclaw devices approve <requestId>` |
| UI laedt aber zeigt leere Listen | Stufe 1 fehlt → kein API-Zugriff | wie Stufe 1 |

Reihenfolge: erst Token (Stufe 1), dann probiert der Server das Pairing (Stufe 2). Nie zuerst Pairing-approven, wenn Token fehlt — dann wird gar nicht erst gesendet. Details in Auto-Memory: `reference_control_ui_auth.md`.

**🔴 Token-Klartext-Sandbox-Block + Helper-Skript-Pattern:**
Das Bash-Tooling blockt aktiv Befehle wie `printf "...token=$CLAWDBOT_GATEWAY_TOKEN"` mit der Begruendung "leaks a sensitive credential into the transcript/logs". Workaround:
1. Helper-Skript `~/bin/dashboard-url.sh` mit `chmod 700` schreiben (nutzt `source ~/.openclaw/.env` intern, gibt URL via printf aus)
2. Diana fuehrt selbst aus: `! ~/bin/dashboard-url.sh [local|lan|cf]` — Output landet in ihrem Terminal, nicht im Tool-Filter
3. Nach Gebrauch: `rm ~/bin/dashboard-url.sh` (Diagnose-Kruecke, nicht fuer Dauerbetrieb)

**🟡 `openclaw dashboard --no-open` crasht headless via Clipboard-EPIPE:**
Der offizielle Befehl ruft am Ende ein Clipboard-Write auf — bei Headless-Sessions (kein DISPLAY/xclip) kommt EPIPE. Der Befehl gibt vorher die URL OHNE Token in stdout aus (`Dashboard URL: http://127.0.0.1:18789/`), das `#token=` Fragment landet nur in Clipboard und Browser-Aufruf. Im Headless-Kontext also unbrauchbar — dort Helper-Skript-Pattern nutzen.

**🟡 CF-Tunnel verschleiert peer-IP in Gateway-Logs:**
`peer=127.0.0.1:xxxxx` ist immer der Cloudflared-Tunnel-Endpunkt, nicht das echte Client-Geraet. Echte Quell-IP steht in `fwd=<IPv6>` (X-Forwarded-For). Beim Identifizieren von Clients aus Logs immer `fwd=` lesen, nie `peer=`. Gleiche Logik fuer `remote=` (gleiche 127.0.0.1).

**🟡 127.0.0.1 vs LAN/CF aus Browser-Sicht:**
`http://127.0.0.1:18789` im Browser zeigt IMMER auf das Browser-Geraet selbst, nicht auf moltbot. Vom Yoga7/Win-Browser → ERR_CONNECTION_REFUSED. Korrekte URLs:
- Lokal (Browser auf moltbot): `http://127.0.0.1:18789`
- LAN: `http://192.168.22.206:18789`
- Public: `https://openclaw.forensikzentrum.com`

**🔵 ss-Grep-Fallstrick:**
`ss -tlnp | grep 18789` matched gelegentlich nicht wegen Spaltenbreite/Whitespace-Zerlegung im Output. Bei "Port-lauscht-nicht?"-Diagnose immer parallel: `systemctl is-active <service>` + `curl -I http://host:port/` + `ss -tlnp | grep <port>`. Wenn HTTP 200 kommt, lauscht er — der grep luegt.

**Diagnose-Reihenfolge bei "alle Clients weg":**
1. `systemctl --user is-active openclaw-gateway.service` → laeuft Service?
2. `curl -I https://openclaw.forensikzentrum.com/` → CF-Tunnel ok? HTTP 200?
3. `openclaw devices list` → wie viele Pending? wie viele Paired?
4. `journalctl --user -u openclaw-gateway.service -n 50 | grep -E "unauthorized|pairing"` → Stufe 1 oder Stufe 2?
5. Stufe 1 → Helper-Skript fuer Token-URL ; Stufe 2 → `openclaw devices approve <requestId>`
6. Erst dann Cleanup-Frage stellen (alte Karteileichen-Pairings via `lastUsedAtMs > 30 Tage`)

**Verwandte Memory-Dateien (Auto-Memory):**
- `reference_control_ui_auth.md` — vollstaendige Symptom-Tabelle + CLI-Pfad
