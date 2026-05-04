# Home Assistant Skill

Patterns and best practices for working with Home Assistant configuration on this NAS.

## Environment

- **Location**: `/volume1/docker/home-assistant`
- **Config**: `/volume1/docker/home-assistant/config`
- **Internal URL**: `http://192.168.22.90:8123`
- **External URL**: `https://homeassistant.forensikzentrum.com`
- **Container Name**: `homeassistant` (NICHT `home-assistant`)
- **HA Version**: 2026.4.x (stable, verifiziert 2026-04-22)
- **Docker**: `network_mode: host`, `privileged: true`
- **Voice-Container** (laufen parallel auf NAS):
  - `ha-wyoming-whisper` (Port 10300, STT lokal, rhasspy/wyoming-whisper:latest)
  - `ha-wyoming-piper` (Port 10200, TTS lokal, rhasspy/wyoming-piper:latest, default voice `de_DE-thorsten-medium`)

## Common Commands

```bash
# Restart Home Assistant (sauberer als docker restart)
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  "$HA_URL/api/services/homeassistant/restart" -d '{}'
# Fallback: docker restart homeassistant

# Check config validity (REST — schneller, kein NAS-Login nötig)
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  -H "Content-Type: application/json" \
  "$HA_URL/api/config/core/check_config" -d '{}'
# Liefert: {"result":"valid","errors":null,"warnings":null}
# Fallback: docker exec homeassistant python3 -m homeassistant --script check_config --config /config

# View logs
docker logs homeassistant --tail 100 -f

# Check health
docker inspect --format='{{.State.Health.Status}}' homeassistant

# Entity Registry auslesen
docker exec homeassistant python3 -c "
import json
with open('/config/.storage/core.entity_registry') as f:
    data = json.load(f)
for e in data['data']['entities']:
    if 'climate' in e['entity_id']:
        print(e['entity_id'], e.get('platform'))
"
```

## REST-Auth & Token-Speicher (Yoga7)

HA Long-Lived Tokens persistent in `~/.config/homeassistant/env` ablegen, **niemals im Chat oder Shell-History eintippen**:

```bash
# Token-Datei anlegen — IMMER via Editor, nie via printf/echo (Shell-History-Leak)
nano ~/.config/homeassistant/env
# Inhalt:
# HA_URL=http://192.168.22.90:8123
# HA_LONG_LIVED_TOKEN=eyJ…
chmod 600 ~/.config/homeassistant/env
```

In allen HA-Skripten/Bash-Routinen `source ~/.config/homeassistant/env` als ersten Schritt. URL ist die LAN-Variante (schneller, internetausfall-fest), externe URL nur wenn ausdrücklich aus dem WAN gerufen wird.

Token-Generation: HA UI → Profil → Sicherheit → "Lange gültige Zugriffstokens".
Bei Leak (Token im Chat/Commit/Screenshot): sofort revoken in derselben UI-Sektion.

### Env-Export für Python-Subprocesses
`source <env>` setzt Variablen nur in der aktuellen Shell, **nicht** für aufgerufene Python-Skripte. Wenn ein Python-Helper `os.environ["HA_LONG_LIVED_TOKEN"]` liest, KeyError. Lösung:
```bash
set -a
source ~/.config/homeassistant/env
set +a
/tmp/hawsv/bin/python3 /tmp/ha_helper.py
```
`set -a` markiert alle gesourcten Variablen als exportiert (`export`). Nach Subprocess: `set +a` zurücksetzen.

Schnelles WebSocket-Helper-Setup:
```bash
python3 -m venv /tmp/hawsv && /tmp/hawsv/bin/pip install -q websockets
```

## Package System

Home Assistant loads all YAML files from `config/packages/` automatically:

```
config/packages/
├── backup.yaml                # Nightly backup + rotation
├── clawdbot_automations.yaml  # Webhook handlers (WhatsApp Bot)
├── clawdbot_devices.yaml      # Template entities, groups
├── clawdbot_scripts.yaml      # All Clawdbot scripts
├── clawdbot_webhooks.yaml     # REST commands, input helpers
├── network_status.yaml        # Ping monitoring, USV
├── ops_automations.yaml       # Battery, unavailable, update alerts
├── security.yaml              # Security status template
├── standards.yaml             # Naming conventions, input helpers
├── system_monitoring.yaml     # CPU, RAM, Load, Disk sensors
├── weather_api_extended.yaml  # REST weather sensors
└── weather_automations.yaml   # Weather alerts
```

## Entity Naming — Matter Migration (KRITISCH)

Die Thermostate liefen frueher ueber Bosch SHC (Zigbee), jetzt ueber **Matter**. Entity-IDs sind anders:

| Alt (Bosch SHC, FALSCH) | Neu (Matter, RICHTIG) |
|---|---|
| `climate.gastezimmer_heizkorper_th` | `climate.gastezimmer_room_climate_contr` |
| `climate.schlafzimmer_heizkorper_th` | `climate.schlafzimmer_room_climate_cont` |
| `climate.badezimmer_heizkorper_th` | `climate.badezimmer_room_climate_contro` |
| `sensor.*_heizkorper_th_temperatur` | `sensor.*_room_climate_contr_temperatur` |

**Matter Entity ID Truncation**: Matter kuerzt lange Entity-IDs ab. Immer in der Entity Registry verifizieren, nie raten.

### Real Entities (aktuelle Installation)

| Typ | Entity ID | Beschreibung |
|-----|-----------|-------------|
| TV (Philips JS) | `media_player.55oled855_12_3` | Philips OLED TV |
| TV (Cast) | `media_player.55oled855_12` | Chromecast auf TV |
| Ambilight | `light.55oled855_12_ambilight` | TV Ambient Light |
| Flur | `switch.eg_flur_licht` | Shelly Plus 1 |
| Vordach | `switch.shellyplus1pm_78ee4cc850bc` | Shelly Plus 1PM |
| Bad | `switch.badezimmer_links_rechts_switch_0/1` | Shelly Plus 2PM |
| Schlafzimmer | `switch.shelly_steckdose_schlafzimmer` | Shelly Plus 2PM |
| Heizung GZ | `climate.gastezimmer_room_climate_contr` | Matter Thermostat |
| Heizung SZ | `climate.schlafzimmer_room_climate_cont` | Matter Thermostat |
| Heizung Bad | `climate.badezimmer_room_climate_contro` | Matter Thermostat |
| Fenster Bad | `binary_sensor.fensterkontakt` | Bosch SHC |
| Fenster GZ | `binary_sensor.fensterkontakt_rechts` | Bosch SHC |
| Fenster SZ | `binary_sensor.fensterkontakt_rechts_2` | Bosch SHC |
| Person | `person.diana` | Mobile App (Samsung S25 Ultra) |

## Voice Assistant / Assist Pipeline

Vollständiges Voice-Setup für HA — STT, Conversation, TTS. Gilt seit HA 2024+.

### Architektur

```
Mobile-App (HA Companion, Wake-Word "Hey Nabu" on-device)
  └─ STT-Engine     (stt.faster_whisper  — lokal via Wyoming)
  └─ Conversation   (conversation.openai_conversation — gpt-4.1, Tool-Calling)
  └─ TTS-Engine     (tts.openai_tts "shimmer" — cloud, oder tts.piper lokal)
```

### Conversation-Entity-ID ≠ Integration-Title (KRITISCH)

Die Conversation-Entity-ID leitet sich vom **Domain + Unterscore-Title** ab, nicht vom UI-Titel:

| Integration-Title (UI) | Conversation-Entity-ID |
|---|---|
| "ChatGPT" | `conversation.openai_conversation` |
| "Claude" | `conversation.anthropic` (voraussichtlich) |
| "Home Assistant" (Default) | `conversation.home_assistant` |

Immer prüfen via `GET /api/states` mit Prefix-Filter `conversation.`, niemals raten. Falsche `agent_id` → `"invalid agent ID"` 400.

### Voice-Pipeline via REST testen

```bash
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  -H "Content-Type: application/json" \
  http://192.168.22.90:8123/api/conversation/process \
  -d '{"text":"Schalte das Flur EG Licht aus","language":"de",
       "agent_id":"conversation.openai_conversation"}'
```

Erwartbare Latenz:
- Reine Konversation (ohne Tool-Call): **~2-3s** mit gpt-4.1
- Tool-Calling (Licht, Szene, Klima): **~6-9s**
- Optimierung: `gpt-4o-mini` ist ~2x schneller, 5x günstiger, leichter Verständnis-Verlust

### Entity-Exposure für Voice — Domain-Whitelist

NICHT alle Entities exponieren, nur steuerbare. Sonst Tool-Call-Verwässerung (LLM bekommt 439 Optionen und wählt schlecht).

**Whitelist** (für Voice-Tool-Exposure verwenden):
```
light, switch, scene, climate, script, media_player, cover, fan, lock
```

**Blacklist** (niemals exponieren für Voice):
```
sensor, binary_sensor, device_tracker, weather, sun, zone,
input_*, automation (triggerbar via script statt direkt)
```

### WebSocket-Pattern für Pipeline + Expose

**`homeassistant.expose_entity` ist KEIN Service** — nicht via REST oder `POST /api/services/...` erreichbar. Nur via WebSocket-Command:

```json
{"id": N, "type": "homeassistant/expose_entity",
 "assistants": ["conversation"], "entity_ids": [...],
 "should_expose": true}
```

Ebenso: `assist_pipeline/pipeline/{list,create,update,set_preferred}` nur via WebSocket.

Script-Pattern (permanent besser in `~/bin/ha-*.py` ablegen):
```python
import os, json, asyncio, websockets
async def main():
    async with websockets.connect("ws://192.168.22.90:8123/api/websocket") as ws:
        await ws.recv()  # auth_required
        await ws.send(json.dumps({"type":"auth","access_token":os.environ["HA_LONG_LIVED_TOKEN"]}))
        assert json.loads(await ws.recv())["type"] == "auth_ok"
        # ... commands hier
asyncio.run(main())
```

Installation der lib (Debian PEP 668-safe):
```bash
python3 -m venv /tmp/hamv && /tmp/hamv/bin/pip install websockets
```

### TTS-Probe via REST funktioniert nicht trivial

`POST /api/tts_get_url` gibt häufig `Extra data` oder leere Response. Zum Audio-Testen besser: im HA-UI unter Settings → Voice Assistants → Pipeline → "Test" klicken, oder echten End-to-End-Test via Companion-App.

## Native LLM-Integrations ab HA 2024+

Große Provider sind seit HA 2024.x **nativ** integriert — **kein HACS mehr nötig** für Conversation-Agents:

| Provider | Handler (für Flow-API) | Subentry |
|---|---|---|
| OpenAI | `openai_conversation` | Conversation + AI Task |
| Anthropic | `anthropic` | Conversation |
| Google Generative AI | `google_generative_ai_conversation` | Conversation |

Installation via REST (statt UI):

```bash
# Flow starten
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" -H "Content-Type: application/json" \
  http://192.168.22.90:8123/api/config/config_entries/flow \
  -d '{"handler":"openai_conversation"}'
# Response enthält flow_id und data_schema (api_key required)

# Key submit
curl -X POST .../flow/<flow_id> -d '{"api_key":"sk-..."}'
```

Subentries haben `llm_hass_api: ["assist"]` → Tool-Calling mit allen exponierten Entities ist automatisch aktiv.

**HACS bleibt nötig für:**
- ElevenLabs TTS (kein natives Integration bis HA 2026.4)
- Spezial-Provider ohne offizielle Integration
- Custom Community-Komponenten

## Modern Action Syntax (HA 2024.8+)

**`service:` ist deprecated. Nutze `action:`:**

```yaml
# RICHTIG (modern)
- action: climate.set_temperature
  target:
    entity_id: climate.gastezimmer_room_climate_contr
  data:
    temperature: 20

# FALSCH (deprecated)
- service: climate.set_temperature
```

## Webhook Patterns (Security-gehaertet)

```yaml
trigger:
  - platform: webhook
    webhook_id: !secret clawdbot_webhook_id  # UUID4, nie Klartext
    local_only: true                          # Nie false ohne Auth
    allowed_methods:
      - POST                                  # Kein GET (CSRF-Risiko)
```

## Performance Patterns

### scan_interval Richtwerte
| Sensor-Typ | Empfehlung | Begruendung |
|---|---|---|
| CPU/RAM/Load | 60s | Aenderungsrate ~1440/Tag bei 30s, unnoetig |
| Docker Status | 600s | Container aendern selten Status |
| REST APIs | 120s | Health Checks, kein Echtzeit noetig |
| Wetter | 600s | API-Rate-Limits |

### Recorder Excludes
Hochfrequente Sensoren aus History ausschliessen:
```yaml
recorder:
  exclude:
    entities:
      - sensor.load_1_min
      - sensor.load_5_min
      - sensor.load_15_min
      - sensor.ram_frei
      - sensor.ram_belegt
      - sensor.home_assistant_uptime
```

### Template Sensor Performance
**FALSCH** (iteriert bei jedem Update ueber ALLE Sensoren):
```yaml
state: >
  {{ states.sensor | selectattr('attributes.device_class', 'eq', 'power') | ... }}
```

**RICHTIG** (explizite Entity-Liste):
```yaml
state: >
  {{ [states('sensor.vordach_beleuchtung_power') | float(0),
      states('sensor.shelly_steckdose_schlafzimmer_power') | float(0)]
     | sum | round(2) }}
```

## Security Patterns

- `secrets.yaml`: chmod 600 (via `docker exec homeassistant chmod 600 /config/secrets.yaml`)
- Webhook-IDs: UUID4 in secrets.yaml, nie Klartext
- `.gitignore`: secrets.yaml, .storage/, *.db*, *.log*
- `ip_ban_enabled: true` + `login_attempts_threshold: <n>` — **Default 5 ist sehr scharf** für aktiv genutzte Setups (Bots, Mobile-Apps, Gateways triggern schnell). Empfehlung:
  - **25** für gemischte Setups mit eigenen Clients (NAS-Standard seit 2026-05-04)
  - **5** nur für reine Headless-Server, die keine externen Auth-Quellen haben
  - alternativ `trusted_networks: [192.168.x.0/24]` für vertrautes LAN — schließt LAN-IPs vom Counter aus, riskanter weil pauschal
- Shell commands: KEINE Template-Variablen aus User-Input (`{{ command }}` = Injection)

### ip_bans.yaml — Entban-Workflow

`config/ip_bans.yaml` wird **nur beim Container-Start** gelesen — Live-Edit ohne Restart bleibt wirkungslos. Korrekte Sequenz:

```bash
# 1. Backup
cp config/ip_bans.yaml config/ip_bans.yaml.bak.$(date +%Y%m%d_%H%M%S)

# 2. Eintrag entfernen ODER ganze Datei leeren (HA toleriert leere Datei)
#    Edit-Tool bevorzugt; oder per Editor

# 3. HA neustarten — Cache wird neu aufgebaut
docker restart homeassistant

# 4. Verify
sleep 15 && curl -s -o /dev/null -w "%{http_code}\n" http://192.168.22.90:8123/
cat config/ip_bans.yaml  # leer oder ohne Ziel-IP
```

Häufige Ursache für unerwarteten Ban: spekulatives Auth-Debugging (siehe Common Mistakes #19).

## Backup Rotation Pattern

```yaml
automation:
  - id: ops_backup_rotation
    trigger:
      - platform: time
        at: "04:30:00"
    action:
      - action: shell_command.backup_cleanup

shell_command:
  backup_cleanup: >
    find /config/backups/ -name "*.tar" -mtime +14 -delete;
    find /config/backups/ -name "*.tar.gz" -mtime +30 -delete
```

## Dashboard Registration

```yaml
lovelace:
  mode: storage
  # Resources ueber UI verwalten (storage-mode)
  dashboards:
    lovelace-system-monitor:
      mode: yaml
      title: System Monitor
      icon: mdi:monitor-dashboard
      show_in_sidebar: true
      filename: dashboards/system_monitor.yaml
```

## Bootstrap-Phase Logging

Logger-Config wird NACH dem Bootstrap geladen. Fruehe Warnings (prompt_loader, pychromecast) koennen nicht ueber `logger:` unterdrueckt werden. Das ist ein bekanntes HA-Verhalten.

## NAS Volume Permissions

`chmod` vom Host funktioniert nicht auf NAS-Volumes (Operation not permitted). Stattdessen:
```bash
docker exec homeassistant chmod 600 /config/secrets.yaml
```

## /config Refactoring-Patterns

Gewachsene HA-Configs (6+ Monate Iteration) sammeln Duplikate, Backup-Dateien und verwaiste Dashboards. Saubere Konsolidierungs-Patterns:

### Git-Repo in /config/.git nutzen
Die HA-Config auf dieser NAS ist ein Git-Repo. **Jeder Refactoring-Durchgang beginnt mit:**
```bash
ssh Jahcoozi@192.168.22.90 docker exec homeassistant sh -c \
  "cd /config && git add -A && git -c user.name=auto -c user.email=auto@localhost commit -m 'pre-cleanup snapshot <datum>'"
```
Das Safety-Net macht jeden späteren Schritt reversibel per `git revert` oder `git checkout <hash> -- <datei>`.

### Zero-Delete-Cleanup via `_attic/`
Statt Dateien zu löschen:
```bash
mkdir -p /config/_attic/{dashboards,packages,root}
mv /config/dashboards/smart_home_v3.yaml /config/_attic/dashboards/
mv /config/packages/*.pre-fix /config/_attic/packages/
```
- Psychologisch: User sieht "entfernt" ohne Verlustangst
- Praktisch: 30s bis zum Zurück-Move falls doch gebraucht
- Nach 3-6 Monaten in zweiter Cleanup-Runde endgültig entscheiden

### YAML-Edit via NAS-CIFS-Mount (Yoga7, BEVORZUGT)
Auf Yoga7 ist der NAS-Docker-Share via CIFS gemountet (siehe `nas-docker-mount.service`):
- `/mnt/nas/docker/home-assistant/config/` ↔ `/volume1/docker/home-assistant/config/` auf NAS
- Direkter Read/Write/Edit mit allen lokalen Tools, kein SSH/Docker-Roundtrip nötig
- Beispiel: `cp /tmp/stawag_strom.yaml /mnt/nas/docker/home-assistant/config/packages/`
- YAML-Validierung lokal: `python3 -c "import yaml; yaml.safe_load(open('...'))"`
- Anschließend `check_config` + Restart via REST-API (siehe Common Commands oben)
- Restriktion: NAS-Home-Verzeichnis (`/volume1/homes/Jahcoozi/...`) ist NICHT gemountet — nur der Docker-Share

### YAML-Edit via SSH-Round-Trip (Fallback)
Wenn NAS-Mount nicht verfügbar (andere Maschine, Mount kaputt):
```bash
# Pull
ssh Jahcoozi@192.168.22.90 'docker exec homeassistant cat /config/configuration.yaml' > /tmp/ha-config.yaml
# ...lokal mit Edit-Tool/Editor bearbeiten...
# Push
cat /tmp/ha-config.yaml | ssh Jahcoozi@192.168.22.90 'docker exec -i homeassistant tee /config/configuration.yaml > /dev/null'
```
Vorteile: präzises Editing mit strukturierten Tools, kein `sed` auf Mehrzeiliges. Nachteil: SSH-Key zum NAS oft nicht eingerichtet → Password-Prompt blockiert Automation.

### HA-Restart via REST-Service
```bash
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  http://192.168.22.90:8123/api/services/homeassistant/restart -d '{}'
```
Sauberer als `docker restart homeassistant` (sauberer Shutdown, kein Container-Crash-State), ~30s bis wieder up.

### Storage-mode Default-Dashboard
Das Default-Dashboard (`.storage/lovelace`) erscheint **zusätzlich** zu allen in `configuration.yaml` konfigurierten YAML-Dashboards in der Sidebar. Lässt sich NICHT aus YAML entfernen — nur via HA-UI:
`Settings → Dashboards → Overview (Default) → Hide in sidebar`

### Voice-Pipeline-Persistenz über Restart
Die Assist-Pipeline liegt in `.storage/assist_pipeline.pipelines` + `.storage/core.entity_registry`. Full-Restart (siehe oben) ändert daran nichts. YAML-Refactoring in `/config/*.yaml` ist risikoarm, solange `.storage/` nicht angefasst wird.

### Entity-Registry direkt editieren funktioniert NICHT
`.storage/core.entity_registry` mit `python3` oder Editor zu ändern und HA neu zu starten **überlebt den Restart nicht** — HA pflegt die Registry in-memory und schreibt beim Boot/State-Sync zurück, was das gesamte File überschreiben kann. Manuelle JSON-Edits sind nur valide, wenn HA komplett gestoppt ist (`docker stop homeassistant`, was via REST nicht geht).

**Sauberer Weg für entity_id-Renames** — bei laufender HA via WebSocket-Command `config/entity_registry/update`:
```python
# In WebSocket-Helper (siehe REST-Auth Sektion oben):
await ws.send(json.dumps({
    "id": msg_id,
    "type": "config/entity_registry/update",
    "entity_id": "sensor.haus_verbrauch_monat_gemessen",   # alt
    "new_entity_id": "sensor.haus_verbrauch_monat",         # neu
}))
```
Das Update ist atomic, persistent, überlebt Restart. Erlaubt umfassenden Rename ohne YAML-Trickserei (`unique_id`-Match-Verhalten).

Andere nützliche WebSocket-Commands für Registry:
- `config/entity_registry/remove` — Eintrag löschen (re-creates beim nächsten Reload aus YAML)
- `config/entity_registry/list` — alle Einträge
- `config/entity_registry/get` — einzelner Eintrag mit allen Properties
- `template.reload` (via `call_service`) — Template-Sektion neu lesen ohne Full-Restart

## check_config — Warnungs-Zeilennummern-Versatz

HAs `check_config` meldet bei duplicate-key-Warnings oft Zeilennummern, die **um 1-2 Zeilen vom echten Vorkommen abweichen**. Beispiel:
```
WARNING: duplicate key "mode". Check lines 185 and 187
```
Tatsächliche mode-Zeilen waren 186 und 188. Verifikation vor Fix:
```bash
grep -n "^  mode:\|^- id:" automations.yaml
```
Dann sed-delete auf die ECHTEN Zeilen. `sed -i "186d;212d;289d;327d" datei` matcht gegen Original-Zeilennummern (sed iteriert die Datei einmal, Reihenfolge im Ausdruck egal).

## Zero-Warnings-Discipline

Ziel für `check_config`-Output: **komplett leer** (nicht nur "error-frei").
- Jede Warning = Rauschen, das legitime Fehler versteckt
- Nach erfolgreichem Cleanup: `python3 -m homeassistant --script check_config --config /config 2>&1` sollte nur `Testing configuration at /config` zeigen
- Rauschen-Unterdrückung ist wertvoller als der einzelne Fix — zukünftige Warnings sind sofort als "neu" erkennbar

## Helper-Entities (input_*)

### `initial:` ist nur bei input_number/input_boolean/input_text
- `input_number`/`input_boolean`/`input_text`: `initial:` setzt Wert beim **allerersten Start** (wenn keine .storage-Datei existiert). Bei späteren Restarts gewinnt der gespeicherte Wert.
- `input_datetime`: hat **kein** `initial:` Feld. Frisch deployed = State `"unknown"` bis zum ersten `input_datetime.set_datetime`-Service-Call.
- Konsequenz: Template-Sensoren, die `as_datetime(states('input_datetime.x'))` nutzen, müssen den Fall `'unknown'/'unavailable'/''` behandeln, sonst `TypeError`.

### Initial-Werte nach Deploy via REST setzen
Nach erstem Restart die Datums-Helper befüllen:
```bash
source ~/.config/homeassistant/env
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" -H "Content-Type: application/json" \
  "$HA_URL/api/services/input_datetime/set_datetime" \
  -d '{"entity_id":"input_datetime.stawag_vertragsende","date":"2026-12-31"}'
# Bei has_time: true zusätzlich "time":"HH:MM:SS", oder "datetime":"YYYY-MM-DDTHH:MM:SS"
```
Werte sind nach dem Setzen in `.storage/` persistiert, überleben Restarts.

### utility_meter bleibt `unknown` bis zum ersten Source-Tick
- `utility_meter` mit Source-Sensor (`state_class: total_increasing`) startet **nicht spontan** mit Wert 0
- State bleibt `unknown` bis sich der Source-Sensor ändert (= mindestens ein kWh-Tick = ~5–10 W für mehrere Minuten)
- Bei Geräten in Standby (0 W) kann das Stunden bis Tage dauern
- **Konsequenz für Templates**: jede Referenz auf utility_meter braucht `| float(0)` als Fallback, sonst `TypeError` oder Sensor wird `unknown`
- **Lovelace**: `unknown` als „0 kWh" oder „—" rendern, nicht als Fehler

### state_class ist Pflicht für Energy-Dashboard-Fähigkeit
Aggregat-Sensoren, die im Energy Dashboard als Grid-Source oder Long-Term-Statistic dienen sollen, brauchen **beide** Felder:
```yaml
- name: "Haus Verbrauch Lifetime"
  unique_id: haus_verbrauch_lifetime
  unit_of_measurement: "kWh"
  device_class: energy            # Klassifiziert als Energie-Sensor
  state_class: total_increasing   # PFLICHT für Long-Term-Statistics + Energy Dashboard
  state: >
    {% set sensors = [...] %}
    {{ (sensors | map('states') | map('float', 0) | sum) | round(3) }}
```
- `device_class: energy` allein → Sensor wird gespeichert, aber NICHT in Statistics-Tabelle
- Ohne `state_class` kann der Sensor nicht als Grid-Source im Energy Dashboard ausgewählt werden
- Für monoton steigende Summen: `total_increasing`. Für resetbare Zähler: `total`. Niemals `measurement` für kWh

### Slugify-Verhalten (Entity-ID aus `name:`)
HA bildet entity_ids aus `name:` per Slugify — **Umlaute werden als reines ASCII gemappt, nicht ausgeschrieben**:
| name (Quelle) | entity_id (Ergebnis) |
|---|---|
| `Stawag Tage bis Kündigungsfrist` | `stawag_tage_bis_kundigungsfrist` (ü→u, **nicht** ue) |
| `Stawag — Ablesetermin in 2 Tagen` | `stawag_ablesetermin_in_2_tagen` (Bindestrich raus, Zahl bleibt) |
| `Wohnzimmer (oben)` | `wohnzimmer_oben` |

Vor REST-Aufrufen mit raten: lieber `GET /api/states` filtern mit Prefix:
```bash
curl -s -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" "$HA_URL/api/states" \
  | python3 -c "import sys,json; [print(s['entity_id']) for s in json.load(sys.stdin) if 'stawag' in s['entity_id']]"
```

## Energy Dashboard (HA 2026+)

### Schema-Änderung in 2026.4 — Grid-Source nur noch via UI
Das Schema von `energy/save_prefs` hat sich in HA 2026.4 geändert:
- Alte Felder `flow_from`/`flow_to` werden mit `extra keys not allowed` abgelehnt
- Neue Felder (`import_meter`, `power_sensor`, etc.) sind ebenfalls schemafremd, exakte Struktur intransparent
- Reverse-Engineering via Trial-and-Error trifft das aktuelle Schema nicht
- **Pragmatisch: Grid-Source via UI konfigurieren** — Settings → Dashboards → Energie → "Stromnetz hinzufügen"

WebSocket bleibt aber für **`device_consumption`** zuverlässig nutzbar:
```python
# Funktioniert in HA 2026.4:
{
  "type": "energy/save_prefs",
  "energy_sources": [],
  "device_consumption": [
    {"stat_consumption": "sensor.shelly_X_total_energy"},
    ...
  ],
}
```
Neu in HA 2026+: `device_consumption_water` als separates Feld für Wasser-Tracking.

### Voraussetzungen für Sensoren im Energy Dashboard
- `device_class: energy` + `state_class: total_increasing` (siehe Helper-Entities Sektion)
- Long-Term-Statistics aktiv (default seit HA 2022.4)
- Verifikation via WebSocket `recorder/list_statistic_ids`:
  ```python
  await ws.send(json.dumps({"id": N, "type": "recorder/list_statistic_ids",
                            "statistic_type": "sum"}))
  # Sensor muss in Result-Liste auftauchen
  ```

### Grid-Source vs. Individuelle Geräte — Mehrwert
| Bereich | Zeigt | Voraussetzung |
|---|---|---|
| **Grid Source** (Strom-Karte oben) | Verbrauch + €-Kosten in EUR | kWh-Sensor mit `total_increasing` + Tarif-Sensor |
| **Individuelle Geräte** (Verteilungs-Karte) | nur kWh-Verteilung über Zeit | kWh-Sensor mit `total_increasing` |
| Solar / Battery / Gas / Wasser | je nach Sektion | spezifische Sensoren |

Daher die übliche **A+B-Empfehlung** (siehe Vertragsdaten-Pattern unten): Energy Dashboard für Standardvisualisierung, Custom Template-Package für €-Aggregate.

## Vertragsdaten-Package-Pattern

Statische Verträge (Strom/Gas/Internet/Mobilfunk) als wiederverwendbares Package-Schema in `config/packages/<anbieter>_<sparte>.yaml`:

| Block | Zweck | Begründung |
|---|---|---|
| `input_number.<anbieter>_arbeitspreis_netto` | variable Tarifkomponenten | Tarif ändert sich → UI-Edit ohne YAML-Restart |
| `input_number.<anbieter>_grundpreis_netto_jahr` | Grundpreis pro Jahr netto | – |
| `input_number.<anbieter>_abschlag_brutto` | Monatlicher Abschlag | Cashflow-Tracking, kann vom Anbieter-Vorschlag abweichen |
| `input_number.<anbieter>_zaehlerstand_basis` | Zählerstand bei Abrechnung | Referenz für Verbrauchs-Templates |
| `input_datetime.<anbieter>_vertragsende` | Vertragsende | Tage-bis-Sensor + Status-Templating |
| `input_datetime.<anbieter>_kuendigungsfrist` | letzter Kündigungstermin | Reminder-Trigger |
| `input_datetime.<anbieter>_ablesetermin` | nächster Ablesetermin | Jahres-Reminder |
| `template.sensor.<anbieter>_*_brutto` | Brutto-Berechnungen aus Netto×1.19 | Single Source of Truth = netto-Felder |
| `template.sensor.<anbieter>_tage_bis_*` | Countdown bis Datum | Dashboard + Automation-Trigger |
| `template.sensor.<anbieter>_vertrag_status` | Stati `läuft/möglich/dringend/verpasst` | UI-Statusbadge |
| `automation.<anbieter>_kuendigung_reminder` | Push an Tag 90/60/30/14/7/1 | Verhindert Auto-Verlängerung |
| `automation.<anbieter>_ablesetermin_reminder` | Push am 09.01. (z. B.) | Manuelle Ablesung erinnern |

**Bewusst NICHT ins Package:**
- IBAN, BIC, SEPA-Mandat, Bankverbindung (PII, gehören nicht in YAML)
- Kundennummer/Vertragskonto im Klartext (allenfalls in `secrets.yaml` falls überhaupt nötig)
- Klartext-Adresse der Lieferstelle, falls anders als Wohnsitz

**Implementiert (Beispiele):**
- `packages/stawag_strom.yaml` (16 Entities, deployed 2026-05-02) — Stromtarif + Vertragsdaten
- `packages/energy_costs.yaml` (22 Entities, deployed 2026-05-02) — Verbrauch+Kosten der Shelly-PMs gegen Stawag-Tarif

### Variante A + B Doppel-Pattern (Verbrauch + Kosten)
Vertragsdaten allein zeigen den Tarif. Für **konkreten Verbrauch + €** ergänzt man:

**Variante A — HA Energy Dashboard** (UI/WebSocket):
- `device_consumption` mit den vorhandenen Geräte-Energy-Sensoren (z. B. Shelly PM `*_total_energy`)
- Grid-Source via UI (Schema-Änderungen 2026.4) mit Tarif-Sensor als Preisreferenz
- Liefert: Tag/Woche/Monat/Jahr-Verlauf, Geräte-Verteilung, €-Kosten in Standard-Karte

**Variante B — Custom Template-Package**:
- `utility_meter` pro Gerät (cycle: monthly) → Monatszähler
- `template.sensor.<gerät>_kosten_lifetime` = `total_energy × tarif`
- `template.sensor.<gerät>_kosten_monat` = `utility_meter × tarif`
- Aggregat: `haus_verbrauch_lifetime/monat` (mit `state_class: total_increasing`!)
- Aggregat: `haus_kosten_monat_total` = Arbeitspreis-Anteil + Grundpreis
- Differenz-Sensor: `kosten_monat_total - abschlag` → Status („unter/über Abschlag")
- Liefert: €-Aggregate, Lovelace-tauglich, Abschlags-Vergleich

A+B kombinieren — A für Standard-Visualisierung, B für €-Logik die Energy Dashboard nicht abdeckt (Abschlags-Vergleich, Geräte-Kosten).

## Common Mistakes to Avoid

1. **Container-Name**: `homeassistant` (kein Bindestrich!)
2. **service: statt action:**: Deprecated seit HA 2024.8
3. **Entity-IDs raten**: Immer Entity Registry pruefen (Matter kuerzt IDs ab)
4. **Webhook local_only: false**: Sicherheitsrisiko, immer true oder Auth
5. **states.sensor Iteration in Templates**: Performance-Killer, explizite Listen nutzen
6. **Condition mitten in Sequence**: Blockt ALLE nachfolgenden Actions, nutze `if/then`
7. **Placeholder-Entities**: Automationen fuer nicht-existierende Geraete disablen
8. **agent_id raten**: Conversation-Entity-ID != Integration-Title. "ChatGPT"-Integration hat `conversation.openai_conversation`, nicht `conversation.chatgpt`. Immer via `GET /api/states` prüfen.
9. **Expose via REST-Service**: `homeassistant.expose_entity` existiert NICHT als Service-Call. Exposure (und Pipeline-Config) gehen NUR über WebSocket.
10. **HACS-Reflex für OpenAI/Anthropic**: Beide Provider sind seit HA 2024+ nativ eingebaut. HACS nur noch für Nischen-Integrationen (z.B. ElevenLabs TTS).
11. **check_config Zeilennummer direkt trauen**: Zeilen-Versatz 1-2 möglich. Immer mit `grep -n` verifizieren bevor sed-basiertes Fixen.
12. **`sh -c` mit runden Klammern in Kommentaren**: `sh: syntax error: unexpected "("`. In SSH-Commands die durch `sh -c` laufen KEINE Klammern in Echo-Texten. Alternativen: eckige Klammern oder Bash (`bash -c` toleriert mehr).
13. **Storage-mode Default-Dashboard aus YAML entfernen wollen**: Geht nicht — nur via HA-UI (siehe /config-Refactoring-Patterns).
14. **Memory-Fakten als Ground Truth behandeln**: Config-Realität driftet — "laut Memory sollte X so sein" ist Hypothese. Vor Aktionen messen (via REST oder WebSocket), Memory bei Abweichung korrigieren.
15. **Token via `printf`/`echo` schreiben**: Token landet in Shell-History und ggf. Tool-Logs. IMMER `nano <datei>` nutzen, danach `chmod 600`. Bei Verdacht auf Leak: sofort revoken (HA UI → Profil → Sicherheit).
16. **SSH zum NAS als Default-Edit-Weg**: Auf Yoga7 ist `/mnt/nas/docker/home-assistant/config/` via CIFS gemountet — direkt schreiben statt SSH-Roundtrip. SSH-Key ist auf NAS oft nicht eingerichtet, Password-Prompt blockt Automation.
17. **`input_datetime` mit `initial:`-Feld konfigurieren**: Existiert nicht. Werte nach erstem Restart via `input_datetime/set_datetime` REST-Service setzen, sonst bleiben abhängige Template-Sensoren auf `unknown`.
18. **Slugify-Annahme `ü → ue`**: Falsch — HA mappt Umlaute zu reinem ASCII (`ü → u`, `ö → o`, `ß → ss`). Vor REST-Aufrufen entity_id mit `GET /api/states` verifizieren.
19. **`.storage/core.entity_registry` direkt editieren**: Überlebt Restart NICHT — HA überschreibt die Datei beim Boot/Sync. Für Renames: WebSocket `config/entity_registry/update` mit `new_entity_id` (atomic, persistent). Manuelle JSON-Edits nur bei vollständig gestoppter HA (`docker stop`).
20. **HA 2026.4 Energy-Schema raten**: `flow_from`/`flow_to`/`import_meter` werden alle abgelehnt mit `extra keys not allowed`. Schema-Reverse-Engineering ist Sackgasse — Grid-Source via UI konfigurieren. Nur `device_consumption` ist via WebSocket zuverlässig setzbar.
21. **utility_meter braucht ersten Source-Tick**: Bleibt `unknown` bis sich der Source-Sensor ändert — bei 0 W Standby kann das Stunden dauern. Templates müssen `| float(0)` Fallback haben, Lovelace-Karten `unknown` als „—" rendern.
22. **`device_class: energy` ohne `state_class`**: Sensor erscheint NICHT als Wahlmöglichkeit im Energy Dashboard. Beide setzen — `state_class: total_increasing` für Long-Term-Statistics-Aufnahme.
23. **Tote Auth-Varianten beim 401-Debug durchprobieren**: NIEMALS spekulativ `x-ha-access`-Header, `?api_password=`-Query oder andere Legacy-Auth-Methoden testen, wenn HA mit 401 antwortet. Diese Varianten sind seit modernen HA-Versionen entfernt — jeder Fehlversuch zählt gegen `login_attempts_threshold` und schreibt die Source-IP in `ip_bans.yaml`. Besonders gefährlich für Bot-/Gateway-IPs (z.B. moltbot 192.168.22.206), die dann von HA komplett abgeschnitten sind, bis ip_bans.yaml + HA-Restart Cleanup macht. **Richtig**: Ausschließlich `Authorization: Bearer <Long-Lived-Token>` testen. Vor weiteren Tests: `docker logs homeassistant | grep -i "login attempt"` lesen und ggf. `cat config/ip_bans.yaml` prüfen.
24. **check_config-Output ohne Diff bewerten**: `check_config` zeigt oft vorbestehende, nicht-blockierende Fehler (z.B. `entity_category` für `command_line`-Sensoren) — die blockieren den Restart NICHT und sind keine Folge des aktuellen Edits. Nicht abbrechen ohne zu klären: war der Fehler vor meiner Änderung schon im Output? Wenn ja: weiter mit Restart, Fehler separat tracken. Wenn nein: rollback und neu prüfen.

## Cross-Machine-Limitation (NAS-Instanz)

NAS (`192.168.22.90`) kann andere Hosts im Setup **nicht direkt steuern**:
- Clawbot VM (`192.168.22.206`, User `moltbotadmin`): kein SSH-Key auf NAS hinterlegt, Tailscale-CLI nicht installiert, Hostname `moltbot` lokal nicht aufgelöst
- Yoga7, Windows-PC: kein SSH-Setup vom NAS aus

**Konsequenz**: `systemctl --user restart …` oder ähnliche Befehle auf moltbot/Yoga7 muss der User selbst ausführen — oder die jeweilige Instanz-Skill-Session (`clawdbot-admin`, `yoga7-admin`, `windows-admin`) übernimmt es vor Ort. Vor Vorschlag von Cross-Machine-Aktionen: explizit kennzeichnen, dass NAS-Claude das nicht selbst durchführen kann.
