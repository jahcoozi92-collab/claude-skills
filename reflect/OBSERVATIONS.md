# Beobachtungen zur späteren Überprüfung

Hier werden Beobachtungen gespeichert, die beim `/reflect`-Befehl abgelehnt wurden, aber für spätere Überprüfung interessant sein könnten.

---

## Format

```
### [DATUM] - Session-Kontext

**Konfidenz:** LOW/MEDIUM
**Beobachtung:** Was wurde bemerkt
**Mögliche Änderung:** Was könnte man tun
**Grund für Ablehnung:** Warum wurde es nicht übernommen
```

---

## Einträge

### 2026-05-29 — Eigene Lesson sofort falsifiziert (Pfad-Länge, nicht `&&`)

**Konfidenz:** MEDIUM
**Beobachtung:** Im Commit `e419f52` wurde die Lesson kodifiziert: „KEIN `&&` in User-Befehlen — bricht auch unter 100 Zeichen". 10 Minuten später lief `scp Jahcoozi@192.168.22.90:/tmp/o.sh /tmp/ && bash /tmp/o.sh` (~58 Zeichen) sauber durch. Falsifikation: nicht `&&` ist der Bruch-Trigger, sondern **Pfad-Länge → Terminal-Auto-Wrap, das zufällig vor `&&` landet** wenn die Zeile lang genug ist. `&&` ist Symptom, nicht Ursache.
**Mögliche Änderung:** Lesson in `reflect/SKILL.md` (Step 5) verfeinern: statt absoluter `&&`-Verbot besser „Befehle so kurz halten, dass keine Terminal-Auto-Wrap-Position vor strukturellen Tokens (`&&`, `||`, `;`) entsteht". Praktische Faustregel weiterhin: separate Zeilen sicherer als Verkettung.
**Grund für Ablehnung:** Eine einzelne Falsifikation ist noch kein Pattern. Wenn der Fall mehrfach in den nächsten Reflect-Runden wiederkommt → in Skill übernehmen. Bis dahin als ehrliche Beobachtung hier ablegen.

### 2026-05-29 — Reflect-Frequenz: 3× pro Session ist hochfrequent

**Konfidenz:** LOW
**Beobachtung:** Diese Session hatte drei `/reflect`-Aufrufe hintereinander. Erster brachte 16 substanzielle Lessons (rag-system + nas-instance), zweiter 3 Meta-Lessons über reflect selbst, dritter eine Lesson-Falsifikation. Abnehmender Grenznutzen erkennbar.
**Mögliche Änderung:** Workflow könnte eine Heuristik bekommen — z.B. „bei < 3 echten Korrekturen/Erfolgen seit letztem Reflect-Commit: OBSERVATIONS statt Commit empfehlen". Aktuell muss Claude das ad-hoc abwägen.
**Grund für Ablehnung:** Nicht generalisierbar nach einer Session. Wenn Diana das Muster über mehrere Wochen bestätigt → in Skill übernehmen.

### 2026-08-18 — Nachtrag zur Lektion vom 2026-08-17: `update` hat ZWEI Formen, dazu `delete`

Die Lektion vom 2026-08-17 („update-Zeilen liegen flach, nicht unter entity") ist **unvollständig**.
Gemessen am echten Graphen (2726 Zeilen) existieren nebeneinander:

```
create   1357   ['entity', 'op']
update     19   ['id', 'op', 'properties']      <-- die dokumentierte Form
update      1   ['entity', 'op']                <-- NICHT dokumentiert
delete      1   ['id', 'op']                    <-- gar nicht erwähnt
relate   1346   ['from','op','properties','rel','to']
relate     22   ['from','op','rel','to']        <-- ohne properties
```

Mein Prüfskript, das der gestrigen Lektion wörtlich folgte, brach mit `KeyError: 'id'` ab —
an der einen `update`-Zeile mit `entity`. Ein Parser, der `delete` ignoriert, zählt zudem eine
gelöschte Entity als vorhanden.

Robuste Fassung (deckt alle sechs Formen ab):
```python
if op in ("create","update"):
    if "entity" in d: e=d["entity"]; ents[e["id"]]=e
    else:
        ents.setdefault(d["id"], {"id":d["id"],"type":None,"properties":{}})
        ents[d["id"]]["properties"] = d.get("properties",{})
elif op=="delete":
    ents.pop(d["id"], None)
elif op=="relate":
    rels.append((d["from"], d["rel"], d["to"]))
```

**Verallgemeinerung:** Bei einem Append-Log nicht die Form aus einer Stichprobe ableiten, sondern
einmal alle vorkommenden Schlüsselkombinationen zählen:
```python
forms[(d["op"], tuple(sorted(k for k in d if k!="timestamp")))] += 1
```
Zehn Sekunden Aufwand, und man kennt die Ausnahmen statt sie zu treffen.

⚠ Steht hier statt im SKILL, weil zum Zeitpunkt des Reflects eine parallele Session in
`reflect/SKILL.md` schrieb (siehe unten). Beim nächsten Reflect in den Skill übernehmen und
diesen Eintrag löschen.

### 2026-08-18 — Eigener Fehler: `git add` nahm den Zwischenstand einer parallelen Session mit

Ich habe die Lektion vom 2026-08-17 („vor dem ERSTEN Schreibzugriff prüfen, ob eine andere Session
arbeitet") beim Reflect selbst verletzt — sie handelt vom Projektverzeichnis, ich habe sie nicht
auf das **Skills-Repo** übertragen.

Ablauf: `git status --short` zeigte vor Beginn nur `?? deploy-check/`. Während ich die drei
Lektionen anhängte, schrieb eine parallele Session (`jahcoozi-a2`, Blender-Thema) ihrerseits in
`reflect/SKILL.md`. Mein `git add reflect/SKILL.md` nahm ihren Zwischenstand mit: Commit `1eb391b`
enthält **104 Zeilen statt meiner 48**, darunter ihre komplette Lektion unter meiner
Commit-Message. Aufgefallen ist es erst, weil `git pull --rebase` danach mit „unstaged changes"
abbrach — sonst wäre es unbemerkt geblieben.

**Regel fürs nächste Mal:** Unmittelbar vor `git add` den Diff der Zieldatei ansehen, nicht nur
den Status vor Beginn:
```bash
git -C ~/.claude/skills diff --stat <datei>     # sind es MEINE Zeilen?
git -C ~/.claude/skills diff <datei> | grep -a '^+### '   # welche Überschriften?
```
Weicht die Zeilenzahl vom eigenen Anhang ab, schreibt jemand anderes mit — dann `git add -p`
oder warten. Nichts ging verloren, aber die fremde Lektion ist früher und unter falscher
Commit-Message veröffentlicht; beide Sessions wurden per SendMessage informiert.
