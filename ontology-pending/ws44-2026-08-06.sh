#!/usr/bin/env bash
# Ontology-Update von WS44, Session 2026-08-06 (Azubi-Uebersicht / PowerShell-Encoding / PDF-Bilder)
# Clawbot VM war offline (last seen 8d), daher als pending abgelegt.
# Ausfuehren:  ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-06.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.
set -u
cd ~/clawd
ONT() { python3 skills/ontology/scripts/ontology.py "$@"; }

# ---------- CREATE: Software ----------
ONT create -t Software --id sw_azubi_uebersicht \
  -p '{"name":"Azubi-Uebersicht.html","desc":"Single-File-HTML-Dashboard der Arche Noah Azubi-Verwaltung auf \\\\SERVER2012R2\\Dokumente. Daten als JS-Array DATA in einer 940-KB-Zeile, Portraitfotos base64-inline. Ansichten: Galerie, Mindmap, Statistik."}'

ONT create -t Software --id sw_system_drawing_ps \
  -p '{"name":"System.Drawing in PowerShell","desc":"GDI+ via Add-Type -AssemblyName System.Drawing. Auf WS44 der Bordmittel-Weg fuer Bildmasse, Zuschnitt und Bitmap-Bau ohne Pillow. LockBits erwartet BGR-Reihenfolge."}'

# ---------- CREATE: Patterns ----------
ONT create -t Pattern --id p_ps51_bom_pflicht \
  -p '{"name":"PS 5.1 braucht UTF-8-BOM in .ps1","desc":"Das Write-Tool schreibt BOM-los, PowerShell 5.1 liest solche Dateien als cp1252. Umlaut-Pfade werden zu Mojibake (Uebersicht -> Ãœbersicht, FileNotFoundException), Sonderzeichen in String-Literalen landen verstuemmelt in der Zieldatei. Fix: BOM-Bytes EF BB BF voranstellen, bevor das Skript aufgerufen wird."}'

ONT create -t Pattern --id p_umlautpfad_wildcard \
  -p '{"name":"Umlaut-Pfade per Wildcard aufloesen","desc":"Statt den Pfad literal zu schreiben: (Get-ChildItem -LiteralPath $root -Filter \"Azubi-*bersicht.html\").FullName. Umgeht jedes Encoding-Problem zwischen Tool, Shell und Dateisystem."}'

ONT create -t Pattern --id p_anti_include_ohne_wildcard \
  -p '{"name":"ANTI: Get-ChildItem -Include ohne Wildcard im Pfad","desc":"Mit -LiteralPath filtert -Include stillschweigend gar nicht und liefert den kompletten Baum zurueck - ohne Fehler. Entweder -Path \"X\\*\" -Include nutzen oder nachgelagert per Where-Object auf Extension filtern. Gegenprobe: Trefferzahl immer mitloggen."}'

ONT create -t Pattern --id p_pdf_bild_extraktion \
  -p '{"name":"Bilder aus PDF ohne poppler extrahieren","desc":"Filter-Matrix: /DCTDecode = fertiges JPEG, Bytes zwischen FFD8FF und FFD9 rausschneiden. /FlateDecode = zlib, 2-Byte-Header ueberspringen, DeflateStream, Kanalzahl aus raw.Length/(w*h). /CCITTFaxDecode = nicht mit Bordmitteln machbar. Bild-Dictionary per Kontextfenster um /Subtype /Image finden, NICHT per <<...>>-Regex (scheitert an verschachteltem /DecodeParms)."}'

ONT create -t Pattern --id p_ccitt_abbruchkriterium \
  -p '{"name":"CCITTFax-Anteil als Abbruchkriterium","desc":"Vor jedem Extraktionsversuch die Filter-Verteilung im PDF zaehlen. Ueberwiegt /CCITTFaxDecode (S/W-Dokumentenscanner), ist ohne poppler/Ghostscript nichts zu holen - dann aufhoeren statt weitere Skript-Iterationen zu verbrennen. Hier vier Iterationen an vier Scan-PDFs verloren."}'

ONT create -t Pattern --id p_grosse_datenzeile_pflegen \
  -p '{"name":"Single-File-HTML mit Riesen-Datenzeile pflegen","desc":"Read zeigt bei 940-KB-Zeilen nur [Omitted long matching line], Edit ist unbrauchbar. Vorgehen: base64-Fotos per Regex zu \"foto\": true maskieren, Substring von [ bis ]; nehmen, ConvertFrom-Json - dann ist es analysierbar. Einfuegen per String-Splice hinter const DATA=[. Verifikation: <script>-Block herausschneiden und node --check."}'

ONT create -t Pattern --id p_render_vor_daten_pruefen \
  -p '{"name":"Render-Funktion lesen vor Datenergaenzung","desc":"In generierten Dashboards stehen Werte hart im Code, die zum Generierungszeitpunkt fuer alle Eintraege gleich waren (hier: ab 09/2026 im NEU-Badge). Beim ersten Nachtrag stimmt genau das nicht mehr. Erst Render-Funktion pruefen, ggf. Datenfeld einfuehren und Bestand mit dem alten Wert nachruesten, Fallback erhalten."}'

ONT create -t Pattern --id p_namensdrift_quellen \
  -p '{"name":"Namensdrift zwischen Ablage-Quellen","desc":"Ordnername, Word-Liste und Dashboard schreiben Personennamen unterschiedlich (Aarirsse/Aarisse, Schamo Karo/Schamo Caro, Dia Malekuly/Dia Malekudy). Naiver Substring-Abgleich erzeugt Geister-Treffer und uebersieht Personen. Ordnername als Kanon, Abweichungen dem User melden statt still zu vereinheitlichen."}'

ONT create -t Pattern --id p_docx_ohne_word \
  -p '{"name":"DOCX ohne Word-COM lesen","desc":"ZipFile::ExtractToDirectory, dann word/document.xml mit Tag-Regex plaetten: </w:p> -> Newline, </w:tc> -> Pipe, </w:tr> -> Newline, <[^>]+> weg. Schneller als COM (kein Word-Start, keine Prozess-Leiche). Fuer saubere Zellstruktur ist python-docx besser - der Regex-Weg plaettet verbundene Zellen."}'

# ---------- CREATE: Tasks ----------
ONT create -t Task --id t_azubi_uebersicht_pflege_2026_08 \
  -p '{"name":"Azubi-Uebersicht: 5 Karteien nachgetragen (2026-08-06)","desc":"Abgleich Ordnerstruktur gegen Word-Listen gegen Dashboard ergab 8 fehlende Personen. Fuenf davon mit Diana-Daten angelegt (Suresh 08/26, Schamo Karo + Bouziane 10/26, Rubab + Beka 09/26), start-Feld eingefuehrt, Badge dynamisiert, Backup abgelegt, node --check bestanden. Offen: Dia Malekuly, Houari, Sawah, sowie Klaerung Battulga."}'

# ---------- RELATE ----------
ONT relate --from sw_azubi_uebersicht --rel maintained_with --to p_grosse_datenzeile_pflegen
ONT relate --from sw_azubi_uebersicht --rel requires --to p_render_vor_daten_pruefen
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel modifies --to sw_azubi_uebersicht
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel uses --to p_grosse_datenzeile_pflegen
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel uses --to p_namensdrift_quellen
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel uses --to p_docx_ohne_word
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel uses --to p_pdf_bild_extraktion
ONT relate --from t_azubi_uebersicht_pflege_2026_08 --rel blocked_by --to p_ps51_bom_pflicht
ONT relate --from p_ps51_bom_pflicht --rel mitigated_by --to p_umlautpfad_wildcard
ONT relate --from p_pdf_bild_extraktion --rel limited_by --to p_ccitt_abbruchkriterium
ONT relate --from p_pdf_bild_extraktion --rel uses --to sw_system_drawing_ps

# ---------- VERIFIKATION ----------
echo "--- Relationen am Task ---"
ONT related --id t_azubi_uebersicht_pflege_2026_08
echo "--- Relationen am Dashboard ---"
ONT related --id sw_azubi_uebersicht
