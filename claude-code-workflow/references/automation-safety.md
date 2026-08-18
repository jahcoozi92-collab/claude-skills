# Sicherheit fragiler Automationen

## Hooks und Einstellungen

- Vor Änderungen an Hook-Konfigurationen das reale Format und vorhandene Beispiele lesen.
- JSON-Konfigurationen einzeilig und syntaktisch validieren; keine Kommentare oder ungeprüften Shell-Fragmente einbetten.
- Einen Hook nie so konfigurieren, dass er seine eigene Konfiguration bei jedem Lauf erneut verändert.
- Nach der Änderung einen kontrollierten Positiv- und Negativtest ausführen und die tatsächlich erzeugte Eingabe prüfen.

## Ontologie und Pending-Skripte

- Den kanonischen Graphen verwenden; bei Nichterreichbarkeit keinen lokalen Ersatzgraphen beginnen.
- Pending-Skripte vor Ausführung auf Shell-Expansion, Quoting, Variablen und mehrzeiliges JSON prüfen.
- Ziel-IDs vor `create`, `update` und `relate` abfragen; ein erneutes `create` darf keine bestehende Entity unbemerkt überschreiben.
- Erst alle benötigten Entities anlegen oder aktualisieren, danach Relationen erzeugen.
- Nach dem Lauf den sichtbaren Endzustand abfragen, nicht nur Exitcode oder angehängte Logzeile.

## Gemeinsam veränderter Zustand

- Vor jeder Mutation Status und Dateiversion frisch lesen.
- Nach jeder Mutation prüfen, ob ein Peer dieselbe Datei inzwischen verändert oder committet hat.
- Fremde Änderungen nicht aus Gedächtnis zuordnen; mit Status, Diff und Historie belegen.
