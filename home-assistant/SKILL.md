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

# Einzelne Config-Entry reloaden (kein HA-Restart nötig)
# Anwendung: Integration steckt nach Backend-Restart im Fehler-Zustand
ENTRY_ID=$(docker exec homeassistant python3 -c "
import json
with open('/config/.storage/core.config_entries') as f:
    [print(e['entry_id']) for e in json.load(f)['data']['entries'] if e.get('domain')=='ollama']")
curl -X POST -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  "$HA_URL/api/config/config_entries/entry/$ENTRY_ID/reload"
# Erwartete Antwort: {"require_restart":false}

# Reload-Erfolg verifizieren — state muss "loaded" sein
curl -s -H "Authorization: Bearer $HA_LONG_LIVED_TOKEN" \
  "$HA_URL/api/config/config_entries/entry?domain=ollama" \
  | python3 -c "import sys,json; [print(e['state']) for e in json.load(sys.stdin)]"

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

### Token-Fallback-Quellen (wenn `~/.config/homeassistant/env` fehlt)

Auf NAS oder fremder Maschine ohne lokales Token-Env: bereits existierende Long-Lived Tokens liegen in anderen Service-Configs:

| Pfad | Variable | Owner |
|---|---|---|
| `/volume1/docker/n8n/.env` | `HA_TOKEN` | n8n-User (clawdbot) |
| `/volume1/docker/moltbot/.env` | `HOMEASSISTANT_TOKEN` | openwebui-User |

`.storage/auth` enthält **nur Hash-Listen** der Tokens, nicht den JWT — Revoke geht damit, aber nicht Re-Use. Über die existierenden Service-Tokens kann man ad-hoc REST-Calls absetzen ohne neues Token in der UI erzeugen zu müssen.

```bash
TOKEN=$(grep "^HA_TOKEN=" /volume1/docker/n8n/.env | cut -d= -f2-)
curl -s -H "Authorization: Bearer $TOKEN" http://192.168.22.90:8123/api/config/...
```

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

### Pipeline-Storage: exakte JSON-Keys + „kopflose" Pipeline

`.storage/assist_pipeline.pipelines` → `data.items[]` + `data.preferred_item` (NICHT `pipelines` / `preferred_pipeline` — falsche Keys liefern still `None` und täuschen „keine Pipeline" vor). Jedes Item: `conversation_engine`, `stt_engine`, `tts_engine`, `tts_voice`, `wake_word_entity`, `wake_word_id`, `prefer_local_intents`.

**Kopflose Pipeline:** `conversation_engine` kann auf einen **nicht existierenden** Agenten zeigen (z.B. `conversation.ollama_conversation`, wenn die Ollama-Integration zwar angelegt, aber ohne Modell konfiguriert ist → es wird gar kein Conversation-Entity erzeugt). Folge: Gerätebefehle laufen noch über lokale Intents (`prefer_local_intents: true`), aber freies „mit dem Assistenten reden" schlägt **still** fehl. Prüfen: zeigt `preferred_item.conversation_engine` auf ein real existierendes `conversation.*`-Entity (Recorder/REST, nicht raten)?

**Refactor-Hygiene (Dangling References):** Beim Entfernen/Umbenennen von Entities AUCH `homeassistant.exposed_entities`, Automations-Trigger und Dashboard-Refs mitziehen — sonst zeigt Voice auf tote Entities (real: „hey jarvis, Flurlicht an" war auf gelöschtes `light.flur_eg` exponiert statt auf das lebende `switch.eg_flur_licht`). Klassisch „unsichtbar kaputt".

**Template-Rebind-Caveat:** Ein neuer `template`-Sensor reclaimt eine entity_id NICHT, wenn ein Waisen-Eintrag einer **anderen Platform** (z.B. alter `rest`-Sensor) den Slug noch hält → der neue bekommt `_2`. Fix: im Stop-Fenster den Waisen-Registry-Eintrag löschen, dann übernimmt der Template-Sensor die kanonische entity_id (Automationen/Dashboards bleiben unverändert).

### Voice-Satellit via ESPHome (freihändiges Wake-Word)

Der openWakeWord-Service allein triggert NICHTS — es braucht eine Audioquelle. Ohne registriertes `assist_satellite`-Entity gibt es kein freihändiges „hey jarvis", nur Push-to-talk in der App (Assist-Knopf).
- **Server-WW** (M5Stack Atom Echo, ESP32 ohne PSRAM, ~17 €): Gerät streamt Audio, das vorhandene `wyoming-openwakeword` erkennt das Wake-Word. `voice_assistant: { use_wake_word: true }` + `on_client_connected: voice_assistant.start_continuous`.
- **On-device WW** (HA Voice PE / ESP32-S3-Box, mit PSRAM): `micro_wake_word` (Modell `hey_jarvis`) läuft lokal auf dem Chip → weniger Netz-Last, niedrigere Latenz, robustere Erkennung. Voice PE ist adopt-and-go (offizielle Firmware, kein Hand-YAML).
- Config IMMER vor dem Flashen validieren: `docker exec esphome esphome config /config/<datei>.yaml` (fängt Versions-Drift ab, ESPHome-Dashboard auf :6052).
- **2026.5-Falle:** `speaker: { platform: i2s_audio }` akzeptiert kein `mode: mono` mehr (Mono ist Default; Zeile entfernen).

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

## Jinja-Templates in YAML-Heading-Cards (Whitespace-Falle)

Heading-Cards mit zeitabhängigen Begrüßungen (oder beliebigen Conditional-Texts) erzeugen sichtbare Leerzeichen-Artefakte, wenn YAML-Folded-Scalar `>-` mit Jinja-Blöcken kombiniert wird ohne Whitespace-Control.

**Problem:** `>-` faltet jede Newline zu einem Space. Im Template entstehen dann Spaces VOR/NACH den Block-Tags, die als Output erhalten bleiben:

```yaml
# FALSCH — rendert " Hallo " (führende und nachfolgende Spaces)
heading: >-
  {% set h = now().hour %}
  {% if h < 6 %}Gute Nacht
  {% elif h < 14 %}Hallo
  {% else %}Guten Abend{% endif %}
```

Bei `heading_style: title` sieht das eingerückt/asymmetrisch aus — User-feedback: "Überschrift sieht seltsam aus".

**Fix:** Jinja-Whitespace-Marker `{%- -%}` in jeder Branch — entfernt Whitespace links/rechts vom Tag:

```yaml
# RICHTIG — rendert "Hallo" sauber
heading: >-
  {%- set h = now().hour -%}
  {%- if h < 6 %}Gute Nacht
  {%- elif h < 14 %}Hallo
  {%- else %}Guten Abend{% endif -%}
```

Verify offline (vor HA-Reload):
```bash
docker exec homeassistant python3 -c "
import yaml
from jinja2 import Environment
with open('/config/dashboards/home.yaml') as f:
    d = yaml.safe_load(f)
h = d['views'][0]['sections'][0]['cards'][0]['heading']
env = Environment()
for hour in [3, 8, 12, 16, 20, 23]:
    env.globals['now'] = lambda hh=hour: type('N',(),{'hour':hh})()
    print(repr(env.from_string(h).render()))
"
```

YAML-Mode-Dashboards aktualisieren sich ohne HA-Restart — Browser-Hard-Refresh (`Ctrl+Shift+R`) reicht.

## Custom Cards & card_mod Design Patterns

### tap_action für `button.*`-Entities — NIEMALS `toggle`

`button`-Entities haben nur **eine** Service-Aktion: `button.press`. Es gibt KEIN `button.toggle` und KEIN `button.turn_on/off`. `tap_action: { action: toggle }` auf einer Button-Card macht UI-seitig nichts (still failure), weil HA den Service nicht findet — Codex/Review-Hooks fangen das, der User sieht aber nur eine tote Card.

```yaml
# FALSCH — Button reagiert nicht
- type: custom:mushroom-entity-card
  entity: button.klimaanlage_sz_create_data_archive
  tap_action: { action: toggle }

# RICHTIG — modern syntax (HA 2024.8+)
- type: custom:mushroom-template-card
  primary: SZ Diagnose-Export
  icon: mdi:file-export
  tap_action:
    action: perform-action
    perform_action: button.press
    target:
      entity_id: button.klimaanlage_sz_create_data_archive
    confirmation:
      text: Diagnose-Archiv erstellen?
```

**Faustregel pro Entity-Domain:**

| Domain | `toggle` erlaubt? | Korrekte Action |
|--------|-------------------|-----------------|
| `switch.*` | ✅ ja | `toggle` oder `switch.turn_on/off` |
| `light.*` | ✅ ja | `toggle` |
| `input_boolean.*` | ✅ ja | `toggle` |
| `button.*` | ❌ nein | `perform-action: button.press` |
| `scene.*` | ❌ nein | `perform-action: scene.turn_on` |
| `script.*` | ❌ nein | `perform-action: script.<name>` oder `script.turn_on` |
| `climate.*` | ❌ nein | `perform-action: climate.set_hvac_mode` etc. |

### State-aware card_mod-Animationen (Pflicht bei Glow/Pulse)

card_mod-Styles werden **unkonditional** angewendet, solange kein Jinja drumrum steht. Eine Card mit `animation: pulse infinite` pulsiert auch dann, wenn das Gerät aus ist — das verwirrt den User („warum pulsiert SZ obwohl die Klima aus ist?").

card_mod akzeptiert Jinja **direkt im `style:`-Block**. Das ist der saubere Hebel:

```yaml
card_mod:
  style: |
    {% set s = states('climate.klimaanlage_sz_klimaanlage') %}
    {% set on = s not in ['off','unavailable','unknown','none'] %}
    {% set heat = s == 'heat' %}
    {% if heat %}{% set rgb = '255,140,60' %}
    {% else %}{% set rgb = '80,180,255' %}{% endif %}
    ha-card {
      {% if on %}
      background: linear-gradient(140deg, rgba({{ rgb }},0.22) 0%, rgba(20,30,50,0.78) 100%) !important;
      box-shadow: 0 0 32px rgba({{ rgb }},0.22) !important;
      animation: pulse 4.5s ease-in-out infinite;
      {% else %}
      background: linear-gradient(140deg, rgba(40,45,55,0.45) 0%, rgba(28,32,42,0.65) 100%) !important;
      filter: grayscale(40%) brightness(0.82);
      /* keine animation: → ruhiger Off-State */
      {% endif %}
    }
    {% if on %}
    @keyframes pulse {
      0%,100% { box-shadow: 0 0 28px rgba({{ rgb }},0.18); }
      50%     { box-shadow: 0 0 48px rgba({{ rgb }},0.42); }
    }
    {% endif %}
```

Wichtig: `not in ['off','unavailable','unknown','none']` — nicht nur `!= 'off'`. Sonst pulsiert die Card auch bei Cloud-Verbindungsabbruch.

### `config.entity` als DRY-Hebel in card_mod

In Mushroom-Cards referenziert `config.entity` im Jinja die Entity der jeweiligen Card. Damit lässt sich der gleiche YAML-Anchor für viele Tiles wiederverwenden:

```yaml
- type: custom:mushroom-entity-card
  entity: switch.klimaanlage_sz_health_mode
  card_mod: &active_tile
    style: |
      ha-card {
        background: {% if is_state(config.entity, 'on') %}
          linear-gradient(135deg, rgba(120,80,200,0.30), rgba(60,40,100,0.50))
        {% else %}
          rgba(28,32,42,0.55)
        {% endif %} !important;
      }
- type: custom:mushroom-entity-card
  entity: switch.klimaanlage_sz_silent_modus
  card_mod: *active_tile   # gleicher Anchor, anderes Switch
```

### Bubble-Card `card_type: climate` crasht bei fehlender Entity

Wenn die referenzierte Entity nicht existiert oder im `unavailable`-State noch nie `attributes` hatte, wirft die Bubble-Card im Browser:

```
TypeError: Cannot read properties of undefined (reading 'attributes')
```

und nimmt das gesamte Dashboard mit (weißer Bildschirm). Schutz vor First-Render:

1. **Vor Rollout**: Entity-Registry prüfen, dass `climate.X` existiert UND mindestens einmal initialisiert wurde
2. **Beim Build mit Platzhaltern**: Cards in `type: conditional`-Wrapper packen, der State auf `not in ['unavailable','unknown']` prüft
3. **Setup-Banner**: bei fehlender Entity stattdessen `type: markdown` mit Setup-Anleitung rendern

### Glassmorphism-Standard-Stack

Wiederverwendbares card_mod-Setup für „Apple Liquid Glass"-Look — funktioniert konsistent für Bubble, Mushroom, mini-graph, ApexCharts:

```yaml
ha-card {
  background: linear-gradient(135deg, rgba(20,28,42,0.78) 0%, rgba(28,40,60,0.62) 100%) !important;
  backdrop-filter: blur(22px) saturate(170%);
  -webkit-backdrop-filter: blur(22px) saturate(170%);
  border: 1px solid rgba(255,255,255,0.08) !important;
  border-radius: 22px !important;
  box-shadow: 0 10px 30px rgba(0,0,0,0.40) !important;
}
```

**Mode-Coloring-Palette** (für climate/state-reactive Themes — als RGB-Triple, in `rgba(...,alpha)` einsetzbar):

| Modus | RGB-Triple |
|-------|------------|
| `cool` | `80,180,255` (Eisblau) |
| `heat` | `255,140,60` (Orange) |
| `dry` | `220,200,80` (Bernstein) |
| `fan_only` | `100,230,220` (Türkis) |
| `auto` | `180,120,255` (Lila) |
| `off`/disabled | `120,130,150` (Neutralgrau) |

Performance-Hinweis: `backdrop-filter: blur(...)` kostet GPU — bei >15 gleichzeitigen Glass-Cards auf einem View ist Frame-Drop auf Tablets sichtbar. Blur-Radius reduzieren oder Cards weiter unten ohne Blur rendern.

## hOn / Haier Custom Integration (HA 2026.x-Patches)

`Andre0512/hon` (Custom Component für Haier hOn-Klima/Geräte) ist seit Aug 2024 inaktiv. v0.14.0 bricht in HA 2026.x mit zwei Breaking-Changes der HA-Core-API:

### Patch 1: `HomeAssistantType` entfernt → `HomeAssistant`

In 12 .py-Dateien (`__init__.py`, `binary_sensor.py`, `button.py`, `climate.py`, `config_flow.py`, `entity.py`, `fan.py`, `light.py`, `number.py`, `select.py`, `sensor.py`, `switch.py`):

```bash
cd /config/custom_components/hon
sed -i 's/from homeassistant\.helpers\.typing import HomeAssistantType/from homeassistant.core import HomeAssistant/g' *.py
sed -i 's/HomeAssistantType/HomeAssistant/g' *.py
```

### Patch 2: `async_forward_entry_setup` (Singular) → `async_forward_entry_setups` (Plural)

In `__init__.py`:

```python
# FALSCH (alte API, in HA 2026.x entfernt)
for platform in PLATFORMS:
    hass.async_create_task(
        hass.config_entries.async_forward_entry_setup(entry, platform)
    )

# RICHTIG (atomic, mit Plural-Service)
await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)
```

### Python-Dep-Stolperfalle: pip-Name ≠ Import-Name

```bash
docker exec homeassistant pip install pyhOn==0.17.5   # pip-Name: gemischte Schreibweise
docker exec homeassistant python3 -c "import pyhon"   # Import: alles lowercase
```

Verwechsung kostet einen Setup-Versuch + verwirrenden Stack-Trace.

### Live-Pull aus hOn-Cloud (Diagnose-Anker)

Wenn `climate.X.state` und das physische Gerät divergieren, ist hOn-Cloud die Ground Truth:

```python
from pyhon import Hon
import asyncio, json

ce = json.load(open("/config/.storage/core.config_entries"))
hon_entry = next(e for e in ce["data"]["entries"] if e.get("domain") == "hon")
email = hon_entry["data"]["email"]
password = hon_entry["data"]["password"]

async def run():
    async with Hon(email=email, password=password) as hon:
        await hon.setup()
        for app in hon.appliances:
            for k in ["onOffStatus","machMode","tempIndoor","tempSel"]:
                v = app._data.get(k) if hasattr(app, "_data") else None
                print(f"{app.nick_name} {k} = {v}")

asyncio.run(run())
```

`onOffStatus=1` ist die Wahrheit, `climate.X.state` ist der HA-State-Machine-Cache.

## Mehrquellen-State-Check bei „Wert stimmt nicht"-Reports

Wenn der User sagt „Sensor X zeigt falschen Wert" oder „Gerät ist aus, aber HA sagt an": **nie blind einer einzelnen Quelle vertrauen**. Diskrepanzen sind häufiger als Bugs.

**Quellen-Hierarchie** (steigende Verlässlichkeit von oben nach unten):

1. **`climate.X.state` / aggregierter HA-State** — zeigt den letzten persisted Modus, kann veraltet sein nach Cloud-Cut oder Restart
2. **`climate.X` Attribut `hvac_action`** — sagt ob aktiv arbeitend (`cooling`/`heating`) oder `idle` (an, aber Zieltemp erreicht)
3. **`sensor.X_machine_status`** — vom Gerät gemeldeter Betriebszustand
4. **`select.X_programm`** — letzter gesetzter Modus (kann von state divergieren)
5. **Direct API/Cloud-Pull** (z.B. `pyhon.Hon`-Live-Query, MQTT-Topic, Webhook) — Ground Truth

**Diagnose-Pattern für climate:**

```python
import json
d = json.load(open("/config/.storage/core.restore_state"))
target = "climate.klimaanlage_flur_klimaanlage"
for item in d["data"]:
    s = item.get("state", {})
    if s.get("entity_id") == target:
        a = s.get("attributes", {})
        print("state            =", s.get("state"))
        print("hvac_action      =", a.get("hvac_action"))
        print("current_temp     =", a.get("current_temperature"))
        print("target_temp      =", a.get("temperature"))
        print("last_changed     =", s.get("last_changed"))
```

**Häufige Ursachen für „falsche" Anzeige:**

- `hvac_action: idle` bei `state: cool` → an, aber Zieltemp erreicht (kein Bug, sondern Standby)
- `state: cool` + `machine_status: off` → letzter App-Modus gecached, Gerät via Fernbedienung aus
- Alle Werte `unavailable` → Cloud/WS-Connection weg
- State-Cache aus `core.restore_state` nach Restart, bevor erstes Cloud-Update kam

### Recorder-DB als token-freie Ground-Truth + „Frozen-since-restart"-Heuristik

Wenn kein Token griffbereit ist (oder Registry-/YAML-Annahmen geprüft werden müssen): die SQLite-Recorder-DB direkt abfragen — liefert den **aktuellen** Wert + `last_updated_ts` ohne REST/Token.

```bash
docker exec -i homeassistant python3 - <<'PY'
import sqlite3
con=sqlite3.connect('/config/home-assistant_v2.db'); cur=con.cursor()
for e in ['climate.schlafzimmer_room_climate_cont_2','switch.eg_flur_licht']:
    cur.execute("""SELECT s.state, datetime(s.last_updated_ts,'unixepoch','localtime')
      FROM states s JOIN states_meta m ON s.metadata_id=m.metadata_id
      WHERE m.entity_id=? ORDER BY s.last_updated_ts DESC LIMIT 1""",(e,))
    print(e, cur.fetchone())
con.close()
PY
```

**„Frozen-since-restart"-Heuristik** (mächtigstes Waisen-Diagnose-Tool): Entities, deren `last_updated` exakt auf der letzten Boot-Zeit klebt und sich nie erholt, sind **Waisen** — ihr Producer (Integration / Template / REST-Sensor) wurde bei einem Refactor entfernt, aber Registry + Exposure + Dashboard-Refs blieben. So trennt man eine **lebende** Entity (`_2`, vor Minuten aktualisiert) von einer **toten Dublette** (eingefroren beim Boot). Real: 6 `light.*`-Template-Lights + 3 non-`_2`-Klima-Dubletten, alle `unavailable @ 01:38` = letzter Restart → Waisen.

**🔴 Registry-Präsenz ≠ Laufzeit.** `core.entity_registry` listet auch tote/entfernte Entities; `core.restore_state` ist **partiell** (climate/light/switch persistieren dort oft nicht → Abwesenheit beweist NICHTS). Audit-Claims („Entity X existiert nicht / ist kaputt") IMMER gegen Recorder-DB oder REST `/api/states` verifizieren, NIE allein gegen Registry oder statisches YAML — sonst Falsch-Positive (live passiert: ein als „tot" gemeldeter Monats-Energiesensor lief in Wahrheit mit echtem Wert).

**Caveat:** Sensoren in `recorder.exclude` haben absichtlich veraltete DB-Timestamps → für die ist die DB-Zeit KEIN Frische-Indikator (Live-Wert via REST holen).

**`check_config`-Scope:** validiert `configuration.yaml` + `packages/`, aber **NICHT** YAML-Mode-Dashboards (`resource_mode`) — die nur per `yaml.safe_load` / Render prüfen. `configuration.yaml` selbst ist wegen `!include`/`!secret` nicht mit naive `yaml.safe_load` lintbar (Fehlalarm) — dafür ist `check_config` die Wahrheit.

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

### Lovelace YAML-Mode → Resources kommen aus `configuration.yaml`

Wenn `lovelace.mode: yaml` (statt `storage`) — egal ob nur Sub-Dashboards oder das ganze System YAML-getrieben sind — werden Custom-Card-JS-Resources **NICHT** mehr aus `.storage/lovelace_resources` gelesen. HA ignoriert diese Datei in dem Modus stillschweigend. Folge: ApexCharts/Bubble-Card/Mushroom/Card-Mod erscheinen im UI als „Unknown card-type".

**Lösung**: Resources unter `lovelace.resources:` in `configuration.yaml` deklarieren (vor `dashboards:`):

```yaml
lovelace:
  mode: storage        # auch wenn storage-mode für Haupt-Dashboard
  resources:
    - url: /hacsfiles/mushroom/mushroom.js
      type: module
    - url: /hacsfiles/Bubble-Card/bubble-card.js
      type: module
    - url: /hacsfiles/mini-graph-card/mini-graph-card-bundle.js
      type: module
    - url: /hacsfiles/card-mod/card-mod.js
      type: module
    - url: /local/community/apexcharts-card.js
      type: module
  dashboards:
    lovelace-haier:
      mode: yaml
      filename: dashboards/haier_klima.yaml
      title: Klima
      icon: mdi:air-conditioner
```

Nach Änderung: HA-Restart (Resources werden nur beim Bootstrap geladen), nicht nur Reload.

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

## Premium Lovelace Dashboards (2026-05-22)

Patterns für hochwertige, responsive Dashboards mit Glassmorphism, 3D-Modellen und konsistentem Design. Voraussetzung: `mushroom`, `button-card`, `card-mod`, `custom:layout-card`, optional `apexcharts-card`, `mini-graph-card` installiert (alle via HACS).

### Mushroom-Card Overflow-Fix (KRITISCH)

`mushroom-template-card` mit langem `secondary`-Text rutscht aus der Card auf Mobile oder bei schmalen Spalten. Default-CSS hat `min-width` issues.

```yaml
card_mod:
  style: |
    ha-card {
      padding: 14px 16px !important;
      border-radius: 22px !important;
      overflow: hidden;
    }
    mushroom-state-info {
      min-width: 0 !important;       /* PFLICHT – sonst Overflow */
      max-width: 100% !important;
    }
    mushroom-state-info .primary {
      font-size: clamp(1.05em, 3.4vw, 1.45em) !important;
      white-space: nowrap !important;
      overflow: hidden !important;
      text-overflow: ellipsis !important;
    }
    mushroom-state-info .secondary {
      font-size: clamp(0.78em, 2.5vw, 0.92em) !important;
      line-height: 1.35 !important;
      white-space: normal !important;
      word-break: break-word !important;
      margin-top: 4px !important;
    }
    @media (max-width: 480px) {
      ha-card { padding: 11px 13px !important; border-radius: 18px !important; }
      mushroom-shape-icon { --icon-size: 38px !important; }
    }
```

Zusätzlich `multiline_secondary: true` auf der Card setzen.

### Glassmorphism Card-Pattern (kopierbar)

Konsistente Premium-Optik für alle Karten. Anchor-fähig via `card_mod: &name`.

```yaml
card_mod: &glass_card
  style: |
    ha-card {
      background: rgba(20,28,42,0.55) !important;
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid rgba(255,255,255,0.08) !important;
      border-radius: 18px !important;
      box-shadow: 0 8px 24px rgba(0,0,0,0.30);
      padding: 14px 16px !important;
      transition: transform .2s ease, box-shadow .2s ease;
    }
    ha-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 14px 32px rgba(0,0,0,0.40);
    }
```

Re-use via `card_mod: *glass_card`. View-Background mit radial-gradients (dunkles Blau/Rot) gibt der Glass-Card den Tiefen-Effekt.

### Custom-Progressbar via `::after` Pseudo-Element

Tank-, AdBlue-, Service-Bars direkt in einer Mushroom-Card ohne extra Element:

```yaml
card_mod:
  style: |
    ha-card {
      padding: 14px 16px 20px 16px !important;
      position: relative;
      overflow: hidden;
    }
    ha-card::after {
      content: "";
      position: absolute;
      left: 16px; right: 16px; bottom: 8px;
      height: 3px;
      border-radius: 2px;
      background:
        linear-gradient(90deg,
          {% set f = states('sensor.X_fuel_level') | float(0) %}
          {% set col = '#ef4444' if f < 15 else ('#f59e0b' if f < 30 else '#10b981') %}
          {{ col }} 0%,
          {{ col }} {{ f }}%,
          rgba(255,255,255,0.06) {{ f }}%,
          rgba(255,255,255,0.06) 100%);
    }
```

Jinja im Card-Mod-Style wird beim Card-Update neu gerendert.

### custom:layout-card für echte Responsive Grids (PFLICHT)

HA-eigenes `type: grid columns: N` ist **nicht responsive** — N Spalten fix, auch auf Phone-Viewports. Lösung: `custom:layout-card` mit CSS-Grid-Auto-Fit.

```yaml
- type: custom:layout-card
  layout_type: custom:grid-layout
  layout:
    grid-template-columns: "repeat(auto-fit, minmax(140px, 1fr))"
    grid-gap: 10px
  cards:
    - type: tile
      ...
```

Richtwerte `minmax(X, 1fr)`:
- Stat-Tiles mit Zahl: `140px`
- Quick-Actions (Icon + 2 Lines): `135px`
- Detail-Tiles: `150-180px`
- Lock-Cards mit Buttons: `220px`

### YAML Flow-Mapping `?`-Trap

Inline `{ key: value? }` triggert YAML-ParserError. `?` ist YAML-Key-Separator in Flow-Mappings.

```yaml
# ✗ FAIL – yaml.parser.ParserError
confirmation: { text: Tiguan verriegeln? }

# ✓ OK – Block-Style
confirmation:
  text: "Tiguan verriegeln?"
```

Generell: alle Strings mit `?`, `:`, `,`, `{`, `}`, `[`, `]` in Flow-Mappings quoten.

### Anti-Pattern „Zu viele Tiles"

Symptom: User sagt „unübersichtlich, zu viel". Daumenregel:
- **Cockpit/Daily-View**: max. 6 Schnellaktionen, max. 4 Stat-Tiles
- **Detail-View pro Raum/Gerät**: max. 4 Toggle-Tiles für Komfortfunktionen
- **Diagnose/Power-User-Sachen** in `subview: true` View — nur via Banner-Klick oder Sidebar erreichbar

Frage vor jedem Tile: **„Wird das im Alltag genutzt?"** Wenn nein → Diagnose-Subview.

### 3D-Modelle via model-viewer (lokales GLB)

Echte 3D-Modelle in HA Lovelace einbetten, ohne CDN-Abhängigkeit oder iframe-Embed-Dienste:

**1. GLB nach `/config/www/<folder>/` legen:**
```bash
mkdir -p /volume1/docker/home-assistant/config/www/Tiguan
cp /path/to/model.glb /volume1/docker/home-assistant/config/www/Tiguan/model.glb
```

**2. model-viewer.min.js lokal hosten** (kein CDN-Load zur Laufzeit):
```bash
cd /volume1/docker/home-assistant/config/www/Tiguan
curl -sL -o model-viewer.min.js \
  "https://unpkg.com/@google/model-viewer@3.5.0/dist/model-viewer.min.js"
```

**3. viewer.html erstellen:**
```html
<!DOCTYPE html>
<html><head>
  <meta charset="UTF-8" />
  <script type="module" src="model-viewer.min.js"></script>
  <style>
    html,body { margin:0; padding:0; background:transparent; height:100% }
    model-viewer { width:100%; height:100vh; background:transparent }
  </style>
</head><body>
  <model-viewer id="m" src="model.glb"
    camera-controls touch-action="pan-y"
    auto-rotate auto-rotate-delay="1200" rotation-per-second="16deg"
    shadow-intensity="1.6" shadow-softness="0.75"
    exposure="0.82" environment-image="neutral" tone-mapping="aces"
    field-of-view="28deg" bounds="tight"
  ></model-viewer>
  <script>
    const mv = document.getElementById('m');
    mv.addEventListener('load', () => {
      // Camera mathematisch fitten – siehe nächste Sektion
      fitCamera();
      // Optional Material-Tinting
      repaint();
    });
  </script>
</body></html>
```

**4. Im Dashboard via iframe-Card einbinden (transparent, nahtlos):**
```yaml
- type: iframe
  url: /local/Tiguan/viewer.html?v=5    # Cache-Buster für Updates!
  aspect_ratio: "16:9"
  card_mod:
    style: |
      ha-card {
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
        padding: 0 !important;
      }
      ha-card iframe {
        border: none !important;
        background: transparent !important;
        filter: drop-shadow(0 30px 32px rgba(0,0,0,0.55));
      }
```

**Cache-Buster `?v=N`** hochzählen bei jeder viewer.html-Änderung, sonst zeigt der Browser die alte Version. Mobile Companion-App cached aggressiv.

### Camera-Fit für GLB (mathematisch, nicht „auto")

`camera-orbit="auto auto auto"` + `bounds="tight"` funktionieren in der Praxis **nicht zuverlässig** — Camera landet oft im Modell-Innenraum oder das Modell ist winzig. Lösung: JS nach `load`-Event die Bounding-Box auslesen und Distanz berechnen.

```js
function fitCamera() {
  const size = mv.getDimensions();          // {x, y, z}
  const center = mv.getBoundingBoxCenter();
  const maxDim = Math.max(size.x, size.y, size.z);
  const fov = parseFloat((mv.getAttribute('field-of-view') || '28').replace('deg',''));
  const fitDist = maxDim / (2 * Math.tan(fov * Math.PI / 360));
  const distance = fitDist * 1.18;          // 18% Luft drumherum
  mv.cameraTarget = `${center.x}m ${center.y}m ${center.z}m`;
  mv.cameraOrbit = `35deg 78deg ${distance.toFixed(2)}m`;
  mv.minCameraOrbit = `auto auto ${(fitDist * 0.55).toFixed(2)}m`;
  mv.maxCameraOrbit = `auto auto ${(fitDist * 4).toFixed(2)}m`;
}
```

Padding-Faktor-Tuning:
- `1.0` = Wagen randet — schneidet ab
- `1.15` = füllt Card sehr gut aus ✓ (Standard)
- `1.6` = zu viel Luft, Auto wirkt klein

`camera-orbit="35deg 78deg"` = Hero-Shot-3/4-Ansicht. Bei `45deg` ist es klassische Press-Photo-Perspektive.

### GLB-Material-Tinting via JS

Nach `load`-Event Materialien des GLB umfärben, z.B. Karosserie schwarz-metallic:

```js
function repaintBlack() {
  const paintHints = ['paint','body','karosse','exterior','lack','door','hood',
                      'fender','bumper','roof','pillar','panel','tailgate','trunk'];
  const tireHints = ['tire','tyre','reifen','rubber'];
  const glassHints = ['glass','window','fenster','scheibe','windshield'];
  const chromeHints = ['chrome','rim','felg','wheel_rim','badge','emblem','grill'];

  mv.model.materials.forEach((mat) => {
    const name = (mat.name || '').toLowerCase();
    if (glassHints.some(h => name.includes(h))) return;  // Glas NICHT anfassen
    if (chromeHints.some(h => name.includes(h))) {
      mat.pbrMetallicRoughness.setBaseColorFactor([0.78, 0.80, 0.84, 1.0]);
      mat.pbrMetallicRoughness.setMetallicFactor(0.95);
      mat.pbrMetallicRoughness.setRoughnessFactor(0.12);
      return;
    }
    if (tireHints.some(h => name.includes(h))) {
      mat.pbrMetallicRoughness.setBaseColorFactor([0.025, 0.025, 0.025, 1.0]);
      mat.pbrMetallicRoughness.setRoughnessFactor(0.85);
      return;
    }
    if (paintHints.some(h => name.includes(h))) {
      // Deep Black Pearl Metallic
      mat.pbrMetallicRoughness.setBaseColorFactor([0.015, 0.015, 0.018, 1.0]);
      mat.pbrMetallicRoughness.setMetallicFactor(0.93);
      mat.pbrMetallicRoughness.setRoughnessFactor(0.16);
    }
  });
}
```

Fallback für GLBs mit generischen Material-Namen (`Material.001`):
```js
const bc = mat.pbrMetallicRoughness.baseColorFactor;
if (bc && (bc[0]+bc[1]+bc[2])/3 > 0.55) {
  // helle Materialien dunkler ziehen
  mat.pbrMetallicRoughness.setBaseColorFactor([0.06, 0.06, 0.07, bc[3] ?? 1.0]);
}
```

### Sketchfab vs. lokales GLB — Trade-off

| Aspekt | Sketchfab-iframe | Lokales GLB + model-viewer |
|---|---|---|
| Setup | 1 URL | GLB + JS + HTML, ~3 Dateien |
| Material-Customization | ❌ | ✓ volle PBR-Kontrolle |
| Offline-Fähigkeit | ❌ | ✓ |
| Datentransfer | je Aufruf | einmal cached |
| Auto-Rotate-Speed | begrenzt | frei |
| Camera-Limits | nein | min/max-Orbit konfigurierbar |
| iOS Companion-App | manchmal blank | zuverlässig |
| Update-Latenz | sofort | Cache-Buster nötig |
| Risiko bei Constraint „no remote assets" | ✗ | ✓ |

**Empfehlung**: Lokales GLB wenn Material-Kontrolle/Offline gewünscht, Sketchfab nur für schnelle Quick-Wins.

### Sections-View vs. Subview

```yaml
- title: Diagnose
  path: diagnose
  icon: mdi:stethoscope
  subview: true           # ← versteckt aus Sidebar, nur via navigate erreichbar
  type: sections
```

`subview: true` blendet die View aus Tab-Bar/Sidebar aus. Erreichbar nur via `navigation_path: /lovelace-XYZ/diagnose` aus anderen Karten (z.B. Status-Banner). Power-User-/Wartungs-Inhalte gehören dorthin.

### `relative_time` für Live-Status in Schnellaktionen

Sekundärtext "vor 5 Minuten" statt absolute Zeit:

```yaml
secondary: >-
  {% if is_state('binary_sensor.X_request_in_progress','on') %}läuft …
  {% else %}{{ relative_time(states.sensor.X_last_data_refresh.last_changed) }}{% endif %}
```

`relative_time(datetime)` rendert lokalisiert ("vor 3 Minuten", "vor 2 Stunden").

### Dashboard-Reload ohne HA-Restart

YAML-Mode-Dashboards aktualisieren sich beim Browser-Reload, ohne dass HA neu startet:
- Desktop: **Strg+Shift+R**
- iOS/Android Companion-App: App komplett schließen + neu öffnen, oder `Settings → Companion App → Reset frontend cache`
- card-mod-Styles cachen aggressiv — bei DOM-Änderungen evtl. auch HA-Frontend-Cache leeren via Profile → Browser-Storage löschen

Bei Scripts/Helpers reicht `script.reload` / `homeassistant.reload_config_entry` via Developer Tools — kein Restart nötig.

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
25. **Integration nach Backend-Restart als "kaputt" behandeln**: Wenn eine Integration mit `ConnectionError` / `httpx.ConnectError` im Setup scheitert, ist das oft eine **Race-Condition** zwischen HA und dem Backend-Container (Ollama, Postgres, Mosquitto …), nicht ein dauerhaftes Problem. Erst **Diagnose**: Timestamp des HA-Errors vs. `docker inspect <name> --format '{{.State.StartedAt}}'` vergleichen. Wenn der HA-Error VOR dem Backend-Container-Start liegt → reine Race-Condition. **Fix ohne HA-Restart**: einzelne Config-Entry reloaden via `POST /api/config/config_entries/entry/<entry_id>/reload` (siehe Common Commands). HA hat kein Auto-Retry für gescheiterte Integration-Setups — manuell reload nötig.
26. **`tap_action: { action: toggle }` auf `button.*`-Entity**: Buttons haben nur `press`, kein `toggle`. Card reagiert nicht auf Tap (still failure, kein UI-Feedback). IMMER `perform-action: button.press` + `target.entity_id`. Faustregel: `toggle` nur für `switch.* / light.* / input_boolean.*` — alle anderen Domänen brauchen domain-spezifische Service-Calls. Codex Stop-Hook fängt das, aber besser vor Commit erkennen (Audit-grep: `grep -nB1 "action: toggle" *.yaml | grep "entity: button"`).
27. **card_mod-Animationen ohne State-Check**: Pulse/Glow/Conic-Rotation in `style:` ohne Jinja-Wrapper laufen unkonditional weiter, auch wenn das Gerät aus ist. User-Report: „Card pulsiert obwohl Klima aus". Lösung: `{% if states('...') not in ['off','unavailable','unknown','none'] %} animation: ... {% endif %}` UND `@keyframes` ebenfalls in den `{% if %}`-Block. Zusätzlich Off-State explizit gestalten (`filter: grayscale(40%) brightness(0.82)`), damit der User sieht: „aus = ruhig".
28. **Lovelace YAML-Mode + Resources via .storage**: Im `mode: yaml` werden Custom-Card-JS-URLs aus `.storage/lovelace_resources` ignoriert. Resources MÜSSEN in `configuration.yaml` unter `lovelace.resources:`. Nach Edit: HA-Restart nötig (nicht nur Reload).

## Cross-Machine-Limitation (NAS-Instanz)

NAS (`192.168.22.90`) kann andere Hosts im Setup **nicht direkt steuern**:
- Clawbot VM (`192.168.22.206`, User `moltbotadmin`): kein SSH-Key auf NAS hinterlegt, Tailscale-CLI nicht installiert, Hostname `moltbot` lokal nicht aufgelöst
- Yoga7, Windows-PC: kein SSH-Setup vom NAS aus

**Konsequenz**: `systemctl --user restart …` oder ähnliche Befehle auf moltbot/Yoga7 muss der User selbst ausführen — oder die jeweilige Instanz-Skill-Session (`clawdbot-admin`, `yoga7-admin`, `windows-admin`) übernimmt es vor Ort. Vor Vorschlag von Cross-Machine-Aktionen: explizit kennzeichnen, dass NAS-Claude das nicht selbst durchführen kann.

---

## Audio-Pipelines (TTS + Music-Merge) — 2026-05-07

### HA-Container hat ffmpeg 6.1.2 standardmäßig dabei

`homeassistant/core` Image enthält ffmpeg mit allen Codecs (libmp3lame, libx264, libwebp, libsoxr etc.). Audio-Pipelines (Voice+Music-Merge, Loudness-Normalization) gehen direkt im HA-Container via `shell_command`. Kein separater Worker-Container nötig.

```yaml
shell_command:
  jarvis_test_ffmpeg: 'bash -lc "ffmpeg -version > /config/www/sounds/_ffmpeg_check.txt 2>&1"'
```

### Cast-Receiver kann nur EIN Audio-Stream gleichzeitig

**Hard-Limit von Google Cast** (Philips OLED, Chromecast, Nest Hub):
- `play_media(loop.mp3)` startet Audio-Stream A
- `tts.speak(...)` ersetzt Stream A komplett durch Stream B
- → Music-Underlay UNTER TTS via Cast-Service-Calls **nicht möglich**

**Workaround:** Pre-rendered combined MP3 mit ffmpeg-amix (Voice + Music in EINEM Stream):
```bash
ffmpeg -y -i voice.mp3 -i music.mp3 \
  -filter_complex "[0:a]adelay=1500|1500,apad=pad_dur=3[voice];
                   [1:a]volume=0.35[music];
                   [voice][music]amix=inputs=2:duration=longest[out]" \
  -map "[out]" -ac 2 -ar 44100 -b:a 192k combined.mp3
```

### Cast-Receiver setzt Volume bei jedem `play_media` auf 0.65

**pychromecast-Default**: jeder `media_player.play_media`-Call löst intern `Receiver: setting volume to 0.65` aus, **unabhängig vom vorherigen Cast-Volume**. Logged als `[pychromecast.controllers] Receiver:setting volume to 0.65`.

**Konsequenz:** TV-Hardware-Lautstärke 0.10 → Cast springt auf 0.65 → effektive Lautstärke springt von leise auf laut. Bei TTS-Ansagen sehr störend.

**Workaround in Skripten:**
```yaml
- action: media_player.play_media
  target: { entity_id: media_player.tv_cast }
  data: { media_content_id: "...", media_content_type: "music" }
- delay: "00:00:00.4"   # Cast-Override hat Zeit zu greifen
- action: media_player.volume_set
  target: { entity_id: media_player.tv_cast }
  data: { volume_level: 0.30 }
```

### ElevenLabs TTS-Cache nutzen für externe Audio-Pipelines

HA cached ElevenLabs-Voice-MP3s deterministisch in `/config/tts/{hash}_{lang}_{options}_tts.elevenlabs_text_zu_sprache.mp3`. Pattern um die Voice für ffmpeg/externes Audio-Processing zu bekommen:

```yaml
script:
  jarvis_render_voice:
    sequence:
      # 1. Cast stumm schalten (User hört Render-Voice nicht)
      - action: media_player.volume_set
        target: { entity_id: media_player.tv_cast }
        data: { volume_level: 0 }
      # 2. tts.speak mit cache=true → MP3 in /config/tts/
      - action: tts.speak
        target: { entity_id: tts.elevenlabs_text_zu_sprache }
        data:
          media_player_entity_id: media_player.tv_cast
          cache: true
          message: "{{ message }}"
          options: { voice: "..." }
      # 3. Render-Wait (länger als Voice-Wiedergabe wegen Cast-Stumm-Modus)
      - delay:
          milliseconds: "{{ (message | length * 80) + 8000 }}"
      # 4. Cast stoppen
      - action: media_player.media_stop
        target: { entity_id: media_player.tv_cast }
      # 5. shell_command findet `ls -t /config/tts/*elevenlabs*.mp3 | head -1`
      - action: shell_command.jarvis_render_combined
```

So bekommt man ElevenLabs-Voice ohne API-Key in n8n hinterlegen zu müssen — HA macht den Auth-Teil.

### Async Service-Call via `script.turn_on` + `variables`

**Problem:** `/api/services/script/{script_name}` ist **synchron** — wartet auf Script-Ende. Bei langen Skripten (Cinematic-Rendering 60-90s) blockiert der HTTP-Caller die ganze Zeit.

**Lösung — async via `script.turn_on`:**
```yaml
# Async (returns sofort, Script läuft Hintergrund):
POST /api/services/script/turn_on
{ "entity_id": "script.jarvis_briefing_speak", "variables": { "message": "..." } }
```

`script.turn_on` startet das Script im Hintergrund und returned sofort 200. `variables` werden als Script-`fields` durchgereicht.

### `home_assistant`-Conversation versteht oft generelle Fragen nicht

HA's Default-Conversation-Engine `conversation.home_assistant` ist Intent-basiert — nur Smart-Home-Befehle aus gelisteten Templates. Generelle Fragen ("wie spät ist es", "welche Lichter sind an") antwortet sie oft mit "Tut mir leid" oder leerer `speech.plain.speech`.

**Fallback-Pattern in Workflows:**
```js
const respType = data.response.response_type || '';
const speech = data.response.speech.plain.speech;
if (respType === 'error' || /tut mir leid|sorry|verstehe nicht/i.test(speech)) {
  // → Fallback an Ollama / OpenRouter / GPT
}
```

Plus: HA's Conversation-Engine sieht nur **expose'd Entities** (siehe `homeassistant.expose_entity` WebSocket-Pattern). Wenn Lichtschalter nicht für `conversation` exposed: HA's Default-Engine kann nicht steuern.

### Spotify-Single-Stream-Limit (auf Echos + Cast)

Spotify-Account streamt **nur ein Gerät gleichzeitig** (technische Spotify-Restriction). Multi-Room-Musik mit "Spotify auf Echo + parallel auf Cast" nicht möglich.

**Konsequenzen:**
- Echo Show: Spotify-Underlay + Echo-natives TTS-Ducking → cinematisch ✓
- TV-Cast: **nicht** Spotify-Stream + tts.speak parallel → braucht ffmpeg-pre-merge
- Mehrere Echos gleichzeitig: nur via "Multi-Room Audio" in Alexa-App (HA orchestriert das nicht)

### Voice-Pipeline `voice_assistant_run_start`-Event

HA feuert ein Event wenn Wake-Word (`Hey Jarvis`, `Hey Nabu`) erkannt wurde. Nutzbar für Cinematic-Underlay-Automations:
```yaml
automation:
  - id: jarvis_wake_underlay
    triggers:
      - trigger: event
        event_type: voice_assistant_run_start
    actions:
      - action: media_player.play_media
        target: { entity_id: media_player.tv_cast }
        data:
          media_content_id: "http://192.168.22.90:8123/local/sounds/jarvis_activate.mp3"
          media_content_type: "music"
```

### Spotify-Cold-Start auf Echo Show ist 3-7 Sekunden

`media_player.select_source` + `media_player.play_media` für Spotify auf Echo Show braucht **3-7s** bis Audio tatsächlich kommt. Build-up-delays von 1-2s sind zu kurz, der TTS-Trigger danach killt den Stream bevor User Music hört.

**Empfohlene Sequenz für cinematic Build-up:**
```yaml
- action: media_player.select_source
  target: { entity_id: media_player.spotify_account }
  data: { source: "Dianas Echo Show 8 2nd Gen" }
- delay: "00:00:01"
- action: media_player.volume_set
  target: { entity_id: media_player.dianas_echo_show_8_2nd_gen }
  data: { volume_level: 0.25 }
- action: media_player.play_media
  target: { entity_id: media_player.spotify_account }
  data: { media_content_id: "spotify:playlist:...", media_content_type: "music" }
- delay: "00:00:06"   # ← Spotify hat jetzt Zeit anzulaufen
# Erst jetzt TTS-Ansage triggern
```

---

### 2026-05-15 — HA-Komplettrefactor: Theme-Falle, YAML-Cache, Multi-Wellen-Cleanup

**🔴 KRITISCH: `default_theme:` NIEMALS auf Theme in Subdir setzen**
- `themes: !include_dir_merge_named themes/` lädt NUR Top-Level YAMLs, keine Subdirs
- "Frosted Glass" liegt typischerweise in `themes/Frosted Glass/*.yaml` (Subdir)
- Wenn `default_theme: "Frosted Glass"` aber Theme nicht ladbar → HA crashed PARTIAL:
  Container ist "healthy" aber lädt nur 5 Backup-Entities, ALLE anderen Integrationen werden geblockt
- **Sicherer Weg:** Per-User-Theme via WS-API `frontend/set_user_data`:
  ```python
  await ws.send_json({
    "type": "frontend/set_user_data",
    "key": "selectedTheme",
    "value": {"dark": True, "theme": "dark_openclaw"}
  })
  ```
- Wenn Default-Theme global gewollt: Subdir-Files INS Top-Level kopieren (alle Frosted Glass Lite/Dark/Light Varianten) — und ha core check verifizieren

**🔴 "Successful config (partial)" = FEHLERMELDUNG, nicht Erfolg**
- `ha core check` Output endet mit "Successful config (partial)" wenn EIN Block defekt war
- Bedeutet: HA hat sich aus dem fehlerhaften Block "gerettet", aber dieser läuft NICHT
- Action: sofort `revert + git diff` letzten Edits, nicht weitermachen mit Refactor

**🔴 YAML-Mode Lovelace + Browser-Cache = Frust-Hauptquelle**
- HA serves neue Dashboard-Config sofort (verify via `lovelace/config` WS-Call)
- Browser cached aggressiv → User sieht alte Version trotz Server-Update
- **User-Action nach jedem Dashboard-Edit kommunizieren:**
  1. `Ctrl+Shift+R` (Hard-Refresh)
  2. DevTools → Application → "Clear site data" → F5
  3. Inkognito-Tab fresh
- WICHTIG: nicht annehmen "User sieht es" — explizit nach Browser-Refresh fragen

**🔴 Status-Check FIRST, bevor Integrations einrichten**
```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" \
  "$HA_URL/api/config/config_entries/entry" | \
  jq -r '.[] | "\(.domain) | \(.title) | \(.state)"' | sort
```
- Spart Stunden: Matter, Philips TV, Home Connect, alexa_media etc. waren in dieser Session bereits eingerichtet
- Plot-Twist-Wahrscheinlichkeit ist hoch bei gewachsenen Setups

**🔴 Cross-Stack docker-compose `depends_on` funktioniert NICHT**
- HA und Postgres-ha in getrennten compose-Stacks → kein gegenseitiger depends_on
- Boot-Order-Race nach NAS-Reboot: HA started, Postgres noch nicht ready, HA exited Code 0
- Docker respektiert Exit 0 als "intentional" und restart nicht (auch mit `restart: unless-stopped`)
- **Fix in HA-compose:**
  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8123/manifest.json', timeout=10)\""]
    interval: 60s
    timeout: 15s
    retries: 5
    start_period: 180s   # ← gibt Postgres Zeit zum Hochfahren
  ```

**🔴 Package-Konsolidierung mit Python yaml + HA-Tag-Constructor**
- PyYAML's `safe_load` kennt HA-spezifische Tags nicht (`!secret`, `!include`)
- Custom multi-constructor preserveiert Tags:
  ```python
  class HATag(str):
      def __new__(cls, tag, value):
          s = str.__new__(cls, value); s._tag = tag; return s

  def _tl(loader, suf, n):
      if isinstance(n, yaml.ScalarNode):
          return HATag('!'+suf, loader.construct_scalar(n))
      elif isinstance(n, yaml.SequenceNode):
          return loader.construct_sequence(n)
      else:
          return loader.construct_mapping(n)

  def _td(d, data):
      return d.represent_scalar(data._tag, str(data))

  yaml.SafeLoader.add_multi_constructor('!', _tl)
  yaml.SafeDumper.add_representer(HATag, _td)
  ```
- Für Package-Mergen: Top-Level-Keys disjunkt prüfen (`input_*`, `script`, `automation`, `template`, `rest`)
- Conflict-Detection BEFORE merge: bei Duplicate-Keys warnen

**🟡 WS-API > REST für HA-Config-Operations**
| Operation | WS-Command |
|-----------|-----------|
| Theme per-user | `frontend/set_user_data` |
| Dashboard inspect | `lovelace/config` mit `url_path` |
| Energy prefs | `energy/get_prefs`, `energy/save_prefs` |
| Core config | `config/core/update` (currency, units) |
| Frontend reload | `frontend/reload_themes` |
| Device/Entity Registry | `config/device_registry/list`, `config/entity_registry/list` |
- REST nur für simple state-reads + service-calls
- WS via aiohttp im HA-Container: `docker exec homeassistant python ...`

**🟡 3-Wellen-Refactor-Pattern für HA-Cleanup**
- **Welle A (Quick Wins, risikolos):** Storage-Müll archivieren, Legacy-DB raus, alte .bak-Files
- **Welle B (Konsolidierung):** Package-Mergen, Dashboard-Split, modulare Files
- **Welle C (Modernisierung):** Theme, Hero-Cards, Boot-Order, Watchdog, neue Integrationen
- IMMER vor Welle A: vollständiges HA-Backup (UI: Einstellungen → System → Sicherungen)
- Pro Schritt: ha core check → reload/restart → verify entity counts → next

**🟡 Archive-statt-delete für Refactors**
- Zentraler Bucket: `_audit_archive_YYYY-MM-DD/` im /config-Verzeichnis
- Subdirs nach Kategorie: `storage_bak/`, `legacy_db/`, `weather_packages_replaced/`, etc.
- Rollback einfach via `mv $ARCH/<file> $CFG/packages/` + HA restart
- User-Vertrauen: "nichts ist weg, alles reversibel"

**🟡 Recorder-Exclude für High-Frequency-Sensors**
- Bridge-/Sonden-Sensoren mit ≥30s poll → dominieren states-Table
- Top-Talker-Query:
  ```sql
  SELECT sm.entity_id, COUNT(*) AS cnt
  FROM states s JOIN states_meta sm USING (metadata_id)
  WHERE s.last_updated_ts > extract(epoch from now() - interval '24 hours')
  GROUP BY sm.entity_id ORDER BY cnt DESC LIMIT 15;
  ```
- Exclude via `recorder.exclude.entity_globs`: `sensor.yoga_7_*`
- Statistics bleiben (Trends für Dashboards OK)
- POLL_INTERVAL der Bridge entsprechend hochsetzen (30 → 60s halbiert Last)

**🟡 3-Channel-Watchdog-Pattern (MQTT + HA + ntfy)**
- Monitoring-Tools NIE auf monitored-System angewiesen (HA-down → kein Alert)
- Channels in Priorisierung:
  1. **MQTT** (Mosquitto direkt) — primary, retained `watchdog/alert/<key>`
  2. **HA** (jarvis_say) — secondary, nice-to-have wenn HA up
  3. **ntfy.sh** (push to phone) — fallback, externes Push, kostenlos
- Watchdog publisht heartbeat retained: `watchdog/heartbeat` + `watchdog/status=online`
- User installiert ntfy-App + subscribed Topic → bekommt Pushes direkt aufs Phone

**🔵 Energy currency ≠ Core currency**
- `config/core/update` mit `{"currency": "EUR"}` setzt Core-Default
- `energy/save_prefs` Schema lehnt top-level `currency` key ab
- Energy-UI nutzt Core-Currency wenn keine eigene gesetzt — HA-Restart kann nötig sein

**🔵 Ollama Port-Conflict Pattern**
- Container crashed/exited → docker-proxy bleibt orphaned als zombie
- Symptom: `docker compose up` → "port is already allocated"
- Diagnose: `ss -tlnp | grep <port>` zeigt PID — kein Container, nur docker-proxy
- Fix-Optionen:
  1. `kill <pid>` für orphan docker-proxy
  2. Port im compose wechseln (z.B. 11436 → 11437) + alte Integration löschen + neue mit neuer URL
- Konsequenz: HA-Integration muss neu eingerichtet werden (DELETE config_entry + neuer flow)
- **Doku-Drift bestätigt 2026-05-20:** Ollama läuft jetzt auf **11437** (extern), `/volume1/docker/CLAUDE.md` dokumentiert noch 11436. HA-Config-Entry-Title spiegelt aktuellen Port (`http://192.168.22.90:11437`). Bei Race-Restart Integration NICHT neu einrichten — nur reloaden (siehe Common Mistake #25).

**🔵 Dashboard-Hero-Pattern für Übersicht**
- Erste Section im Dashboard mit `column_span: 4` (volle Breite)
- Mushroom-Template-Card mit dynamischer Greeting (now().hour basiert)
- 4 Quick-Stat-Cards in horizontal-stack: Lichter an, Heizungen aktiv, Fenster offen, aktueller Verbrauch
- Klickbar (tap_action: navigate) → Räume / Wetter / Energie
- Card-mod-Gradient für moderne Optik (rgba + backdrop-filter: blur)

---

### 2026-05-23 — Custom-Integration-Bugs, reverse_state-Konvention, UI-Fehler-Triage

**🔴 `hon` Custom-Integration: sync_command-ValueError nach erfolgreichem Befehl**
- Setup: Haier hOn-Integration (`custom_components/hon/`) + `pyhOn==0.17.5`
- Symptom UI: "Die Aktion climate/set_hvac_mode konnte nicht ausgeführt werden. Allowed values: ['2', '4', '5', '6', '7', '8'] But was: 0"
- Trotz Fehlermeldung: **Befehl wird tatsächlich ausgeführt** (z.B. Klimaanlage geht aus)
- Stack-Trace zeigt: `commands["stopProgram"].send()` ist schon durch, der Fehler kommt aus dem nachgelagerten `self._device.sync_command("stopProgram", "settings")` in `climate.py:202`
- pyhon strict-validiert beim Sync den Wert `0` gegen `settings.machMode.values = ['2','4','5','6','7','8']` → ValueError eskaliert ins UI
- **Fix-Pattern:** try/except ValueError um JEDEN sync_command-Aufruf:
  ```python
  try:
      self._device.sync_command("stopProgram", "settings")
  except ValueError as err:
      _LOGGER.debug("sync_command stopProgram->settings ignored: %s", err)
  ```
- Betroffene Files in hon-Integration: `climate.py` (4 Stellen), `switch.py` (2), `number.py` (1, braucht Logger-Import), `select.py` (1)
- Backups vor Patch: `*.py.bak-YYYYMMDD-HHMMSS`
- Beim HA-Restart kompiliert Python die `.pyc`-Cache-Files neu — Verifikation: mtime der `.pyc` > Restart-Zeit

**🔴 volkswagencarnet `reverse_state=True` Konvention**
- Alle `*_closed_*`-BinarySensoren (`door_closed_*`, `window_closed_*`, `hood_closed`, `trunk_closed`, `sunroof_closed`, `windows_closed`) haben `reverse_state=True` in `pyhon-style` dashboard.py
- Source: `/usr/local/lib/python3.14/site-packages/volkswagencarnet/vw_dashboard.py:2575+`
- Bedeutung in HA-State:
  - `state: 'off'` = **geschlossen** (kein Problem, normal)
  - `state: 'on'` = **offen** (Warnung)
- Templates müssen `is_state(..., 'off')` für "geschlossen" prüfen — das fühlt sich semantisch verkehrt an, ist aber korrekt
- Tile-Karten mit `device_class: door` zeigen via HA-Standard-Lokalisierung automatisch korrekt "Geschlossen"/"Offen"
- Custom-Cards (mushroom-template, button-card mit JS) müssen Logik selbst korrekt setzen — Bug-Hotspot beim Copy-Paste aus anderen Dashboards

**🔴 UI-Fehlermeldung "Allowed values: [...]" — Triage-Reihenfolge**
- Bei `ServiceValidationError`/`ValueError` mit "Allowed values" im UI **NICHT** sofort im Dashboard suchen
- Reihenfolge:
  1. `docker logs homeassistant --since 24h | grep -B30 "Allowed values"` — vollständige Stack-Trace
  2. Stack-Trace lesen: ist der Fehler aus `homeassistant/components/...` oder aus `custom_components/...` bzw. `pyhon/site-packages`?
  3. Wenn Custom-Integration: dort fixen (try/except), nicht im Dashboard
  4. Wenn HA-Core: Dashboard-Werte gegen Entity-Capabilities prüfen
- Falsche Hypothese ("Dashboard schickt falschen Wert") kostet eine Iteration — Stack-Trace zuerst lesen

**🟡 Diana-Präferenz: Fahrzeug-Dashboard Farblogik invertiert**
- Standard HA-Konvention: geschlossen=grün/neutral, offen=rot
- Diana möchte für Fahrzeug-Dashboard `fahrzeug.yaml`: **geschlossen=rot, offen=grün**
- Bestätigt 2026-05-23 nach Rückfrage — bewusste Präferenz, nicht Missverständnis
- Bei Edit/Reflect: nicht erneut diskutieren, direkt umsetzen
- Separate Lock-Logik bleibt Standard: `locked=grün, unlocked=rot` (separater Status, nicht von Inversion betroffen)
- Pattern für gemischte Logik:
  ```js
  const C_CLOSED = '#ef4444';  // rot für Tür/Fenster geschlossen
  const C_OPEN   = '#10b981';  // grün für Tür/Fenster offen
  const C_OK     = '#10b981';  // grün für Lock verriegelt
  const C_WARN   = '#ef4444';  // rot für Lock unverriegelt
  ```

**🟡 SVG Dark-Mode robust — Card-Background reicht oft nicht**
- Problem: `background: linear-gradient(..., rgba(15,22,42,0.75) ...)` ist semi-transparent → Light-Theme schimmert durch
- Lösung 1 (Card): Vollopaken Background setzen: `linear-gradient(180deg, #0a0e1a 0%, #050810 100%)`
- Lösung 2 (SVG, robust auch bei Theme-Wechsel): Als erste Zeichenebene ein `<rect>` mit dunklem `<radialGradient>` einfügen:
  ```svg
  <defs>
    <radialGradient id="bg" cx="50%" cy="35%" r="75%">
      <stop offset="0%" stop-color="#1a2238"/>
      <stop offset="60%" stop-color="#0a0e1a"/>
      <stop offset="100%" stop-color="#03050b"/>
    </radialGradient>
  </defs>
  <rect x="0" y="0" width="400" height="720" rx="20" fill="url(#bg)"/>
  ```
- Beide kombinieren = doppelter Schutz, theme-unabhängig

**🔵 Storage-Mode-Dashboards: kein HA-Restart nötig**
- YAML-Files in `config/dashboards/*.yaml` werden bei jedem Lovelace-View-Aufruf neu eingelesen
- Browser-Hard-Reload (Strg+Shift+R / Cmd+Shift+R) genügt, um Änderungen zu sehen
- HA-Restart nur nötig bei: Änderungen in `configuration.yaml`, Packages, Custom-Components, scripts.yaml
- check_config bleibt trotzdem sinnvoll für YAML-Syntax-Verifikation vor jedem Edit

**🔵 Custom-Component-Backups vor Edit IMMER**
- Pattern: `cp climate.py climate.py.bak-$(date +%Y%m%d-%H%M%S)` vor jeder Änderung
- HACS-Updates überschreiben sonst eigene Fixes ohne Vorwarnung
- Alternative für längere Lifetime: Fix als PR upstream einreichen (`Andre0512/hon`)
