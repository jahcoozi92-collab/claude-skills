#!/usr/bin/env bash
# Ontology-Update von WS44, 2026-08-21
# Quelle: Reflect nach der Azubi-Uebersicht-Session 20./21.08.2026 (Wochenlauf-Abbruch,
# Aufgabe auf "unabhaengig von der Anmeldung", Ausbildungsende-Feature, docx-Kopfzeile).
#
# Ausfuehren von einer Maschine mit Route zur Clawbot VM:
#   ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-21.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.
#
# Referenzierte, bereits vorhandene IDs (aus ws44-2026-08-12): sw_parse_einsaetze,
# p_namensabgleich_alias_klaerfall, p_docx_tabellen_ohne_com, p_abbruchbedingung_vor_neuer_pflicht,
# t_azubi_externe_einsaetze. Keine Dollarzeichen/Backticks/Apostrophe in den Texten (eval).

set -u
O="cd ~/clawd && python3 skills/ontology/scripts/ontology.py"

echo "=== Software ==="
eval "$O create -t Software --id sw_secedit_user_rights -p '{\"name\":\"secedit (lokale Benutzerrechte)\",\"desc\":\"Windows secedit.exe: /export /cfg datei.inf /areas USER_RIGHTS liest die lokale Richtlinie (UTF-16), /configure /db x.sdb /cfg grant.inf /areas USER_RIGHTS schreibt sie. INF-Aufbau [Unicode] Unicode=yes, [Version] signature CHICAGO Revision=1, [Privilege Rights] SeBatchLogonRight = bestehende Liste,*SID. Braucht Admin. Auf WS44 am 21.08.2026 genutzt, um D.Goebel das Batch-Anmelderecht zu geben.\"}'"
eval "$O create -t Software --id sw_word_com_powershell -p '{\"name\":\"Word COM aus PowerShell (Integritaetstest)\",\"desc\":\"New-Object -ComObject Word.Application; Documents.Open(pfad, false, true) schreibgeschuetzt; Tables.Count und Tables.Item(n).Cell(r,c).Range.Text lesen; Close([ref]0); Quit(). Auf WS44 verfuegbar. Bester Beleg, dass eine per zipfile umgeschriebene docx heil ist.\"}'"
eval "$O create -t Software --id sw_parse_ausbildungszeit -p '{\"name\":\"parse_ausbildungszeit.py (Azubi-Uebersicht)\",\"desc\":\"C:/AzubiUebersicht/parse_ausbildungszeit.py: liest die Word-Jahrestabellen beider Haeuser, wertet die Zellfuellfarbe der Monatsspalten aus (FF0000 rot = sicher, D9D9D9 grau = unsicher), schreibt ausbildungszeit.json mit Beginn/Ende (Monatsende), Aenderungserkennung, ENDET BALD (90 Tage) und ENDE UEBERSCHRITTEN. Importiert norm/baue_index aus parse_einsaetze.py. Seit 20.08.2026 Schritt 2b des Wochenauftrags.\"}'"
eval "$O create -t Software --id sw_set_task_unattended_admin -p '{\"name\":\"set_task_unattended_admin.ps1 + test_unattended.ps1\",\"desc\":\"C:/AzubiUebersicht/: Helfer fuer die Umstellung der Aufgabe AzubiUebersicht-Woechentlich auf LogonType Password. Muss eleviert laufen, fragt das Kennwort per Get-Credential ab, registriert eine temporaere Testaufgabe unter demselben Konto, pollt bis State ungleich Running, zeigt logs/test_unattended.log (Sitzung, Netzlaufwerk, claude --version, claude -p OK) und stellt bei Fehlschlag automatisch auf Interactive zurueck.\"}'"

echo "=== Patterns ==="
eval "$O create -t Pattern --id p_task_exit_c000013a_fenster_geschlossen -p '{\"name\":\"Aufgabenplanung: Rueckgabecode 3221225786 = 0xC000013A = Konsolenfenster geschlossen\",\"desc\":\"STATUS_CONTROL_C_EXIT. Aufgabe mit LogonType Interactive und Hidden False oeffnet ein sichtbares PowerShell-Fenster; wird es zugeklappt, endet der Lauf mit diesem Code, Ereignis 201 meldet trotzdem erfolgreich abgeschlossen. Diagnose: Get-ScheduledTaskInfo (LastTaskResult dezimal zu hex), Operational-Log 100/200/201/104/101, Run-Log und headless-Transkript unter ~/.claude/projects/C--AzubiUebersicht/. Fix: LogonType Password.\"}'"
eval "$O create -t Pattern --id p_sebatchlogonright_nicht_automatisch -p '{\"name\":\"Unabhaengig von der Anmeldung braucht SeBatchLogonRight - Scheduler vergibt es auf WS44 nicht automatisch\",\"desc\":\"Set-ScheduledTask -User -Password stellt auf LogonType Password um, Start scheitert dann mit Ereignis 104/101 Fehlerwert 2147943785 = 0x80070569 (Anmeldetyp nicht gewaehrt) - auch wenn ein Administrator registriert. D.Goebel ist kein lokaler Admin (lokale Admins: Administrator, Domaenen-Admins, User). Domaene ARCHENOAH.LOCAL: nur die Default Domain Controllers Policy setzt das Recht, lokaler Eintrag bleibt. Vergabe per secedit, danach Testaufgabe in Sitzung 0: Netzlaufwerk lesbar, claude im PATH, claude -p antwortet (Profil und Credentials sind im Passwort-Logon da). Kennwortaenderung = Task neu hinterlegen.\"}'"
eval "$O create -t Pattern --id p_elevation_arbeitsteilung_admin_fenster -p '{\"name\":\"Admin-Schritte als Arbeitsteilung: Claude bereitet vor, User fuehrt im Admin-Fenster aus, Claude liest Dateien\",\"desc\":\"Claude kann nicht elevieren, Kennwoerter gehen nicht durch den Chat. Skript nach C:/AzubiUebersicht, Start per Start-Process powershell -Verb RunAs -ArgumentList -NoExit -NoProfile -ExecutionPolicy Bypass -File pfad, Ergebnisse in logs/, Claude liest sie per Test-Path. Befehle ausdruecklich mit im Admin-Fenster, nicht hier im Chat kennzeichnen - Diana pastete sie zweimal in den Chat. Classifier blockt das Schreiben von secedit-Skripten und Zeilen mit bypassPermissions - Richtlinienaenderung ist ein User-Schritt, claude -p ohne Tools braucht keine Flags.\"}'"
eval "$O create -t Pattern --id p_gpresult_verweigert_sysvol_gpttmpl -p '{\"name\":\"gpresult /scope computer verweigert - GPO-Rechte direkt im SYSVOL lesen\",\"desc\":\"gpresult /scope computer /h meldet auf WS44 selbst eleviert Zugriff verweigert. Ohne Admin lesbar (UNC, hier mit Schraegstrichen notiert): //ARCHENOAH.LOCAL/SYSVOL/ARCHENOAH.LOCAL/Policies/GUID/MACHINE/Microsoft/Windows NT/SecEdit/GptTmpl.inf (UTF-16, Get-Content -Encoding Unicode) nach SeBatchLogonRight/SeDenyBatchLogonRight filtern. GUID 6AC1786C-016F-11D2-945F-00C04fB984F9 = Default Domain Controllers Policy, gilt nur fuer DCs.\"}'"
eval "$O create -t Pattern --id p_bang_prefix_gitbash_backslashes -p '{\"name\":\"!-Praefix in Claude Code ist Git Bash: Windows-Backslashes zerfallen\",\"desc\":\"! powershell.exe -File C:-Backslash-Pfad-Backslash-x.ps1 kommt als C:Pfadx.ps1 an (Argument fuer -File nicht vorhanden). Fuer alle Befehle, die man dem User fuer ! gibt: Vorwaerts-Schraegstriche C:/Pfad/x.ps1 oder Quoting. Gleicher Mechanismus wie die Backslash-Halbierung in Bash-Heredocs und python -c.\"}'"
eval "$O create -t Pattern --id p_zustandsbehaftete_aenderungserkennung_abbruch -p '{\"name\":\"Zustandsbehaftete Aenderungserkennung: nach Abbruch nicht einfach neu starten\",\"desc\":\"parse_*.py vergleichen mit der zuvor geschriebenen JSON und ueberschreiben sie sofort. Bricht der Lauf danach ab, meldet ein Neustart keine Aenderung und veroeffentlicht nicht (20.08.2026: ein KH-Einsatz waere aus der Uebersicht gefallen). Vorgehen: Transkript und Zeitstempel pruefen, Restschritte von Hand (build_uebersicht, build_manifest, Protokoll mit Abbruchvermerk). Design: Vergleichsbasis erst nach erfolgreicher Veroeffentlichung festschreiben (json.new, am Ende umbenennen).\"}'"
eval "$O create -t Pattern --id p_docx_inplace_zip_wordcom -p '{\"name\":\"docx in-place korrigieren: zipfile, eine eindeutige Stelle, Word-COM-Pruefung\",\"desc\":\"document.xml lesen, Zielzeile per Regex isolieren, xml.count(head)==1 sichern, re.subn mit erwarteter Trefferzahl, ET.fromstring auf Wohlgeformtheit, alle anderen ZIP-Eintraege unveraendert kopieren, os.replace ueber .tmp. Vorher Sicherungskopie und Sperrdatei ~dollar-name pruefen, danach testzip und Word-COM-Open. Datei wird kleiner (andere Kompression), kein Datenverlust. Nur interaktiv mit Diana, nicht im unbeaufsichtigten Lauf.\"}'"
eval "$O create -t Pattern --id p_docx_zellfarbe_als_daten -p '{\"name\":\"Word-Jahrestabellen: Zeitraum steckt in der Zellfuellfarbe, nicht im Text\",\"desc\":\"Monatsspalten MM/YY sind leer, Markierung ist w:shd w:fill (FF0000 rot sicher, D9D9D9 grau unsicher); mit ET tc.iter(shd), Fill ungleich auto/FFFFFF = markiert. Kopfzeilen-Jahre je Gruppe muessen aufsteigen (wiederholtes Jahr = Kopierfehler, Folgejahr annehmen und melden). Markierung ab der ersten Spalte = Beginn vor der Uebersicht, leer lassen. Summenzeilen (Gesamt, Ziffern) ueberspringen. Ende = letzter Tag des letzten markierten Monats.\"}'"

echo "=== Tasks ==="
eval "$O create -t Task --id t_azubi_wochenlauf_20260820_nachgeholt -p '{\"name\":\"Azubi-Wochenlauf 20.08.2026 nach Abbruch manuell nachgeholt\",\"desc\":\"Automatischer Lauf nach 41 s mit 0xC000013A abgebrochen (Fenster geschlossen), Schritt 1+2 waren durch. Manuell: build_uebersicht (Bleilefens KH Luisen-Hospital), build_manifest, Protokolleintrag. Ordner 80/80 unveraendert.\",\"status\":\"done\"}'"
eval "$O create -t Task --id t_azubi_task_unattended_20260821 -p '{\"name\":\"AzubiUebersicht-Woechentlich auf unabhaengig von der Anmeldung umgestellt\",\"desc\":\"21.08.2026: SeBatchLogonRight per secedit im Admin-Fenster (ARCHENOAH Administrator) vergeben, Task auf LogonType Password, Testlauf Sitzung 0 erfolgreich (claude -p OK). Kein Fenster mehr. Naechster Lauf Do 27.08.2026 10:00.\",\"status\":\"done\"}'"
eval "$O create -t Task --id t_azubi_ausbildungsende_20260820 -p '{\"name\":\"Ausbildungsende in Azubi-Uebersicht und Wochenauftrag aufgenommen\",\"desc\":\"20.08.2026: parse_ausbildungszeit.py (52/52 Personen, 1 unsicher, 9 Aliase), build_uebersicht mit Ende-Badge (bald/ueberschritten/unsicher), Filter, KPI, Statistik, Detail; roster.json Feld ende als Uebersteuerung; WOCHENAUFTRAG Schritt 2b. Diana: grau = unsicher, Datum als Monatsende.\",\"status\":\"done\"}'"
eval "$O create -t Task --id t_wp_docx_kopfzeile_20260820 -p '{\"name\":\"Kopfzeile der Wohnpark-Word-Uebersicht korrigiert (01/26 zu 01/27)\",\"desc\":\"20.08.2026: zweite 1-jaehrig-Tabelle trug 2026 statt 2027; per zipfile korrigiert, Backup in C:/AzubiUebersicht/backups, Word-COM-Pruefung ok, Parser meldet keinen Hinweis mehr.\",\"status\":\"done\"}'"

echo "=== Relationen ==="
eval "$O relate --from t_azubi_wochenlauf_20260820_nachgeholt --rel applies --to p_task_exit_c000013a_fenster_geschlossen"
eval "$O relate --from t_azubi_wochenlauf_20260820_nachgeholt --rel applies --to p_zustandsbehaftete_aenderungserkennung_abbruch"
eval "$O relate --from t_azubi_wochenlauf_20260820_nachgeholt --rel related_to --to t_azubi_externe_einsaetze"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel applies --to p_sebatchlogonright_nicht_automatisch"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel applies --to p_elevation_arbeitsteilung_admin_fenster"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel applies --to p_gpresult_verweigert_sysvol_gpttmpl"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel applies --to p_bang_prefix_gitbash_backslashes"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel uses --to sw_secedit_user_rights"
eval "$O relate --from t_azubi_task_unattended_20260821 --rel uses --to sw_set_task_unattended_admin"
eval "$O relate --from p_sebatchlogonright_nicht_automatisch --rel uses --to sw_secedit_user_rights"
eval "$O relate --from p_sebatchlogonright_nicht_automatisch --rel supersedes --to p_task_exit_c000013a_fenster_geschlossen"
eval "$O relate --from t_azubi_ausbildungsende_20260820 --rel uses --to sw_parse_ausbildungszeit"
eval "$O relate --from t_azubi_ausbildungsende_20260820 --rel applies --to p_docx_zellfarbe_als_daten"
eval "$O relate --from t_azubi_ausbildungsende_20260820 --rel applies --to p_namensabgleich_alias_klaerfall"
eval "$O relate --from sw_parse_ausbildungszeit --rel uses --to sw_parse_einsaetze"
eval "$O relate --from p_zustandsbehaftete_aenderungserkennung_abbruch --rel related_to --to p_abbruchbedingung_vor_neuer_pflicht"
eval "$O relate --from t_wp_docx_kopfzeile_20260820 --rel applies --to p_docx_inplace_zip_wordcom"
eval "$O relate --from t_wp_docx_kopfzeile_20260820 --rel uses --to sw_word_com_powershell"
eval "$O relate --from p_docx_inplace_zip_wordcom --rel uses --to sw_word_com_powershell"
eval "$O relate --from p_docx_inplace_zip_wordcom --rel extends --to p_docx_tabellen_ohne_com"
eval "$O relate --from p_docx_zellfarbe_als_daten --rel extends --to p_docx_tabellen_ohne_com"

echo "=== Verifikation (ausgehende Kanten je Quelle) ==="
for id in t_azubi_wochenlauf_20260820_nachgeholt t_azubi_task_unattended_20260821 t_azubi_ausbildungsende_20260820 t_wp_docx_kopfzeile_20260820 p_sebatchlogonright_nicht_automatisch sw_parse_ausbildungszeit p_zustandsbehaftete_aenderungserkennung_abbruch p_docx_inplace_zip_wordcom p_docx_zellfarbe_als_daten; do
  printf '%-50s' "$id"
  eval "$O related --id $id" | python3 -c 'import json,sys
r=json.load(sys.stdin)
print(" -> " + ", ".join("%s:%s" % (x["relation"], x["entity"]["id"]) for x in r) if r else " -> keine ausgehenden (nur Ziel?)")'
done
