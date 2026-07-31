---
name: rollen-workflow
description: Multi-Rollen-Workflow für Claude Code — eine Rolle pro Ordner mit eigener CLAUDE.md-Rollenkarte, Staffelübergabe (Handoff) zwischen den Rollen. Nutze diesen Skill, wenn Diana eine App/Software mit dem Rollen-Prinzip bauen will (Planer → Designer → Programmierer → Sicherheit → Marketing), ein neues Projekt aus der Vorlage aufsetzen möchte, oder nach "Rollen-Workflow", "Rollenkarte", "Handoff", "Staffelübergabe" fragt.
---

# Rollen-Workflow: Claude als komplettes Software-Team

## Das Prinzip in einem Satz

Statt „Bau mir eine App!" bekommt Claude **eine Rolle nach der anderen** — jede Rolle
lebt in einem eigenen Ordner mit einer eigenen `CLAUDE.md`-Rollenkarte und übergibt ihr
Ergebnis wie beim Staffellauf an die nächste Rolle.

## Die 3 goldenen Regeln

1. **Eine Rolle = ein Ordner = ein frischer Claude-Start.**
   So bleibt Claude konzentriert, wie ein Schüler mit nur einem Fach pro Stunde.
2. **Jede Rolle schreibt NUR in ihren eigenen Ordner.**
   Lesen darf sie überall (besonders in den Ordnern davor), schreiben nur bei sich.
3. **Jede Rollenkarte benennt exakt, was abgeliefert wird** (Dateiname!).
   Der Nächste im Team weiß dann genau, wo er suchen muss.

## Die 5 Rollen (aus dem Video)

| Nr. | Ordner              | Rolle                              | Liefert ab                      |
| --- | ------------------- | ---------------------------------- | ------------------------------- |
| 01  | `01-planer`         | Product Manager (Planer)           | `plan.md`                       |
| 02  | `02-designer`       | UI/UX Designer (Zeichner)          | `design.md` + `prototyp.html`   |
| 03  | `03-programmierer`  | Software Engineer (Baumeister)     | lauffähige App in `app/`        |
| 04  | `04-sicherheit`     | Security Engineer (Prüfer)         | `sicherheits-bericht.md`        |
| 05  | `05-marketing`      | Growth Marketer (Werbetrommler)    | `launch-texte.md`               |

## So setzt du ein neues Projekt auf

```bash
# Vorlage kopieren (Pfad zu diesem Skill-Repo anpassen)
cp -r ~/claude-skills/rollen-workflow/vorlage ~/meine-app
cd ~/meine-app

# 1. Idee ins Briefing schreiben (oder Skizzen-Foto ablegen)
#    → 00-briefing/AUFTRAG.md ausfüllen

# 2. Rollen nacheinander starten — pro Rolle ein FRISCHER Claude-Start:
cd 01-planer        && claude   # → schreibt plan.md
cd ../02-designer   && claude   # → liest ../01-planer/plan.md, baut Prototyp
cd ../03-programmierer && claude # → liest Plan + Prototyp, baut die App
cd ../04-sicherheit && claude   # → prüft die App, schreibt Bericht
cd ../05-marketing  && claude   # → schreibt Launch-Texte
```

**Wichtig:** Zwischen den Rollen selbst prüfen! Gefällt der Plan nicht → ändern lassen,
BEVOR der Designer startet. Fehler sind früh billig und spät teuer.

## Warum das besser funktioniert als „alles auf einmal"

- Jede Rolle hat einen kleinen, klaren Auftrag → weniger Kontext-Chaos, bessere Ergebnisse.
- Zwischenergebnisse sind Dateien → jederzeit prüfbar, versionierbar, korrigierbar.
- Ein frischer Claude-Start pro Rolle → kein „verschmutzter" Kontext aus der Vorrolle.

## Bezug zu bestehenden Skills

- **grill-me-codex** macht Architekt→Arbeiter in EINER Session. Der Rollen-Workflow ist
  dasselbe Prinzip, aber mit dauerhaften Ordnern und frischen Sessions pro Rolle —
  besser für größere Projekte mit mehreren Übergaben.
- Extra-Werkzeuge (Skills, MCP-Server) können pro Rolle in der jeweiligen `CLAUDE.md`
  erwähnt werden (z. B. Deployment-Wissen nur beim Programmierer).

## Anpassen der Vorlage

- Rollen weglassen ist okay: Für kleine Tools reichen oft `01-planer` + `03-programmierer`.
- Rollen ergänzen ist okay: z. B. `06-doku` (Technical Writer) oder `02b-datenmodell`.
- Nummerierung beibehalten — sie IST die Reihenfolge der Staffelübergabe.
