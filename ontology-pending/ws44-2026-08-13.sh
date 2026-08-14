#!/usr/bin/env bash
# Ontology-Update von WS44, 2026-08-13
# Quelle: Reflect nach der yoga7-Session (GNOME Remote Desktop repariert + Speicher-Cleanup)
#
# Ausfuehren von einer Maschine mit Route zur Clawbot VM:
#   ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < ws44-2026-08-13.sh
# Danach diese Datei loeschen und den Loeschvorgang committen.
#
# Hinweis: ws44-2026-08-12.sh liegt ebenfalls noch offen. Erst jene Datei ausfuehren,
# dann diese - die Reihenfolge entspricht der Dateinamen-Sortierung.

set -u
O="cd ~/clawd && python3 skills/ontology/scripts/ontology.py"

echo "=== Software ==="
eval "$O create -t Software --id sw_gnome_remote_desktop -p '{\"name\":\"GNOME Remote Desktop (grd)\",\"desc\":\"RDP-Server auf yoga7, Paket gnome-remote-desktop 50.2-1 unter Kali. Zwei getrennte Dienste: Benutzer-Unit (Bildschirmfreigabe, eigenes RDP-Passwort) und System-Unit --system (Fernanmeldung headless, reicht an GDM durch). Steuerung per grdctl bzw. grdctl --system. Erreichbar ueber Tailscale 100.98.252.44:3389.\"}'"

echo "=== Patterns ==="
eval "$O create -t Pattern --id p_grd_zwei_dienste -p '{\"name\":\"grd: Bildschirmfreigabe und Fernanmeldung nicht verwechseln\",\"desc\":\"Benutzer-Unit = Bildschirmfreigabe, laeuft nur bei grafisch angemeldetem Nutzer, eigenes frei waehlbares RDP-Passwort. System-Unit (--system) = Fernanmeldung headless, reicht die Anmeldung an GDM durch, verlangt daher das LINUX-Anmeldepasswort. Welcher laeuft: ps -eo user,cmd | grep gnome-remote-desktop-daemon, --system im Aufruf entscheidet. loginctl list-sessions zeigt gdm-greeter seat0 yes wenn niemand angemeldet ist.\"}'"
eval "$O create -t Pattern --id p_grd_negotiate_port -p '{\"name\":\"negotiate-port erklaert falsche Ports in gespeicherten .rdp-Dateien\",\"desc\":\"Bei negotiate-port true weicht der Benutzer-Dienst auf 3390 aus, solange der System-Dienst 3389 haelt. Gespeicherte .rdp zeigen dann auf 3390 und sterben, sobald sich der Nutzer abmeldet. Erste Pruefung ss -tln | grep 339. Windows: .rdp sind UTF-16LE, beim Bearbeiten Encoding erhalten.\"}'"
eval "$O create -t Pattern --id p_systemctl_enable_now_kein_restart -p '{\"name\":\"systemctl enable --now startet einen laufenden Dienst nicht neu\",\"desc\":\"Der Daemon liest Konfiguration beim Start. Nach grdctl --system rdp set-credentials ist systemctl restart zwingend. Reihenfolge: erst set-credentials, dann restart - umgekehrt sieht erfolgreich aus und wirkt nicht. Erkennungsmerkmal: unveraenderte PID im Journal trotz erledigter Konfiguration.\"}'"
eval "$O create -t Pattern --id p_grd_system_tls_cert -p '{\"name\":\"Fernanmeldung braucht ein eigenes TLS-Zertifikat\",\"desc\":\"Der Benutzer-Modus hat eins unter ~/.local/share/gnome-remote-desktop/certificates, der System-Modus bekommt keins automatisch. openssl req -x509 nach /var/lib/gnome-remote-desktop/tls.crt und .key, chown auf gnome-remote-desktop, dann grdctl --system rdp set-tls-cert und set-tls-key. Meldung Init TPM credentials failed using GKeyFile as fallback ist kosmetisch. /var/lib/gnome-remote-desktop ist fuer den User nicht lesbar, grdctl --system status braucht sudo und damit ein TTY.\"}'"
eval "$O create -t Pattern --id p_grd_journal_diagnose -p '{\"name\":\"RDP-Diagnose laeuft ueber journalctl -u gnome-remote-desktop\",\"desc\":\"mstsc meldet alles pauschal als Dieser Computer kann keine Verbindung mit dem Remotecomputer herstellen und unterscheidet nicht zwischen Port tot und abgewiesen. Im Journal: Credentials are not set denying client = keine Zugangsdaten hinterlegt. ERRINFO_LOGOFF_BY_USER = Session kam zustande, Erfolg. ERRINFO_RPC_INITIATED_DISCONNECT = serverseitig beendet, typisch Abmeldung. transport_accept_nla beim ersten Versuch = Zertifikatsdialog, harmlos.\"}'"
eval "$O create -t Pattern --id p_opt_root_loeschrecht -p '{\"name\":\"/opt gehoert root, eigene Dateien dort loeschen braucht sudo\",\"desc\":\"Das Loeschrecht haengt am Verzeichnis, nicht an der Datei. ISOs mit Eigentuemer yoga7:yoga7 liessen sich nicht entfernen, weil /opt drwxr-xr-x root root ist. Gilt analog fuer jedes root-eigene Verzeichnis mit fremden Nutzdateien.\"}'"
eval "$O create -t Pattern --id p_anti_rm_ohne_exitcode -p '{\"name\":\"ANTI: destruktiven Schritt ohne Exit-Code-Pruefung protokollieren\",\"desc\":\"Ein Verschiebeskript leitete stderr nach /dev/null und pruefte den rm-Rueckgabewert nicht. Es protokollierte OK verschoben und geloescht, obwohl beide Dateien noch dalagen. Erst df entlarvte es durch einen unveraenderten Wert. Regel: jeden destruktiven Schritt am Exit-Code pruefen (rm -f \\\"\\$f\\\" || { echo FEHLER; continue; }) und stderr nicht verwerfen. Ein Log das ungeprueften Erfolg meldet ist schlimmer als keins.\"}'"
eval "$O create -t Pattern --id p_bom_skript_transfer_win_linux -p '{\"name\":\"Skript von Windows nach Linux: BOM und CRLF strippen\",\"desc\":\"Das Write-Tool erzeugt auf Windows UTF-8 mit BOM. Der BOM steht vor dem Shebang, bash liest 357 273 277 #!/bin/bash als Befehl und meldet command not found. Uebertragung: Get-Content -Raw | ssh host \\\"tr -d BACKSLASH-r > /tmp/x.sh && sed -i 1s/^BOM// /tmp/x.sh && bash -n /tmp/x.sh\\\". Mit od -c sichtbar machen, bash -n immer vor dem Ausfuehren.\"}'"
eval "$O create -t Pattern --id p_tailscale_ip_statt_lan_ip -p '{\"name\":\"Von WS44 immer die Tailscale-IP nutzen, nie die LAN-IP\",\"desc\":\"WS44 liegt im Arbeitsnetz 192.168.2.0/24, das Heimlabor im 192.168.22.0/24 - keine direkte Route. Die Tailscale-IP von yoga7 ist stabil (100.98.252.44, Knoten yoga7-1), der darunterliegende Endpunkt haengt vom Standort des Anfragenden ab: von WS44 gesehen 192.168.3.4:41641, von der NAS gesehen 192.168.22.86:41641. Die im Skill dokumentierte LAN-IP taugt daher nicht als Verbindungsziel.\"}'"
eval "$O create -t Pattern --id p_nas_move_hash_verify -p '{\"name\":\"Grosse Dateien auf die NAS: kopieren, Hash vergleichen, dann erst loeschen\",\"desc\":\"SHA256 auf beiden Seiten pruefen bevor die Quelle faellt. Ueber CIFS dauert die Pruefung etwa so lang wie die Kopie (11 GB rund 8 Minuten gesamt), daher im Hintergrund laufen lassen und den Log pollen. Verschieben auf die NAS bringt echten Platz, weil anderes Dateisystem - Umraeumen innerhalb des Home nicht.\"}'"

echo "=== Tasks ==="
eval "$O create -t Task --id t_yoga7_rdp_fernanmeldung -p '{\"name\":\"yoga7 RDP-Fernanmeldung repariert\",\"desc\":\"2026-08-13. Zwei Ursachen gleichzeitig: die gespeicherte .rdp zeigte auf Port 3390 (dort lauschte seit der Abmeldung um 09:53 nichts mehr), und der System-Dienst auf 3389 hatte weder Zugangsdaten noch TLS-Zertifikat. Fix per Skript: Zertifikat erzeugt, set-credentials, dann restart. Verifiziert durch ERRINFO_LOGOFF_BY_USER im Journal.\",\"status\":\"done\"}'"
eval "$O create -t Task --id t_yoga7_disk_cleanup_0813 -p '{\"name\":\"yoga7 Speicher-Cleanup August 2026\",\"desc\":\"Platte war bei 98 Prozent (454 GB, 9,5 GB frei). Caches und Papierkorb geloescht: 4,6 GB. ISOs (Win11 23H2, Kali 2025.1c, zusammen 11 GB) hash-verifiziert nach /mnt/autofs/nas-personal/ISOs verschoben. OFFEN: Loeschen der Originale in /opt braucht sudo. Groesster verbleibender Posten ist Steam mit rund 96 GB (.var/app Steam 60G, .local/share/Steam 24G, ~/SteamLibrary 12G), dazu Cowork-VM rootfs.img 11 GB.\",\"status\":\"open\"}'"

echo "=== Relationen ==="
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to sw_gnome_remote_desktop"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_grd_zwei_dienste"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_grd_negotiate_port"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_systemctl_enable_now_kein_restart"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_grd_system_tls_cert"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_grd_journal_diagnose"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_bom_skript_transfer_win_linux"
eval "$O relate --from t_yoga7_rdp_fernanmeldung --rel uses --to p_tailscale_ip_statt_lan_ip"
eval "$O relate --from sw_gnome_remote_desktop --rel uses --to p_grd_zwei_dienste"
eval "$O relate --from t_yoga7_disk_cleanup_0813 --rel uses --to p_opt_root_loeschrecht"
eval "$O relate --from t_yoga7_disk_cleanup_0813 --rel uses --to p_anti_rm_ohne_exitcode"
eval "$O relate --from t_yoga7_disk_cleanup_0813 --rel uses --to p_nas_move_hash_verify"

echo "=== Verifikation (ausgehende Kanten je Quell-ID) ==="
for id in t_yoga7_rdp_fernanmeldung t_yoga7_disk_cleanup_0813 sw_gnome_remote_desktop; do
  printf '%-34s' "$id"
  eval "$O related --id $id" | python3 -c 'import json,sys
r=json.load(sys.stdin)
print(" -> " + ", ".join("%s:%s" % (x["relation"], x["entity"]["id"]) for x in r) if r else " -> keine ausgehenden (nur Ziel?)")'
done
