# Skill: yoga7-admin

| name | description |
|------|-------------|
| yoga7-admin | Verwaltung der Yoga7-Instanz (Dianas Laptop): CLAUDE.md, Architektur-Locks, lokale Entwicklungsumgebung. Nicht fuer NAS oder Clawbot VM. |

## Scope — NUR Yoga7

Diese Skill gilt **ausschliesslich** fuer:
- **Host:** Yoga7 (Dianas Laptop)
- **User:** yoga7 (oder aktueller User)
- **Zweck:** Primaere Entwicklungsmaschine, Claude Code, Skills-Verwaltung

**Nicht** fuer:
- NAS DXP4800PLUS-30E (192.168.22.90, User: Jahcoozi)
- Clawbot VM (192.168.22.206, User: moltbotadmin)
- exe.dev VMs

---

## Verwaltete Dateien

### Geschuetzte Dateien
| Datei | Schutz | Zweck |
|-------|--------|-------|
| ~/CLAUDE.md | chattr +i (immutable) | System-Router fuer Claude Code |
| ~/architecture/ARCHITECTURE_LOCK.md | — | Architektur-Constraints |

### Konfiguration
| Datei | Zweck |
|-------|-------|
| ~/.claude/settings.local.json | Claude Code Permissions |
| ~/.claude/skills/ | Skill Repository (git: jahcoozi92-collab/claude-skills) |

---

## Abgrenzung zu anderen Instanzen

| Skill | Maschine | IP |
|-------|----------|-----|
| yoga7-admin (dieser) | Yoga7 Laptop | 192.168.22.86 |
| clawdbot-admin | Clawbot VM | 192.168.22.206 |
| nas-instance | NAS DXP4800 | 192.168.22.90 |

---

## Schutz-Operationen

**WICHTIG:** Claude kann kein `sudo` ausfuehren — User muss chattr-Befehle immer manuell im Terminal laufen lassen. Anleitung immer mit vollem Dateipfad angeben (User vergisst sonst den Pfad).

### CLAUDE.md schuetzen
```bash
sudo chattr +i ~/CLAUDE.md
```

### Schutz pruefen
```bash
lsattr ~/CLAUDE.md
# Erwartete Ausgabe: ----i---------e------- (i = immutable)
```

### Entsperren (fuer Updates)
```bash
sudo chattr -i ~/CLAUDE.md
# → Aenderungen vornehmen →
sudo chattr +i ~/CLAUDE.md
```

---

## Terminal-Eigenheiten

**KRITISCH:** Das Yoga7-Terminal bricht Zeilen >80 Zeichen um und zerstoert dabei Befehle!
- Betrifft: Shell-Einzeiler, fstab-Eintraege, heredocs, UND nano (!)
- **Sofort** zu Script-Dateien eskalieren statt lange Einzeiler zu versuchen
- Variablen-Trick: `H=user@host` + `sshfs $H:/path /mnt` statt alles in eine Zeile
- Heredoc-Terminatoren (`EOF`, `S`) muessen am Zeilenanfang stehen (ohne Leerzeichen)

**SSHFS niemals mit sudo mounten** — sudo nutzt root's SSH-Keys, nicht die des Users.
Immer als User mounten (fstab: `user`-Option, oder `mount` ohne sudo).

---

## Remote-Mounts

### moltbot VM (SSHFS)
| Was | Pfad/Wert |
|-----|-----------|
| Mountpoint | `~/moltbot-remote` |
| Remote | `moltbotadmin@192.168.22.206:/home/moltbotadmin` |
| Script | `~/mount-moltbot.sh` |
| Service | `~/.config/systemd/user/moltbot-sshfs.service` (enabled) |
| Steuerung | `systemctl --user start/stop/restart moltbot-sshfs` |

**Use Case:** Claude Code mit `/voice` auf Yoga7 laufen lassen und gleichzeitig moltbot-Dateien bearbeiten (`cd ~/moltbot-remote && claude`).

**Hinweis:** `/voice` funktioniert nur auf Geraeten mit Mikrofon — nicht ueber SSH auf headless Server.

---

## System-Cleanup Checkliste (5 Dimensionen)

Bei jeder Bereinigung ALLE 5 Dimensionen abarbeiten — nicht nur Speicher:

| # | Dimension | Was prüfen | Level-1-Fehler |
|---|-----------|-----------|----------------|
| 1 | **Speicher** | Caches (uv/pip/npm), site-packages, node_modules (rekursiv!), .cache/*, Shell-Snapshots | Nur offensichtliche Caches, nicht rekursiv |
| 2 | **Performance** | `systemd-analyze blame`, Boot-Bottlenecks, RAM-Fresser (`ps --sort=-%mem`), Error-Loops in journalctl | Komplett ignoriert |
| 3 | **Security** | SSH-Config, offene Ports (`ss -tlnp`), Credentials in Downloads, Key-Permissions, Firewall | Komplett ignoriert |
| 4 | **Services** | `systemctl --failed`, Restart-Loops, doppelte Prozesse, verwaiste Timer | Nur offensichtliche Fehler |
| 5 | **Hygiene** | Broken Symlinks, leere Dirs, Autostart, redundante Scripts, Home-Root Cruft | Oberflächlich |

### Backup-Locations (VOR Neuerstellung prüfen!)
- `~/03_AUTOMATISIERUNG/scripts/` — Backup-Pfad für System-Scripts (forensikzentrum_master.sh etc.)
- `~/scripts/_archive/` — Archiv für redundante Scripts

### pgrep-Patterns
- `pgrep -x` matcht NICHT bei vollqualifizierten Pfaden (`/usr/bin/cloudflared`)
- Korrekt: `pgrep -f "cloudflared tunnel"` für Prozesse mit Argumenten

### sudo-Einschränkung
- Claude Code hat kein sudo ohne Terminal
- Security-Fixes (sshd_config, fail2ban, chattr, dotslash) als Copy-Paste-Befehle ausgeben

---

## Gelernte Lektionen

### 2026-02-08 — Initiale Einrichtung

- Instanz-Skills auf allen drei Maschinen angelegt
- Shared Skills-Repo verhindert Verwechslungen durch klare Scope-Sektionen
- Architecture Locks + chattr +i als Guardrail gegen Agent-Aenderungen

### 2026-02-08 — SSH-Setup & Claude Update

**SSH-Konnektivität:**
- SSH-Key (`id_ed25519`) auf Clawbot VM (.206) eingerichtet
- NAS (.90) hatte bereits SSH-Key-Zugang
- fail2ban ist auf Clawbot VM nicht installiert
- Passwortloser Zugang: `ssh moltbotadmin@192.168.22.206`

**Claude Code Installation:**
- Doppelte Installation bereinigt (npm-global + native)
- Aktive Installation: `/home/yoga7/.npm-global/bin/claude`
- Native Installation entfernt: `/home/yoga7/.local/bin/claude`
- Update-Befehl: `claude update`

**Sync-Befehle (Referenz):**
```bash
# NAS synchronisieren
ssh Jahcoozi@192.168.22.90 'cd ~/.claude/skills && git pull --rebase origin main'

# Clawbot VM synchronisieren
ssh moltbotadmin@192.168.22.206 'cd ~/.claude/skills && git pull --rebase origin main'
```

### 2026-02-26 — CLAUDE.md Pflege

**chattr-Workflow:**
- Claude kann kein `sudo` — User muss chattr immer manuell im Terminal ausfuehren
- Anleitung immer mit vollem Pfad (`~/CLAUDE.md`) angeben, User vergisst sonst den Pfad

**Home-Verzeichnis Hinweise:**
- `docker-compose.yml` im Home ist ein Shell-Script (kein echtes Compose-File) — nicht mit `docker-compose up` ausfuehren
- Docker ist lokal NICHT installiert — n8n laeuft auf NAS (192.168.22.90)
- Python via pyenv (`~/.pyenv/`), nicht System-Python

### 2026-03-14 — Naming-Bereinigung + Workflow-Learnings

**CWD-Löschung blockiert Shell:**
- NIEMALS das aktuelle Arbeitsverzeichnis (`cwd`) löschen während Claude Code darin läuft
- Bash-Tool kann danach nicht mehr starten — keine Workarounds möglich
- Lösung: IMMER zuerst `cd` woanders hin, dann löschen — oder User bitten, Claude neu zu starten

**Edit-Tool nach mv/rename:**
- Nach `mv dir_alt/ dir_neu/` erfordert das Edit-Tool einen erneuten `Read` am NEUEN Pfad
- Der alte Read-Cache (vor dem Rename) gilt nicht — Edit schlägt sonst fehl mit "File has not been read yet"

**Naming-Bereinigung (moltbot → Clawbot VM):**
- Display-Namen und Skill-Namen umbenennen: `moltbot-admin` → `clawdbot-admin`, "moltbot VM" → "Clawbot VM"
- System-Usernames (moltbotadmin, /home/moltbotadmin/) NICHT ändern — das sind echte Credentials auf der VM
- Betroffene Dateien: CLAUDE.md + 5 Skill-Dateien (clawdbot-admin, yoga7-admin, nas-instance, reflect, docker-admin)
- `git pull --rebase origin main` vor Push wenn Remote neuere Commits hat

### 2026-03-19 — Magic Video App Session (59 Commits, 4060 LOC)

**Diana's UI-Präferenzen (KRITISCH):**
- NIEMALS Emojis in App-UIs — Diana hasst das
- JEDER Sub-Screen braucht Zurück-Button — sonst "hängt" die App
- Cleanes Premium-Design bevorzugt (Linear/Raycast Stil)
- Borderradius 10-12px, nicht 24px

**Prompt-Handling (KRITISCH):**
- User-Prompts >100 Zeichen NIEMALS mit Suffix modifizieren
- Kling versteht keine XML-Tags — Prompt-Cleaner entfernt sie
- Zeichenlimit großzügig setzen (500 statt 200) — sonst blockiert Paste
- RN Web TextInput blockt Paste → natives DOM textarea verwenden

**React Native Hooks:**
- useRef/useEffect in FlatList renderItem = "Invalid hook call" Crash
- Hooks nur in Function Components, NIEMALS in Callbacks
- Lösung: Separate Component statt inline renderItem

**Gradle Lock Problem:**
- ~/.gradle/caches Lock blockiert alle Builds
- Fix: `GRADLE_USER_HOME=/tmp/gradle-fresh` für frischen Build
- Oder: `find ~/.gradle -name "*.lock" -delete && pkill -9 gradle`

**fal.ai:**
- Balance läuft regelmäßig leer → 500er "Forbidden" Fehler
- 3x passiert in einer Session
- Backend sollte "Forbidden" als spezifische Meldung weitergeben

**scp auf NAS funktioniert nicht:**
- `scp` gibt "dest open: No such file" obwohl Datei existiert
- Workaround: `cat file | ssh user@host "cat > /path/file"`

### 2026-03-18 — Magic Video App (React Native + NAS Backend)

**Metro Web Kompatibilität (kritisch):**
- Zustand v5 ESM (.mjs) nutzt `import.meta.env` → Metro Web crasht → Custom resolver in metro.config.js nötig
- Firebase v10+ modular SDK nutzt `import.meta` → `firebase/compat/*` verwenden
- NativeWind v4 `className` auf `Text` funktioniert nicht auf Web → Inline Styles
- `Alert.alert` Callbacks auf Web unzuverlässig → `window.confirm` als Fallback
- FlatList `scrollToIndex` auf Web broken → State-basiertes Rendering
- FormData: RN URI-Objekt vs Web Blob → Platform.OS Check

**Android Build:**
- Java 17 nötig für Gradle: `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
- Emulator (Pixel 3a) hat SDK-Image-Probleme — APK direkt bauen: `./gradlew assembleDebug`

**NAS Backend Management:**
- Backend-Pfad: `/home/Jahcoozi/magic-video-backend`
- Port freimachen + starten: `fuser -k 3001/tcp; nohup node dist/main.js >> backend.log 2>&1 &`
- Prisma Migrations: `npx prisma migrate dev --name xyz` oder `npx prisma db push`

### 2026-03-28 — CLAUDE.md Prompting-Standards + Ontology lokal

**Platzierung neuer Always-On Constraints:**
- Neue Blocks thematisch einordnen (Standards neben Standards), nicht einfach am Ende anhängen
- Code Style → Prompting-Standards → Instanzen ist logische Reihenfolge

**Prompting-Methodologie als Always-On:**
- User hat Prompting-Standards (Evaluation Criteria First, Constraint Propagation CoT, Pre-Mortem, Verbote) als Always-On Constraint etabliert
- Diese Methoden gelten skill-übergreifend für alle Aufgaben

**Ontology-Infrastruktur auf Yoga7 eingerichtet:**
- Script: `~/clawd/skills/ontology/scripts/ontology.py`
- Graph: `~/clawd/memory/ontology/graph.jsonl`
- Schema: `~/clawd/memory/ontology/schema.yaml`
- Aufruf: `cd ~/clawd && python3 skills/ontology/scripts/ontology.py [command]`
- Kopiert von Clawbot VM — gleicher Datenstand, läuft jetzt lokal
- Graph hat vorbestehende Validierungsfehler (status "completed" statt "done", Pattern in part_of) — Aufräumen in separater Session

**Proaktiv-Regel:**
- Fehlende Tools/Infrastruktur NICHT überspringen — proaktiv einrichten oder fixen
- User erwartet Eigeninitiative bei Infrastruktur-Lücken

### 2026-03-14 — SSHFS-Mount & Terminal-Breite

**Terminal-Breite-Problem:**
- Yoga7-Terminal bricht bei ~80 Zeichen um — zerstoert Shell-Befehle, fstab, heredocs, sogar nano
- 8+ fehlgeschlagene Versuche bis zur Loesung (Script mit Variablen-Trick)
- Lektion: Sofort zu Script-Datei eskalieren, keine langen Einzeiler probieren

**SSHFS-Setup:**
- `~/moltbot-remote` gemountet via systemd user service (`moltbot-sshfs.service`)
- Zweck: Claude Code mit `/voice` auf Yoga7 + moltbot-Dateien bearbeiten
- `/voice` funktioniert nicht ueber SSH (kein Audio-Forwarding, Server hat kein Mikrofon)

### 2026-04-16 — Claude Code Permissions Best Practices

**Auto-Allowed Commands (kein Allowlist-Entry nötig):**
Folgende Befehle werden von Claude Code AUTOMATISCH erlaubt — niemals in `settings.json` eintragen:
- Always (mit allen Args): `ls`, `cat`, `head`, `tail`, `wc`, `find`, `echo`, `printf`, `true`, `false`, `sleep`, `which`, `type`, `test`, `seq`, `basename`, `dirname`, `realpath`, `cut`, `paste`, `tr`, `id`, `uname`, `free`, `df`, `du`, `diff`, `stat`, `nl`, `cd`, `cal`, `uptime`
- Mit 0 Args: `pwd`, `whoami`, `alias`
- Mit safe flags: `grep`, `sort`, `sed` (read-only), `date`, `hostname`, `lsof`, `pgrep`, `ss`, `ps`, `netstat`, `jq`, `rg`, `tree`, `uniq`, `file`, `xargs`, `sha256sum`
- Alle git read-only subcommands (status, log, diff, show, blame, branch etc.)
- Alle gh read-only subcommands (pr view/list/diff/checks, issue view/list, run view/list, api GET)
- Docker read-only: `docker ps`, `docker images`, `docker logs`, `docker inspect`

**NIEMALS allowlisten (Arbitrary Code Execution):**
- Interpreter: `node:*`, `python3:*`, `bun:*`, `deno:*`, `ruby:*`, `perl:*`, `php:*`, `lua:*`
- Shells: `bash:*`, `sh:*`, `zsh:*`, `eval`, `exec`, `ssh:*` (nur spezifische Hosts!)
- Package Runner: `npx:*`, `bunx:*`, `uvx:*`, `uv run:*`
- Task Wildcards: `npm run *`, `bun run *`, `make *`, `just *`, `cargo run *`
- Stattdessen: exakte Forms (`node -e "..."`) oder enge Prefixes (`npx tsc:*`)

**Pattern-Syntax-Unterschiede:**
| Form | Matcht |
|------|--------|
| `Bash(foo:*)` | Prefix `foo` mit Colon-Separator (z.B. `foo -x`, `foo bar`) |
| `Bash(foo *)` | Prefix `foo ` mit Space — wichtig: Space vor `*` |
| `Bash(foo)` | Exakt `foo` (keine Args) |
| `Bash(foo bar:*)` | Prefix `foo bar` mit Args |

**Workflow `/less-permission-prompts`:**
1. Transcripts: `~/.claude/projects/<sanitized-cwd>/*.jsonl` — 50 neueste per mtime
2. Extract: `message.content[]` mit `type: "tool_use"`, feld `input.command`
3. Filter 1: Drop auto-allowed (siehe Liste oben)
4. Filter 2: Drop non-read-only (`rm`, `pkill`, `kill`, `mkdir`, `mv`, `npm install`, `npm update`)
5. Filter 3: Drop arbitrary code execution (node, python3, npx catch-all)
6. Dedupe: Gegen existierende `settings.json` UND `settings.local.json`
7. Threshold: ≥3 Aufrufe

**Yoga7-Besonderheit (HOME=PROJECT):**
- cwd=`/home/yoga7` ⇒ project-`settings.json` und user-global `~/.claude/settings.json` sind DASSELBE File
- `/less-permission-prompts` landet daher zwangsläufig im globalen File
- Auf normalen Projekten: Ziel wäre `<projektordner>/.claude/settings.json`

**settings.local.json ist Haupt-Allowlist:**
- Aktuell ~287 Einträge — deckt curl:*, systemctl:*, journalctl:*, docker ps:*, npm view * etc. bereits ab
- VOR Ergänzungen zur `settings.json` IMMER `settings.local.json` prüfen, sonst Duplikate
