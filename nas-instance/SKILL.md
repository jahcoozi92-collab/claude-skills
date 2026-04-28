# Skill: nas-instance

| name | description |
|------|-------------|
| nas-instance | Verwaltung der NAS-Instanz DXP4800PLUS-30E (192.168.22.90): CLAUDE.md, Architektur-Locks, Docker-Stack-Schutz, Service-Topologie. Nicht fuer Clawbot VM, Yoga7 oder andere Maschinen. |

## Scope — NUR NAS DXP4800PLUS-30E

Diese Skill gilt **ausschliesslich** fuer:
- **Host:** DXP4800PLUS-30E (UGREEN NAS, Debian 12)
- **IP:** 192.168.22.90, Tailscale: 100.90.233.16
- **User:** Jahcoozi
- **Home:** /home/Jahcoozi
- **Domain:** forensikzentrum.com (via Cloudflare Tunnel)
- **Zweck:** Docker-Services, Ollama, n8n, Open WebUI, AI-Infrastruktur

**Nicht** fuer:
- Clawbot VM (192.168.22.206, User: moltbotadmin)
- Yoga7 (Dianas Laptop)
- Windows-Systeme
- exe.dev VMs

---

## Verwaltete Dateien

### Geschuetzte Dateien
| Datei | Schutz | Zweck |
|-------|--------|-------|
| `~/CLAUDE.md` | Empfohlen: `chattr +i` | System-Router fuer Claude Code |
| `~/architecture/ARCHITECTURE_LOCK.md` | — | Architektur-Constraints |

### Konfiguration
| Datei | Zweck |
|-------|-------|
| `~/.claude/settings.local.json` | Claude Code Permissions |
| `~/.claude/agents/` | Custom Agent Definitionen (Security, Docker, Ollama) |
| `~/.claude/skills/` | Skill Repository (git: jahcoozi92-collab/claude-skills) |

---

## Architektur-Constraints

### Service-Topologie (gelockt)

```
Internet → Cloudflare Tunnel (cloudflared Container)
  ├── chat.forensikzentrum.com       → Open WebUI (:8080)
  ├── agents.forensikzentrum.com     → Open WebUI (:8080, Alias)
  ├── n8n.forensikzentrum.com        → n8n (:5678)
  ├── playground.forensikzentrum.com → LiveKit Playground (:8090)
  ├── token.forensikzentrum.com      → LiveKit Token (:8088)
  ├── livekit-ws.forensikzentrum.com → LiveKit WS (:7880)
  ├── ssh.forensikzentrum.com        → SSH (:22)
  ├── searxng.forensikzentrum.com    → SearXNG (:8081)
  ├── songcraft.forensikzentrum.com  → SongCrafter (:3080/:8002)
  ├── crawl.forensikzentrum.com      → Crawl4AI (:18800)
  ├── freqtrade.forensikzentrum.com  → Freqtrade (:8085)
  ├── medifox-admin.forensikzentrum.com → MediFox Admin (:8086)
  ├── speech.forensikzentrum.com     → SpeechReader (:5174)
  ├── speech-api.forensikzentrum.com → SpeechReader API (:8006)
  ├── ollama.forensikzentrum.com     → Ollama (:11436)
  ├── vaultwarden.forensikzentrum.com → Vaultwarden (:8083)
  ├── homeassistant.forensikzentrum.com → HA (:8123)
  ├── jellyfin.forensikzentrum.com   → Jellyfin (:8096)
  ├── nextcloud.forensikzentrum.com  → Nextcloud (:8282)
  ├── gedenkseite.forensikzentrum.com → Gedenkseite (:8182)
  ├── crewai.forensikzentrum.com     → CrewAI (:3400)
  ├── workflow-auditor.forensikzentrum.com → Auditor UI (:3456)
  ├── workflow-auditor-api.forensikzentrum.com → Auditor API (:3457)
  ├── openclaw.forensikzentrum.com   → OpenClaw (:18789)
  └── (25 Routes, Stand 2026-03-25, 6 tote entfernt)

Lokal (kein Tunnel):
  magic-video-backend (:3001) → NestJS API
    ├── magic-video-db (:5438) → PostgreSQL 16
    └── magic-video-redis (:6380) → Redis 7
```

### Docker-Netzwerk-Isolation (nicht aendern)
| Netzwerk | Services |
|----------|----------|
| `openwebui-network` | Open WebUI, Ollama, SearXNG, OpenAPI-Server |
| `n8n_default` | n8n, verbundene Automationen |
| `livekit-net` | LiveKit Server, Agent, Playground |
| `default` (magic-video) | magic-video-db, magic-video-redis |

### Daten-Pfade (kritisch)
| Pfad | Inhalt |
|------|--------|
| `/volume1/docker/open-webui/` | Open WebUI Daten, Tools, Functions |
| `/volume1/docker/ollama/data/` | Ollama Modelle |
| `/volume1/docker/n8n/` | n8n Daten und Workflows |
| `/volume1/docker/home-assistant/` | Home Assistant Config |
| `/datenbank/*` | NAS-Datenbank (gemountet in n8n) |

---

## Ollama Modelle (aktuell)

| Modell | Groesse | Zweck |
|--------|---------|-------|
| qwen2.5-coder:14b | 9GB | Code-Generierung |
| deepseek-r1:14b | 9GB | Reasoning |
| gemma3:12b | 8GB | General Purpose |
| qwen3:8b | 5GB | Leichtgewicht |
| llama3.2-vision | 8GB | Vision/Multimodal |
| bge-m3 | 1.2GB | Embeddings |

Port: 11436 (extern) → 11434 (intern im Container)

---

## Schutz-Operationen

### CLAUDE.md schuetzen (empfohlen)
```bash
chmod 444 ~/CLAUDE.md
sudo chattr +i ~/CLAUDE.md    # falls sudo verfuegbar
```

### Schutz pruefen
```bash
lsattr ~/CLAUDE.md
```

### Docker-Stack Neustart
```bash
# Open WebUI Stack
docker compose -f docker-compose.production.yml up -d

# n8n
cd n8n && docker compose up -d

# Alles pruefen
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## Sensitive Pfade (NIEMALS lesen/committen)

- `.env` — API Keys und Tokens
- `secrets/` — Docker Secrets
- `.ssh/` — SSH Keys
- `.git-credentials`
- `SYSTEM_ANALYSIS.md` — Klartext-Credentials (Legacy)
- `/volume1/docker/*/env*` — Service-Umgebungsvariablen

---

## Abgrenzung zu anderen Skills

| Skill | Zweck | Ueberschneidung |
|-------|-------|-----------------|
| `nas-instance` (dieser) | Claude Code Instanz-Verwaltung, Architektur-Locks | — |
| `nas-homelab` | NAS-Operationen (Volumes, Shares, Hardware) | Ergaenzt sich |
| `docker-admin` | Container-Management (generisch) | Nutzt nas-instance Topologie |
| `clawdbot-admin` | Clawbot VM Instanz (andere Maschine\!) | Klar getrennt |

---

## QPR Pipeline v4 — Architektur

**Kernprinzip:** Kleine LLMs (4B-8B) NIEMALS fuer strukturierte Parsing-Aufgaben einsetzen. Deterministische Regex ist schneller (5ms vs 40s), zuverlaessiger (16/16 Tests), und hat null Halluzinationen.

### Pipeline-Flow (6 Nodes, ~1-2 Min)
```
Datei-Upload → Text extrahieren → Sofort-Antwort → Medifox PII-Parser → Claude QPR-Analyse → Ergebnis speichern
```

### Workflow-IDs
| Workflow | ID |
|----------|----|
| Upload-Seite | `awEwRy06dnMmYGHo` |
| QPR-Pipeline (v4) | `13BSbohy6LXnnsva` |
| Ergebnis-Polling | `OVyDxI3TMa2aQDMF` |

### Medifox PII-Parser (deterministisch, kein LLM)
Erkennt automatisch aus Medifox-Header-Struktur:
1. **Bewohner:** `Name, Vorname: Nachname, Vorname (*DD.MM.YYYY)`
2. **Geburtsdatum:** NUR `(*DD.MM.YYYY)` Pattern — Pflegedaten (seit, Zeitraum) NICHT ersetzen
3. **Benutzer:** `Benutzer: Nachname, Vorname (Kuerzel)`
4. **Bezugspflegekraft**
5. **Arzt:** Nur Grossbuchstabe-Namen nach Hausarzt/Facharzt/etc., NICHT generisches "Arzt"
6. **Angehoerige**
7. **Einrichtung + Adresse + Tel/Fax + E-Mail + IK** (Einzel-Patterns, kein Block-Regex)
8. **Zimmer**
9. **Fliesstext-Scan:** Dr./Schwester + Name

### Medifox PII-Regeln (kritisch)
- **PP = Pflegeperson** — Standard-Medifox-Abkuerzung, ist KEIN Name, NIEMALS ersetzen
- **Word-Boundary `\b`** fuer Ersetzungen < 5 Zeichen (verhindert "Suppe" → "SuPK_1e")
- **Sortierung:** Laengste Matches zuerst, dann nach Prioritaet
- **Safety-Check:** Falls Bewohner-Nachname nach allen Ersetzungen noch im Text → Notfall-Replace

### Claude QPR-Prompt Kontext
- `max_tokens: 8192` (4096 reicht nicht, Report wird abgeschnitten)
- Claude muss wissen: `PP = Pflegeperson` (Medifox-Abkuerzung)
- Claude bewertet einen **Massnahmenplan**, nicht die vollstaendige Dokumentation
- Fehlende SIS/Medikation → "separat pruefen", nicht "fehlt"
- Warnung im Ergebnis-HTML wenn `stop_reason = max_tokens`

### Deutsches Namens-Regex (8/8 getestet)
```regex
[A-ZÄÖÜa-zäöüß][A-ZÄÖÜa-zäöüßé\-]+(?:\s+(?:von|van|de|der|den|zu|zum|zur)\s+[A-ZÄÖÜa-zäöüß][A-ZÄÖÜa-zäöüßé\-]+)*
```
Unterstuetzt: Schmidt-Meier, von der Heide, Oezdemir, étranger-Varianten

---

## n8n Webhook Constraints

- **CSP Sandbox:** Webhooks erzwingen `sandbox` OHNE `allow-same-origin`
  - `fetch()`, `XMLHttpRequest`, `localStorage`, `sessionStorage` BLOCKIERT
  - Nutze `<form target="_blank">` fuer POST
  - Nutze `<meta http-equiv="refresh">` fuer Polling
- **JS Variable Naming:** NIEMALS `var status` oder `var error` als globale Variablen (Konflikt mit `window.status`)
- **Cloudflare Free:** 100s HTTP-Timeout (Fehler 524) → Async-Pattern mit Polling-Endpoint erforderlich
- **Task Runner Timeout:** `N8N_RUNNERS_TASK_TIMEOUT` wird intern *1000 → Max safe: 1800000 (30 Min)

---

## Gelernte Lektionen

### 2026-04-23 — fem-pipeline Service-Deployment

**Verzeichnis-Struktur:**
```
/volume1/docker/fem-pipeline/
├── docker-compose.yml        # Service-Def + Network: shared-services (external)
└── service/
    ├── Dockerfile             # python:3.12-slim + libreoffice + ffmpeg + poppler
    ├── app.py                 # FastAPI mit Endpoints /extract, /tts_edge, /render_slides, /whisper_stt, /compose_video, /compose_full_video
    └── requirements.txt       # fastapi, python-pptx, lxml, edge-tts, faster-whisper
```

**Container-Port:** `8746:8000` (Host:Container)
**Docker-Network:** `shared-services` (nicht `n8n_default`!) — n8n läuft dort, intern erreicht man den Service als `http://fem-pipeline:8000`
**Volumes:** 
- `fem_tmp:/tmp/fem` (scratch space)
- `fem_models:/root/.cache/huggingface` (Whisper-Model-Cache, 500MB)

**SSH-Pattern für Auto-Deploy:**
```bash
sshpass -p '<pwd>' ssh -o StrictHostKeyChecking=no Jahcoozi@192.168.22.90 \
  'cd /volume1/docker/fem-pipeline && docker compose build && docker compose up -d'
```

**Datei-Sync via NAS-Mount:**
- Lokale Dev-Kopie in `/tmp/fem-pipeline/`
- Sync auf NAS via `cp ... /mnt/nas/docker/fem-pipeline/service/`
- Dann SSH für Build-Trigger
- Alternativ: direkt in `/mnt/nas/docker/fem-pipeline/` editieren (aber Git-Versioning verlieren)

---

### 2026-02-08 — Initiale Einrichtung

**Instanz-Differenzierung:**
- NAS und Clawbot VM haben unterschiedliche User, Pfade, Services
- Skills muessen pro Maschine differenziert werden
- Architecture Locks dokumentieren welche Strukturen stabil sind

**NAS-Besonderheiten:**
- Kein systemd (Docker-basiert, kein systemctl)
- Cloudflare Tunnel statt Reverse Proxy
- Ollama laeuft als Docker Container (nicht nativ)
- Mehrere Docker-Compose-Dateien fuer verschiedene Stacks

### 2026-02-18 — QPR Pipeline v1-v4 Evolution

**Architektur-Evolution (v1→v4):**
- v1: Ollama gemma3:4b Volltext-Anonymisierung → Bengali-Gibberish bei 30K Input
- v2: Ollama mit Truncation auf 5K + JSON-Mapping → Halluzinationen ("geben" → Arzt)
- v3: Ollama + Regex-Fallback → "PP" → "PK_1" zerstoert Woerter ("Suppe" kaputt)
- **v4: Ollama komplett entfernt** → Deterministischer Medifox PII-Parser (16/16 Tests bestanden)

**Level-2 Thinking Prinzip:**
- Nach 3+ iterativen Patches am selben Problem → STOPP
- Architektur ueberdenken statt weitere Patches
- Symptom-Patches (Blacklist, Boundary-Fixes) sind Warnsignal fuer falschen Ansatz
- In diesem Fall: LLM-basiertes Parsing war der falsche Ansatz fuer strukturierte Daten

**Infrastruktur-Fixes:**
- Cloudflare 524 Timeout → Async-Polling-Architektur mit meta-refresh
- N8N_RUNNERS_TASK_TIMEOUT=2400000 crasht Task Runner (32-bit Overflow) → 1800000
- `var status` in sandboxed Webhook-Page → `statusBox` (window.status Konflikt)
- PDF-Extraktion mit pdfjs-dist funktioniert fuer Medifox-Exporte

### 2026-03-25 — Home Assistant Level 1/2/3 Deep Optimization

**Bosch SHC → Matter Migration:**
- Thermostate liefen frueher ueber Bosch SHC (Zigbee), jetzt ueber Matter
- Entity-IDs komplett anders: `climate.*_heizkorper_th` → `climate.*_room_climate_contr/cont/contro`
- Matter kuerzt Entity-IDs ab (Truncation) — immer Entity Registry pruefen
- Betrifft 57+ Referenzen in automations, scripts, dashboards

**NAS Volume Permissions:**
- `chmod` vom Host auf NAS-Volumes: `Operation not permitted`
- Workaround: `docker exec homeassistant chmod 600 /config/secrets.yaml`
- NAS-Filesystem (wahrscheinlich Btrfs/ext4 auf Volume) hat eigene Rechte-Verwaltung

**Bootstrap-Phase Logging:**
- HA Logger-Config wird NACH dem Bootstrap geladen
- Fruehe Warnings (custom_components, pychromecast) koennen nicht ueber `logger:` in configuration.yaml unterdrueckt werden
- Das ist ein bekanntes HA-Verhalten, kein Config-Fehler

**HA Container-Name:**
- Container heisst `homeassistant` (ohne Bindestrich!)
- NICHT `home-assistant` wie man vermuten wuerde

### 2026-04-08 — KVM Autoload, OpenClaw Avatar, Static Hosting

**KVM-Module nach NAS-Reboot nicht geladen:**
- UGREEN NAS laedt `kvm` und `kvm_intel` Module NICHT automatisch nach Reboot
- Symptom: VM startet nicht, `/dev/kvm` fehlt, libvirtd meldet "Permission denied"
- UGOS-Fehlermeldung ist irrefuehrend: zeigt "openclaw" als Pfad, tatsaechlich UUID-basiert
- Fix: `/etc/modules-load.d/kvm.conf` mit `kvm` und `kvm_intel` erstellen
- Nach Fix: `modprobe kvm kvm_intel && sudo systemctl restart libvirtd`

**UGOS VM-Verwaltung Pfad-Mapping:**
- UGOS zeigt VM-Namen ("openclaw"), Dateisystem nutzt UUIDs
- Tatsaechlicher Pfad: `/volume1/@kvm/<uuid>/<uuid>_<disk-uuid>.qcow2`
- Fehlermeldung zeigt `.gcow2` — tatsaechlich `.qcow2`

**OpenClaw Avatar-Constraints:**
- `ui.assistant.avatar` in `openclaw.json`: max 200 Zeichen (data URIs unmoeglich)
- Avatar wird CLIENT-SEITIG geladen → URL muss vom Browser erreichbar sein
- Interne IPs (`192.168.x.x`) funktionieren nur im LAN, nicht ueber Cloudflare
- **Loesung:** Bild in Open WebUI Static-Verzeichnis hosten:
  ```bash
  docker cp bild.png open-webui:/app/backend/open_webui/static/bild.png
  ```
  → Erreichbar unter `https://chat.forensikzentrum.com/static/bild.png`
- ACHTUNG: Ueberlebt Container-Recreate NICHT! Bei Updates erneut kopieren

**Static File Hosting hinter Cloudflare (Rangfolge):**
1. Open WebUI: `docker cp` → `/app/backend/open_webui/static/` → `chat.forensikzentrum.com/static/`
2. Gedenkseite: `sudo cp` → `/volume1/docker/gedenkseite/site/` → `gedenkseite.forensikzentrum.com/`
3. rag-landing: nginx hat Permission-Probleme mit bind-mounts (403 trotz 777)

**UGOS systemd Units nach Reboot:**
- `domain_tool`: braucht `/etc/samba/smbdomain.conf` (leere Datei reicht: `sudo touch`)
- `upnpd`: sed-Fehler im Init-Script, Neustart hilft
- `video_serv`: erholt sich selbst nach kurzer Verzoegerung

### 2026-04-01 — SPA-Fetch & UGNAS Knowledge Center

**UGNAS Knowledge Center ist SPA (Single Page App):**
- URL-Pattern: `support.ugnas.com/knowledgecenter/#/detail/eyJ...` (Base64-kodierte Artikel-ID)
- Base64 enthält: `{"id":3747,"articleInfoId":570,"language":"de-DE","clientType":"PC"}`
- curl/WebFetch liefern nur leere HTML-Shell (JS-only Rendering)
- **Lösung:** Playwright MCP (`browser_navigate` + `browser_snapshot`) rendert JS korrekt
- Kein API-Endpoint direkt abrufbar (403 + SPA-Redirect)

### 2026-03-16 — Magic Video Backend E2E

**Neues Projekt:** `~/magic-video-backend`
- NestJS + Prisma + BullMQ + fal.ai (Kling Video v2.5 Turbo Pro)
- Image-to-Video-Generierung mit Credit-System
- Compose: PostgreSQL (:5438), Redis (:6380), Backend (:3001)
- Compose-Verzeichnis: `~/magic-video-backend/`

**Zombie-Prozess-Problem:**
- `nest start --watch` hinterlaesst Zombie-Prozesse wenn Terminal geschlossen wird
- 11 Zombies fraßen ~4GB RAM
- Pruefung: `ps aux | grep "nest start" | grep -v grep | wc -l`
- Aufraumen: `pkill -f "nest start"`

**fal.ai Kling Video Constraints:**
- Bilder muessen mindestens ~512x512 sein, sonst `ValidationError: Unprocessable Entity`
- Bilder muessen ueber fal.ai CDN hochgeladen werden (POST /api/upload → fal.storage.upload)
- Generierung dauert ~60-90 Sekunden pro 10s-Video
- Error-Logging: `error.body` muss explizit geloggt werden (fal.ai SDK wirft ValidationError mit body-Property)

### 2026-04-16 — Cleanup-Playbook + Swap/VM-Warnungen

**NIEMALS: `swapoff -a` auf UGREEN-NAS**
- UGREEN verwaltet 4× zram-Devices (je ~5 GB, ~20 GB gesamt) über eigenes Init — **NICHT in /etc/fstab**
- `swapoff -a` deaktiviert sie, `swapon -a` reaktiviert sie **nicht** (liest nur fstab)
- Ergebnis: Swap total 0 B bis zum Reboot → bei RAM-Druck OOM-Risiko
- **Swap-Leerung nur per Reboot.** Für dauerhaft weniger Swap: nur swappiness senken.
- Falls doch mal passiert: `sudo swapon /dev/nvme1n1p5 && sudo swapon /overlay/.swapfile` als Disk-Swap-Notfall, danach `sudo reboot` für zram-Wiederherstellung.

**QEMU-VM ist openclaw — NICHT anfassen**
- `/volume1/@kvm/d9537353-72ec-498d-82bb-d0b28e20616b/` = openclaw-VM
- Läuft als qemu-system-x86_64-Prozess (User `libvirt+`, ~10 GB RAM, 5 vCPUs, 30 %+ CPU)
- **`virsh list --all` zeigt sie NICHT** — sie läuft außerhalb der libvirt-Registry (direkt gestartet)
- Bei Cleanup-Analysen: Prozess ist KEIN Zombie, hoher Ressourcenverbrauch ist erwartet
- Siehe auch 2026-04-08 KVM-Module-Autoload: Nach Reboot müssen `kvm` + `kvm_intel` geladen sein

**NAS-Cleanup Playbook (reproduzierbar, ~100 GB Gewinn)**
- Scripts liegen im Home: `~/cleanup-nas.sh` (Phase 1) + `~/cleanup-nas-phase2.sh` (Phase 2)
- Beide idempotent, dry-run-fähig (`--apply` = echte Ausführung)
- **Phase 1** (risikoarm, ~80 GB): Container-Prune, dangling Image-Prune, Builder-Prune, `~/.cache`-Cleanup (uv, pip, npm, playwright, autoresearch), `apt clean`, `journalctl --vacuum-size=200M`
- **Phase 2** (kalibriert): `docker image prune -af` (oft nur ~4 GB, weil Images an Container gebunden), n8n-Backup-Rotation, Volume-Whitelist

**n8n-Backup-Rotation Pattern**
- Zwei Speicherorte: `/volume1/docker/n8n/backups/` (tar/tar.zst) + `/volume1/docker/n8n/data_backup_*/` (Ordner)
- Backups wachsen auf 70+ GB (14 Archive × 4-6 GB) → Rotation: 3 jüngste tar.zst + 1 Jahresbackup behalten
- `data_backup_*` Ordner sind oft 6-15 GB groß und ungenutzt nach erfolgreichem Upgrade

**Sichere Volume-Whitelist (tote Projekte)**
Immer mit `docker volume inspect` + in-use-Check vorher. Bestätigt sicher entfernbar:
- `agentgpt_*`, `autogpt_*`, `auto-claude_*`, `langflow_*`, `mcp-server_mcp_data`
- `monitoring_*` (grafana/loki/prometheus), `openhands_*`, `openwebui-optimized_*`
- `portainer_data`, `smart-home-platform_*` (alle), `openapi-servers_git_repos`

**Kernel-Tuning `/etc/sysctl.d/99-nas-tuning.conf`**
```
vm.swappiness = 10           # Standard 60 — weniger unnötiges Swapping bei viel freiem RAM
vm.vfs_cache_pressure = 50   # Standard 100 — FS-Metadaten länger im Cache
```
Aktivieren: `sudo sysctl --system`. Reversibel: Datei löschen.

**Docker-Prune Realität**
- `docker system df` zeigt „reclaimable" — das **überschätzt** den tatsächlichen Gewinn
- `docker image prune -af` holt nur Images zurück, die KEIN Container (auch gestoppt) mehr referenziert
- Bei 30+ laufenden Containern sind oft nur 3-5 GB wirklich reclaimable, nicht die angezeigten 50+ GB
- Großer Hebel liegt meist in: dangling Images (ungetaggte Duplikate nach Updates) + Volumes + n8n-Backups

**Classifier-Ausfälle während Bash/Write**
- Bei längerer Classifier-Downtime („claude-opus-4-7[1m] is temporarily unavailable"): Scripts ins Home schreiben, User via SSH selbst ausführen lassen
- Script-Output teilen → dann Tasks von Claude-Seite finalisieren
- Schneller als auf Classifier-Recovery zu warten (>5 Min Downtimes beobachtet)

**Celery-Worker 104 % CPU war kein Zombie**
- `songcrafter-celery-worker` Container hatte PID 3435843, 104 % CPU in Momentanmessung
- Tatsächlich: produktiver Song-Generation-Task (GPU-Pool `--pool=solo`, concurrency=1)
- Lehre: Vor Kill eines „Host-Root-Celery-Workers" immer Container-Zuordnung prüfen (`/proc/$PID/cgroup | grep docker`)

### 2026-04-19 — `/init` auf der NAS

**Filesystem-Root `/` ist read-only**
- `touch /CLAUDE.md` → `Permission denied` (auch als root-Session)
- Konsequenz: Eine Root-Level-`CLAUDE.md` am Filesystem-Root ist auf dieser NAS technisch **nicht möglich** — der Ansatz "Top-Level-Landkarte nach `/`" scheitert am EACCES
- Schreibbar sind nur Nutzer-/Volume-Pfade (`/home/Jahcoozi/`, `/volume1/docker/`, `/tmp`, `/root`)

**Scoped CLAUDE.md decken bereits alles ab**
- `/home/Jahcoozi/CLAUDE.md` → Dev-Workspace, Open WebUI Prod, n8n, LiveKit, Medifox RAG, Claude Agents/Skills
- `/volume1/docker/CLAUDE.md` → kompletter Docker-Stack, Cloudflare Tunnel, Backup-System, Port-Referenz
- Beide sind aktuell und architektonisch solide — keine Lücke, die eine Root-Datei füllen würde

**Verhalten bei `/init` auf dieser Instanz (bestätigt von Diana 2026-04-19):**
1. Zuerst prüfen ob scoped CLAUDE.md bereits existieren (`find / -maxdepth 3 -name CLAUDE.md`)
2. Falls ja: **NICHT** redundant eine Root-Datei erzwingen, auch nicht als "Landkarte"
3. Stattdessen Optionen anbieten: (a) nichts tun, (b) Updates an bestehenden, (c) neue scoped Datei in einem konkreten Unterverzeichnis
4. Diana bevorzugt Option (a) bei vollständigen Scopes — **Minimalismus vor Vollständigkeit**

**Warum das zählt:**
- `/init` ist der typische "Onboarding"-Reflex — verleitet dazu, eine zentrale Datei anzulegen, auch wenn sie nur Verweise enthält
- Auf Multi-Scope-Systemen (NAS, Homelab, Monorepos mit Sub-Projekten) ist die scoped Struktur bewusst gewählt und sollte nicht übersteuert werden
- Zusammenfassungs-/Router-Dateien werden schnell zu veralteter Redundanz

### 2026-04-19 — systemd --user Timer statt Cron (UGREEN-Einschraenkung)

**Problem: UGREEN DXP4800PLUS blockt User-Crontab**
```
$ crontab -e
/var/spool/cron/: mkstemp: Permission denied
```
User `Jahcoozi` darf kein eigenes crontab anlegen.

**Lösung: systemd --user Timer**
- Laeuft als User, kein sudo noetig
- `Persistent=true` → holt verpasste Runs nach Reboot nach
- `RandomizedDelaySec=5m` → verhindert Thundering Herd bei mehreren Timern

**Pattern (Skills-Sync):**
```
~/.config/systemd/user/
├── skill-sync.service  (Type=oneshot, ExecStart=bash /path/script.sh)
└── skill-sync.timer    (OnCalendar=*-*-* 03:30:00, Persistent=true)

systemctl --user daemon-reload
systemctl --user enable --now skill-sync.timer
```

**Linger-Flag fuer headless:**
- Ohne Linger: Timer laeuft nur bei aktiver Session (SSH/lokal)
- Einmalig: `sudo loginctl enable-linger Jahcoozi`

**Diagnose:**
```bash
systemctl --user list-timers                 # Naechster Lauf
systemctl --user status skill-sync.service   # Letzter Run
journalctl --user -u skill-sync.service -n 50
systemctl --user start skill-sync.service    # Manueller Test
```

**Installer:** `~/.claude/skills/tools/open-webui-sync/install-systemd-timer.sh` (idempotent)

**Automation-Kette Skills-Sync:**
```
git push → 03:00 n8n → Supabase RAG
        → 03:30 systemd → Open WebUI Collection
```
Fire-and-forget: User macht nur `git push`.

### 2026-04-20 — SSH Home-Dir Permissions & btrfs Layout

**UGOS Pro Filesystem-Layout (btrfs-Subvolumes)**
- `/volume1` ist btrfs-Pool `ug_A602FF_*-volume1` (subvolid=5)
- `/home` ist Subvolume `@home` (subvolid=261) — **kein separater Mount**, `findmnt /home/<user>` liefert leer
- Echtes User-Home: `/volume1/@home/Jahcoozi`
- Versionierungs-Cache: `/volume1/@version_explorer_cache/home/Jahcoozi` (UGOS Snapshot-Feature)
- Docker-Overlays: `/volume1/@docker/overlay2/*/merged` (pro Container ein Mount)

**SSH Home-Dir Access-Bug (UGOS Default)**
- UGOS setzt Home-Permissions default auf `drwx------ Jahcoozi:admin` (Mode 700, Primärgruppe admin)
- Trotz Owner-Match scheitert SSH-Login mit:
  ```
  Could not chdir to home directory /home/Jahcoozi: Permission denied
  bash: /home/Jahcoozi/.bashrc: Permission denied
  ```
- User landet in `/` statt `$HOME`, PATH-Setup greift nicht → `claude`, nvm, pyenv nicht verfügbar
- **Fix:**
  ```bash
  sudo chown -R Jahcoozi:users /home/Jahcoozi
  sudo chmod 755 /home/Jahcoozi
  sudo chmod 644 /home/Jahcoozi/.bashrc
  ```
- `chown -R` kann auf einzelnen verwalteten Dateien (z.B. `CLAUDE.md` mit chattr-Schutz) mit "Operation not permitted" scheitern — **Gesamtfix ist trotzdem erfolgreich**, nur die geschützte Datei bleibt beim alten Owner

**UGREEN User-Setup Referenz (Jahcoozi)**
- `uid=1000(Jahcoozi)`, `gid=10(admin)` primär
- Sekundärgruppen: `admin(10)`, `users(100)`, `docker(121)`, `ughomeusers(133)`
- `ughomeusers` = UGOS-spezifische Gruppe für Home-Management (PAM/Encryption-Hooks)
- Für normale Home-Operation sollte Owner-Gruppe `users`, nicht `admin` sein

**Claude-Installation auf NAS**
- NAS hat `claude` nicht vorinstalliert, nicht im PATH
- Install via npm global: `sudo npm install -g @anthropic-ai/claude-code`
- Alternativ: pipx oder curl-Installer (siehe Claude Code Docs)

**Diagnose-Anti-Pattern (Selbstkorrektur)**
- Nach Fix-Vorschlag IMMER aktuellen Zustand vs. Vorher-State vergleichen — nicht blind in tiefere Diagnose-Pfade abbiegen
- "Operation not permitted" auf EINZELNER Datei ≠ Gesamtfail des Fixes
- Reihenfolge: (1) Fix anwenden, (2) Zustand verifizieren, (3) erst bei weiterhin-kaputt tiefer graben
- Session 2026-04-20: fscrypt/ACL/AppArmor-Diagnose war unnötiger Detour — erster Fix-Vorschlag (chown+chmod) hatte bereits funktioniert, wurde aber nicht re-verifiziert

### 2026-04-23 — CIFS-Mount-Services Boot-Race (Client-seitig, Cross-Reference)

**CIFS-basierte systemd-Services auf Clients scheitern beim Boot**
- Auf Yoga7 beobachtet (siehe `yoga7-admin` 2026-04-23): `nas-docker-mount.service`, `nas-mount.service` (user), `moltbot-sshfs.service` (user) failed beim Boot weil Netzwerk noch nicht ready
- Relevant für alle CIFS-Clients gegen die NAS (Yoga7, Clawbot VM, andere)
- Manuell nach Boot gestartet: alle OK → reiner Race-Condition
- Fix-Pattern in `[Unit]`:
  ```
  After=network-online.target
  Wants=network-online.target
  ```
- Plus: `sudo systemctl enable systemd-networkd-wait-online.service`
- NAS selbst ist Docker-basiert ohne systemd-CIFS-Services → nicht direkt betroffen, aber wichtig für NAS-konsumierende Systeme

**Password-Leak-Pattern in CIFS-Service-Dateien (KRITISCH)**
- Bei Clients die gegen NAS mounten: Klartext-Password in `ExecStart`-Zeile ist häufig
  ```
  ExecStart=... mount -t cifs -o username=Jahcoozi,password=XXX,...
  ```
- Das landet in systemd-Logs, journalctl, und ggf. Git-History der Service-Datei
- IMMER credentials-Datei nutzen: `credentials=/etc/samba/nas-credentials` (mode 600, root:root)
- Audit bei neuen Clients: `sudo grep -r 'password=' /etc/systemd/system/`
- Bei gefundenem Leak: **NAS-Password rotieren** (kann via Logs geleakt sein)

**Autofs auf Clients triggert nicht bei allen Operationen**
- Yoga7: `/mnt/nas/nas/` (Symlink auf `/mnt/autofs/nas/`) wird von `touch` nicht zuverlässig getriggert
- Symptom: `df -h /mnt/nas/nas` zeigt lokales FS statt NAS → Mount ist inaktiv
- Mount-Verify: `mount | grep cifs` oder `mountpoint /mnt/nas`
- Bei "soft failure" scheinbar-schreibbar aber tatsächlich-nicht: Vor Bulk-Moves Write-Test mit Cleanup: `touch /mnt/nas/X/.test_$$ && rm /mnt/nas/X/.test_$$`

### 2026-04-24 — n8n Update via update_n8n.sh

**Container-Crash nach `compose recreate` (beobachtet, nicht reproduzierbar)**
- `bash ops/n8n/update_n8n.sh` pullt Image, recreated Container — Start-Log zeigt `Up 3 seconds`
- 10-15s später: Container im State `Created` (nicht `Up`), "Last session crashed" im Log
- Manueller `docker start n8n-n8n-1` lief danach sauber durch, Healthcheck HTTP 200
- Mögliche Ursache: DB-Migration/Init-Race beim Recreate. Nicht kritisch, aber Verifikation nötig
- **Pattern:** Nach `update_n8n.sh` → 10s warten → `docker ps` prüfen (nicht nur Startup-Log). Falls `Created`: `docker start n8n-n8n-1` nachschieben

**n8n v3 Migration vormerken (Deprecation Warning)**
- `/home/node/.n8n/binaryData` wird in v3 zu `/home/node/.n8n/storage`
- Für Migration: `N8N_MIGRATE_FS_STORAGE_PATH=true` setzen
- Bei gemountetem Volume: Mount-Config nach Migration aktualisieren
- Noch nicht akut — erst beim v3-Sprung relevant

**n8n-Update-Skript Verhalten**
- `ops/n8n/update_n8n.sh` macht: graceful stop (120s) → Backup via `backup_n8n.sh` → pull → `compose up -d`
- Backup-Format: `/volume1/docker/n8n/backups/n8n-backup-YYYYMMDD-HHMMSS.tar.zst`
- Image: `docker.n8n.io/n8nio/n8n:latest` (kein Pin) → jeder Update-Run holt latest
- Version 2.17.6 → 2.17.7 war nur Patch-Bump

### 2026-04-28 — /schedule Cloud vs Local + n8n CLI Cred-Export + Cron-Wrapper

**/schedule-Vorab-Check (Cloud-Sandbox-Limits, KRITISCH):**

Bevor `/schedule` für eine Routine genutzt wird: prüfen ob die Aufgabe NAS-lokale Ressourcen referenziert. Anthropic-Cloud-Agents laufen in Sandbox und haben **KEINEN** Zugriff auf:

- `/volume1/...` (NAS-Filesystem)
- `/volume1/docker/<service>/.env` (Service-Secrets)
- `/etc/cron.d/` (lokale Crons)
- Lokale Docker-Container (`docker exec ...`)
- Interne Netzwerk-Services (192.168.22.x)

**Entscheidungsregel:**
- Aufgabe braucht **nur** öffentliche APIs (GitHub, Slack, externe HTTPs) → `/schedule` Remote-Agent passt
- Aufgabe braucht **NAS-Pfade oder lokale Secrets** → lokaler Cron-Job auf NAS, **kein** Remote-Agent
- Bei Mischung: separate beide Teile, Remote macht den Cloud-Teil, lokaler Cron den NAS-Teil

Diana wählt bei NAS-Pfaden konsistent **Variante A (lokaler Cron)** — wegen Token-Verfügbarkeit, MD-Datei-Zugriff, kein Cloud-Token-Verbrauch.

**n8n-Credential-Token-Extraktion (offizielle Methode):**

Statt manueller Vault-Decryption (CryptoJS+EVP_BytesToKey, AES-256-CBC, "Salted__"-Prefix) lieber das offizielle n8n-CLI nutzen:

```bash
docker exec n8n-n8n-1 n8n export:credentials \
  --id=<credId> --decrypted --output=/tmp/cred.json

docker exec n8n-n8n-1 cat /tmp/cred.json | python3 -c \
  "import sys,json; d=json.load(sys.stdin); c=d[0] if isinstance(d,list) else d; print(c['data'].get('accessToken') or c['data'].get('token'))"

docker exec n8n-n8n-1 rm -f /tmp/cred.json
```

- Funktioniert für Telegram, OpenAI, Anthropic, Supabase, etc. — JSON-Struktur in `data` enthält je nach Credential-Typ unterschiedliche Felder (`accessToken`, `token`, `apiKey`, ...)
- Erfordert keine Crypto-Library im Host-Python
- **Permission-Lerneffekt:** Bei sensiblen Operationen (Vault-Decrypt) hat das Permission-System den ersten Versuch (manuelle Crypto-Lib) abgelehnt. Lehre: VORHER Optionen anbieten, nicht direkt durchführen. Diana autorisierte erst nach explizitem Vorschlag.

**System-Zeitzone für Cron auf DXP4800Plus:**

- `timedatectl` → `Time zone: Europe/Amsterdam (CEST, +0200)` — identisch zu Europe/Berlin (gleiche DST-Regeln).
- `/etc/cron.d/`-Einträge interpretieren Zeit als **lokal**, nicht UTC.
- `0 9 1 * * Jahcoozi /path/script.sh` = 09:00 Berlin/Amsterdam, KEIN UTC-Mapping nötig.
- Bestehender Crawler-Cron `30 4 * * 1` = Mo 04:30 lokal (Logfile-Timestamps bestätigen das).

**Cron-Wrapper-Pattern für Scripts mit Secrets:**

Bewährt für alle Cron-Jobs, die Keys aus mehreren Service-`.env`-Files brauchen (Pattern aus `crawl_medifox_updates_cron.sh`, `medifox_update_monthly_report.sh`):

```bash
#!/bin/bash
set -u

LOG_DIR="/volume1/docker/n8n/workflows/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/job_$(date +%Y%m%d_%H%M%S).log"

# Keys aus bekannten Quellen (in mehreren .env verteilt)
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" /volume1/docker/open-webui/backups/complete-update-*/.env 2>/dev/null | cut -d= -f2-)
export SUPABASE_SERVICE_KEY=$(grep "^SUPABASE_SERVICE_ROLE_KEY=" /volume1/docker/lightrag/.env.lightrag 2>/dev/null | cut -d= -f2-)
export TELEGRAM_BOT_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" /volume1/docker/n8n/.env 2>/dev/null | cut -d= -f2-)

# Optional/required-Checks
[ -z "$SUPABASE_SERVICE_KEY" ] && { echo "FEHLER: SUPABASE_SERVICE_KEY fehlt"; exit 1; }
[ -z "$TELEGRAM_BOT_TOKEN" ] && echo "WARN: Telegram übersprungen"

python3 /pfad/zum/script.py 2>&1 | tee -a "$LOG_FILE"
RC=${PIPESTATUS[0]}

# Log-Rotation: nur N letzte behalten
ls -t "$LOG_DIR"/job_*.log 2>/dev/null | tail -n +13 | xargs -r rm

exit $RC
```

**Idempotenz-State-File-Pattern:**

Für Cron-Jobs, die "neue Daten seit letztem Lauf" verarbeiten — JSON-State-File neben Script:

```python
STATE_FILE = Path("/volume1/docker/n8n/workflows/.<jobname>_state.json")

def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_max_id": 0, "last_run": None}

def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2))
```

- Initial-Lauf: `last_max_id=0` → verarbeitet alles, setzt dann den State.
- Folgeläufe: nur `id > last_max_id`.
- State-Reset für Testlauf: `rm /volume1/docker/n8n/workflows/.<jobname>_state.json`.
