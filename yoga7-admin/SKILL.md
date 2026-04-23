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
