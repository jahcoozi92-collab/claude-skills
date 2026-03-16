# Docker-Admin Skill – Container-Management für Diana

| name | description |
|------|-------------|
| docker-admin | Hilft bei Docker-Container-Management auf Diana's NAS und lokalen Systemen. Optimiert für UGREEN DXP4800PLUS, Portainer und Docker Compose. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Stell dir vor, du hast viele verschiedene Apps auf deinem Computer. Jede App braucht andere Sachen zum Laufen. Das kann chaotisch werden!

Docker ist wie ein Schuhkarton-System:
- Jede App kommt in ihren eigenen "Karton" (Container)
- Der Karton hat alles, was die App braucht
- Die Kartons stören sich nicht gegenseitig
- Du kannst Kartons einfach hinzufügen oder wegnehmen

---

## Diana's Docker-Umgebung

### Hardware

| System | Beschreibung | IP/Zugang |
|--------|--------------|-----------|
| **UGREEN NAS** | DXP4800PLUS-30E (Haupt-Host) | 192.168.22.90 |
| **Yoga7** | Kali Linux (Entwicklung) | Lokal |
| **Windows 11** | Arbeitsrechner | Lokal |

### Laufende Container auf dem NAS

| Container | Port | Zweck |
|-----------|------|-------|
| **n8n** | 5678 | Workflow-Automatisierung |
| **Open-WebUI** | 8080 | KI-Chat-Interface |
| **Ollama** | 11436 | Lokale LLMs |
| **Home Assistant** | 8123 | Smart Home |
| **LiveKit** | 7880 | Video/Audio-Kommunikation |
| **Portainer** | 9000 | Docker-Management-UI |
| **NextCloud** | 8282 | Dateispeicher |
| **Cloudflared** | - | Cloudflare Tunnel |
| **SearXNG** | 8081 | Suchmaschine für RAG |
| **Vaultwarden** | 8083 | Passwort-Manager |

### Container-zu-Compose-Mapping (NAS)

Nicht jeder Container hat sein eigenes Compose-Verzeichnis. Diese Zuordnung ist kritisch für Updates:

| Container | Compose-Verzeichnis | Anmerkung |
|-----------|---------------------|-----------|
| cloudflared | `/volume1/docker/cloudflared/` | Eigenständig |
| n8n-n8n-1 | `/volume1/docker/n8n/` | Image: `docker.n8n.io/n8nio/n8n:latest` |
| crawl4ai-n8n | `/volume1/docker/Crawl4AI/` | Nutzt gleiches n8n-Image, anderer Stack! |
| ollama | `/volume1/docker/ollama/` | Eigenständig |
| searxng | `/volume1/docker/searxng-docker/` | NICHT `/volume1/docker/searxng/`! |
| homeassistant | `/volume1/docker/home-assistant/` | `-p home-assistant` für Compose |
| mosquitto | `/volume1/docker/home-assistant/` | Teil des HA-Stacks |
| esphome | `/volume1/docker/home-assistant/` | Teil des HA-Stacks |
| matter-server | `/volume1/docker/home-assistant/` | Teil des HA-Stacks |
| nextcloud_app | `/volume1/docker/nextcloud/` | Eigenständig |
| nextcloud_db | `/volume1/docker/nextcloud/` | MariaDB, Teil des NC-Stacks |
| vaultwarden | `/volume1/docker/vaultwarden/` | Eigenständig |
| dify-* | `/volume1/docker/dify/` | Gepinnt auf 0.15.3 (Feb 2025), Major Update separat prüfen! |
| open-webui | `/volume1/docker/open-webui/` | Eigenständig |
| magic-video-db | `~/magic-video-backend/` | PostgreSQL 16, Port 5438 |
| magic-video-redis | `~/magic-video-backend/` | Redis 7, Port 6380 |

---

## Docker-Grundlagen (für Anfänger)

### Die wichtigsten Begriffe

| Begriff | Bedeutung | Analogie |
|---------|-----------|----------|
| **Image** | Bauplan für Container | Backrezept |
| **Container** | Laufende Instanz eines Images | Der fertige Kuchen |
| **Volume** | Dauerhafter Speicher | Kühlschrank (bleibt auch wenn Kuchen weg) |
| **Network** | Verbindung zwischen Containern | Straßen zwischen Häusern |
| **Compose** | Multi-Container-Setup | Ganzes Menü statt einzelnes Gericht |

### Container vs. Virtual Machine

**Für 12-Jährige:**

**Virtual Machine (VM):**
- Wie ein ganzes zweites Haus in deinem Haus bauen
- Hat eigene Wände, eigene Heizung, eigenes alles
- Braucht viel Platz und Energie

**Container:**
- Wie ein Zimmer in deinem Haus
- Teilt sich Wände, Heizung, Strom mit dem Haus
- Braucht viel weniger Platz und Energie

---

## Wichtige Docker-Befehle

### Container-Update-Workflow (sicher)

```bash
# 1. Alle öffentlichen Images pullen (sicher, ändert keine Container)
docker pull [image:tag]

# 2. Prüfen ob neues Image verfügbar
#    "Image is up to date" = kein Update
#    "Downloaded newer image" = Update verfügbar

# 3. Risiko-Kategorisierung:
#    SICHER:   cloudflared, ollama, searxng, n8n (stateless/unkritisch)
#    MITTEL:   home-assistant, jellyfin (wichtig, aber Volume-basiert)
#    SENSIBEL: vaultwarden, mariadb/nextcloud (Passwörter/Datenbank)
#    → Sichere zuerst, sensible nur nach Bestätigung

# 4. Container aktualisieren (im jeweiligen Compose-Verzeichnis)
docker compose up -d

# 5. Bei Namenskonflikten (orphaned Container):
docker compose down && docker compose up -d
# Oder einzelne alte Container entfernen:
docker rm [alte-container-id]

# 6. Verifizieren
docker ps --format "table {{.Names}}\t{{.Status}}"
docker ps -a --filter "status=exited" --filter "status=restarting"
```

**Typische Probleme beim Update:**
- Port already allocated → alter Container mit gleichem Port läuft noch
- Container name conflict → `docker compose down` dann `up -d`
- Orphaned Container mit Prefix-Namen (z.B. `7b0265dce765_searxng-docker-searxng-1`) → `docker rm` der alten Container

### Container verwalten

```bash
# Alle laufenden Container anzeigen
docker ps

# ALLE Container anzeigen (auch gestoppte)
docker ps -a

# Container starten
docker start [container-name]

# Container stoppen
docker stop [container-name]

# Container neu starten
docker restart [container-name]

# Container-Logs anzeigen
docker logs [container-name]

# Container-Logs live verfolgen
docker logs -f [container-name]

# In Container einsteigen (Bash)
docker exec -it [container-name] bash
```

### Images verwalten

```bash
# Alle Images anzeigen
docker images

# Image herunterladen
docker pull [image-name]

# Ungenutzte Images löschen
docker image prune

# ALLE ungenutzten Daten löschen (Vorsicht!)
docker system prune -a
```

### Docker Compose

```bash
# Alle Services starten (im Ordner mit docker-compose.yml)
docker-compose up -d

# Alle Services stoppen
docker-compose down

# Status aller Services
docker-compose ps

# Logs aller Services
docker-compose logs

# Einen Service neu bauen und starten
docker-compose up -d --build [service-name]
```

---

## Diana's typische Docker-Compose-Struktur

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - diana-network

  ollama:
    image: ollama/ollama
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - diana-network

volumes:
  n8n_data:
  ollama_data:

networks:
  diana-network:
    driver: bridge
```

---

## Constraints – Was ich IMMER beachten muss

### 🔴 NIEMALS

1. **NIEMALS** Container ohne Restart-Policy
   ```yaml
   # ✅ Richtig
   restart: unless-stopped
   
   # ❌ Falsch (kein restart)
   ```

2. **NIEMALS** Passwörter direkt in docker-compose.yml
   ```yaml
   # ✅ Richtig - Umgebungsvariable
   environment:
     - PASSWORD=${MY_SECRET}
   
   # ❌ Falsch - Klartext
   environment:
     - PASSWORD=geheim123
   ```

3. **NIEMALS** `docker system prune -a` ohne Warnung
   - Löscht ALLE ungenutzten Images
   - Kann viel Arbeit zerstören

4. **NIEMALS** Container auf `latest` Tag in Produktion
   ```yaml
   # ✅ Richtig - Feste Version
   image: n8nio/n8n:1.20.0
   
   # ❌ Falsch - Kann sich ändern
   image: n8nio/n8n:latest
   ```

### 🟡 BEVORZUGT

1. **Benannte Volumes** statt Bind Mounts für Daten
2. **Eigenes Netzwerk** für zusammengehörige Container
3. **Health Checks** für wichtige Services
4. **Ressourcen-Limits** setzen (memory, cpu)

### 🟢 GUT ZU WISSEN

1. Diana nutzt Portainer für visuelles Management
2. NAS-Pfade beginnen mit `/volume1/` oder ähnlich
3. Bei UGREEN: Web-UI unter http://192.168.22.90
4. **Cloudflare Tunnel:** Nach Container-Restart auch `docker restart cloudflared`
5. **Docker-Netzwerke:** `webui-network` und `shared-services` sind externe Bridge-Netzwerke

---

## Troubleshooting

### Problem: Container startet nicht

**Diagnose-Schritte:**
```bash
# 1. Status prüfen
docker ps -a | grep [container-name]

# 2. Logs anschauen
docker logs [container-name]

# 3. Letzte 50 Zeilen
docker logs --tail 50 [container-name]
```

**Häufige Ursachen:**

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| "Port already in use" | Port belegt | Anderen Port nutzen |
| "Volume mount failed" | Pfad existiert nicht | Ordner erstellen |
| "Permission denied" | Rechte-Problem | chown oder chmod |
| "Out of memory" | Zu wenig RAM | Limits erhöhen |

### Problem: Container ist langsam

```bash
# Ressourcen-Verbrauch anzeigen
docker stats [container-name]

# Detaillierte Infos
docker inspect [container-name]
```

### Problem: Kein Netzwerk zwischen Containern

```bash
# Netzwerke anzeigen
docker network ls

# Container in Netzwerk prüfen
docker network inspect [network-name]

# Container zu Netzwerk hinzufügen
docker network connect [network-name] [container-name]
```

---

## UGREEN NAS Spezifisches

### Besonderheiten

1. **Web-UI:** Viele Einstellungen nur über Browser
2. **Pfade:** Anders als Standard-Linux
3. **SSH:** Muss eventuell aktiviert werden
4. **Docker:** Läuft nativ, aber UI-Integration beachten

### Typische Pfade auf UGREEN

```
/volume1/docker/         # Docker-Daten
/volume1/nextcloud/      # NextCloud-Daten
/volume1/media/          # Mediendateien
```

---

## Backup-Strategie

### Container-Daten sichern

```bash
# Volume-Backup
docker run --rm \
  -v [volume-name]:/data \
  -v /backup:/backup \
  busybox tar cvf /backup/[volume-name].tar /data
```

### Docker Compose sichern

```bash
# Alle Compose-Dateien
cp -r /path/to/compose-files /backup/docker-compose-$(date +%Y%m%d)
```

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

### 2026-01-11 - Open WebUI Modell-Konfiguration

**Open WebUI Datenbank-Manipulation:**
- Modelle werden in SQLite gespeichert: `/volume1/docker/open-webui/webui.db`
- Tabelle `model` enthält: id, name, meta (JSON mit icon, description, tags)
- Nach DB-Änderungen IMMER: `docker restart open-webui`
- Python-Skripte für Updates unter `/volume1/docker/open-webui/*.py`

**SVG-Icons in Web-Interfaces:**
- SVG-Gradient-IDs müssen eindeutig sein wenn mehrere Icons auf einer Seite
- Lösung: Hash des Model-IDs als Suffix (z.B. `id='g{uid}'`)
- Base64-Encoding: `data:image/svg+xml;base64,...`

**Cloudflare Tunnel Troubleshooting:**
- 502/530 Fehler = Origin nicht erreichbar
- Nach Container-Restart: `docker restart cloudflared`
- Logs prüfen: `docker logs cloudflared --tail 20`
- Tunnel-Config liegt in `/volume1/docker/cloudflared/config.yml`

**Open WebUI Modell-Kategorisierung:**
- Lokal (grün): Ollama-Modelle, offline nutzbar
- Extern (blau): API-Modelle (OpenAI, Anthropic, Google, Mistral, MiniMax)
- Custom (lila): Eigene Personas/Assistenten
- Integration (orange): Workflow-Router (n8n)

### 2026-01-11 - Open WebUI Level 3 Optimierung

**API-Verbindungen - NIEMALS:**
- NIEMALS Anthropic als OpenAI-kompatiblen Endpoint konfigurieren (nutzt eigenes API-Format)
- NIEMALS MiniMax ohne korrekten Endpoint (`/v1/models` existiert nicht bei allen Providern)
- Fehlerhafte Verbindungen verursachen `500 Internal Server Error` bei `/openai/models/X`

**Datenbank-Reparatur bei API-Fehlern:**
```bash
# API-Verbindungen prüfen
sqlite3 webui.db "SELECT data FROM config WHERE id=1;" | python3 -c "
import sys,json
d=json.loads(sys.stdin.read())
print(json.dumps(d.get('openai',{}), indent=2))"

# Fehlerhafte Verbindungen entfernen (nur OpenAI behalten)
# → Python-Skript zum Bereinigen der api_base_urls Liste
```

**Docker-Compose YAML-Syntax:**
- NIEMALS Prompt-Templates mit Sonderzeichen direkt in environment-Liste
- Führt zu: `unexpected type map[string]interface {}`
- Lösung: Templates über Admin-UI konfigurieren, nicht YAML

**Level-basierte Konfiguration:**
```
docker-compose.level1.yml  → Basis + DALL-E + TTS/STT
docker-compose.level2.yml  → + Code Interpreter + Autocomplete
docker-compose.level3.yml  → Produktionsreif (alle Features)
```

**Wichtige Level 3 Environment-Variablen:**
```yaml
- ENABLE_CODE_INTERPRETER=true      # Pyodide Sandbox
- ENABLE_AUTOCOMPLETE_GENERATION=true
- TASK_MODEL=qwen2.5:7b             # Schnelle lokale Tasks
- TASK_MODEL_EXTERNAL=gpt-4o-mini   # Externe Tasks
- WHISPER_LANGUAGE=de               # Deutsche Spracherkennung
- PDF_EXTRACT_IMAGES=true           # OCR für PDFs
- YOUTUBE_LOADER_LANGUAGE=de,en     # YouTube-Transkripte
```

**NAS-spezifisch:**
- `cp -f` funktioniert nicht immer → nutze `yes | cp` für automatische Bestätigung
- Nach Level-Wechsel: `docker compose down && docker compose up -d`

### 2026-01-11 - Open WebUI Fehlerbehebung & Best Practices

**Functions/Tools bei Fehlern - NIEMALS nur deaktivieren:**
```sql
-- FALSCH: Nur deaktivieren (wird trotzdem geladen!)
UPDATE function SET is_active=0, meta=json_set(meta,'$.enabled',false) WHERE id='...';

-- RICHTIG: Komplett löschen
DELETE FROM function WHERE id='elasticsearch_forensik_rag';
DELETE FROM tool WHERE id='elasticsearch_forensik_rag';
```

**DALL-E Bildgenerierung - korrekte Model-Namen:**
```
❌ FALSCH: gpt-image-1 (existiert nicht)
✅ RICHTIG: dall-e-2 oder dall-e-3
```

**RAM/OOM Management:**
- Modelle >10GB NIEMALS als Default wenn <20GB RAM frei
- `free -h` vor Modell-Konfiguration prüfen
- Swap voll = System überlastet → kleinere Modelle wählen
- qwen2.5:32b (19GB) → qwen2.5:7b (4.7GB)

**Custom Models/Assistants:**
- `base_model_id` muss auf lauffähiges Modell zeigen
- Prüfen: `SELECT id, base_model_id FROM model WHERE id LIKE '%assistant%';`
- Bei OOM-Fehlern: base_model_id auf kleineres Modell ändern

**Modell-Anzeige in Open WebUI:**
- Benchmarks ins NAME-Feld setzen (nicht DESCRIPTION)
- Format: `Kategorie • Name | ≈XX% ≈Vergleichsmodell`
- Beispiel: `Lokal • Qwen 2.5 7B | ≈78% ≈GPT-4o Mini`

**'NoneType' Fehler debuggen:**
1. `docker logs open-webui | grep -E "(Error|NoneType)"`
2. Meist: Function/Tool mit fehlerhafter externer Verbindung
3. Lösung: Function komplett löschen (nicht nur deaktivieren)

**Container-Neustart bei DB-Änderungen:**
```bash
# FALSCH: restart lädt DB-Änderungen nicht immer
docker restart open-webui

# RICHTIG: down/up erzwingt komplettes Neuladen
docker compose down open-webui && docker compose up -d open-webui
```

### 2026-01-15 - Container-Updates & Synology-Spezifika

**Container-Update-Workflow:**
```bash
# 1. Update-Check für alle wichtigen Images
docker pull [image] && docker inspect --format '{{.Id}}' [image]

# 2. Vergleich: Laufender Container vs. neues Image
docker inspect --format '{{.Image}}' [container]

# 3. Bei Update verfügbar: down/up (nicht restart!)
docker compose down [service] && docker compose up -d [service]

# 4. Aufräumen - alte Images entfernen
docker image prune -a
```

**Synology BTRFS Berechtigungsprobleme:**
- Mosquitto kann `passwordfile` nicht lesen trotz korrekter chmod/chown
- Exit code 13 = Permission denied bei Bind-Mounts
- Versuche wie `chmod 777`, `chown 1883:1883` helfen NICHT
- **Workarounds:**
  - `allow_anonymous=true` (für internen MQTT)
  - Docker Named Volume statt Bind-Mount verwenden
  - File im Container erstellen: `docker exec mosquitto mosquitto_passwd -c ...`

**Port-Binding für externe Erreichbarkeit:**
```yaml
# ❌ FALSCH - Nur localhost, nicht von außen erreichbar
ports:
  - "127.0.0.1:8081:8080"

# ✅ RICHTIG - Alle Interfaces
ports:
  - "8081:8080"
  # oder explizit:
  - "0.0.0.0:8081:8080"
```

**Container-Namen ändern sich:**
- Docker Compose v2 nutzt andere Namenskonvention
- Alt: `projectname_servicename_1` (Compose v1)
- Neu: `projectname-servicename-1` oder einfach `servicename` (Compose v2)
- **Prüfen:** `docker ps --format "{{.Names}}"`
- Home Assistant Sensor-Commands anpassen!

**Home Assistant Docker-Sensor Optimierung:**
- Scan Intervals von 300s auf 600s erhöhen (weniger Last)
- Container-Status-Checks sind ressourcenintensiv
- Nur kritische Container überwachen

**Defekte Container identifizieren:**
```bash
# Restart-Loops finden
docker ps -a --filter "status=restarting"

# Unhealthy Container
docker ps --filter "health=unhealthy"

# Exit-Codes prüfen
docker inspect --format '{{.State.ExitCode}}' [container]
# Exit 13 = Permission denied
# Exit 137 = OOM Killed
# Exit 1 = Allgemeiner Fehler
```

**SearXNG + Open WebUI Integration:**
- Open WebUI hat bereits RAG_WEB_SEARCH_ENGINE Umgebungsvariable
- SearXNG muss im gleichen Docker-Netzwerk sein
- URL-Format: `http://searxng:8080` (Container-Name, interner Port)

### 2026-01-12 - npm ci vs npm install in Docker

**Problem:** Docker-Build schlägt fehl mit `npm ci` Fehler:
```
npm error `npm ci` can only install packages when your package.json
and package-lock.json are in sync
npm error Invalid: lock file's picomatch@2.3.1 does not satisfy picomatch@4.0.3
```

**Ursache:**
- `npm ci` ist strikt - Lock-File muss exakt zur npm-Version passen
- Host-System hat andere npm-Version als Container (node:20-alpine)
- Lock-File wurde mit Host-npm generiert, Container-npm lehnt ab

**Lösung im Dockerfile:**
```dockerfile
# ❌ FALSCH - Strikt, bricht bei Versions-Mismatch
RUN npm ci

# ✅ RICHTIG - Tolerant, aktualisiert Lock-File bei Bedarf
RUN npm install
```

**Vite allowedHosts - Nur für Dev-Server:**
- Fehler "This host is not allowed" kommt nur vom Vite Dev-Server
- Production-Build mit nginx hat KEINE Host-Restriktionen
- `vite.config.ts` → `server.allowedHosts` nur für `npm run dev` relevant
- Bei Docker mit nginx: Problem liegt woanders (Container läuft nicht, Port-Mapping, etc.)

### 2026-01-16 - AI Container Stack & Cloudflare Automation

**AI Container Installation:**
| Container | Port | Besonderheiten |
|-----------|------|----------------|
| Dify | 3100 | Nach Start: `docker exec dify-api flask db upgrade` |
| OpenHands | 3200 | SANDBOX_USER_ID=0, FILE_STORE_PATH Volume nötig |
| Langflow | 7860 | `user: root` in docker-compose.yml |
| CrewAI | 3400 | Kein offizielles Image → Custom Dockerfile |
| AutoGPT | 8100 | Braucht OPENAI_API_KEY (kein Ollama-Support) |
| vLLM | - | ❌ Benötigt GPU - auf CPU nicht nutzbar |

**Dify Setup-Workflow:**
```bash
# 1. Stack starten
cd /volume1/docker/dify && docker compose up -d

# 2. Warten bis DB healthy
docker ps --filter "name=dify-db" --format "{{.Status}}"

# 3. Migration ausführen (WICHTIG!)
docker exec dify-api flask db upgrade

# 4. API neustarten
docker restart dify-api dify-worker
```

**CrewAI Custom Build:**
```dockerfile
FROM python:3.11-slim
RUN pip install crewai crewai-tools langchain-ollama fastapi uvicorn
COPY app.py /app/
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Container Permission Fixes:**
```yaml
# Langflow - Permission denied für /app/data
services:
  langflow:
    user: root  # Löst Permission-Problem

# OpenHands - JWT Secret schreiben
services:
  openhands:
    environment:
      - SANDBOX_USER_ID=0
      - FILE_STORE_PATH=/opt/openhands
    volumes:
      - openhands-data:/opt/openhands
```

**Cloudflare Tunnel API (Token-basiert):**
```bash
# Token-basierte Tunnel ignorieren lokale config.yml!
# Routes nur via API änderbar:

# 1. Aktuelle Config abrufen
curl -X GET "https://api.cloudflare.com/client/v4/accounts/{account_id}/cfd_tunnel/{tunnel_id}/configurations" \
  -H "Authorization: Bearer $CF_TUNNEL_TOKEN"

# 2. Neue Routes hochladen
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/{account_id}/cfd_tunnel/{tunnel_id}/configurations" \
  -H "Authorization: Bearer $CF_TUNNEL_TOKEN" \
  -d '{"config":{"ingress":[...]}}'
```

**Cloudflare DNS via API:**
```bash
# Separater Token mit "Zone DNS:Edit" nötig!
ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=domain.com" \
  -H "Authorization: Bearer $CF_DNS_TOKEN" | jq -r '.result[0].id')

# CNAME erstellen
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_DNS_TOKEN" \
  -d '{"type":"CNAME","name":"subdomain","content":"tunnel-id.cfargotunnel.com","proxied":true}'
```

**Zwei Cloudflare Tokens benötigt:**
| Zweck | Template | Berechtigung |
|-------|----------|--------------|
| Tunnel Routes | Custom | Account → Cloudflare Tunnel → Edit |
| DNS Records | Edit zone DNS | Zone → DNS → Edit |

**Port-Kollisionen vermeiden:**
```bash
# VOR Installation prüfen
docker ps --format "{{.Ports}}" | tr ',' '\n' | grep -oE ':[0-9]+' | sort -u
```

**DNS-Cache auf NAS umgehen:**
```bash
# Lokaler DNS cached alte Einträge - Test mit direkter IP:
curl --resolve "host.domain.com:443:104.21.30.51" https://host.domain.com
```

### 2026-01-27 - Clawdbot Installation & Migration

**VOR Docker-Setup immer prüfen ob Container existiert:**
```bash
# IMMER zuerst prüfen!
docker ps -a | grep -E 'claw'

# Falls Container existiert → nicht neu installieren
# Stattdessen: docker compose up -d im bestehenden Verzeichnis
```

**Clawdbot WhatsApp deaktivieren:**
```bash
# ❌ config "enabled: false" reicht NICHT
# ✅ Credentials verschieben:
mv config/credentials/whatsapp config/credentials/whatsapp.disabled
docker compose restart clawdbot-gateway

# Log zeigt dann: "[whatsapp] skipping provider start (no linked session)"
```

**Cloudflare Tunnel für neue Subdomain:**
1. `config.yml` editieren reicht NICHT allein
2. DNS CNAME Record muss im Cloudflare Dashboard angelegt werden
3. Name: `clawdbot` → Target: `[tunnel-id].cfargotunnel.com`
4. Dann: `docker restart cloudflared`

**Clawdbot Gateway Token:**
- Liegt in `.env` als `CLAWDBOT_GATEWAY_TOKEN`
- Control UI: http://192.168.22.90:18789/
- Token in UI-Settings eingeben für Zugriff

### 2026-02-04 - Ollama Modell-Management

**Modelle auflisten, hinzufügen, entfernen:**
```bash
# Liste aller installierten Modelle
docker exec ollama ollama list

# Modell herunterladen
docker exec ollama ollama pull qwen3:8b

# Modell entfernen (Speicher freigeben)
docker exec ollama ollama rm qwen3:30b-a3b

# Custom Modelfile erstellen
docker exec ollama ollama create pflege-assistent -f /root/.ollama/Modelfile-pflege
```

**Modell-Größen für CPU-only NAS (UGREEN DXP4800):**
| Kategorie | Empfehlung |
|-----------|------------|
| ✅ Gut | 3B-8B Modelle (~3-8 GB, 20-50 tok/s) |
| ⚠️ Grenzwertig | 14B Modelle (~9 GB, 10-15 tok/s) |
| ❌ Vermeiden | 30B+ Modelle (>18 GB, <5 tok/s) |

**Speicherplatz-Optimierung:**
- Vor dem Löschen: `docker exec ollama ollama list` für Größen prüfen
- Nach dem Löschen: Speicher wird sofort freigegeben
- Embedding-Modelle (bge-m3, nomic-embed) klein halten (~1-2 GB)

**Port-Mapping beachten:**
- Ollama intern: Port 11434
- NAS extern: Port 11436 (gemapped in docker-compose.yml)
- API-Calls: `http://192.168.22.90:11436/api/tags`

### 2026-02-03 - OpenClaw / Clawdbot VM Troubleshooting

**VM-Architektur auf dem NAS:**
- `192.168.22.206` ist eine VM auf dem NAS `192.168.22.90` (kein separates Gerät!)
- Hostname: `ugreen-gateway`, User: `moltbotadmin`
- Docker ist auf der VM NICHT installiert
- Dienste laufen als systemd User-Services, nicht als Container

**Clawdbot Gateway Diagnose-Reihenfolge:**
1. Config-Validierung: `clawdbot.json` auf ungültige Keys prüfen
2. Auth: `auth-profiles.json` auf abgelaufene/gesperrte Keys prüfen
3. Billing: `"disabledReason": "billing"` = Guthaben/Zahlung beim Provider prüfen
4. Service-Status: `systemctl --user status clawdbot-gateway.service`

**Clawdbot Config-Reparatur:**
```bash
# Config-Keys validieren und ungültige entfernen
clawdbot doctor --fix

# NICHT existierende Befehle: clawdbot wizard
# Stattdessen: clawdbot doctor --fix, clawdbot agents add <id>
```

**Clawdbot Gateway als systemd User-Service:**
```bash
# Status prüfen
systemctl --user status clawdbot-gateway.service

# Neustarten
systemctl --user restart clawdbot-gateway.service

# Logs anzeigen
journalctl --user -u clawdbot-gateway.service --no-pager -n 50

# User-Service auch ohne Login laufen lassen
loginctl enable-linger moltbotadmin
```

**Auth-Profile Pfad:**
```
~/.clawdbot/agents/main/agent/auth-profiles.json
```

**Häufige Fehler:**
| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `Unrecognized keys` in clawdbot.json | Veraltete Config | `clawdbot doctor --fix` |
| `HTTP 401 invalid x-api-key` | API-Key ungültig/abgelaufen | Neuen Key eintragen |
| `No API key found for provider` | Provider nicht konfiguriert | `auth-profiles.json` bearbeiten |
| `disabledReason: "billing"` | Kein Guthaben beim Provider | Billing auf Provider-Seite prüfen |
| `Context overflow` | Prompt zu groß für Model | Kontext leeren oder größeres Model |

**502 bei Cloudflare Tunnel zu VM-Diensten:**
- Cloudflared-Logs prüfen: `docker logs cloudflared --tail 50 | grep openclaw`
- Fehler `connection refused` = Dienst auf VM läuft nicht
- Erst VM-Erreichbarkeit testen: `nc -z -w 3 192.168.22.206 18789`
- Dann Dienst auf VM starten (SSH → systemctl)

### 2026-02-04 - Clawdbot Modell-Konfiguration

**Fehler "HTTP 404: model 'X' not found":**
- Bedeutet: Modell-ID in clawdbot.json existiert nicht auf Ollama-Server
- Prüfen welche Modelle verfügbar: `docker exec ollama ollama list`
- Config anpassen: `nano ~/.clawdbot/clawdbot.json`

**Clawdbot Config-Struktur für Modelle:**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-20250514",
        "fallbacks": [
          "anthropic/claude-opus-4-5",
          "ollama/qwen2.5:7b"
        ]
      }
    }
  },
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://192.168.22.90:11436/v1",
        "models": [
          {"id": "qwen2.5:7b", "name": "Qwen 2.5 7B", ...}
        ]
      }
    }
  }
}
```

**Wichtige Pfade in clawdbot.json:**
| Pfad | Bedeutung |
|------|-----------|
| `agents.defaults.model.primary` | Haupt-Modell (Format: provider/model-id) |
| `agents.defaults.model.fallbacks` | Backup-Modelle wenn primary fehlschlägt |
| `models.providers.ollama.models` | Ollama-Modell-Definitionen |
| `models.providers.ollama.baseUrl` | Ollama API URL |

**Verfügbare Ollama-Modelle auf NAS (Stand 02/2026):**
- `qwen2.5:32b` (19 GB) - Flagship, langsam
- `qwen2.5:7b` (4.7 GB) - Empfohlen für Clawdbot
- `qwen2.5-coder:7b-instruct` (4.7 GB) - Code
- `deepseek-r1:7b` (4.7 GB) - Reasoning
- `phi4:14b` (9.1 GB) - Research
- `bge-m3` (1.2 GB) - Embedding only

**Empfohlene Clawdbot-Konfiguration:**
```json
"model": {
  "primary": "anthropic/claude-sonnet-4-20250514",
  "fallbacks": ["anthropic/claude-opus-4-5", "ollama/qwen2.5:7b"]
}
```

**Heartbeat deaktivieren:**
```json
"heartbeat": {
  "enabled": false
}
```
Oder Interval sehr hoch setzen: `"every": "8760h"` (1 Jahr)

### 2026-03-14 - Kontext-Erkennung & SSH-User

**SSH-User IMMER aus Instanzen-Tabelle (CLAUDE.md) prüfen:**
- NAS: `Jahcoozi@192.168.22.90` (NICHT `yoga7@`)
- Clawbot: `moltbotadmin@192.168.22.206`
- Fehler in dieser Session: `ssh yoga7@192.168.22.90` → Timeout/Fehler

**Kontext-Erkennung bei "Docker aktualisieren":**
- Docker ist auf Yoga7 NICHT installiert → keine Rückfrage nötig
- n8n läuft auf NAS (steht in CLAUDE.md) → direkt NAS ansteuern
- Regel: Wenn Docker lokal nicht existiert UND CLAUDE.md sagt "Docker auf NAS" → sofort NAS-SSH

**Standard Docker-Update-Workflow (bewährt):**
1. `docker ps` — alle Container auflisten
2. `docker images` — alle Images auflisten (nur Remote-Images pullen, lokale Builds skippen)
3. `docker pull` für jedes Remote-Image
4. Vergleich: laufender Container-Image-Hash vs. gepullter Hash
5. Falls Update nötig: `docker compose up -d` im jeweiligen Compose-Verzeichnis
6. Cleanup: `docker image prune -f && docker builder prune -f`
7. `docker system df` — Ergebnis zeigen

### 2026-02-10 - Container-Update-Session (Reflect)

**Container-zu-Compose-Mapping ist kritisch:**
- SearXNG liegt in `searxng-docker/`, nicht `searxng/`
- Mosquitto ist Teil des home-assistant Stacks (kein eigenes Compose)
- MariaDB ist Teil des nextcloud Stacks
- crawl4ai-n8n nutzt das gleiche n8n-Image, gehört aber zum Crawl4AI-Stack

**Orphaned Container bei Updates:**
- Nach Docker Compose v1→v2 Migration bleiben alte Container mit Prefix-Namen
- Symptom: `Conflict. The container name "/xyz" is already in use`
- Lösung: `docker compose down && docker compose up -d` oder `docker rm [alte-id]`
- Port-Konflikte: Alten Container erst stoppen bevor neuer starten kann

**Risiko-basiertes Update-Verfahren:**
- Pull zuerst (ändert keine laufenden Container)
- Kategorisiere: sicher → mittel → sensibel
- Patch-Updates (z.B. MariaDB 11.4.9→11.4.10) sind sicher
- Sensible Services (Vaultwarden, Datenbanken) nur nach Bestätigung

**Dify sehr veraltet:**
- Gepinnt auf 0.15.3 (Feb 2025) — über 1 Jahr alt
- Major Update separat behandeln (Breaking Changes möglich)

**n8n Image-Registry:**
- Tatsächliches Image: `docker.n8n.io/n8nio/n8n:latest` (nicht `n8nio/n8n`)

### 2026-02-05 - Große Modelle: API statt Lokal

**Modelle >10GB auf CPU-only NAS → API bevorzugen:**
| Modell | Lokal (CPU) | API | Empfehlung |
|--------|-------------|-----|------------|
| glm-4.7-flash (19GB) | ~4-5 tok/s | sofort | ❌ Lokal, ✅ API |
| qwen3:30b (18GB) | ~5 tok/s | - | ❌ Zu groß |
| phi4:14b (9GB) | ~10 tok/s | - | ⚠️ Grenzwertig |
| qwen3:8b (5GB) | ~25-30 tok/s | - | ✅ Lokal OK |

**Faustregel:** Modelle >8GB = API nutzen (Z.AI, Moonshot, OpenRouter)

**Custom Modelfile für CPU-Optimierung (+25% Speed):**
```bash
cat > Modelfile-fast << 'EOF'
FROM [model]:latest
PARAMETER num_ctx 2048      # Reduzierter Context
PARAMETER num_predict 256   # Kürzere Ausgabe
PARAMETER num_thread 4      # CPU-Threads
PARAMETER num_batch 256
PARAMETER num_gpu 0
EOF
docker exec ollama ollama create model-fast -f /root/.ollama/Modelfile-fast
```

**Z.AI (Zhipu AI) für GLM-Modelle:**
- API-Base: `https://api.z.ai/api/paas/v4`
- GLM-4.7-Flash: **KOSTENLOS**
- GLM-4.7: $0.60/$2.20 per 1M tokens
- OpenAI-kompatibel → In Open WebUI als weitere Verbindung hinzufügen

---

## Quick Reference Card

```
┌────────────────────────────────────────────────────────┐
│                 DOCKER QUICK REFERENCE                  │
├────────────────────────────────────────────────────────┤
│ Container starten:    docker start [name]              │
│ Container stoppen:    docker stop [name]               │
│ Logs anzeigen:        docker logs [name]               │
│ In Container:         docker exec -it [name] bash      │
├────────────────────────────────────────────────────────┤
│ Compose up:           docker-compose up -d             │
│ Compose down:         docker-compose down              │
│ Compose logs:         docker-compose logs              │
├────────────────────────────────────────────────────────┤
│ Alle Container:       docker ps -a                     │
│ Alle Images:          docker images                    │
│ Aufräumen:            docker system prune              │
└────────────────────────────────────────────────────────┘
```
