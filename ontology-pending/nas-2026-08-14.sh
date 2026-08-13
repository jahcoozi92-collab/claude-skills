#!/bin/bash
# Ontology-Update NAS 2026-08-14 — Classifier blockte Cross-Host-SSH, daher als pending abgelegt.
# Ausfuehren:  ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < nas-2026-08-14.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.
set -e
O="python3 skills/ontology/scripts/ontology.py"
cd ~/clawd

$O create -t Pattern --id p_template_sensor_state_limit -p '{"name":"Template-Sensor: Text ins Attribut","desc":"State fasst nur 255 Zeichen; unit_of_measurement macht den Sensor numerisch und verhindert das Anlegen der Entitaet; State darf nicht sein eigenes Attribut lesen. Langer Text gehoert in attributes."}'
$O create -t Pattern --id p_yaml_off_boolean -p '{"name":"YAML off ist Boolean False","desc":"hvac: off wird als False geparst; Vergleich gegen den String off schlaegt fehl. Skript haier_beide_aus war dadurch seit Mai wirkungslos. on/off/yes/no immer quoten."}'
$O create -t Pattern --id p_ha_sections_grid_options -p '{"name":"column_span 2 braucht grid_options","desc":"Eine Section mit column_span 2 hat 24 Grid-Spalten; Karten ohne grid_options columns full bekommen span 12 und fuellen nur die linke Haelfte."}'
$O create -t Pattern --id p_mushroom_tile_info_selector -p '{"name":"Mushroom rendert ueber ha-tile-info","desc":"Text liegt in span slot=primary/secondary im Light-DOM. Alle card_mod-Regeln auf mushroom-state-info sind wirkungslos, auch die Dollar-Shadow-Variante. Stand 2026-08-14 noch offen in fahrzeug, heizung, waschmaschine, media, rollos."}'
$O create -t Pattern --id p_exposure_via_api -p '{"name":"Voice-Exposure ueber die API pruefen","desc":"Direktes Lesen von .storage/homeassistant.exposed_entities ergab 0 statt 130 freigegebener Entitaeten. ha_get_entity_exposure ist die verlaessliche Quelle."}'
$O create -t Pattern --id p_hon_setter_schaltet_ein -p '{"name":"hOn-Setter schalten das Geraet ein","desc":"Nicht nur Lamellenbefehle, auch set_temperature und set_fan_mode starten ein ausgeschaltetes Haier-Geraet. Sollwerte setzen solange es laeuft, erst danach ausschalten. Aus-/Einschalten setzt echo_mode und screen_display zurueck."}'
$O create -t Pattern --id p_guard_helper_ohne_schalter -p '{"name":"Guard-Helfer den niemand schaltet","desc":"input_boolean.do_not_disturb ist Bedingung der Briefing-Automation, wird von keiner Automation umgeschaltet und blockierte sie seit Mai dauerhaft. Bei Automation laeuft nie pruefen wer jede Bedingung je aendert."}'
$O create -t Pattern --id p_fachskill_vor_eingriff -p '{"name":"Fach-Skill vor dem Eingriff laden","desc":"Drei Ausgabewege fuer ein Sprachbriefing neu gebaut, obwohl Skill und Zielkonfiguration den richtigen Weg bereits dokumentierten. Skills werden nicht automatisch geladen."}'
$O create -t Pattern --id p_fehlermeldung_nicht_verallgemeinern -p '{"name":"Fehlermeldung dem Aufruf zuordnen","desc":"Amazons direct-music-streaming-Sperre galt dem MP3-Boot-Sound, nicht der Sprachausgabe. Daraus abgeleitete generelle Unmoeglichkeit war falsch und musste widerrufen werden."}'
$O create -t Task --id t_haier_dashboard_audit_2026_08 -p '{"name":"Klima-Haier-Dashboard Audit und Funktionstest","desc":"Vier Fehler gefunden und behoben: Beide-aus wirkungslos durch YAML-off, Eco-Pilot-Highlight ohne Sofortfeedback, halbe Kartenbreite durch fehlende grid_options, tote Mushroom-Selektoren. Anschliessend alle Funktionen live ausgeloest und verifiziert.","status":"done"}'
$O create -t Task --id t_ha_config_audit_2026_08 -p '{"name":"HA-Konfigurationsaudit Dashboards und Jarvis","desc":"321 Dashboard-Entitaeten geprueft: nur 1 echter Fehltreffer, aber 61 tote Anzeigen (50 Fahrzeug durch VW-API-Block). Jarvis technisch korrekt verdrahtet, 130 Entitaeten exponiert inkl. Rollos mit echten Positionen.","status":"done"}'
$O create -t Task --id t_briefing_umbau_2026_08 -p '{"name":"Morgen-Briefing lauffaehig gemacht","desc":"Lief seit Mai nie: Ziel magentatv unavailable, Spotify-Underlay nicht unterstuetzt, do_not_disturb blockiert. Text ins Attribut verlagert, Ausgabe ueber jarvis_say_echo mit Musikbett, Anrede nach Anwesenheit, Aussprache Dianna.","status":"open"}'

$O relate --from t_haier_dashboard_audit_2026_08 --rel uses --to p_yaml_off_boolean
$O relate --from t_haier_dashboard_audit_2026_08 --rel uses --to p_ha_sections_grid_options
$O relate --from t_haier_dashboard_audit_2026_08 --rel uses --to p_mushroom_tile_info_selector
$O relate --from t_haier_dashboard_audit_2026_08 --rel uses --to p_hon_setter_schaltet_ein
$O relate --from t_ha_config_audit_2026_08 --rel uses --to p_exposure_via_api
$O relate --from t_ha_config_audit_2026_08 --rel uses --to p_mushroom_tile_info_selector
$O relate --from t_briefing_umbau_2026_08 --rel uses --to p_template_sensor_state_limit
$O relate --from t_briefing_umbau_2026_08 --rel uses --to p_guard_helper_ohne_schalter
$O relate --from t_briefing_umbau_2026_08 --rel uses --to p_fachskill_vor_eingriff
$O relate --from t_briefing_umbau_2026_08 --rel uses --to p_fehlermeldung_nicht_verallgemeinern

for id in t_haier_dashboard_audit_2026_08 t_ha_config_audit_2026_08 t_briefing_umbau_2026_08; do
  printf '%-38s' "$id"
  $O related --id $id | python3 -c 'import json,sys
r=json.load(sys.stdin)
print(" -> " + ", ".join("%s:%s" % (x["relation"], x["entity"]["id"]) for x in r) if r else " -> KEINE")'
done
