#!/usr/bin/env bash
# Ontology-Update aus dem Reflect vom 2026-08-05 (WS44 / windows-workstation).
# Konnte am Reflect-Tag nicht laufen: Clawbot VM (192.168.22.206) war offline
# (Tailscale "moltbot-vm: offline, last seen 7d ago"), und WS44 liegt im
# Arbeitsnetz 192.168.2.0/24 ohne Route ins 192.168.22.0/24.
#
# Ausfuehren, sobald die VM wieder erreichbar ist -- von einer Maschine, die
# passwortlos auf die VM kommt (z. B. Yoga7):
#
#   ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-05.sh
#
# Reihenfolge beachtet: erst ALLE create, dann ALLE relate (sonst dangling edges).
# Jedes create traegt ein explizites --id, damit die relate-Referenzen stimmen.

set -u
ONT() { python3 ~/clawd/skills/ontology/scripts/ontology.py "$@"; }

# ---------- Software ----------
ONT create -t Software --id sw_pillow -p '{"name":"Pillow","desc":"Python-Bildbibliothek 11.0.0, auf WS44 installiert. Skalieren, Zuschneiden, DPI-Metadaten setzen, PNG->PDF exportieren."}'
ONT create -t Software --id sw_auf_din_format -p '{"name":"auf_din_format.py","desc":"Skript, das ein Flyer-Rohbild auf exaktes DIN A4/A5 bei 300 dpi bringt und PNG + PDF ausgibt. Liegt im jeweiligen Flyer-Ordner auf WS44 (Desktop und Netzlaufwerk Y:)."}'
ONT create -t Software --id sw_outlook_olk_cache -p '{"name":"Outlook Olk Attachment-Cache","desc":"Neues Outlook legt geoeffnete Anhaenge unter %LOCALAPPDATA%/Microsoft/Olk/Attachments/ooa-<guid>/<hash>/ ab. Dateiname im Klartext, LastWriteTime = Oeffnungszeitpunkt."}'

# ---------- Patterns ----------
ONT create -t Pattern --id p_recent_lnk_aufloesung -p '{"name":"Recent-lnk-Aufloesung","desc":"Arbeitsordner finden, indem %APPDATA%/Microsoft/Windows/Recent/*.lnk per WScript.Shell.CreateShortcut().TargetPath aufgeloest werden. Zeigt Pfad und Oeffnungszeitpunkt, schneller als rekursive Profilsuche."}'
ONT create -t Pattern --id p_cover_crop_din -p '{"name":"Cover-Crop auf DIN-Format","desc":"faktor = max(ziel_b/quell_b, ziel_h/quell_h), LANCZOS-Resample, mittig zuschneiden. Kein Verzerren, keine weissen Raender. A4 = 2480x3508 px, A5 = 1748x2480 px bei 300 dpi."}'
ONT create -t Pattern --id p_png_und_pdf_druckausgabe -p '{"name":"PNG und PDF parallel ausgeben","desc":"Das PDF traegt die Seitengroesse im /MediaBox und verhindert, dass der Druckertreiber auf An-Seite-anpassen skaliert. 595.2x841.92 pt = A4, 419.52x595.2 pt = A5."}'
ONT create -t Pattern --id p_skript_ortsunabhaengig -p '{"name":"Ortsunabhaengiges Skript","desc":"ORDNER = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent. Verhindert Divergenz, wenn dasselbe Skript in mehreren Ordnern liegt (Desktop und Netzlaufwerk)."}'
ONT create -t Pattern --id p_ki_flyer_ohne_quelldatei -p '{"name":"KI-Flyer ohne Quelldatei aendern","desc":"Bei eingebranntem Text gibt es kein Canva/PSD-Original. Statt Retusche: verdichtete Textfassung plus fertiger Generator-Prompt liefern, neu generieren lassen, danach Druckaufbereitung. Umlaute nach jeder Generierung Wort fuer Wort pruefen."}'
ONT create -t Pattern --id ANTI_unc_an_senduserfile -p '{"name":"ANTI: UNC-Pfad an SendUserFile","desc":"SendUserFile lehnt UNC-Pfade hart ab (is a UNC network path, which is not supported). Datei erst nach lokal/Scratchpad kopieren, dann senden. Auf WS44 mit fuenf gemappten Shares der Normalfall."}'
ONT create -t Pattern --id ANTI_zeitstempel_ueberschreiben -p '{"name":"ANTI: Zeitstempel setzen ohne Hash-Notiz","desc":"Setzen von CreationTime/LastWriteTime/LastAccessTime zerstoert die Erkennung, ob eine Datei neu ist. Vorher/nachher SHA1 notieren (Get-FileHash -Algorithm SHA1). Zeitstempel ueberleben Mail/Cloud/NAS-Transport ohnehin nicht zuverlaessig."}'
ONT create -t Pattern --id p_ordner_verifizieren_vor_suche -p '{"name":"Ablageort verifizieren statt annehmen","desc":"Wenn eine angeblich neue Datei am erwarteten Ort fehlt: NICHT dort erneut suchen, sondern Recent-lnk aufloesen. Diana arbeitet zwischen Desktop und Netzlaufwerk Y:, beide Ordner tragen oft denselben Namen."}'

# ---------- Tasks ----------
ONT create -t Task --id t_herbstzauber_flyer_2026 -p '{"name":"Herbstzauber-Flyer 2026 druckfertig","desc":"Flyer fuer Herbstzauber in der Arche Noah am 10. und 11. Oktober 2026. Inhalt verdichtet (Ueberschrift zusammengefasst, Kueche entdoppelt, Geschenkideen in den Aussteller-Button gezogen), danach A4 und A5 bei 300 dpi als PNG und PDF."}'

# ---------- Relationen ----------
ONT relate --from t_herbstzauber_flyer_2026 --rel uses --to sw_auf_din_format
ONT relate --from sw_auf_din_format --rel uses --to sw_pillow
ONT relate --from sw_auf_din_format --rel implements --to p_cover_crop_din
ONT relate --from sw_auf_din_format --rel implements --to p_png_und_pdf_druckausgabe
ONT relate --from sw_auf_din_format --rel implements --to p_skript_ortsunabhaengig
ONT relate --from t_herbstzauber_flyer_2026 --rel uses --to p_ki_flyer_ohne_quelldatei
ONT relate --from t_herbstzauber_flyer_2026 --rel uses --to p_recent_lnk_aufloesung
ONT relate --from p_recent_lnk_aufloesung --rel relates_to --to p_ordner_verifizieren_vor_suche
ONT relate --from p_recent_lnk_aufloesung --rel relates_to --to sw_outlook_olk_cache
ONT relate --from t_herbstzauber_flyer_2026 --rel avoids --to ANTI_unc_an_senduserfile
ONT relate --from t_herbstzauber_flyer_2026 --rel avoids --to ANTI_zeitstempel_ueberschreiben

# ==========================================================================
# Nachtrag aus dem zweiten Reflect am 2026-08-06 (Ziel: reflect-Workflow).
# VM war weiterhin offline (last seen 8d), daher in dieselbe Warteschlangen-
# Datei angehaengt statt eine zweite anzulegen.
# ==========================================================================

# ---------- Software ----------
ONT create -t Software --id sw_tailscale_ws44 -p '{"name":"Tailscale auf WS44","desc":"Einziger Weg von WS44 (Arbeitsnetz 192.168.2.0/24) ins Heimlabor (192.168.22.0/24). Knoten ws44 = 100.115.38.98. Status je Knoten via tailscale status: - bedeutet online, sonst offline last seen."}'

# ---------- Patterns ----------
ONT create -t Pattern --id p_ontology_pending_queue -p '{"name":"ontology-pending Warteschlange","desc":"Wenn die Clawbot VM beim Reflect nicht erreichbar ist: Ontology-Update als lauffaehiges Skript nach ontology-pending/<maschine>-<datum>.sh im Skills-Repo committen statt lokal zu schreiben. Jede Maschine mit Route fuehrt es spaeter per stdin-Pipe aus. Nach Erfolg Datei loeschen und Loeschung committen."}'
ONT create -t Pattern --id p_erreichbarkeit_vor_ssh -p '{"name":"Erreichbarkeit vor SSH pruefen","desc":"Reihenfolge vor jedem Cross-Netz-SSH: Subnetz vergleichen, dann tailscale status lesen, erst dann Test-NetConnection bzw. SSH. Spart fehlschlagende Verbindungsversuche und macht die Ursache sofort sichtbar."}'
ONT create -t Pattern --id p_git_dash_c_auf_windows -p '{"name":"git -C statt cd auf Windows","desc":"Das PowerShell-Tool setzt die CWD nach jedem Aufruf zurueck (Shell cwd was reset to). Git-Befehle daher immer mit git -C <pfad> absetzen."}'
ONT create -t Pattern --id p_eol_check_vor_linux_lauf -p '{"name":"Zeilenenden-Check vor Linux-Lauf","desc":"Von Windows committete .sh-Dateien mit git ls-files --eol pruefen, muss i/lf w/lf zeigen. Pruefung ueber git cat-file mit Out-String ist wertlos, weil PowerShell beim Rejoin selbst CRLF einfuegt."}'
ONT create -t Pattern --id ANTI_lokaler_ontology_fork -p '{"name":"ANTI: lokaler Ontology-Fork","desc":"Bei unerreichbarer VM NICHT ersatzweise in einen lokalen Store schreiben. Lokale Stores sind leer, der kanonische Graph liegt nur auf der Clawbot VM. Lokales Schreiben erzeugt einen divergenten Fork."}'

# ---------- Tasks ----------
ONT create -t Task --id t_reflect_ws44_2026_08 -p '{"name":"Reflect-Workflow von WS44 haerten","desc":"Zweiter Reflect-Durchlauf am 2026-08-06: Step 5 um Erreichbarkeitspruefung und Warteschlangen-Fallback ergaenzt, Instanz-Skill-Name windows-admin auf windows-workstation korrigiert (3 Stellen), Rebase-Konflikt-Regel praezisiert."}'

# ---------- Relationen (Nachtrag) ----------
ONT relate --from t_reflect_ws44_2026_08 --rel uses --to p_ontology_pending_queue
ONT relate --from t_reflect_ws44_2026_08 --rel uses --to p_erreichbarkeit_vor_ssh
ONT relate --from t_reflect_ws44_2026_08 --rel avoids --to ANTI_lokaler_ontology_fork
ONT relate --from p_erreichbarkeit_vor_ssh --rel uses --to sw_tailscale_ws44
ONT relate --from p_ontology_pending_queue --rel relates_to --to p_eol_check_vor_linux_lauf
ONT relate --from p_ontology_pending_queue --rel relates_to --to ANTI_lokaler_ontology_fork
ONT relate --from t_reflect_ws44_2026_08 --rel uses --to p_git_dash_c_auf_windows

# ---------- Verifikation (dangling edges sichtbar machen) ----------
echo "--- related: t_herbstzauber_flyer_2026 ---"
ONT related --id t_herbstzauber_flyer_2026
echo "--- related: sw_auf_din_format ---"
ONT related --id sw_auf_din_format
echo "--- related: t_reflect_ws44_2026_08 ---"
ONT related --id t_reflect_ws44_2026_08
echo "--- related: p_ontology_pending_queue ---"
ONT related --id p_ontology_pending_queue
