---
name: prompting-muster
description: Aktiviert Prompting-Muster aus der Bibliothek. Trigger bei "Nutze Muster", "Muster:", Musternamen (MVP-Validator, Monetarisierung, Conversion, Pre-Mortem, Sprint, etc.), oder wenn ein Projekt ein strukturiertes Vorgehen braucht.
---

# Prompting-Muster-Bibliothek

## Was dieser Skill tut

Enthält 16 einsatzbereite Prompting-Muster in drei Gruppen:

- **Basis (6):** Kombi-Agent, Pre-Mortem, Multi-Persona, Evaluation Criteria, Reversal,
  Architektur-Denker
- **Monetarisierung (4):** MVP-Validator, Monetarisierungs-Stratege, Conversion-Architekt,
  Wettbewerbs-Autopsie
- **App-Entwicklung (6):** Prompt-Kettenbauer, Solo-Dev-Sprint, User-Story-Zerlegung,
  Rubber-Duck-Debugger, Feature-Priorisierung (RICE), Chain-of-Density

## Trigger

- "Nutze Muster: [Name]" oder "Muster: [Name]"
- Ein Musternamen wird direkt genannt (z. B. "MVP-Validator", "Pre-Mortem")
- "Welches Muster passt für...?"
- "Muster-Bibliothek", "Prompting-Muster"

## Muster-Index

| ID | Name | Trigger-Wörter | Kategorie |
|---|---|---|---|
| kombi-agent | Kombi-Agent | "kombi", "vereint", "produktionsreif" | Planung |
| pre-mortem | Risiko-Analyst | "pre-mortem", "risiko", "scheitern" | Planung |
| multi-persona | Perspektiven-Debatte | "perspektiven", "debatte", "blinde flecken" | Analyse |
| eval-criteria | Qualitäts-Prüfer | "qualität", "kriterien", "checkliste" | Qualität |
| reversal | Rückwärts-Planer | "rückwärts", "reversal", "erfolgsbild" | Planung |
| constraint | Architektur-Denker | "architektur", "infrastruktur" | Technik |
| mvp-validator | MVP-Validator | "mvp", "validieren", "pilotkunden" | Monetarisierung |
| monetarisierung | Monetarisierungs-Stratege | "pricing", "preis", "go-to-market" | Monetarisierung |
| conversion | Conversion-Architekt | "landing page", "conversion", "trust" | Monetarisierung |
| wettbewerb | Wettbewerbs-Autopsie | "wettbewerb", "konkurrenz", "marktanalyse" | Monetarisierung |
| prompt-kette | Prompt-Kettenbauer | "prompt-kette", "pipeline", "chaining" | Technik |
| solo-sprint | Solo-Dev-Sprint | "sprint", "priorisierung", "wochenplan" | Produktivität |
| user-story | User-Story-Zerlegung | "user story", "invest", "epic" | Produktivität |
| rubber-duck | Rubber-Duck-Debugger | "debug", "fehler", "geht nicht" | Technik |
| rice-scoring | Feature-Priorisierung | "rice", "feature-prio", "scoring" | Produktivität |
| chain-density | Chain-of-Density | "verdichten", "verfeinern", "iterativ" | Qualität |

## Empfohlene Reihenfolge (für neue Produkte/Projekte)

```
1. Wettbewerbs-Autopsie   → Markt verstehen
2. MVP-Validator          → Problem validieren
3. Monetarisierungs-Stratege → Pricing festlegen
4. Conversion-Architekt   → Landing Page
5. User-Story-Zerlegung   → Features zerlegen
6. Solo-Dev-Sprint        → Entwicklung planen
7. Prompt-Kettenbauer     → Automatisierungen
```

Überspringe nie 1→2→3 (Markt, Validierung, Pricing). Die universellen Muster
(Qualitäts-Prüfer, Pre-Mortem, Debugger, Chain-of-Density, RICE, Perspektiven-Debatte,
Kombi-Agent) können jederzeit ergänzend eingesetzt werden.

## Workflow

**Ein konkretes Muster wird genannt:** Muster aktivieren, kurz ankündigen ("Ich
arbeite jetzt mit dem [Name]-Muster"), direkt mit Schritt 1 starten.

**Frage "Welches Muster passt?":** Aufgabe beschreiben lassen, 1–2 passende Muster mit
Begründung empfehlen, Rückfrage stellen, ob gestartet werden soll.

**Ein größeres Projekt wird beschrieben, ohne Muster zu nennen:** Proaktiv empfehlen —
neue Produktidee → MVP-Validator; Preisfindung → Monetarisierungs-Stratege; "Was baue
ich zuerst?" → Solo-Dev-Sprint + RICE; technische Architektur →
Architektur-Denker; "Wird das funktionieren?" → Pre-Mortem; Marketing/Website →
Conversion-Architekt; Feature zu groß → User-Story-Zerlegung; etwas ist kaputt →
Rubber-Duck-Debugger; Text verbessern → Chain-of-Density.

## Constraints

- Nie eine Muster-Phase überspringen
- Kill-Kriterien der Monetarisierungs-Muster einhalten
- Muster können kombiniert werden (z. B. Pre-Mortem + MVP-Validator)
- Alle Outputs copy-paste-fertig liefern

## Vollständige Muster-Texte

Die vollständigen System-Prompts für alle 16 Muster gehören in eine separate,
interaktive Referenzdatei (z. B. als Artifact) — dieser Skill ist der Index/Router, der
entscheidet, welches Muster wann zum Einsatz kommt.
