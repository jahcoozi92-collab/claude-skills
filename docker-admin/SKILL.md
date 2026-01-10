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
| **Open-WebUI** | 3000 | KI-Chat-Interface |
| **Ollama** | 11434 | Lokale LLMs |
| **Home Assistant** | 8123 | Smart Home |
| **LiveKit** | 7880 | Video/Audio-Kommunikation |
| **Portainer** | 9000 | Docker-Management-UI |
| **NextCloud** | - | Dateispeicher |

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

### Session-Learnings:

*Noch keine Learnings erfasst. Führe `/reflect docker-admin` nach einer Session aus!*

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
