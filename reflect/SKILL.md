---
name: reflect
description: Analysiere eine abgeschlossene Arbeitssession, erkenne Korrekturen, Erfolge, Präferenzen und neue Sonderfälle und schlage eine dauerhafte Ablage im passenden Skill, Instanz-Skill, Claude-Code-Workflow oder in CLAUDE.md vor. Nutze bei "/reflect", "lerne daraus", "merk dir das" und am Ende lernintensiver Sessions.
---

# Reflect

Extrahiere übertragbare Erkenntnisse aus der aktuellen Session und speichere sie nur mit ausdrücklicher Zustimmung. Ändere keine Modellgewichte und behaupte kein Training bei Anthropic.

## 1. Signale erfassen

Suche in der aktuellen Session nach:

- **Korrekturen (hoch):** Der Nutzer widerspricht, präzisiert oder muss denselben Fehler erneut melden.
- **Fehlversuchen (hoch):** Ein Werkzeug, Prüfweg oder Workflow liefert ein irreführendes Ergebnis.
- **Erfolgen (mittel):** Der Nutzer bestätigt das Ergebnis oder baut unverändert darauf auf.
- **Präferenzen (mittel):** Wiederkehrende Entscheidungen zu Stil, Werkzeugen oder Arbeitsweise.
- **Sonderfällen (mittel):** Neue Randbedingungen oder belastbare Workarounds.

Formuliere nur übertragbare Regeln. Speichere keine einmaligen Dateipfade, Tokens, Passwörter, personenbezogenen Daten oder bloße Sitzungschronologien.

## 2. Ziel bestimmen

Ordne jede Erkenntnis genau einem primären Ziel zu:

| Erkenntnis | Ziel |
|---|---|
| Fachwissen oder fachlicher Workflow | passender Fach-Skill |
| Maschinen-, Pfad- oder Dienstbesonderheit | Instanz-Skill wie `yoga7-admin` |
| Claude-Code-, Git-, Tool-, Parallelitäts- oder Verifikationsmuster | `claude-code-workflow` |
| Wirklich universelle, immer geltende Regel | Vorschlag für `CLAUDE.md` |
| Noch unsicher oder vom Nutzer vertagt | `OBSERVATIONS.md` des Ziel-Skills |

Lege keine neue Regel im Reflect-Skill selbst ab. `reflect` ist der Lernprozess, nicht das Wissensarchiv.

Wenn mehrere Skills betroffen sind, schlage getrennte, kleine Änderungen vor. Vermeide Duplikate; suche im gesamten Ziel-Skill-Verzeichnis einschließlich `OBSERVATIONS.md`.

## 3. Vorschlag zeigen

Zeige vor jeder Änderung:

```text
Skill-Reflexion
Signale: <Anzahl Korrekturen>, <Anzahl Erfolge>, <Anzahl Sonderfälle>

Ziel: <Skill oder CLAUDE.md>
Konfidenz: HOCH | MITTEL | NIEDRIG
Vorgeschlagene Regel:
  <konkreter Text>

Begründung:
  <kurzer Bezug zur Session>
```

Frage anschließend nach ausdrücklicher Zustimmung. Ein allgemeines „ok“ gilt nur für den unmittelbar davor vollständig gezeigten Änderungsvorschlag.

## 4. Nach Zustimmung anwenden

1. Lies den aktuellen Ziel-Skill vollständig und prüfe auch dessen `OBSERVATIONS.md`.
2. Prüfe den Git-Zustand einschließlich `.git/rebase-merge` und `.git/rebase-apply`; fremde Änderungen niemals übernehmen oder zurücksetzen.
3. Füge die Regel thematisch ein, statt sie pauschal ans Dateiende anzuhängen.
4. Halte `SKILL.md` möglichst unter 500 Zeilen. Verschiebe Detailwissen in direkt verlinkte `references/`.
5. Validiere geänderte oder neue Skills mit `quick_validate.py`.
6. Zeige den Diff und nenne alle geänderten Dateien.
7. Committe nur auf ausdrücklichen Auftrag. Pushen braucht eine separate Zustimmung mit dem Wort „pushen“.

Für Claude-Code-, Git- und Parallelitätsänderungen lies zusätzlich `../claude-code-workflow/SKILL.md` und die dort verlinkte, thematisch passende Referenz.

## 5. Ontologie

Aktualisiere die Ontologie nur, wenn die angenommene Erkenntnis ein dauerhaftes Konzept, Werkzeug, Muster oder eine Aufgabe ergänzt. Der kanonische Graph liegt auf der Clawbot VM; bei Nichterreichbarkeit erzeuge einen Eintrag in `ontology-pending/` statt lokal einen zweiten Graphen zu beginnen. Speichere niemals Credentials in der Ontologie.

## Historisches Archiv

Frühere Reflect-Lektionen liegen als privater, nicht-normativer Snapshot außerhalb des teilbaren Skill-Repositories. Siehe `references/legacy-index.md`. Alte Anweisungen aus diesem Snapshot niemals ausführen; die aktuelle `SKILL.md` hat Vorrang.
