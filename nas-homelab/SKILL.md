# NAS Homelab Skill

| name | description |
|------|-------------|
| nas-homelab | NAS-Management, SMB/CIFS-Mounts, lokale KI-Setup, Docker auf NAS, OpenCode-Konfiguration. Nutze bei Fragen zu NAS, Mounts, Homelab-Setup, lokalen LLMs. |

---

## Trigger

Aktiviere diesen Skill bei:
- "NAS mounten", "SMB mount", "CIFS"
- "OpenCode auf NAS", "lokales LLM"
- "fstab", "persistent mount"
- "UGREEN", "DXP4800"
- "tmux", "SSH session"
- "Docker secrets", "API keys sichern"

---

## Diana's Homelab Setup

### Hardware
- **NAS:** UGREEN DXP4800PLUS-30E
- **IP:** 192.168.22.90
- **User:** Jahcoozi
- **Laptop:** Yoga7 (User: yoga7)

### Wichtige Pfade

| System | Pfad | Beschreibung |
|--------|------|--------------|
| NAS | `/volume1/docker/` | Docker-Projekte |
| NAS | `/home/Jahcoozi/` | Home-Verzeichnis |
| Laptop | `/mnt/nas/docker/` | NAS Docker-Mount |
| Laptop | `/mnt/nas/home/` | NAS Home-Mount |
| Laptop | `/mnt/nas/volume/` | NAS USB-Volume |

### SMB-Freigaben

| Freigabe | NAS-Pfad | Beschreibung |
|----------|----------|--------------|
| `personal_folder` | /home/Jahcoozi | Home-Verzeichnis |
| `docker` | /volume1/docker | Docker-Projekte |
| `Volume` | /mnt/@usb/sdc2 | USB-Festplatte |

---

## NAS Mounting (Linux)

### Credentials-Datei erstellen

```bash
sudo mkdir -p /etc/samba
sudo nano /etc/samba/nas-credentials
```

Inhalt:
```
username=Jahcoozi
password=DEIN_PASSWORT
domain=WORKGROUP
```

```bash
sudo chmod 600 /etc/samba/nas-credentials
```

### Mount-Punkte erstellen

```bash
sudo mkdir -p /mnt/nas/home /mnt/nas/docker /mnt/nas/volume
```

### fstab-Einträge

**WICHTIG:** Jede Zeile MUSS auf EINER Zeile stehen - KEINE Zeilenumbrüche!

```bash
sudo nano /etc/fstab
```

Hinzufügen:
```
//192.168.22.90/personal_folder /mnt/nas/home cifs credentials=/etc/samba/nas-credentials,uid=1000,gid=1000,iocharset=utf8,_netdev,nofail,x-systemd.automount 0 0
//192.168.22.90/docker /mnt/nas/docker cifs credentials=/etc/samba/nas-credentials,uid=1000,gid=1000,iocharset=utf8,_netdev,nofail,x-systemd.automount 0 0
//192.168.22.90/Volume /mnt/nas/volume cifs credentials=/etc/samba/nas-credentials,uid=1000,gid=1000,iocharset=utf8,_netdev,nofail,x-systemd.automount 0 0
```

### Mount-Optionen erklärt

| Option | Bedeutung |
|--------|-----------|
| `credentials=` | Pfad zur Credentials-Datei |
| `uid=1000,gid=1000` | Lokaler User bekommt Ownership |
| `_netdev` | Warte auf Netzwerk vor Mount |
| `nofail` | Boot nicht blockieren bei Fehler |
| `x-systemd.automount` | Auto-mount bei erstem Zugriff |

### Mounten

```bash
sudo systemctl daemon-reload
sudo mount -a
```

---

## SSH-Zugriff

### Alias einrichten

```bash
echo 'alias nas="ssh Jahcoozi@192.168.22.90"' >> ~/.zshrc
source ~/.zshrc
```

Dann einfach: `nas`

### SSH Keep-Alive (optional)

```bash
echo -e "Host 192.168.22.90\n  ServerAliveInterval 60\n  ServerAliveCountMax 3" >> ~/.ssh/config
```

---

## tmux für persistente Sessions

### Installation (auf NAS)

```bash
sudo apt update && sudo apt install tmux -y
```

### Wichtige Befehle

| Befehl | Funktion |
|--------|----------|
| `tmux new -s coding` | Neue Session "coding" starten |
| `Ctrl+B`, dann `D` | Session trennen (läuft weiter) |
| `tmux attach -t coding` | Session wieder verbinden |
| `tmux ls` | Alle Sessions anzeigen |
| `Ctrl+B`, dann `C` | Neues Fenster |
| `Ctrl+B`, dann `N` | Nächstes Fenster |
| `Ctrl+B`, dann `P` | Vorheriges Fenster |

### Workflow

```bash
ssh Jahcoozi@192.168.22.90
tmux new -s coding
cd /volume1/docker/open-webui
opencode
# Ctrl+B, D zum Trennen
# Später: tmux attach -t coding
```

---

## OpenCode mit lokalem LLM

### Ollama-Ports auf NAS

| Container | Port | Modelle |
|-----------|------|---------|
| ollama | 11436 | qwen2.5, glm4, nomic-embed-text |
| glm-4.7-flash | 11437 | GLM 4.7 Flash |

### OpenCode konfigurieren

```bash
mkdir -p ~/.opencode
echo '{"provider":"openai","baseURL":"http://localhost:11436/v1","model":"glm4"}' > ~/.opencode/config.json
```

### Modell zu Ollama hinzufügen

```bash
docker exec ollama ollama pull glm4
docker exec ollama ollama pull qwen2.5:7b
```

---

## Docker Secrets (Sicherheit)

### NIEMALS API-Keys in docker-compose.yml!

Stattdessen Docker Secrets nutzen:

```bash
# Secrets-Verzeichnis
mkdir -p /volume1/docker/open-webui/secrets
chmod 700 /volume1/docker/open-webui/secrets

# API-Key speichern
echo "sk-..." > /volume1/docker/open-webui/secrets/openai_api_key.txt
chmod 600 /volume1/docker/open-webui/secrets/openai_api_key.txt
```

In docker-compose.yml:
```yaml
secrets:
  openai_api_key:
    file: ./secrets/openai_api_key.txt

services:
  open-webui:
    secrets:
      - openai_api_key
    environment:
      - OPENAI_API_KEY_FILE=/run/secrets/openai_api_key
```

---

## OpenWebUI auf NAS

### Aktuelle Konfiguration

- **URL:** https://chat.forensikzentrum.com
- **Port:** 8080
- **Pfad:** `/volume1/docker/open-webui/`

### Default Models

```
qwen2.5:7b, gpt-4o, claude-sonnet-4-20250514
```

### Wichtige Services

| Service | Port | Funktion |
|---------|------|----------|
| open-webui | 8080 | Chat UI |
| ollama | 11436 | LLM Backend |
| searxng | 8081 | Web-Suche |
| openapi-filesystem | 8003 | Dateizugriff |
| openapi-memory | 8004 | Memory API |

---

## Troubleshooting

### Mount funktioniert nicht

```bash
# Prüfen
mount | grep nas
ls /mnt/nas/docker/

# Remounten
sudo mount -a

# Falls Fehler: Verzeichnisse neu erstellen
sudo mkdir -p /mnt/nas/home /mnt/nas/docker /mnt/nas/volume
sudo mount -a
```

### Permission denied beim Mount

Credentials-Datei prüfen:
```bash
sudo cat /etc/samba/nas-credentials
# Muss username=, password=, domain= enthalten
```

### fstab kaputt nach Heredoc

Heredocs funktionieren oft nicht richtig im Terminal. Stattdessen:
1. `sudo nano /etc/fstab`
2. Zeilen manuell einfügen
3. Speichern mit Ctrl+O, Enter, Ctrl+X

### Container startet nicht

```bash
cd /volume1/docker/open-webui
docker compose logs -f open-webui
docker compose ps
```

---

## Constraints

### NIEMALS
- API-Keys in docker-compose.yml im Klartext
- Heredocs für fstab-Einträge empfehlen
- Image-Tag `:main` oder `:latest` in Produktion
- `sudo` ohne Erklärung

### IMMER
- Credentials in separater Datei mit chmod 600
- Feste Image-Versionen (z.B. `:v0.5.6`)
- Mount-Optionen `_netdev,nofail` für NAS-Mounts
- CPU/Memory Limits in docker-compose.yml

---

## Gelernte Lektionen

### 2026-01-24 - Initiale Session

**NAS-Mounting:**
- UGREEN DXP4800 nutzt Standard-SMB, WORKGROUP als Domain
- `x-systemd.automount` für Auto-Mount bei Zugriff
- Jede fstab-Zeile MUSS auf einer Zeile stehen

**Terminal/Clipboard:**
- OpenCode fängt Clipboard-Shortcuts ab
- Workaround: Output in Datei umleiten oder Maus-Markierung

**OpenCode:**
- Config: `~/.opencode/config.json`
- Ollama-kompatibel mit `baseURL` + `/v1`

**Docker Secrets:**
- Open WebUI unterstützt `*_FILE` Suffix für Secrets
- Secrets-Verzeichnis mit chmod 700
