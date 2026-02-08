# Skill: yoga7-admin

| name | description |
|------|-------------|
| yoga7-admin | Verwaltung der Yoga7-Instanz (Dianas Laptop): CLAUDE.md, Architektur-Locks, lokale Entwicklungsumgebung. Nicht fuer NAS oder moltbot VM. |

## Scope — NUR Yoga7

Diese Skill gilt **ausschliesslich** fuer:
- **Host:** Yoga7 (Dianas Laptop)
- **User:** yoga7 (oder aktueller User)
- **Zweck:** Primaere Entwicklungsmaschine, Claude Code, Skills-Verwaltung

**Nicht** fuer:
- NAS DXP4800PLUS-30E (192.168.22.90, User: Jahcoozi)
- moltbot VM (192.168.22.206, User: moltbotadmin)
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
| moltbot-admin | moltbot VM | 192.168.22.206 |
| nas-instance | NAS DXP4800 | 192.168.22.90 |

---

## Schutz-Operationen

### CLAUDE.md schuetzen
```bash
chmod 444 ~/CLAUDE.md
sudo chattr +i ~/CLAUDE.md
```

### Schutz pruefen
```bash
lsattr ~/CLAUDE.md
```

### Entsperren (fuer Updates)
```bash
sudo chattr -i ~/CLAUDE.md
```

---

## Gelernte Lektionen

### 2026-02-08 — Initiale Einrichtung

- Instanz-Skills auf allen drei Maschinen angelegt
- Shared Skills-Repo verhindert Verwechslungen durch klare Scope-Sektionen
- Architecture Locks + chattr +i als Guardrail gegen Agent-Aenderungen

### 2026-02-08 — SSH-Setup & Claude Update

**SSH-Konnektivität:**
- SSH-Key (`id_ed25519`) auf moltbot VM (.206) eingerichtet
- NAS (.90) hatte bereits SSH-Key-Zugang
- fail2ban ist auf moltbot VM nicht installiert
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

# moltbot VM synchronisieren
ssh moltbotadmin@192.168.22.206 'cd ~/.claude/skills && git pull --rebase origin main'
```
