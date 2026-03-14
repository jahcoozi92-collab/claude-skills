---
name: pflege-dokumentation
description: Hilft bei der Arbeit mit Medifox DAN, Medifox Connect, Resmed stationär und anderen Pflegesoftware-Systemen. Optimiert für Qualitätsmanagement und Pflegedokumentation. Trigger bei Medifox, Pflegeplanung, SIS, Bewohnerakte, MDK, Pflegedokumentation.
---

# Pflege-Dokumentation Skill – Medifox, DAN & Pflegesoftware

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

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->

*Noch keine Learnings erfasst. Führe `/reflect pflege-dokumentation` nach einer Session aus!*

---

## Datei-Pfade (Diana's Setup)

| Was | Wo |
|-----|-----|
| Medifox-Docs (NextCloud) | NAS 192.168.22.90 |
| RAG-Vektoren | Supabase @ wfklkrgeblwdzyhuyjrv |
| Workflow-Backups | NextCloud |
| Skills-Repository | ~/.claude/skills/ |
