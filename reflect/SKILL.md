# Reflect Skill – Selbstverbesserung für Diana's Skills

| name | description |
|------|-------------|
| reflect | Analysiere die aktuelle Session und schlage Verbesserungen für Skills vor. Nutze wenn Diana sagt "reflect", "lerne daraus", "merk dir das", oder am Ende skill-intensiver Sessions. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Stell dir vor, du hast einen Helfer, der sich nach jedem Gespräch hinsetzt und nachdenkt:
- "Was habe ich falsch gemacht?"
- "Was hat Diana korrigiert?"
- "Was hat gut funktioniert?"

Dann schreibt er das alles in sein Notizbuch, damit er es beim nächsten Mal besser macht. Das ist der Reflect-Skill!

---

## Trigger (Wann wird dieser Skill aktiviert?)

Führe `/reflect` oder `/reflect [skill-name]` aus nach einer Session, in der du einen Skill genutzt hast.

**Beispiele:**
```
/reflect                     → Claude fragt, welchen Skill analysieren
/reflect pflege-dokumentation → Analysiert direkt den Pflege-Skill
/reflect n8n-workflow        → Analysiert den n8n-Skill
```

---

## Workflow

### Step 1: Skill identifizieren

Falls kein Skill-Name angegeben wurde, frage:

```
Welchen Skill soll ich für diese Session analysieren?
- pflege-dokumentation (Medifox, Pflegesoftware)
- n8n-workflow (Automatisierungen)
- docker-admin (Container-Management)
- rag-system (RAG-Pipelines, Vektordatenbank)
- [anderer]
```

### Step 2: Konversation analysieren

Suche nach diesen Signalen in der aktuellen Konversation:

#### Korrekturen (HOHE Konfidenz) 🔴
Diana erkennt man an Aussagen wie:
- "Nein", "nicht so", "ich meinte..."
- "Das ist falsch bei Medifox..."
- "So funktioniert das nicht in n8n..."
- Diana hat den Output explizit korrigiert
- Diana hat sofort nach Generierung Änderungen verlangt

#### Erfolge (MITTLERE Konfidenz) 🟡
- Diana sagte "perfekt", "genau so", "ja", "exakt"
- Diana hat den Output ohne Änderung akzeptiert
- Diana hat auf dem Output aufgebaut

#### Edge Cases (MITTLERE Konfidenz) 🟡
- Fragen, die der Skill nicht vorhergesehen hat
- Szenarien, die Workarounds erforderten
- Features, die Diana wollte, aber nicht abgedeckt waren

#### Präferenzen (akkumulieren über Sessions)
- Wiederholte Muster in Diana's Entscheidungen
- Stil-Präferenzen (z.B. immer deutsche Variablennamen)
- Tool/Framework-Präferenzen (z.B. Python statt JavaScript)
- Medifox-spezifische Konventionen
- n8n-Node-Präferenzen

### Step 3: Änderungen vorschlagen

Präsentiere die Erkenntnisse mit barrierefreien Farben (WCAG AA 4.5:1 Kontrastverhältnis):

```
┌─ Skill Reflexion: [skill-name] ─────────────────────────┐
│ Signale: X Korrekturen, Y Erfolge                        │
│                                                          │
│ Vorgeschlagene Änderungen:                               │
│                                                          │
│ 🔴 [HOCH]  + Constraint hinzufügen: "[spezifisch]"       │
│ 🟡 [MITTEL] + Präferenz hinzufügen: "[spezifisch]"       │
│ 🔵 [NIEDRIG] ~ Zur Überprüfung: "[beobachtung]"          │
│                                                          │
│ Commit: "[skill]: [zusammenfassung]"                     │
└──────────────────────────────────────────────────────────┘

Diese Änderungen anwenden? [J]a / [N]ein / oder Anpassungen beschreiben
```

**Farbpalette (ANSI-Codes für Terminal):**
- HOCH: `\033[1;31m` (fettes Rot #FF6B6B - 4.5:1 auf dunkel)
- MITTEL: `\033[1;33m` (fettes Gelb #FFE066 - 4.8:1 auf dunkel)
- NIEDRIG: `\033[1;36m` (fettes Cyan #6BC5FF - 4.6:1 auf dunkel)
- Reset: `\033[0m`

**Vermeide:** Reines Rot (#FF0000) auf Schwarz, Grün auf Rot (Farbenblinde)

**Benutzer-Optionen:**
- J → Änderungen anwenden, committen und pushen
- N → Dieses Update überspringen
- Oder Anpassungen in natürlicher Sprache beschreiben

### Step 4: Falls akzeptiert

1. Lies die aktuelle Skill-Datei von `~/.claude/skills/[skill-name]/SKILL.md`
2. Wende die Änderungen mit dem Edit-Tool an
3. Führe Git-Befehle aus:
   ```bash
   cd ~/.claude/skills
   git add [skill-name]/SKILL.md
   git commit -m "[skill]: [änderungszusammenfassung]"
   git push origin main
   ```
4. Bestätige: "Skill aktualisiert und zu GitHub gepusht"

### Step 5: Falls abgelehnt

Frage: "Möchtest du diese Beobachtungen für spätere Überprüfung speichern?"

Falls ja, hänge an `~/.claude/skills/[skill-name]/OBSERVATIONS.md` an

---

## Beispiel-Session

Diana arbeitet an einem n8n-Workflow und korrigiert Claude mehrmals:

**Dialog:**
```
Diana: "Erstelle einen Workflow für PDF-Verarbeitung"
Claude: *erstellt mit HTTP Request Node*
Diana: "Nein, nutze den Webhook-Node, nicht HTTP Request!"
Claude: *korrigiert*
Diana: "Perfekt! Und verbinde das mit Supabase"
Claude: *verbindet*
Diana: "Die Credentials heißen bei mir immer 'supabase-prod', nicht 'Supabase'"
```

**Diana ruft auf:** `/reflect n8n-workflow`

**Output:**
```
┌─ Skill Reflexion: n8n-workflow ─────────────────────────┐
│ Signale: 2 Korrekturen, 1 Erfolg                         │
│                                                          │
│ Vorgeschlagene Änderungen:                               │
│                                                          │
│ 🔴 [HOCH]  + Constraints/NIEMALS:                        │
│            "HTTP Request Node für eingehende Daten -     │
│             nutze stattdessen Webhook Node"              │
│ 🔴 [HOCH]  + Credentials-Naming:                         │
│            "Supabase-Credentials heißen 'supabase-prod'" │
│ 🟡 [MITTEL] + Workflow-Pattern:                          │
│            "PDF → Webhook → Verarbeitung → Supabase"     │
│                                                          │
│ Commit: "n8n-workflow: webhook statt http, credentials"  │
└──────────────────────────────────────────────────────────┘

Diese Änderungen anwenden? [J]a / [N]ein / oder Anpassungen beschreiben
```

---

## Git-Integration

Dieser Skill hat die Berechtigung:
- Skill-Dateien zu lesen von `~/.claude/skills/`
- Skill-Dateien zu editieren (mit Diana's Zustimmung)
- `git add`, `git commit`, `git push` im Skills-Verzeichnis auszuführen

Das Skills-Repository sollte bei `~/.claude/skills` initialisiert sein mit einem Remote Origin.

---

## Wichtige Regeln

1. **IMMER** die exakten Änderungen zeigen VOR dem Anwenden
2. **NIEMALS** Skills ohne explizite Benutzer-Zustimmung ändern
3. Commit-Messages sollten kurz und beschreibend sein
4. Push NUR nach erfolgreichem Commit
5. Bei deutschen Begriffen: Nutze deutsche Commit-Messages

---

## Toggle-Befehle (für automatisches Lernen)

```bash
reflect on      # Automatisches Lernen am Session-Ende aktivieren
reflect off     # Automatisches Lernen deaktivieren
reflect status  # Aktuellen Status anzeigen
```

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->
## Gelernte Lektionen

### 2026-01-11 - Setup-Session

**GitHub-Authentifizierung:**
- GitHub erlaubt keine Passwörter mehr → Personal Access Token (PAT) nutzen
- Fine-grained Tokens brauchen "Contents: Read and write" Berechtigung

**Diana's GitHub:**
- Organisation: `jahcoozi92-collab` (nicht persönlicher Account)
- Repository: `github.com/jahcoozi92-collab/claude-skills`

**Systeme:**
- Yoga7: `~/claude-skills` (Original) + Symlink `~/.claude/skills`
- Windows: `$HOME\.claude\skills`
- NAS: `/home/Jahcoozi/.claude/skills`

**Workarounds:**
- GNOME Keyring umgehen: `GIT_ASKPASS="" git push`
- Windows hat kein nano → `notepad` nutzen


*Noch keine Learnings erfasst. Führe `/reflect` nach einer Session aus!*
