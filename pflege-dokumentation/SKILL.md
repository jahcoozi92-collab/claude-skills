# Pflege-Dokumentation Skill – Medifox, DAN & Pflegesoftware

| name | description |
|------|-------------|
| pflege-dokumentation | Hilft bei der Arbeit mit Medifox stationär (ehem. Medifox DAN), Medifox Connect, Resmed stationär und anderen Pflegesoftware-Systemen. Optimiert für Qualitätsmanagement und Pflegedokumentation. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
In einem Pflegeheim müssen die Mitarbeiter genau aufschreiben, wie es den Bewohnern geht. Welche Medikamente sie bekommen, wie sie sich fühlen, was sie gegessen haben. Früher war das alles auf Papier – heute nutzt man Computer-Programme dafür.

Diana arbeitet mit solchen Programmen und dieser Skill hilft Claude, genau zu verstehen, wie diese Programme funktionieren und wie man sie richtig benutzt.

---

## Kontext: Diana's Arbeitsumgebung

- **Arbeitgeber:** BZWP/Arche Noah Pflegeeinrichtung
- **Rolle:** Quality Management Coordinator
- **Software-Stack:**
  - Medifox DAN (Pflegedokumentation)
  - Medifox Connect (Schnittstellen)
  - Resmed stationär (Beatmung/Schlafmedizin)
- **Projekte:** PflegeAssist Pro (interaktives Entscheidungsbaum-System)

---

## Medifox DAN – Grundwissen

### Was ist Medifox DAN?

**Einfach erklärt:**
Medifox DAN ist wie ein digitales Tagebuch für Pflegeheime. Statt auf Papier zu schreiben "Frau Müller hat heute gut gegessen", tippt man das in den Computer. Das Programm merkt sich dann alles und kann Berichte erstellen.

### Wichtige Begriffe

| Begriff | Bedeutung | Für 12-Jährige |
|---------|-----------|----------------|
| **Bewohnerakte** | Alle Daten zu einem Bewohner | Wie ein Ordner mit allen Infos zu einer Person |
| **Pflegeplanung** | Was braucht der Bewohner? | Ein Plan, wie man jemandem hilft |
| **Durchführungsnachweis** | Wurde die Pflege gemacht? | Ein Häkchen, dass man seine Arbeit getan hat |
| **SIS** | Strukturierte Informationssammlung | Ein Fragebogen bei der Aufnahme |
| **Maßnahme** | Eine Pflege-Aktion | z.B. "Medikament geben" oder "Beim Waschen helfen" |

### Häufige Aufgaben in Medifox

1. **Bewohner anlegen** → Stammdaten eingeben
2. **Pflegeplanung erstellen** → Probleme und Maßnahmen definieren
3. **Dokumentieren** → Tägliche Einträge machen
4. **Berichte erstellen** → Für MDK, Angehörige, etc.

---

## Medifox Connect – Schnittstellen

### Was ist Medifox Connect?

**Einfach erklärt:**
Manchmal muss Medifox mit anderen Programmen "reden". Zum Beispiel mit dem Arzt-System oder der Apotheke. Medifox Connect ist wie ein Übersetzer, der zwischen verschiedenen Programmen vermittelt.

### Wichtige Schnittstellen

| Schnittstelle | Verbindet mit | Zweck |
|---------------|---------------|-------|
| **HL7** | Krankenhaus-Systeme | Patientendaten austauschen |
| **FHIR** | Moderne Gesundheits-Apps | Standardisierter Datenaustausch |
| **GDT** | Arztpraxis-Software | Befunde empfangen |
| **CSV-Export** | Excel, Analyse-Tools | Daten für Auswertungen |

---

## Resmed stationär

### Was ist das?

**Einfach erklärt:**
Manche Menschen brauchen nachts ein Gerät, das ihnen beim Atmen hilft. Resmed stellt solche Geräte her. Die Software zeigt an, wie gut jemand geschlafen hat und ob das Gerät richtig funktioniert.

### Wichtige Werte

| Wert | Bedeutung | Normal |
|------|-----------|--------|
| **AHI** | Atemaussetzer pro Stunde | <5 = gut |
| **Leckage** | Entweicht Luft aus der Maske? | <24 L/min = ok |
| **Nutzungsstunden** | Wie lange getragen? | >4h = compliance |

---

## PflegeAssist Pro – Diana's Projekt

### Was ist das?

Ein interaktives **Entscheidungsbaum-System** für Pflegekräfte.

**Beispiel-Szenario:**
```
Frage: "Der Bewohner hat Fieber. Was tun?"
        ↓
System: "Ist das Fieber über 38,5°C?"
        ↓
   [Ja]     [Nein]
    ↓         ↓
"Arzt      "Weiter
rufen"     beobachten"
```

### Technische Umsetzung

- **Backend:** n8n Workflows
- **Datenbank:** Supabase (PostgreSQL + Vektoren)
- **Wissensbasis:** RAG-System mit Medifox-Dokumentation
- **Interface:** Wird über Claude entwickelt

---

## Constraints – Was ich IMMER beachten muss

### 🔴 NIEMALS (HIGH PRIORITY)

1. **Niemals** echte Bewohnernamen oder Gesundheitsdaten verwenden
2. **Niemals** Diagnosen stellen – nur Dokumentation unterstützen
3. **Niemals** Medikamentendosierungen empfehlen
4. **Niemals** ärztliche Anweisungen ersetzen
5. **Niemals** DSGVO-relevante Daten in Beispielen nutzen

### 🟡 BEVORZUGT (MEDIUM PRIORITY)

1. **Deutsche Fachbegriffe** verwenden (nicht englische)
2. **Praxisnahe Beispiele** aus dem Pflegealltag
3. **MDK-konforme** Formulierungen bei Dokumentation
4. **SGB XI** Vorgaben beachten (Pflegeversicherung)

### 🟢 GUT ZU WISSEN (LOW PRIORITY)

1. Diana bevorzugt strukturierte Antworten
2. Medifox-Screenshots sind hilfreich für Erklärungen
3. Schulungsmaterial sollte für Pflegekräfte verständlich sein

---

## Dokumentations-Formulierungen

### ✅ Gute Pflegedokumentation

```
"Bewohner klagte heute Morgen über Schmerzen im 
rechten Knie (VAS 5/10). Bewegungseinschränkung 
festgestellt. Hochlagerung durchgeführt. 
Arzt informiert um 10:15 Uhr."
```

**Warum gut?**
- Konkret (rechtes Knie, nicht "Bein")
- Messbar (VAS 5/10)
- Maßnahme dokumentiert
- Uhrzeit angegeben

### ❌ Schlechte Pflegedokumentation

```
"Bewohner hatte Schmerzen. Habe was gemacht."
```

**Warum schlecht?**
- Unspezifisch (wo?)
- Nicht messbar (wie stark?)
- Maßnahme unklar
- Keine Zeit

---

## n8n Integration für Pflege-Workflows

### Typische Workflows

1. **PDF-Einlesen von Medifox-Exporten**
   ```
   Webhook → PDF Extract → Supabase → RAG-Query
   ```

2. **Automatische Erinnerungen**
   ```
   Schedule → Check Pflegeplanung → Slack/Email
   ```

3. **Dokumenten-Analyse**
   ```
   Upload → Textextraktion → Vektor-Embedding → Supabase
   ```

---

## QZ Qualitätszirkel Pflege – Standardisierte Aufstellungen

### Workflow-Pattern: Medifox → Word-Tabelle (via Claude Browser)

Der QZ Pflege erstellt pro Wohnbereich standardisierte Word-Tabellen, die periodisch mit aktuellen Medifox-Daten abgeglichen werden. Dafür werden **Browser-Prompts** eingesetzt, die Claude durch Medifox navigieren lassen:

```
Phase 0: Soll-Anzahl feststellen (Bewohnerliste → "Klienten (N)")
Phase 1: Bewohner-Schleife (strikt oben→unten, pro BW Reiter prüfen, Zeile sofort schreiben)
Phase 2: Vollständigkeitsprüfung (geprüft == Soll? Summen plausibel?)
Phase 3: Word-Dokument erstellen → Download
```

**Regeln:** Still arbeiten, keine Rückfragen, keine Zwischenstände. Gewissenhaftigkeit vor Tempo.

### QZ-Themen und Medifox-Reiter

| QZ-Thema | Medifox-Reiter | Tabellen-Spalten (7) |
|----------|---------------|----------------------|
| **Schmerzmanagement** | "Medikamente" + "Assessments/Maßnahmenplanung" | Bewohner, Dauermedikation, BTM, Bedarfsmedikation, Indikation, RIA, Kontrolle Datum/Hdz |
| **Wundversorgung** | "Wunde" + "Verordnungen" | Bewohner/in, Art der Wunde, Datum der Entstehung, Material, Wechselintervall, Anordnender Arzt, Wundvisite Datum/Hdz |

**Unterschied:** Bei Schmerzmanagement bekommt JEDER Bewohner eine Zeile (ohne Medikation → "/"). Bei Wundversorgung nur Bewohner MIT aktiver Wunde.

### Medifox-Reiter für Schmerzmanagement

- **Medikamente** (oder "Ärztl. Verordnungen"): Zeigt alle aktuellen Medikamente
  - Festmedikation = Dauermedikation (Spalte 2)
  - Bedarfsmedikation = PRN (Spalte 4)
  - BTM-pflichtige Medikamente separat (Spalte 3)
- **Assessments / Maßnahmenplanung**: RIA (Risikoeinschätzung Initiales Assessment)
  - Schmerzassessment / Initiales Assessment → Art des Schmerzes + "Initial"

### Wohnbereiche BZWP

**Betreuungszentrum (BZ) — 76 Betten**

| Wohnbereich | Etage | Kürzel |
|-------------|-------|--------|
| Wurmtal | UG | BZ |
| Voreifel | EG | BZ |
| Aachener Land | OG | BZ |
| Siebengebirge | DG | BZ |

**Wohnpark (WP) — 53 Betten**

| Wohnbereich | Etage | Kürzel |
|-------------|-------|--------|
| Paulinenwäldchen | UG | WP |
| Indetal | EG | WP |
| Burg Wilhelmstein | OG | WP |

**Gesamt: 129 Bewohnerbetten, 7 Wohnbereiche**

**Organisationsstruktur:**
- Je Gebäude 1 PDL + 1 stv. PDL
- 1 zentrales Pflegemanagement
- WBL: Indetal/Paulinenwäldchen (1), Burg Wilhelmstein (1), Aachener Land/Siebengebirge (1), Voreifel (1), Wurmtal (1)
- Bezugspflege mit festen Bezugspflegekräften pro Bewohner

### QZ Word-Layout-Standard

- **Seite:** A4 Querformat, Ränder: 2,5 / 2,5 / 2,0 / 2,5 cm
- **Tabellenformat:** "Tabellenraster" (Table Grid), dünne schwarze Rahmen
- **Shading-Regeln:**
  - Leere Zellen ("/"): `#7F7F7F` (Dunkelgrau)
  - Zellen mit Inhalt: `#FFFFFF` (Weiß) oder auto
  - Assessment-Spalten (RIA): `#D9D9D9` (Hellgrau), "Initial" = fett + weiße Schrift
  - Fehler/Warnungen: Rote Schrift
- **Dosierungsschemata** (z.B. "1-1-1-0"): immer **fett**
- **Footer-Standard:** 27.04.2022 | J. Frantzen | B.Pauly/QMB | Version I. | Seite X von Y
- **Prompt-Dateien:** `Q:\Konzepte-Formulare BZWP\Kapitel 5 Qualität\Qualitätszirkel Pflege\`

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

### 2026-04-14 - Konzeptstandards und Einrichtungsstruktur

**Medifox stationär (nicht mehr "DAN"):**
- Die Einrichtung nutzt Medifox stationär v10.26.15 (+ Testsystem/Schulungsmandant)
- In QM-Dokumenten und Konzeptstandards immer "Medifox stationär" schreiben, nicht "DAN"
- Lernplattform: smartAware (Fachfortbildungen, Pflichtunterweisungen, Expertenstandards)

**Assessments in Medifox stationär:**
- Dekubitus: Norton-Skala
- Sturz: Sturzrisiko-Screening
- Schmerz: NRS, VAS, BESD (bei Demenz)
- Kontinenz: Kontinenzprofil
- Zusätzlich importiert: Aspiration, Hautintegrität, Intertrigo, Obstipation, Pneumonie, Thrombose

**Beauftragte:**
- Wundbeauftragte (ICW): mind. 1 pro Gebäude
- Schmerzbeauftragte/Pain Nurses: mind. 1 pro Gebäude
- Kontinenzbeauftragte: jeweils stv. PDL pro Gebäude
- Hygienebeauftragte: 3 insgesamt
- Praxisanleiter: mind. 4 insgesamt
- KEINE Sturzbeauftragten, KEINE Demenzbeauftragten

**Kooperationspartner (namentlich):**
- Zahnärztin: Dr. Slama
- Neurologin: Dr. Drangmeister (jeden Montag Visite)
- Wundversorgung: WundEx, bb-medica
- Physiotherapie: Maurice Nießen + weitere
- Sanitätshäuser: Koczyba, bb-medica
- Podologie: Monika Dohmen
- Apotheke: Stadtapotheke Eschweiler
- Inkontinenz: bb-medica (Einlagen/Vorlagen + Kontinenzberater)
- Palliativ: Hospizvereine, Homecare, PAN-Netzwerk, GVP-Beratung

---

### 2026-04-12 - QZ Schmerzmanagement Browser-Prompt

**QZ-Aufstellungen via Claude Browser:**
- Browser-Prompts folgen dem Phase 0-3 Pattern (Zählen → Schleife → Prüfung → Download)
- Schmerztherapie-Prompt erstellt analog zum bestehenden Wundversorgung-Prompt
- Prompt liegt unter: `Q:\...\QZ Schmerzmanagement\2026\Aufstellung Schmerztherapie BZ\Prompt_Schmerztherapie_BZ.md`
- Bestehende Vorlagen (Januar 2026) dienten als exakte Layout-Referenz

**Medikamenten-Klassifikation im Prompt:**
- WHO-Stufenschema (Stufe 1/2/3) als Referenzliste für Identifikation schmerzrelevanter Medikamente
- Ko-Analgetika (Pregabalin, Gabapentin, Baclofen) werden immer aufgenommen, mit Klammervermerk falls Nicht-Schmerz-Indikation
- BTM strikt in eigener Spalte (nicht bei Dauermedikation)

---

### 2026-02-12 - MD Stationär Ordner-Analyse

**MD Stationär Migration (DAN/Tulipan → MD Stationär):**
- Kunde: Betreuungszentrum Arche Noah KG, Herzogenrath
- Zwei Standorte: Betreuungszentrum (BZ) + Wohnpark (WP)
- Projektmanager Medifox: Norbert Biron
- Migration geplant: KW 30/2025 (Datenübernahme)

**5-Schritte-Migrationsprozess:**
1. Update DAN auf aktuelle Version
2. MD-Datenbank vorbereiten
3. Pflichtdaten übernehmen (Stammdaten, Mitarbeiter)
4. Abrechnungs-/Pflegedokumente übernehmen
5. Manuelle Nachbearbeitung

**Module MD Stationär:**
- PEP (Personalplanung), VA (Verwaltung), KPB (Pflegeplanung/Dokumentation)
- Connect (Schnittstellen), KI-Dienstplanung, KI-Tourenplanung
- Schulungscodes: KPEP, KVA, KPB, APEP, AVA, APB, KKI, KTour, KCon

**Korrekte Menüpfade (im RAG-System korrigiert):**
- Maßnahmenplanung: `Verwaltung → Bewohner → [Bewohner] → Reiter Planung`
- Textbausteine: `Administration → Dokumentation → Kataloge/Textbausteine`
- FALSCH: `Pflege/Betreuung → Dokumentation → Pflegemappe`

**Projektordner-Struktur:**
- `\\SERVER2012R2\Dokumente\MD Stationär\` enthält ~38 Dateien (PDF, DOCX, XLSX, XLSM)
- Unterordner: `MD Hilfeordner\`, `Konfiguration\`, `Ticketsystem\`
- Analyse-Skript: `C:\Users\D.Göbel\analyze_md_stationaer.py`
- Analyse-Output: `C:\Users\D.Göbel\md_stationaer_analyse.txt`

---

## Datei-Pfade (Diana's Setup)

| Was | Wo |
|-----|-----|
| Medifox-Docs (NextCloud) | NAS 192.168.22.90 |
| RAG-Vektoren | Supabase @ wfklkrgeblwdzyhuyjrv |
| Workflow-Backups | NextCloud |
| Skills-Repository | ~/.claude/skills/ |
| **MD Stationär Projektordner** | `\\SERVER2012R2\Dokumente\MD Stationär\` (= `Y:\MD Stationär\`) |
