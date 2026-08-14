#!/bin/bash
# Ontology-Update NAS 2026-08-14, 2. Reflect-Durchlauf (Lamellen + KI-Dashboard).
# Der erste Teil (nas-2026-08-14.sh) wurde bereits von einer anderen Instanz
# ausgefuehrt (Commit 40c3d73) — hier nur der Nachtrag.
# Ausfuehren:  ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < nas-2026-08-14b.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.
set -e
O="python3 skills/ontology/scripts/ontology.py"
cd ~/clawd

# --- Nachtrag 2. Reflect-Durchlauf, 2026-08-14 (Lamellen + KI-Dashboard) ---
$O create -t Pattern --id p_state_trigger_ohne_to -p '{"name":"state-Trigger ohne to: feuert auf Attribute","desc":"platform: state ohne to: loest auch bei reinen Attribut-Aenderungen aus, bei Cloud-Integrationen also im Poll-Takt (gemessen 1 Lauf/Minute). Gefaehrlich sobald die Aktion Geraete schalten kann. Nachweis per ha_get_automation_traces. Fix: to: ~ plus for: 2min plus Verzoegerung im ha-start-Zweig."}'
$O create -t Pattern --id p_sperrzeit_vs_poll -p '{"name":"Feste Sperrzeit gegen Poll-Intervall ist ein Rennen","desc":"Watcher sperrte 45s, Poll laeuft 60s. Endete die Sperre zuerst, schrieb der Poll den alten Wert zurueck — Ergebnis haengt an der Phasenlage. Muster: auf Bestaetigung warten statt auf die Uhr, mit Deckel, und beim Auslaufen den echten Wert durchlassen."}'
$O create -t Pattern --id p_intermittierend_einzeltest -p '{"name":"Einzeltest widerlegt keinen intermittierenden Fehler","desc":"Bei nicht zuverlaessig ist ein bestandener Durchlauf wertlos — auch nach dem Fix hielten 3 von 3 Runden. Statt Wiederholungen die Zeitstruktur suchen: welche zwei Uhren laufen gegeneinander. Beleg ueber Mechanismus und Logzeile, nicht ueber Trefferquote."}'
$O create -t Pattern --id p_endzustand_gegen_snapshot -p '{"name":"Endzustand maschinell gegen Snapshot pruefen","desc":"Soll/Ist-Abgleich am Ende ist ein Fehlerdetektor, kein Ritual. Der Feld-fuer-Feld-Vergleich deckte ein Geraet auf fan_only auf und fuehrte zur eigentlichen Ursache. Template mit expliziten Sollwerten formulieren, das KORREKT/ABWEICHUNG selbst ausgibt."}'
$O create -t Pattern --id p_unerklaerter_rest_ist_spur -p '{"name":"Unerklaerter Rest ist ein offener Faden","desc":"Nach dem ersten plausiblen Fund pruefen, ob er das Symptom vollstaendig erklaert. Der als nicht reproduzierbar abgelegte Rest (horiz sprang 6 auf 0) war die Spur zur zweiten, groesseren Ursache."}'
$O create -t Pattern --id p_logger_setlevel_fluechtig -p '{"name":"logger.set_level ueberlebt keinen Neustart","desc":"Debug-Level ist fluechtig. Wer Debug setzt, neu startet und dann im Log sucht, findet nichts und haelt den Fix fuer wirkungslos. Nach jedem restart erneut setzen. Zusaetzlich: hon-Debug schreibt JSON mit Feld errors, worauf naives grep -i error trifft — per ANSI-Farbcode am Zeilenanfang filtern."}'
$O create -t Task --id t_lamellen_zuverlaessigkeit_2026_08 -p '{"name":"Lamellen-Positionswechsel zuverlaessig gemacht","desc":"Zwei Ursachen: Timer-Rennen im hon-Watcher (45s Sperre gegen 60s Poll) und eine Resync-Automation mit state-Trigger ohne to:, die im Minutentakt lief und ausgeschaltete Geraete einschalten konnte. Beide behoben, fuenf Testrunden bestanden, Wirkung im Log belegt.","status":"done"}'
$O create -t Task --id t_ki_dashboard_sprachassistent -p '{"name":"Sprachassistent im KI-Dashboard eingebaut","desc":"Chat lief auf conversation.home_assistant (nur feste Kommandos), umgestellt auf conversation.openai_conversation mit Zugriff auf 130 exponierte Entitaeten. Zusaetzlich Karte Jarvis im Raum fragen: conversation.process plus script.jarvis_say_echo mit Musikbett. Bewusst nicht ueber script.jarvis_ask, dessen brain-Container Status unknown meldet.","status":"done"}'

$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_state_trigger_ohne_to
$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_sperrzeit_vs_poll
$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_intermittierend_einzeltest
$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_endzustand_gegen_snapshot
$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_unerklaerter_rest_ist_spur
$O relate --from t_lamellen_zuverlaessigkeit_2026_08 --rel uses --to p_logger_setlevel_fluechtig
$O relate --from t_ki_dashboard_sprachassistent --rel uses --to p_fachskill_vor_eingriff

for id in t_lamellen_zuverlaessigkeit_2026_08 t_ki_dashboard_sprachassistent; do
  printf '%-42s' "$id"
  $O related --id $id | python3 -c 'import json,sys
r=json.load(sys.stdin)
print(" -> " + ", ".join("%s:%s" % (x["relation"], x["entity"]["id"]) for x in r) if r else " -> keine ausgehenden")'
done
