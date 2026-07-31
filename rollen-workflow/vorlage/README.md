# Rollen-Workflow-Vorlage

Diese Ordner-Vorlage macht aus Claude ein komplettes Software-Team:
**eine Rolle pro Ordner, eine Rollenkarte (`CLAUDE.md`) pro Rolle, Staffelübergabe per Datei.**

## Schnellstart

1. Diesen `vorlage`-Ordner unter neuem Namen kopieren (z. B. `meine-app`).
2. `00-briefing/AUFTRAG.md` ausfüllen — deine Idee, gern mit Skizzen-Foto daneben.
3. Rollen **nacheinander** starten, pro Rolle ein **frischer** Claude-Start:

```bash
cd 01-planer && claude          # Rolle 1: Plan schreiben
cd ../02-designer && claude     # Rolle 2: Prototyp bauen
cd ../03-programmierer && claude # Rolle 3: App bauen
cd ../04-sicherheit && claude   # Rolle 4: App prüfen
cd ../05-marketing && claude    # Rolle 5: Launch-Texte
```

Claude liest beim Start automatisch die `CLAUDE.md` im aktuellen Ordner — das ist die
Rollenkarte. Du musst nur noch sagen: „Leg los" (oder Änderungswünsche nennen).

## Die 3 goldenen Regeln

1. **Eine Rolle = ein Ordner = ein frischer Claude-Start.**
2. **Jede Rolle schreibt nur in ihren eigenen Ordner** (lesen überall erlaubt).
3. **Jede Rolle liefert genau die Dateien ab, die auf ihrer Rollenkarte stehen.**

## Zwischen den Rollen: DU prüfst!

Nach jeder Rolle das Ergebnis anschauen. Plan unklar? Design hässlich?
→ In derselben Rolle nachbessern lassen, BEVOR die nächste Rolle startet.
Fehler sind früh billig und spät teuer.

## Übergabe-Kette (Handoff)

```
00-briefing/AUFTRAG.md
        │
        ▼
01-planer ──────────── plan.md
        │
        ▼
02-designer ────────── design.md + prototyp.html
        │
        ▼
03-programmierer ───── app/ (lauffähige App)
        │
        ▼
04-sicherheit ──────── sicherheits-bericht.md
        │
        ▼
05-marketing ───────── launch-texte.md
```

## Anpassen

- Kleines Tool? `02`, `04`, `05` einfach überspringen.
- Mehr Rollen nötig (Doku, Datenmodell, Tests)? Neuen nummerierten Ordner mit
  eigener `CLAUDE.md` nach demselben Rezept anlegen: **Wer bist du? Was bekommst du?
  Was lieferst du ab? + die goldenen Regeln.**
