# Git und parallele Sitzungen

## Vor Änderungen

- `git status` ungefiltert lesen.
- `.git/rebase-merge` und `.git/rebase-apply` explizit prüfen.
- Offene Änderungen anderen Sitzungen zuordnen; unklare Dateien nicht anfassen.
- Den gesamten Ziel-Skill einschließlich `OBSERVATIONS.md` nach vorhandenen Regeln durchsuchen.

## Rebase

- Einen fremd begonnenen Rebase niemals automatisch abbrechen oder überspringen.
- Vor Fortsetzung `git-rebase-todo` und `done` prüfen.
- Einen konfliktfreien offenen Rebase nicht-interaktiv mit `GIT_EDITOR=true git rebase --continue` fortsetzen; danach erneut Status, Branch und verbleibende Todo-Schritte prüfen.
- Vor dem Push `fetch`, den Unterschied zu `origin/main` prüfen und anschließend sauber rebasen.

## Commit

- Nur ausdrücklich benannte Dateien stagen.
- Direkt danach mit `git show --stat HEAD` und `git show --name-only HEAD` prüfen, ob fremde Inhalte aufgenommen wurden.
- Die erwartete Zeilenzahl mit dem tatsächlichen Commitumfang vergleichen.
- Historie nicht nachträglich umschreiben, wenn mehrere Sitzungen denselben Branch verwenden.
- Schreiben und Commit nicht durch lange Zwischenphasen trennen; andere Sitzungen können die Datei sonst in ihren Commit aufnehmen.

## Push

- Commit und Push als getrennte Aktionen behandeln.
- Eine Zustimmung zum Skill-Update ist keine automatische Zustimmung zum Push auf den Default-Branch.
- Eindeutig fragen: „Soll ich pushen?“
