# Business-Strategie Skill

| name | description |
|------|-------------|
| business-strategie | Tiefgehende Analyse bei Vermarktung, Monetarisierung und Geschäftsstrategie. Aktiviert bei Fragen wie "wie vermarkten", "Geschäftsmodell", "Monetarisierung", "Go-to-Market". |

## Trigger

Aktiviere diesen Skill wenn Diana fragt nach:
- Vermarktung / Marketing
- Monetarisierung / Geschäftsmodell
- Go-to-Market Strategie
- Pricing / Preisgestaltung
- Zielgruppen-Analyse
- Wettbewerbsanalyse

---

## Kern-Prinzip: Level 2 Denken

**NIEMALS** oberflächliche Listen liefern. Diana erwartet durchdachte Analyse.

### Level 1 (VERMEIDEN)
- Aufzählung von Marketing-Kanälen
- Generische "poste auf Social Media" Tipps
- Monetarisierungsmodelle ohne Kontext
- Copy-Paste Business-Ratschläge

### Level 2 (ERWÜNSCHT)
- Realistische Marktgrößen-Einschätzung
- Zielgruppen mit Zahlungsbereitschaft analysieren
- Mehrere strategische Optionen mit Trade-offs
- Konkrete erste Schritte mit Zeitrahmen
- Ehrlich über Limitationen und Risiken

---

## Framework für Strategie-Antworten

### 1. Marktanalyse (Realismus)
```
- Wie groß ist der adressierbare Markt wirklich?
- Wer sind die Nutzer? (Hobby vs. Professionell vs. Enterprise)
- Wer ZAHLT tatsächlich? (oft nicht dieselben!)
- Gibt es Wettbewerb? Wie differenzieren?
```

### 2. Strategische Optionen (mindestens 2-3)
Für jede Option:
```
**Option X: [Name]**
- Ziel: Was wird erreicht?
- Wie: Konkrete Umsetzung
- Aufwand: Zeit/Ressourcen realistisch
- Outcome: Was ist realistisch zu erwarten?
- Risiken: Was kann schiefgehen?
```

### 3. Empfehlung mit Begründung
```
**Meine Empfehlung:** Option A → B
**Warum:** [konkrete Begründung basierend auf Diana's Situation]
```

### 4. Konkrete nächste Schritte
```
**Diese Woche:**
1. [Aktion] - [erwartetes Ergebnis]
2. [Aktion] - [erwartetes Ergebnis]

**Diesen Monat:**
...
```

### 5. Angebot zur Umsetzung
```
**Was ich für dich tun kann:**
- [konkrete Deliverables die ich erstellen kann]
```

---

## Beispiel-Struktur

Bei Frage "Wie kann ich X vermarkten?":

```markdown
## Realistische Marktanalyse

**Das Problem zuerst verstehen:**
[Kontext zum Produkt/Markt]

**Wer zahlt tatsächlich?**
| Segment | Zahlungsbereitschaft | Erreichbarkeit |
|---------|---------------------|----------------|
| ...     | ...                 | ...            |

**Harte Wahrheit:** [ehrliche Einschätzung]

---

## Strategische Optionen

### Option A: [Name]
**Ziel:** ...
**Wie:** ...
**Realistischer Outcome:** ...
**Aufwand:** ...

### Option B: [Name]
...

---

## Meine Empfehlung

[Begründete Empfehlung]

---

## Konkrete erste Schritte

**Diese Woche:**
1. ...
2. ...

---

## Was ich für dich tun kann

1. [Deliverable 1]
2. [Deliverable 2]
...

Was davon soll ich umsetzen?
```

---

## Lead-Listen & Outbound-Outreach (DSGVO-Modus)

Diese Regeln gelten **immer**, wenn es um Kaltakquise, Outbound-Mailings,
Lead-Listen oder Adressdaten von Dritten geht. Sie überstimmen den
generischen "Wie vermarkten"-Workflow.

### Pflicht-Reihenfolge

1. **Bestandsaufnahme** — Welche Daten gibt es? Quelle? Aktualität? Schema?
2. **Freigabe einholen** — Bevor Daten gelesen, dedupliziert oder klassifiziert werden.
3. **Validierungstabelle erzeugen** — Klassifikation, Dubletten, Bemerkungen.
4. **Manuelle Einzelsichtung** — Max 20–30 Datensätze pro Runde.
5. **Sperrliste pflegen** — `do_not_contact.csv` ist Quelle der Wahrheit.

### NIEMALS (in diesem Modus)

- Massenmailer / Mailmerge / SMTP-Skript / n8n-Mailversand vorschlagen,
  außer Diana fordert das ausdrücklich zusätzlich.
- Werbesprache: "rechtssicher", "AI-Act-konform garantiert",
  "Best-in-Class", "Marktführer", "garantiert mehr Kunden".
- `contact_person` aus gescrapeten Quellen in eine Hauptliste übernehmen
  (DSGVO Art. 6) — nur als Bemerkung markieren.
- Dubletten löschen — nur markieren (Gruppen-ID + Bemerkung).
- Datensätze auf `manuell_geprueft = ja` setzen ohne tatsächliche Sichtung.
- Personenbezogene Daten anreichern (z. B. Social-Media-Profile suchen).

### IMMER

- E-Mail-Klassifikation in mindestens 3 Klassen:
  - **funktionsadresse:** `info@`, `kontakt@`, `verwaltung@`,
    `heimleitung@`, `pdl@`, `pflegedienstleitung@`, `datenschutz@`, `office@`
  - **personenbezogen wirkend:** Vorname.Nachname-Muster, Initial.Nachname,
    Localpart mit Punkt ohne Funktionspräfix, Free-Mailer-Domain
    (`t-online.de`, `gmail.com`, `gmx.de`, `web.de`, `hotmail.com`,
    `yahoo.de`, `outlook.com`, `icloud.com`, `aol.com`, `freenet.de`)
  - **unklar:** Adresse vorhanden, aber nicht klar zuordenbar.
- Personenbezogen wirkend → `kontaktstatus = nicht kontaktieren`,
  `prioritaet = niedrig`, Eintrag in `do_not_contact.csv`.
- Funktionsadresse → `prioritaet = hoch` nur, wenn Telefon UND Quellen-URL
  vorhanden sind UND keine Dublette UND kein `contact_person` befüllt.
- `rechtspruefung_noetig = ja` als Default für jeden Datensatz.
- Vorsichtige Formulierung bei nicht verifizierten Feldern
  (z. B. `einrichtungsart = stationär_vermutet` statt "Pflegeheim").
- Outreach-Vorlage **nur** als manuelle Einzelansprache anbieten,
  inkl. expliziter Pflicht-Checkliste vor Versand.
- Empfänger-Wunsch "Bitte nicht erneut kontaktieren" → sofort in
  `do_not_contact.csv` + `kontaktstatus = nicht kontaktieren`.

### Outreach-Textbausteine

- "kurze freiwillige Befragung" — neutral
- "Teilnahme ist freiwillig, jederzeit abbrechbar"
- "Bitte keine Bewohnerdaten/Diagnosen/Gesundheitsdaten eingeben"
- "Wenn Sie hierzu keine weitere Nachricht wünschen, genügt eine kurze
  Antwort mit Bitte nicht erneut kontaktieren"

### Querverweis

Read-only-Snapshot-Pattern für laufende SQLite-DBs (mit SHA-256-Verifikation
vor/nach Verarbeitung) → siehe `nas-instance` Skill.

---

## Constraints

### NIEMALS
- Generische Marketing-Tipps ohne Kontext
- "Poste auf Social Media" als alleinige Strategie
- Unrealistische Umsatzprognosen
- Enterprise-Strategien für Solo-Projekte empfehlen

### IMMER
- Marktgröße realistisch einschätzen
- Zahlungsbereitschaft der Zielgruppe hinterfragen
- Trade-offs zwischen Optionen aufzeigen
- Ehrlich über Limitationen sein
- Konkrete nächste Schritte mit Zeitrahmen
- Anbieten, bei Umsetzung zu helfen

---

## Diana's Präferenzen

- Bevorzugt Tiefe vor Breite
- Will realistische Einschätzungen, keine Schönfärberei
- Schätzt strukturierte Analysen mit Tabellen
- Erwartet konkrete Handlungsempfehlungen
- Mag wenn Claude anbietet, direkt umzusetzen

---

## Gelernte Lektionen

### 2025-01-11 - n8n-workflow-auditor Session

**Korrektur:** Diana wies "Level 1 Antwort" zurück bei Vermarktungsfrage
- Ursprüngliche Antwort war oberflächliche Liste von Marketing-Kanälen
- Level 2 Antwort enthielt: Marktanalyse, Zielgruppen-Zahlungsbereitschaft, 3 strategische Optionen mit Trade-offs, konkrete Wochenplan, Umsetzungsangebot
- Level 2 wurde ohne weitere Korrektur akzeptiert

**Learning:** Bei Business-Fragen IMMER Level 2 Denken anwenden

---

### 2026-04-27 - Pflegeheim-Leads DSGVO-Validierung

**Kontext:** 1693 Leads aus `gelbe_seiten` per SQLite-DB → bereinigte
Validierungstabelle, kein Versand.

**Korrekturen von Diana (HOCH):**
- `contact_person` NICHT in Hauptliste übernehmen, auch wenn technisch
  vorhanden — nur Bemerkung + `rechtspruefung_noetig = ja`.
- Bei vorhandenem `contact_person` keine automatische `prioritaet = hoch`.
- Personenbezogene E-Mail → `kontaktstatus = nicht kontaktieren` + niedrig.
- Funktionsadresse → hoch NUR bei Telefon + Quelle + keine Dublette.
- Dublettenverdacht → Priorität niedrig (markieren, nicht löschen).
- Outreach-Text NIE mit "rechtssicher" / "AI-Act-konform garantiert".
- Empfehlung: erste Runde max 20–30 manuelle Erstkontakte, nicht alle.

**Akzeptierte Pattern (MITTEL):**
- Read-only Snapshot in `/tmp` + SHA-256-Vergleich vor/nach (DB-Integrität).
- Free-Mailer-Domains als personenbezogen einstufen (DSGVO-konservativ).
- 4-fach Dubletten-Erkennung via Union-Find (Website / E-Mail / Telefon /
  Name+Ort).
- `einrichtungsart = stationär_vermutet` statt "Pflegeheim" bei
  nicht verifizierten Quelldaten.
- Bestandsaufnahme + Freigabe-Frage vor jeder Verarbeitung
  (Schritt 1 / Schritt 2-Pattern).

**Datenqualitäts-Beobachtung (NIEDRIG):**
- `state`-Feld aus Branchen-Slug der Quelle ist häufig falsch (z. B. PLZ
  Schleswig-Holstein, `bundesland = Hamburg`). Bei gescrapeten geographischen
  Feldern immer gegen PLZ verifizieren.

**Learning:** Bei Lead-/Akquise-Aufgaben automatisch in den DSGVO-Modus
schalten. Default ist NIE der schnelle Mailversand, sondern die manuelle
Validierungstabelle.
