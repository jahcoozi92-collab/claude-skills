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
