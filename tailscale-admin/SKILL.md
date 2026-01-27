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
| **NAS (ugreen)** | `100.90.233.16` | `tag:server` | Synology/UGREEN DXP4800, Docker Host |
| **ws44** | `100.115.38.98` | `tag:desktop` | Windows Arbeits-PC |
| **yoga7** | `100.98.252.44` | `tag:desktop` | Linux Laptop (Fedora/Ubuntu) |
| **Samsung** | `100.126.122.31` | `tag:mobile` | Samsung Galaxy S24 Ultra |

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
2. Computer: `100.98.252.44`
3. Benutzer: `yoga7`
4. Passwort: GNOME-Fernanmelde-Passwort

**Zu NAS:**
- Computer: `100.90.233.16`

### Von Samsung via Microsoft Remote Desktop App

**Zu yoga7 (Linux):**
1. App öffnen → `+` → PC hinzufügen
2. PC-Name: `100.98.252.44`
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
