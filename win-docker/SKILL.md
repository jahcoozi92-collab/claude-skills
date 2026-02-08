# Win-Docker Skill – Docker Desktop auf WS44 (Windows 11)

| name | description |
|------|-------------|
| win-docker | Instanz-Skill für Docker Desktop auf Diana's Windows-Arbeitsplatz WS44. Unterscheidet sich von docker-admin (NAS). Lokale Container-Entwicklung, Image-Builds, Compose. |

## Was ist dieser Skill?

Stell dir vor, du hast eine große Werkstatt (NAS) wo die schweren Maschinen stehen und dauerhaft laufen, und einen kleinen Werkbank (Windows-PC) wo du Sachen bastelst und testest, bevor sie in die große Werkstatt kommen. Dieser Skill kennt die kleine Werkbank — Docker Desktop auf Windows.

---

## Trigger

Aktiviere diesen Skill bei:
- Docker auf Windows / Docker Desktop
- Lokale Container bauen oder testen
- `docker compose` auf dem Arbeitsplatz
- Container-Images lokal erstellen
- Unterschied zwischen lokalen und NAS-Containern

---

## System-Steckbrief

| Eigenschaft | Wert |
|-------------|------|
| **Hostname** | WS44 |
| **Docker Version** | 28.4.0 |
| **Context** | desktop-linux (Docker Desktop mit Linux-VM) |
| **Compose** | v2.39.4-desktop.1 |
| **Buildx** | v0.28.0-desktop.1 |
| **Backend** | Linux VM (kein WSL2 installiert) |
| **Plugins** | AI (Gordon), Buildx, Cloud, Compose, Debug |

---

## Abgrenzung: Windows-Docker vs. NAS-Docker

| Aspekt | WS44 (dieser Skill) | NAS (docker-admin) |
|--------|---------------------|---------------------|
| **Docker** | Docker Desktop 28.4 | Docker Engine (Linux nativ) |
| **Zweck** | Entwicklung, Tests, Builds | Produktion, Services 24/7 |
| **Persistenz** | Temporär, wird nach Test gestoppt | Dauerlauf mit `restart: always` |
| **Zugriff** | Lokal, `localhost` | Netzwerk, `192.168.2.215:PORT` |
| **Volumes** | Windows-Pfade (`C:\...`) | Linux-Pfade (`/volume1/docker/...`) |
| **Management** | Docker Desktop GUI + CLI | Portainer (Port 9000) + SSH |
| **Status** | Wird bei Bedarf gestartet | Immer an |

---

## Docker Desktop starten

Docker Desktop ist nicht immer aktiv. Bei Bedarf:

```bash
# Status prüfen
docker info 2>/dev/null && echo "Docker läuft" || echo "Docker nicht aktiv"

# Docker Desktop starten (aus Git Bash)
"/c/Program Files/Docker/Docker Desktop.exe" &

# Warten bis Docker bereit ist
docker info > /dev/null 2>&1
```

---

## Typische lokale Workflows

### Image bauen und testen
```bash
cd ~/pflegeassist
docker build -t pflegeassist:local .
docker run -p 8000:80 pflegeassist:local
# Browser: http://localhost:8000
```

### Compose für lokale Entwicklung
```bash
docker compose up -d
docker compose logs -f
docker compose down
```

### Image für NAS vorbereiten
```bash
# Lokal bauen
docker build -t pflegeassist:latest .

# Als tar exportieren für NAS-Transfer
docker save pflegeassist:latest | gzip > pflegeassist.tar.gz

# Auf NAS laden (via SSH)
scp pflegeassist.tar.gz sshd@192.168.2.215:/tmp/
ssh sshd@192.168.2.215 "docker load < /tmp/pflegeassist.tar.gz"
```

---

## Volume-Pfade auf Windows

Docker Desktop mounted Windows-Pfade in die Linux-VM:

```yaml
# docker-compose.yml auf Windows
volumes:
  - C:\Users\D.Göbel\pflegeassist:/app          # Windows-Pfad
  - /c/Users/D.Göbel/pflegeassist:/app           # Git Bash Pfad (auch gültig)
```

**Achtung:** UNC-Pfade (`\\192.168.2.215\...`) funktionieren NICHT als Docker-Volume-Mounts.

---

## Constraints

### NIEMALS
1. Keine Produktions-Container auf WS44 dauerhaft laufen lassen — dafür ist die NAS da
2. Keine NAS-Docker-Befehle über Docker Desktop ausführen — Docker-Contexts sind getrennt
3. Keine UNC-Pfade als Volume-Mounts verwenden

### BEVORZUGT
1. Images lokal bauen und testen, dann auf NAS deployen
2. `docker compose` statt einzelne `docker run` Befehle
3. Docker Desktop nur starten wenn nötig (spart Ressourcen auf Büro-PC)

### GUT ZU WISSEN
1. Docker Desktop ist nicht immer aktiv — `docker info` prüft den Status
2. Kein WSL2 installiert — Docker Desktop nutzt eigene Linux-VM
3. Docker AI Agent (Gordon) ist als Plugin verfügbar
4. Der NAS-Docker ist über SSH erreichbar: `ssh sshd@192.168.2.215 docker ps`

---

## Gelernte Lektionen

### 2026-02-08 - Initiale Erstellung

**Instanz-Differenzierung:**
- Docker Desktop auf Windows ist eine Entwicklungsumgebung, nicht Produktion
- NAS-Docker (docker-admin Skill) läuft dauerhaft mit 15+ Services
- Windows-Docker wird bei Bedarf gestartet und nach Tests wieder gestoppt
- UNC-Pfade als Volume-Mounts sind nicht möglich — nur lokale Windows-Pfade
