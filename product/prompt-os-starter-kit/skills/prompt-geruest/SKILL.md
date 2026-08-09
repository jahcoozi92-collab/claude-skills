---
name: prompt-geruest
description:
  Das 10-Schichten-Prompt-Gerüst nach Anthropic "Prompting 101" (Applied AI Team). Baut aus einer Aufgabe +
  Daten einen vollständig strukturierten Claude-Prompt mit Rolle, Kontext, Nicht-Raten-Regel, Reihenfolge und
  Ausgabeformat. Trigger bei "10-Schichten", "Prompt-Gerüst", "baue mir einen strukturierten Prompt", oder wenn
  wichtige Dokumente/Bilder/Logs zuverlässig ausgewertet werden sollen.
---

# Prompt-Gerüst — Die 10 Schichten nach Anthropic "Prompting 101"

## Was dieser Skill tut

Ein guter Prompt ist wie ein Sandwich mit zehn Schichten. Eine knappe Frage ohne
Kontext lässt Claude raten. Stapelt man dagegen alle Schichten — Wer bist du? Was
weißt du schon? Was darfst du nicht (raten)? In welcher Reihenfolge arbeitest du? Wie
sieht die Antwort aus? — liefert Claude zuverlässig das richtige Ergebnis. Dieser Skill
stapelt das Sandwich systematisch.

Quelle: Anthropic „Prompting 101" (Applied AI Team, Code w/ Claude).

---

## Wann triggert dieser Skill?

- "Baue mir einen strukturierten Prompt für [X]" / "10-Schichten" / "Prompt-Gerüst"
- Wichtige Daten sollen zuverlässig ausgewertet werden: Berichte, Fehlerlogs,
  Konfigurationen, Formulare/Fotos
- Ein bestehender Prompt liefert unzuverlässige oder erfundene Ergebnisse

**Kein Trigger:** Schnelle Alltagsfragen. Das Gerüst ist für wiederverwendbare, wichtige
Prompts.

**Abgrenzung zu prompt-coach:** prompt-coach prüft und routet (Foundation vs.
Eskalation). prompt-geruest ist die Bau-Vorlage für die finale, Claude-spezifische
Fassung. Reihenfolge: prompt-coach → ggf. Muster → prompt-geruest.

---

## Die 10 Schichten (Reihenfolge einhalten)

| # | Schicht | Leitfrage | Pflicht? |
|---|---|---|---|
| 1 | Rolle & Aufgabe | Wer ist Claude hier? Was ist der Job? | immer |
| 2 | Ton & Haltung | Sachlich? Und immer: „Rate nicht — sag, wenn du unsicher bist" | immer |
| 3 | Hintergrundwissen | Was ändert sich nie? (Format, Architektur) → in den System-Prompt, cachebar | bei Dokumenten/Daten |
| 4 | Detail-Regeln | Schritt-für-Schritt-Anleitung, Sonderfälle | immer |
| 5 | Beispiele (Few-Shot) | 1–3 knifflige Fälle mit Musterlösung, in XML-Tags | wenn vorhanden |
| 6 | Gesprächsverlauf | Bisheriger Kontext, falls relevant | selten |
| 7 | Die aktuellen Daten | Das konkrete Dokument/Bild/Log, klar abgegrenzt mit XML-Tags | immer |
| 8 | Denk-Reihenfolge | „Lies erst das Eindeutige, dann das Unklare" | bei mehreren Quellen |
| 9 | Ausgabeformat | Zieltags/JSON — maschinenlesbar | immer |
| 10 | Wichtigstes wiederholen | Die 2–3 kritischsten Regeln nochmal am Ende | immer |

**Goldene Regeln:**

1. Kontext ist alles — ohne Schicht 1–3 rät Claude
2. Nicht-Raten-Regel explizit reinschreiben (verhindert Halluzinationen)
3. Reihenfolge wie ein Mensch: erst das Klare, dann das Wirre
4. XML-Tags als beschriftete Schubladen nutzen
5. Iterieren: testen → Fehlstelle finden → genau die Schicht nachbessern

---

## Workflow

### Schritt 1: Aufgabe erfassen

Aufgabe + Datenart abfragen. Fehlen Rolle, Erfolgskriterium oder Ausgabeformat → kurz
nachfragen (max. drei Fragen).

### Schritt 2: Gerüst füllen

Alle Pflicht-Schichten konkret füllen — keine Platzhalter. Statisches Wissen (Schicht
3) in den System-Prompt, dynamische Daten (Schicht 7) in den User-Prompt.

### Schritt 3: Liefern + Testanleitung

Fertigen Prompt liefern plus einen Satz: „Teste mit [konkretem Beispiel]; wenn X
schiefgeht, verstärke Schicht Y."

---

## Beispiele

**Fehlerlog analysieren:** Schicht 1 „Du bist Debugger für System X"; Schicht 3
Systemarchitektur einmalig komplett beschreiben; Schicht 8 „Lies erst die
Konfiguration, dann das Fehlerlog"; Schicht 9 `<diagnose>`, `<fix>`, `<risiko>`.

**Formular vom Foto erfassen:** Schicht 2 „Wenn ein Feld unleserlich ist, schreibe
UNLESERLICH — niemals raten"; Schicht 3 Formular-Aufbau einmalig beschreiben; Schicht 9
strukturiertes JSON für die Weiterverarbeitung.

**Code-Auftrag an ein zweites Modell (TDD-Workflow):** Schicht 3 Projektstruktur,
Test-Befehl, unantastbare Pfade; Schicht 8 umgedreht — hier ist die Testdatei das
Eindeutige: „Lies erst die Tests, dann die Umsetzung"; Schicht 10 „Schränkt dich ein
Test ein, ändere das Design — nicht den Test." Auftragsdateien immer mit den echten
Sonderzeichen der Zielsprache schreiben, nicht mit ASCII-Ersatz — das Arbeiter-Modell
übernimmt die Schreibweise wörtlich in Nutzertexte.

---

## Anti-Pattern

1. Keine Platzhalter-Prompts liefern
2. Nicht alle 10 Schichten erzwingen — optionale Schichten nur bei Bedarf
3. Statisches nicht in den User-Prompt packen — gehört ins System-Prompt (Caching)
4. Nicht ohne Nicht-Raten-Regel ausliefern, wenn Fakten extrahiert werden
