# Druckdaten Skill – Flyer, Plakate und Onlinedruckereien

| name        | description                                                                                                                                                          |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| druckdaten  | Druckfertige PDFs erzeugen und bei Onlinedruckereien bestellen. Trigger: "Flyer drucken", "Plakat", "Beschnitt", "Druckdaten", "Flyeralarm", "Auflösung reicht nicht". |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Wenn du ein Bild ausdrucken lässt, schneidet die Druckerei den Rand ab — und zwar nie
ganz genau. Deshalb muss das Bild etwas größer sein als das fertige Blatt, sonst gibt es
weiße Streifen am Rand. Dieser Skill weiß, **wie viel** größer es sein muss (das ist bei
jeder Druckerei anders!), wie man solche Dateien baut und was beim Bestellen schiefgeht.

---

## 🔴 Die wichtigste Regel: Datenblatt ZUERST

**Beschnittzugabe ist produktspezifisch. Niemals annehmen.**

Branchenüblich sind 3 mm — FLYERALARM verlangt beim "Flyer Klassiker" aber nur **1 mm**.
Wer 3 mm liefert, bekommt im Uploader eine Formatabweichung gemeldet und den Vorschlag,
die Datei automatisch herunterzuskalieren. Das verkleinert das Motiv um rund 3,6 % und
zieht den Beschnittrand ins sichtbare Format.

Das Datenblatt steht im Konfigurator rechts unter "Ihr Produkt" → **"Datenblatt herunterladen"**.
Direkt abrufbar:

```bash
curl -sL -o blatt.pdf "https://www.flyeralarm.com/sheets/de/flyer_a6_mass.pdf"
curl -sL -o blatt.pdf "https://www.flyeralarm.com/sheets/de/flyer_a4_mass.pdf"
```

Auslesen (die Zahlen stehen als lose Textfragmente drin, nicht als Fließtext):

```bash
python -c "
import fitz, re, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
d=fitz.open('blatt.pdf'); t='\n'.join(p.get_text() for p in d)
for z in t.split('\n'):
    if re.search(r'\d+\s*(x|mm)|beschnitt|endformat|datenformat|dpi|CMYK', z, re.I):
        print(z.strip()[:110])
"
```

### FLYERALARM "Flyer Klassiker" — verifiziert 2026-08-10

| Format | Endformat     | Datenformat   | Beschnitt | Sicherheitsabstand |
| ------ | ------------- | ------------- | --------- | ------------------ |
| DIN A6 | 105 × 148 mm  | 107 × 150 mm  | 1 mm      | 4 mm               |
| DIN A4 | 210 × 297 mm  | 212 × 299 mm  | 1 mm      | 4 mm               |

---

## Druckdaten erzeugen (PyMuPDF + Pillow)

Referenzskript liegt unter
`\\SERVER2012R2\Dokumente\Diana Göbel\Flyer\Herbstmarkt-Flyer\druckdaten_erzeugen.py`.
Parameter oben in der Datei: `BESCHNITT_MM`, `SICHERHEIT_MM`, `VERSATZ_OBEN_MM`, `FORMATE`.

**Beschnitt aus einem randlosen Motiv erzeugen — drei Verfahren:**

| Verfahren               | Wann                                     | Nachteil                       |
| ----------------------- | ---------------------------------------- | ------------------------------ |
| Cover-Skalierung        | Motiv hat Reserve, Rand ist unwichtig    | Randinhalt wird abgeschnitten  |
| Spiegelung der Randpixel | fotografischer Rand ohne Text            | Text/Logos doppelt sichtbar    |
| **Randpixel ausziehen** | **Rand enthält Text, Logo oder Kanten**  | 1–2 mm leicht verwaschen       |

Bei einem Logo oder Schriftzug am Rand ist Spiegeln falsch: der Schriftzug erscheint
lesbar gespiegelt im Beschnitt und fällt auf, sobald der Schnitt nach außen abweicht.
Ausziehen der äußersten Pixelreihe (`crop` 1 px + `resize(..., NEAREST)`) ergibt einen
ruhigen Verlauf.

**TrimBox setzen** — damit erkennt die Druckerei das Endformat automatisch:

```python
doc.xref_set_key(seite.xref, "TrimBox", "[x0 y0 x1 y1]")   # in PDF-Punkten
doc.xref_set_key(seite.xref, "BleedBox", "[0 0 breite hoehe]")
```

**Weiße Rückseite anhängen** (für 4/4-Bestellungen ohne Rückseitenmotiv):
`doc.new_page()` + `draw_rect(..., fill=(1,1,1))`. Wichtig: Werte der Vorderseite
**vor** `new_page()` auslesen — das Anlegen macht bestehende Page-Objekte ungültig
(`AttributeError: 'NoneType' object has no attribute 'page_xref'`).

**Kontrollansicht ausgeben:** PNG mit rotem Rechteck (Endformat) und grünem Rechteck
(Sicherheitsabstand). Spart jede Diskussion darüber, was abgeschnitten wird.

---

## Auflösung: was reicht, und was tun wenn nicht

| Ziel        | Untergrenze | Kommentar                        |
| ----------- | ----------- | -------------------------------- |
| Flyer A6/A5 | ~250 dpi    | 255 dpi war einwandfrei          |
| Plakat A4   | 300 dpi     | 128 dpi wirkt sichtbar weich     |

Effektive Auflösung = `Pixelbreite / Endformatbreite_mm × 25,4`.
**Nicht** die dpi-Angabe der Datei glauben — hochskalierte Bilder melden 300 dpi und
haben trotzdem nur die Schärfe des Originals.

### KI-Upscaling lokal mit Real-ESRGAN

Auf WS44 ist PyTorch 2.8 (CPU) und OpenCV vorhanden — es fehlt nur die Modelldatei.
Kein Online-Dienst nötig, das Bild verlässt den Rechner nicht.

```bash
curl -sL -o RealESRGAN_x4plus.pth \
  "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"
```

Die RRDBNet-Architektur (23 Blöcke, 64 Feature-Maps) ist in ~60 Zeilen selbst
implementierbar; `load_state_dict(zustand.get("params_ema", zustand), strict=True)`.
Kachelweise mit Überlappung verarbeiten (192 px Kachel, 24 px Rand), sonst Nahtkanten.

**Messwerte 2026-08-10 (WS44, 8 Threads):** 1055 × 1491 → 4220 × 5964 px in 7,3 Minuten.
Faustformel: rund 10 Sekunden pro 42.000 Quellpixel.

Ergebnis danach auf das Zielformat **herunter**rechnen — das gibt zusätzliche Bildruhe.

**Was Upscaling NICHT kann:** Layout ändern, Text neu setzen, Logos verschieben.
Es rekonstruiert Kanten und Strukturen, mehr nicht. Wenn der Kunde "Layout unverändert"
sagt, ist Upscaling der richtige und einzige Hebel.

---

## Farbraum: RGB ist oft die bessere Wahl

Für korrektes CMYK braucht es **ISO Coated v2 (ECI)**. Auf Windows liegen unter
`C:\Windows\System32\spool\drivers\color\` nur `sRGB` und `RSWOP.icm` (US-Standard).
Eine Konvertierung mit SWOP verfälscht die Farben stärker als die automatische
Umrechnung der Druckerei.

**Regel:** Ohne ISO-Coated-Profil in RGB liefern und das dokumentieren. FLYERALARM
akzeptiert RGB, der Datencheck lief 2026-08-10 ohne Beanstandung durch.

---

## Bestellung bei FLYERALARM

### Preisfallen

- **Einseitig kann teurer sein als beidseitig.** Bei DIN A4 / 100 Stück: 4/0 = 34,44 €,
  4/4 = 26,43 €. Lösung: 4/4 bestellen und eine Datei mit weißer Rückseite hochladen.
  Beim A6 war es umgekehrt (4/0 minimal günstiger). **Immer beide Varianten abfragen.**
- **Auflagen sind grob gestaffelt** — zwischen 1.000 und 2.500 liegt nichts. Für 1.200
  Stück zahlt man den 2.500er-Preis.
- Papierstärke kostet unterschiedlich viel: A6 130 → 170 g = +3,19 €, A4 = +9,19 €.
  Für Plakate lohnt 170 g (130 g wellt an der Wand), für Handzettel reicht 130 g.

### Preise ablesen — 🔴 immer gegenprüfen

Die Preistabelle hat eng gesetzte Zeilen. Sowohl Screenshot-Koordinaten als auch
`find`-refs treffen regelmäßig die **Nachbarzeile**. In einer Session dreimal passiert
(75 statt 100, 500 statt 1000, und ein Preis der falschen Zeile zugeordnet — daraus
wurde eine falsche Empfehlung an die Kundin).

**Nach jeder Mengenauswahl den gesetzten Wert im Kasten "Ihr Produkt" auslesen**, bevor
irgendetwas darauf aufgebaut wird:

```
find "Angabe Menge: mit Stückzahl im rechten Produktkasten"
→ muss die erwartete Zahl zeigen, sonst Konfiguration neu laden
```

### Ablauf

1. Konfigurator: Ausführung → Format → Material → Veredelung → Farbigkeit
2. Preistabelle: linke Spalte = Standard, mittlere = Express, rechte = Overnight
3. In den Warenkorb → Zahlart → Adressen → AGB → Kaufen
4. **Daten-Upload erst NACH dem Kauf** (`/uploader/upload?orderitemid=…`)
5. Datencheck starten → Ergebnis abwarten → Druckfreigabe erteilen

Auftragsnummern enden auf `X01`, `X02` … pro Position. Die Druckdatenübersicht einer
Position erreicht man über `Meine Bestellungen` oder direkt per orderitemid.

### Was ich NICHT tun darf

- **Anmelden** (Passworteingabe) — grundsätzlich Sache des Nutzers
- **"Jetzt kaufen"** — löst die Zahlungsverpflichtung aus
- **AGB anhaken** — ist der Vertragsschluss
- **Dateien hochladen** — `file_upload` wird sowohl für Netzlaufwerke als auch für den
  Scratchpad abgelehnt ("only files this session is allowed to read"). Das gehört von
  vornherein eingeplant und angesagt, nicht erst beim Scheitern erklärt.

---

## Rechnungsdaten aus vorhandenen Unterlagen

Firmierung, Adresse und Ansprechpartner stehen meist schon in alten Angeboten oder
Rechnungen auf dem Server. Gezielt suchen statt nachfragen:

```bash
python -c "
import fitz, glob, re, os
for f in glob.glob('Angebote_Bestellungen/**/*.pdf', recursive=True)[:60]:
    try: d=fitz.open(f); t='\n'.join(p.get_text() for p in d); d.close()
    except Exception: continue
    for m in re.finditer(r'\bSUCHBEGRIFF\b', t):
        print(os.path.basename(f), '|', t[max(0,m.start()-120):m.start()+120].replace(chr(10),' | ')[:240])
        break
"
```

**🔴 USt-ID und Handelsregister aus Fußzeilen NICHT übernehmen.** In einem Angebot steht
die USt-ID des **Absenders**, nicht die des Empfängers. Konkret: `DE 319 533 524` /
`AG Hildesheim HRB 202124` gehört MediFox DAN — nicht Arche Noah. Wer das einträgt,
produziert eine falsche Rechnung.

Bei Inlandskäufen ist das USt-ID-Feld optional. Pflegeeinrichtungen sind nach
§ 4 Nr. 16 UStG oft umsatzsteuerbefreit und haben gar keine.

### Bekannte Firmierungen (Stand 2026-08-10)

| Zweck              | Angaben                                                                |
| ------------------ | ---------------------------------------------------------------------- |
| Lieferung          | Betreuungszentrum Arche Noah, Hoheneichstr. 20, 52134 Herzogenrath      |
| Rechnung           | SSU Service & Leistungen GmbH, Arnold-von-Harff-Str. 15, 41812 Erkelenz |
| Ansprechpartner Rg. | Theo Sanders                                                          |

Vor- und Nachname sind bei FLYERALARM **Pflichtfelder** — ein Firmenname allein wird
nicht gespeichert ("Bitte ausfüllen").

---

## Preisvergleich ehrlich führen

Bei einer Agenturrechnung stecken die Kosten selten im Druck. Beispiel RE17080 (netto):

| Posten                | Agentur  | Selbst   |
| --------------------- | -------- | -------- |
| Design, 2 Motive      | 190,00 € | 0 €      |
| Druckabwicklung       | 105,00 € | 0 €      |
| Express + Versand     |  35,00 € | 0 €      |
| **Dienstleistung**    | **330 €**| **0 €**  |
| Reiner Druck          |  79,00 € | 48,33 €  |

Rund 92 % der Ersparnis stammen aus weggefallener Dienstleistung. Pro Stück war die
Agentur beim Druck sogar konkurrenzfähig (Plakat: 26,0 ct gegen 29,9 ct bei uns).
**Das gehört dazugesagt** — sonst entsteht der falsche Eindruck, die Agentur hätte
überteuert gedruckt. Und: die 330 € Arbeit sind nicht verschwunden, sie sind zum Kunden
gewandert, samt Reklamationsrisiko.

---

## Diagnose

| Symptom                                        | Ursache / Prüfung                                          |
| ---------------------------------------------- | ---------------------------------------------------------- |
| "Benötigtes Datenformat" weicht ab             | Beschnitt falsch → Datenblatt lesen, Datei neu erzeugen     |
| Uploader schlägt Skalierung vor                | **Nicht übernehmen** — Motiv würde verkleinert              |
| PDF-Seite hat 0 Zeichen Text                   | Scan oder Rasterexport → `get_pixmap(dpi=170)` und ansehen  |
| Bild wirkt weich trotz 300 dpi                 | effektive Auflösung rechnen, nicht die Datei-Angabe glauben |
| `get_text()` liefert nichts bei Datenblättern  | Maßangaben stehen als lose Fragmente → zeilenweise filtern  |
