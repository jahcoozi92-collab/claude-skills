# MediFox RAG Skill – Wissensaufbereitung für Pflegesoftware

| name | description |
|------|-------------|
| medifox-rag | Spezialisiert auf MediFox Stationär Dokumentation. Formatiert Artikel für RAG-Optimierung und kennt die Struktur der Wissensdatenbank. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**

MediFox ist eine Software für Pflegeheime. Die Software hat eine riesige Wissensdatenbank mit Anleitungen wie "Wie trage ich Urlaub ein?" oder "Wie schließe ich die Mitarbeiterzeiterfassung ab?"

Dieser Skill hilft dabei:
1. Die Anleitungen aus der Wissensdatenbank zu holen
2. Sie so aufzubereiten, dass eine KI sie gut verstehen kann
3. Tags und Suchbegriffe hinzuzufügen

---

## MediFox Artikel-Struktur

### Standard-Format für RAG-optimierte Artikel

```markdown
# Titel des Artikels

**Quelle:** MediFox Stationär Wissensdatenbank
**ID:** 590767
**URL:** https://wissen.medifoxdan.de/pages/viewpage.action?pageId=590767

---

[Einleitungstext / Problembeschreibung]


**Lösung**

[Erklärung der Lösung]


## Schritt-für-Schritt Anleitung

- Gehen Sie hierfür bitte in den Reiter *Bereichsname*
- Klicken Sie auf *Schaltfläche*
- Wählen Sie *Option* aus
- Bestätigen Sie mit *OK*


**Zu beachten**

[Wichtige Hinweise, Warnungen]


## Verwandte Artikel

[Tags/Labels für Suche]

---
*Extrahiert am YYYY-MM-DD für RAG-Wissensbasis*
```

---

## Häufige MediFox-Bereiche

| Bereich | Typische Themen |
|---------|-----------------|
| **Personaleinsatzplanung (PEP)** | Dienstplan, Stundenkonto, MZE, Urlaub |
| **Mitarbeiterzeiterfassung (MZE)** | Sollstunden, Überstunden, Abschließen |
| **Verwaltung > Mitarbeiter** | Stammdaten, Regelarbeitszeit, Abwesenheiten |
| **Administration** | Benutzerverwaltung, Rollen/Rechte |
| **Dokumentation** | Pflegemappe, Dokumentation, SIS, Sturzdokumentation |
| **Organisation** | Jahresübersicht, Urlaubsanträge |

---

## Tag-Kategorien für FTS

### PEP (Personaleinsatzplanung)
```
pep, dienstplan, stundenkonto, mze, mitarbeiterzeiterfassung,
überstunden, saldo, startsaldo, abschließen
```

### Urlaub & Abwesenheiten
```
urlaub, urlaubsantrag, urlaubsverwaltung, krank, lohnfortzahlung,
abwesenheit, 13-wochen-regel
```

### Arbeitszeit
```
arbeitszeit, regelarbeitszeit, sollstunden, ist-arbeitszeit,
ausbezahlt, mehrarbeit, differenz, jahresarbeitszeit
```

### Administration
```
rollen, rechte, benutzerverwaltung, rechtepaket
```

---

## SQL für MediFox-Dokumente

### Dokument mit strukturiertem Content aktualisieren

```sql
UPDATE rag_chunks SET
  content = $c$# Startsaldo bearbeiten

**Quelle:** MediFox Stationär Wissensdatenbank
**ID:** 590767
**URL:** https://wissen.medifoxdan.de/pages/viewpage.action?pageId=590767

---

Sie möchten bei einem Mitarbeiter das Startsaldo, also die Mehr- oder Minusstunden eintragen.


## Schritt-für-Schritt Anleitung

1. Gehen Sie in den Reiter **Personaleinsatzplanung**
2. Klicken Sie auf **Stundenkonto**
3. Wählen Sie den **Mitarbeiter**
4. Klicken Sie auf **Startsaldo bearbeiten**
5. Tragen Sie die Mehr- oder Minusstunden ein
6. Bestätigen Sie mit **OK**


**Tags:** saldo, startsaldo, stundenkonto, pep$c$,
  fts = to_tsvector('german', 'startsaldo saldo stundenkonto pep mitarbeiter bearbeiten minusstunden mehrstunden personaleinsatzplanung')
WHERE id = 347453;
```

---

## Constraints – Was ich IMMER beachten muss

### Chat-Widget Architektur (KRITISCH)

**Der Medifox-Chat (`/webhook/medifox-chat`) ist NICHT das n8n Chat-Trigger Widget!**
- Es ist eine eigene HTML-Anwendung (3900+ Zeilen) im **Respond to Webhook** Node
- CSS/JS-Aenderungen muessen im `responseBody` dieses Nodes gemacht werden
- Der n8n Chat-Trigger (`customCss`) ist ein separates Widget und NICHT das, was User sehen
- Aktiver Workflow: `SJ47UX9mv8wh1Wwy` (Name: `RAG_Masterclass_Chat_hybrid`)

### Deployment: n8n Workflow-Updates

Aenderungen IMMER direkt per n8n API deployen, nicht als Dateien/Anleitung:
1. API-Key aus DB holen: `SELECT apiKey FROM user_api_keys WHERE label = 'claude_desktop_linux'`
2. GET `/api/v1/workflows/{id}` → Workflow lesen
3. Nodes patchen (im JSON)
4. PUT `/api/v1/workflows/{id}` mit `{name, nodes, connections, settings}` zurueckschreiben
5. **settings darf nur erlaubte Felder enthalten**: `executionOrder`, `callerPolicy` (sonst 400 Error)
6. Nach CLI-Import (`n8n import:workflow`): Workflow per API POST `/activate` reaktivieren
7. Neuere n8n-Versionen brauchen published versions (`workflow_published_version` Tabelle)

### Chat-HTML Rendering-Pipeline

```
formatMessage() → parseStructuredResponse()
  ├── formatAsCards() (bei 2+ Sektionen: summary, steps, notice, sources)
  │     ├── formatSimpleMessage() (fuer summary, notice, sources)
  │     └── formatSteps() (fuer steps — eigene OL/Blockquote/HR Logik)
  └── formatSimpleMessage() (Fallback bei einfachen Antworten)
```

**KRITISCH: Reihenfolge in formatSimpleMessage:**
1. Backtick-Code-Spans ZUERST als Platzhalter schuetzen (`%%CODE0%%`)
2. DANN `formatClickpaths()` ausfuehren (greift sonst `>` in Code-Blocks auf)
3. DANN Platzhalter zu `<code>` Tags restaurieren
4. Dann rest: HR, Blockquotes, Bold/Italic, Headers, Listen, Paragraphs

### Antwortqualitaet: Faktentreue vor Kreativitaet

- KI darf NUR Inhalte nennen, die sie aus der Wissensbasis abgerufen hat
- Kein Extrapolieren, kein Allgemeinwissen ueber Pflegesoftware einfliessen lassen
- Konkrete Dokumenttitel nennen statt generische Kategorielisten
- NIEMALS die Frage des Nutzers paraphrasieren ("Sie fragen...", "Sie moechten wissen...")
- Direkt mit der Antwort starten

### Embedding-Pipeline: Dokumente in rag_chunks einfuegen

1. Dokument in Chunks splitten (nach ## Sektionen, max ~2000 chars)
2. Embeddings generieren: **text-embedding-3-large** (3072 dim) — NICHT text-embedding-3-small (1536)!
3. Einfuegen via Supabase REST API: POST `/rest/v1/rag_chunks` mit `{content, metadata, embedding}`
4. Trigger `sync_rag_chunks_embedding_half` konvertiert automatisch zu halfvec
5. FTS-Spalte ist auto-generated (kein manuelles UPDATE moeglich)
6. OpenAI-Key: aus n8n Credentials entschluesseln (EVP_BytesToKey, AES-256-CBC, Salted__ prefix)

**Metadata-Felder:**
```json
{"source": "screenshot_documentation", "file_name": "...", "section": "...", "priority": "critical", "quality": "high"}
```

### MD Stationaer: 8 Ribbon-Tabs (NICHT 7!)

Die Hauptnavigation hat 8 Tabs. "Pflege/Betreuung" ist KEIN Tab, sondern eine Wissensdatenbank-Kategorie:
1. Datei, 2. Organisation, 3. Verwaltung, 4. Abrechnung, 5. Dokumentation, 6. Personaleinsatzpl., 7. Controlling, 8. Administration (Sonderlayout)

### Korrekte MediFox Menuepfade (NIEMALS abweichen!)

| Funktion | Korrekter Pfad | FALSCH |
|----------|---------------|--------|
| Dienstplan | `Personaleinsatzplanung > Dienstplan` | ~~Planung > Dienstplanung~~ |
| Stundenkonto | `Personaleinsatzplanung > Stundenkonto` | ~~Verwaltung > Stundenkonto~~ |
| Urlaub | `Personaleinsatzplanung > Urlaubsverwaltung` | ~~Organisation > Urlaub~~ |
| Pflegedoku | `Dokumentation > Dokumentation` | ~~Pflege/Betreuung > Dokumentation~~ |
| Abrechnung | `Abrechnung > Abrechnung der Aufträge` | ~~Verwaltung > Abrechnung~~ |
| Bewohner | `Verwaltung > Bewohner` | |
| Mitarbeiter | `Verwaltung > Mitarbeiter` | |
| Benutzerverwaltung | `Administration > Benutzerverwaltung` | |
| Dienstarten | `Administration > Personaleinsatzplanung > Dienstarten` | |
| Kataloge | `Administration > Kataloge > Verwaltung/Pflege` | |

Menuepfade NIEMALS erfinden — nur aus Wissensbasis oder dieser Tabelle verwenden.

### Bei MediFox-Artikeln formatieren

1. **Titel** muss als H1 (`#`) beginnen
2. **Metadaten** (Quelle, ID, URL) immer mit `**Bold:**` formatieren
3. **Schritte** als nummerierte Liste oder Aufzählung
4. **Menüpfade** mit `*Kursiv*` oder `**Fett**` hervorheben
5. **Tags** als FTS-Keywords extrahieren (Deutsch!)

### Bei FTS-Vektoren

```sql
-- Deutsche Sprache für Stemming!
to_tsvector('german', 'stundenkonto mitarbeiter überstunden')

-- NICHT:
to_tsvector('english', ...)  -- Falsch!
to_tsvector(...)             -- Default ist English!
```

### URL-Muster

```
NextCloud-Quelle: https://nextcloud.forensikzentrum.com/.../RAG_Masterclass/[id].md
MediFox-Original: https://wissen.medifoxdan.de/pages/viewpage.action?pageId=[id]
```

---

## Gelernte Lektionen

### 2026-03-25 - Prompt-Architektur + OpenRouter LLM-Wechsel

**Prompt radikal geschaerft (VERBOTEN/PFLICHT statt hoeflicher Bitten):**
- LLMs folgen harten Negationen besser als langen Erklaerungen
- Struktur: VERBOTEN (5 Regeln) → PFLICHT (3 Regeln) → Format (5 Zeilen)
- Konkrete Negativbeispiele: "Kein 'Sie fragen...', kein 'Ueberblick: Was sich in...'"
- Ergebnis: KI startet direkt mit Inhalt, keine Frage-Paraphrase mehr

**LLM-Wechsel: gpt-4o-mini → gpt-5.4-nano (via OpenRouter):**
- Modell-ID: `openai/gpt-5.4-nano`
- Kosten: $0.20 input / $1.25 output pro 1M tokens (kaum teurer als gpt-4o-mini)
- Massiv bessere Prompt-Treue, Faktentreue und Instruktionsbefolgung
- In n8n: OpenAI Chat Model Node mit Custom Base URL `https://openrouter.ai/api/v1`

**Prompt-Extraktion Bug gefixt:**
- `---BEGIN PROMPT---` ohne Newline-Match griff den Anweisungstext statt den Prompt
- Fix: `c.find('---BEGIN PROMPT---\n') + len('---BEGIN PROMPT---\n')`

---

### 2026-03-25 - Faktentreue + Embedding-Pipeline + Tab-Korrektur

**Faktentreue als oberste Regel:**
- KI halluzinierte Inhalte wie "DTA-Verfahren", "Offline-Modus", "Reportvorlagen" ohne Beleg
- Fix: Prompt-Regel "NUR belegte Aussagen aus abgerufenen Dokumenten"
- Fix: Schlechtes Beispiel (halluziniert) vs. gutes Beispiel (nur belegte Fakten) im Prompt
- Fix: "Frage nicht wiederholen" — kein "Sie fragen..." am Anfang

**Embedding-Pipeline aufgebaut:**
- 29 Chunks aus Screenshot-Dokumentation (md_stationaer_level2_vollstaendig.md) embedded
- FEHLER: Erst text-embedding-3-small (1536 dim) → DB erwartet 3072 dim → Fix: text-embedding-3-large
- OpenAI-Key: Aus n8n-Credentials entschluesselt (EVP_BytesToKey, AES-256-CBC)
- Supabase REST API: POST /rest/v1/rag_chunks mit apikey + Authorization Header
- Source: `screenshot_documentation`, Priority: `critical`, Quality: `high`

**Tab-Struktur korrigiert (Screenshot-Beweis):**
- 8 Ribbon-Tabs: Datei, Organisation, Verwaltung, Abrechnung, Dokumentation, Personaleinsatzpl., Controlling, Administration
- "Pflege/Betreuung" ist KEIN Tab der Hauptnavigation (Wissensdatenbank-Kategorie)
- Administration hat Sonderlayout (kein Ribbon, Navigationsbaum)
- Bewohnerakte hat eigene 8 Tabs: Stammdaten, Planung, Verlauf, Arzt, Risiken, Vitalwerte, Wunde, Ernaehrung

---

### 2026-03-25 - High-End Chat-Widget Redesign + Menuepfad-Korrektur

**System-Prompt v2.0 deployed:**
- Vollstaendige MediFox Menuestruktur als Tabelle im Prompt (7 Haupt-Reiter, 20+ Sub-Pfade)
- Formatierungsregeln: `##` Ueberschriften, `code`-Format fuer Menuepfade, Blockquote-Hinweise
- maxTokens: 800 → 1500 (damit Formatierung nicht abgeschnitten wird)
- Prompt-Datei: `agents/medifox-rag-n8n/prompts/supabase_agent_prompt.md` (v2.0)

**Chat-Widget HTML-Fixes (im Respond to Webhook Node):**
- `formatSimpleMessage()`: Code-Spans vor Klickpfad-Detektor schuetzen (Platzhalter-Pattern)
- `formatSteps()`: Blockquote, HR, Heading, Bullet-Support hinzugefuegt
- `parseStructuredResponse()`: Regex fuer "Vorgehensweise" statt nur "Vorgehen" (verhindert "sweise" Fragment)
- CSS: `--text-base` 0.875rem → 1rem, `.message-bubble p` margin 10px → 4px, `.answer-card.steps li` margin space-3 → space-1
- Neue CSS-Klassen: `.msg-quote` (Blockquote), `.msg-hr` (HR), `ol.msg-list` (nummerierte Listen)

**n8n API Deployment-Workflow entdeckt:**
- n8n API braucht API-Key (aus `user_api_keys` Tabelle, label: `claude_desktop_linux`)
- PUT settings darf nur `executionOrder` + `callerPolicy` enthalten (sonst 400)
- CLI-Import deaktiviert Workflow → muss per API POST `/activate` reaktiviert werden
- Published versions noetig: `workflow_published_version` Tabelle verlinkt auf `workflow_history`

**Falsche Menuepfade korrigiert (User-Korrektur):**
- `Planung > Dienstplanung` → `Personaleinsatzplanung > Dienstplan`
- `Dokumentation > Pflegedokumentation` → `Pflege/Betreuung > Dokumentation > Dokumentation`
- `Abrechnung > Abrechnung` → `Verwaltung > Abrechnung`

---

### 2026-03-24 - Komplette DB-Neuaufbau + Deep Audit

**Tabellen-Wechsel: `documents` → `rag_chunks`**
- Alte `documents`-Tabelle enthielt nur Metadaten-Muell (5 Rows pro Datei: Dateiname, URL, Timestamp, Extension, Pfad)
- Neue `rag_chunks`-Tabelle: saubere, deduplizierte Chunks mit echtem Content
- Funktion: `match_qm_chunks(vector(3072), int, jsonb)` - NIEMALS zwei Overloads (PostgREST kann nicht disambiguieren)
- Trigger: `trg_rag_chunks_sync_half` konvertiert `embedding → embedding_half` automatisch

**5 Quellen, dedupliziert:**

| Quelle | Chunks | Artikel |
|--------|--------|---------|
| Confluence Wiki (wissen.medifoxdan.de) | 725 | 228 |
| NextCloud QM-Handbuch | 245 | 109 |
| Strukturierte Klickpfade (click_paths → text) | 68 | 66 |
| Support-FAQs (manuell erstellt) | 8 | 8 |
| **Gesamt** | **1046** | **406** |

**Deduplizierung:**
- Content-Hash: SHA256 der ersten 500 normalisierten Zeichen
- Cross-Source: Wiki-Version behalten, NextCloud-Duplikate entfernt
- _COMBINED_ALL_ARTICLES (375 Chunks) + LightRAG-Batch (597 Chunks) = reine Duplikate → entfernt

**Confluence 🎞-Seiten:**
- 26 Seiten mit 🎞 im Titel sind reine Video-Embeds (0 Zeichen Textinhalt)
- Braeuchten Transkription fuer RAG - existiert nicht in MSKB

**click_paths → rag_chunks Konvertierung:**
- 68 strukturierte Klickpfade per SQL INSERT konvertiert
- Format: `# Klickpfad: Titel\n**Menüpfad:**...\n**Schritte:**...`
- Massiv bessere Antwortqualitaet fuer Navigationsfragen

**Support-FAQ-Dokumente (8 Stueck):**
- Passwort vergessen, Druckprobleme, DTA-Fehler, Berechtigungen
- Bewohnerdaten aendern, Performance, Backup, Pflegegrad-Wechsel
- Format: Problem → Loesung → Schritte → Hinweis

**DB-Status (2026-03-24): 1046 Chunks, 406 Artikel, 44 MB (8.8% vom Limit), 100% Embeddings**

---

### 2026-02-08 - Level 2 Deep-Audit: Komplett-Inventar Wiki

**247 Wiki-Seiten in der DB (von 301 im Wiki gesamt):**
- 194 neue Seiten via Confluence REST API gescraped und inseriert
- 53 bestehende Wiki-Docs (7 mit erneuertem Content aus Level-1)
- 54 Wiki-Seiten bewusst ausgeschlossen (Video-Refs, Update-Logs, Kategorieseiten)
- 88 manual_enrichment Docs als `unverified` markiert (KI-generiert)

**Confluence API für Wiki-Scraping:**
```
# Alle Seiten im Space MSKB:
GET https://wissen.medifoxdan.de/rest/api/content?spaceKey=MSKB&limit=500

# Einzelne Seite mit HTML-Body:
GET https://wissen.medifoxdan.de/rest/api/content/{PAGE_ID}?expand=body.view

# Kein Auth nötig (öffentliches Wiki)
```

**HTML → Markdown Konvertierung:**
- Confluence-Macros entfernen (ac:structured-macro, ri:attachment)
- HTML-Tags: h1-h6 → #, li → -, b/strong → **, i/em → *
- Tabellen: Confluence-Tabellen → Pipe-Tabellen (vereinfacht)
- Standard-Header: `# Titel\n\n**Quelle:** MediFox Stationär Wissensdatenbank\n**URL:** ...`

**DB-Status (2026-02-08): 1369 Docs total, 100% Embeddings** (VOR Neuaufbau)

---

### 2026-01-26 - Initiale Dokumentation

**503 URL-only Dokumente entdeckt:**
- Viele Dokumente hatten nur die URL gespeichert, nicht den Inhalt
- Batch-Download von NextCloud mit curl
- Strukturierte Neuformatierung für optimale RAG-Qualität

**Typische Artikeltypen:**
- Schritt-für-Schritt Anleitungen (häufigstes Format)
- Problemlösung ("Warum passiert X?" → "Lösung")
- Konfiguration von Berechtigungen
- Spalten/Ansichten anpassen

**100 Dokumente erfolgreich re-indexiert, 403 ausstehend.**

---

### 2026-04-24/25 — Extrapolations-Verbot + Confluence-API + Boost-Matrix

**Extrapolations-Verbot (KRITISCH):**
- NIE aus ähnlichen MediFox-Themen extrapolieren — auch wenn Pfade analog scheinen
- Konkrete Fehlschluss-Beispiele: **Impfung ≠ Infektion**, Mitarbeiter-Impfung ≠ Bewohner-Impfung, Stationäre Dauerpflege ≠ Kurzzeitpflege, MD Stationär ≠ MediFox DAN
- Wenn kein dediziertes Dokument vorliegt: **abstain** statt schlussfolgern
- Real-Beispiel: Impfungen liegen NICHT unter Administration → Kataloge (weder Vorgabewerte noch Verwaltung) — direkte MediFox-Support-Auskunft 2026-04-27: Pfad ist **Dokumentation → Dokumentation → Einstellungen (Zahnrad) → Impfungen / Impfstoffe → Neu**. Auch der Update 8.2-PDF-Hinweis auf „Verwaltung → Impfungen" war für die aktuelle UI nicht (mehr) zutreffend.

**Confluence-REST-API für schnelle Wiki-Recherche (kein Auth):**
```bash
# Volltext-Suche im MSKB-Space
curl -sS "https://wissen.medifoxdan.de/rest/api/content/search?cql=space=MSKB+AND+text~%22Suchbegriff%22&limit=20"

# Einzelseite mit HTML-Body holen
curl -sS "https://wissen.medifoxdan.de/rest/api/content/{PAGE_ID}?expand=body.view"

# Label-basierte Suche (Tags wie 'admin', 'kataloge', 'rechte')
curl -sS "https://wissen.medifoxdan.de/label/MSKB/{LABEL}"
```

**Update-PDFs als Migrations-Quelle:**
- Wenn ein Pfad in der aktuellen MediFox-Version anders liegt als im alten Wiki: **Update-PDFs durchsuchen**
- Format: `https://wissen.medifoxdan.de/download/attachments/3375911/Update-Information_YYYY_stationaer_X.Y.pdf`
- Versions-Migrationen werden dort namentlich beschrieben
- Mit `pypdf` Text extrahieren, dann nach Schlüsselbegriff grepen

**source_type-Boost-Matrix (in hybrid_search_v3, Stand 2026-04-25):**

| source_type | Boost |
|-------------|-------|
| `konzeptstandard` (hausintern Arche Noah) | **1.35** |
| `faq` | 1.30 |
| `confluence_wiki` | 1.25 |
| `update_info_10x` | 1.22 |
| `cached_wiki_page` | 1.20 |
| `qm_handbuch_md` | 1.20 |
| `wiki_article` | 1.18 |
| `structured_click_path` | 1.15 |
| `expertenstandard` (DNQP) | 1.15 |
| sonst | 1.0 |

Zusätzlich: **+5% wenn `verified=true`**, **−10% wenn `metadata.needs_review='true'`**.

**Konzept- vs. Expertenstandard:**
- Einrichtung Arche Noah hat eigene Konzeptstandards (8 Themen: Dekubitus, Sturz, Schmerz, Mobilität, Hautintegrität, Mundgesundheit, Demenz-Beziehungsgestaltung, Wunden) — gehen IMMER vor DNQP-Expertenstandards
- Zitier-Regel: „**unser hausinterner Konzeptstandard [Thema]**" / „**DNQP-Expertenstandard [Thema, Jahr]**"
- Konzeptstandards in „wir/unsere"-Form formulieren — nie als neutrale Empfehlung
- Themen ohne Konzeptstandard (Kontinenz, Ernährung, Entlassung): kurz erwähnen, dann DNQP-Empfehlung

**Seed-Skript-Pattern (idempotent, RLS-bypass):**
```python
# Hash-Präfix pro Lauf (z.B. 'lg2604-', 'std2604-', 'imp2604v2-')
# 1) SECURITY DEFINER RPC anlegen (umgeht RLS)
# 2) Pro Artikel: hash via md5(title|chunk_idx)[:12]
# 3) Existenz-Check vor Insert (Idempotenz)
# 4) OpenAI text-embedding-3-large (3072d)
# 5) RPC-Aufruf mit content+metadata+vec
# 6) Nach Lauf: DROP FUNCTION
```

**MediFox-Strukturwissen 2026 (Korrekturen):**

| Bereich | Quelle | Pfad |
|---------|--------|------|
| Bewohner-Impfungen anlegen | MediFox-Support 2026-04-27 | Dokumentation → Dokumentation → **Einstellungen (Zahnrad)** → Impfungen → Neu |
| Impfstoffe anlegen (zwingend parallel!) | MediFox-Support 2026-04-27 | Dokumentation → Dokumentation → **Einstellungen (Zahnrad)** → Impfstoffe → Neu |
| Infektionen | unverändert | Administration → Kataloge → Vorgabewerte → Pflege → Infektion |
| Bewohner-Impfung einsehen | click_paths ID 60 | Dokumentation → Dokumentation → [Bewohner] → Arzt → Medizinische Daten |
| ⚠️ NICHT mehr gültig | überholt | ~~Administration → Kataloge → Verwaltung → Impfungen~~ (Update-PDF 8.2-Annahme war falsch / inzwischen verschoben) |

**Erkenntnis Wiki-Struktur:**
- MediFox-Wiki zeigt für viele Admin-Themen NUR 1-2 Treffer + PDFs
- Wiki ist primär Troubleshooting-FAQ, kein systematisches Handbuch
- → bei Admin/Konfig-Fragen IMMER Update-PDFs als zweite Quelle prüfen

---

### 2026-04-27 — Quellen-Hierarchie + Embedding-Dim-Unterschiede + Korrektur-Workflow

**Quellen-Hierarchie für MediFox-Pfade (KRITISCH):**

1. **Direkte MediFox-Support-Auskunft** (höchste Priorität) — `trust_level=3`, `verified_by='medifox_support'`
2. Aktuelle Confluence-Wiki-Seite mit Screenshot
3. Update-Information PDF (kann durch spätere UI-Änderungen überholt sein!)
4. Eigene Annahme aus analogem Pfad (FORBIDDEN ohne Quelle — siehe Extrapolations-Verbot)

**Wichtig:** Auch Update-PDFs altern. Beispiel-Fall: Update 8.2 (2022) PDF beschrieb Migration nach „Verwaltung → Impfungen" — 2026-04-27 hat MediFox-Support den Pfad als „Dokumentation → Dokumentation → Einstellungen (Zahnrad) → Impfungen" bestätigt. Bei Konflikt: Support-Auskunft gewinnt; alte Quelle in alten Chunks explizit als „NICHT korrekt" markieren.

**Embedding-Dimensionen je Tabelle (Stolperstein):**

| Tabelle | Spalte | Dimensionen | Modell |
|---------|--------|-------------|--------|
| `rag_chunks` | `embedding` | **3072** | `text-embedding-3-large` (`dimensions=3072`) |
| `rag_chunks` | `embedding_half` | 3072 (halfvec) | automatisch via Trigger `trg_sync_embedding_half` |
| `click_paths` | `embedding` | **1536** | `text-embedding-3-small` (default) |

Falsches Modell → `22000: expected 1536 dimensions, not 3072` (oder umgekehrt). Vor PATCH die `data_type` der Spalte verifizieren.

**Korrektur-Workflow (5-Schritt-Pattern bei UI-Pfad-Korrekturen):**

```
1. rag_chunks UPDATE: content + embedding=NULL + embedding_half=NULL + verified=true
2. workflows/embed_new_chunks.py (mit OPENAI_API_KEY + SUPABASE_SERVICE_KEY)
   → embedding_half + fts werden automatisch via Trigger gefüllt
3. click_paths INSERT mit verified=true, verified_by='medifox_support', trust_level=3
   → search_text + embedding (1536d) manuell mit text-embedding-3-small generieren
4. Memory-Eintrag (feedback_*.md) + alte widersprüchliche Memory aktualisieren
5. MEMORY.md Index pflegen
```

**Env-Quellen für Embedding-Skripte (NAS):**
- `OPENAI_API_KEY` aus `/volume1/docker/open-webui/backups/complete-update-*/`.env`
- `SUPABASE_SERVICE_ROLE_KEY` aus `/volume1/docker/lightrag/.env.lightrag`

**Anti-Imitations-Pattern:**
- Korrigierte Chunks sollen den falschen Pfad explizit als „NICHT korrekt" benennen, nicht stillschweigend ersetzen
- Sonst können bei Hybrid-Search alte + neue Versionen gleichzeitig gezogen werden → LLM mischt → falsche Antwort
- Format: „Der Pfad X existiert in dieser Form NICHT (mehr) — korrekt ist: Y"

---

### 2026-04-28 — Plattform-Mapping Mobile Apps + Schulungsmandant + Schema-Detail

**MediFox-Plattform-Mapping (Mobile, KRITISCH):**

| Produkt | Plattform | Zweck | Paket-/Identifier |
|---------|-----------|-------|-------------------|
| **MD CarePad** | iPad-only (iOS) | Pflegedokumentation am Bewohner | App Store, MEDIFOX DAN GmbH |
| **MD Stationär** (Android-App) | Android ≥ 9.0 | Pflegedokumentation am Bewohner | Google Play `de.medifoxdan.stationaer.playstore` |
| **MD CareMobile** | Android | Mobile Zeit-/Leistungserfassung (primär ambulant) | Google Play `medifox.caremobile.android` |
| **MediFox Connect** | Browser (alle OS) | Mitarbeiter-/Familien-/Arzt-/Apothekenportal | Webanwendung, keine App |

- **Korrektur frühere Annahme:** "CarePad = stationäre App generell" ist falsch — CarePad ist explizit iPad-Marke. Für stationäre Pflege auf Android gibt es eine separate **"MD Stationär" App** im Play Store von MEDIFOX DAN GmbH.
- **Huawei-Sonderfall:** Kein Google Play → APK-Direktdownload nötig. Samsung/Pixel/etc.: Play Store Standard.
- **Kompatibilität:** MEDIFOX DAN führt offizielle Liste auf <https://www.medifoxdan.de/service/kompatible-geraete/>. Samsung Galaxy S25 Ultra (Android 15) erfüllt Anforderung deutlich, ist aber nicht namentlich gelistet — bei Anschaffung Vertrieb kontaktieren: +49 5121 28291-9206.
- **Connect-Setup:** Läuft als separater Dienst auf IIS-Server in der DMZ, TCP 9710 + HTTP(S)-Port zum MediFox-Server, SSL-Zertifikat zwingend. Zugriff für Externe via Login + optional QR-Code-PDF.

**Schulungsmandant = MediFox-Begriff für Testsystem (KRITISCH):**

- **Synonyme:** Testsystem, Sandbox, Spiegel-System, Trainings-Mandant, Schulungs-Datenbank.
- **Voraussetzung:** Kostenpflichtige Lizenz-Erweiterung — über Vertriebsbeauftragten von MEDIFOX DAN buchen.
- **Setup:** In der MediFox Versionsverwaltung selben Aktivierungsschlüssel wie Hauptsystem nutzen + Häkchen **"Testsystem"** setzen → leere zweite Datenbank wird angelegt → SQL-Backup vom Echtsystem als Restore einspielen → identische Spiegelung.
- **Funktionsumfang:** Voll funktionsfähig (FiBu-/LoBu-Exporte, Geräte-Sync, Ausdrucke). Alle Ausdrucke automatisch mit Wasserzeichen **"Muster"**.
- **Update-Strategie Test→Echt:** Auto-Updates **müssen deaktiviert werden** (Versionsverwaltung → Konfiguration → Reiter Updates → Häkchen "Autom. Updates" entfernen), sonst rollen Updates parallel auf beide Mandanten. 4-Phasen-Workflow: Vorbereitung (Echtsystem-Backup → Schulungsmandant-Restore) → Test → Echt → Nachbereitung.
- **Auto-Updates funktionieren nur** bei **zentraler** Serverinstallation. Bei dezentral / Terminal Server gar nicht verfügbar — alles strikt manuell.

**rag_chunks-Schema-Detail (Versionsfeld):**

- Bei `metadata.source_type='update_info_10x'`-Chunks (Crawler `crawl_medifox_updates_10x.py`) liegt die Versionsnummer in `metadata.product_version` — **NICHT** in `metadata.version`.
- Beispiel: `{"source_type": "update_info_10x", "product_version": "10.22.0", "file_name": "Updateinfo 10.22.0.pdf", ...}`
- Wenn nach Versionen gefiltert werden muss: `metadata->>'product_version'`, nicht `metadata->>'version'`.

**Bewährtes Seed-Pattern (bestätigt funktional):**

- `metadata.content_hash` mit kurzem Datums-Prefix pro Lauf (`andr2604-`, `upd2604-`, `lg2604-`, …) → idempotent gegen Wiederholung.
- `metadata.topic`-Feld zur späteren thematischen Filterung (z. B. `android-mobile`, `update-workflow`).
- Defaults: `source_type=cached_wiki_page`, `trust_level=2`, `product_scope=stationaer`, `lifecycle=active`, `category=anleitung`.
- Hash-Funktion: `md5(f"{title}|{chunk_idx}".encode())[:12]` mit Prefix.
- Idempotenz-Check: `GET /rest/v1/rag_chunks?metadata->>content_hash=eq.{hash}&limit=1`.
- Insert ohne SECURITY DEFINER RPC möglich, wenn Service-Role-Key verwendet wird (umgeht RLS direkt).

**FTS-Validation nach Insert:**
```sql
SELECT id, ts_rank(fts, query) AS rank
FROM rag_chunks, plainto_tsquery('german', 'erwartete suchbegriffe') query
WHERE fts @@ query
ORDER BY rank DESC LIMIT 5;
```
Top-1 sollte die neu eingefügte ID sein, Rang typisch > 0.95.

---

### 2026-04-30 — Indexieren reicht nicht: System-Prompt-Patch ist PFLICHT + RPC-Realität

**Diana-Bug "Dazu habe ich keine Information":**
- Trotz korrekt indexierter MD-Orbit-Chunks (IDs 3844-3852) lieferte der Live-Chat Abstain mit `grounding_score=0.4` (in `answer_traces` belegt).
- Ursache: System-Prompt v5 enthält die Regel *"Bei Fragen zu MediFox ambulant, MediFox DAN Tagespflege oder anderen **Produktvarianten**: Weise darauf hin, dass nur MediFox stationär abgedeckt ist"*.
- Das LLM klassifizierte `MD Orbit` und `MD CareMobile` als „andere Produktvariante" → Abstain ausgelöst, OBWOHL Treffer da waren.
- Gleicher Bug schlug bei MD CareMobile zu — derselbe System-Prompt-Mechanismus.

**Pflicht-Pipeline nach JEDER Indexierung eines neuen Themen-/Modul-/Produktbereichs:**

1. **Tool-Description** des `Supabase - Vector Store_Abruf`-Nodes erweitern um den neuen Bereich (z.B. „… deckt auch MD Orbit, MD CareMobile, MediFox Connect, MD CarePad, Update-Workflows ab").
2. **System-Prompt** des `Supabase KI-Agent`-Nodes erweitern:
   - Im Themenbereich-Block (vor `## Abstain-Regeln`) den Bereich mit Stichworten und Partner-/Funktionsliste eintragen.
   - In der Abstain-Regel den Bereich aus „andere Produktvariante" explizit ausnehmen: *„MD Orbit, MediFox Connect, MD CarePad, MD CareMobile sind Teil der Wissensbasis und sollen vollständig beantwortet werden. NICHT als andere Produktvariante abweisen."*
3. **Workflow-Deploy** (verifiziert funktional 2026-04-30):
   ```
   GET  /api/v1/workflows/{id}                         # Internal API!
   → Python: in-place patch der nodes
   → Minimal-Payload: {name, nodes, connections, settings}
     settings nur mit {executionOrder, timezone, callerPolicy}
   POST /api/v1/workflows/{id}/deactivate
   PUT  /api/v1/workflows/{id}                         # name-Feld zwingend
   POST /api/v1/workflows/{id}/activate
   docker restart n8n-n8n-1                            # Webhook-Cache leeren
   ```
4. **Live-Verifikation** über `answer_traces`:
   ```sql
   SELECT id, query, abstain_triggered, grounding_score, LEFT(answer,200)
   FROM answer_traces WHERE query ILIKE '%neues_thema%' ORDER BY created_at DESC LIMIT 5;
   ```
   Gut: `abstain_triggered=false`, `grounding_score > 0.7`. Schlecht: `0.4` und Abstain-Template im answer.

**Workflow-RPC ist `match_qm_chunks`, NICHT `hybrid_search_v3` (KRITISCH):**

- Der Live-Workflow nutzt im `Supabase - Vector Store_Abruf` (LangChain Node) `queryName: match_qm_chunks` mit `topK: 12` und `useReranker: true`.
- `match_qm_chunks` ist **pure Cosine-Ähnlichkeit auf `embedding_half`** — KEINE source_type-Boosts, KEINE FTS-Komponente.
  ```
  SELECT id, content, metadata, (1 - (embedding_half <=> query)) AS similarity
  FROM rag_chunks WHERE embedding_half IS NOT NULL AND content IS NOT NULL AND length(content) > 20
  ORDER BY embedding_half <=> query LIMIT match_count;
  ```
- `hybrid_search_v3` (Edge Function `n8n-hybrid`) macht RRF + Boosts (FAQ 1.30, Wiki 1.25, …) — wird im Live-Workflow NICHT aufgerufen!
- Konsequenz: **Tests via `n8n-hybrid` Edge Function sind NICHT repräsentativ** für die Live-Antwort. Echte Test-Pfade:
  1. **SQL-Test mit Self-Embedding:** `WITH q AS (SELECT embedding FROM rag_chunks WHERE id = <neuer_chunk>) SELECT id, similarity FROM match_qm_chunks((SELECT embedding FROM q), 10, '{}')` — Top-1 muss der neue Chunk sein, danach Cluster verwandter Chunks.
  2. **Live-Test im Chat** + 30 Sek Wartezeit + `answer_traces` prüfen.

**Reranker (`useReranker: true`) als Filter (Verdächtiger #2):**

- Steht im `Supabase - Vector Store_Abruf`-Node aktiviert.
- Reranker ordnet die `topK` Treffer nach LLM-basierter Relevanz neu — kann bei Themen, die das Reranker-Modell nicht kennt, Treffer despriorisieren.
- Wenn nach System-Prompt-Patch der Live-Chat IMMER NOCH nicht antwortet: testweise `useReranker: false` setzen.

**`click_paths.product` Wert-Schema (erweitert 2026-04-30):**

| Wert | Verhalten | Anwendung |
|------|-----------|-----------|
| `'stationaer'` | matcht Default-Filter `'stationaer'` | MD Stationär-spezifische Pfade |
| `'ambulant'` | matcht nur `product_filter='ambulant'` | MD Ambulant-spezifische Pfade |
| `'alle'` | matcht **immer** (jeder Filter) | Cross-Product-Themen (CareMobile in Mischbetrieb, Ökosystem) |
| `'cross_product'` | wie `'alle'` | Synonym, gleiche Wirkung |
| `NULL` | matcht nur, wenn `product_filter IS NULL` | sollte vermieden werden |

`search_click_paths`-Funktion (Stand 2026-04-30):
```sql
WHERE cp.fts @@ plainto_tsquery('german', query_text)
  AND (
    product_filter IS NULL
    OR cp.product = product_filter
    OR cp.product = 'alle'
    OR cp.product = 'cross_product'
  )
  AND COALESCE(cp.trust_level, 2) >= 2
```

Bestehender Datenbestand-Bug (Stand 2026-04-30): **19 Klickpfade** haben `product='MediFox stationär'` (mit Leerzeichen + Umlaut) — werden vom Default-Filter `'stationaer'` NIE gefunden. One-Time-Migration empfohlen:
```sql
UPDATE click_paths SET product = 'stationaer' WHERE product = 'MediFox stationär';
```

**Edge Function `embed-rag-chunks` (deployed 2026-04-30, slug `embed-rag-chunks`, verify_jwt=false):**

Backfill-Funktion für `rag_chunks.embedding` ohne lokalen `OPENAI_API_KEY` — nutzt den Key aus den Supabase-Function-Secrets.
- POST `{ids:[3844, 3845, ...]}` → gezielter Backfill der angegebenen IDs.
- POST `{batch_size:20}` (oder leer) → nimmt die nächsten N Rows mit `embedding IS NULL`.
- Trigger `trg_rag_chunks_sync_half` füllt anschließend `embedding_half`; `fts` ist Generated Column.
- Nutzbar als Alternative zu `workflows/embed_new_chunks.py`, wenn die `.env`-Datei nicht zugänglich ist.

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│              MEDIFOX RAG QUICK REFERENCE               │
├────────────────────────────────────────────────────────┤
│ Format:     Markdown mit H1, Metadaten, Schritte       │
│ FTS:        to_tsvector('german', 'keywords')          │
│ Tags:       pep, mze, urlaub, stundenkonto, etc.       │
│ Quelle:     wissen.medifoxdan.de                       │
│ Storage:    NextCloud → Supabase rag_chunks table      │
├────────────────────────────────────────────────────────┤
│ Total Docs: 1046 (725 Wiki, 245 NC, 68 KP, 8 FAQ)     │
│ Sprache:    Deutsch (IMMER 'german' für tsvector!)     │
└────────────────────────────────────────────────────────┘
```
