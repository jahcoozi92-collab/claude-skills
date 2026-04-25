---
name: prompt-coach
description: Foundation-Layer-Vorstufe zur prompting-muster-referenz. Zerlegt Roh-Prompts nach Context-Task-Rules, scannt Lücken und entscheidet, ob das einfache 3-Schritt-Schema reicht oder zu Tier-S-Patterns eskaliert werden muss. Trigger bei "hilf mir einen Prompt zu schreiben", "verbessere diesen Prompt", "schreibe einen Prompt für [Modell]", "wie frage ich Claude/GPT/Gemini am besten", "Prompt für [Aufgabe] bauen", "review meinen Prompt", "Prompt-Coaching".
---

# Prompt Coach – Foundation-Layer für Diana's Prompting-Library

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Bevor man eine komplizierte Maschine baut, schaut man erst, ob ein Schraubenzieher reicht. Dieser Skill ist der Schraubenzieher: Er prüft jeden neuen Prompt nach drei einfachen Fragen (Wer? Was? Wie?) und entscheidet, ob das schon genug ist – oder ob die große Werkzeugkiste (prompting-muster-referenz.md mit den 16 Patterns) geöffnet werden muss.

Dieser Skill **läuft immer zuerst**. Er ersetzt nichts, er filtert und routet.

---

## Wann triggert dieser Skill?

Trigger-Phrasen:
- "Hilf mir einen Prompt zu schreiben für [X]"
- "Verbessere / review meinen Prompt"
- "Schreibe einen Prompt für [Claude / GPT / Gemini]"
- "Wie frage ich [Modell] am besten nach [X]?"
- "Prompt-Coaching" / "Prompt-Review"
- Diana paste einen Roh-Prompt-Entwurf und fragt nach Optimierung

**KEIN Trigger:** Diana stellt direkt eine Aufgabe ("Schreibe mir die ICD-10-Liste für Bewohner X"). In diesem Fall ist Diana selbst der Prompt-Autor – kein Coaching nötig.

---

## Das 3-Schritt-Schema (Foundation-Layer)

Jeder Prompt wird gegen diese drei Achsen geprüft:

### 1. CONTEXT (Wer & Wo)
- Welche Rolle hat Diana in dieser Aufgabe?
- Welche Domäne (Pflege / RAG-Business / Korrespondenz / Technik)?
- Welcher Hintergrund-Kontext muss das Modell kennen?
- Welches Ziel verfolgt Diana mit dem Output?

### 2. TASK (Was)
- Welche konkrete Aktion (schreiben / analysieren / klassifizieren / coden / extrahieren)?
- Welcher Input liegt vor (Dokument / Daten / Beispiel)?
- Welcher Output wird erwartet (Format / Länge / Struktur)?
- Gibt es Teilschritte oder Abhängigkeiten?

### 3. RULES (Wie)
- Welcher Tonfall (formal-distanziert wie Bardenberger / fachlich-pflegerisch / technisch-präzise)?
- Welche Constraints (DSGVO / max. Wortzahl / Sprache / verbotene Begriffe)?
- Welche Beispiele zeigen das gewünschte Ergebnis?
- Welche Erfolgskriterien (woran erkennt Diana, dass der Output gut ist)?

---

## Workflow

### Step 1: Roh-Prompt entgegennehmen

Wenn Diana einen bestehenden Prompt zur Review gibt, **erst lesen, dann zerlegen**.
Wenn Diana nur eine Aufgabenidee skizziert ("Ich brauche einen Prompt, der mir die Pflegevisiten aus MD Stationär extrahiert"), **erst die drei Achsen abfragen**.

### Step 2: Context-Task-Rules-Dekomposition

Stelle den Roh-Input in einer Tabelle dar – was ist da, was fehlt:

    ┌─ Prompt-Dekomposition ──────────────────────────────────┐
    │ Achse        │ Vorhanden                │ Lücke         │
    ├──────────────┼──────────────────────────┼───────────────┤
    │ CONTEXT      │ [aus Roh-Prompt]         │ [was fehlt]   │
    │ TASK         │ [aus Roh-Prompt]         │ [was fehlt]   │
    │ RULES        │ [aus Roh-Prompt]         │ [was fehlt]   │
    └─────────────────────────────────────────────────────────┘

### Step 3: Lücken-Scan (kritische Fragen)

Prüfe diese 8 Fragen explizit:

🔴 **Hochrisiko-Lücken (sofort nachfragen)**
1. Fehlt das **Erfolgskriterium**? → ohne das weiß das Modell nicht, wann es fertig ist
2. Fehlt der **Output-Stil/Format**? → ohne das wird der Output zufällig
3. Sind **Constraints widersprüchlich** (z.B. "kurz UND vollständig")? → muss aufgelöst werden

🟡 **Mittlere Lücken (oft kritisch, manchmal verzichtbar)**
4. Fehlen **Negativ-Beispiele** (was soll explizit NICHT passieren)?
5. Fehlen **Beispiele für gute Outputs**?
6. Fehlt der **Adressat** (für wen schreibt das Modell)?

🔵 **Niedrige Lücken (nice-to-have)**
7. Fehlt eine **Selbst-Prüfungs-Anweisung** ("prüfe deine Antwort")?
8. Fehlt **Iterations-Spielraum** ("falls unklar, frage nach")?

### Step 4: Eskalations-Entscheidung

Foundation reicht – kein Tier-S nötig – wenn:
- Einzelne, klar abgrenzbare Aufgabe
- Ein Output-Artefakt erwartet
- Keine konkurrierenden Stakeholder/Perspektiven
- Niedrige Auswirkung bei Fehlern (Entwurf, kein Versand)
- Diana wird das Ergebnis sowieso nochmal review'en

**Tier-S aus prompting-muster-referenz.md nachladen, wenn mind. eines zutrifft:**

| Signal | Empfohlenes Pattern |
|--------|---------------------|
| Diana muss zwischen Optionen entscheiden | **Multi-Persona Debate** |
| Output muss messbar gut sein (Audit, Veröffentlichung) | **Evaluation Criteria First** |
| Mehrere harte Constraints kollidieren (DSGVO + Vollständigkeit + Kürze) | **Constraint Propagation CoT** |
| Aufgabe ist neu, Diana hat noch keine Beispiele | Tier A: Few-Shot mit synthetischen Beispielen |
| Output geht direkt raus (Mandant, Behörde, Kunde) | Evaluation Criteria First + Self-Critique |
| Lange Verarbeitungskette (Extraktion → Klassifikation → Bericht) | Tier A: Chain-of-Thought mit Zwischenartefakten |

Bei Eskalation: Verweise explizit auf den Pfad und das Pattern, lade die Patterns-Library aber nur, wenn Diana zustimmt – sonst zu viel Token-Overhead.

### Step 5: Modell-Routing

Diana arbeitet mit drei Modellfamilien (aus ihrer Memory-Instruktion):

- **Anthropic (Claude)** → XML-Tags, system-prompt-getrennt von user-prompt, thinking-Tags für CoT
- **OpenAI (GPT-4o, o3)** → Markdown-Struktur, klare Rollenzuweisung, Function-Calling-freundlich
- **Gemini** → kompaktere Prompts, gute mit großem Kontext, weniger XML

Wenn Modell **unklar**: Frage explizit – "Für welches Modell? Claude / GPT / Gemini?"
Wenn Modell **klar**: Wende modell-spezifische Konventionen an.

### Step 6: Finalen Prompt liefern

Liefere den Prompt in genau einem von zwei Formaten:

**A) Foundation-Output (kein Tier-S nötig)**

    ROLLE: [aus Context]
    AUFGABE: [aus Task]
    INPUT: [konkret, kein Platzhalter]
    OUTPUT-FORMAT: [Struktur + Länge]
    REGELN:
    - [Constraint 1]
    - [Constraint 2]
    ERFOLGSKRITERIUM: [woran ist erkennbar, dass es gut ist]
    SELBSTPRÜFUNG: Prüfe vor dem Senden gegen die Erfolgskriterien.

**B) Eskalations-Hinweis (Tier-S empfohlen)**

    🔼 Tier-S-Eskalation empfohlen
    
    Grund: [Signal aus Tabelle]
    Empfohlenes Pattern: [Name aus prompting-muster-referenz.md]
    Pfad: ~/claude-skills/prompting-muster-referenz.md
    
    Foundation-Version steht bereits unten – soll ich auf Tier-S erweitern?
    
    [Foundation-Output trotzdem mitliefern]

---

## Beispiele aus Diana's Domänen

### Beispiel 1: Pflege-Outreach (Foundation reicht)

**Diana sagt:** "Ich brauche einen Prompt, der mir LinkedIn-Connection-Texte für PDLs in NRW schreibt."

**Dekomposition:**
- CONTEXT ✅ (B2B-Outreach, DACH-Pflegesektor)
- TASK ✅ (LinkedIn-Connection-Text)
- RULES ❌ (Tonfall? Länge? CTA?)

**Coaching-Output:**
> Drei kurze Rückfragen, dann liefere ich:
> 1. Tonfall: persönlich-fachlich oder formal-distanziert?
> 2. CTA: konkretes Meeting oder weiche Anbahnung?
> 3. Längen-Hard-Cap: 300 Zeichen (LinkedIn-Limit) okay?

→ Nach Antwort: Foundation-Output, kein Tier-S.

---

### Beispiel 2: Bardenberger Korrespondenz (Tier-S nötig)

**Diana sagt:** "Schreibe Antwort auf das Schreiben von Stein & Partner."

**Dekomposition:**
- CONTEXT ✅ (aus Memory: Stein & Partner-Stil mirrorn, Bardenberger Str. 38)
- TASK ✅ (Antwortschreiben)
- RULES ✅ (Memory hat den Stil-Code)

**Eskalations-Signale:**
- Output geht direkt an Anwalt → hochrisiko
- Mehrere harte Constraints (Beweislast verschieben + nicht-bindend + höflich-distanziert)
- Strategischer Kontext (Commerzbank-Schuldfreigabe, Teilungsversteigerung)

→ **Tier-S empfohlen:** Multi-Persona Debate (Diana's Anwalt + Gegner-Anwalt + neutraler Schiedsrichter), dann Constraint Propagation CoT für die Sprache.

---

### Beispiel 3: ICD-10-Coding-Prompt (Foundation + Selbstprüfung)

**Diana sagt:** "Prompt für ICD-10-GM Doppelkodierungs-Plausibilitätscheck."

**Dekomposition:**
- CONTEXT ✅ (MD Stationär, Diana ist QBP)
- TASK ✅ (Plausibilitätscheck Doppelkodierung)
- RULES 🟡 (fehlt: was ist "implausibel"? Beispiele?)

**Eskalations-Check:**
- Klar abgrenzbar ✅
- Ein Output ✅
- Aber: Audit-relevant → **Selbstprüfung verstärken**, kein voller Tier-S nötig

→ Foundation-Output + Self-Critique-Anweisung am Ende.

---

## Anti-Pattern (Was dieser Skill NICHT tun darf)

1. **Nicht direkt Tier-S laden**, ohne Foundation-Check – Token-Verschwendung
2. **Nicht Platzhalter-Prompts liefern** ("schreibe über {{TOPIC}}") – Diana's harte Regel: "No placeholders or demo content"
3. **Nicht ohne Modell-Klärung optimieren**, wenn das Modell unklar ist
4. **Nicht alle 8 Lücken-Fragen abfragen** – nur die relevanten herausziehen
5. **Nicht Patterns erfinden** – wenn Tier-S, dann nur aus prompting-muster-referenz.md

---

## Integration mit anderen Skills

Dieser Skill ist **Eingangs-Filter** für:
- prompting-muster-referenz.md (16 Patterns) → Eskalations-Ziel
- chrome-shortcut-builder → wenn Prompt für Claude-in-Chrome, dort nochmal mit LL-Patterns optimieren
- pflege-dokumentation → wenn Prompt im Pflegekontext, Domänen-Constraints automatisch ergänzen

Reihenfolge: **prompt-coach → eventuell Tier-S → eventuell Domain-Skill** → finaler Prompt

---

## Sync-Hinweis (nach Anlage)

Auf allen Systemen (Yoga7 / NAS / Windows): Skill liegt unter `~/.claude/skills/prompt-coach/SKILL.md` und im Repo `~/claude-skills/prompt-coach/SKILL.md`.

Update-Workflow:

1. Skill in `~/.claude/skills/prompt-coach/SKILL.md` editieren
2. Ins Repo kopieren: `cp ~/.claude/skills/prompt-coach/SKILL.md ~/claude-skills/prompt-coach/`
3. `cd ~/claude-skills && git pull --rebase origin main`
4. `git add prompt-coach/SKILL.md && git commit -m 'prompt-coach: <änderung>'`
5. `GIT_ASKPASS="" git push origin main`

---

## Selbst-Verbesserung

Dieser Skill profitiert vom reflect-Skill. Nach 3–5 Coaching-Sessions:

    /reflect prompt-coach

→ Häufige Lücken-Patterns aus realen Diana-Sessions sollten in den Lücken-Scan einfließen.
