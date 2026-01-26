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
UPDATE documents SET
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

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│              MEDIFOX RAG QUICK REFERENCE               │
├────────────────────────────────────────────────────────┤
│ Format:     Markdown mit H1, Metadaten, Schritte       │
│ FTS:        to_tsvector('german', 'keywords')          │
│ Tags:       pep, mze, urlaub, stundenkonto, etc.       │
│ Quelle:     wissen.medifoxdan.de                       │
│ Storage:    NextCloud → Supabase documents table       │
├────────────────────────────────────────────────────────┤
│ Total Docs: ~500+ Artikel                              │
│ Sprache:    Deutsch (IMMER 'german' für tsvector!)     │
└────────────────────────────────────────────────────────┘
```
