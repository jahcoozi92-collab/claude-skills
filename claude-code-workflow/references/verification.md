# Verifikationsmuster

## Prüfer selbst prüfen

- Einen bekannten Verstoß einbauen oder eine bestehende Positivkontrolle verwenden.
- Sicherstellen, dass der Prüfer Strecken, Zeiträume oder Wertebereiche vollständig untersucht und nicht nur einzelne Punkte.
- Bei gewachsenen Logformaten zuerst alle tatsächlich vorkommenden Schlüssel- und Operationsformen zählen.

## Auslieferung prüfen

- Bei einem lokalen Server einen eindeutigen Marker der neuen Fassung abrufen.
- Serverstart und Inhaltsprüfung als getrennte Schritte ausführen.
- Bei Cacheverdacht die wirklich geladene URL, Query-Parameter und Quelldatei prüfen.

## Korrekturschleife

1. Fehlerzahl vor der Änderung messen.
2. Eine begründete Änderung ausführen.
3. Fehlerzahl erneut messen.
4. Neue Folgewirkungen untersuchen.
5. Erst bei objektivem Nullstand abschließen.

## Zeit und Intermittenz

- Uhrzeit, Datum, Zufall und externe Zustände als Eingaben modellieren.
- Intermittierende Fehler mehrfach unter denselben Bedingungen testen.
- Logs nur aus dem Zeitfenster nach dem relevanten Neustart oder Ereignis bewerten.

## Datengrundlage prüfen

- Neues Praxismaterial vor jeder Zählung (n, Stichprobe, „zweite Quelle") auf Identität mit bereits ausgewertetem Material prüfen: markante wörtliche Passagen, Struktur, Versionskennung. Eine Dublette erhöht n nicht — sie erlaubt nur die Nachprüfung der früheren Auswertung und wird genau so gemeldet.
- Hochgeladene Praxisdokumente vor dem Lesen einordnen: blanko oder ausgefüllt? Ausgefüllte Unterlagen können Personendaten tragen, die vor jedem Modellkontakt geschwärzt sein müssen.
- Geschäftsdaten (Entgelttabellen, Preislisten) sofort aus git-verwalteten Pfaden in einen gitignorierten Materialordner verschieben, bevor weitergearbeitet wird.
