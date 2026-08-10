#!/bin/bash
# Ontology-Update von WS44, Reflect-Session 2026-08-10 (windows-workstation).
# Thema: Azubi-Uebersicht-Automatisierung (Task Scheduler + Gesichtserkennung).
# Ausfuehren auf der Clawbot VM: ssh moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-10.sh
set -e
cd ~/clawd
O="python3 skills/ontology/scripts/ontology.py"

# --- Software ---
$O create -t Software --id sw_pymupdf -p '{"name":"PyMuPDF (fitz)","desc":"Python-Bibliothek zum Rendern von PDF-Seiten als Bilder (Matrix-Zoom fuer hohe DPI); Basis fuer Portrait-Extraktion aus gescannten Bewerbungsunterlagen"}'
$O create -t Software --id sw_opencv_haarcascade -p '{"name":"OpenCV Haar-Cascade-Gesichtserkennung","desc":"cv2.CascadeClassifier mit mehreren Modellen (frontalface default/alt/alt2) + IoU-Deduplizierung; auf Windows scheitert das Laden stumm bei Umlaut-Pfaden (empty()==True, keine Exception)"}'
$O create -t Software --id sw_claude_cli_headless -p '{"name":"claude -p (headless/print mode)","desc":"Nicht-interaktiver Aufruf der Claude-Code-CLI fuer unbeaufsichtigte Automatisierung; Prompt per stdin-Pipe statt CLI-Argument (Laengenlimits), --permission-mode bypassPermissions + --allowedTools fuer engen Scope"}'
$O create -t Software --id sw_windows_task_scheduler_local -p '{"name":"Windows-Aufgabenplanung (lokal, fuer Claude-Automatisierung)","desc":"Register-ScheduledTask mit LogonType Interactive ruft ein PowerShell-Wrapper-Skript auf, das claude -p headless startet; Alternative zu Cloud-Routinen wenn lokale UNC-Shares/Tools gebraucht werden"}'

# --- Patterns ---
$O create -t Pattern --id p_opencv_ascii_path -p '{"name":"OpenCV braucht ASCII-Pfade","desc":"cv2.CascadeClassifier und aehnliche OpenCV-Dateizugriffe scheitern still (leeres Objekt, keine Exception) auf Windows-Pfaden mit Nicht-ASCII-Zeichen (z.B. Umlaut im Benutzerprofil). Fix: Modell-/Cascade-Dateien vorab auf reinen ASCII-Pfad kopieren (z.B. C:\\ftmp oder eigener Tool-Ordner am Laufwerkswurzel). PIL/Pillow und regulaere Python-Dateizugriffe sind davon NICHT betroffen."}'
$O create -t Pattern --id p_ps_subprocess_utf8_encoding -p '{"name":"PowerShell Subprozess-stdout-Encoding","desc":"Wird ein UTF-8-ausgebender Subprozess (z.B. claude -p) in PowerShell 5.1 per Pipe/Redirect mitgeschnitten, muss vorher [Console]::OutputEncoding und $OutputEncoding auf UTF8 gesetzt werden - sonst Mojibake beim Einlesen, unabhaengig vom -Encoding-Parameter beim Zurueckschreiben. Separater Mechanismus zur bekannten BOM-Pflicht fuer eigene .ps1-Dateien mit Umlaut-Literalen."}'
$O create -t Pattern --id p_local_vs_cloud_automation -p '{"name":"Lokale vs. Cloud-Automatisierung fuer Dateisystem-Aufgaben","desc":"Cloud-Scheduling-Routinen (isolierte Cloud-Sandbox) haben keinen Zugriff auf lokale UNC-Netzlaufwerke, lokal installierte Pakete oder den Session-Scratchpad. Fuer wiederkehrende Aufgaben auf Netzlaufwerken: lokaler Windows Task Scheduler ruft claude -p headless auf, nicht eine Cloud-Routine."}'
$O create -t Pattern --id p_unattended_pii_guardrails -p '{"name":"Guardrails fuer unbeaufsichtigte Agents mit Personendaten","desc":"Ein claude -p Lauf ohne Konversationserinnerung braucht eine vollstaendig selbststaendige Auftragsdatei. Pflicht-Regeln: automatisches Backup vor jedem Ueberschreiben, nichts erfinden (Felder nur bei eindeutiger Dokumentquelle setzen), lieber kein Foto als ein falsches, Schreibrechte auf engen Dateikreis begrenzen, Quelldokumente nie veraendern."}'
$O create -t Pattern --id p_portrait_contact_sheet -p '{"name":"Portrait-Erkennung per Kontaktbogen","desc":"Fuer Gesichtssuche in gescannten PDFs: jede Seite in 4 Rotationen x mehreren Haar-Cascades rendern, IoU-Deduplizierung, Kandidaten zuschneiden und als nummerierten Kontaktbogen (Bild) zusammenfassen. Ein vision-faehiger Agent waehlt den passenden Kandidaten visuell aus statt automatischer Bestwahl - vermeidet falsche Fotos bei mehrdeutigen Treffern."}'
$O create -t Pattern --id p_scriptfile_over_inline_unc -p '{"name":"Skriptdatei statt inline UNC-Pfad","desc":"UNC-Pfade mit Umlauten in inline bash python -c oder langen powershell -Command Strings brechen unzuverlaessig (verlorener Backslash oder verstuemmeltes Umlautzeichen). Robuste Loesung: Pfad/Logik in eine .py/.ps1-Datei schreiben und diese aufrufen statt literal einzubetten."}'

# --- Task ---
$O create -t Task --id t_azubi_uebersicht_automation -p '{"name":"Azubi-Uebersicht Wochenautomatisierung","desc":"Woechentlicher unbeaufsichtigter Claude-Lauf (Do 10:00, Windows Task Scheduler) prueft die Azubi-Dokumentablage auf neue Personen, sucht Portraits per Gesichtserkennung, aktualisiert roster.json und veroeffentlicht Azubi-Uebersicht.html mit automatischem Backup. Werkzeuge in C:\\AzubiUebersicht (ASCII-Pfad).","status":"aktiv"}'

# --- Relationen (erst nach allen creates) ---
$O relate --from t_azubi_uebersicht_automation --rel uses --to sw_pymupdf
$O relate --from t_azubi_uebersicht_automation --rel uses --to sw_opencv_haarcascade
$O relate --from t_azubi_uebersicht_automation --rel uses --to sw_claude_cli_headless
$O relate --from t_azubi_uebersicht_automation --rel uses --to sw_windows_task_scheduler_local
$O relate --from t_azubi_uebersicht_automation --rel implements --to p_unattended_pii_guardrails
$O relate --from t_azubi_uebersicht_automation --rel implements --to p_portrait_contact_sheet
$O relate --from t_azubi_uebersicht_automation --rel implements --to p_local_vs_cloud_automation
$O relate --from sw_opencv_haarcascade --rel affected_by --to p_opencv_ascii_path
$O relate --from sw_claude_cli_headless --rel affected_by --to p_ps_subprocess_utf8_encoding

echo "Ontology-Update ws44-2026-08-10 abgeschlossen: 4 Software, 6 Patterns, 1 Task, 9 Relationen."
