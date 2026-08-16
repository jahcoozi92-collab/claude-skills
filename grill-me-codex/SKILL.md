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
- 🔴 **Der Agent `codex:codex-rescue` existiert auf der NAS NICHT** (verifiziert 2026-08-02). Ein
  `Agent`-Aufruf mit diesem `subagent_type` schlägt fehl. Stattdessen die CLI direkt aufrufen — siehe Phase 4.
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

Auftrag als **Datei** schreiben (`CODEX_TASK.md` im Projektordner), dann die CLI direkt aufrufen:

```bash
codex exec -s workspace-write --skip-git-repo-check -m gpt-5.6-luna -C <projektverzeichnis> "$(cat CODEX_TASK.md)"
```

**Modellwahl Arbeiter (Stand 2026-08-04):** `gpt-5.6-luna` — laut Frontier-Code-Benchmark für viele Aufgaben
auf Opus-5-Niveau (Extra High) bei ~17× geringerem Preis (nach der 80%-Preissenkung: ~0,20 $/Mio Input-Token).
Das globale Codex-Default (`gpt-5.6-sol` in `~/.codex/config.toml`) bleibt unverändert für interaktive
Nutzung; das `-m`-Flag überschreibt nur pro Aufruf. Smoke-Test am 2026-08-04 verifiziert (`-m gpt-5.6-luna`
wird akzeptiert). Bei komplexen Aufgaben, an denen Luna in der Revisionsschleife scheitert: auf `gpt-5.6-sol`
hochschalten.

🔴 **Flag-Fallen (alle 2026-08-02 verifiziert):**

- `--full-auto` **gibt es nicht** — der Schreibmodus kommt allein über `-s workspace-write`
- `codex exec resume` akzeptiert **weder `-s` noch `-C`**; diese Flags gehören nur an `exec` selbst. Für
  Revisionsrunden deshalb entweder aus dem Zielverzeichnis heraus `resume` aufrufen oder eine frische
  `exec`-Runde mit Verweis auf den Stand starten.
- Der Auto-Modus-Classifier blockt `codex exec` mit **Pipes oder `$(cat …)`** in manchen Formen. Robuster Weg:
  Auftragsdatei schreiben, Codex per Auftragstext auf sie verweisen lassen („Lies CODEX_TASK.md in diesem
  Verzeichnis und arbeite sie ab").

Der Auftragstext enthält:

- Den vollständigen Plan aus Phase 2 (Dateistruktur, Entscheidungen aus dem Interview)
- Den Hinweis: „Die Tests unter <pfad> definieren das Soll-Verhalten. Implementiere, bis alle Tests grün sind.
  **Schränkt dich ein Test ein, ändere das Design — nicht den Test.**"
- Harte Constraints: keine Platzhalter, keine :latest Tags, keine erfundenen APIs
- 🟡 **Echte Umlaute schreiben.** ASCII-Ersatz (`fuer`, `loeschen`) wandert sonst wörtlich in nutzersichtbaren
  Produkttext — passiert, sobald Codex Beschriftungen aus dem Auftrag übernimmt.

Ein Aufruf pro Übergabe. Nicht parallel selbst implementieren — der Architekt wartet.

**🟢 Bewährt (3 Zyklen, 242 Tests, 0 veränderte Testdateien):** Der Satz „ändere das Design, nicht den Test"
hielt durchgehend. Er gehört wörtlich in jeden Auftrag.

### Phase 5 — Validierung (Architekt) + Revisionsschleife

1. Tests ausführen (`npm test` / `pytest` etc.) und Build prüfen (`npm run build`)

   🔴 **Codex' Testbericht ist KEIN Nachweis — der Architekt misst immer selbst nach.** Am 2026-08-02 meldete
   Codex „166/166 grün", dieselbe Suite zeigte bei mir **63 Fehlschläge** (alle 401-Sicherheitstests). Ursache
   war weder Code noch Lüge, sondern die Umgebung: Codex' Sandkasten läuft auf **Node 18**, meine Shell auf
   **Node 24** — `better-sqlite3` war für die falsche ABI gebaut (`NODE_MODULE_VERSION 108` vs. `137`). **Der
   Code war korrekt.** Fix: `npm rebuild better-sqlite3`. Ein `require()` allein entlarvt das nicht — die
   native Bindung lädt erst, wenn tatsächlich eine Datenbank geöffnet wird. Ein Vorab-Check muss also wirklich
   `new Database(':memory:')` aufrufen.

2. **Rot** → Revisionsschleife: Fehlerausgabe + präzise Korrekturanweisung an Codex (Flags siehe Phase 4 —
   `resume` verträgt kein `-s`/`-C`). Max. 3 Runden; danach übernimmt Claude die Restfixes selbst und vermerkt
   das im Report.
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

---

## Phase 0 — Konzeptrunde vor dem Interview (bei großen Vorhaben)

Der Ablauf oben startet beim Interview und geht direkt in TDD. Kommt das Vorhaben als **Master-Prompt
mit mehreren Phasen** (Analyse → Expertenrat → PRD → Architektur → UX → erst dann Code) oder liegt
bereits ein umfangreiches Ausgangsdokument vor, gehört eine Konzeptrunde davor. Sonst wird ein
Entwurf implementiert, dessen tragende Annahmen nie geprüft wurden.

**Erkennungsmerkmal:** Der Nutzer liefert eine Spezifikation statt einer Idee, oder verlangt
ausdrücklich mehrere Rollen/Agenten. Dann ist das Interview nicht der erste Schritt.

### Expertenrat statt Direkt-Interview

Rollen, die sich bewährt haben: Markt/Produktstrategie · Architektur · Infrastruktur & Kosten ·
UX/Adoption · Recht & Sicherheit · Red Team. Getrennt beauftragen, **ohne Kenntnis voneinander** —
der Ertrag entsteht daraus, dass zwei Rollen aus verschiedenen Richtungen dieselbe Schwachstelle
finden. In der VDAB-Session fanden UX und Recht unabhängig dieselbe Stelle (eine Risikozahl neben
einem Namen) und schlugen dieselbe Lösung vor.

**Auftragsformat, das Kontextüberlauf verhindert:**

> Schreibe deine Analyse nach `docs/02-agentN-thema.md`.
> Gib als finalen Text maximal 450 Wörter zurück: [die drei bis fünf Kernfragen].

Ohne diese Klausel liefern Agenten mehrere tausend Wörter zurück und fluten den Architektenkontext.

**In JEDEN Agentenauftrag gehört:**
- „Erfinde keine Zahlen/Normen/Preise. Jede Angabe mit Quelle und Datum. Schätzungen als solche
  kennzeichnen."
- „Sei kritisch, nicht bestätigend. Deine Aufgabe ist prüfen, nicht loben."
- Echte Umlaute (wandern sonst wörtlich in nutzersichtbaren Produkttext)

### 🔴 Websearch-Budget ist endlich — Recherche-Agenten staffeln

Eine Session hat **200 Websuchen**. Sechs parallel gestartete Agenten haben es in der VDAB-Session
vollständig aufgebraucht, bevor die Synthese begann (allein der Marktagent: 74 Werkzeugaufrufe).
Wer danach dran ist, sucht ins Leere — **liefert aber trotzdem eine Antwort**. Genau daraus
entstehen erfundene Angaben.

**Regel:** Recherchelastige Rollen (Markt, Recht, Preise) zuerst und allein losschicken. Rollen, die
überwiegend aus dem Ausgangsmaterial arbeiten (Architektur, UX, Red Team), danach. Beim Aufbrauchen
des Budgets den Nutzer informieren — er kann `CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` anheben.
`WebFetch` auf einzelne URLs funktioniert weiterhin.

### 🔴 Agentenberichte sind Rohmaterial, kein Ergebnis

Zwei Rechercheagenten haben in derselben Session eigene Angaben **selbst als erfunden
zurückgezogen** (ein kompletter Kostenabschnitt, ein Lizenzname, eine Parameterzahl). Daraus folgt:
Was auffällig falsch war, wurde bemerkt — was unauffällig erfunden ist, steht noch drin.

Vor der Synthese jede Zahl prüfen, die eine Investitions-, Rechts- oder Architekturentscheidung
trägt. Drei Wege, die funktioniert haben:

| Quelle | Weg |
|---|---|
| **Amtliches PDF** | WebFetch scheitert oft an großen PDFs, speichert die Datei aber lokal → `pdftotext -layout datei.pdf out.txt` + `grep -n` |
| **EU-Recht** | EUR-Lex-Volltext ist für WebFetch zu groß (bricht in den Erwägungsgründen ab). Verordnungs-Metadaten per CELEX-URL, Artikelwortlaut über eine Artikel-Einzelseite |
| **Modell-Lizenz** | HuggingFace-MCP `hub_repo_details` liefert Lizenz, Parameterzahl und Sprachen direkt |

Belegstand sichtbar dokumentieren (belegt / geschätzt / unbelegt), statt ihn zu glätten. Widersprüche
zwischen zwei Läufen offen als unbestätigt ausweisen, nicht auf einen Wert einigen.

### 🔴 Lizenzen prüfen, BEVOR die Architektur steht

Zwei Lizenzfallen in einem Vorhaben, beide erst nach dem Bauen schmerzhaft:

- **n8n** (Sustainable Use License): Weitergabe nur kostenlos und nicht-kommerziell → als Laufzeit
  eines verkauften SaaS ausgeschlossen. Bleibt als interne Werkstatt nutzbar.
- **Teuken-7B** (cc-by-nc-4.0): das naheliegende deutsche Modell, kommerziell unbrauchbar.

Prüfen, sobald eine Komponente in die engere Wahl kommt — nicht erst im Deployment. Bei Modellen:
Apache-2.0 o. ä. ist Auswahlkriterium Nummer eins, Qualität kommt danach.

## 🟡 Handover am Sessionende — ohne dass gefragt wird

Bei mehrstündigen Projektsessions gehört ein Wiedereinstiegspunkt zum Abschluss, nicht auf Nachfrage.
In der VDAB-Session musste Diana zweimal nachfassen („wie kann ich morgen weiterarbeiten", „auf
welcher Hardware"). Beides hätte von selbst kommen müssen.

Erzeugt werden:

1. **`<projekt>/CLAUDE.md`** — wird beim Öffnen automatisch geladen. Produktkern, harte Regeln,
   technische Festlegungen, korrigierte Fehler als Prüfregel. Verweist auf die Dokumente, dupliziert
   sie nicht.
2. **`<projekt>/docs/STATUS.md`** — Arbeitsstand, mögliche nächste Wege mit Aufwand, offene Punkte,
   und was **nur der Nutzer** beisteuern kann (Beispieldaten, Telefonate, anwaltliche Prüfung).
3. **Memory-Einträge** für projektübergreifenden Kontext.
4. **Den Rechnernamen und die Zugangswege nennen** — bei einem verteilten Setup ist „wo liegt das"
   keine triviale Frage.

Dazu gehört der Hinweis, wenn das Projektverzeichnis **kein Git-Repository** ist. Nicht ungefragt
anlegen — aber sagen, dass die Arbeit genau einmal auf einer Platte liegt.

## 🔵 Erklärstufe auf Anforderung wechseln

Diana hat mitten in der Konzeptarbeit um eine Fassung „für einen 12-Jährigen" gebeten. Das ist kein
Themenwechsel, sondern eine Prüfung, ob die Sache selbst verstanden ist. Funktioniert hat: ein
konkretes Bild aus dem Alltag (Regenschirmverleih vor dem Bahnhof), dann die drei Fragen daran
entlanggeführt — ohne Fachbegriffe, aber ohne den Inhalt zu verkleinern.

---

## Zweite Betriebsart: Codex als PRÜFER (statt als Arbeiter)

Der Ablauf oben lässt Codex **bauen**. Das Kernprinzip des Skills — *der Prüfer ist nie der
Autor* — trägt aber auch ohne Implementierung. Verlangt der Nutzer eine Bewertung („was kann
man verbessern"), und hat Claude zu demselben Gegenstand bereits eine Analyse geliefert, ist
Codex als **unabhängiger Zweitprüfer** die passende Rolle.

**Aufruf (read-only, kein Schreibzugriff auf das Produktivsystem):**

```bash
codex exec -s read-only --skip-git-repo-check -C <verzeichnis> \
  "Lies die Auftragsdatei <pfad>/CODEX_TASK.md und arbeite sie ab."
```

**In den Auftrag gehört zwingend:**

- „Du bist der Prüfer, nicht der Autor." Die eigene Analyse **bewusst zurückhalten** — sonst
  bestätigt Codex sie, statt unabhängig zu suchen.
- „Jede Feststellung mit `Datei:Zeile` belegen. Was du nicht gelesen hast, behauptest du nicht."
- „Sei kritisch, nicht bestätigend. Drei belegte Befunde sind besser als zehn geratene."
- Bei Produktivsystemen: „Gib niemals Inhalte aus `secrets.yaml`, `.env` oder `.storage/` wieder."
- Ausgabeformat je Befund: `[SCHWERE] Datei:Zeile — Befund — konkrete Folge im Betrieb`

### 🔴 `-s read-only` verträgt KEINEN Auftrag, der eine Datei verlangt

Am 2026-08-16 stand im Auftrag „schreibe deine Analyse nach `…/codex-befunde.md`", während der
Aufruf `-s read-only` gesetzt hatte. Codex konnte nicht schreiben — und verbrauchte einen seiner
Befund-Slots dafür, genau das zu melden. Der Widerspruch war meiner, nicht seiner.

**Regel:** Im Prüf-Modus kommt das Ergebnis über den **Rückgabetext**. Die Wortbegrenzung aus
Phase 0 („maximal N Wörter zurückgeben") bleibt trotzdem wichtig, sonst flutet der Bericht den
Architektenkontext. Eine Datei nur verlangen, wenn der Aufruf `workspace-write` hat.

### 🔴 Die Modellangabe im Skill gegen `~/.codex/config.toml` prüfen, nicht übernehmen

Dieser Skill nennt `gpt-5.6-luna` (Stand 2026-08-04). Am 2026-08-16 stand in der config
tatsächlich `model = "gpt-5.5"` mit `model_reasoning_effort = "xhigh"` — das im Skill genannte
Default `gpt-5.6-sol` existierte dort nicht mehr.

**Regel:** Vor dem Aufruf einmal nachsehen:

```bash
codex --version; grep -iE "^model" ~/.codex/config.toml
```

Für reine Analyse ist das konfigurierte Default mit hoher Denkstufe meist die bessere Wahl als
ein per `-m` erzwungenes Modell, dessen Verfügbarkeit man nicht geprüft hat. Ein `-m` auf einen
Namen, den es nicht mehr gibt, lässt den ganzen Lauf scheitern.

### 🟡 Der Ertrag liegt in der EBENEN-Differenz, nicht in der Menge

Beleg vom 2026-08-16 (Home-Assistant-Stack): Von meinen vier Befunden waren **zwei falsch** —
beide auf Infrastruktur-Ebene (Tunnel-Route zeige am Reverse-Proxy vorbei; zwei Connectors seien
riskant). Beide zerfielen bei der Prüfung an der maßgeblichen Quelle.

Codex, der dieselbe Codebasis ohne Kenntnis meiner Analyse las, lieferte **drei Befunde in der
Logik** — alle drei an der Quelle bestätigt:

| Befund | Folge im Betrieb |
| ------ | ---------------- |
| Ziel wird bei der Bestätigung neu gelesen statt beim Auswerten gemerkt | Messwert landet auf dem falschen Gaszähler, in der Abrechnungsgrundlage |
| Serielle Cover-Aufrufe ohne `continue_on_error` | ein Cloud-Fehler bricht die Nachtabsenkung ab, Folgeräume bleiben offen |
| Merker wird VOR dem Gerätebefehl gesetzt | System hält den Raum für geparkt, während der Heizkörper weiterheizt |

**Lehre:** Wer ein System selbst betreibt, prüft zuerst die Ebene, die er am besten kennt — hier
die Verkabelung. Die teuren Fehler sitzen in der Logik. Genau dafür lohnt der zweite Blick eines
Modells, das die eigene Vorgeschichte nicht kennt.

**Und die Verifikationspflicht gilt unverändert:** Alle sieben Codex-Befunde wurden an der
Fundstelle nachgelesen. Zwei davon waren **keine** Handlungsempfehlung — einer beschrieb eine
dokumentierte Nutzerentscheidung, einer eine bewusst gewählte Container-Konfiguration. Ein
Prüfbericht ist Rohmaterial, kein Ergebnis.

## 2026-08-16 — Skill-Verweis in der Projekt-CLAUDE.md ist eine Ladeanweisung; Attrappen-Grenze; Gegenprobe

**🔴 Ein Verweis auf `/grill-me-codex` in der Projekt-CLAUDE.md heißt: diesen Skill laden, bevor der
erste Befehl läuft**
- Die CLAUDE.md des Projekts sagte wörtlich „Ab Phase 7 gilt der Architekt-Arbeiter-Workflow
  (`/grill-me-codex`)". Ich habe die Datei gelesen, den Workflow aus dem Gedächtnis gefahren — und
  `codex exec --full-auto` aufgerufen. Dass es dieses Flag nicht gibt, steht in Phase 4 dieses Skills
  seit dem 2026-08-02, samt korrektem `-s workspace-write`.
- Folgekosten: Der Aufruf schlug still fehl (kein Output, Exit sofort). Ich habe die Blockade dem
  Auto-Modus-Classifier zugeschrieben, dem Nutzer denselben falschen Befehl zum Selbstausführen
  gegeben, und wir haben zwei Runden mit Auth- und Session-Diagnose verbracht, bis `codex exec --help`
  die Wahrheit zeigte.
- **Regel:** Nennt eine Projekt-CLAUDE.md einen Skill, ist das kein Hintergrundwissen, sondern eine
  Ladeanweisung — auch und gerade dann, wenn man den Workflow zu kennen glaubt. Gedächtnis schlägt
  hier systematisch fehl, weil genau die Flag-Details verlorengehen, die den Unterschied machen.
- **Diagnose-Reihenfolge bei stillem CLI-Fehlschlag** (bevor „Classifier" oder „Auth" vermutet wird):
  `<cli> <sub> --help | grep -E "flag1|flag2"` → Session-/Logverzeichnis auf einen neuen Eintrag
  prüfen (`ls ~/.codex/sessions/<jahr>/<monat>/`) → erst dann Umgebung und Berechtigungen.
  Kein neuer Session-Eintrag = der Aufruf hat nie begonnen = Argumentfehler, nicht Blockade.

**🔴 Wird die Übergabe an Codex blockiert: roten Stand als eigenen Commit festhalten**
- Der Skill beschreibt Phase 4 nur für den Fall, dass Codex läuft. Ist die Übergabe nicht möglich
  (Berechtigung, Anbieter offline, kein Zugang), implementiert der Architekt selbst — dann fehlt aber
  der strukturelle Beleg, dass die Tests vor der Implementierung standen.
- **Vorgehen:** Tests schreiben, rot verifizieren, **committen** (`test: … (rot)`), erst danach
  implementieren und als zweiten Commit grün stellen. Die Trennung ist damit im Verlauf nachweisbar,
  nicht nur behauptet — und der Nutzer kann sie prüfen, ohne dem Bericht glauben zu müssen.
- Im Auftragsdokument einen Erledigungsvermerk hinterlassen: wer implementiert hat, warum nicht Codex,
  und dass die Testdateien unverändert blieben. Sonst liest die nächste Sitzung „Auftrag 02" und hält
  ihn für offen.

**🔴 Ein Test gegen eine Attrappe beweist nichts über die Grenze zu einem echten System**
- Ich hatte einen SQL-Filter (`anlass = ANY($4::text[])`) über eine Attrappen-Ablage getestet: grün.
  Die Attrappe hätte bei falschem SQL genauso grün gemeldet — sie führt das SQL nie aus.
- Erst der Testlauf gegen eine echte Datenbank (hier PGlite, eingebettetes PostgreSQL ohne
  Serverdienst) hat den Filter tatsächlich geprüft.
- **Regel:** Für jede Grenze zu einem externen System (Datenbank, HTTP, Dateisystem, Zeit) mindestens
  ein Test gegen das echte System. Attrappen prüfen die eigene Ablauflogik — nie die Schnittstelle.
- Nützlich, wenn kein Server verfügbar ist: eingebettete Varianten (PGlite für PostgreSQL, SQLite
  in-memory, MSW für HTTP). Sie kosten eine Entwicklungsabhängigkeit und ersetzen die Attrappe an
  genau der Stelle, an der sie wertlos wäre.

**🔴 Grüne Tests an sicherheitskritischen Stellen gegenproben — Schutz abschalten, muss rot werden**
- Der Mandanten-Leckagetest war zuerst **falsch-positiv grün**: Die Kennung wurde per
  `set_config(…, true)` gesetzt, das gilt nur für die laufende Transaktion und war bei der nächsten
  Anweisung schon fort. Der Test lief also immer gegen eine leere Kennung und hätte auch bei völlig
  fehlender Zugriffssteuerung bestanden.
- Aufgefallen ist es nur, weil ein *anderer* Test derselben Gruppe fehlschlug. Danach habe ich die
  Zeilensicherheit versuchsweise abgeschaltet und geprüft, ob der Test rot wird — erst damit war er
  belegt.
- **Regel:** Bei jedem Test, der eine Schutzeigenschaft behauptet (Zugriffstrennung, Signaturprüfung,
  Rechteprüfung), einmal den Schutz entfernen und den Testlauf wiederholen. Bleibt er grün, prüft er
  nichts. Der Aufwand ist ein Wegwerf-Durchlauf, der Ertrag ist der Unterschied zwischen Nachweis und
  gutem Gefühl.
- Erkennungsmerkmal für falsch-positive Tests: Sie prüfen auf **Abwesenheit** („liefert keine Daten",
  „wirft nicht", „ist leer"). Abwesenheit stellt sich auch ein, wenn der Testaufbau kaputt ist.

**🟡 Die Umgebung ist eine Testvariable — nicht nur die Laufzeitversion**
- Ergänzung zur Node-18-gegen-24-Lektion aus Phase 5: Dort war die ABI der Unterschied. Hier war es
  die **Systemzeitzone**. `fromZonedTime` aus `date-fns-tz` liest ein übergebenes `Date` in der
  Systemzeitzone der Maschine, nicht in der angegebenen Zone — unter `Europe/Berlin` und `UTC`
  unauffällig, unter `America/New_York` fielen 8 von 11 Tests um.
- Der Fehler stammte aus einer früheren, für grün erklärten Codex-Runde und hätte im Betrieb den
  Versandzeitpunkt verschoben, je nachdem wie der Server gestellt ist.
- **Regel:** Bei allem, was Zeit, Zahl- oder Textformate berührt, die Suite unter mehreren
  Umgebungswerten laufen lassen, bevor „grün" gemeldet wird:
  ```bash
  for tz in Europe/Berlin UTC America/New_York Australia/Sydney; do TZ=$tz npm test || break; done
  ```
  Dasselbe Muster gilt für `LC_ALL` (Dezimaltrenner, Sortierung) und Zeitumstellungstage.
- Wenn eine solche Prüfung etwas findet, gehört sie als Skript in die Auslieferungsprüfung, nicht in
  den Bericht.

**🟡 „Testdateien unverändert" ist eine Messung, keine Annahme**
- Der Satz „ändere das Design, nicht den Test" wirkt nur, wenn jemand nachsieht. Nach jedem Zyklus:
  ```bash
  git status --short -- '*test*' '*__tests__*'   # muss leer sein
  git diff --stat HEAD -- <testverzeichnis>
  ```
- Das gilt für Codex-Runden **und** für selbst implementierte. Der eigene Griff zum Test ist
  verführerischer, weil man die Spezifikation selbst geschrieben hat und sie „nur präzisieren" will.
- Zulässig ist das Nachbessern von **Testinfrastruktur** (Hilfsfunktionen, Aufbau) — nicht von
  Erwartungen. Ein Beispiel aus dieser Session: `set_config(…, true)` → `false` im Testaufbau war
  richtig; die erwartete Zeilenzahl zu ändern wäre falsch gewesen. Die Grenze verläuft dort, wo die
  Behauptung des Tests beginnt.
