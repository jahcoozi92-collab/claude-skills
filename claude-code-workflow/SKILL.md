---
name: claude-code-workflow
description: Verhindere Zustands-, Datenverlust- und Verifikationsfehler bei Claude Code. Nutze bei parallelen Sessions, gemeinsam veränderten Dateien, Skills oder Hooks, Git-Rebase-/Commit-Konflikten, laufenden lokalen Prozessen oder Prüfservern sowie wiederholten oder irreführenden Verifikationsergebnissen.
---

# Claude Code Workflow

Arbeite zustandsbewusst, überprüfbar und konfliktarm. Behandle Dateisystem, Git, laufende Prozesse und andere Claude-Sitzungen als veränderlichen gemeinsamen Zustand.

## Vor dem Eingriff

1. Ermittle den tatsächlichen Ist-Zustand frisch; übernimm keine flüchtigen Pfade aus alten Sessions.
2. Lies `CLAUDE.md`, den passenden Fach-Skill und den Instanz-Skill, bevor du änderst.
3. Prüfe aktive Prozesse, Dienste, Symlinks und Referenzen, bevor du Dateien verschiebst oder entfernst.
4. Prüfe Git mit der Langform von `git status` und zusätzlich `.git/rebase-merge` sowie `.git/rebase-apply`.
5. Bewahre fremde oder unklare Änderungen; nie automatisch resetten, aborten oder skippen.

## Änderungen durchführen

- Ändere während einer Diagnose nur Variablen, die zur aktuellen Hypothese gehören.
- Behandle deaktivierten Code als mögliche frühere Entscheidung, nicht automatisch als Lücke.
- Halte Schreiben, `git add` und einen ausdrücklich beauftragten Commit möglichst in einem engen, kontrollierten Ablauf; prüfe danach Umfang und Inhalt des Commits.
- Nutze bei parallelen Sitzungen genaue Dateiverantwortung und überprüfe den Zustand erneut unmittelbar vor jeder Mutation.
- Trenne Commit und Push. Pushen nur nach eigener, eindeutiger Zustimmung.
- Rebase vor dem Push auf den aktuellen Remote-Stand; fremde Rebase-Schritte weder überspringen noch abbrechen.

Für die detaillierte Git- und Parallelitätscheckliste lies [references/git-concurrency.md](references/git-concurrency.md).

Für Hooks, Ontologie-Pending und andere fragile Automationen lies [references/automation-safety.md](references/automation-safety.md).

## Verifizieren

1. Prüfe die sichtbare Wirkung, nicht nur den internen Mechanismus.
2. Misstraue auch einem Nullbefund: Beweise mit einem bekannten Fehler, dass der Prüfer anschlagen kann.
3. Prüfe nach jeder eigenen Korrektur erneut, bis die objektive Fehlerzahl null ist.
4. Verifiziere bei lokalen Servern einen Marker aus der aktuellen Version; HTTP `200` allein genügt nicht.
5. Bei „unverändert“ oder „kommt nicht an“ verfolge die Auslieferung rückwärts von der Anzeige bis zur tatsächlichen Quelldatei.
6. Injiziere Zeit und Zufall in Zustandslogik; lies sie nicht verborgen aus der Umgebung.
7. Bei intermittierenden Fehlern genügt ein erfolgreicher Einzeltest nicht; nutze Wiederholungen und prüfe den Endzustand maschinell.

Für konkrete Prüfmuster lies [references/verification.md](references/verification.md).

## Eskalationsregeln

- Nach zwei Fehlversuchen bei subjektiven Ergebnissen: Referenzbild, Beispieltext oder Vergleichsvorlage erbitten.
- Nach drei Korrekturen auf derselben Qualitätsachse: technische Methode statt weiterer Parameteränderung hinterfragen.
- Genannte Symptome sind der Einstieg; prüfe angrenzende Auswirkungen innerhalb des beauftragten Umfangs.
- Wenn ein benötigtes Werkzeug fehlt, richte es innerhalb des erlaubten Umfangs ein oder benenne den echten Blocker.

## Umgebungsgrenzen

- Voice-Diktat (Leertaste halten, `/voice`) funktioniert nur, wenn die CLI auf der Maschine mit dem Mikrofon läuft. In SSH-Sessions und Remote-Umgebungen ist es laut offizieller Doku (code.claude.com/docs/en/voice-dictation) ausgeschlossen — die Meldung „hat nicht geklappt“ ist dann kein Paket-, Rechte- oder Treiberproblem, also nicht auf dem Server debuggen. Headless-Hosts wie das NAS haben zudem oft gar kein Aufnahmegerät (`arecord -l` prüfen: nur Playback-PCMs). Fix: Claude Code lokal auf einem Rechner mit Mikrofon starten (z. B. yoga7) und den Zielhost per SSH ansprechen.

## Lernen

Nutze `reflect`, um neue Claude-Code-spezifische Muster hier thematisch einzubauen. Lege ausführliche Fallberichte in `references/` ab; halte diese Hauptdatei kurz und handlungsorientiert.
