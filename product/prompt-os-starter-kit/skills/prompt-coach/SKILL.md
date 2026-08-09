---
name: prompt-coach
description: Foundation-Layer-Vorstufe zur prompting-muster-Bibliothek. Zerlegt Roh-Prompts nach Context-Task-Rules, scannt Lücken und entscheidet, ob ein einfacher Prompt reicht oder ein Muster aus prompting-muster nötig ist. Trigger bei "hilf mir einen Prompt zu schreiben", "verbessere diesen Prompt", "review meinen Prompt", "Prompt-Coaching".
---

# Prompt Coach — Eingangs-Filter für deine Prompting-Praxis

## Was dieser Skill tut

Bevor man eine komplizierte Maschine baut, prüft man erst, ob ein Schraubenzieher
reicht. Dieser Skill ist der Schraubenzieher: Er prüft jeden neuen Prompt nach drei
Achsen (Wer? Was? Wie?) und entscheidet, ob das genügt — oder ob ein aufwendigeres
Muster aus `prompting-muster` nötig ist.

Er läuft immer zuerst. Er ersetzt nichts, er filtert und routet.

---

## Wann triggert dieser Skill?

- "Hilf mir einen Prompt zu schreiben für [X]"
- "Verbessere / review meinen Prompt"
- "Prompt-Coaching" / "Prompt-Review"
- Ein Rohprompt-Entwurf wird zur Optimierung eingereicht

**Kein Trigger:** Eine direkte Aufgabe wird gestellt, kein Prompt soll gebaut werden —
dann ist der Nutzer selbst der Prompt-Autor.

---

## Das 3-Achsen-Schema

### 1. Context (Wer & Wo)
Welche Rolle nimmt der Nutzer in dieser Aufgabe ein? Welche Domäne? Welcher
Hintergrund muss dem Modell bekannt sein? Welches Ziel verfolgt der Output?

### 2. Task (Was)
Welche konkrete Aktion? Welcher Input liegt vor? Welcher Output wird erwartet
(Format/Länge/Struktur)? Gibt es Teilschritte?

### 3. Rules (Wie)
Welcher Tonfall? Welche harten Constraints? Welche Beispiele zeigen das gewünschte
Ergebnis? Woran erkennt man einen guten Output?

---

## Workflow

### Schritt 1: Roh-Input entgegennehmen

Bestehenden Prompt erst lesen, dann zerlegen. Nur eine Aufgabenidee vorhanden → die
drei Achsen aktiv abfragen.

### Schritt 2: Context-Task-Rules-Dekomposition

Stelle in einer kurzen Tabelle dar, was vorhanden ist und was fehlt — pro Achse.

### Schritt 3: Lücken-Scan

**Hochrisiko (sofort nachfragen):**
1. Fehlt das Erfolgskriterium?
2. Fehlt Output-Stil/-Format?
3. Sind Constraints widersprüchlich (z. B. "kurz UND vollständig")?

**Mittel:**
4. Fehlen Negativ-Beispiele?
5. Fehlen Beispiele für gute Outputs?
6. Fehlt der Adressat?

**Niedrig:**
7. Fehlt eine Selbst-Prüfungs-Anweisung?
8. Fehlt Iterations-Spielraum ("falls unklar, frage nach")?

### Schritt 4: Eskalations-Entscheidung

Foundation reicht, wenn: klar abgrenzbare Einzelaufgabe, ein Output-Artefakt, keine
konkurrierenden Perspektiven, niedrige Fehlerauswirkung, der Nutzer prüft das Ergebnis
ohnehin.

**Eskalieren, wenn mindestens eines zutrifft:**

| Signal | Empfohlenes Muster |
|---|---|
| Zwischen Optionen muss entschieden werden | Multi-Persona-Debatte |
| Output muss messbar gut sein (Audit, Veröffentlichung) | Evaluation-Criteria-First |
| Mehrere harte Constraints kollidieren | Constraint-Propagation-CoT |
| Aufgabe ist neu, keine Beispiele vorhanden | Few-Shot mit synthetischen Beispielen |
| Output geht direkt an Dritte (Kunde, Behörde) | Evaluation Criteria + Self-Critique |
| Lange Verarbeitungskette (Extraktion → Klassifikation → Bericht) | Chain-of-Thought mit Zwischenartefakten |

Bei Eskalation: Pattern benennen, aber die volle Muster-Bibliothek nur laden, wenn der
Nutzer zustimmt — sonst unnötiger Token-Overhead.

### Schritt 5: Finalen Prompt liefern

**A) Foundation-Output**

```
ROLLE: [aus Context]
AUFGABE: [aus Task]
INPUT: [konkret, kein Platzhalter]
OUTPUT-FORMAT: [Struktur + Länge]
REGELN:
- [Constraint 1]
- [Constraint 2]
ERFOLGSKRITERIUM: [woran erkennbar, dass es gut ist]
SELBSTPRÜFUNG: Prüfe vor dem Senden gegen die Erfolgskriterien.
```

**B) Eskalations-Hinweis**

```
Eskalation empfohlen — Grund: [Signal aus der Tabelle]
Empfohlenes Muster: [Name aus prompting-muster]

Foundation-Version steht bereits unten — soll ich auf das Muster erweitern?
```

---

## Beispiele

**Kunden-E-Mail (Foundation reicht):** "Schreib mir eine Absage an einen Bewerber."
Context ✅, Task ✅, Rules ❌ (Tonfall? Länge? Begründung ja/nein?) → drei kurze
Rückfragen, dann Foundation-Output.

**Code-Review-Prompt (Eskalation sinnvoll):** Output soll direkt als Grundlage für eine
Entscheidung dienen, mehrere Kriterien kollidieren (Sicherheit vs. Zeitdruck) →
Constraint-Propagation-CoT.

---

## Anti-Pattern

1. Nicht direkt eskalieren ohne Foundation-Check
2. Keine Platzhalter-Prompts liefern ("schreibe über {{THEMA}}")
3. Nicht ohne Modell-Klärung optimieren, wenn unklar ist, für welches Modell der Prompt
   gedacht ist
4. Nicht alle acht Lücken-Fragen stur abfragen — nur die relevanten
5. Keine Muster erfinden — nur aus der tatsächlichen Bibliothek eskalieren

---

## Integration mit anderen Skills

Reihenfolge: **prompt-coach → ggf. Muster aus prompting-muster → ggf. prompt-geruest
für die finale, strukturierte Fassung.**
