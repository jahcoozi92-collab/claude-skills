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
| Datei | Zweck | Permissions |
|-------|-------|-------------|
| ~/.claude/settings.local.json | Claude Code Permissions | default |
| ~/.claude/skills/ | Skill Repository (git: jahcoozi92-collab/claude-skills) | default |
| ~/.config/homeassistant/env | HA-API: `HA_URL` + `HA_LONG_LIVED_TOKEN` | **0600** (Token!) |
| ~/.config/n8n-mcp/n8n-api-config.sh | n8n API-Key | **0600** (Token!) |
| ~/.config/shelly/credentials | Shelly Cloud Server + Auth-Key (falls genutzt) | **0600** (Token!) |

### Token-Speicher-Konvention
Tokens für externe APIs (HA, n8n, Shelly, etc.) gehören in `~/.config/<service>/env` oder `~/.config/<service>/credentials`, **chmod 600**, source-bar in Bash:
```bash
source ~/.config/homeassistant/env  # setzt HA_URL + HA_LONG_LIVED_TOKEN
```
**Anlegen IMMER via `nano <datei>`**, nie via `printf 'TOKEN=…' > datei` — der Klartext-Token landet sonst in der Shell-History (`~/.zsh_history`) und ist via `Ctrl+R` wieder auffindbar. Nach dem Speichern: `chmod 600 <datei>`.

Wenn ein Token doch in History/Chat/Commit landet: in der jeweiligen Service-UI revoken und neu generieren — der Schaden ist nicht durch Bereinigen rückgängig zu machen.

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

### 2026-04-23 — User-Datei-Pfade nicht über Sessions cachen

**Beobachtung:** PPTX `FEM_Kurzschulung.pptx` lag in einer Session in `~/.local/share/Trash/files/` (aus Papierkorb), in späterer Session aber wiederhergestellt in `~/Downloads/`. Der aus Memory übernommene Trash-Pfad verursachte FileNotFoundError.

**Lektion:** Bei User-gelieferten Datei-Pfaden (Downloads, Desktop, Trash) immer **frisch mit `find`/`Glob` suchen**, statt Pfade aus Session-Memory zu recyceln. Gilt besonders für:
- Downloads-Ordner (Dateien werden verschoben/gelöscht)
- Desktop (regelmäßig aufgeräumt)
- Trash (Dateien werden wiederhergestellt oder endgültig gelöscht)

**Ausnahmen:** Projekt-kanonische Pfade (z.B. `~/Desktop/FEM/` oder `/mnt/nas/docker/X/`) sind stabil genug fürs Caching, weil Benutzer sie bewusst strukturiert hat.

---

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

### 2026-04-19 — Security-Output-Hygiene + Multi-Script-Pattern

**Script-Output NIE blindlings Werte printen (KRITISCH):**
- Debug-Script das ALLE `*api_key*` Felder inkl. Werte dumped → Keys im Chat geleakt (OpenAI, OpenRouter, Mistral, Zhipu)
- Regel: Nur **Feldnamen** printen, NIE die Werte
- Bei Inspection: `print(f"  {key}: {'<set>' if value else '<empty>'}")`
- Bei Credentials in DB: Nur `id` und `name` zeigen, NIEMALS value/secret/token-Feld

**Token-Eingabe ohne Chat-Leak:**
- User soll Token in `~/.openclaw/.env.owui` via `nano` eintragen
- Script liest `source ~/.openclaw/.env.owui; $OWUI_TOKEN` aus
- Nur Laenge + Prefix in Output: `echo "Laenge: ${#TOKEN}, Prefix: ${TOKEN:0:4}..."`
- **NIE** curl-Aufrufe mit `$TOKEN` in der Response echoen

**Terminal-Break-Problem auch auf NAS:**
- Nicht Yoga7-spezifisch — NAS DXP4800PLUS bricht ebenfalls bei Zeilen mit Whitespace-Prefix
- Betroffen: Python-Heredocs, Multi-line curl mit \ line continuation, docker exec mit langen Strings
- Workaround: Script-Dateien statt Einzeiler
- Pattern: Script ins Repo pushen → User macht `git pull && bash ~/.claude/skills/tools/X/Y.sh`

**Multi-Script-Pattern für Docker-Deployments:**
- Wrapper-Script (`.sh`) macht: `docker cp script.py → docker exec python3 /tmp/script.py`
- Python-Script im Container hat Zugriff auf SQLite DB + Python built-in
- sqlite3 CLI fehlt in Open-WebUI Container → `python3 -c "import sqlite3"` nutzen
- Heredoc-Python in Bash vermeiden (Terminal-Break) → separate .py-Datei

**Shared Credentials aus bestehenden n8n-Workflows:**
- OpenAI: `QtmiduKKAgX93kQP` (text-embedding-3-large)
- Supabase: je nach aktuellem Projekt — wird bei 90d Pause stale
- Postgres NAS: `cx83gXjDOqCuXZtm` (persistent)
- Abrufen per API: GET `/api/v1/workflows/{id}` → `nodes[].credentials`
- Auf Credential-IDs referenzieren statt neu anlegen

### 2026-04-22 — 3D-Modellierung aus Grundrissen + Fotos (Blender + bpy)

**Foto > Plan bei Konflikten (KRITISCH):**
- Handgezeichnete Grundrisse allein reichen NICHT fuer 1:1 Rekonstruktion
- Pruefe IMMER ob Originalfotos (Straße/Garten/Dach) vorhanden sind, bevor du Annahmen triffst
- Bei Widerspruch Plan vs. Foto: Foto gewinnt (reale Aenderungen waehrend Bauzeit)
- Beispiele: Material (Plan = abstrakt, Foto = Klinker/Putz-Mix), Dach-Orientierung, Anbau-Laenge

**Schrittweise + Zwischenvalidierung (Diana-Praeferenz):**
- Diana bevorzugt 1-3 sichtbare Aenderungen pro Turn + Render-Check statt Big-Bang-Umbau
- Bei "vollumfaenglich" Anfrage: Top 10 Punkte priorisieren, nicht alles auf einmal
- Pattern: Nummerierte Schritte (Schritt 1, 2, 3...) damit User gezielt validieren/korrigieren kann
- Nach jedem Schritt: kurz berichten was geaendert wurde, dann naechster Schritt vorschlagen

**Praezise Maße aus Plaenen ablesen (nicht runden):**
- Toleranz von 30cm kann sichtbar falsch werden (9.58 ≠ 9.28, 4.49 ≠ 4.78)
- Bei kleiner Schrift: PIL-Crop in `/tmp/` erstellen, dann mit Read-Tool anzeigen
- Crop-Strategie: Bild in 4 Quadranten (Top/Bottom/Left/Right) schneiden
- Wichtige Maße notieren: Hausbreite, Wandstaerke, Geschosshoehen, Fenster-/Tuerbreiten

**Blender UV-Unwrap fuer Brick-Texturen:**
- `Generated` oder `Object` Koordinaten → vertikale Streifen statt Mauerwerk
- Loesung: `bpy.ops.uv.smart_project(angle_limit=66)` + `tc.outputs["UV"]` nutzen
- Mapping Scale ~4.0, Brick Scale ~12 ergibt ~50 Ziegel pro UV-Quadrat
- Alternative fuer Klinker: Noise-Textur mit ColorRamp (3 Stops: anthrazit → rotbraun → hellorange)

**Filmic reduziert Farbsaettigung:**
- Cycles + Filmic View Transform entsaettigt Materialien deutlich
- Klinker/Dachziegel im Material-Slot SATTER anlegen als fotorealistisch gewuenscht
- Basis-Farbe z.B. (0.45, 0.22, 0.16) statt (0.35, 0.18, 0.13)

**bpy-Helper-Muster:**
- `add_cube(name, loc, size)` wrapper mit transform_apply fuer skaliertes Mesh
- `boolean_diff(target, cutter)` fuer Fenster/Tuer-Aussparungen
- `uv_unwrap(obj)` nach `add_cube` fuer saubere Textur-Mapping
- Cutter IMMER `transform_apply` vor boolean_diff aufrufen, sonst Skalierung ignoriert

**Chain-of-Density S0→S4 Pattern fuer iterative Modellierung:**
- S0: Grobe Kubatur (Haus als Quader)
- S1: Beleuchtung + Basis-Materialien (Sonnenwinkel, Putz/Klinker)
- S2: Architektur-Details (Fensterrahmen, Schornstein, Dachueberstand)
- S3: Umgebung (Vegetation, Gehweg, Nachbarn)
- S4: Innenausbau (Aushoehlung, Etagen, Treppen)
- Pattern gut kombinierbar mit Qualitaets-Pruefer + RICE-Scoring vorab

**Kamera-Konstellation fuer Aussenansichten:**
- Target-Empty als Track-To Ziel (statt Rotations-Winkel raten)
- cam_strasse: (0, -22, 6), lens 35-45mm (frontal)
- cam_garten: leicht schraeg mit Offset X=8-14 (nicht frontal wegen Vegetation)
- cam_seite: X=20-26, lens 32-40mm, mit Option Nachbar_L/R ausblenden
- cam_axo: hoch oben schraeg (14, -18, 14), lens 35mm fuer Uebersicht
- Vegetation AM RAND platzieren (x=±8), nicht zentral zwischen Kamera und Haus

### 2026-04-23 — Blender-Session Fortsetzung (Detail-Lektionen)

**Kontext-Elemente dezent halten (KRITISCH):**
- Abgrenzungen wie vertikale Trennfugen zwischen Haeusern koennen das Hauptobjekt verdecken
- Regel: Material-Kontrast zwischen Nachbarn + kleines Gap (10cm) reicht
- NIEMALS dunkle Fugen ueber volle Haushoehe, die wirken wie Gefaengnis-Gitter
- Signal "durch die Abtrennungen sieht man das Objekt nicht mehr" → sofort entfernen

**Sichtbarkeit durch Ueberdimensionierung:**
- Kleine Details wie Vordaecher, Briefkaesten verschwinden im Cycles+Filmic-Rendering
- Vordach: mindestens 1.3x Tuerbreite + 1.1-1.4m Auskragung + sichtbarer Rand (5-15% dunkler)
- Briefkasten: mindestens 0.40 × 0.55m pro Einheit
- Im Zweifel: in Dimensionen groesser anlegen als real, dann schrittweise reduzieren

**Sichtblocker per-Render ausblenden:**
- Nachbargebaeude blockieren Garten-/Seitenperspektive
- Muster: `for obj in bpy.data.objects: if obj.name.startswith("Nachbar"): obj.hide_render = hide_nb`
- `startswith("Nachbar")` faengt auch abgeleitete Kinder (Glas-Fenster, Daecher)
- Renders als Tupel: `(camera, filename, hide_neighbors)` fuer saubere Per-Camera-Logik

**Fenster vs. Tuer unterscheiden (Foto-Lesen):**
- Schmale hohe Oeffnung (0.8-1.0m × 2.0-2.1m) mit Griff = TUER
- Breite rechteckige Oeffnung (1.0-3.0m × 1.3-1.6m) = FENSTER
- Nicht vorschnell als Fenster modellieren — bei Unsicherheit Diana fragen
- Bei Balkontuer: Hochformatig, oft mit Glas-Einsatz

**Material = bauliche Struktur, nicht Fensterglas:**
- "Wintergarten aus Beton" → WAND aus Beton, MIT Fensteraussparungen eingesetzt
- NICHT: alles Glas
- Wintergarten-Typologie: Beton-Brüstung/Waende + eingesetzte Fenster + Acryl-Dach
- Innenwand-Andeutung (Holz-Panelen) sichtbar durch Fenster hindurch → Realismus-Boost

**Tuerfarbe nicht standardisieren:**
- Auch Balkontueren koennen weiss sein (nicht alle Tueren = schwarz-modern)
- `farbe_weiss` Parameter in tuer() einbauen statt globales Material
- Pattern: `tb.data.materials.append(mat_tuer_weiss if farbe_weiss else mat_tuer)`

**Material-Trennung fuer zweifarbige Fassaden:**
- EG-Rueckwand weisser Putz + OG/DG Klinker → separate Objekte (eg_rueck als Putz-Vorsatz)
- Putz-Vorsatz dünn (0.04m) vor Klinker-EG positionieren
- Fenster-Booleans auf das Putz-Objekt anwenden (nicht auf EG-Klinker)

**bpy 8-Vertex Trapez-Prisma:**
- Fuer Wintergarten-Seitenwaende (unterschiedliche Hoehe vorn/hinten)
- 8 Vertices (4 aussen + 4 innen, 0.12m Wanddicke)
- 6 Faces (Aussen, Innen, Oben, Unten, Vorne, Hinten)
- Face-Orientierung abhaengig von xs (links/rechts) — bei xs>0 und xs<0 unterschiedlich
- Ohne korrekte Orientierung: Normals zeigen falsch, Material sieht schwarz aus

### 2026-04-23 — !-Prefix Terminal-Break + claude-cowork-linux Install

**!-Prefix + sudo + langer Pfad = doppelter Terminal-Break (KRITISCH):**
- Bekanntes Yoga7-Terminal-Problem (>80 Zeichen Bruch) trifft auch Claude Code `!`-Prefix-Befehle
- Session-Beispiel: `! sudo ln -s /home/yoga7/.config/Claude/local-agent-mode-sessions/sessions /sessions` wurde ZWEIMAL in Folge zerstört
  - 1. Versuch: `/sessions` landete auf neuer Zeile → als separates Kommando ausgeführt → "datei oder Verzeichnis nicht gefunden"
  - 2. Versuch: Pfad falsch zusammengefügt → falscher Symlink in `~/sessions` (statt `/sessions`) angelegt
- Regeln für `!`-Prefix-Befehle:
  - **<60 Zeichen** halten (Platz für Prompt + Umbruch lassen)
  - `$HOME` immer expandieren (`/home/yoga7/...` statt `$HOME/...`)
  - Bei >60 Zeichen: Script-Datei erzeugen, User ruft `bash ~/tmp/cmd.sh` auf
  - Nach jedem `!`-Kdo Verifizierung via Bash-Tool (`ls -la <ziel>`)

**claude-cowork-linux Install-Rezept:**
- Repo: `github.com/johnzfitch/claude-cowork-linux`
- Prereqs (via npm): `npm install -g @electron/asar electron`
- Root-Symlink (einmalig, sudo):
  ```bash
  sudo ln -s /home/yoga7/.config/Claude/local-agent-mode-sessions/sessions /sessions
  ```
- Install: `./install.sh` lädt DMG (~285 MB), extrahiert app.asar, appliziert Cowork-Patch
- Launcher: `~/.local/bin/claude-desktop`, `~/.local/bin/claude-cowork`
- AUR-Binary in `/usr/bin/claude-desktop` bleibt parallel — PATH-Reihenfolge muss `~/.local/bin` zuerst listen
- CLI wird erkannt wenn `~/.npm-global/bin/claude` existiert
- Doctor vor Install: `./install.sh --doctor` — zeigt fehlende Prereqs/Symlinks ohne Änderungen

**Pre-Clone-Check-Pattern:**
- Vor `git clone <repo>`: prüfen ob Zielverzeichnis schon existiert
- Wenn ja: `git status` im bestehenden Repo → auf uncommitted Änderungen prüfen
- Dann User fragen: pull / reclone (rm -rf) / anderer Pfad
- Bei `rm -rf` des Zielverzeichnisses: vorher `cd` woanders hin, sonst bricht die Shell (siehe 2026-03-14)

### 2026-04-23 — Blender-Session 3 (Raumlogik + Tuer-Konstruktionen)

**Raumlogik-Konsistenz vertikal (KRITISCH):**
- Raumaufteilung zwischen Stockwerken MUSS konsistent sein
- Beispiel: Kueche im OG liegt in X-Position UEBER Kueche im EG
- Besondere Indikatoren: Kuppeln/Schaechte/Installationen verbinden Raeume vertikal
- Signal: "Fenster auf Hoehe der Kuppelreihe" = Diana meint X-Ausrichtung (vertikale Achse durch Kuppel → Raum oben)

**"Auf Hoehe von" = X-Position (nicht Z-Hoehe):**
- Diana's Positionsangaben "auf Hoehe" beziehen sich auf raeumliche Ausrichtung ENTLANG einer Achse
- NICHT vertikale z-Koordinate
- Pruefen: Welches Referenzelement wird genannt? → X oder Y nehmen, nicht Z

**Terrassen-/Balkontueren = GLASTUEREN (nicht solide):**
- NIEMALS solide Tuerblaetter fuer Terrassen-/Balkontueren
- Konstruktion:
  1. Aeusserer Rahmen (Cube, Material weiss)
  2. Inneren Bereich via Boolean ausschneiden
  3. Glasscheibe innen (duenn, Glas-Material)
  4. Senkrechter Tuergriff (duenner Streifen, anthrazit/metallisch)
- `farbe_weiss=True` Parameter in tuer() → Glastuer-Branch
- `farbe_weiss=False` → schwarze Haustuer mit Lichtschlitz-Glas

**Wintergarten-Typologie (Beton + Glas-Front):**
- Aussenwaende: BETON (weiss/hell) mit Wanddicke 0.12-0.15m
- Frontfenster: FAST DURCHGEHEND, links + rechts der Tuer (Wandpfeiler nur 15cm breit)
- Tuer MITTIG in der Frontwand
- Seitenwaende: dickes Trapez-Prisma aus Beton
- Dach: 3 rechteckige Acryl-Panele getrennt durch schwarze Rahmen-Pfosten
- Neigung flach (~10-15°), am Haus hoch, zur Wiese runter

**Innenwand-Andeutung fuer Realismus:**
- Hinter transparenten Flaechen (Wintergarten-Front, Balkontuer) Innenmaterial als Plane platzieren
- Holzpanel (0.52, 0.38, 0.25) oder Teppich (0.55, 0.38, 0.30) hinter Glasflaechen
- Tiefenwirkung durch sichtbare Innenwand

**Element-Position iterativ verfeinern:**
- Diana: erst Element setzen → dann Korrektur mit Bezug auf anderes Element
- Bezugsrahmen: Fuer "auf Hoehe von X" → X.location oder feste Raum-Koordinate
- Pattern gilt fuer alle Fenster/Tueren in Fassaden mit mehreren Elementen

### 2026-04-23 — System-Cleanup (Security + Services + Hygiene Patterns)

**Password-Leak in systemd-Service-Dateien (KRITISCH)**
- Gefunden in `/etc/systemd/system/nas-docker-mount.service`: `ExecStart=... mount -t cifs -o username=X,password=Y,...` — Klartext-Password in systemd-Logs, journalctl und ggf. Git-History
- IMMER `credentials=/etc/samba/X-credentials` Pattern nutzen (Datei 600, root:root)
- Audit-Check vor Release: `sudo grep -r 'password=' /etc/systemd/system/`
- Beim Finden: Password rotieren (kann bereits via Logs geleakt sein)

**CIFS-Services scheitern an Boot-Race-Condition**
- Alle NAS/SSHFS-Services (nas-docker-mount, nas-mount, moltbot-sshfs) failed beim Boot — Netzwerk noch nicht ready zum Start-Zeitpunkt
- Manuell nach Boot gestartet funktionieren alle → reiner Race-Condition
- Fix-Pattern in `[Unit]`:
  ```
  After=network-online.target
  Wants=network-online.target
  ```
- Plus: `sudo systemctl enable systemd-networkd-wait-online.service`

**Service-Check muss DREI Ebenen pruefen**
- Initial: `systemctl --failed` zeigte 2. Dritter versteckter: `nas-mount.service` (user) verweist auf nicht-existentes Script `/home/yoga7/mount-nas` (korrekt: `mount-nas-permanent.sh`)
- `systemctl --failed` zeigt nur aktiv-fehlgeschlagene, nicht die mit kaputtem ExecStart-Pfad
- Zusätzlich prüfen:
  ```bash
  systemctl list-unit-files --state=enabled --no-pager | awk 'NR>1 && $2=="enabled" {print $1}' | \
    xargs -I{} sh -c 'p=$(systemctl cat {} 2>/dev/null | grep -m1 ^ExecStart | cut -d= -f2- | awk "{print \$1}"); [ -n "$p" ] && [ ! -e "$p" ] && echo "{}: $p fehlt"'
  ```

**Verschiebungen sparen KEINEN Speicher (selbe Partition)**
- Bei Cleanup-Sessions explizit trennen: "Struktur-Gewinn" vs "echter Speicher-Gewinn"
- `mv ~/Desktop/X ~/06_DOKUMENTE/` = 0 Byte auf df, nur Inode-Update
- Bei Diana's "Auf NAS archivieren" + NAS offline → lokal verschieben ist Struktur, kein Speicher
- IMMER klarstellen: "Das ist nur Struktur. Speicher spart erst Wechsel auf anderes FS (NAS, externe Platte) oder rm."

**Duplikat-Erkennung via MD5 — NIEMALS blind loeschen**
- Browser-Downloads mit `(1)`, `(2)` Suffix sind **oft verschiedene Versionen** (anderer Export, andere Encoding-Runde)
- Session-Beispiele:
  - `Hugo_Renn_Musikvideo.mp4` Desktop 119M ≠ Downloads/Hugo 148M → andere Version
  - `Topliner_Bardenberger.mp3` vs. `(1)` → unterschiedlicher Hash
  - ABER: `otto_ki.mp4` = `Otto/finale_musicvideo.mp4` → identisch, sicher löschbar
  - `jessica_achim.WAV` in ALT = in Voice-Recordings (identisch)
- Pattern: `md5sum file1 file2` oder `cmp -s file1 file2 && echo identisch` VOR `rm`

**Desktop/Interessant = Voice-Dump (bekanntes Diana-Pattern)**
- Diana sammelt Sprachaufnahmen in `~/Desktop/Interessant/` (WAV/MP3, 6+ GB)
- Vor Move Cruft raus: `venv/` (70M Python venv war drin), `node_modules/`, Temp-Files
- Kanonisches Ziel: `~/06_DOKUMENTE/Voice-Recordings/`

**~/~ Anomalie durch Shell-Expansion-Fail**
- 127M-Ordner namens `~` mit Chromium-Profile-Daten (Confluence-Profile, AutofillStates)
- Entsteht durch Chromium `--user-data-dir=~/X` wo `~` NICHT expandiert wird (in `.desktop`-File oder systemd-Unit)
- Fix im Root-Verursacher: IMMER `$HOME` statt `~` in Config-Dateien verwenden

**Tier 1 Cleanup-Checkliste erweitern um AI-Tool-Outputs**
- `~/Downloads/demucs_output` (AI-Stem-Separation, 120M Session-Fund)
- `.cxx` Android NDK Build-Caches (per Projekt 300M+)
- ComfyUI-Outputs, SD-WebUI-Outputs
- Pattern-Search:
  ```bash
  find ~ -maxdepth 4 -type d \( -name "demucs_output" -o -name "*_output" \
    -o -name ".cxx" -o -name "outputs" \) 2>/dev/null
  ```

**Case-Konflikt privat vs Privat (ext4 case-sensitive)**
- Auf case-sensitive FS zwei echte Ordner — Diana's Konvention ist deutsche Kleinschreibung (`privat/`, `geschaeft/`)
- Vor `mkdir` check: `ls -d ~/PATH/{x,X} 2>/dev/null`

**Downloads/ALT = Catch-All mit Pflege-Docs-Risiko**
- 156+ Files gemischt, dabei kritische Pflege-Docs (Techniker Krankenkasse .zip, Wundfotos.rar, database.sqlite.backup)
- NIEMALS pauschal archivieren/löschen. Keyword-Filter vor Bulk-Move:
  ```bash
  ls ~/Downloads/ALT | grep -iE "wund|medifox|SIS|pflege|MDK|behandl|patient|Schaut|Göbel|nextcloud_db"
  ```
- Pflege-relevantes → `~/06_DOKUMENTE/Medifox/`

**Sensible Dateien in Downloads — Standard-Suche im Cleanup**
- Session-Funde: 2× Google OAuth Client-Secrets (`client_secret_*.json`), `db_cluster-*.backup.gz`, `Ausweiskopie.pdf`, `Resume.pdf/docx`
- Standard-Check in jedem Cleanup:
  ```bash
  find ~/Downloads -maxdepth 2 -type f \( -iname "*secret*" -o -iname "*credential*" \
    -o -iname "*token*" -o -iname "*.env*" -o -iname "*ausweis*" -o -iname "*backup*" \
    -o -iname "client_secret*" -o -iname "*password*" \) 2>/dev/null
  ```
- Ziel: `~/06_DOKUMENTE/Credentials/` + `~/06_DOKUMENTE/privat/Persoenliches/` + `~/06_DOKUMENTE/Sicherungen/`

**zsh-Glob `.[^.]*` scheitert bei leerem Match (NULLGLOB)**
- `mv src/* src/.[^.]* dst/` crasht die Chain bei zsh wenn keine Hidden-Files da sind
- Fix: `mv src/* src/.[^.]* dst/ 2>/dev/null || mv src/* dst/`
- Oder: `(setopt NULL_GLOB; mv ...)` lokal

**Cleanup-Kommunikationspattern (Diana-verifiziert)**
- Tier-Struktur 1-5 nach Risiko: risikofrei → brauchtEntscheidung → sudo → Security
- Workflow: Bestandsaufnahme ZUERST (5 Dimensionen) → Plan mit Zahlen → AskUserQuestion pro Tier → Ausführung
- Nach jedem Tier: Vorher/Nachher-Tabelle. Nach Abschluss: Finale Bilanz + verbleibende Entscheidungen + Copy-Paste für sudo-Teile

**Session-Bilanz (Referenz für Grössenordnung)**
- Disk 300G → 287G (13G frei), Desktop 9,9G → 52K, Downloads 12G → 1,9G
- Dauer ca. 40 Min, 0 Fehler, 0 Rollbacks nötig

### 2026-05-02 — claude-cowork-linux Diagnose + Flatpak-Browser OAuth-Bug

**Diagnose-First Pattern bei System-Software (KRITISCH):**
- Vor "deinstallieren+neu installieren" IMMER prüfen ob Komponente überhaupt der richtige Pfad ist
- User sagte "Claude Desktop deinstallieren+neu für Cowork" — ich habe System-.deb erneuert, aber Cowork läuft aus separater User-Installation
- Pflicht-Checks vor destruktiven System-Aktionen:
  ```bash
  which <cmd>                              # welcher Pfad gewinnt?
  ls /usr/share/applications/*.desktop     # welche Launcher?
  ls ~/.local/share/applications/*.desktop # User-Overrides?
  xdg-mime query default x-scheme-handler/<scheme>  # URL-Handler?
  cat $(which <cmd>)                       # ist es ein Wrapper?
  ```
- Wrapper-Skripte in `~/.local/bin/` überschreiben System-Binaries via PATH-Order

**Magic-Link/OAuth-Login bricht im Flatpak-Browser (CLAUDE-COWORK-SPEZIFISCH):**
- Diana's Default-Browser ist `org.chromium.Chromium` (Flatpak) → sandboxed
- Symptom: User gibt Email ein → bekommt "Link zum Anmelden" statt Code → Klick öffnet Flatpak-Browser → OAuth-Flow bricht ab oder zeigt keinen Code
- Lösung: Magic-Link-URL **manuell** in System-Browser (`/usr/bin/firefox` oder `/usr/bin/chromium`) öffnen → Code wird angezeigt → manueller Login
- Permanent-Fix anbieten: `xdg-settings set default-web-browser firefox.desktop`
- Gilt vermutlich für ALLE OAuth-Flows die `claude://`/`postMessage`/Cross-Window nutzen

**claude-cowork-linux Architektur (zwei parallele Installationen):**
- **System-.deb** (`/usr/bin/claude-desktop` von aaddrick) ≠ **Cowork-Build** (`~/.local/bin/claude-desktop` von johnzfitch)
- Cowork-Build lebt in `~/.local/share/claude-desktop/` (eigenes git-Repo)
- PATH-Order: `~/.local/bin` vor `/usr/bin` → User-Wrapper gewinnt bei `claude-desktop` Aufruf
- ABER: Dock-Icon kann auf `/usr/share/applications/claude-desktop.desktop` (System-.deb) zeigen → Cowork wird umgangen
- `launch.sh` synct `stubs/` bei jedem Start automatisch in `linux-app-extracted/` und repackt `app.asar` → kein erneutes `install.sh` nötig nach stub-Änderungen
- `enable-cowork.py` ist idempotent ("Already patched" bei Re-Run)

**.desktop-Datei-Diagnose-Pattern:**
```bash
for f in ~/.local/share/applications/claude*.desktop /usr/share/applications/claude*.desktop; do
  echo "--- $f ---"; grep -E "^(Name|Exec|MimeType)=" "$f"
done
```
- Mehrere .desktop-Files mit identischem `Name=Claude` → Dock zeigt unklar welcher gewinnt
- Bei Diana waren 4 parallele Files (Sept 25, Okt 25, Cowork April 26, .deb Mai 26)
- xdg-mime URL-Handler unabhängig von .desktop-Reihenfolge — separat prüfen

**"Download Claude for Mac" / "Download Claude for Windows" ist KEIN Plattform-Bug:**
- UI-String-IDs in `.../linux-app-extracted/resources/ion-dist/assets/v1/index-*.js`:
  - `BobP7MV3sG` = "Download Claude for Mac"
  - `qZjfHa3uMI` = "Download Claude for Windows"
  - `Av25B3J2jg` = "Download Cowork"
- Render-Logik: `e ? "Cowork" : nH() ? "Mac" : "Windows"` — `e` = Cowork-User-Account
- → Wenn User "Mac" sieht: ist nicht eingeloggt oder Account hat kein Cowork
- NICHT: Plattform-Detection ist kaputt (UA wird absichtlich als Mac gefälscht in `frame-fix-wrapper.js` Zeile ~976, sonst "Linux nicht unterstützt")

**lokale stub-Reverts in Cowork-Repo (Aufmerksamkeit beim Update):**
- April 26: 3 Dateien hatten lokale Reverts in `~/.local/share/claude-desktop/stubs/`
- 73 Zeilen Linux-Titlebar-Fix waren raus → Tab-Leiste unklickbar, Plattform-Patches deaktiviert
- Vor `git pull` IMMER `git status` + `git diff --stat` checken
- Reset-Workflow: Patch sichern (`git diff > ~/cowork-local-reverts-$(date +%Y%m%d_%H%M%S).patch`) → `git reset --hard origin/master` → `--doctor` validieren

**Backup-Pattern vor System-Paket-Operationen:**
- Vor `apt remove` / `dpkg -r` selektiv Configs sichern (NICHT Caches/Cookies):
  ```bash
  BACKUP=~/.config/<app>_backup_$(date +%Y%m%d_%H%M%S)
  mkdir -p "$BACKUP"
  cp ~/.config/<app>/{*.json,CLAUDE.md} "$BACKUP/" 2>/dev/null
  cp -r ~/.config/<app>/mcp-servers "$BACKUP/" 2>/dev/null
  ```
- Nicht: ganzes `~/.config/<app>/` — enthält 100+MB Caches die nicht relevant sind

**Meta-Lektion (Eigen-Reflexion):**
- Bin zu schnell zur Aktion gesprungen (System-.deb deinstallieren+neu installieren)
- Habe NICHT geprüft ob die .deb der relevante Pfad für Cowork ist
- Hätte ich `which claude-desktop` als allerersten Schritt gemacht, wäre sofort klar gewesen: User-Wrapper aus `~/.local/bin/` ist der Cowork-Pfad, .deb-Reinstall ändert daran nichts
- Regel: Bei "X funktioniert nicht, bitte X neu installieren" — IMMER erst diagnostizieren ob X wirklich der richtige Hebel ist

### 2026-05-05 — Lautstärke-Diagnose + Crash-Loop-Patterns

**Lautstärke-Diagnose 5-Schritt-Reihenfolge (KRITISCH):**
1. `sensors | grep -E "Tctl|temp1|edge"` — Höhe (>75°C = thermisch erhöht)
2. `ps aux --sort=-%cpu | head -15` — Top-Verbraucher (>100% = ein Kern voll)
3. **PID-Wechsel-Check**: gleicher Prozessname mit immer neuer PID alle ~25s = systemd Crash-Loop
4. `journalctl --user -u <service> --since "10 min ago"` — Restart-Counter ist Schlüsselsignal
5. `cat /proc/cpuinfo | grep MHz` + Governor (`performance` heizt unnötig)

Session-Beispiel: Tctl 80,5°C + Load 3,18 + PID-Wechsel `openclaw-node` alle 25s → Logs zeigten **Restart-Counter 848** = 848× Crash über Stunden. Nach Service-Stop: 80,5°C → 60,4°C, Load 1,18.

**`Restart=always` Anti-Pattern bei externen Dependencies (KRITISCH):**
- `openclaw-node.service` hatte `Restart=always` + `RestartSec=10`. Bei 502 vom Gateway: jeder Restart-Versuch frisst 15s CPU bei 25s wall = 60% CPU dauerhaft, Memory peak 600+ MB pro Restart
- Lehre: Services mit externen WebSocket/HTTP-Dependencies brauchen Schutz:
  ```
  Restart=on-failure
  StartLimitInterval=600
  StartLimitBurst=10
  RestartSec=30
  ```
- Bei ~10 fehlgeschlagenen Versuchen in 10 Min stoppt systemd → User merkt Problem, statt dass die CPU 24/7 heizt

**Origin vs Tunnel unterscheiden bei Cloudflare-502:**
- 502 mit `server: cloudflare` und `cf-ray:` Header = **Cloudflare erreicht Origin nicht**, nicht Auth-Problem
- Diagnose-Reihenfolge:
  1. `curl https://<domain>/health` → 502 (Cloudflare-Edge antwortet)
  2. SSH zur Origin-Maschine: `curl http://localhost:<port>/health` → 200 (Origin gesund)
  3. → Problem liegt im Tunnel/Dashboard-Routing, nicht im Service
- WebSocket-Test: `curl -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -H "Sec-WebSocket-Version: 13" http://localhost:<port>/` → erwartet `101 Switching Protocols`

**Cloudflare-Tunnel-Doppel-Connector-Konflikt:**
- **Symptom**: Sporadisches 502 obwohl Origin läuft — Cloudflare load-balanced zwischen Connectoren, einer ist aber kaputt/falsch konfiguriert
- **Ursache**: Token-managed Tunnel auf 2+ Maschinen mit gleicher Tunnel-ID. yoga7 hatte alten config.yml-Connector ohne benötigte Routes, VM hatte vollständige Dashboard-Routes
- **Diagnose**: `cloudflared tunnel list` (auf einer Maschine mit cert.pem, ohne sudo) zeigt Tunnel + alle aktiven `Nx<colo>` Connections
- **Fix**: Auf Sekundär-Maschine `sudo systemctl disable --now cloudflared`. Token-managed Tunnel sollte nur EINE Maschine als Connector haben.
- yoga7-Spezifika: 5 Tunnel-Credentials-Files in `~/.cloudflared/`, `config.yml.broken`/`.working`/`.bak` — Hinweis auf historisches Tunnel-Hopping. `cloudflared.service` mit "Invalid tunnel secret" Loop ist Zombie aus früherer Migration.

**Token-Leak-Vektoren in systemd-Services (KRITISCH, ergänzt 2026-04-23 Password-Lektion):**
| Stelle | Sichtbar via | Beispiel diese Session |
|--------|-------------|------------------------|
| `ExecStart=...--token <wert>` | `ps -ef`, `cat /proc/<pid>/cmdline`, `systemctl cat` | Cloudflare-Tunnel-Token (Base64-JWT, decodierbar) |
| `Environment="X=<wert>"` | `systemctl cat`, override.conf-Datei | OPENCLAW_GATEWAY_TOKEN |
| `EnvironmentFile=/path` | nur Datei selbst (chmod 600) | sicherer |

- Audit-Check vor Release/Backup: `grep -rE 'token|password|secret|=ey[A-Za-z0-9_-]{20,}' /etc/systemd/system/ ~/.config/systemd/user/`
- Sicherer: `LoadCredential=` oder `EnvironmentFile=` mit chmod 600 in `~/.config/<service>/env` (siehe Token-Speicher-Konvention oben)
- Bei Leak: Token-Rotation in der Service-UI ist die einzige Lösung — Session-/Chat-Bereinigung reicht NICHT

**Multi-Host-Diagnose autonom über SSH:**
- Bei "X funktioniert nicht zuverlässig" / "Bring das ans Laufen": autonom via SSH zur Origin-Maschine ohne erneute Diana-Bestätigung
- Pattern: `ssh moltbotadmin@192.168.22.206 'systemctl status X; curl localhost:Y; ps -ef | grep Z'`
- Bündelt Diagnose-Schritte in EINEM SSH-Aufruf (kein 5× Connect-Overhead)
- Nach Reparatur 5×-Stabilitäts-Probe: sporadische Tunnel-/Routing-Issues treten nicht jedesmal auf, ein einzelner 200-Probe verifiziert nicht
  ```bash
  for i in 1 2 3 4 5; do
    echo "Probe $i: $(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 https://X/health)"
  done
  ```

**Sleep blockiert in Bash-Tool:**
- `sleep 25 && check` wird vom Runtime geblockt mit Hinweis auf Monitor/until-loop
- Workaround: Direkt prüfen (Service läuft schon einige Sekunden), oder `run_in_background: true` für lange Wartezeiten
- Nicht: shorter sleeps chained — auch geblockt
