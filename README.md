# Diana's Self-Improving Skills für Claude Code

🧠 **Einmal korrigieren, nie wieder!**

Dieses Repository enthält selbst-verbessernde Skills für Claude Code, maßgeschneidert für Diana's Setup.

---

## 📁 Skill-Übersicht

| Skill | Beschreibung | Trigger |
|-------|--------------|---------|
| **[reflect](./reflect/SKILL.md)** | Meta-Skill zum Lernen aus Sessions | `/reflect` |
| **[pflege-dokumentation](./pflege-dokumentation/SKILL.md)** | Medifox, DAN, Pflegesoftware | automatisch |
| **[n8n-workflow](./n8n-workflow/SKILL.md)** | Workflow-Automatisierung | automatisch |
| **[docker-admin](./docker-admin/SKILL.md)** | Container-Management | automatisch |
| **[rag-system](./rag-system/SKILL.md)** | RAG-Pipelines, Vektordatenbanken | automatisch |

---

## 🚀 Setup-Anleitung

### 1. Repository klonen

```bash
# Auf deinem System
cd ~
git clone [DEIN-REPO-URL] .claude/skills
```

### 2. Claude Code konfigurieren

Füge in deiner Claude Code Config hinzu:
```json
{
  "skills_directory": "~/.claude/skills"
}
```

### 3. Erster Test

```bash
# In Claude Code
/reflect status
```

---

## 🔄 Wie funktioniert Self-Improvement?

```
Session mit Claude
       ↓
Du korrigierst etwas ("Nein, mach es SO")
       ↓
Am Ende: /reflect [skill-name]
       ↓
Claude analysiert die Korrekturen
       ↓
Schlägt Skill-Updates vor
       ↓
Du akzeptierst (J) oder lehnst ab (N)
       ↓
Skill wird aktualisiert + zu Git gepusht
       ↓
Nächste Session: Fehler passiert nicht mehr!
```

---

## 📊 Setup-Informationen

### Hardware
- **NAS:** UGREEN DXP4800PLUS-30E @ 192.168.22.90
- **Dev:** Yoga7 (Kali Linux)
- **Work:** Windows 11

### Services
- n8n (Port 5678)
- Ollama (Port 11434)
- Supabase (wfklkrgeblwdzyhuyjrv)
- NextCloud

---

## 📝 Manuelles Bearbeiten

Du kannst Skills auch manuell bearbeiten:

```bash
# Skill öffnen
nano ~/.claude/skills/[skill-name]/SKILL.md

# Änderungen committen
cd ~/.claude/skills
git add .
git commit -m "[skill-name]: manuelle Anpassung"
git push
```

---

## 🔧 Befehle

| Befehl | Was es tut |
|--------|------------|
| `/reflect` | Startet Reflexion, fragt nach Skill |
| `/reflect [name]` | Reflektiert spezifischen Skill |
| `reflect on` | Aktiviert automatisches Lernen |
| `reflect off` | Deaktiviert automatisches Lernen |
| `reflect status` | Zeigt aktuellen Status |

---

## 📈 Learnings verfolgen

Jeder Skill hat einen "Gelernte Lektionen" Abschnitt, der automatisch aktualisiert wird.

Du kannst auch die Git-History nutzen:
```bash
git log --oneline ./[skill-name]/SKILL.md
```

---

## 🤝 Contributing

Dieses Repository ist für Diana's persönlichen Gebrauch.
Bei Fragen oder Ideen: Einfach in der nächsten Claude-Session besprechen!

---

## 📜 Lizenz

Privates Repository. Nicht zur Weiterverbreitung bestimmt.

---

*Erstellt mit ❤️ von Claude für Diana*
