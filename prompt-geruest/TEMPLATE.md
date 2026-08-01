# 10-Schichten-Vorlage (zum Kopieren)

Alles in `[eckigen Klammern]` konkret ausfüllen. Schichten mit 🟡/🔵 weglassen, wenn nicht gebraucht. Bei
API/Console: Schicht 1–5 in den **System-Prompt**, Schicht 6–10 in den **User-Prompt**. Im Chat (claude.ai /
Claude Code): einfach alles nacheinander in eine Nachricht.

---

```text
[1 — ROLLE & AUFGABE]
Du bist [Rolle, z. B. "ein Debugging-Assistent für n8n-Workflows"].
Deine Aufgabe: [ein Satz, z. B. "analysiere das Fehlerlog und finde die Ursache"].

[2 — TON & HALTUNG]
Bleibe sachlich und präzise.
WICHTIG: Rate niemals. Wenn du dir bei etwas nicht sicher bist oder
Informationen fehlen, sage das ausdrücklich statt zu spekulieren.

[3 — HINTERGRUNDWISSEN (das Unveränderliche)]
<hintergrund>
[Alles, was sich zwischen den Durchläufen NIE ändert:
Formular-Aufbau, Systemarchitektur, Log-Format, Fachbegriffe.
Je vollständiger, desto weniger muss Claude beim Lesen rätseln.]
</hintergrund>

[4 — DETAIL-REGELN]
Gehe so vor:
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]
Beachte Sonderfälle: [z. B. "Handschrift kann Kreise statt Kreuze enthalten"].

[5 — BEISPIELE 🟡]
<beispiel>
<eingabe>[kniffliger Beispielfall]</eingabe>
<ideale_antwort>[Musterlösung]</ideale_antwort>
</beispiel>

[6 — GESPRÄCHSVERLAUF 🔵]
<verlauf>[nur falls relevant]</verlauf>

[7 — DIE AKTUELLEN DATEN]
<daten>
[Hier das konkrete Dokument / Log / Bild einfügen bzw. anhängen]
</daten>

[8 — DENK-REIHENFOLGE]
Analysiere in dieser Reihenfolge:
1. Lies zuerst [die eindeutige Quelle, z. B. "das Formular"] und
   notiere, was du sicher weißt.
2. Erst danach [die unklare Quelle, z. B. "die Skizze"] — gleiche sie
   mit deinem bisherigen Wissen ab.

[9 — AUSGABEFORMAT]
Gib dein Endergebnis GENAU so aus:
<ergebnis>
[Struktur definieren, z. B. JSON-Felder oder feste Abschnitte]
</ergebnis>

[10 — DAS WICHTIGSTE NOCHMAL]
Zur Erinnerung, die kritischsten Regeln:
- [wichtigste Regel, z. B. "Keine Aussage ohne Beleg aus den Daten"]
- [zweitwichtigste Regel, z. B. "Bei Unsicherheit: UNSICHER schreiben"]
Beginne jetzt.
```

---

## Schnell-Checkliste vor dem Absenden

- [ ] Rolle gesetzt? (1)
- [ ] Nicht-Raten-Regel drin? (2)
- [ ] Statisches Wissen beschrieben statt Claude raten lassen? (3)
- [ ] Reihenfolge: erst das Klare, dann das Wirre? (8)
- [ ] Ausgabeformat maschinen-/weiterverwendbar? (9)
- [ ] Wichtigstes am Ende wiederholt? (10)

## Wenn das Ergebnis nicht stimmt

| Symptom                                           | Schicht nachbessern                                                            |
| ------------------------------------------------- | ------------------------------------------------------------------------------ |
| Claude versteht die Aufgabe falsch („Ski-Unfall") | 1 + 3                                                                          |
| Claude erfindet Details                           | 2 + 10                                                                         |
| Claude übersieht Dinge in den Daten               | 4 + 8                                                                          |
| Antwort hat falsches Format                       | 9 (+ Prefill: Antwort mit `{` oder `<ergebnis>` beginnen lassen)               |
| Immer noch unklar warum                           | Extended Thinking einschalten, Denkprotokoll lesen, Erkenntnis in 3/4 einbauen |
