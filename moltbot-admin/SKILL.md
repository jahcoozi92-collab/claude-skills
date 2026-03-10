# Skill: moltbot-admin

| name | description |
|------|-------------|
| moltbot-admin | Verwaltung der moltbot VM-Instanz (192.168.22.206): CLAUDE.md, Architektur-Locks, Agent-Guardrails, System-Hardening. Nicht fuer NAS, Yoga7 oder andere Maschinen. |

## Scope — NUR moltbot VM

Diese Skill gilt **ausschliesslich** fuer:
- **Host:** ugreen-gateway / moltbot (Debian 13, 192.168.22.206)
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
| `~/.clawdbot/.env` | Secrets (chmod 600) |
| `~/.claude/settings.local.json` | Claude Code Permissions |
| `~/.claude/projects/-home-moltbotadmin/memory/MEMORY.md` | Auto-Memory |

**Rebrand-Mapping (clawdbot → openclaw):**
| Alt | Neu |
|-----|-----|
| `~/.clawdbot/` | `~/.openclaw/` (Symlink, gleicher Ordner) |
| `clawdbot.json` | `openclaw.json` |
| `clawdbot-gateway.service` | `openclaw-gateway.service` |
| `CLAWDBOT_*` env vars | `OPENCLAW_*` (legacy vars werden ignoriert mit Warnung) |

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

**Regel: Keine API-Keys in `openclaw.json` oder `clawdbot.json`!** Alle Secrets gehoeren in `~/.openclaw/.env` (chmod 600).

**⚠ REGRESSION (Stand 2026-03-10):** `openclaw.json` hat noch Plaintext-API-Keys (OpenRouter, Telegram Bot-Token, GitHub PAT, Gateway/Hooks-Tokens, Skill-Keys). Die Secrets-Migration wurde nur fuer `clawdbot.json` durchgefuehrt — `openclaw.json` muss noch migriert werden!

OpenClaw kennt drei Secret-Mechanismen:

| Mechanismus | Wann nutzen | Beispiel |
|-------------|-------------|---------|
| **Auto-Fill** | Provider-Keys, Channel-Tokens | `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN` — einfach Feld weglassen |
| **`${VAR}` Interpolation** | Gateway-Token, Hooks, Skills | `"token": "${CLAWDBOT_GATEWAY_TOKEN}"` |
| **`env.vars` Block** | Sonderfaelle | Setzt env vars beim Config-Laden |

**Auto-Fill Env-Variablen (kein Feld in JSON noetig):**
`OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENAI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `DISCORD_BOT_TOKEN`, `CLAWDBOT_GATEWAY_TOKEN`

---

## Config-Optimierung Checkliste

### Level 1 — Sicherheit & Korrektheit
- [ ] Alle Secrets in `.env` ausgelagert (keine Klartext-Keys in JSON)
- [ ] `.env` hat `chmod 600`
- [ ] Model-Parameter stimmen mit Intention ueberein (thinking, maxTokens)
- [ ] Tote Eintraege entfernt (leere Objekte, deaktivierte Plugins, unreferenzierte Modelle)
- [ ] `plugins.allow` hat keinen Leerstring

### Level 2 — UX & Performance
- [ ] `typingMode: "instant"` — sofortiger Typing-Indicator
- [ ] `ackReaction` + `removeAckAfterReply` — visuelles Feedback
- [ ] `queue.mode: "collect"` + `debounceMs: 1500` — Schnellnachrichten buendeln
- [ ] `session.reset.mode: "idle"` + `idleMinutes` — stale Sessions vermeiden
- [ ] `userTimezone` + `timeFormat: "24"` — Zeitbewusstsein
- [ ] Fallback-Kette: guenstigstes Modell zuerst (Gemini Free vor Opus $75/M)
- [ ] `contextPruning.keepLastAssistants: 3` — schuetzt letzte Antworten
- [ ] `heartbeat.activeHours` — nur waehrend Wachzeiten
- [ ] Telegram: `linkPreview: false`, `markdown.tables: "code"`, `dmHistoryLimit: 50`

### Level 3 — Features
- [ ] TTS: `messages.tts.auto: "inbound"` + Edge TTS (kostenlos, kein API-Key)
- [ ] Deutsche Stimmen: `de-DE-FlorianMultilingualNeural` (multilingual) oder `de-DE-KatjaNeural`

---

## Gateway-Schnellreferenz

```bash
systemctl --user restart openclaw-gateway.service
systemctl --user status openclaw-gateway.service
journalctl --user -u openclaw-gateway.service -f
openclaw doctor
```

### Gateway Build-from-Source (aktueller Zustand)

Der Gateway laeuft auf einem **lokalen Build** statt dem npm-Paket, weil die npm-Version eine pnpm-Inkompatibilitaet hat.

| Parameter | Wert |
|-----------|------|
| ExecStart | `/usr/bin/node ~/clawdbot-src/dist/entry.js gateway --port 18789` |
| bind | `"lan"` (in openclaw.json, nicht als CLI-Flag) |
| `OPENCLAW_BUNDLED_PLUGINS_DIR` | `/home/moltbotadmin/clawdbot-src/extensions` |
| `plugins.load.paths` (openclaw.json) | `["/home/moltbotadmin/clawdbot-src/extensions"]` |

**Nach `pnpm install` oder Version-Update:** `cd ~/clawdbot-src && pnpm build` ausfuehren, dann Gateway neu starten.

**`--bind` Werte (v2026.3.3+):** `loopback`, `lan`, `tailnet`, `auto`, `custom` (keine IP-Adressen mehr)

### Model-Aliases (`~/.clawdbot-model-aliases.sh`)

Schnelles Model-Switching per Shell-Funktion. Wird in `.bashrc` gesourced.

**WICHTIG:** Kein `clawdbot`/`openclaw` Binary im PATH — Aliases nutzen:
```bash
OPENCLAW_CLI="/usr/bin/node /home/moltbotadmin/clawdbot-src/dist/entry.js"
```

| Alias | Modell | Kosten |
|-------|--------|--------|
| `clawdbot-use-free` | Gemini 2.0 Flash | FREE |
| `clawdbot-use-cheap` | DeepSeek V3.2 | $0.25/$0.38 |
| `clawdbot-use-gpt` | GPT-5.4 (OpenAI) | $$ |
| `clawdbot-use-balanced` | Sonnet 4 | $3/$15 |
| `clawdbot-use-premium` | Opus 4.6 | $15/$75 |

**OpenAI-Modelle (Built-in Provider):**
- `openai/gpt-5.4` — 1M+ Kontext, 128K Output, Reasoning, Text+Bild
- `openai/gpt-5.4-pro` — Premium mit xhigh Thinking
- API-Key per Auto-Fill aus `OPENAI_API_KEY` (in `~/.openclaw/.env`)

### Troubleshooting

**502 von Cloudflare:**
1. `systemctl --user status openclaw-gateway.service` — laeuft der Service?
2. `curl -sI http://127.0.0.1:18789/` — antwortet der Gateway lokal?
3. `pgrep -af cloudflared` — laeuft der Tunnel? (System-Service, PID ~836)

**"unsafe plugin manifest path" Crash-Loop:**
- Ursache: pnpm Content-Addressable-Store nutzt Hardlinks, die die Boundary-Pruefung (`openBoundaryFileSync`) nicht bestehen
- Fix: `OPENCLAW_BUNDLED_PLUGINS_DIR` in der systemd-Unit auf `~/clawdbot-src/extensions` setzen
- Alternativ: `plugins.load.paths` in `openclaw.json` auf das Extensions-Verzeichnis zeigen lassen

**"Unrecognized key: path" in plugins.entries:**
- `plugins.entries.*.path` wurde in v2026.3+ entfernt
- Stattdessen: `plugins.load.paths` als globales Array nutzen
- Falls vorhanden: manuell entfernen (doctor --fix kann fehlschlagen wenn andere Validierungsfehler vorliegen)

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
- Stimme: `de-DE-FlorianMultilingualNeural` (gut fuer gemischte DE/EN-Texte)
- Voice-Samples generieren: `cd ~/clawdbot-src && node /tmp/voice-test.mjs`

**Preis-Korrektur:**
- DeepSeek V3.2 kostet $0.25/$0.38 pro 1M Tokens (nicht $0.14/$0.28 wie vorher notiert)

**Systemd-Hinweis:**
- Service-Datei hat noch hardcodierte API-Keys — werden durch `.env` ueberdeckt
- Beim naechsten `clawdbot wizard` Run sollten die bereinigt werden

### 2026-02-25 — CLAUDE.md /init Verbesserung

**Hostname:**
- Tatsaechlicher Hostname ist `ugreen-gateway` (nicht `moltbot`) — in CLAUDE.md und Skill korrigiert
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

**CLI-Workaround:**
- `openclaw` Binary nicht verfuegbar (dist/ nicht gebaut, kein globales npm-Paket)
- Cron-Jobs direkt in `~/.openclaw/cron/jobs.json` editieren statt `openclaw cron add` CLI
- Gateway muss nach Config-Aenderungen neu gestartet werden

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
