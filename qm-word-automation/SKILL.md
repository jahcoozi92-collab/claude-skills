# QM-Word-Automation Skill – Word-Dokumentenautomatisierung für QM-Handbuch

| name | description |
|------|-------------|
| qm-word-automation | Skill für die Automatisierung von QM-Handbuch Word-Dokumenten via pywin32 COM. Läuft ausschließlich auf Windows (WS44). Patterns für Footer-Updates, Migrationen, Dokumentenschutz. |

## Was ist dieser Skill?

Stell dir vor, du hast hunderte Word-Dokumente in einem Ordner, und in jedem musst du den gleichen Text ändern — den Namen im Fußbereich, eine Versionsnummer hochzählen, oder ein Wort überall ersetzen. Von Hand dauert das Wochen. Dieser Skill weiß, wie man das automatisch macht, welche Fallen es gibt (geschützte Dokumente, alte Formate, Netzlaufwerke), und wie man dabei nichts kaputt macht.

---

## Trigger

Aktiviere diesen Skill bei:
- QM-Handbuch, QM-Dokumente, Qualitätsmanagement
- Word-Dokument-Automatisierung, pywin32, COM-Automation
- Footer aktualisieren, Versionsnummern, römische Ziffern
- "DAN" → "Medifox stationär" Migration
- Dokument-Schutz aufheben/wiederherstellen
- `.doc` / `.docx` Massenbearbeitung

---

## Umgebung

| Eigenschaft | Wert |
|-------------|------|
| **Maschine** | WS44 (Windows 11 Pro) |
| **Python** | 3.13.7 |
| **pywin32** | 311 |
| **python-docx** | 1.2.0 |
| **openpyxl** | 3.1.5 |
| **python-pptx** | 1.0.2 |
| **Skript-Ordner** | `C:\Users\D.Göbel\` (Home-Verzeichnis) |
| **QM-Pfad (Server)** | `Q:\Konzepte-Formulare BZWP\` |
| **QM-Pfad (NAS)** | `\\192.168.2.215\arche\QM-Handbuch\Konzepte-Formulare BZWP\` |
| **Backup-Pfad** | `C:\QM-Backup\` |

---

## Skript-Übersicht

### Kern-Skripte

| Skript | Modus | Beschreibung |
|--------|-------|--------------|
| `qm_migration_tool.py` | `--scan` / `--replace` | Haupttool: "DAN" → "Medifox stationär" in allen Formaten |
| `update_footers.py` | direkt | Footer-Datum, Name und Version (röm. Ziffern) aktualisieren |

### Fix-Skripte (einmalige Korrekturen)

| Skript | Beschreibung |
|--------|--------------|
| `fix_names_versions.py` | Autorennamen und Versionen in spezifischen Dokumenten korrigieren |
| `fix_wrong_versions.py` | Falsche Versionsnummern durch Backup-Vergleich reparieren |
| `fix_toc_hyperlinks.py` | Inhaltsverzeichnis-Hyperlinks reparieren |
| `fix_einarbeitungsmappe_wp.py` | Einarbeitungsmappe-spezifische Korrekturen |
| `copy_back.py` | Einzelne Datei zurück auf NAS kopieren |

### Analyse-Skripte (nur lesen)

| Skript | Beschreibung |
|--------|--------------|
| `inspect_footer.py` | Footer-Struktur eines einzelnen Dokuments analysieren |
| `inspect_footers_multi.py` | Footer-Analyse für mehrere Dokumente |
| `analyze_toc.py` / `analyze_toc_full.py` | Inhaltsverzeichnis-Struktur analysieren |

---

## Ausführung

```bash
# 1. Abhängigkeiten installieren (einmalig)
setup_qm_tool.bat                              # python-docx, openpyxl, python-pptx

# 2. Scan (nicht-destruktiv, erzeugt JSON-Bericht)
python qm_migration_tool.py --scan

# 3. Dry-Run (simuliert Änderungen, schreibt nichts)
python qm_migration_tool.py --replace --dry-run

# 4. Ausführung (erstellt erst Backup, dann interaktive Bestätigung)
python qm_migration_tool.py --replace

# 5. Footer aktualisieren
python update_footers.py

# 6. Footer inspizieren (Kontrolle)
python inspect_footers_multi.py
```

**Ausgabe-Dateien:**
- `qm_migration_bericht_YYYYMMDD_HHMMSS.json` — Strukturierter Ergebnisbericht
- `qm_migration_scan_YYYYMMDD_HHMMSS.log` — Detailliertes Log

---

## Zentrale Code-Patterns

### 1. COM-Initialisierung (zwingend)

```python
import pythoncom
import win32com.client

pythoncom.CoInitialize()
try:
    app = win32com.client.DispatchEx("Word.Application")
    app.Visible = False
    app.DisplayAlerts = False
    # ... Arbeit ...
finally:
    app.Quit()
    pythoncom.CoUninitialize()  # MUSS aufgerufen werden!
```

**Ohne `CoUninitialize()` bleibt Word als Zombie-Prozess hängen!**

### 2. Dokument-Schutz

```python
DOC_PASSWORT = "15bz10"

# Schutz-Status prüfen
prot_type = doc.ProtectionType  # -1 = ungeschützt

# Schutz aufheben
if prot_type != -1:
    doc.Unprotect(DOC_PASSWORT)

# ... Bearbeitung ...

# Schutz wiederherstellen (gleicher Typ!)
if prot_type != -1:
    doc.Protect(Type=prot_type, NoReset=True, Password=DOC_PASSWORT)
```

### 3. Lokale-Kopie-Workflow (NAS-sicher)

```python
import shutil, tempfile
from pathlib import Path

nas_pfad = r"\\192.168.2.215\arche\QM-Handbuch\Datei.doc"
tmp_dir = Path(tempfile.gettempdir()) / "qm_fix"
tmp_dir.mkdir(exist_ok=True)
local_copy = tmp_dir / Path(nas_pfad).name

# 1. Von NAS kopieren
shutil.copy2(nas_pfad, str(local_copy))

# 2. Lokal bearbeiten
doc = app.Documents.Open(str(local_copy))
# ...
doc.Save()
doc.Close()

# 3. Zurück auf NAS
shutil.copy2(str(local_copy), nas_pfad)

# 4. Aufräumen
local_copy.unlink()
```

### 4. UNC-Pfade korrekt handhaben

```python
# RICHTIG: String-Konvertierung
pfad = Path(r"\\192.168.2.215\arche\Datei.doc")
abs_pfad = str(pfad)  # "\\192.168.2.215\arche\Datei.doc"

# FALSCH: resolve() oder abspath() konvertiert UNC zu lokalem Pfad!
abs_pfad = pfad.resolve()       # C:\192.168.2.215\arche\...  FALSCH!
abs_pfad = os.path.abspath(pfad) # C:\192.168.2.215\arche\...  FALSCH!
```

### 5. Dual-Format-Verarbeitung

```python
SUPPORTED_NEW = {'.docx', '.xlsx', '.pptx', '.txt'}  # Python-Bibliotheken
SUPPORTED_OLD = {'.doc', '.xls', '.ppt'}               # COM-Automation

if suffix in SUPPORTED_NEW:
    # python-docx / openpyxl / python-pptx
    from docx import Document
    doc = Document(pfad)
    for para in doc.paragraphs:
        if "DAN" in para.text:
            # ...
elif suffix in SUPPORTED_OLD:
    # pywin32 COM
    app = win32com.client.DispatchEx("Word.Application")
    doc = app.Documents.Open(str(pfad))
    # ...
```

### 6. Footer-Zugriff

```python
# Footer in Word-COM: Section → Footer → Table → Cell
for section in doc.Sections:
    for footer_idx in [1, 2, 3]:  # 1=Primary, 2=FirstPage, 3=EvenPages
        try:
            footer = section.Footers(footer_idx)
            if footer.Range.Tables.Count > 0:
                table = footer.Range.Tables(1)
                # Typisch: Zeile 2, Spalte 1 enthält Datum/Name/Version
                cell_text = table.Cell(2, 1).Range.Text
        except Exception:
            continue  # Footer-Typ existiert nicht
```

### 7. Römische Versionsnummern

```python
ROMAN_VALUES = [(1000,'M'), (900,'CM'), (500,'D'), (400,'CD'),
                (100,'C'), (90,'XC'), (50,'L'), (40,'XL'),
                (10,'X'), (9,'IX'), (5,'V'), (4,'IV'), (1,'I')]

def roman_to_int(s):
    result, i = 0, 0
    for value, numeral in ROMAN_VALUES:
        while s[i:].startswith(numeral):
            result += value
            i += len(numeral)
    return result

def int_to_roman(num):
    result = ""
    for value, numeral in ROMAN_VALUES:
        while num >= value:
            result += numeral
            num -= value
    return result

# Version inkrementieren: "III." → "IV."
old_roman = "III"
new_roman = int_to_roman(roman_to_int(old_roman) + 1)  # "IV"
```

### 8. Word-Boundary-Check für "DAN"

```python
import re

# Regex für standalone "DAN" (nicht Teil von "DANIEL", "STANDARDS")
DAN_REGEX = re.compile(r'\bDAN\b')

# Bei COM Find&Replace: Word's MatchWholeWord funktioniert nicht mit Bindestrichen
# Daher manueller Boundary-Check:
def is_word_boundary(char):
    return not char.isalnum() and char != '_'
```

---

## Skip-Patterns

Dateien die übersprungen werden:
- Ordner mit `archiv` im Namen (case-insensitive)
- Temporäre Dateien (`~$Datei.docx`)
- `Thumbs.db`
- Nur unterstützte Endungen werden verarbeitet

---

## Constraints

### NIEMALS
1. Nie direkt auf NAS-Dateien schreiben — immer erst lokal kopieren, bearbeiten, zurückkopieren
2. Nie `--replace` ohne vorherigen `--scan` ausführen
3. Nie `pythoncom.CoUninitialize()` vergessen — Word-Zombie-Prozesse blockieren weitere Skript-Läufe
4. Nie `Path.resolve()` oder `os.path.abspath()` auf UNC-Pfade anwenden
5. Nie Dokument-Schutz entfernen ohne ihn danach mit gleichem Typ wiederherzustellen

### BEVORZUGT
1. Immer `--dry-run` vor echtem `--replace` testen
2. Immer Backup erstellen bevor Massenänderungen gemacht werden (`C:\QM-Backup\`)
3. JSON-Berichte für Audit-Trail nutzen
4. Footer-Inspektion (`inspect_footers_multi.py`) nach Änderungen als Kontrolle
5. Neue Fix-Skripte nach dem Muster der bestehenden erstellen (Deklarativ mit `fixes`-Liste)

### GUT ZU WISSEN
1. QM-Dokumente sind in der Regel formulargeschützt (Passwort: in Skripten hinterlegt)
2. `.doc` (Legacy) erfordert COM, `.docx` (Modern) geht auch mit python-docx
3. `mcp-server-office` (v0.2.0) ist als Alternative installiert — für einfache Aufgaben nutzbar
4. Footer-Struktur: Tabelle mit 2 Zeilen, Datum/Name/Version in Zeile 2 Spalte 1
5. Ergebnisse landen als `qm_migration_bericht_*.json` und `qm_migration_scan_*.log` im Home-Verzeichnis

---

## Konzeptstandard-Erstellung aus DNQP-Expertenstandards

### Workflow (PFLICHT-Reihenfolge)

1. **Interview führen** — IMMER zuerst einrichtungsspezifische Daten erheben, bevor Dokumente erstellt werden. Ohne Interview sind die Konzeptstandards generisch und bei MDK-Prüfung wertlos.
   - Pflegeorganisation (Bezugspflege, Fachkraftquote, Beauftragte)
   - Software & Assessments (Medifox stationär, konkrete Instrumente)
   - Kooperationspartner (Ärzte, Therapeuten, Sanitätshäuser namentlich)
   - Hilfsmittel (was ist vor Ort, was wird geordert)
   - QM-Strukturen (Pflegevisiten, Fallbesprechungen, Fortbildungen)
   - Bewohnerstruktur (Demenzanteil, Psychiatrie, Besonderheiten)

2. **Plausibilitätscheck** — Vor Erstellung prüfen: Stimmt alles mit aktueller Gesetzeslage überein? Gibt es Lücken (fehlende Beauftragte, veraltete Assessments)?

3. **PDF-Auszüge einlesen** — DNQP-Expertenstandard per PyPDF2 extrahieren (Präambel + Standardtabelle)

4. **Konzeptstandard schreiben** — Einrichtungsspezifisch, im Stil der Vorlage

### 8-teilige Gliederung (verbindlich für alle Konzeptstandards)

```
1. Definition:           (bold)     — Was ist das Thema, Relevanz
2. Grundsätze:           (bold)     — Haltung und Leitprinzipien der Einrichtung
3. Ziele:                (bold)     — Konkrete Pflegeziele
4. Vorbereitung          (bold, 14pt) — Organisation, Risikoeinschätzung, Informationssammlung
5. Durchführung          (bold, 14pt) — Beratung + themenspezifische Unterabschnitte
6. Nachbereitung         (bold, 14pt) — Evaluation, Dokumentation
7. Mitgeltende Dokumente:(bold)     — Verweise auf Medifox, QM-Handbuch
8. Verantwortlichkeit:   (bold)     — "Pflegefachkräfte"
```

### Schreibstil

- Erste Person Plural: "Wir stellen sicher...", "Unsere Bezugspflegekraft..."
- Praxisnah, konkret, nicht abstrakt-wissenschaftlich
- "Bewohner/-Innen" (stationäre Langzeitpflege)
- Einrichtungsspezifisch: Medifox stationär, konkrete Beauftragte, benannte Kooperationspartner

### Formatierung mit python-docx

```python
import docx
from docx.shared import Pt

doc = docx.Document()

# Hauptabschnitt (Vorbereitung, Durchführung, Nachbereitung):
p = doc.add_paragraph()
run = p.add_run("Überschrift")
run.bold = True
run.font.size = Pt(14)

# Unterabschnitt (Definition:, Grundsätze:, etc.):
p = doc.add_paragraph()
run = p.add_run("Unterüberschrift:")
run.bold = True

# Fließtext:
doc.add_paragraph("Text...")

# Leerzeile zwischen Abschnitten:
doc.add_paragraph()
```

### Unicode-Umlaute (Windows-Heredoc-sicher)

In Python-Skripten auf Windows Unicode-Escapes statt rohe Umlaute verwenden:
```python
"\u00e4"  # ä     "\u00c4"  # Ä
"\u00f6"  # ö     "\u00d6"  # Ö
"\u00fc"  # ü     "\u00dc"  # Ü
"\u00df"  # ß     "\u2013"  # –
"\u2014"  # —     "\u201e"  # „
"\u201c"  # "
```

### Agent-Delegation (WARNUNG)

Sub-Agenten können auf WS44 keine Bash/Write-Berechtigungen erhalten. Für docx-Erstellung IMMER direkte Ausführung nutzen:
1. `Write` → Python-Skript als `.py` Datei erstellen
2. `Bash` → `python skript.py` ausführen
3. Skript aufräumen

---

## Gelernte Lektionen

### 2026-04-14 - Konzeptstandard-Erstellung (6 Expertenstandards)

**Interview-First-Prinzip:**
- Diana hat die sofortige Dokumenterstellung gestoppt und ein strukturiertes Interview verlangt
- Ohne einrichtungsspezifische Details wären die Konzeptstandards bei MDK-Prüfung wertlos
- Zwei Interview-Runden: Hauptfragen (18 Fragen in 5 Blöcken) + Nachfragen (6 offene Punkte)

**Erstellte Konzeptstandards (6 Stück):**
- Dekubitusprophylaxe (2017), Sturzprophylaxe (2022), Schmerzmanagement (2020)
- Kontinenzförderung (2024), Beziehungsgestaltung Demenz (2019), Ernährungsmanagement (2017)
- Entlassungsmanagement wurde als nicht relevant für stationäre Langzeitpflege eingestuft

**Technisch:**
- Alle 5 Sub-Agenten scheiterten an Bash/Write-Berechtigungen auf WS44
- Lösung: Ein großes Python-Skript mit allen 5 Funktionen, per Write + Bash direkt ausgeführt
- Ernährungsmanagement nachträglich als separates Skript (PDF wurde nachgeliefert)

**BZWP-spezifische Details (in Memory gespeichert):**
- 2 Gebäude (WP 53 + BZ 76 Betten), 7 Wohnbereiche
- Medifox stationär v10.26.15, Bezugspflege, Norton-Skala, NRS/VAS/BESD
- Konkrete Kooperationspartner: WundEx, bb-medica, Dr. Slama, Dr. Drangmeister, Stadtapotheke Eschweiler
- BZ-Besonderheit: Psychiatrie/Suchterkrankungen als Risikofaktor in mehreren Standards berücksichtigt

---

### 2026-02-08 - Initiale Erstellung

**COM-Automation Pitfalls:**
- `pythoncom.CoInitialize/CoUninitialize` ist zwingend — ohne Cleanup entstehen Zombie-Word-Prozesse
- Word's `MatchWholeWord` funktioniert nicht zuverlässig mit Bindestrichen ("DAN-Software")
- Manueller Word-Boundary-Check ist die sichere Alternative

**UNC-Pfad-Falle:**
- `Path.resolve()` und `os.path.abspath()` konvertieren UNC-Server-Pfade in lokale C:-Pfade
- Immer `str(pfad)` statt resolve/abspath verwenden
- Betrifft alle Skripte die auf `\\192.168.2.215\arche\` zugreifen

**Dual-Format-Strategie:**
- Moderne Formate (.docx/.xlsx/.pptx) → Python-Bibliotheken (schneller, kein Word nötig)
- Legacy-Formate (.doc/.xls/.ppt) → COM-Automation (einzige Möglichkeit)
- Migration-Tool unterstützt beide Pfade mit Fallback

**Footer-Muster:**
- Version steht als römische Ziffer NACH dem letzten Datum im Footer
- Regex: `r'\s{2,}([IVXLCDM]+)\.\s'` — nach 2+ Leerzeichen, mit Punkt und Space
- Footer-Zugriff: Section → Footers(1/2/3) → Tables(1) → Cell(2,1)
