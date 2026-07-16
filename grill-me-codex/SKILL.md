---
name: grill-me-codex
description:
  Architekt-Arbeiter-Workflow für neue Features und Apps — Claude (Fable/Opus) plant per strukturiertem
  Interview und TDD, Codex (GPT 5.x) implementiert, Claude validiert in Revisionsschleifen. Trigger bei
  "/grill-me-codex", "grill me", "Architekt-Arbeiter", "baue mit Codex", "Zwei-Modell-Workflow", oder wenn ein
  neues Projekt/Feature von Grund auf gebaut werden soll.
---

# Grill Me Codex — Architekt-Arbeiter-Workflow

Zwei-Modell-Workflow nach dem Prinzip: **Ein Modell allein reicht nicht.**

- **Claude (Fable/Opus) = Architekt**: stellt Rückfragen, erstellt den Plan, schreibt die Tests (TDD),
  validiert das Ergebnis. Die "weiße Eule" — nachdenklich, präzise.
- **Codex (GPT 5.x) = Arbeiter**: setzt den Plan Schritt für Schritt um, bis alle Tests grün sind. Der
  "Rottweiler" — packt das Problem und lässt nicht los.

Vorteile: Stärken beider Modelle kombiniert, weniger Token-Verbrennung im teuren Modell, eingebaute
Qualitätssicherung durch Modell-Trennung (der Prüfer ist nie der Autor).

## Voraussetzungen

- Codex CLI installiert (`codex --version`) mit ChatGPT-Auth — siehe Memory `reference_codex_plugin`
- Codex-Plugin aktiv (`codex:codex-rescue` Agent verfügbar)
- **Fallback**: Ist Codex nicht verfügbar → Nutzer informieren und im Ein-Modell-Modus (Claude macht alles)
  fortfahren, aber explizit sagen, dass der Arbeiter-Schritt lokal läuft.

## Ablauf

### Phase 1 — Interview ("Grill Me")

Der Architekt grillt den Nutzer, BEVOR eine Zeile Code entsteht. Per `AskUserQuestion` (gebündelt, max. 4
Fragen pro Runde) klären — aber NUR was der Nutzer nicht schon vorgegeben hat:

1. **Tech-Stack / Grundgerüst** — z. B. Vite+React+TS (Empfehlung: schnellster Dev-Server) vs. Next.js vs.
   Bestand. Immer eine Empfehlung markieren.
2. **State-Management** — nativ (Context + useReducer) vs. Library (z. B. Zustand)
3. **Persistenz** — localStorage (Prototyp/Fallbeispiel) vs. echte DB (`supabase-prod`!) vs. keine
4. **Kernaktionen / Datenmodell** — welche CRUD-Operationen, welche Felder pro Entität
5. **Styling** — Tailwind (Default) vs. CSS-Module vs. Bestand; Light/Dark Mode ja/nein
6. **Qualitätssicherung** — Unit-Tests (Default, Best Practice), zusätzlich E2E?
7. **Zielgeräte** — fully responsive (Default) vs. Desktop-only

Bei Architektur-Entscheidungen: Constraint Propagation CoT anwenden (siehe CLAUDE.md Prompting-Standards). Bei
ganz neuen Projekten: kurzes Pre-Mortem vor Phase 2.

### Phase 2 — Plan (Architekt)

- Architekturplan erstellen: Dateistruktur, Module, Datenfluss, Task-Liste in Umsetzungsreihenfolge
- Design-Regeln aus `~/.claude/rules/ecc/web/` beachten (kein Template-Look, Design-Tokens,
  Performance-Budgets)
- Plan dem Nutzer kurz zusammenfassen (keine Freigabe-Schleife nötig, wenn das Interview eindeutig war)

### Phase 3 — Tests zuerst (RED)

- Test-Setup aufsetzen (Vitest/Jest nach Stack)
- Unit-Tests für die Kernlogik SCHREIBEN, BEVOR implementiert wird (AAA-Pattern, sprechende Namen)
- Test-Runner ausführen und **verifizieren, dass die Tests rot sind** — rote Tests sind der Arbeitsauftrag

### Phase 4 — Übergabe an den Arbeiter (Codex)

Agent-Tool mit `subagent_type: "codex:codex-rescue"` starten. Der Prompt an Codex enthält:

- Den vollständigen Plan aus Phase 2 (Dateistruktur, Entscheidungen aus dem Interview)
- Den Hinweis: "Die Tests unter <pfad> definieren das Soll-Verhalten. Implementiere, bis alle Tests grün sind.
  Tests selbst NICHT verändern."
- Harte Constraints: keine Platzhalter, keine :latest Tags, keine erfundenen APIs
- Schreibmodus ist Default (`--write` setzt der Rescue-Agent selbst)

Ein `task`-Aufruf pro Übergabe. Nicht parallel selbst implementieren — der Architekt wartet.

### Phase 5 — Validierung (Architekt) + Revisionsschleife

1. Tests ausführen (`npm test` / `pytest` etc.) und Build prüfen (`npm run build`)
2. **Rot** → Revisionsschleife: Fehlerausgabe + präzise Korrekturanweisung erneut an `codex:codex-rescue` mit
   `--resume` (setzt die letzte Codex-Session fort). Max. 3 Runden; danach übernimmt Claude die Restfixes
   selbst und vermerkt das im Report.
3. **Grün** → Code-Review durch den Architekten (code-reviewer Agent bei größeren Diffs): Plan eingehalten?
   Keine Secrets? Keine Test-Manipulation? Coverage ≥ 80 %?
4. Funktional verifizieren, nicht nur Tests: App starten, Kernflows durchklicken (bei Web: responsive per
   DevTools/Playwright bei 320/768/1440 prüfen)

### Phase 6 — Abnahme & Report

Kurzer Bericht an den Nutzer:

- Was gebaut wurde (Features, Stack-Entscheidungen)
- Testergebnis (X/Y grün, Coverage)
- Wer was gemacht hat (Architekt-Anteile vs. Codex-Anteile, Anzahl Revisionsrunden)
- Offene Punkte / bewusste Auslassungen

Commit erst nach Nutzer-Freigabe (Conventional Commits: `feat:` …).

## Abgrenzung

- **Kleine Fixes / Einzeldateien**: kein Grill-Me nötig — direkt umsetzen oder `codex:rescue` einzeln nutzen
- **Adversarial Review zweier Modelle**: dafür gibt es `/santa-loop`
- **Multi-Modell-Planung ohne Umsetzung**: `/multi-plan`
- Dieser Skill ist für: neue Apps, neue Features, größere Umbauten mit klarer Test-Definition
