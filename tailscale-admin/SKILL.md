# Tailscale Admin Skill – VPN & Remote-Access Management

| name | description |
|------|-------------|
| tailscale-admin | Verwalte Tailscale-Netzwerk, Geräte, ACLs und Remote-Desktop-Verbindungen. Nutze für VPN-Setup, Gerätebereinigung, Troubleshooting und RDP-Anleitungen. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Stell dir vor, du hast einen geheimen Tunnel zwischen all deinen Geräten - egal wo sie sind. Tailscale ist dieser Tunnel. Dieser Skill hilft dir:
- Neue Geräte in den Tunnel zu bringen
- Alte/kaputte Geräte rauszuwerfen
- Regeln aufzustellen, wer mit wem reden darf
- Fernsteuerung (Remote Desktop) einzurichten

---

## Trigger (Wann wird dieser Skill aktiviert?)

- "Tailscale einrichten/konfigurieren"
- "VPN Probleme", "Gerät nicht erreichbar"
- "Remote Desktop", "RDP", "Remmina"
- "Tailscale API", "Geräte aufräumen"
- "Exit Node Problem"

---

## Diana's Tailscale-Netzwerk

### Geräte-Referenz

| Gerät | Tailscale IP | Tag | Beschreibung |
|-------|--------------|-----|--------------|
| **NAS (ugreen)** | `100.90.233.16` | tagged | UGREEN DXP4800, Docker-Host — Container `tailscale` (v1.98.8 gepinnt) |
| **ws44** | `100.115.38.98` | user | Windows 11 Arbeits-PC — **ANDERES NETZ (192.168.2.x)!** Zugriff via Tailscale: RDP 3389 ✓, SMB 445 ✓, KEIN SSH (Port 22 zu) |
| **yoga7-1** | `100.98.252.44` | tagged | Linux Laptop (Kali) — Tailnet-Name ist `yoga7-1`, nicht `yoga7`. RDP auf **Port 3390** |
| **moltbot-vm** | `100.111.159.120` | tagged | Clawbot VM (192.168.22.206) |
| **lenovo-t450s** | `100.92.109.104` | user | Windows Laptop |
| **samsung-sm-s938b** | `100.126.122.31` | user | Samsung Galaxy S25 Ultra (Diana) |

**Hinweis zur Tag-Spalte:** In `tailscale status` erscheint bei getaggten Geräten
`tagged-devices` als Owner-Platzhalter — das bedeutet "gehört einem Tag" und ist
nicht der Tag-Name selbst.

### Tailnet-Details

- **Tailnet:** `tail2c206a.ts.net`
- **Account:** `jahcoozi92@gmail.com`
- **MagicDNS:** Aktiviert (aber DNS-Override auf Linux problematisch)

---

## API-Operationen

### Authentifizierung

API-Key Format: `tskey-api-XXXXX-XXXXX`
Auth-Key Format: `tskey-auth-XXXXX-XXXXX` (für Geräte-Registrierung)

```bash
# Basis-Authentifizierung
curl -u "APIKEY:" "https://api.tailscale.com/api/v2/..."
```

### Häufige API-Calls

```bash
# Alle Geräte auflisten
curl -s -u "$TS_API_KEY:" "https://api.tailscale.com/api/v2/tailnet/-/devices" | jq '.devices[] | {id, hostname, addresses: .addresses[0], online}'

# Gerät löschen
curl -s -X DELETE -u "$TS_API_KEY:" "https://api.tailscale.com/api/v2/device/{DEVICE_ID}"

# ACL abrufen
curl -s -u "$TS_API_KEY:" "https://api.tailscale.com/api/v2/tailnet/-/acl"

# ACL setzen
curl -s -X POST -u "$TS_API_KEY:" -H "Content-Type: application/json" -d @acl.json "https://api.tailscale.com/api/v2/tailnet/-/acl"

# Tag einem Gerät zuweisen
curl -s -X POST -u "$TS_API_KEY:" -H "Content-Type: application/json" -d '{"tags": ["tag:server"]}' "https://api.tailscale.com/api/v2/device/{DEVICE_ID}/tags"
```

---

## ACL-Konfiguration

### Diana's aktuelle ACL

```json
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:desktop": ["autogroup:admin"],
    "tag:mobile": ["autogroup:admin"]
  },
  "acls": [
    {"action": "accept", "src": ["*"], "dst": ["*:*"]}
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    },
    {
      "action": "accept",
      "src": ["tag:desktop", "tag:mobile"],
      "dst": ["tag:server"],
      "users": ["autogroup:nonroot", "root"]
    }
  ],
  "autoApprovers": {
    "routes": {
      "0.0.0.0/0": ["autogroup:member"],
      "::/0": ["autogroup:member"]
    },
    "exitNode": ["autogroup:member"]
  }
}
```

---

## Remote-Desktop-Verbindungen

### Von Windows (ws44) via RDP

**Zu yoga7 (Linux):**
1. `Win + R` → `mstsc` → Enter
2. Computer: `100.98.252.44:3390` ← **Port 3390, nicht Standard-3389!**
3. Benutzer: `yoga7`
4. Passwort: GNOME-Fernanmelde-Passwort

**Fertige Verbindungsdatei:** `\\192.168.2.215\Public\RDP\yoga7.rdp`
(enthält `full address:s:100.98.252.44:3390`, `username:s:yoga7`)

**Zu NAS:**
- Computer: `100.90.233.16`

### Von Samsung via Microsoft Remote Desktop App

**Zu yoga7 (Linux):**
1. App öffnen → `+` → PC hinzufügen
2. PC-Name: `100.98.252.44:3390`
3. Benutzername: `yoga7`
4. Passwort: GNOME-Fernanmelde-Passwort

**Zu ws44 (Windows):**
1. PC-Name: `100.115.38.98`
2. Benutzername: Windows-Login
3. Passwort: Windows-Passwort

### Von yoga7 (Linux) via Remmina

```bash
# Installation falls nötig
sudo apt install -y remmina remmina-plugin-rdp
```

**Zu ws44 (Windows):**
1. Remmina öffnen → `+` (neue Verbindung)
2. Protokoll: **RDP**
3. Server: `100.115.38.98`
4. Benutzername: Windows-Login
5. Passwort: Windows-Passwort

---

## Tailscale auf Linux einrichten

### Installation

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### Dauerhaft aktivieren

```bash
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
sudo tailscale up --accept-routes
```

### Status prüfen

```bash
tailscale status
```

---

## Troubleshooting

### Diagnose-Reihenfolge bei "Verbindung geht nicht" (IMMER zuerst)

Ein abgelaufener Key oder ein offline Peer sieht in RDP/SSH/Browser aus wie ein
Fehler der jeweiligen Anwendung. Deshalb **von unten nach oben** prüfen, bevor
xrdp, sshd oder die App verdächtigt werden:

```bash
# 1. Ist der Peer überhaupt im Tailnet und online?
tailscale status                    # Windows: & "C:\Program Files\Tailscale\tailscale.exe" status

# 2. Kommen Pakete durch?
tailscale ping 100.98.252.44        # "pong ... via <IP>:41641" = direkte Verbindung OK

# 3. Lauscht der Zielport?
```
```powershell
# Windows-Portcheck ohne Extra-Tools
foreach ($p in 3390,3389,22) {
  $c = New-Object System.Net.Sockets.TcpClient
  $r = $c.BeginConnect("100.98.252.44",$p,$null,$null)
  if ($r.AsyncWaitHandle.WaitOne(4000,$false) -and $c.Connected) { "Port $p : OFFEN" }
  else { "Port $p : KEINE VERBINDUNG" }
  $c.Close()
}
```

**Interpretation:**

| Ergebnis | Bedeutet |
|----------|----------|
| Peer fehlt in `status` / "offline" | Key-Expiry oder Gerät aus → siehe nächster Abschnitt |
| Ping OK, Port zu | Dienst auf dem Ziel läuft nicht (xrdp/sshd prüfen) |
| Ping OK, Port offen | Netzwerk ist NICHT das Problem → Credentials/App prüfen |

### Problem: Schlüsselablauf (Key-Expiry) — Gerät plötzlich nicht mehr erreichbar

**Symptom:** RDP/SSH zu einer `100.x`-Adresse schlägt ohne aussagekräftige Meldung
fehl ("Verbindung nicht möglich"). Die Anwendung meldet KEINEN Tailscale-Fehler,
weil die Verbindung schon vor dem Handshake scheitert.

**Ursache:** Tailscale-Node-Keys laufen standardmäßig nach ~180 Tagen ab. Danach
fällt das Gerät aus dem Tailnet und seine `100.x`-IP ist nicht mehr routbar.
Betrifft besonders Geräte, die per `.rdp`-Datei o.ä. **fest auf eine 100.x-Adresse**
verdrahtet sind — es gibt dann keinen Fallback.

**Lösung:** Admin-Konsole → https://login.tailscale.com/admin/machines
→ Gerät → `...` → **"Disable key expiry"**

**WICHTIG:** Gilt **pro Gerät**, nicht fürs ganze Tailnet. Nach dem Fix für ein
Gerät laufen alle anderen Nodes weiter mit Standardablauf und treffen dasselbe
Problem später erneut. Für dauerhaft benötigte Geräte (NAS, Server, Remote-Ziele)
den Ablauf direkt mit deaktivieren.

**Fallback einplanen:** yoga7 ist zusätzlich per SSH (Port 22) erreichbar. Eine
lokale IP als Notweg nur nutzen, wenn sie aktuell stimmt — das Gerät wechselt die
Netze (2026-08-04 gemessen: `direct 192.168.3.4:41641`, während `yoga7-admin`
noch `192.168.22.86` notiert). Die aktuelle lokale Adresse zeigt `tailscale status`
in der `direct`-Angabe.

### Problem: Android-Apps funktionieren nicht wenn Tailscale an

**Ursache:** Exit Node ausgewählt, der offline ist.

**Lösung:**
1. Tailscale App öffnen
2. Exit Node → "None" / "Kein Exit Node"

### Problem: DNS-Fehler auf Linux

```
remove of "/etc/resolv.conf" failed
```

**Lösung:** DNS-Override deaktivieren:
```bash
sudo tailscale up --accept-dns=false
```

### Problem: Duplikate im Tailnet

Geräte erscheinen mehrfach (z.B. `yoga7` und `yoga7-1`).

**Lösung:** Alte Geräte via API löschen:
```bash
# Geräte-ID finden
curl -s -u "$TS_API_KEY:" "https://api.tailscale.com/api/v2/tailnet/-/devices" | jq '.devices[] | {id, hostname, lastSeen}'

# Altes Gerät löschen
curl -s -X DELETE -u "$TS_API_KEY:" "https://api.tailscale.com/api/v2/device/{OLD_DEVICE_ID}"
```

### Problem: tailscaled startet nicht

```bash
# Logs prüfen
sudo journalctl -xeu tailscaled.service --no-pager | tail -50

# Oft: Wartet auf Login → URL im Log öffnen
```

---

## NIEMALS

- Exit Node auf ein Gerät setzen, das offline sein könnte
- API-Keys in Logs oder öffentlichen Repos speichern
- `tailscale down` auf dem NAS ausführen (Docker-Container!)

---

## Voraussetzungen für RDP

| Gerät | Einstellung |
|-------|-------------|
| **yoga7 (Linux)** | Einstellungen → Freigabe → Fernanmeldung: **EIN** |
| **ws44 (Windows)** | Einstellungen → System → Remotedesktop: **EIN** |

---

## Gelernte Lektionen

### 2026-01-27 - Initiale Session

- **Exit Node Problem:** Wenn Android-Apps nicht funktionieren bei aktivem Tailscale, ist meist ein offline Exit Node ausgewählt
- **Duplikate entstehen** wenn Geräte neu installiert/authentifiziert werden ohne das alte zu löschen
- **API-Key vs Auth-Key:** API für Verwaltung, Auth für Geräte-Registrierung
- **DNS auf Linux:** GNOME/systemd-resolved kollidiert oft mit Tailscale DNS → `--accept-dns=false`
- **ACL-Syntax:** `"dst": ["*"]` ist ungültig, muss `"dst": ["*:*"]` sein
- **Tags:** Werden via separatem API-Endpoint gesetzt, nicht beim Gerät direkt

### 2026-07-07 — Container-Wiederherstellung: State schlägt Auth-Key, Image-Pin, WS44-Zugriff verifiziert

**🔴 State-Persistenz schlägt Auth-Key — Container-Neuanlage braucht meist KEIN Re-Auth**
- Der NAS-Tailscale-Container war seit 1. Mai gelöscht (66 Tage offline), der `TS_AUTHKEY` in `.env` längst abgelaufen — trotzdem loggte sich der neu erstellte Container **sofort als `ugreen` (100.90.233.16) wieder ein**: das `./state`-Volume (`tailscaled.state`) hält die Node-Identität, und der Node war nie aus dem Tailnet gelöscht. Abgelaufener Auth-Key wird bei vorhandenem State ignoriert.
- **Vor-Check ohne API-Key:** `tailscale status` auf einem BELIEBIGEN anderen Tailnet-Gerät (z. B. Yoga7) zeigt auch offline-Nodes inkl. `last seen` → verrät sofort, ob der Node noch registriert ist (dann reicht `docker compose up -d`) oder gelöscht wurde (dann neuer Auth-Key/Interactive-Login nötig).

**🔴 NAS-Container-Setup (Referenz)**
- Pfad: `/volume1/docker/tailscale/` — hat eine **eigene CLAUDE.md** mit allen Befehlen. Compose: `network_mode: host`, `privileged`, `--ssh`-Flag (Tailscale-SSH aufs NAS), State-Volume `./state:/var/lib/tailscale`, `.env` hält `TS_AUTHKEY`.
- Compose-`hostname: nas-jahcoozi` + `--hostname=nas-jahcoozi` sind für den Tailnet-Namen WIRKUNGSLOS, solange State existiert — der Admin-Console-Machine-Name `ugreen` persistiert.

**🟡 Image gepinnt: `tailscale/tailscale:v1.98.8` (statt `:latest`, Diana-Regel)**
- Version des laufenden Containers ermitteln: `docker exec tailscale tailscale version` → als `vX.Y.Z`-Tag in die Compose. Update künftig: Version in Compose ändern → `sudo docker compose up -d`. Backup: `docker-compose.yml.bak-20260707`.

**🟡 WS44-Zugriff (Windows 11 Arbeitsrechner, ANDERES Netz 192.168.2.x) — live verifiziert 2026-07-07**
- Kanonischer Weg: **Tailscale-IP `100.115.38.98`** — funktioniert von überall (auch wenn WS44 unterwegs/im Arbeitsnetz ist).
- Offene Zugriffswege via Tailscale: **RDP 3389 ✓** (mstsc/Remmina), **SMB 445 ✓** (Dateifreigaben: `smb://100.115.38.98/`). **KEIN SSH** (Port 22 zu — kein OpenSSH-Server auf WS44; Tailscale-SSH-Server gibt es unter Windows ohnehin nicht).
- Nebenfund: Es existiert eine Route zwischen 192.168.22.x und 192.168.2.x (192.168.2.38 pingbar, sogar RDP 3389 direkt offen von Yoga7) — für Automationen trotzdem IMMER die Tailscale-IP nutzen (funktioniert standortunabhängig, Route ist nicht garantiert).

**🔵 Geräte-Tabelle oben aktualisiert** (moltbot-vm + lenovo-t450s ergänzt, `yoga7-1`-Name korrigiert, Samsung = SM-S938B/S25 Ultra).

### 2026-08-04 - RDP zu yoga7 defekt: Key-Expiry als Root Cause

**Der Fehler zeigt sich nie dort, wo er entsteht:**
- Symptom war "RDP-Verbindung funktioniert nicht" → Verdacht lag auf xrdp/Credentials
- Tatsächliche Ursache: abgelaufener Tailscale-Node-Key → `100.98.252.44` nicht routbar
- Diana hat den Schlüsselablauf deaktiviert → sofort wieder funktionsfähig
- Lektion: Bei fest auf `100.x`-Adressen verdrahteten Verbindungen (`.rdp`-Dateien,
  Bookmarks, Scripts) ist Key-Expiry die **erste** zu prüfende Ursache, nicht die letzte

**Diagnose vor Hypothese:**
- `tailscale status` → `tailscale ping` → TCP-Portcheck liefert in <1 Min eine
  eindeutige Schichtzuordnung (Tailnet / Dienst / Anwendung)
- Messergebnis nach dem Fix: Peer `active; direct 192.168.3.4:41641`, pong in 20 ms,
  Ports 3390/3389/22 offen → Netzwerk-Layer sauber, Problem war restlos behoben

**yoga7 RDP-Port ist 3390, nicht 3389:**
- Die `.rdp`-Datei nutzt `full address:s:100.98.252.44:3390`
- Der Skill nannte vorher nur die IP → mit `mstsc` auf Standard-3389 wäre man auf
  einem anderen Dienst gelandet
- Beide Ports lauschen auf yoga7; welcher Dienst auf 3389 sitzt, ist nicht untersucht

**Key-Expiry ist eine Pro-Gerät-Einstellung:**
- Das Deaktivieren für yoga7 schützt NICHT ws44, ugreen oder die anderen Nodes
- Bei jedem dauerhaft benötigten Gerät separat setzen
