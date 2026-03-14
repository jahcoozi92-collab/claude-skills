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
