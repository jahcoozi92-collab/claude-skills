---
name: grill-me-codex
description:
  Architekt-Arbeiter-Workflow für neue Features und Apps — Claude plant per strukturiertem Interview und TDD,
  ein zweites (typischerweise günstigeres) Modell implementiert, Claude validiert in Revisionsschleifen.
  Trigger bei "/grill-me-codex", "grill me", "Architekt-Arbeiter", "Zwei-Modell-Workflow", oder wenn ein neues
  Projekt/Feature von Grund auf gebaut werden soll.
---

# Grill Me Codex — Architekt-Arbeiter-Workflow

Zwei-Modell-Workflow nach dem Prinzip: **Ein Modell allein reicht nicht.**

- **Architekt (dein Hauptmodell):** stellt Rückfragen, erstellt den Plan, schreibt die
  Tests (TDD), validiert das Ergebnis. Nachdenklich, präzise.
- **Arbeiter (zweites, oft günstigeres Modell/CLI):** setzt den Plan Schritt für Schritt
  um, bis alle Tests grün sind. Hartnäckig, lässt nicht los.

Vorteile: Stärken beider Modelle kombiniert, weniger Token-Verbrennung im teuren
Modell, eingebaute Qualitätssicherung durch Modell-Trennung — der Prüfer ist nie der
Autor.

## Voraussetzungen

- Eine CLI oder API für das Arbeiter-Modell muss verfügbar und authentifiziert sein
- **Fallback:** Ist das Arbeiter-Modell nicht verfügbar → Nutzer informieren und im
  Ein-Modell-Modus fortfahren (Architekt übernimmt beide Rollen), das explizit sagen

## Ablauf

### Phase 1 — Interview ("Grill Me")

Der Architekt klärt, BEVOR eine Zeile Code entsteht — gebündelt, max. 4 Fragen pro
Runde, nur was noch nicht vorgegeben wurde:

1. **Tech-Stack / Grundgerüst** — immer eine Empfehlung markieren
2. **State-Management** — nativ vs. Library
3. **Persistenz** — lokal/Prototyp vs. echte Datenbank vs. keine
4. **Kernaktionen / Datenmodell** — welche Operationen, welche Felder pro Entität
5. **Styling** — Standard-Framework vs. Bestand; Light/Dark Mode ja/nein
6. **Qualitätssicherung** — Unit-Tests (Standard), zusätzlich End-to-End?
7. **Zielgeräte** — responsive (Standard) vs. Desktop-only

Bei Architektur-Entscheidungen: mehrere Optionen mit Trade-offs statt einer einzelnen
Empfehlung ohne Begründung. Bei ganz neuen Projekten: kurzes Pre-Mortem vor Phase 2.

### Phase 2 — Plan (Architekt)

- Architekturplan erstellen: Dateistruktur, Module, Datenfluss, Task-Liste in
  Umsetzungsreihenfolge
- Bestehende Design-/Code-Konventionen des Projekts beachten
- Plan kurz zusammenfassen (keine Freigabe-Schleife nötig, wenn das Interview eindeutig
  war)

### Phase 3 — Tests zuerst (RED)

- Test-Setup aufsetzen
- Unit-Tests für die Kernlogik schreiben, BEVOR implementiert wird (AAA-Pattern,
  sprechende Namen)
- Test-Runner ausführen und verifizieren, dass die Tests rot sind — rote Tests sind der
  Arbeitsauftrag

### Phase 4 — Übergabe an den Arbeiter

Auftrag als Datei schreiben (z. B. `TASK.md` im Projektordner), dann das
Arbeiter-Modell darauf verweisen.

**Modellwahl:** Nutze für den Arbeiter das günstigste Modell, das die Tests
zuverlässig grün bekommt — bei komplexen Aufgaben, an denen es in der
Revisionsschleife scheitert, auf ein stärkeres Modell hochschalten.

Der Auftragstext enthält:

- Den vollständigen Plan aus Phase 2
- Den Hinweis: „Die Tests unter `<pfad>` definieren das Soll-Verhalten. Implementiere,
  bis alle Tests grün sind. **Schränkt dich ein Test ein, ändere das Design — nicht den
  Test.**"
- Harte Constraints: keine Platzhalter, keine `:latest`-Tags, keine erfundenen APIs
- Auftragsdateien mit den echten Sonderzeichen der Zielsprache schreiben (keine
  ASCII-Ersatzschreibweise) — das Arbeiter-Modell übernimmt Formulierungen wörtlich in
  nutzersichtbare Texte

Ein Aufruf pro Übergabe. Nicht parallel selbst weiterarbeiten — der Architekt wartet.

### Phase 5 — Validierung (Architekt) + Revisionsschleife

1. Tests selbst ausführen und Build prüfen — **der Testbericht des Arbeiter-Modells ist
   kein Nachweis, der Architekt misst immer selbst nach.** Umgebungsunterschiede
   (z. B. andere Laufzeit-Version) können einen falschen "alles grün" vortäuschen, ohne
   dass der Code fehlerhaft ist.
2. **Rot** → Revisionsschleife: Fehlerausgabe + präzise Korrekturanweisung an den
   Arbeiter. Max. 3 Runden; danach übernimmt der Architekt die Restfixes selbst und
   vermerkt das im Report.
3. **Grün** → Code-Review durch den Architekten: Plan eingehalten? Keine Secrets? Keine
   Test-Manipulation? Coverage ausreichend?
4. Funktional verifizieren, nicht nur Tests: App starten, Kernflows durchklicken.

### Phase 6 — Abnahme & Report

Kurzer Bericht:

- Was gebaut wurde (Features, Stack-Entscheidungen)
- Testergebnis (X/Y grün, Coverage)
- Wer was gemacht hat, Anzahl Revisionsrunden
- Offene Punkte / bewusste Auslassungen

Commit erst nach Freigabe.

## Abgrenzung

- **Kleine Fixes / Einzeldateien:** kein Grill-Me nötig — direkt umsetzen
- **Adversarial Review zweier Modelle:** eigener, spezialisierter Workflow
- **Multi-Modell-Planung ohne Umsetzung:** eigener, spezialisierter Workflow
- Dieser Skill ist für: neue Apps, neue Features, größere Umbauten mit klarer
  Test-Definition
