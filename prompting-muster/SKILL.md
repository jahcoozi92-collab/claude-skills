---
name: prompting-muster
description: Aktiviert Prompting-Muster aus der Bibliothek. Trigger bei "Nutze Muster", "Muster:", Musternamen (MVP-Validator, Monetarisierung, Conversion, Pre-Mortem, Sprint, etc.), oder wenn ein Projekt ein strukturiertes Vorgehen braucht.
---

# Prompting-Muster-Bibliothek — Skill

## Was ist dieser Skill?

Enthält 16 produktionsreife Prompting-Muster in drei Gruppen:
- **Basis (6):** Kombi-Agent, Pre-Mortem, Multi-Persona, Evaluation Criteria, Reversal, Architektur-Denker
- **Level 2 Monetarisierung (4):** MVP-Validator, Monetarisierungs-Stratege, Conversion-Architekt, Wettbewerbs-Autopsie
- **Level 2 App-Dev (6):** Prompt-Kettenbauer, Solo-Dev Sprint, User-Story-Zerlegung, Rubber-Duck-Debugger, Feature-Priorisierung (RICE), Chain-of-Density

## Trigger

Aktiviere diesen Skill wenn Diana eines der folgenden sagt:
- "Nutze Muster: [Name]" oder "Muster: [Name]"
- Einen Musternamen direkt nennt (z.B. "MVP-Validator", "Pre-Mortem", "Sprint-Architekt")
- "Welches Muster passt für...?"
- "Muster-Bibliothek", "Prompting-Muster"

## Muster-Index

| ID | Name | Tier | Trigger-Wörter | Kategorie |
|----|------|------|---------------|-----------|
| kombi-agent | Kombi-Agent | S | "kombi", "vereint", "produktionsreif" | Planung |
| pre-mortem | Risiko-Analyst | S | "pre-mortem", "risiko", "scheitern" | Planung |
| multi-persona | Perspektiven-Debatte | S | "perspektiven", "debatte", "blinde flecken" | Analyse |
| eval-criteria | Qualitäts-Prüfer | S | "qualität", "kriterien", "checkliste" | Qualität |
| reversal | Rückwärts-Planer | A | "rückwärts", "reversal", "erfolgsbild" | Planung |
| constraint | Architektur-Denker | S | "architektur", "docker", "infrastruktur" | Technik |
| mvp-validator | MVP-Validator | S | "mvp", "validieren", "pilotkunden" | Monetarisierung |
| monetarisierung | Monetarisierungs-Stratege | S | "pricing", "preis", "go-to-market" | Monetarisierung |
| conversion | Conversion-Architekt | A | "landing page", "conversion", "trust" | Monetarisierung |
| wettbewerb | Wettbewerbs-Autopsie | A | "wettbewerb", "konkurrenz", "marktanalyse" | Monetarisierung |
| prompt-kette | Prompt-Kettenbauer | A | "prompt-kette", "pipeline", "chaining" | Technik |
| solo-sprint | Solo-Dev Sprint | A | "sprint", "priorisierung", "wochenplan" | Produktivität |
| user-story | User-Story-Zerlegung | A | "user story", "invest", "epic", "zerlegung" | Produktivität |
| rubber-duck | Rubber-Duck-Debugger | A | "debug", "fehler", "geht nicht" | Technik |
| rice-scoring | Feature-Priorisierung | A | "rice", "feature-prio", "scoring" | Produktivität |
| chain-density | Chain-of-Density | A | "verdichten", "verfeinern", "iterativ" | Qualität |

## Empfohlene Reihenfolge (für neue SaaS-Projekte)

```
1. Wettbewerbs-Autopsie → Markt verstehen
2. MVP-Validator → Problem validieren
3. Monetarisierungs-Stratege → Pricing festlegen
4. Conversion-Architekt → Landing Page
5. User-Story-Zerlegung → Features zerlegen
6. Solo-Dev Sprint → Entwicklung planen
7. Prompt-Kettenbauer → Automatisierungen
```

Überspringe nie 1→2→3 (Markt, Validierung, Pricing).
Universelle Muster (Qualitäts-Prüfer, Pre-Mortem, Debugger, Chain-of-Density, RICE, Perspektiven-Debatte, Kombi-Agent) können jederzeit ergänzend eingesetzt werden.

## Workflow

### Wenn Diana ein SPEZIFISCHES Muster nennt:
1. Aktiviere das Muster-System-Prompt
2. Sage kurz: "Ich arbeite jetzt mit dem [Name]-Muster."
3. Starte direkt mit Schritt 1 des Musters

### Wenn Diana fragt "Welches Muster passt?":
1. Lass sie die Aufgabe beschreiben
2. Empfehle 1-2 passende Muster mit Begründung
3. Frage: "Soll ich [Muster X] starten?"

### Wenn Diana ein großes Projekt beschreibt (ohne Muster zu nennen):
Empfehle proaktiv:
- Neues Produkt/Geschäftsidee → MVP-Validator
- Preisfindung → Monetarisierungs-Stratege
- "Was baue ich zuerst?" → Solo-Dev Sprint + RICE
- Technische Architektur → Architektur-Denker
- "Wird das funktionieren?" → Pre-Mortem
- Marketing/Website → Conversion-Architekt
- Feature zu groß → User-Story-Zerlegung
- Etwas geht kaputt → Rubber-Duck-Debugger
- Text/Konzept verbessern → Chain-of-Density

## Constraints

- NIEMALS eine Muster-Phase überspringen
- IMMER Kill-Kriterien der Level-2-Muster einhalten
- Muster können KOMBINIERT werden (z.B. Pre-Mortem + MVP-Validator)
- Alle Muster antworten auf Deutsch
- Alle Outputs copy-paste-fertig

## Vollständige System-Prompts

Die vollständigen Prompts für alle 16 Muster sind in der interaktiven Bibliothek verfügbar (React Artifact "prompting-bibliothek.jsx"). Jeder Prompt kann dort kopiert oder direkt aktiviert werden.

## Gelernte Lektionen

*Noch keine — führe `/reflect prompting-muster` nach einer Session aus.*
