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
| `~/.clawdbot/clawdbot.json` | Gateway-Runtime-Config |
| `~/.claude/settings.local.json` | Claude Code Permissions |
| `~/.claude/projects/-home-moltbotadmin/memory/MEMORY.md` | Auto-Memory |

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

**WICHTIG:** Claude Code kann `sudo` nicht ausfuehren (kein interaktives Terminal fuer Passwort-Eingabe). Der User muss per SSH selbst entsperren/sperren. Workflow:
1. Claude Code erkennt, dass Edit fehlschlaegt (EPERM)
2. User auffordern: `sudo chattr -i ~/CLAUDE.md` per SSH ausfuehren
3. Nach Bestaetigung: `chmod u+w` → Edits anwenden → User auffordern zu sperren

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

**Regel: Keine API-Keys in `clawdbot.json`!** Alle Secrets gehoeren in `~/.clawdbot/.env` (chmod 600).

Clawdbot kennt drei Secret-Mechanismen:

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
systemctl --user restart clawdbot-gateway.service
systemctl --user status clawdbot-gateway.service
journalctl --user -u clawdbot-gateway.service -f
clawdbot doctor
```

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
