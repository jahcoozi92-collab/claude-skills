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
3. **Commit lokal** (Push als separater Schritt, siehe 3b):
   ```bash
   cd ~/.claude/skills
   git add [skill-name]/SKILL.md
   git commit -m "[skill]: [änderungszusammenfassung]"
   ```
3a. **Vor Push: Multi-Instanz-Rebase** — auf jeder Maschine läuft eine Claude-Instanz, die parallel committet (Yoga7/Clawbot/NAS/Windows). Push fails sonst mit `non-fast-forward`:
   ```bash
   git fetch origin main
   git log --oneline HEAD..origin/main  # zeigt was andere Instanzen gepusht haben
   git pull --rebase origin main         # rebased lokalen Commit drauf
   ```
3b. **Push als separater Schritt** — Auto-Mode-Classifier blockt `git push origin main` oft, weil das "J" des Users den Reflect-Workflow approve t, NICHT automatisch den Push auf den Default-Branch:
   ```bash
   git push origin main
   ```
   Wenn blockiert: explizit beim User nachfragen — **die Frage MUSS das Wort "pushen" enthalten**, sonst akzeptiert der Classifier "ja" als Mehrdeutigkeit. Funktionierender Wording-Pattern (verifiziert 2026-05-29):
   - Claude: "Soll ich pushen?"
   - User: "ja pushen" oder "ja push" → Classifier lässt durch
   - User: nur "ja" oder "J" → Classifier kann erneut blocken (Mehrdeutigkeit)
4. Bestätige: "Skill aktualisiert und zu GitHub gepusht (Commit-Hash)"
5. **Ontology aktualisieren** — PFLICHT nach jedem Reflect:
   - **Yoga7:** Ontology ist LOKAL verfügbar — `cd ~/clawd && python3 skills/ontology/scripts/ontology.py [command]`
   - **Andere Maschinen:** Via SSH auf Clawbot VM (192.168.22.206): `ssh moltbotadmin@192.168.22.206 'cd ~/clawd && python3 skills/ontology/scripts/ontology.py [command]'`
   - **CLI-Syntax**: `-t TYPE -p '{"name":"...","desc":"..."}'` (NICHT `--name`/`--desc`)
   ```bash
   cd ~/clawd
   python3 skills/ontology/scripts/ontology.py create -t Software -p '{"name":"X","desc":"Y"}'
   python3 skills/ontology/scripts/ontology.py create -t Pattern -p '{"name":"X","desc":"Y"}'
   python3 skills/ontology/scripts/ontology.py create -t Task -p '{"name":"X","desc":"Y"}'
   python3 skills/ontology/scripts/ontology.py relate --from <id> --rel <rel> --to <id>
   ```
   - GRANULAR: eine Entity pro Konzept/Tool/Erkenntnis, nicht eine Meta-Entity pro Session
   - Checkliste: Neue Software? Patterns? Tasks? Relationen?
   - **🔴 NIE mehrzeilige JSON-Befehle ins Terminal pasten** — Terminal-Paste trennt bei Zeilenumbruch `-p` von seinem JSON (`error: argument --props/-p: expected one argument`, JSON wird als eigener „Befehl" interpretiert). Stattdessen:
     - **Bevorzugt:** Claude führt die Befehle selbst aus (ein `create`/`relate` pro SSH-Call): `ssh moltbotadmin@192.168.22.206 'cd ~/clawd && python3 skills/ontology/scripts/ontology.py create ...'`
     - **Wenn der Auto-Mode-Classifier Cross-Host-SSH blockt** und der User selbst ausführen muss: alle Befehle in ein Skript schreiben und per **stdin-Pipe** an die VM geben — ein einziger kurzer Einzeiler, JSON-Quoting bleibt im File intakt:
       ```bash
       # Claude schreibt z.B. /tmp/ontology_update.sh (je 1 Zeile pro create/relate)
       # User führt von der QUELL-Maschine aus (Skript liegt dort, läuft via bash -s auf der VM):
       ssh moltbotadmin@192.168.22.206 'bash -s' < /tmp/ontology_update.sh
       ```
     - **🔴 Multi-Hop-Caveat (verifiziert 2026-05-29):** Die stdin-Pipe oben funktioniert NUR wenn der Skript-Pfad auf der Maschine existiert, von der der User SSH startet. Wenn das Skript auf einer dritten Maschine liegt (z.B. NAS), schlägt es fehl mit `Datei oder Verzeichnis nicht gefunden`.
       - **Fall A** (Skript auf User-Quell-Maschine): `ssh moltbotadmin@VM 'bash -s' < /lokaler/pfad.sh` ✓
       - **Fall B** (User auf Yoga, Skript auf NAS, Ziel ist Clawbot VM): zwei Schritte —
         ```bash
         # 1. User SSH'd zuerst zur Clawbot
         ssh moltbotadmin@192.168.22.206
         # 2. Auf Clawbot: Skript von NAS holen und ausführen (zwei einzelne Zeilen!)
         scp Jahcoozi@192.168.22.90:/volume1/docker/n8n/workflows/ontology/update.sh /tmp/
         bash /tmp/update.sh
         ```
       - **NICHT** `scp ... && bash ...` kombinieren — siehe Push-Lessons (Terminal-Paste-Bruch).
     - **🟡 KEIN `&&` in User-Befehlen (verifiziert 2026-05-29):** Auch wenn jeder Teil < 60 Zeichen ist, bricht Terminal-Paste die Verkettung auf. Beispiel-Fail: `scp Q:p /tmp/ && bash /tmp/p` (~85 Zeichen) → `bash: Syntaxfehler beim unerwarteten Symbol »&&«`. Immer separate, einzeln pasteable Zeilen liefern.
     - Skript-Reihenfolge: erst ALLE `create`, dann ALLE `relate` — Relations brauchen existierende Endpunkte, sonst dangling Edges.

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

### 2026-05-15 — Ontology-CLI: chmod, query --where, related-Format, ID-Convention

**🔴 ontology.py braucht chmod +x — Shebang allein reicht nicht**
- Datei hat `#!/usr/bin/env python3` als erste Zeile
- ABER: Default-Permissions sind `rw-rw-r--` (kein +x)
- Direkter Aufruf scheitert: `zsh: keine Berechtigung: ~/clawd/.../ontology.py`
- **Fix einmalig auf jeder Maschine:**
  ```bash
  chmod +x ~/clawd/skills/ontology/scripts/ontology.py
  ```
- Step 5 im Reflect-Workflow sollte einmaliger chmod-Check sein

**🔴 `ontology query` ist EXAKT-MATCH via `--where`, nicht Volltextsuche**
- FALSCH (war meine Annahme): `query -q "MQTT"` für Substring-Suche
- RICHTIG: `query --where '{"name":"yoga7-ha-bridge"}'` (exakte Property)
- Volltext-Workaround mit jq:
  ```bash
  ont list -t Pattern | jq '.[] | select(.properties.name | test("MQTT"; "i"))'
  ```
- Oder mit Python:
  ```bash
  ont list -t Software | python3 -c '
  import json, sys, re
  for e in json.load(sys.stdin):
      if re.search("X", json.dumps(e.get("properties",{})), re.I):
          print(e["id"], e["properties"].get("name"))'
  ```

**🔴 `ontology related` Output-Struktur — Keys: `relation` + `entity` (nested)**
- FALSCH (meine erste Annahme): `.[].rel`, `.[].target_id`
- RICHTIG:
  ```json
  [{
    "relation": "uses",
    "entity": {
      "id": "sw_paho_mqtt_v2",
      "type": "Software",
      "properties": {"name": "...", "desc": "..."}
    }
  }]
  ```
- jq-Parse:
  ```bash
  ont related --id sw_yoga7_ha_bridge | jq -r '.[] | "  --\(.relation)--> \(.entity.id) (\(.entity.properties.name))"'
  ```

**🟡 ID-Naming-Konvention für neue Entities — IMMER `--id` setzen**
- Konsequent: `sw_<name>` (Software), `p_<name>` (Pattern), `t_<name>` (Task)
- Beispiel: `--id sw_yoga7_ha_bridge` statt Auto-`soft_<hash>`
- Auto-IDs (`soft_a1b2c3d4`) entstehen wenn `--id` fehlt — schlechter durchsuchbar
- Bestehende Auto-IDs in der Graph: gewachsen über Sessions, neu erstellte konsequent saubere Prefixe

**🟡 Daily-Use-Filter-Patterns**
| Frage | Befehl |
|-------|--------|
| Heute neu erstellt? | `ont list -t Pattern \| jq '.[] \| select(.created > "2026-05-14") \| .properties.name'` |
| Volltext-Suche | `ont list -t Software \| jq '.[] \| select(.properties.name \| test("MQTT"; "i"))'` |
| Was nutzt X? | `ont related --id sw_X \| jq -r '.[] \| "\(.relation): \(.entity.id)"'` |
| Alle Anti-Patterns | `ont list -t Pattern \| jq '.[] \| select(.properties.name \| startswith("ANTI"))'` |

**🔵 Aliase + Symlinks für Daily-Use**
- Symlink: `ln -s ~/clawd/skills/ontology/scripts/ontology.py ~/.local/bin/ont`
- Voraussetzung: `~/.local/bin` im PATH (Debian/Kali Default ja, manche Distros nicht)
- zsh-Alias als Backup: `echo "alias ont='python3 ~/clawd/skills/ontology/scripts/ontology.py'" >> ~/.zshrc`
- Verify: `which ont`

### 2026-05-20 — Push-Confirm-Step, Multi-Instanz-Rebase, MEMORY-Concurrency

**🔴 Auto-Mode-Classifier blockt `git push origin main` trotz User-"J"**
- Reflect-Workflow-"J" approve t den Reflect-Vorschlag, NICHT pauschal Push auf Default-Branch
- Classifier-Reasoning: "User's 'J' approved /reflect but did not specifically authorize a push to the default branch"
- **Fix im Workflow**: commit als Schritt 3, push als separater Schritt 3b
- Wenn Push blockt: explizit beim User nachfragen ("Soll ich pushen?") — kostet eine kurze Iteration, ist aber sauber
- Niemals Push mit `--no-verify` o.ä. erzwingen wollen — Classifier ist absichtlicher Guard

**🔴 Multi-Instanz-Rebase ist Pflicht vor Push**
- 4 Maschinen pushen ins gleiche Repo (`jahcoozi92-collab/claude-skills`) — Race ist Regel, nicht Ausnahme
- Beispiel dieser Session: Yoga7 hat während meiner Reflexion `2070bd1 reflect: Jarvis-Multi-Skill` gepusht
- Push fails mit `non-fast-forward`
- **Pattern** vor jedem Push:
  ```bash
  git fetch origin main
  git log --oneline HEAD..origin/main   # was kam dazu?
  git pull --rebase origin main         # lokal sauber rebased
  git push origin main
  ```
- `rebase` > `merge` für Skill-Repo: linear, kein Merge-Noise

**🟡 MEMORY.md kann während Reflect von User/Linter geändert werden**
- Mitten in Step 4 kann ein `<system-reminder>` eintreffen, dass MEMORY.md modifiziert wurde
- Konkret: User hat `screenshot_drop.md`-Eintrag hinzugefügt während ich am Skill-Push war
- **NICHT reverten** — der Linter/User-Change ist absichtlich
- Memory-Reads zwischen Schritten erneuern, nicht aus initialer Context-Ladung cachen

### 2026-05-29 — Push-Wording, Multi-Hop-Pipe, kein && für User

**🟡 Push-Authorization-Wording: User-Antwort muss "pushen" enthalten**
- Vorherige Annahme (2026-05-20): User-"J" approve t nur Reflect-Vorschlag, nicht Push
- Verifiziert heute: nur "ja" ist mehrdeutig, "ja pushen" macht den Push-Intent eindeutig
- Push lief mit "ja pushen" sofort durch (kein Re-Block, kein Re-Prompt)
- Workflow-Fix: Push-Confirm-Frage MUSS das Wort "pushen" enthalten → User-Antwort wird dann automatisch mit "pushen" als Bestätigung formuliert
- Anti-Pattern: "Soll ich das pushen?" und User antwortet nur "J" → Classifier kann wieder blocken

**🔴 Multi-Hop-Pipe-Fail wenn User auf falscher Quell-Maschine startet**
- Workflow-Doc aus 2026-05-15: `ssh VM 'bash -s' < /path/script.sh`
- Stille Annahme: `/path/script.sh` ist auf der Maschine erreichbar, von der User SSH startet
- Heute live gescheitert: User startete von Yoga7 (zsh) mit Skript-Pfad auf NAS → 3 Iterationen mit `zsh parse error` und `Datei oder Verzeichnis nicht gefunden`, bis scp dazwischen kam
- **Konkrete Topologie** dieser Session:
  ```
  Yoga7 (User-Terminal)
   └─ SSH ──> Clawbot VM (Ontology-Ziel)
                                ↑
                                │ scp benötigt!
                                │
                                └── NAS (Skript-Quelle)
  ```
- **Workaround-Pattern** (in Step 5 ergänzt): User SSH'd zuerst zur Ziel-Maschine, holt das Skript per scp von der Quell-Maschine, führt es lokal aus

**🔵 Kein `&&` in User-Befehlen — auch wenn Gesamtlänge < 100 Zeichen ist**
- Vorherige Lesson (2026-05-29 nas-instance): "max 60 Zeichen, ein Wort + ein Pfad"
- Verfeinert: `&&` ist eigenständiger Bruch-Trigger unabhängig von Zeichenzahl
- Beispiel-Fail heute: `scp Q:/p /tmp/ && bash /tmp/p` (85 Zeichen) → `Syntaxfehler beim unerwarteten Symbol »&&«`
- Mechanismus: Terminal-Auto-Newline-Insertion vor jedem `&&` bei Multi-Line-Paste
- Lösung: separate Zeilen liefern, jede für sich pasteable

### 2026-06-01 — Ontology-Batch braucht `--id`, kurze Dateinamen, stdin-Pipe als Default

**🔴 `--id` ist auch in Batch-Skripten Pflicht — sonst dangling relations**
- Lesson 2026-05-15 sagte "IMMER `--id` setzen" — beim Schreiben des Ontology-Update-Skripts trotzdem vergessen
- Folge: alle `create` bekamen Auto-IDs (`patt_dd7adc60`, `soft_eb8cf223`, `task_742bbad0`), aber die `relate`-Befehle referenzierten die Convention-IDs (`p_…`, `sw_…`, `t_…`) → alle 8 Relationen liefen ins Leere (dangling, kein Fehler geworfen!)
- `ontology.py relate` validiert die Endpunkte NICHT — falsche IDs erzeugen stille Geister-Edges
- **Regel:** In jedem `create` explizit `--id <prefix>_<name>` setzen. Dann stimmen die `relate`-Referenzen automatisch. Wenn `--id` vergessen → `relate` mit den tatsächlichen Auto-IDs aus dem `create`-Output nachziehen.
- Verifikation IMMER ans Skript-Ende: `ont related --id <task>` zeigt, ob Edges real hängen

**🔴 Skript-Dateinamen für User-scp KURZ halten (Terminal-Paste bricht lange Namen um)**
- `fix_relations_2026_05_31.sh` (28 Zeichen Name) wurde beim Paste umgebrochen: `fix_relation` + Newline + `s_2026_05_31.sh` → `Kommando nicht gefunden`
- Auch das Leerzeichen vor `/tmp/` ging beim Paste verloren (`fixrel.sh/tmp/`)
- **Regel:** Skripte, die der User per scp/paste anfasst, kurz benennen (`fr.sh`, `ont.sh`) und an kurzem Pfad ablegen (`/volume1/docker/n8n/fr.sh`, nicht tief verschachtelt)

**🟡 stdin-Pipe ist robuster als Multi-Hop-scp — aber Skript erst auf User-Quell-Maschine holen**
- Was hier final funktionierte (User auf Yoga7, Skript auf NAS, Ziel Clawbot VM):
  ```
  scp Jahcoozi@NAS:/pfad/fr.sh /tmp/fr.sh        # NAS → Yoga7 (Zeile 1)
  ssh moltbotadmin@VM 'bash -s' < /tmp/fr.sh     # Yoga7 → VM via stdin (Zeile 2)
  ```
- Vorteil ggü. "User SSH'd zur VM, scp't von NAS": kein Passwort-Prompt mitten in der VM-Session, JSON-Quoting bleibt im File, nur 2 pasteable Zeilen
- Achten: User-Prompt-Zeichen prüfen (`~ ❯` = Yoga7, `moltbotadmin@…$` = VM) — User wechselt zwischen Schritten oft unbemerkt die Maschine

### 2026-06-01 — Push-403 ist NICHT der Classifier: falsches GitHub-Konto

**🔴 403 „Permission denied to <user>" ≠ Auto-Mode-Classifier-Block**
- Bisherige Lessons (2026-05-20/29) drehten sich nur um den Classifier. Hier ein anderer Fall: Push lief bis zum Remote durch und kam mit echtem GitHub-`403`: `remote: Permission to jahcoozi92-collab/claude-skills.git denied to Jahcoozi92`.
- Unterscheidung: Classifier-Block = Befehl wird gar nicht ausgeführt, KEIN Netzwerk-Roundtrip. GitHub-403 = `remote:`-Zeile + `The requested URL returned error: 403`.

**🔴 Wahre Ursache: mit dem FALSCHEN Konto angemeldet (NICHT "Org-OAuth-Sperre")**
- Diagnose-Befehle bei Push-403:
  ```bash
  gh api user --jq .login                       # wer bin ich gerade?
  gh api repos/jahcoozi92-collab/claude-skills --jq '{owner:.owner.login,type:.owner.type,push:.permissions.push}'
  ```
- Ergebnis hier: eingeloggt als `Jahcoozi92`, aber das Repo gehört dem SEPARATEN Account `jahcoozi92-collab` (Typ `User`, KEINE Organisation!). `Jahcoozi92` hatte nur Lesezugriff (`push:false`, nicht mal Collaborator).
- Merke: `jahcoozi92-collab` ist Dianas **zweites GitHub-Konto** (Repo-Owner), NICHT eine Org. Beim Web-Login landet gh leicht im falschen Konto.
- Fix: als `jahcoozi92-collab` authentifizieren (Token dieses Kontos), ODER `Jahcoozi92` als Collaborator mit Write hinzufügen.

**🔴 gh `--with-token` ist zickig — robuster: gh umgehen, Token direkt in git (store)**
- gh lehnt Tokens mit `missing required scope 'read:org'` ab: fine-grained PATs haben keine klassischen Scopes; selbst klassische brauchen `repo`+`read:org` NUR wegen gh.
- Für reinen `git push` reicht `repo` (classic) bzw. Contents:RW (fine-grained) — `read:org` NICHT nötig.
- Funktionierender Workaround (gh-Helper repo-lokal aushebeln, Token via store):
  ```bash
  cd ~/.claude/skills
  git config --local --replace-all credential.helper ""
  git config --local --add credential.helper store
  git remote set-url origin https://jahcoozi92-collab@github.com/jahcoozi92-collab/claude-skills.git
  # User fuehrt EINMAL interaktiv aus, Token am Passwort-Prompt einfuegen (kein Echo):
  git -C ~/.claude/skills push origin main
  ```
- Danach liegt der Token in ~/.git-credentials → künftige Pushes (auch von Claude) laufen ohne Prompt.

**🟡 Vor jedem Push-Retry Konto + permissions.push verifizieren**
- „push nochmal" ohne echten Fix trifft garantiert dasselbe 403 — erst `gh api user --jq .login` und `… --jq .permissions.push` prüfen.

**🔵 `gh auth login` Browser-Open wirft hier einen Node-Fehler — Auth läuft trotzdem durch**
- `$BROWSER` zeigt auf einen kaputten Wrapper → `Cannot find module '.../@anthropic-ai/claude-code/cli.js'`. Device-Code-Flow läuft dennoch durch; Fehlerzeilen kosmetisch.

### 2026-06-01 — Rebase-Konflikt an der Lektionen-Endregion + Auto-Push-Flow

**🔴 Reflect-Commits kollidieren beim Rebase fast immer an der „Gelernte Lektionen"-Endregion**
- Alle Instanzen (Yoga7/NAS/Clawbot/Windows) hängen neue Lektionen ans DATEI-ENDE → `git pull --rebase` erzeugt dort regelmäßig einen Konflikt. Das ist die Regel, nicht die Ausnahme.
- Diese Session: lokale Commits `n8n` + `reflect` gegen fremdes `62715d9 reflect: Ontology-Batch` → Konflikt nur im Reflect-Commit (n8n-Commit lief sauber durch).
- **Auflösung (beide Lektionen behalten, NIE eine verwerfen):**
  - Konfliktstil ist `diff3` → vier Marker: `<<<<<<<`, `|||||||` (Basis), `=======`, `>>>>>>>`.
  - Programmatisch per kleinem Python-Splice mergen (robuster als Edit bei großen Blöcken):
    ```python
    L=open(p).read().split("\n")
    a=next(i for i,l in enumerate(L) if l.startswith("<<<<<<<"))
    b=next(i for i,l in enumerate(L) if l.startswith("|||||||"))
    c=next(i for i,l in enumerate(L) if l.startswith("======="))
    d=next(i for i,l in enumerate(L) if l.startswith(">>>>>>>"))
    head=L[a+1:b]                      # fremde Lektion behalten
    mine=L[c+1:d]                      # eigene Lektion behalten
    open(p,"w").write("\n".join(L[:a]+head+[""]+mine+L[d+1:]))
    ```
  - Danach: `git add <datei>` + **`GIT_EDITOR=true git rebase --continue`** (GIT_EDITOR=true verhindert das Hängen am Editor-Prompt im non-interaktiven Bash-Tool).
- Verifikation: `grep -cE '^(<<<<<<<|=======|>>>>>>>)' <datei>` muss `0` ergeben, bevor weitergemacht wird.

**🟡 Auto-Push ist jetzt Standard-Flow (User-Präferenz, gespeichert)**
- User will NICHT mehr „pushen" bestätigen müssen → nach Commit direkt `git fetch` + `git pull --rebase` + `git push`, ohne Rückfrage.
- Voraussetzung ist erfüllt: Token liegt in `~/.git-credentials` (`store`-Helper), Remote auf `https://jahcoozi92-collab@github.com/...` gepinnt, globaler `gh auth git-credential`-Helper **repo-lokal ausgehebelt** (`credential.helper ""` + `store`). → Push läuft prompt-frei, auch von Claude aus.
- Der frühere „Frage-mit-Wort-pushen"-Schritt (2026-05-29) entfällt damit für dieses Repo — bleibt nur relevant, falls die Credentials mal fehlen.
