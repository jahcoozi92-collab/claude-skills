#!/usr/bin/env bash
# Ontology-Update von WS44, 2026-08-12
# Quelle: Reflect nach der Herbstmarkt-Flyer-Session (Druckdaten + FLYERALARM-Bestellung)
#
# Ausfuehren von einer Maschine mit Route zur Clawbot VM:
#   ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-12.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.

set -u
O="cd ~/clawd && python3 skills/ontology/scripts/ontology.py"

echo "=== Software ==="
eval "$O create -t Software --id sw_flyeralarm -p '{\"name\":\"FLYERALARM\",\"desc\":\"Onlinedruckerei, Sammelformdruck. Beschnittzugabe produktspezifisch (Flyer Klassiker: 1mm, nicht 3mm). Daten-Upload erst NACH dem Kauf. Auftragsnummern enden auf X01/X02 pro Position.\"}'"
eval "$O create -t Software --id sw_real_esrgan -p '{\"name\":\"Real-ESRGAN x4plus\",\"desc\":\"KI-Upscaler, RRDBNet 23 Bloecke. Laeuft lokal auf WS44 mit vorhandenem PyTorch 2.8 CPU. 1055x1491 -> 4220x5964 in 7,3 Min bei 8 Threads. Modell 67MB von github.com/xinntao/Real-ESRGAN.\"}'"
eval "$O create -t Software --id sw_ratepay -p '{\"name\":\"Ratepay\",\"desc\":\"Zahlungsdienstleister fuer Kauf auf Rechnung bei FLYERALARM. Rechnungsadresse nach dem Kauf NICHT mehr aenderbar.\"}'"

echo "=== Patterns ==="
eval "$O create -t Pattern --id p_beschnitt_datenblatt_zuerst -p '{\"name\":\"Beschnittzugabe aus dem Datenblatt, nie annehmen\",\"desc\":\"Branchenueblich 3mm, FLYERALARM Flyer Klassiker verlangt 1mm. A6: 107x150mm Daten bei 105x148mm Endformat. A4: 212x299mm bei 210x297mm. Sicherheitsabstand 4mm. Datenblatt unter /sheets/de/flyer_a6_mass.pdf abrufbar.\"}'"
eval "$O create -t Pattern --id p_randpixel_ausziehen -p '{\"name\":\"Beschnitt durch Ausziehen der Randpixel\",\"desc\":\"Bei randstaendigem Text oder Logo NICHT spiegeln (Schriftzug erscheint lesbar doppelt). Aeusserste Pixelreihe croppen und mit NEAREST auf Randbreite resizen ergibt ruhigen Verlauf.\"}'"
eval "$O create -t Pattern --id p_trimbox_im_pdf -p '{\"name\":\"TrimBox und BleedBox im PDF setzen\",\"desc\":\"doc.xref_set_key(seite.xref, TrimBox, [x0 y0 x1 y1]) in PDF-Punkten. Druckerei erkennt das Endformat dann automatisch. Werte der Vorderseite VOR new_page() auslesen, sonst NoneType-Fehler.\"}'"
eval "$O create -t Pattern --id p_effektive_aufloesung_rechnen -p '{\"name\":\"Effektive Aufloesung rechnen statt dpi-Angabe glauben\",\"desc\":\"Pixelbreite / Endformatbreite_mm * 25,4. Hochskalierte Bilder melden 300dpi und haben die Schaerfe des Originals. Flyer ab 250dpi ok, Plakat A4 braucht 300dpi.\"}'"
eval "$O create -t Pattern --id p_listenauswahl_verifizieren -p '{\"name\":\"Nach Klick in dichter Liste den gesetzten Wert gegenlesen\",\"desc\":\"Screenshot-Koordinaten UND find-refs treffen bei eng gesetzten Tabellen regelmaessig die Nachbarzeile. In einer Session 3x passiert (75/100, 500/1000, Preis falscher Zeile). Reihenfolge: read_page-ref > find-ref > Koordinaten.\"}'"
eval "$O create -t Pattern --id p_formular_speichern_verifizieren -p '{\"name\":\"Formulareingabe ist erst nach Speichern real\",\"desc\":\"Dialog schliessen ohne Speichern-Button = alles verloren. Button liegt oft unterhalb des sichtbaren Bereichs. Danach die dargestellte Fassung per get_page_text gegenlesen, nicht die Formularfelder.\"}'"
eval "$O create -t Pattern --id p_rechenlauf_muster_vorab -p '{\"name\":\"Rechenlauf ueber 1 Minute: erst Muster zeigen\",\"desc\":\"Nutzerin brach den Upscaling-Lauf 2x ab trotz vorheriger Beauftragung. Nach 10-Sekunden-Testausschnitt mit Vorher/Nachher-Bild lief er sofort durch. Laufzeit messen statt schaetzen, Threads drosseln damit die Maschine bedienbar bleibt.\"}'"
eval "$O create -t Pattern --id p_anti_fremde_ustid -p '{\"name\":\"ANTI: USt-ID aus Angebots-Fussleiste uebernehmen\",\"desc\":\"In einem Angebot steht die USt-ID des ABSENDERS. DE 319 533 524 / AG Hildesheim HRB 202124 gehoert MediFox DAN, nicht Arche Noah. Feld ist bei Inlandskauf optional, Pflegeeinrichtungen nach 4 Nr 16 UStG oft befreit.\"}'"
eval "$O create -t Pattern --id p_einseitig_teurer -p '{\"name\":\"Einseitig kann teurer sein als beidseitig\",\"desc\":\"FLYERALARM A4 100 Stk: 4/0 = 34,44 EUR, 4/4 = 26,43 EUR. Loesung: 4/4 bestellen mit weisser Rueckseite. Bei A6 umgekehrt. Immer beide Varianten abfragen.\"}'"
eval "$O create -t Pattern --id p_file_upload_nur_user -p '{\"name\":\"file_upload erreicht weder Netzlaufwerk noch Scratchpad\",\"desc\":\"Beide Pfade abgelehnt: only files this session is allowed to read. Datei-Uploads in Portale sind Nutzersache, das gehoert beim Planen angesagt statt beim Scheitern erklaert.\"}'"
eval "$O create -t Pattern --id p_rgb_statt_falschem_cmyk -p '{\"name\":\"RGB liefern wenn ISO Coated v2 fehlt\",\"desc\":\"Windows hat unter spool/drivers/color nur sRGB und RSWOP.icm (US-Standard). SWOP verfaelscht staerker als die automatische Umrechnung der Druckerei. FLYERALARM-Datencheck akzeptierte RGB ohne Beanstandung.\"}'"
eval "$O create -t Pattern --id p_preisvergleich_ehrlich -p '{\"name\":\"Preisvergleich Agentur vs Selbstbestellung ehrlich fuehren\",\"desc\":\"Bei Rechnung RE17080 stammten 92 Prozent der Ersparnis aus weggefallener Dienstleistung (Design 190, Abwicklung 105, Express+Versand 35 EUR), nicht aus billigerem Druck. Pro Stueck war die Agentur konkurrenzfaehig. Dazusagen, sonst falscher Eindruck.\"}'"

echo "=== Tasks ==="
eval "$O create -t Task --id t_herbstmarkt_flyer_2026 -p '{\"name\":\"Herbstmarkt-Flyer 2026 Druckdaten und Bestellung\",\"desc\":\"Arche Noah Herbstzauber 10./11.10.2026. 1000 Flyer A6 4/0 130g + 100 Plakate A4 4/4 170g, 57,51 EUR brutto bei FLYERALARM statt 260,61 EUR ueber Agentur. Auftrag DE262260269, Druckfreigabe erteilt. Motiv per Real-ESRGAN von 128 auf 510 dpi Reserve gehoben.\",\"status\":\"done\"}'"

echo "=== Relationen ==="
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel uses --to sw_flyeralarm"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel uses --to sw_real_esrgan"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel uses --to sw_ratepay"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_beschnitt_datenblatt_zuerst"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_randpixel_ausziehen"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_trimbox_im_pdf"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_effektive_aufloesung_rechnen"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_rgb_statt_falschem_cmyk"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel applies --to p_preisvergleich_ehrlich"
eval "$O relate --from t_herbstmarkt_flyer_2026 --rel avoids --to p_anti_fremde_ustid"
eval "$O relate --from sw_flyeralarm --rel requires --to p_beschnitt_datenblatt_zuerst"
eval "$O relate --from sw_flyeralarm --rel requires --to p_listenauswahl_verifizieren"
eval "$O relate --from sw_flyeralarm --rel requires --to p_einseitig_teurer"
eval "$O relate --from sw_flyeralarm --rel requires --to p_file_upload_nur_user"
eval "$O relate --from sw_flyeralarm --rel uses --to sw_ratepay"
eval "$O relate --from sw_real_esrgan --rel requires --to p_rechenlauf_muster_vorab"
eval "$O relate --from p_randpixel_ausziehen --rel part_of --to p_beschnitt_datenblatt_zuerst"
eval "$O relate --from p_formular_speichern_verifizieren --rel part_of --to p_listenauswahl_verifizieren"

echo "=== Verifikation (ueber die QUELL-IDs, nur ausgehende Kanten zaehlen) ==="
for id in t_herbstmarkt_flyer_2026 sw_flyeralarm sw_real_esrgan p_randpixel_ausziehen p_formular_speichern_verifizieren; do
  printf '%-42s' "$id"
  eval "$O related --id $id" | python3 -c 'import json,sys
r=json.load(sys.stdin)
print(" -> " + ", ".join("%s:%s" % (x["relation"], x["entity"]["id"]) for x in r) if r else " -> keine ausgehenden (nur Ziel?)")'
done
