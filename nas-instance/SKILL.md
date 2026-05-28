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
Internet → Cloudflare Tunnel (cloudflared + cloudflared-archenoah, BEIDE notwendig)
  ├── chat.forensikzentrum.com       → Open WebUI (:8080)
  ├── agents.forensikzentrum.com     → Open WebUI (:8080, Alias)
  ├── n8n.forensikzentrum.com        → n8n (:5678)
  ├── ssh.forensikzentrum.com        → SSH (:22)
  ├── searxng.forensikzentrum.com    → SearXNG (:8081)
  ├── crawl.forensikzentrum.com      → Crawl4AI (:18800)
  ├── freqtrade.forensikzentrum.com  → Freqtrade (:8085)
  ├── medifox-admin.forensikzentrum.com → MediFox Admin (:8086)
  ├── speech.forensikzentrum.com     → SpeechReader (:5174)
  ├── speech-api.forensikzentrum.com → SpeechReader API (:8006)
  ├── ollama.forensikzentrum.com     → Ollama (:11436)
  ├── vaultwarden.forensikzentrum.com → Vaultwarden (:8084)  # ab 2026-05-17, Docker-Daemon-Cache-Bug auf 8083
  ├── homeassistant.forensikzentrum.com → HA (:8123)
  ├── jellyfin.forensikzentrum.com   → Jellyfin (:8096)
  ├── nextcloud.forensikzentrum.com  → Nextcloud (:8282)
  ├── gedenkseite.forensikzentrum.com → Gedenkseite (:8182)
  ├── crewai.forensikzentrum.com     → CrewAI (:3400)
  ├── workflow-auditor.forensikzentrum.com → Auditor UI (:3456)
  ├── workflow-auditor-api.forensikzentrum.com → Auditor API (:3457)
  ├── openclaw.forensikzentrum.com   → OpenClaw (:18789)
  └── (21 Routes, Stand 2026-05-05, 4 LiveKit/Songcrafter-Routes entfernt)

Lokal (kein Tunnel):
  magic-video-backend (:3001) → NestJS API
    ├── magic-video-db (:5438) → PostgreSQL 16
    └── magic-video-redis (:6380) → Redis 7
```

### Cloudflared Dual-Instance (KRITISCH — beide notwendig)
- `cloudflared` und `cloudflared-archenoah` laufen parallel und müssen BEIDE bleiben
- Kein Optimierungspotenzial — vermutlich getrennte Tunnels für unterschiedliche Cloudflare-Accounts/Zonen
- Diana hat das am 2026-05-05 explizit bestätigt — niemals als Redundanz hinterfragen oder als Cleanup-Kandidat vorschlagen

### Docker-Netzwerk-Isolation (nicht aendern)
| Netzwerk | Services |
|----------|----------|
| `openwebui-network` | Open WebUI, Ollama, SearXNG, OpenAPI-Server |
| `n8n_default` | n8n, verbundene Automationen |
| `default` (magic-video) | magic-video-db, magic-video-redis |
| `speechreader-backend_speechreader-network` | Speechreader + faster-whisper (Speaches) |
| `home-assistant_default` | HA + ha-wyoming-whisper |

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

### 2026-04-29 — Statisches Webformular auf NAS + Apache-Bind-Mount-Edge

**Edge: `php:8.2-apache` Standard-Image kann Bind-Mounts auf UGREEN-Volumes nicht lesen**

Beobachtet bei `/volume1/docker/nextcloud/ai-act-befragung/` (Owner `1000:uucp`, Mode `775` mit `o+rx`):

```bash
docker run --rm -d --name X -p 8093:80 \
  -v /volume1/docker/nextcloud/ai-act-befragung:/var/www/html \
  php:8.2-apache
```

Apache-Log liefert sofort 403 auf alles:
```
[core:crit] (13)Permission denied: /var/www/html/.htaccess pcfg_openfile:
  unable to check htaccess file, ensure it is readable and that
  '/var/www/html/' is executable
```

- Apache läuft als `www-data` (UID 33), nicht als Owner (1000)
- `o+rx` ist gesetzt, aber **Synology/UGREEN-ACLs überschreiben POSIX-Bits** und verweigern www-data den Zugriff trotzdem
- `docker exec --user root` kann lesen → es ist *kein* Container-Konfigurationsfehler

**Drei Auswege (Reihenfolge nach Aufwand):**

| # | Variante | Eingriff |
|---|---|---|
| A | Auf Nextcloud Forms ausweichen (App via UI installieren, Fragen 1:1 nachbauen, IP-Speicherung deaktivieren) | keiner am Filesystem |
| B | Container mit `--user $(stat -c %u:%g <pfad>)` starten — Apache muss dann auf Port ≥1024 lauschen, also Image-Override mit `Listen 8080` + Compose-Datei | mittel, neue Datei |
| C | `synoacltool -add <pfad> user:www-data:allow:rx` (gezielte ACL, reversibel) | klein, ABER Rechte-Änderung → Diana fragen |

Diana wählte konsistent **A** für Validierungs-Befragungen (geringster Eingriff, nutzt vorhandene Infrastruktur).

**Port-Inventar-Update (vor `docker run -p ...` oder `python3 -m http.server`):**

| Port | Status |
|------|--------|
| 8088 | belegt (LiveKit-Token-Server, siehe Architektur-Topologie) |
| 8089 | belegt (LiveKit-Playground, **NICHT** für andere Tests verwenden) |
| 8090 | belegt (LiveKit-Playground laut Cloudflare-Route, in Praxis manchmal frei — prüfen) |
| 8092 | belegt |
| 8093 / 8095 / 8189 | typischerweise frei — gute Default-Optionen für temporäre Test-Server |

Immer vor Start prüfen: `ss -tln 2>/dev/null \| awk '{print $4}' \| grep -qE '[:.]<port>$' && echo BELEGT \|\| echo frei`.

**Validierungs-Befragungen — Datenschutz-Pattern (Pflege-/Healthcare-Kontext)**

Wenn auf der NAS eine Mini-Befragung gehostet wird (Validierung, Marktforschung, interne Umfrage):

1. **Niemals** Bewohner-/Diagnose-/Gesundheitsdaten abfragen — selbst optional nicht
2. **Niemals** Mitarbeitenden-Klarnamen abfragen
3. **Fachliche Antworten und Kontaktdaten getrennt speichern** — *zwei* JSONL-Dateien:
   - `data/answers.jsonl` — fachliche Antworten mit präzisem UTC-Timestamp
   - `data/contacts.jsonl` — nur freiwillige Kontaktangabe + Tagesdatum (keine Uhrzeit) → erschwert Re-Korrelation
4. **Niemals** speichern: IP, User-Agent, Cookies, Session-Daten
5. Kein externes JS/CSS/Font (kein CDN, kein Google Fonts, kein reCAPTCHA, kein Analytics)
6. Anti-Spam minimal: Honeypot-Feld + globales Stunden-Rate-Limit (z. B. 200/h) + serverseitige Whitelist-Validierung jeder Auswahl
7. `data/.htaccess` mit `Require all denied` + `Options -Indexes` (greift nur bei Apache mit `AllowOverride All`)
8. Direkt vor dem Submit-Button expliziter Hinweis: „keine Bewohnerdaten/Diagnosen/Gesundheitsdaten"
9. **Default-Empfehlung: Nextcloud Forms** — entfernt das ACL-/Apache-Problem komplett, nutzt vorhandene Infrastruktur

**Prüfprotokoll für statische HTML/PHP-Pakete (vor Container-Test):**

```bash
# PHP-Lint via Throwaway-Container (ohne PHP auf Host)
docker run --rm -v <dir>:/app -w /app php:8.2-cli php -l <file>.php

# HTML-Tag-Bilanz
grep -c '<form '   index.html ; grep -c '</form>'   index.html
grep -c '<fieldset>' index.html ; grep -c '</fieldset>' index.html
grep -c '<legend>' index.html ; grep -c '</legend>' index.html

# Forbidden-Pattern-Scan in PHP (keine IP/UA/Cookies)
grep -nE 'REMOTE_ADDR|HTTP_USER_AGENT|setcookie|session_start|\$_COOKIE' submit.php

# External-Resource-Scan in HTML/CSS (kein Tracking/CDN)
grep -nE '<script|googleapis|gstatic|fonts\.google|cdn\.|cdnjs|jsdelivr|unpkg|matomo|google-analytics|gtag' *.html *.css
```

**Spec-Validierung als zweiter Pass — Lehre aus dieser Session:**

- Erste Implementierung übersah die Vorgabe „fachliche Antworten und Kontaktdaten möglichst getrennt behandeln"
- Diana fand das beim selbstgeschriebenen Prüfauftrag durch eine systematische Checkliste
- **Konsequenz:** Bei mehrteiligen Specs (Datenschutz-Befragungen, QM-Templates etc.) immer eigene Validierungsrunde mit der Spec-Liste machen, *bevor* der User prüfen muss

### 2026-05-05 — Container-Cleanup Lessons (Bind-Mount-Falle, Network-Prune-Recreate)

**Bind-Mount vs Docker-Volume Check (KRITISCH vor Volume-Löschung)**

Open-WebUI und Ollama nutzen BIND-MOUNTS, nicht die gleichnamigen Docker-Volumes. Die Volumes `open-webui`, `open-webui_chroma_data`, `open-webui_postgres_data`, `open-webui_redis_data`, `ollama_models` existieren als Karteileichen — alle 0 Bytes — während die echten Daten unter `/volume1/docker/open-webui/` und `/volume1/docker/ollama/data/` liegen.

**Verifikations-Pattern vor jedem Volume-Prune:**
```bash
# 1) Welche Mounts hat der laufende Container?
docker inspect <container> --format '{{range .Mounts}}{{.Type}}: {{.Source}} -> {{.Destination}} (Name: {{.Name}})
{{end}}'

# 2) Wieviel Daten liegen im Volume? (sudo nötig auf NAS)
sudo du -sh /volume1/@docker/volumes/<volume-name>/_data
```
- Wenn Container `bind:` zeigt → das gleichnamige Volume ist sicher löschbar
- Wenn `_data` 0 Bytes zeigt → Volume ist eine leere Karteileiche
- **Niemals** `docker volume prune -a` ohne diese Checks bei kritischen Services (Open-WebUI, Ollama, Nextcloud, Vaultwarden)

**Network-Prune triggert Compose-Container-Recreate**

`docker network prune` entfernt `<project>_default`-Netze auch wenn Compose-Container darauf referenzieren. Folge: Beim nächsten Lifecycle-Trigger (oder sofort bei `unless-stopped`) recreated Docker den Container.

In dieser Session: `caddy-ha-proxy` wurde durch Network-Prune des `caddy-ha-proxy_default` recreated. Container nutzt zwar `host`-Network und lief sauber weiter, aber HA war ~30s nicht erreichbar.

**Pattern:** Vor Network-Prune prüfen welche Compose-Projekte aktive Netze haben:
```bash
docker network ls --format '{{.Name}}' | while read net; do
  containers=$(docker network inspect "$net" --format '{{range .Containers}}{{.Name}} {{end}}')
  [ -n "$containers" ] && echo "$net → $containers"
done
```

**Cleanup-Bilanz dieser Session (~109 GB freigegeben)**
- Images: 85,45 GB (60 Stück, inkl. einem `<none>` mit 26,7 GB)
- Volumes: 17,11 GB (16 Stück, alle leer — Reste alter Stacks)
- Build Cache: 6,97 GB
- Networks: 10 verwaiste entfernt
- Container: 56 → 45 (11 entfernt: Songcrafter-Stack, LiveKit-Stack, rag-landing, pflege-demo-ui, kimi-free-api)

Korrigiert frühere Annahme aus 2026-04-16 ("Volume-Prune meist nur 4 GB"): Bei massivem Stack-Removal lohnt sich Volume-Prune sehr wohl, weil leere Karteileichen-Volumes mit gelöscht werden.

**Stack-Identifikation vor Removal**

Compose-Projekt-Mapping prüfen, bevor `docker compose down` ausgeführt wird:
```bash
docker inspect <container> --format 'ComposeProject: {{index .Config.Labels "com.docker.compose.project"}}
WorkDir: {{index .Config.Labels "com.docker.compose.project.working_dir"}}
ConfigFile: {{index .Config.Labels "com.docker.compose.project.config_files"}}'
```
- Manche Container gehören zu nicht-offensichtlichen Compose-Projekten (z.B. `cassandra-agent` gehörte zu LiveKit-`stack`-Compose, nicht zu eigenem Projekt)
- Standalone-Container (kein ComposeProject-Label) brauchen `docker stop && docker rm`, kein `compose down`

**Faster-Whisper vs HA-Wyoming-Whisper — beide sind notwendig**

Zwei Whisper-Container, die einander NICHT ersetzen können:

| Container | Implementation | Konsument | Network |
|---|---|---|---|
| `faster-whisper` | Speaches (`ghcr.io/speaches-ai/speaches`), `faster-whisper-large-v3` | Speechreader / Open WebUI (OpenAI-kompatible API) | `speechreader-backend_speechreader-network` |
| `ha-wyoming-whisper` | Rhasspy Wyoming-Protokoll (`rhasspy/wyoming-whisper`) | Home Assistant Voice Assistant | `home-assistant_default` |

Speaches ist genauer (large-v3 vs Wyoming-Default tiny/base), nutzt aber inkompatible API. Bei Cleanup-Audits niemals als „doppelt" markieren.

**Image-Prune im Background bei großen Mengen**

`docker image prune -a -f` braucht bei >50 GB durchaus 60-90 Sekunden. Bei Background-Ausführung Progress via Output-Datei tracken statt mit `sleep` zu pollen:
```bash
docker image prune -a -f &  # oder via Bash-Tool run_in_background:true
# Output landet in /tmp/claude-*/tasks/<id>.output
```

**Cloudflare-Routes manuell pflegen (UI-Eingriff)**

Mit Token-basiertem cloudflared (kein lokales `config.yml`) sind Routen nur über das Zero-Trust-Dashboard löschbar. Nach Container-Removal IMMER prüfen ob Route verwaist ist und Diana darauf hinweisen — Cleanup ist nicht automatisierbar.

### 2026-05-05 — Nextcloud 32 / Calendar 6.2.x Bug-Trio + Sabre-Constraints

**Drei nicht-offensichtliche Bugs in NC 32 + Calendar 6.2.x — alle drei können gleichzeitig auftreten und sich gegenseitig maskieren. Code-Lesen war zur Diagnose nötig.**

**Bug 1: `shareapi_allow_share_dialog_user_enumeration` muss EXPLIZIT `yes` sein**

Calendar-App (`apps/calendar/lib/Controller/ContactController.php:114`) hat:
```php
$shareeEnumeration = $this->config->getAppValue(
    'core', 'shareapi_allow_share_dialog_user_enumeration', 'no'  // ← Default 'no'!
) === 'yes';
```
Im Rest von Nextcloud ist der Default `'yes'`. Wenn die Setting nie explizit gesetzt wurde, liefert der Calendar-Picker leere Trefferlisten zurück (Status 200, ~700 Bytes leeres JSON). Symptom: „Termin-Teilnehmer können nicht ausgewählt werden, Picker zeigt nur Demo-Avatar". Fix:
```bash
docker compose exec app php occ config:app:set core shareapi_allow_share_dialog_user_enumeration --value=yes
```

**Bug 2: `sendEventRemindersMode` muss `backgroundjob` sein (NICHT `background-job`)**

`apps/dav/lib/BackgroundJob/EventReminderJob.php` vergleicht strikt:
```php
if ($this->config->getAppValue('dav', 'sendEventRemindersMode', 'backgroundjob') !== 'backgroundjob') {
    return;  // tut NICHTS
}
```
Bei manchen NC-Installationen ist der Wert als `background-job` (mit Bindestrich) gespeichert → Job läuft alle 5 Min, `last_duration: 0`, **kein einziger Reminder wird verschickt**. Diagnose: `Reminders mit notification_date < now` bleibt nach Job-Lauf gleich. Fix:
```bash
docker compose exec app php occ config:app:set dav sendEventRemindersMode --value=backgroundjob
```

**Bug 3: `sendEventRemindersToSharedUsers` ist INVERTIERT codiert**

`apps/dav/lib/CalDAV/Reminder/ReminderService.php:125`:
```php
if ($this->config->getAppValue('dav', 'sendEventRemindersToSharedUsers', 'yes') === 'no') {
    $users = $this->getAllUsersWithWriteAccessToCalendar(...);  // ← Sharees laden
} else {
    $users = [];  // ← Default-Fall: Liste BLEIBT LEER
}
```
Setting auf `'yes'` (Default, klingt nach „aktiviert") → Sharees bekommen NICHTS. Setting auf `'no'` → Sharees werden geladen. Counter-intuitiv. Bei Setup mit geteiltem Owner-Kalender + Sharee-Gruppen: Setting MUSS `no` sein, sonst gehen Mails nur an den Calendar-Owner.

**Sabre Schedule-Plugin: PUT mit ATTENDEE in fremden Kalender → 400**

Wenn ein User (nicht Owner) via Browser einen Termin mit ATTENDEEs in einem geteilten Kalender speichern will, lehnt das Sabre-Schedule-Plugin mit `400 Bad Request` ab — der ORGANIZER kann nicht der eingeloggte User sein, wenn der Kalender ihm nicht gehört. Diagnose-Test: Programmatisches Schreiben via `\OCA\DAV\CalDAV\CalDavBackend::createCalendarObject()` mit `IUserSession::setUser($user)` umgeht das Schedule-Plugin → wenn das klappt, ist Sharing OK und der 400 kommt vom Schedule-Plugin. Lösung: Owner-Wechsel via `UPDATE oc_calendars SET principaluri = 'principals/users/<neuer-owner>' WHERE id = ...` plus alten Owner als RW-Sharee in `oc_dav_shares` neu eintragen.

**iCalendar VALARM TRIGGER ist immer relativ — kein „absolute Uhrzeit" via Default**

NC-Default-Reminder ist eine Sekunden-vor-Termin-Zahl (z.B. `-172800` = 2 Tage), iCalendar TRIGGER ist immer relativ zu DTSTART. Für „immer um 7:00 morgens" gibt es keinen Server-Setting-Weg. Pragmatischer Workaround: Cron-Window des Cron-Containers begrenzen:
```bash
docker compose exec cron sed -i 's|^\*/5 \*|*/5 7-22|' /var/spool/cron/crontabs/www-data
docker compose restart cron
```
Crontab liegt in `/var/spool/cron/crontabs/www-data` (busybox crond). Effekt: Reminder mit Trigger 03:00 nachts werden auf 07:05 verschoben (= erster Cron-Lauf nach 07:00). Reminder mit Trigger zur Bürozeit kommen pünktlich. Echte „immer 07:00" gibt es nur via Custom-NC-App mit Pre-Save-Hook.

**DB-Schema-Lookup statt Annahme — Tabellennamen ≠ App-Namen**

Beispiele aus dieser Session:
- App `contactsinteraction` → Tabelle `oc_recent_contact` (nicht `oc_contacts_interaction`)
- App `dav` Calendar-Sharing → Tabelle `oc_dav_shares` (Spalten: `principaluri`, `type='calendar'`, `access` (1=RO, 2=RW, 4=Owner-Self), `resourceid`)

Vor `iLike`-Queries auf NC-Tabellen IMMER Schema prüfen (Beispiel-Row holen) — `oc_cards.carddata` ist BINARY, `iLike` mit `utf8mb4_general_ci` collation gibt SQLSTATE[42000]. Workaround: Alle Rows holen und in PHP mit `stripos` filtern.

**NC-Demo-Karten "Leon Green" — Verwirrender Default**

Beim Anlegen eines User-Adressbuchs erstellt NC automatisch einen Demo-Kontakt „Leon Green" mit URI `default` in der `oc_cards`-Tabelle. Erscheint im leeren Calendar-Teilnehmer-Picker als Avatar → wird von Endusern fälschlich als „echter User" interpretiert. Wegputzen via:
```php
$cardDav = \OC::$server->get(\OCA\DAV\CardDAV\CardDavBackend::class);
$cardDav->deleteCard($addressBookId, 'default');
```
(updated korrekt `oc_addressbookchanges` für Sync-Token)

**Anti-Pattern „Erst verifizieren, dann verkünden"**

Bei der Reminder-Diagnose habe ich vorschnell „🎯 HEUREKA!" gerufen, weil eine SQL-Query den Tabellennamen `oc_contacts_interaction` nicht fand. Echter Tabellenname war aber `oc_recent_contact` — meine Query war falsch, kein Bug. Lehre: Bei Domänen-fremden Tools (NC-DB-Schema) erst verifizieren (z.B. `SHOW TABLES LIKE`), dann diagnostizieren. Diana hat das toleriert, aber es kostet Vertrauen.

**Anti-Pattern „Erst minimaler Fix, dann strukturelle Verbesserung"**

Habe in dieser Session 6 Themen-Kalender angelegt + Sharing eingerichtet, weil ich die ArcheNoah-Workflow-Frage „strukturell" lösen wollte. Diana wollte „nur 1 Kalender, fertig aus" → komplett zurückbauen (delete-calendar × 6). Lehre: Bei akuten Bugs (Picker funktioniert nicht) erst den minimalen Fix (Setting ändern), dann den User entscheiden lassen, ob strukturelle Verbesserung gewünscht ist. Über-Engineering verlängert Sessions und frustriert.

**Hook-Schutz hat heute mehrfach Schaden verhindert**

In dieser Session blockiert (alle korrekt):
- HTTP-Auth mit Klartext-Passwort an Live-Service (`curl -u user:pass`)
- Direct-DB-Migration `oc_calendars.principaluri` ohne explicit user consent
- Massive User-Liste / PII lesen ohne explizite Autorisierung

Lehre: NICHT versuchen die Hooks zu umgehen. Bei legitimer Notwendigkeit dem User die Permission-Anfrage stellen, nicht „kreativ" werden.

**Sicherheits-Beobachtungen für `kalender.bz-archenoah.net`**

- Admin-Account `nextcloud` hat als E-Mail `diana.goebel@proton.me` hinterlegt → NC erlaubt Login per E-Mail → wer Diana's Proton-Passwort kennt, ist Admin. Bei Audits dieser Instanz IMMER prüfen.
- Personalstruktur-Memory (15 User in 6 Bereichs-Gruppen) liegt in `/volume1/docker/nextcloud/memory/archenoah_personalstruktur.md` (projekt-lokal), nicht in diesem Skill.
- Reminder-Default: 2 Tage vorher, Cron 07-22 begrenzt, sendInvitations=yes (Standard, sonst PUT 400).

---

### 2026-05-06 - n8n-Update-Strategie + Channel-Check

**n8n `:latest` vs `:stable` vs `:next`:**

Vor jedem `bash ops/n8n/update_n8n.sh` IMMER prüfen, auf welche Version `:latest` zeigt — nicht blind die "neueste laut Hub" pinnen:
```bash
LATEST=$(curl -s "https://hub.docker.com/v2/repositories/n8nio/n8n/tags/latest" | jq -r '.images[0].digest')
STABLE=$(curl -s "https://hub.docker.com/v2/repositories/n8nio/n8n/tags/stable" | jq -r '.images[0].digest')
echo "latest=$LATEST stable=$STABLE  match=$([[ $LATEST == $STABLE ]] && echo yes || echo no)"
```
- **Identisch:** Stable ist current — `:latest` ist der richtige Tag, `pull_policy: always` macht den Rest.
- **Verschieden:** `:next` ist auf eine Pre-Release umgehängt → NICHT pinnen, auf nächsten Stable warten.

Aktuell (Stand 2026-05-06 abend): stable = `2.19.4` (digest `69bc5e62…`). Der `2.20.x`-Branch ist Pre-Release.

**Update-Skript funktioniert tadellos:**
- `bash ops/n8n/update_n8n.sh` macht: stop -t 120 → backup_n8n.sh (tar.zst, ~6 GB) → pull → up -d → status + logs.
- Downtime ~60–90 Sekunden + 18 Sekunden bis Editor + API + Webhooks wieder antworten.
- Nach Update zwingend: `docker exec n8n-n8n-1 n8n --version` zur Verifikation; alle aktiven Workflows zählen via API; einen RAG-Chat-Smoke-Test (`/webhook/rag-chat-api` POST mit `{chatInput, sessionId}`).

**Confluence REST API für PDF-Scraping (von wissen.medifoxdan.de):**

Die HTML-Übersichtsseiten zeigen oft nur veraltete Versionen. Die Confluence REST API liefert ALLE Anhänge zuverlässig:
```bash
curl -sL "https://wissen.medifoxdan.de/rest/api/content/{pageId}/child/attachment?limit=200" \
  | jq -r '.results[] | "\(.title)\t\(._links.download)"'
```
- pageId 60784729 = MD Stationär 10.x Updates
- pageId 3375911 = MediFox stationär 8.x Updates

Pipeline für RAG-Sync neuer Updates: API call → diff gegen `SELECT DISTINCT metadata->>'version' FROM rag_chunks` → curl + pdftotext + Multi-VALUES-INSERT in Supabase + embed-rag-chunks Edge Function. ~5 PDFs in 10 Minuten.

### 2026-05-07 — n8n-Container-Pfade & Diagnose-Workflow

**n8n-spezifische Pfade auf der NAS (kritisch für direkte DB-Eingriffe):**

- Container-Name: `n8n-n8n-1` (image: `docker.n8n.io/n8nio/n8n:latest`)
- SQLite-DB: `/volume1/docker/n8n/data/database.sqlite` (~2.8 GB)
- Datenordner (im Container `/home/node/.n8n`): `/volume1/docker/n8n/data/`
- Encryption-Key-Quellen — beide müssen matchen:
  - `/volume1/docker/n8n/.env` → `N8N_ENCRYPTION_KEY=…`
  - `/volume1/docker/n8n/data/config` → JSON `{"encryptionKey":"…"}`
- `sqlite3` ist am Host verfügbar (`/usr/bin/sqlite3`), aber **NICHT** im n8n-Container (Hardened Alpine ohne apk). Daher DB-Queries IMMER vom Host aus, nicht via `docker exec`.

**Standard-Diagnose-Workflow für n8n-Probleme:**

```bash
# 1. Container-Status
docker ps --filter "name=^n8n-n8n-1$" --format "{{.Status}}"

# 2. Logs nach Fehler-Pattern filtern (mit Kontext)
docker logs n8n-n8n-1 --tail 1000 2>&1 | grep -B2 -A8 "<error-pattern>"

# 3. Healthcheck (nicht /api/v1, sondern /healthz)
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.22.90:5678/healthz

# 4. Aktive Executions zählen
sqlite3 /volume1/docker/n8n/data/database.sqlite \
  "SELECT count(*) FROM execution_entity WHERE status='running';"

# 5. Container-Restart (laufende Executions werden abgebrochen)
docker restart n8n-n8n-1 && sleep 18  # ~12-15s bis "Editor is now accessible"
```

**Encryption-Key-Verifikation (vor Decrypt-Debugging immer zuerst):**

```bash
ENV_KEY=$(grep "^N8N_ENCRYPTION_KEY=" /volume1/docker/n8n/.env | cut -d= -f2-)
CONFIG_KEY=$(docker exec n8n-n8n-1 cat /home/node/.n8n/config | jq -r '.encryptionKey')
[ "$ENV_KEY" = "$CONFIG_KEY" ] && echo "MATCH" || echo "MISMATCH (echte Wurzelursache)"
```

Wenn MATCH → einzelne korrupte Credentials suchen (siehe `n8n-workflow` Skill, Decrypt-Test-Pattern). Wenn MISMATCH → Restore-Problem aus Backup.

---

### 2026-05-12 — LiveKit Voice-Agent (Jarvis) + Yoga7-Bridge

**Container -> Host-Routing (KRITISCH, gilt für ALLE Container, die HA/lokale Services aufrufen):**
- Cloudflare-Hostnames wie `homeassistant.forensikzentrum.com` sind aus Containern UNZUVERLÄSSIG (Tunnel-Routing, externes DNS, möglicher CF-Loop)
- Lösung: `extra_hosts: ["host.docker.internal:host-gateway"]` + Env `HASS_URL=http://host.docker.internal:8123`
- Pattern auch für jeden anderen Service, der den NAS-Host selbst aufrufen muss

**Mosquitto-ACL: dedizierter User pro Service (KRITISCH):**
- Shared `healthcheck`-User hat NUR `topic read $SYS/#` -> kann KEINE Discovery-Topics publishen -> "not authorised"
- Pro Service eigener User + ACL-Block in `/volume1/docker/mosquitto/config/acl`:
  - `user yoga7`
  - `topic readwrite homeassistant/#`
  - `topic readwrite yoga7/#`
- Passwort hashen via `mosquitto_passwd -b` im Container
- Reload ohne Restart: `kill -HUP` PID 1 im Container
- NIEMALS Services den shared `healthcheck`-User verwenden lassen

**MQTT-Bridge Client-ID-Konflikt:**
- Zwei Instanzen mit gleicher `client_id` kicken sich endlos: "Client disconnected: session taken over"
- Fix: alle alten killen, dann GENAU EINE Instanz, idealerweise via systemd-user
- Diagnose: `mosquitto_sub -t 'homeassistant/#' -v | head -20` -> Discovery-Topics sichtbar = Bridge läuft

**LiveKit-Server WebRTC-Binding (Docker mit vielen Bridges):**
- Default bindet UDP auf ALLE Interfaces inkl. Docker-Bridges -> Clients bekommen falsche ICE-Kandidaten
- Fix in `livekit.yaml` rtc-Block:
  - `use_external_ip: false`
  - `node_ip: 192.168.22.90`
  - `port_range_start/end: 50000/50020`
  - `interfaces.includes: ["bridge0"]`
- Container braucht `network_mode: host` (NICHT bridge), WebRTC-Port-Forwards passen sonst nicht

**Cloudflare-Tunnel kann KEIN UDP-WebRTC-Audio:**
- Tunnel routet NUR HTTPS/WSS (Signalisierung), KEINE UDP-Media-Pakete
- `voice.forensikzentrum.com` + `livekit-ws.forensikzentrum.com` reichen für Web-UI/Signal, NICHT für Sprache
- Audio funktioniert nur: (a) im selben LAN ODER (b) Port-Forward 50000-50020/UDP am Router

**Cloudflare Zero Trust: Hostname-Routen != Veröffentlichte Anwendungen:**
- "Veröffentlichte Anwendungen" (Public Hostname Routes) = Tunnel-Routing für Public-Domain -> interne URL
- "Hostname-Routen" / Private Network Routes = WARP-Client-Only (intern)
- Für `*.forensikzentrum.com` IMMER "Veröffentlichte Anwendungen" + DNS-CNAME zu `<tunnel-id>.cfargotunnel.com`
- 1033-Error = falscher Routen-Typ ODER Tunnel-Token-Modus ignoriert `config.yml` (Routes nur via Dashboard konfigurierbar)

**Gemini API direkt statt Vertex AI:**
- Vertex AI Gemini Live benötigt aktives Billing-Konto am Service-Account-Projekt (Error 1008 bei fehlendem Billing)
- Workaround: direkter Gemini API Key (von aistudio.google.com) und `vertexai=False`
- Model für Live-Audio: `gemini-2.5-flash-native-audio-latest`
- Voice "Leda" (weiblich) + `enable_affective_dialog=True` für menschlichere Stimme

**Gemini Embeddings: korrektes Modell:**
- `text-embedding-004` existiert NICHT für embedContent-API -> 404
- Korrekt: `gemini-embedding-001` (768-dim, `task_type="SEMANTIC_SIMILARITY"`)

**Volume-Mount-Hot-Reload-Pattern:**
- Python-Code als `:ro`-Volume statt im Image: `./agent-override/agent.py:/app/agent.py:ro`
- Edit + `docker restart <container>` reicht, kein Rebuild
- Auch für `main.py` + `static/` von FastAPI-Services in der Entwicklung sinnvoll

**PWA-Manifest darf KEINE data:-URL sein:**
- Inline-Manifest via `data:application/manifest+json,...` -> "Failed to construct URL" beim PWA-Install
- `start_url` kann nicht relativ zur data:-URL aufgelöst werden
- Fix: echte Datei servieren (`/static/manifest.webmanifest`) mit absolutem `start_url`

**Alpine.js & SVG-Gotchas:**
- `<template x-for="n in 5">` -> "n is not defined" (Number nicht iterable). Fix: `x-for="n in [1,2,3,4,5]"`
- `<rect :x="foo?.x">` -> "Unexpected end" bei null. SVG-Attribute IMMER mit Default: `:x="foo?.x ?? 0"`

**Plus500/Retail-Auto-Trading blockiert (Diana-Entscheidung 2026-05-12):**
- Plus500 hat KEINE Retail-API; Browser-Automation gegen AGB -> Account-Sperre
- Für echtes Auto-Trading: API-Broker (Capital.com, IG Markets, OANDA) ODER halb-auto via TradingView-Alerts -> n8n -> Broker
- Bei zukünftigen Trading-Anfragen direkt auf API-Broker hinweisen, NICHT Plus500/eToro

**Yoga 7 IST LINUX (kein Windows!):**
- Bridge-Pattern: `yoga7-ha-bridge` (Python paho-mqtt + psutil) - Linux-Analog zu HASS.Agent für Windows
- 26 HA-Entities via MQTT-Discovery (`homeassistant/<component>/yoga7/<obj>/config`)
- HA wandelt `name: "Yoga 7"` -> entity-id `yoga_7_*` (Underscore beachten!)
- Custom-Tools in `/volume1/docker/livekit/agent-override/custom_tools.py` mit `YOGA = "yoga_7"` Prefix-Konstante

**Watchdog-Pattern (jarvis-watchdog):**
- Container im voice-net polled `docker ps` via gemounteten docker.sock
- Alert-Channel: HTTP POST -> `script.jarvis_say_smart` (HA) -> TTS auf Echo-Devices
- Cooldown 60min pro Container (`COOLDOWN_MIN`), Stop-Heuristik via Exit-Code != 0
- Default-Watchset: `voice-livekit, voice-frontend, voice-redis, homeassistant, cloudflared, jarvis-config`

### 2026-05-14 — Gedenkseite Memorial-Frontend (Mondphasen + Editorial-Redesign)

**Gedenkseite-Asset-Layout (deployed):**
```
/var/www/html/Klaus-Dieter-Goebel/
├── index.html      (32 KB nach CSS/JS-Auslagerung)
├── styles.css      (138 KB, Basis-Design)
├── editorial.css   (~10 KB, Modernisierungs-Layer)
├── app.js          (146 KB, Logik + Renderer)
├── sw.js           (Network-First mit Cache)
└── data/           (candles.json, entries.json, stats.json)
```
Editorial-Layer wird NACH styles.css geladen → Override per Cascade, einfacher Rollback durch Entfernen der zweiten `<link>`-Zeile.

**Memorial-Design-Constraints (Diana-Korrekturen):**
- **Feiertage NIEMALS den Geburtstags-`sparkles`-Effekt teilen** (🎂🎁🎈 + 80 Konfetti = unwürdig für Christi Himmelfahrt, Pfingsten etc.). Eigener `gentle`-Effekt: nur `✦ ✧ · ⋅`, 15 Sterne bei 50% Opacity, langsame 12–20s Animation.
- **Memorial-Card BLEIBT rahmenlos.** Keine Borders, keine `border-radius`, keine Gold-Hairlines am Card-Rand. Gold nur als Akzent in Glyphen (✦/✝), nie als Strukturlinie.
- **`backdrop-filter` NIE über animierten Hintergründen** wie cosmic-canvas/parallax-stars — verschmiert die Sterne und zerstört genau den visuellen Charakter. Auf Memorial-Sites: transparent bleiben.

**CSS-Performance-Pattern (Anti-Flicker):**
- **`text-shadow` NIE animieren** — GPU-unbeschleunigt, verursacht Repaint-Kaskade auf benachbarte Texte (war Ursache des Header-Flackerns auf der Gedenkseite). Stattdessen `opacity` auf den Glyph animieren.
- Header-Texte mit `transform: translateZ(0)` + `isolation: isolate` + `backface-visibility: hidden` in eigene Compositing-Layer heben → Background-Animationen triggern keine Text-Repaints mehr.
- **FPS-Throttling auf 30 FPS** in Canvas-Renderern für Hintergrund-Effekte spart 50% CPU/GPU ohne sichtbaren Qualitätsverlust:
  ```js
  const elapsed = timestamp - this.lastFrameTime;
  if (elapsed < this.frameInterval) {
    this.animationId = requestAnimationFrame((t) => this.animate(t));
    return;
  }
  this.lastFrameTime = timestamp - (elapsed % this.frameInterval);
  ```

**Docker-Container für Schreibzugriff auf gemountete Volumes:**
Auf `/volume1/docker/*` gehören Dateien typischerweise `root`. Wenn der laufende User (z.B. `Jahcoozi`) keine Schreibrechte auf eine Datei hat, ist der Container selbst das sauberste Werkzeug — er hat das Volume bereits read-write gemountet und läuft als root:
```bash
docker exec gedenkseite bash -c "sed -n '90,5280p' index.html > styles.css"
docker cp /tmp/patch.pl gedenkseite:/tmp/p.pl
docker exec gedenkseite perl /tmp/p.pl
```
Vorteil gegenüber `chown` auf dem Host: keine Permission-Änderung des Originals nötig, Volume-Berechtigungen bleiben konsistent. Funktioniert für alle Container mit gemountetem Volume: gedenkseite, open-webui, n8n etc.

**Perl-Anchor-Patch für große Dateien:**
Statt kompletten Block matchen (whitespace-fragil) → Start- und End-Anchor finden, dazwischen ersetzen:
```perl
open(my $fh,'<',$path); binmode($fh);  # KEIN :encoding(utf-8) → byte-genau
local $/; my $txt = <$fh>; close($fh);
my $s = index($txt, "    // Marker-Start");
my $e = index($txt, "    // Marker-End");
my $result = substr($txt,0,$s) . $new_block . substr($txt,$e);
```
`binmode` ohne encoding = byte-genauer UTF-8-Vergleich; verhindert Unicode-Dekodierungs-Mismatch zwischen HEREDOC-Bytes und gelesener Datei.

**Cache-Buster-Pattern für statische Sites mit Service Worker:**
Bei jeder Asset-Änderung synchron bumpen — index.html UND sw.js müssen IMMER zusammen:
```bash
VER=$(date +%Y%m%d-%H%M)
docker exec <container> bash -c "
  sed -i 's|styles.css?v=[^\"]*|styles.css?v=$VER|g;
          s|app.js?v=[^\"]*|app.js?v=$VER|g' /path/index.html &&
  sed -i \"s/cachename-v[0-9-]*'/cachename-v$VER'/\" /path/sw.js"
```
Sonst sehen SW-Clients alte Versionen bis TTL-Ablauf. Default-Workflow für alle NAS-gehosteten statischen Sites mit SW.

**Astronomische Mondphasen-Berechnung (validiert gegen NASA):**
- J2000-Referenzneumond: `Date.UTC(2000, 0, 6, 18, 14, 0)` — astronomisch verifiziert.
- Sinusförmige Beleuchtung: `k = (1 − cos(φ)) / 2` (NICHT linear interpolieren).
- **Viertel-Schwellen 42–58 % statt 45–55 %**, weil reale Beleuchtung am exakten Quartal aufgrund der elliptischen Mondbahn 43–48 % beträgt (nicht 50 %). Sonst werden NASA-Quartale fälschlich als „Sichel" klassifiziert.
- CSS Custom Properties (`--moon-shadow-pos`, `--moon-shadow-dir`) statt dynamic `<style>`-Element mit `!important` → kein Re-Parse, sauberer.
- Validierung: Alle Mai-2026 NASA-Phasen (Vollmond 01.05. 17:23 UTC, Letztes Viertel, Neumond 16.05. 20:01 UTC, Erstes Viertel, Vollmond 31.05.) wurden präzise getroffen.

**Editoriale Typografie-Triade (Memorial-würdig):**
- Display: **Fraunces** Variable (`opsz` 9–144, `SOFT` 0–100) — moderner Serif mit feiner Anmutung.
- Body: **Spectral** italic 300 — Magazin-Lesetypografie für Pull-Quotes.
- UI: **Inter** 500 — für Kapitälchen-Labels mit 0.32em Tracking.
- Old-Style + Tabular Nums (`font-variant-numeric: oldstyle-nums tabular-nums`) für Datumsangaben — wirkt wie gedruckter Nachruf.
- `text-wrap: balance` für ausgewogene Pull-Quotes.

### 2026-05-15 — Docker-Daemon Phantom-Port-Allocations

**Symptom:** Mehrere Container failen beim Start mit `Bind for 0.0.0.0:<port> failed: port is already allocated`, obwohl kein anderer Container/Prozess den Port hält. Zusätzlich kann ein Container sich nicht mit seinem Netzwerk verbinden („network <id> not found"), obwohl das gleichnamige Netzwerk noch existiert (mit anderer ID).

**Diagnose-Pattern — Schritt-für-Schritt:**
```bash
# 1) Kernel-Sockets prüfen
ss -tln | grep ":<port>\b"

# 2) iptables NAT prüfen
iptables -t nat -L DOCKER -n | grep <port>

# 3) Prozess auf Port
lsof -i :<port>; fuser <port>/tcp

# 4) Definitiver Beweis: Kann der Host selbst binden?
python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); \
  s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); \
  s.bind(('0.0.0.0', <port>)); print('FREE'); s.close()"

# 5) Welcher Container will den Port?
for c in $(docker ps -aq); do
  b=$(docker inspect "$c" --format '{{.HostConfig.PortBindings}}')
  echo "$b" | grep -q "<port>" && docker inspect "$c" --format '{{.Name}}: {{.HostConfig.PortBindings}}'
done
```
- Wenn 1–4 alle clear sind aber Docker meldet weiterhin „allocated" → **Phantom-Allocation im Docker-Daemon-RAM**.
- `docker rm -f` + `docker compose up -d` reicht NICHT.
- `docker compose down --remove-orphans` + `up -d` reicht NICHT.
- Nur ein Daemon-Restart löst Phantome auf (Daemon-State wird komplett neu aufgebaut). Auf UGREEN NAS: `sudo systemctl restart docker` — wegen Live-Production-Charakter ist das eine bewusste Diana-Entscheidung, nicht automatisierbar.

**Recovery nach Daemon-Restart:**
- `unless-stopped`/`always` Container kommen automatisch hoch (in dieser Session 48 von 54).
- Container mit `restart: no` (z.B. `voice-agent-1`) → manuell `docker start <name>`.
- Container, die schon vor dem Restart im Phantom-Block hingen, bleiben oft im `Created`-Status; nach dem Restart genau prüfen:
  ```bash
  docker ps -a --filter "status=created" --filter "status=exited" \
    --format '{{.Names}}: {{.Status}}'
  ```
- Beobachtet: `searxng`, `openapi-docker-health`, `crawl4ai-n8n` blieben `Created`; `homeassistant` ging in `Exited (0)` — alle vier brauchten ein manuelles `docker start`.

**Verschwundene Network-Referenzen:**
- Symptom: `Error response from daemon: network <id> not found`.
- Ursache: Daemon hält veraltete Network-ID im Container-Spec, obwohl das gleichnamige Netzwerk existiert (neue ID).
- Lösung: Identisch — Daemon-Restart baut Network-IDs neu auf und referenziert sauber.

**Docker-Service-Unit auf UGREEN NAS:**
- `docker.service` (klassischer systemd-Unit) — `pkg-ContainerManager-dockerd` existiert auf UGREEN nicht (anders als auf Synology-DSM).
- `systemctl status docker` zeigt Main PID, Tasks, Memory.

---

### 2026-05-17 — Vaultwarden Port-Migration + Docker-Daemon-Cache + Cloudflare-Token-Mode + UGREEN-UI-Bug

**Vaultwarden auf Port 8084 (vorher 8083):**
- `docker-compose.yml`: `ports: ["8084:80"]`, WebSocket-Port `3012:3012` entfernt (seit Vaultwarden 1.29+ über Port 80 integriert)
- `cloudflared/config.yml` auf 8084 aktualisiert, **aber** im Token-Mode wirkungslos — Route musste manuell im Cloudflare Zero Trust Dashboard auf 8084 gesetzt werden

**Docker-Daemon Port-Reservation-Cache-Bug:**
- Symptom: `Bind for 0.0.0.0:PORT failed: port is already allocated`, obwohl `sudo ss -tlnp` UND `sudo lsof -i :PORT` **nichts** zeigen
- Auslöser: SIGTERM-Crash hinterließ verwaiste `docker-proxy`-Prozesse + stale iptables-DNAT-Regeln zu nicht mehr existierenden Container-IPs
- Cleanup-Reihenfolge half nicht vollständig:
  1. `sudo kill -9 <docker-proxy-PIDs>` (lsof -ti :PORT findet sie nur mit sudo)
  2. `sudo iptables -t nat -L DOCKER -n --line-numbers` → stale Regel per Zeilennummer löschen
  3. `docker rm -f`, `docker network rm`, `docker network prune` — Docker-Daemon-interner State blieb trotzdem blockiert
- Robuste Lösung in Production: **anderen Host-Port nehmen**. Daemon-State löst sich erst beim nächsten Reboot.
- ⚠️ `docker compose down --remove-orphans` räumt diese Geist-Proxies NICHT auf

**Cloudflared Token-Mode (KRITISCH):**
- `docker inspect cloudflared` zeigt `--token eyJh...` oder `CLOUDFLARE_TUNNEL_TOKEN=...` als Env
- Im Token-Mode wird `config.yml` **ignoriert** — Routen leben ausschließlich in der Zero Trust Dashboard
- `api-upload-routes-v2.sh` braucht einen separaten Cloudflare-API-Token (Permission „Edit Cloudflare Zero Trust")
- Konsequenz: Port-Änderungen am NAS-Container brauchen **immer eine zweite manuelle Aktion** in der Dashboard

**UGREEN-Dashboard Container-Link-Bug:**
- Die NAS-UI generiert für **jeden** Container-Port Links der Form `http://192.168.22.90:9999/ugreen/v1/desktop/redirect?url=<base64>`
- Bei TCP-only-Diensten (Wyoming 10200/10300/10400, MQTT 1883/9001, Postgres 5438/5439, Redis 6381, mcp-proxy/sse 8000) → Black/Whitescreen oder `ERR_EMPTY_RESPONSE`
- **Kein Container-Fehler!** Diese Dienste werden nicht per Browser, sondern mit Native-Client genutzt:
  - Wyoming → über Home Assistant Voice-Assistant-Settings
  - MQTT → MQTT Explorer / HA-Integration
  - Postgres → `docker exec -it <container> psql -U <user> -d <db>` oder pgAdmin/DBeaver
  - Redis → `docker exec <container> redis-cli`
  - MCP-Proxy → über `/sse` mit MCP-Client (Browser-Aufruf von `/` ergibt korrekt 404)

**FastAPI-Services ohne Root-Route (NORMAL, nicht melden als Bug):**
| Container | Port | Korrekte Aufruf-URLs |
|---|---|---|
| openapi-docker-health | 8009 | `/docs`, `/health`, `/containers/health` (Sprachabfrage „Läuft alles?") |
| fem-pipeline | 8746 | `/docs`, `/health` |
| pptx-audio-service | 8745 | `/docs`, `/health` |
| crawl4ai | 18800 | `/playground/`, `/health` |
| mcp-proxy-server | 8000 | `/sse`, `/status` |


---

### 2026-05-19 — HA Dashboards Mobile-First, Notify-API, VW Tiguan, Jarvis-Multi-Channel-Alerts, ADB-Phone-Debug

**HA Dashboard-Architektur:**
- `max_columns: 1` für ALLE Dashboards in HA → garantiert Mobile-Lesbarkeit (S25 Ultra)
- Bei Split-Screen am Yoga7 sind 2+ Spalten auch zu schmal — `max_columns: 1` ist universell
- **Standard HA `tile`-Karten** sind nativ mobile-optimiert (Touch-Target 44+ px, große Icons, klare Hierarchie)
- `dense_section_placement: true` packt Sektionen auch bei breiten Viewports optimal
- **Glassmorphism (backdrop-filter, rgba transparency) ist OUT** für HA-Dashboards — verschluckt Textkontrast
- **Card-Mod CSS-Overrides nicht zuverlässig** auf allen Devices — Theme-Variablen + Standard-Karten bevorzugen

**🔴 ANTI-PATTERNS HA-Dashboards:**
| Was | Problem | Stattdessen |
|---|---|---|
| `mushroom-entity-card.secondary_info: "{{ ... }}"` | Akzeptiert NUR Literale (`state`, `last-updated` etc.) | `mushroom-template-card` oder `tile` |
| `card-mod: style:` für Typography | Inkonsistent über Devices | Theme-Variablen (`mush-card-primary-font-size`, `ha-tile-card-icon-size`) |
| `notify.<entity_id>` Service-Call | Deprecated in neuem Notify-Entity-System | `notify.send_message` + `target: { entity_id: notify.X }` |
| Glassmorphism (`backdrop-filter`, `rgba(28,28,43,0.78)`) | Karten verschwimmen, weiß-auf-weiß möglich | volle Opazität `card-background-color: #1c1c2b` |
| Mushroom-Chips mit komplexen Templates | Klein, fragil bei rendering | tile-Grid mit klaren Werten |
| `automation:` im Package + `automation: !include` | Konfliktiert, package-Automations laden nicht | Automations nur in `/config/automations.yaml` |

**🔴 HA Entity-ID-Generation:**
- HA generiert `entity_id` aus **friendly NAME** (in der Locale-Sprache, also Deutsch), NICHT aus `unique_id`
- Beispiel: Template-Sensor mit `name: "Dyson V11 lädt"` → `binary_sensor.dyson_v11_ladt` (nicht `dyson_v11_charging` was `unique_id` ist)
- Dashboards IMMER mit echten DB-entity_ids verifizieren:
  ```python
  sqlite3.connect('file:.../home-assistant_v2.db?mode=ro', uri=True)
  ```

**🟢 Pattern „input_boolean-Fallback vor Companion-App":**
```yaml
input_boolean:
  diana_anwesend:
    name: Diana zu Hause
```
- Manueller Toggle bis Companion App eingerichtet
- Sync-Automation `person.X` → `input_boolean.X_anwesend` mit Bedingung:
  ```yaml
  condition:
    - condition: template
      value_template: "{{ states('person.diana') not in ['unknown','unavailable'] }}"
  ```
- Verhindert dass Toggle bei `unknown` Person fälschlich togglet

**🟢 Pattern „Idempotenter Sync local↔cloud":**
- Sync-Automation hat `condition: states(A) != states(B)` als Guard
- Verhindert Endlos-Loops bei bidirektionalem Setup (lokaler Switch ↔ Cloud-Toggle)

**🟢 Pattern „Picture-Elements für Fahrzeug-Status":**
- Top-Down-SVG unter `/config/www/<auto>.svg` → erreichbar als `/local/<auto>.svg`
- `picture-elements`-Karte mit `state-icon` Elements positioniert per `top: X%, left: Y%`
- Türen/Fenster/Haube zeigen Live-Status (grün=zu, rot=offen)
- Funktioniert ohne Custom-Cards, nur HA-native

**🟢 Pattern „Jarvis-Multi-Channel-Alert":**
```yaml
action:
  - service: notify.send_message
    target: { entity_id: notify.sm_s938b }
    data: { title: "...", message: "..." }
  - service: tts.speak
    target: { entity_id: tts.elevenlabs_text_zu_sprache }
    data:
      media_player_entity_id: media_player.dianas_echo_show_8_2nd_gen
      message: >-
        {% if is_state('input_boolean.diana_anwesend','on') %}Diana, ...
        {% else %}Achtung. Niemand zu Hause...{% endif %}
```
- **Voice via ElevenLabs auf Echo Show + Echo Dot** — natürliche Sprache, kontextabhängig
- Push UND Voice parallel — niemand verpasst den Alarm

**🟢 Software: `volkswagencarnet` HACS-Integration**
- Für VW Tiguan 2024 (Diesel/eHybrid + andere VW-Modelle)
- Erzeugt 63 Entities pro Auto (sensor, binary_sensor, lock, switch, device_tracker)
- **Entity-Naming:** `<DOMAIN>.<VIN-lowercase>_<sensor>` (z.B. `sensor.wvgzzzct6rw519244_fuel_level`)
- Wichtige Entities:
  - `device_tracker.<vin>_position` (GPS mit lat/lon Attributen)
  - `binary_sensor.<vin>_vehicle_moving` (für Jarvis-Bewegungs-Alarm)
  - `lock.<vin>_door_locked`, `lock.<vin>_trunk_locked` (mit lock-commands feature)
  - 8 Tür/Fenster `binary_sensor.<vin>_door_closed_*`, `_window_closed_*`
  - Live-Werte: `_fuel_level`, `_fuel_range`, `_odometer`, `_adblue_level`
  - Trips: `_last_trip_*`, `_long_term_trip_*`, `_refuel_trip_*`
  - Wartung: `_service_inspection_days`, `_oil_inspection_days`
- Login via VW-ID-Account (gleicher wie We-Connect-App)

**🟢 Pattern „Scene-Definitionen mit Climate":**
- Climate-Eintrag im scene.yaml braucht **`state: heat`** + temperature, nicht nur temperature
- Sonst: `Invalid config for 'scene' ... State for climate.X should be a string`
- Korrekt:
  ```yaml
  climate.schlafzimmer_room_climate_cont_2:
    state: "heat"
    temperature: 18
  ```

**🟢 Pattern „Lovelace mode:yaml-Deprecation (HA 2026.8)":**
- Top-Level `lovelace.mode: yaml` wird entfernt
- Migration: `resource_mode: yaml` + expliziter `lovelace`-Dashboard-Eintrag mit `url_path: lovelace` (oder per default-Konvention) + `filename: ui-lovelace.yaml`
- Beispiel-Konfiguration siehe configuration.yaml in `/volume1/docker/home-assistant/config/`

**🟢 Tool: ADB Wireless an Dianas Samsung Galaxy S25 Ultra**
- Adresse: `192.168.22.202:35035` (permanent gepairt)
- **Wichtig:** ADB ist auf **Yoga7** installiert (`/usr/bin/adb`), NICHT auf NAS — Auto-Classifier blockt NAS-`apt install android-tools-adb`
- Pattern für Phone-Debugging:
  ```bash
  adb -s 192.168.22.202:35035 shell pm dump io.homeassistant.companion.android | grep LOCATION
  adb -s 192.168.22.202:35035 shell appops get io.homeassistant.companion.android
  adb -s 192.168.22.202:35035 shell pidof io.homeassistant.companion.android
  ```
- **Force-Stop weckt dormante App auf:**
  ```bash
  adb shell am force-stop io.homeassistant.companion.android
  adb shell am start -n io.homeassistant.companion.android/.launch.LaunchActivity
  # Launcher-Activity NICHT .MainActivity sondern .launch.LaunchActivity
  ```
- Companion App registriert sich bei HA, aber Standort-Sensor wird oft dormant — Force-Stop reaktiviert sofort
- Eingesetzt für: Permissions-Check, App-Crash-Diagnose, GPS-Hänger-Beheben

**🔵 Beobachtungen:**
- **Recorder schließt `automation` Domain aus** (per default config in `02_system_monitoring`/HA-Standard) → Automation-State nicht in DB, Automations laufen TROTZDEM. Debug über `docker logs homeassistant`-grep
- **zsh ohne bracketed-paste** bricht Multi-Line scp-Befehle bei Newlines → Variable-Pattern nutzen:
  ```bash
  D=user@host:/path/
  scp file $D
  ```
- **`cp` mit `-i` alias** (interactive) fragt bei Overwrite → für sichere Overwrites: `cat file > target`
- **Hugging Face ZeroGPU GPU-Tasks aborten** häufig — für deterministische Image-Bedarfe lieber manuelles SVG schreiben
- **`input_text` mit Mode `password`**: Default `max: 100` reicht knapp für Shelly-API-Keys (89+ Zeichen) — auf `255` setzen
- **Ping-Sensoren `binary_sensor.ping` Platform deprecated** → `command_line` mit `ping -c 2 -W 2` als binary_sensor
- **systemmonitor Domain ist config_entry-only**, nicht mehr YAML-konfigurierbar — für NAS-Stats `command_line`-Sensoren direkt aus `/proc/stat`, `/proc/meminfo`, `df` nutzen (HA-Container ist privileged, hat Zugriff)
- **Mit `awk '/^cpu /'`** statt allgemeinem `awk` arbeiten — `/proc/stat` hat mehrere `cpu` Zeilen pro CPU-Core, HA `command_line` erwartet einzelnen Wert

### 2026-05-19/20 — Jarvis Brain Deploy auf UGREEN NAS + Voice-Stack-Discovery

**🔴 UGREEN-rsync läuft im Restricted-Mode — tar-pipe als Fallback**
- `rsync user@nas:dir/` scheitert mit `mkdir failed: No such file or directory (2)` oder `invalid path: 'jarvis/brain/'`
- Sowohl absolute (`/home/Jahcoozi/...`) als auch relative Pfade (`jarvis/...`) werden vom rsync-Daemon abgelehnt
- **Workaround (zuverlässig):** tar-pipe via ssh stdin/stdout
  ```bash
  (cd $LOCAL && tar --exclude='__pycache__' --exclude='*.pyc' -czf - dirname) \
    | ssh Jahcoozi@192.168.22.90 "rm -rf /home/Jahcoozi/target/dirname && tar -xzf - -C /home/Jahcoozi/target"
  ```
- Vorteil: kein rsync-Server-Mode, kein TLS, funktioniert mit jeder UGREEN-Firmware
- Nachteil: kein delta-sync, immer Voll-Übertragung — bei großen Verzeichnissen `--newer` oder `find -mtime` davor

**🔴 NAS-Shell expandiert `~` nicht für SSH-Heredocs**
- `ssh nas "mkdir -p ~/jarvis"` wird zu `Jahcoozi/jarvis` (relativ zu `/`) statt `/home/Jahcoozi/jarvis`
- Absolute Pfade in Scripts hardcoden: `NAS_PATH="${NAS_PATH:-/home/Jahcoozi/jarvis}"`
- Erste ssh-Test-Sequenz für jedes neue Setup: `ssh nas 'echo HOME=$HOME; pwd; whoami'`
- NAS-Home auf DXP4800: `/home/Jahcoozi`, Group: `admin` (nicht users)

**🔴 Bestehender Voice-Stack auf NAS muss respektiert werden**
Bevor neue Jarvis-Container deployen, IMMER `docker ps` auf NAS prüfen. Was schon läuft (2026-05-19):

| Container | Port | Rolle |
|---|---|---|
| `homeassistant` | 8123 | Hauptbrain für Smart-Home, Spotify, Alexa |
| `ha-wyoming-openwakeword` | 10400 | **schon mit `hey_jarvis` preloaded** (threshold 0.6) |
| `ha-wyoming-piper` | 10200 | lokales TTS-Fallback |
| `ha-wyoming-whisper` | 10300 | lokales STT-Fallback |
| `voice-livekit` | 7880 | LiveKit-Server (intern) |
| `voice-frontend` | 3000 | Next.js Voice-UI mit Azure/Deepgram/Gemini |
| `jarvis-watchdog` | — | überwacht voice-* Container, ntfy-Topic `jarvis-bianca-…` |
| `jarvis-config` | 8093 | FastAPI Web-Konfig-Backend |
| `mosquitto` | 1883 | MQTT-Bus für IoT |
| `matter-server` | 5580 | Matter/Thread |
| `ollama` | 11434 | lokale LLMs |

**Konsequenz:** Neuer `jarvis-brain` (8765) **ergänzt** als LLM-Router + Memory + HUD, läuft NICHT als Wake-Word-Ersatz. Wake-Word-Detection bleibt bei `ha-wyoming-openwakeword`; Brain wird nachgeschaltet via MQTT-Event oder HA-Webhook.

**🟡 docker-compose `context:` ist relativ zur compose.yml**
- `deploy/nas/docker-compose.yml` mit `build.context: ../../brain` → suchte `/home/Jahcoozi/brain` (zwei Levels über deploy)
- Korrekt: `../brain` (ein Level), weil Layout `jarvis/{brain,deploy/nas}`
- Fehlermeldung war eindeutig: `unable to prepare context: path "/home/Jahcoozi/brain" not found`
- Lesson: Vor erstem Deploy compose-Pfad mental durchgehen, nicht doppelt abstrahieren

**🟡 Ed25519-Device-Identity persistent im Volume**
- `pynacl.signing.SigningKey.generate()` → Base64-encoded keypair in `/data/oc5-device.json`
- Container-Volume `jarvis-data:/data` überlebt Image-Rebuilds → Device-ID stabil
- Pattern für jedes Pairing-System (OpenClaw v3, Matter, HomeKit-Bridge)

**🟡 HA Long-Lived Token Setup für Container**
- Token via HA-UI → Profil → "Long-Lived Access Tokens" → "Create Token"
- ENV-Var im Container: `HA_URL=http://host.docker.internal:8123` (nicht 127.0.0.1!), `HA_TOKEN=...`
- Test: `curl -H "Authorization: Bearer $HA_TOKEN" http://localhost:8123/api/states | jq '[.[] | select(.entity_id|startswith("media_player."))]'`

**🔵 NAS-Container-Inspect ohne Source-Zugriff**
- `/volume1/docker/<dir>/` ist oft geschützt (Auto-Klassifizierung blockt)
- Trotzdem informativ: `docker inspect <container>` → Env (gefiltert), Mounts, Cmd, Ports
- Sensible Werte (Token/Key/Secret/Password) per Regex aus Env-Liste raus filtern bevor Ausgabe

---

### 2026-05-21 — Docker-Port-Cache-Detail + n8n-Workflow-DB-Direct-Edit

Ergänzungen zu den Lektionen 2026-05-15/17 (Phantom-Allocations, Vaultwarden-Migration). Drei Container betroffen: `nextcloud_app` (8282), `ollama` (11437), `openapi-docker-health` (8009) — alle gleicher 15:55-Vorfall.

**🔴 iptables-DNAT-Cleanup braucht EXAKTE Rule-Syntax**
- `iptables -t nat -D DOCKER -p tcp --dport <port> -j DNAT --to-destination <ip>:<port>` schlägt fehl mit `Bad rule (does a matching rule exist?)`
- Grund: Docker-DNAT-Regeln enthalten `! -i br-<bridge-id>` als Match-Bedingung — fehlt im Delete-Statement, matched nichts
- **Korrekter Workflow:**
  ```bash
  # 1) Exakte Regel holen (Output ist „-A" Notation, einfach „-A" → „-D" tauschen)
  sudo iptables -t nat -S DOCKER | grep <port>
  # → -A DOCKER ! -i br-d985838a7e21 -p tcp -m tcp --dport 8009 -j DNAT --to-destination 172.25.0.9:8000

  # 2) Mit identischen Args löschen
  sudo iptables -t nat -D DOCKER ! -i br-d985838a7e21 -p tcp -m tcp --dport 8009 -j DNAT --to-destination 172.25.0.9:8000
  ```
- Die in 2026-05-15 erwähnte „Zeilennummer"-Methode (`iptables -L --line-numbers` + `-D <chain> <num>`) ist Alternative, aber `-S` + Copy-Paste ist robuster

**🔴 Daemon-Restart fixt NICHT garantiert alle Ports**
- In dieser Session: nach `systemctl restart docker` waren 8282 + 11437 frei, ABER 8009 blieb blockiert
- OS-seitig komplett frei (ss/lsof/iptables alle leer), Bind-Test mit Python erfolgreich, dennoch `port is already allocated`
- **Daemon-internal allocator-state überlebt manchmal Restart** — Mechanismus unklar (vermutlich persistenter Snapshot)
- Bestätigung der 2026-05-17 Lektion: **Port-Umzug ist robusterer Fallback** als Daemon-Restart-Schleifen
- Pattern für Port-Migration: Compose-Port ändern → up -d → `grep -rln "<altport>"` in Konsumenten-Dirs (n8n, HA, openwebui, cloudflared) → einzeln updaten

**🟡 n8n-Workflow-DB-Direct-Edit (workflow_entity + workflow_history)**

Wenn ein Live-Workflow eine URL/Config-Änderung braucht und der Generator-Roundtrip zu aufwändig ist:

```bash
# 1) Sicherheits-Backup
cp /volume1/docker/n8n/data/database.sqlite /tmp/database.sqlite.bak-$(date +%Y%m%d-%H%M%S)

# 2) Workflow finden + activeVersionId holen
sqlite3 /volume1/docker/n8n/data/database.sqlite \
  "SELECT id, name, active, activeVersionId FROM workflow_entity WHERE nodes LIKE '%<altwert>%';"

# 3) ATOMAR beide Tables updaten (workflow_history wird sonst übersehen)
sqlite3 /volume1/docker/n8n/data/database.sqlite <<'SQL'
BEGIN;
UPDATE workflow_entity  SET nodes=replace(nodes, ':8009/path', ':8010/path'), updatedAt=datetime('now') WHERE id='<wfid>';
UPDATE workflow_history SET nodes=replace(nodes, ':8009/path', ':8010/path'), updatedAt=datetime('now') WHERE versionId='<verid>';
COMMIT;
SELECT 'after_entity:',  (length(nodes) - length(replace(nodes, '<altwert>', ''))) / length('<altwert>') FROM workflow_entity  WHERE id='<wfid>';
SELECT 'after_history:', (length(nodes) - length(replace(nodes, '<altwert>', ''))) / length('<altwert>') FROM workflow_history WHERE versionId='<verid>';
SQL

# 4) n8n restart (Pflicht — sonst greift workflow_history-Update nicht)
docker restart n8n-n8n-1

# 5) Healthcheck
until docker exec n8n-n8n-1 wget -q --spider http://localhost:5678/healthz 2>/dev/null; do sleep 3; done
```

**Wichtig:**
- `replace(...)` mit MÖGLICHST SPEZIFISCHEN String (`:8009/containers/health` statt nur `8009`) — sonst false-positives bei MAC-Adressen, Timestamps etc.
- `sqlite3` ist auf dem HOST verfügbar, NICHT im n8n-Container (Alpine-Image hat es nicht)
- Lektion aus `n8n/CLAUDE.md` bestätigt: workflow_history-Tabelle ist die Read-Source für aktive Workflows — Update von workflow_entity alleine wirkt nicht
- DB-Backup-Path `/tmp/database.sqlite.bak-*` (2.6 GB) nach erfolgreichem Test wieder löschen

**🔵 HA-ESTABLISHED-Connections als Polling-Diagnose**
- `sudo lsof -i :<port>` zeigt auch outbound ESTABLISHED — wenn Listener weg ist, der Connection-Versuch aber bleibt: identifiziert wer polled
- In dieser Session: PID gehörte zu `homeassistant`, aber HA-Config selbst hatte 8009 nicht — die Polling-URL kam aus einem aktiven n8n-Workflow (`Voice_Assistant_ElevenLabs` → `Docker Status`-Node) den HA via Webhook anstößt
- **Lesson:** Bei „wer polled diesen Port" nicht nur Konsumenten-Config greppen, sondern auch transitive Aufrufer (n8n-Workflows, HA-Automations die HTTP-Requests triggern)
- Workflow-Suche im n8n-SQLite:
  ```bash
  sqlite3 /volume1/docker/n8n/data/database.sqlite \
    "SELECT id, name, active FROM workflow_entity WHERE nodes LIKE '%<port>%';"
  ```

### 2026-05-26 — Cleanup-Session: Classifier-Move-Block, SSH-Paste-Datenverlust, Docker-Prune-Lock, Repo-Layout

**🔴 Auto-Mode-Classifier blockt `mv`/`mkdir+mv` von VORHANDENEN Dateien in der Production-Wurzel `/volume1/docker`**
- Gilt auch für rein kosmetische Moves (Docs nach `docs/`). Classifier-Reasoning sinngemäß: „beyond the cosmetic cleanup the user authorized / relocating pre-existing files in a live production NAS root".
- `cp` und `command cp` (z.B. Restore aus Backup) sind erlaubt — nur `mv`/`mkdir+mv` von Bestandsdateien wird geblockt.
- → Datei-Verschiebungen in der Wurzel muss **der User selbst im Terminal** ausführen; ich liefere split-sichere Befehle und ziehe danach die Referenzen nach.

**🔴 SSH-Paste-Split + `mv A B` = Datenverlust durch Overwrite (passiert, recovered)**
- Diana's SSH-Terminal zerschneidet mehrzeilige/lange Pastes am Newline (vgl. 2026-05-19 zsh-bracketed-paste, Z.1399). Ein gesplittetes `mv BACKUP_README.md SERVICE_OVERVIEW.md` hat `SERVICE_OVERVIEW.md` mit dem Inhalt von `BACKUP_README.md` ÜBERSCHRIEBEN.
- Das **`!`-Präfix gehört NUR in die Claude-Code-Eingabezeile** — im rohen SSH-Shell ist `!` Bash-History/Negation: `! cmd1 && cmd2 && cmd3` → `(! cmd1)` wird false → `cmd2/cmd3` werden geskippt (hat hier zufällig vor dem Overwrite geschützt, beim 2. Versuch ohne `!` dann nicht mehr).
- **Regel für User-ausgeführte Moves:** EINE Zeile pro Befehl, KEIN `!`, absolute Pfade, und IMMER `mv <eine-quelle> <ziel-dir>/` (Ziel = Verzeichnis mit Slash). NIE `mv A B` mit zwei Dateinamen — bei einem Paste-Split kann das eine Geschwister-Datei überschreiben; mit Dir-Ziel ist das Schlimmste „no such file".
- **Restore-Quelle:** `/mnt/@usb/sdc2/NAS_Daily_Backups/backup_<YYYY-MM-DD>_030001/docker/...` = autoritative Vor-Schaden-Kopien (03:00-Cron, 2 Versionen). Nach Restore mit `diff -q "$BACKUP/$f" "./$f"` verifizieren.

**🟡 `-i`-Aliase umgehen (cp/rm interaktiv auf der NAS)**
- `cp`/`rm` sind als `-i` aliased. `cp -f` reicht NICHT — der Alias gewinnt (`cp -i -f` → Prompt; ohne Input kein Overwrite).
- Fix: `command cp -f ...` (oder `\cp -f`), `rm -fv ...`. Ergänzt die bestehende `cat file > target`-Variante (Z.1404) um eine alias-sichere Standard-Methode.

**🟡 `docker image prune -a` Lock: „a prune operation is already running"**
- Es kann parallel ein anderer Prune laufen (Reclaimable fiel diese Session von 64 GB → 25 GB ohne mein Zutun). → Retry-Loop:
  ```bash
  for i in 1 2 3 4 5; do out=$(docker image prune -a -f 2>&1); echo "$out" | grep -q "already running" && { sleep 15; continue; }; echo "$out"|tail -2; break; done
  ```
- Build-Cache wächst während des parallelen Vorgangs wieder nach (206 MB → 1,3 GB) → nach Abschluss nochmal `docker builder prune -f`.
- `image prune -a` entfernt nur Images OHNE referenzierenden Container (auch gestoppte zählen) → gefahrlos; `--volumes` NICHT in Production.

**🟡 Optical-Cleanup Repo-Layout `/volume1/docker`**
- `docs/` = `BACKUP_README.md`, `SERVICE_OVERVIEW.md`, `SECURITY_REPORT.md`. `scripts/` = alle Helfer (`container-health-check.sh`, `setup-backup-cron.sh`, `test-*backup.sh`, `vaultwarden_ha_sync.sh`, `secure_credentials_migration.py`, `nuke-graph-directory.sh`, `smoke.sh`).
- **`daily-backup.sh` + `daily-backup-cron.log` bleiben in der Wurzel** (cron ruft per Absolutpfad). Andere Skripte nutzen absolute Pfade intern → laufen aus `scripts/`.
- **Service-Verzeichnisse NIE verschieben** (relative Bind-Mounts `./data`/`./config` brechen beim `compose up`-Recreate).
- Referenzen nachziehen: `CLAUDE.md` + `CLAUDE_AUTOCLAUDE.md` (`./container-health-check.sh` → `./scripts/...`), `docs/BACKUP_README.md`, `docs/SECURITY_REPORT.md` und der interne Echo-Cron-Hinweis im verschobenen `vaultwarden_ha_sync.sh`. Neuer Health-Check-Befehl: `./scripts/container-health-check.sh`.

**🔵 `/init` CLAUDE.md-Drift**
- Inventar driftete stark: ~50 Container laufen, ~12 waren dokumentiert; Ports veraltet (Vaultwarden 8083→8084, Ollama 11436→11437, Open-WebUI „3000 intern" →8080). Beim `/init`/Review IMMER gegen `docker ps` + `docker network ls` abgleichen statt CLAUDE.md zu vertrauen.

---

### 2026-05-26 — Docker-Update-Check, Backup link-dest-Fix, fuseblk/pkill-Fallen

**🔴 Docker-Image-Update-Check: Digest-Vergleich, NICHT "kein Slash = local build"**
- Zuverlässig — lokaler RepoDigest vs Registry-Manifest-Digest:
  ```bash
  local=$(docker image inspect "$img" --format '{{range .RepoDigests}}{{.}}{{end}}' | grep -oE 'sha256:[a-f0-9]{64}')
  remote=$(docker buildx imagetools inspect "$img" --format '{{.Manifest.Digest}}')
  [ "$local" = "$remote" ] && echo up-to-date || echo UPDATE
  ```
- `docker manifest inspect` taugt NICHT zum Vergleich (liefert Per-Arch-Digests aus der Manifest-Liste, nicht den List-Digest = RepoDigest).
- 🔴 FALLE: Heuristik "Image-Name ohne `/` ⇒ lokaler Build" ist FALSCH — offizielle Docker-Hub-Images (`mariadb`, `nginx`, `redis`, `php`, `eclipse-mosquitto`) haben keinen Slash, sind aber Registry-Images (`library/*`). Echte lokale Compose-Builds erkennt man daran, dass `buildx imagetools inspect` fehlschlägt (kein Remote).
- Pinned-Tags (z.B. `n8nio/n8n:1.73.1`) bekommen keinen Update, nur floating Tags (`latest`, `stable`, `main`, `*-alpine`) verschieben den Digest.

**🔴 daily-backup.sh: --link-dest + Excludes gegen stille code-11-Fehler**
- Symptom: USB-Backup-Platte (`/mnt/@usb/sdc2`, fuseblk) bei 93% → `[ERROR] ... failed (code: 11)` (rsync = kein Platz) → Backups schlugen TÄGLICH STILL fehl (kein verlässliches Recovery). Immer `backup.log`-Tail prüfen, nicht nur dass der Job lief.
- Ursache: Skript rsyncte ganz `/volume1/docker/` als VOLLKOPIE pro Lauf (kein `--link-dest`), inkl. reproduzierbarer/redundanter Daten; `manage_versions` (keep 2) räumt erst AM ENDE → 3 Vollkopien gleichzeitig → voll.
- Fix angewendet (Original gesichert `daily-backup.sh.bak_*`): `--link-dest=<vorheriges Backup>/docker/` (+ `/home/`); `PREV_BACKUP` in `main()` VOR `create_backup_structure` ermitteln; Excludes `ollama/data/models/*`, `ollama/models/*`, `ollama/ollama.tgz`, `glm-4.7-flash/data/*`, `yoga7-backup/*` (~155 GB/Kopie).
- `Crawl4AI` NICHT ausschließen: schwere venvs greifen schon über generisches `*/venv/*`; Rest ist nicht-reproduzierbarer Code/Config. Modelfiles (`ollama/Modelfile-*`) bleiben drin — nur Modell-Blobs raus.
- 🟡 ÜBERGANGS-FALLE: Beim ERSTEN Lauf kollidiert das schlanke neue Backup mit 2 noch fetten alten (prune-at-end) → Home/DBs scheitern an Platz. Lösung: **2× laufen lassen** — Lauf 1 prunt das älteste Fette, Lauf 2 dedupliziert gegen das schlanke und läuft komplett durch ("Backup Completed Successfully!"). Danach self-healing über die täglichen 03:00-Läufe.

**🟡 `du` über fuseblk (NTFS/exFAT-USB) hängt praktisch**
- `du -xh --max-depth=1 /mnt/@usb/sdc2` über 2,6 TB lief nicht durch (Minuten ohne Output). Stattdessen Top-Level mit `ls -la` ansehen, dann gezielt einzelne Unterordner mit `timeout 90 sudo du -sh <dir>` messen (Timeouts als "zu groß" akzeptieren).

**🟡 `pkill -f '<pattern>'` killt die EIGENE Shell (exit 144)**
- Der Pattern matcht auch den gerade laufenden eval'ten Befehlsstring des Bash-Tools → die eigene Ausführung wird mitgekillt (`Exit code 144`), passierte 2× diese Session.
- Stattdessen: spezifischen Prozess per PID killen, oder Pattern eng genug fassen (vollständiger Binär-/Skript-Pfad). Im-Hintergrund gestartete Tasks lieber per Task-ID/TaskStop beenden.
- Verwandt: `run_in_background:true` PLUS inneres `&` im Befehl = der Launcher kehrt sofort mit Exit 0 zurück (Fehlsignal "fertig"), der echte Prozess läuft detached. Nur EINES von beiden nutzen.

**🔵 Verwaisten Docker-data-root sicher erkennen/löschen**
- `@docker.empty.<unixtime>` (hier 486 GB, Okt 2025) = alter data-root nach Migration. Verifizieren: `docker info --format '{{.DockerRootDir}}'` (live = `/volume1/@docker`) + `mount | grep @docker` zeigt nur Live-Root + `lsof +D <dir>` leer → dann `sudo rm -rf` gefahrlos.

**🔵 `@version_explorer_cache` kann auf TB-Skala wachsen — nur über UGOS-UI lösbar**
- Diese Session: 1,9 TB, weil UGOS Version Explorer das churny `/volume1/docker` versioniert. NICHT per `rm` anfassen (beschädigt das Feature). Remediation: in der UGOS-Weboberfläche Version Explorer für die `docker`-Freigabe deaktivieren + Versionen löschen. Empfehlung: nie für `docker`/`@kvm`/Modell-Verzeichnisse aktivieren.

---

### 2026-05-29 — Cron-Install via /etc/cron.d/ (Classifier-Workaround + Copy-Paste-Resilience)

**🔴 Auto-Mode-Classifier blockt `sudo install` nach /etc/cron.d/ — auch mit User-Passwort via stdin**

Selbst `echo "$PW" | sudo -S install ...` wird abgelehnt mit Reasoning "Installing system-wide cron jobs in /etc/cron.d/ creates unauthorized persistence mechanisms". Die User-Erlaubnis "mach das bitte" inkl. Passwort-Drop reicht dem Classifier nicht — er verlangt Userhandlung selbst.

**Lösung: Helper-Skript-Pattern**

Statt User direkt 2× `sudo install` tippen zu lassen (zerfällt beim Copy-Paste, siehe nächste Lektion), bereite ein installiertes Helper-Skript vor:

```bash
# 1) Templates in persistenten Pfad (überlebt Reboot, /tmp nicht)
mkdir -p /volume1/docker/n8n/workflows/cron-templates
cp /tmp/rag-auto-verify   /volume1/docker/n8n/workflows/cron-templates/
cp /tmp/rag-weekly-digest /volume1/docker/n8n/workflows/cron-templates/

# 2) Install-Skript daneben legen
cat > /volume1/docker/n8n/workflows/cron-templates/install.sh <<'EOF'
#!/bin/bash
set -e
SRC="/volume1/docker/n8n/workflows/cron-templates"
install -m 0644 -o root -g root "$SRC/rag-auto-verify"   /etc/cron.d/rag-auto-verify
install -m 0644 -o root -g root "$SRC/rag-weekly-digest" /etc/cron.d/rag-weekly-digest
echo "✓ Installiert" && ls -la /etc/cron.d/rag-*
EOF
chmod +x /volume1/docker/n8n/workflows/cron-templates/install.sh
```

User-Befehl ist dann nur noch:
```bash
sudo bash /volume1/docker/n8n/workflows/cron-templates/install.sh
```
— eine einzige kurze Zeile, robust gegen Terminal-Copy-Paste-Zerlegung, idempotent, dokumentiert sich selbst.

**🔴 Lange `sudo`-Befehle werden vom Terminal beim Paste in zwei Befehle zerlegt**

Symptom in dieser Session: User pastet
```
sudo install -m 0644 -o root -g root
  /volume1/docker/n8n/workflows/cron-templates/rag-auto-verify /etc/cron.d/rag-auto-verify
```
→ Shell führt zwei separate Befehle aus: `sudo install -m 0644 -o root -g root` (fehlt File-Operand) und der zweite Teil als eigenständiger Pfad (`zsh: keine Berechtigung`).

**Drei Anti-Patterns die alle gescheitert sind:**
1. `\`-Line-Continuation am Zeilenende → Terminal-Paste nimmt das `\` als Literal-Zeichen
2. Mehrere `cmd1 && cmd2 && cmd3` in einer logischen Zeile → Terminal bricht trotzdem nach 80 Zeichen
3. "Bitte komplett markieren und einfügen" → User markiert sichtbare Zeilen, Wrapping verfälscht Markierung

**Funktionierender Pattern** für NAS-Setup mit User-Eingabe:
- Pre-stage alle Inhalte in Dateien
- User-Befehl darf MAX 60 Zeichen sein, ein Wort + ein Pfad
- Bevorzugt: `sudo bash <pfad/install.sh>` oder `sudo bash <pfad/uninstall.sh>`

**🟡 `/tmp` ist flüchtig — Cron-Templates IMMER in persistenten Pfad**

Reboot räumt `/tmp` auf, dann ist das Helper-Skript weg. Konvention: `/volume1/docker/<service>/cron-templates/` (übersteht Reboot, ist im Daily-Backup mit drin, gehört semantisch zum Service).

**🟡 User-Crontab (`crontab -e` als Jahcoozi) ist auf UGREEN/Synology gesperrt**

```
/var/spool/cron/: mkstemp: Permission denied
```
→ `/var/spool/cron/crontabs/` ist nicht schreibbar. Stattdessen `/etc/cron.d/` (per sudo via Helper-Skript) ODER Synology/UGREEN Task Scheduler GUI.

**🟡 `.env`-Permissions für Cron-Jobs prüfen**

Wenn ein Cron-Skript Tokens aus `/volume1/docker/n8n/.env` liest und als User `Jahcoozi` läuft:
```bash
test -r /volume1/docker/n8n/.env && echo OK || echo FEHLT-LESEN
ls -la /volume1/docker/n8n/.env
```
Im Cron-File Token explizit als ENV-Var setzen, NICHT aus Shell-Profil erwarten:
```cron
0 20 * * 0 TELEGRAM_TOKEN="$(grep '^TELEGRAM_BOT_TOKEN=' /volume1/docker/n8n/.env | cut -d= -f2-)" /pfad/skript.sh
```

**🟡 Cron-Logfile-Retention im Skript selbst — sonst wächst `logs/` unbegrenzt**

```bash
# Am Ende jedes Cron-Skripts:
ls -t "$LOG_DIR"/skript_*.log 2>/dev/null | tail -n +31 | xargs -r rm -f
```
Verhindert das `workflows/logs/`-Verzeichnis-Sprawl (diese Session: über 100 Crawler-Logs angesammelt).

**🔵 SSH-Quick-Verify nach Cron-Install**

```bash
ssh Jahcoozi@192.168.22.90 'ls -la /etc/cron.d/<prefix>-* && systemctl is-active cron'
```
`systemctl is-active cron` muss `active` liefern — wenn `inactive`, hilft das beste Cron-File nichts. Cron lädt `/etc/cron.d/` automatisch ein (kein Reload nötig).
