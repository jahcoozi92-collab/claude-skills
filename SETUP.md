# 🛠️ Setup-Anleitung für Self-Improving Skills

Diese Anleitung zeigt dir Schritt für Schritt, wie du die Skills auf deinen Systemen einrichtest.

---

## System-Übersicht: Wo läuft was?

```
┌─────────────────────────────────────────────────────────────────┐
│                        DIANA'S SETUP                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      │
│  │   YOGA7     │      │   WINDOWS   │      │    NAS      │      │
│  │ Kali Linux  │      │     11      │      │   UGREEN    │      │
│  │             │      │             │      │             │      │
│  │ Claude Code │      │ Claude Code │      │  Docker     │      │
│  │ Git         │      │ Git         │      │  n8n        │      │
│  │ Skills-Repo │      │ Skills-Repo │      │  Ollama     │      │
│  └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      │
│         │                    │                    │              │
│         └────────────────────┼────────────────────┘              │
│                              │                                   │
│                       ┌──────▼──────┐                           │
│                       │   GitHub    │                           │
│                       │ Skills-Repo │                           │
│                       └─────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Schritt 1: GitHub Repository erstellen

### Im Browser:

1. Gehe zu https://github.com/new
2. Repository-Name: `claude-skills` (oder wie du willst)
3. **Private** auswählen (wichtig für deine Daten!)
4. NICHT "Add README" anklicken (wir haben schon eins)
5. Create Repository

### Repository-URL notieren:
```
https://github.com/DEIN-USERNAME/claude-skills.git
```

---

## Schritt 2: Auf YOGA7 (Kali Linux) einrichten

```bash
# ═══════════════════════════════════════════════════════════════
# YOGA7-LINUX: Skills-Repository einrichten
# ═══════════════════════════════════════════════════════════════

# 1. Ins Home-Verzeichnis wechseln
cd ~

# 2. Claude-Ordner erstellen (falls nicht vorhanden)
mkdir -p .claude/skills

# 3. Skills-Dateien kopieren (von wo du sie heruntergeladen hast)
# OPTION A: Wenn du die Dateien als ZIP hast
unzip diana-skills.zip -d .claude/skills

# OPTION B: Wenn du die Dateien einzeln hast
cp -r /pfad/zu/diana-skills/* .claude/skills/

# 4. Git initialisieren
cd ~/.claude/skills
git init

# 5. Alle Dateien hinzufügen
git add .

# 6. Erster Commit
git commit -m "Initial: Self-improving skills setup"

# 7. GitHub als Remote hinzufügen (DEINE URL einsetzen!)
git remote add origin https://github.com/DEIN-USERNAME/claude-skills.git

# 8. Zum GitHub pushen
git branch -M main
git push -u origin main

# 9. Prüfen ob alles geklappt hat
git status
```

---

## Schritt 3: Auf WINDOWS-ARBEITSRECHNER einrichten

```powershell
# ═══════════════════════════════════════════════════════════════
# WINDOWS-ARBEITSRECHNER: Skills vom GitHub klonen
# ═══════════════════════════════════════════════════════════════

# 1. PowerShell als Administrator öffnen

# 2. Ins User-Verzeichnis wechseln
cd $HOME

# 3. Claude-Ordner erstellen
New-Item -ItemType Directory -Force -Path ".claude\skills"

# 4. Repository klonen (DEINE URL einsetzen!)
git clone https://github.com/DEIN-USERNAME/claude-skills.git .claude\skills

# 5. Prüfen
cd .claude\skills
git status
```

---

## Schritt 4: Auf NAS (UGREEN) - Optional

Falls du auch auf dem NAS Claude Code nutzt:

```bash
# ═══════════════════════════════════════════════════════════════
# NAS via SSH: Skills klonen
# ═══════════════════════════════════════════════════════════════

# 1. Per SSH verbinden
ssh admin@192.168.22.90

# 2. Ins richtige Verzeichnis wechseln
cd ~

# 3. Claude-Ordner erstellen
mkdir -p .claude/skills

# 4. Repository klonen
git clone https://github.com/DEIN-USERNAME/claude-skills.git .claude/skills
```

---

## Schritt 5: Claude Code konfigurieren

### Variante A: Über CLAUDE.md (empfohlen)

Erstelle oder bearbeite `~/.claude/CLAUDE.md`:

```markdown
# Claude Code Konfiguration

## Skills
Lade Skills aus: ~/.claude/skills/

## Verfügbare Skills:
- reflect: Lerne aus Sessions
- pflege-dokumentation: Medifox, DAN, Pflegesoftware
- n8n-workflow: Automatisierungen
- docker-admin: Container-Management
- rag-system: RAG-Pipelines

## Nutzung:
Nach jeder Session kannst du `/reflect` aufrufen, um Learnings zu speichern.
```

### Variante B: Über Claude Code Settings

In Claude Code:
1. Öffne Settings
2. Suche "Skills Directory"
3. Setze auf: `~/.claude/skills`

---

## Schritt 6: Ersten Test durchführen

In Claude Code:

```
Du: Hallo Claude! Kannst du mir sagen, welche Skills du kennst?

[Claude sollte die Skills auflisten]

Du: /reflect status

[Claude sollte den Reflect-Status anzeigen]
```

---

## Synchronisation zwischen Systemen

### Änderungen PUSHEN (nach Reflect auf einem System):

```bash
cd ~/.claude/skills
git add .
git commit -m "Reflect: [skill-name] gelernt"
git push
```

### Änderungen HOLEN (auf anderem System):

```bash
cd ~/.claude/skills
git pull
```

### Automatisches Sync-Script (optional)

Erstelle `~/.claude/skills/sync.sh`:

```bash
#!/bin/bash
cd ~/.claude/skills
git pull
git add .
git commit -m "Auto-sync: $(date +%Y-%m-%d_%H:%M)"
git push
```

---

## 🔧 Troubleshooting

### Problem: Git fragt nach Passwort

**Lösung:** SSH-Key einrichten oder Git Credential Helper

```bash
# Credential Helper aktivieren (speichert Passwort)
git config --global credential.helper store
```

### Problem: Skills werden nicht erkannt

**Prüfe:**
1. Ist der Pfad korrekt? `ls ~/.claude/skills/`
2. Haben die Dateien die richtige Struktur?
3. Ist Claude Code neu gestartet?

### Problem: Merge-Konflikte

```bash
# Status prüfen
git status

# Bei Konflikten: Datei öffnen, Konflikte lösen
# Dann:
git add .
git commit -m "Merge-Konflikt gelöst"
git push
```

---

## 📅 Empfohlener Workflow

### Täglich:
1. Arbeiten mit Claude Code
2. Bei Korrekturen: `/reflect [skill]` am Ende
3. Änderungen akzeptieren oder ablehnen

### Wöchentlich:
1. `git pull` auf allen Systemen
2. OBSERVATIONS.md durchschauen
3. Eventuell manuelle Skill-Anpassungen

### Monatlich:
1. Git-History reviewen: Wie hat sich der Skill entwickelt?
2. Veraltete Learnings entfernen
3. Skill-Struktur optimieren

---

## 📞 Quick Reference: Befehle pro System

### YOGA7-LINUX
```bash
cd ~/.claude/skills && git pull                    # Updates holen
cd ~/.claude/skills && git add . && git commit -m "msg" && git push  # Updates pushen
```

### WINDOWS-ARBEITSRECHNER
```powershell
cd $HOME\.claude\skills; git pull                  # Updates holen
cd $HOME\.claude\skills; git add .; git commit -m "msg"; git push    # Updates pushen
```

### NAS (via SSH)
```bash
ssh admin@192.168.22.90 "cd ~/.claude/skills && git pull"  # Remote pull
```

---

*Setup-Anleitung erstellt von Claude für Diana* 🚀
