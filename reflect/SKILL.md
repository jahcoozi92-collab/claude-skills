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
5. **Ontology aktualisieren** — PFLICHT nach jedem Reflect:
   - Ontology liegt auf **Clawbot VM** (192.168.22.206), NICHT auf NAS
   - Script: `~/clawd/skills/ontology/scripts/ontology.py` (NICHT `~/clawd/ontology.py`)
   - **Via SSH selbst ausführen** (nicht User zum Copy-Pasten auffordern):
   ```bash
   ssh moltbotadmin@192.168.22.206 'cd ~/clawd/skills/ontology/scripts && \
   python3 ontology.py create -t Software -p "{\"name\":\"X\",\"desc\":\"Y\"}" && \
   python3 ontology.py create -t Pattern -p "{\"name\":\"X\",\"desc\":\"Y\"}" && \
   python3 ontology.py create -t Task -p "{\"name\":\"X\",\"desc\":\"Y\"}"'
   ```
   - **CLI-Syntax**: `-t TYPE -p '{"name":"...","desc":"..."}'` (NICHT `--name`/`--desc`)
   - GRANULAR: eine Entity pro Konzept/Tool/Erkenntnis, nicht eine Meta-Entity pro Session
   - Checkliste: Neue Software? Patterns? Tasks? Relationen?

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
- Yoga7: `~/claude-skills` (Original) + Symlink `~/.claude/skills` → Instanz-Skill: `yoga7-admin`
- Windows: `$HOME\.claude\skills` → Instanz-Skill: `windows-admin`
- NAS: `/home/Jahcoozi/.claude/skills` → Instanz-Skill: `nas-instance`
- Clawbot VM: `/home/moltbotadmin/.claude/skills` → Instanz-Skill: `clawdbot-admin`

**Workarounds:**
- GNOME Keyring umgehen: `GIT_ASKPASS="" git push`
- Windows hat kein nano → `notepad` nutzen

---

### 2026-02-08 - Instanz-Skills + Architecture Locks

**Multi-Maschinen Instanz-Verwaltung:**
- Jede Maschine bekommt einen eigenen Instanz-Skill mit klarer Scope-Sektion
- Shared Git Repo (`jahcoozi92-collab/claude-skills`) — alle Maschinen sehen alle Skills
- Scope-Sektion am Anfang jedes Instanz-Skills verhindert Cross-Machine Verwechslungen

**Instanz-Skills erstellt:**
| Skill | Maschine | IP | User |
|-------|----------|-----|------|
| `clawdbot-admin` | Clawbot VM | 192.168.22.206 | moltbotadmin |
| `nas-instance` | NAS DXP4800 | 192.168.22.90 | Jahcoozi |
| `yoga7-admin` | Yoga7 Laptop | 192.168.22.86 | yoga7 |
| `windows-admin` | Windows 11 PC | 192.168.2.38 | Diana |

**CLAUDE.md Schutz-Eskalation:**
- `chmod 444` — Basis, Owner kann umgehen
- `chattr +i` — Stark, braucht sudo zum Aufheben (Linux)
- Windows: `Set-ItemProperty IsReadOnly` oder NTFS ACLs

**Architecture Lock Pattern:**
- `~/architecture/ARCHITECTURE_LOCK.md` dokumentiert gelockte Strukturen
- Erstellt auf: Clawbot VM, NAS (Yoga7 + Windows manuell)

**CLAUDE.md Rewrite (Clawbot VM):**
- Module-Tabelle (20 Zeilen, 14 fehlend) ersetzt durch Message-Flow-Diagramm
- Coverage-Threshold korrigiert (55% → 70% Branches)
- Workspace-Sektion ergaenzt (Memory-Konzept war undokumentiert)
- Drei-Stufen Hierarchie: Root → clawd/ → clawdbot-src/AGENTS.md

---

### 2026-02-08 - Always-On Constraints Pattern

**Problem:** Skill-Lektionen sind nur aktiv wenn der Skill aufgerufen wird.

**Lösung: Zwei-Stufen-System**
```
~/CLAUDE.md (immutable, immer geladen)
├── ## Always-On Constraints ← Kritische Regeln
│   ├── Credentials (supabase-prod, nextcloud-nas)
│   ├── n8n Kern-Regeln (Webhook statt HTTP Request)
│   ├── Instanzen-Tabelle (alle 4 Maschinen)
│   └── Code Style Präferenzen
│
└── Skills (bei /skill-name Aufruf geladen)
    └── Detaillierte, skill-spezifische Regeln
```

**Wann gehört etwas in Always-On Constraints?**
- Credential-Namen (werden überall gebraucht)
- Instanzen-Verwechslungsgefahr (IP, User)
- Kritische NIEMALS-Regeln die skill-übergreifend gelten
- Allgemeine Präferenzen (deutsche Variablen, Commit-Style)

**Wann bleibt es im Skill?**
- Skill-spezifische Details (n8n Node-Konfiguration)
- Kontext-abhängige Regeln
- Ausführliche Beispiele und Patterns

**Workflow für neue Always-On Constraints:**
1. `sudo chattr -i ~/CLAUDE.md` (entsperren)
2. Regel zur "Always-On Constraints" Sektion hinzufügen
3. `sudo chattr +i ~/CLAUDE.md` (sperren)

---

### 2026-02-01 - RAG-System Optimierung

**Supabase Vektor-Architektur:**
- HNSW-Index mit `halfvec(3072)` umgeht das 2000-Dim Limit von pgvector
- Index-Parameter: `m = 16, ef_construction = 64`
- Suchzeit: 3032ms → 22ms (134x schneller)
- Auto-Sync Trigger: `trg_sync_embedding_half` synchronisiert embedding → embedding_half

**match_documents Boost-System:**
| Bedingung | Boost |
|-----------|-------|
| source = 'system_reference' | +0.20 |
| priority = 'critical' | +0.15 |
| quality = 'high' | +0.05 |
| source = 'manual_enrichment' | +0.03 |

**HNSW Query-Optimierung:**
```sql
SET LOCAL hnsw.ef_search = 100;
```

**n8n Chat-History Persistenz:**
- Von `memoryBufferWindow` → `memoryPostgresChat`
- Credentials: NAS PostgreSQL (ID: cx83gXjDOqCuXZtm)
- Tabelle: `n8n_chat_histories`
- SessionKey: `={{ $json.sessionId || 'default' }}`

**MD Stationär - Korrekte Menüpfade:**
- Maßnahmenplanung: `Verwaltung → Bewohner → [Bewohner] → Reiter Planung`
- Textbausteine: `Administration → Dokumentation → Kataloge/Textbausteine`
- Pflegemappe: `Dokumentation → Dokumentation → [Bewohner]`
- Checklisten erstellen/importieren: `Dokumentation → Dokumentation → [Bewohner] → Stammdaten → Zahnrad (Import) oder Fragebögen → Neu`
- Checklisten-Status einsehen: `Verwaltung → Bewohner → [Bewohner] → Bewohnercockpit → Status`
- Fragebögen = Formulare = Checklisten (gleiche Erstellungsfunktion)
- FALSCH war: `Pflege/Betreuung → Dokumentation → Pflegemappe` (Web-Recherche lieferte falsches Ergebnis)

**Architektur-Insight:**
- Hybrid Search = Vektor-Ähnlichkeit (HNSW) + Full-Text-Search (FTS) + Boost-System
- `system_reference` Dokumente werden für autoritative Antworten priorisiert

**Credentials (Referenz):**
- Supabase Project: `wfklkrgeblwdzyhuyjrv`
- n8n Workflow: `SJ47UX9mv8wh1Wwy`
- Navigationsdokument ID: `368297`
- Korrigiertes Dokument ID: `368064`

---

### 2026-02-12 - Reflect auf Nicht-Skill-Sessions

**Instanz-Skill als Fallback:**
- Wenn eine Session keinen expliziten Skill nutzt (z.B. reine Config-Optimierung, System-Administration), ist der jeweilige **Instanz-Skill** der richtige Ziel-Skill fuer Reflect
- Instanz-Skills: `clawdbot-admin`, `nas-instance`, `yoga7-admin`, `windows-admin`
- Heuristik: Betrifft die Arbeit eine bestimmte Maschine? → Instanz-Skill. Betrifft sie ein Fach-Thema? → Fach-Skill

**JSON-Config und Learn-by-Doing:**
- JSON unterstuetzt keine Kommentare → `TODO(human)` kann nicht inline platziert werden
- Workaround: Helper-Script (z.B. `/tmp/voice-test.mjs`) erstellen, TODO(human) dort platzieren
- Config mit funktionierendem Default schreiben, User passt ueber Script/CLI an

---

### 2026-03-16 - Ontology-Pflicht + Granularitaet

**Ontology-Update ist PFLICHT nach jedem Reflect:**
- Erste Ontology-Runde dieser Session hatte nur 5 Entities — User fragte "Warum nicht mehr?"
- Korrekte Runde: 16 Entities (7 Software, 6 Patterns, 3 Tasks) + 12 Relationen
- Regel: Eine Entity pro Konzept/Tool/Erkenntnis, nicht eine Meta-Entity pro Session
- Checkliste nach jedem Reflect: Neue Software? Patterns? Tasks? Relationen?
- Step 4 im Workflow um Ontology-Pflichtschritt erweitert

### 2026-03-24 - Ontology CLI-Syntax + VM-Pfad

**ontology.py CLI-Syntax (KRITISCH):**
- FALSCH: `python3 ontology.py create --type Software --name "X" --desc "Y"`
- RICHTIG: `python3 ontology.py create -t Software -p '{"name":"X","desc":"Y"}'`
- Properties werden als JSON-String via `-p`/`--props` übergeben, nicht als einzelne Flags

**Ontology-Pfad auf Clawbot VM:**
- FALSCH: `~/clawd/ontology.py`
- RICHTIG: `~/clawd/skills/ontology/scripts/ontology.py`

**VM-Befehle selbst ausführen:**
- Diana bevorzugt, dass Claude komplexe Multi-Befehle via SSH selbst ausführt
- Grund: Terminal-Pasting bricht bei Zeilenumbrüchen, Quoting und Sonderzeichen
- Pattern: `ssh moltbotadmin@192.168.22.206 'cd ... && python3 ...'`
