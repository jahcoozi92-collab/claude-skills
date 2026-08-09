# Prompt OS für Claude Code

Ein Fundament aus sechs Skills, die zusammen einen geschlossenen Regelkreis bilden:
Du korrigierst Claude einmal — der Fehler kommt nicht wieder.

> **Status:** Konzept-/Vorschau-Version. Dies ist eine bereinigte, allgemeingültige Fassung
> eines Systems, das im echten Alltag entstanden und getestet ist — persönliche und
> infrastrukturspezifische Inhalte wurden für diese Veröffentlichung entfernt.

---

## Warum dieses Kit anders ist

Die meisten Skill-Sammlungen sind statische Prompt-Vorlagen. Du kopierst sie einmal,
und sie veralten, sobald sich deine Arbeitsweise ändert. Dieses Kit funktioniert anders:

```
Session → Korrektur → reflect analysiert → Skill wird aktualisiert → nächste Session
   ↑                                                                        │
   └────────────────────────────────────────────────────────────────────────┘
```

`reflect` ist der Kern: Am Ende einer Session erkennt er, was du korrigiert hast, und
schreibt die Regel in den betroffenen Skill zurück — mit deiner Freigabe, nie automatisch
ungefragt.

## Die sechs Skills

| Skill | Rolle im System |
|---|---|
| **prompt-coach** | Eingangs-Filter. Prüft jeden Rohprompt nach Context/Task/Rules und entscheidet, ob ein einfacher Prompt reicht oder ein Muster nötig ist. |
| **prompt-geruest** | Bau-Vorlage für zuverlässige, komplexe Prompts (10-Schichten-Gerüst) — für alles, wo Halluzinationen teuer wären. |
| **prompting-muster** | Bibliothek strukturierter Vorgehensweisen (Planung, Analyse, Monetarisierung, App-Entwicklung). |
| **grill-me-codex** | Architekt-Arbeiter-Workflow für größere Bauaufgaben: Interview → TDD-Plan → Umsetzung → Validierung. |
| **business-strategie** | Erzwingt echte Marktanalyse statt Floskeln, wenn es um Monetarisierung/Vermarktung geht. |
| **reflect** | Der Regelkreis selbst — analysiert Sessions und schreibt Korrekturen in die anderen fünf Skills zurück. |

## Installation

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

Danach in deiner Claude-Code-Konfiguration den Skills-Ordner referenzieren (siehe
Claude-Code-Dokumentation zu `skills_directory`).

## Anpassen an deine Domäne

Diese Skills sind bewusst domänenneutral gehalten. Der Wert entsteht, wenn du sie an
deine eigene Arbeit anpasst — genau dafür ist `reflect` da: Nutze ihn ab der ersten
Session, dann wächst das System mit dir statt zu veralten.

## Lizenz / Nutzung

Konzeptversion — Bedingungen folgen mit dem öffentlichen Launch.
