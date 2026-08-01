---
name: prompt-geruest
description:
  Das 10-Schichten-Prompt-Gerüst nach Anthropic "Prompting 101" (Applied AI Team). Baut aus einer Aufgabe +
  Daten einen vollständig strukturierten Claude-Prompt mit Rolle, Kontext, Nicht-Raten-Regel, Reihenfolge und
  Ausgabeformat. Trigger bei "10-Schichten", "Prompt-Gerüst", "baue mir einen strukturierten Prompt",
  "Anthropic-Struktur", "Sandwich-Prompt", oder wenn Diana wichtige Dokumente/Bilder/Logs zur zuverlässigen
  Auswertung an Claude geben will (Forensik-Berichte, n8n-Fehlerlogs, NAS-Konfigs, Pflege-Formulare, Fotos von
  Formularen).
---

# Prompt-Gerüst – Die 10 Schichten nach Anthropic "Prompting 101"

## Was ist dieser Skill?

**Für 12-Jährige erklärt:** Ein guter Prompt ist wie ein Sandwich mit 10 Schichten. Wenn du einfach nur „Schau
mal, wer ist schuld?" fragst, denkt Claude bei einem Autounfall-Formular vielleicht an einen Ski-Unfall. Wenn
du aber alle Schichten stapelst — Wer bist du? Was weißt du schon? Was darfst du NICHT (raten!)? In welcher
Reihenfolge arbeitest du? Wie sieht die Antwort aus? — dann liefert Claude zuverlässig das richtige Ergebnis.
Dieser Skill stapelt das Sandwich automatisch.

Quelle: Anthropic „Prompting 101" (Hannah & Christian, Applied AI Team, Code w/ Claude).

---

## Wann triggert dieser Skill?

- „Baue mir einen strukturierten Prompt für [X]" / „10-Schichten" / „Prompt-Gerüst"
- Diana gibt wichtige Daten zur Auswertung: Forensik-Berichte, n8n-Fehlerlogs, NAS-Konfigs, Fotos von
  Formularen (Pflege, Werkstatt, Belege)
- Ein bestehender Prompt liefert unzuverlässige oder erfundene Ergebnisse (Halluzinationen)

**KEIN Trigger:** Schnelle Alltagsfragen im Chat. Das Gerüst ist für wiederverwendbare, wichtige Prompts —
nicht für „Wie spät ist es in Tokio?".

**Abgrenzung zu prompt-coach:** prompt-coach prüft und routet (Foundation vs. Tier-S). prompt-geruest ist die
Bau-Vorlage für die Claude-spezifische Endfassung. Reihenfolge: prompt-coach → (evtl. Tier-S) → prompt-geruest
für den finalen Claude-Prompt.

---

## Die 10 Schichten (Reihenfolge einhalten!)

| #   | Schicht                     | Leitfrage                                                                                               | Pflicht?                |
| --- | --------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------- |
| 1   | **Rolle & Aufgabe**         | Wer ist Claude hier? Was ist der Job?                                                                   | ✅ immer                |
| 2   | **Ton & Haltung**           | Sachlich? Und IMMER: „Rate nicht — sag, wenn du unsicher bist"                                          | ✅ immer                |
| 3   | **Hintergrundwissen**       | Was ändert sich NIE? (Formular-Aufbau, Systemarchitektur, Log-Format) → in den System-Prompt, cache-bar | ✅ bei Dokumenten/Daten |
| 4   | **Detail-Regeln**           | Schritt-für-Schritt-Anleitung, Sonderfälle („Menschen kreuzen schlampig an")                            | ✅ immer                |
| 5   | **Beispiele (Few-Shot)**    | 1–3 knifflige Fälle mit Musterlösung, in XML-Tags                                                       | 🟡 wenn vorhanden       |
| 6   | **Gesprächsverlauf**        | Bisheriger Kontext, falls relevant                                                                      | 🔵 selten               |
| 7   | **Die aktuellen Daten**     | Das konkrete Dokument/Bild/Log — klar abgegrenzt mit XML-Tags                                           | ✅ immer                |
| 8   | **Denk-Reihenfolge**        | „Lies ERST das Eindeutige (Formular), DANN das Unklare (Skizze)"                                        | ✅ bei mehreren Quellen |
| 9   | **Ausgabeformat**           | Zieltags/JSON: `<ergebnis>...</ergebnis>` — maschinenlesbar                                             | ✅ immer                |
| 10  | **Wichtigstes wiederholen** | Die 2–3 kritischsten Regeln nochmal am Ende                                                             | ✅ immer                |

**Goldene Regeln aus dem Video:**

1. Kontext ist alles — ohne Schicht 1–3 rät Claude („Ski-Unfall-Effekt")
2. Nicht-Raten-Regel explizit reinschreiben (verhindert Halluzinationen)
3. Reihenfolge wie ein Mensch: erst das Klare, dann das Wirre
4. XML-Tags als beschriftete Schubladen — Claude ist darauf trainiert
5. Iterieren: testen → Fehlstelle finden → genau die Schicht nachbessern. Bei hartnäckigen Fällen Extended
   Thinking einschalten und Claudes Denkprotokoll lesen — dann die Erkenntnis in Schicht 3/4 einbauen
   (tokensparender als dauerhaftes Thinking)

---

## Workflow

### Step 1: Aufgabe erfassen

Diana nennt Aufgabe + Datenart. Fehlen Rolle, Erfolgskriterium oder Ausgabeformat → kurz nachfragen (max. 3
Fragen).

### Step 2: Gerüst füllen

`TEMPLATE.md` aus diesem Skill-Ordner als Basis nehmen und alle Pflicht-Schichten konkret füllen — **keine
Platzhalter** (Dianas harte Regel). Statisches Wissen (Schicht 3) in den System-Prompt, dynamische Daten
(Schicht 7) in den User-Prompt.

### Step 3: Liefern + Testanleitung

Fertigen Prompt liefern plus einen Satz: „Teste mit [konkretem Beispiel]; wenn X schiefgeht, verstärke Schicht
Y."

---

## Beispiele aus Dianas Domänen

### n8n-Fehlerlog analysieren

- Schicht 1: „Du bist ein n8n-Workflow-Debugger für die Instanz n8n.forensikzentrum.com"
- Schicht 3: Workflow-Architektur (Webhook-Input, Delete/Update geben `{}` zurück, …)
- Schicht 8: „Lies ERST die Workflow-Definition, DANN das Fehlerlog"
- Schicht 9: `<diagnose>`, `<fix>`, `<risiko>`

### Pflege-Formular vom Foto erfassen

- Schicht 2: „Wenn ein Feld unleserlich ist, schreibe UNLESERLICH — niemals raten" (medizinische Daten!)
- Schicht 3: Formular-Aufbau einmalig komplett beschreiben (Zeilen, Spalten, typische Handschrift-Macken)
- Schicht 9: JSON für die Übernahme in Medifox/DAN, Prefill mit `{`

### Forensik-Bericht auswerten

- Schicht 2: „Trenne strikt Befund (belegbar) von Vermutung — jede Aussage mit Fundstelle"
- Schicht 10: „WICHTIG: Keine Aussage ohne Beleg aus dem Dokument. Zitiere die Stelle."

---

## Anti-Pattern

1. **Keine Platzhalter-Prompts** liefern — jede Schicht konkret füllen oder weglassen
2. **Nicht alle 10 Schichten erzwingen** — 🟡/🔵-Schichten nur bei Bedarf
3. **Statisches nicht in den User-Prompt** — Formular-Beschreibung gehört in den System-Prompt (Caching!)
4. **Nicht ohne Nicht-Raten-Regel** ausliefern, wenn Fakten extrahiert werden

---

## Sync-Hinweis (nach Änderung)

1. Editieren: `~/.claude/skills/prompt-geruest/`
2. Ins Repo: `cp -r ~/.claude/skills/prompt-geruest ~/claude-skills/`
3. `cd ~/claude-skills && git pull --rebase origin main`
4. `git add prompt-geruest && git commit -m 'prompt-geruest: <änderung>'`
5. `GIT_ASKPASS="" git push origin main`
