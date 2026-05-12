# Skill: blender-mcp

| name | description |
|------|-------------|
| blender-mcp | 3D-Modellierung in Blender via MCP-Server (chrome-devtools-mcp Schwester-Pattern). Nutze diesen Skill für `bpy.ops` vs Data-API, Workspace-Auto-Switch nach Render, Boolean-Cuts via Depsgraph, TRACK_TO-Walkthroughs, sowie Persistenz-Setup via Blender-Startup-Skripte. Maschinenübergreifend (moltbot, yoga7). |

## Scope

Dieser Skill gilt **maschinen-übergreifend** überall wo:
- Blender (≥4.3) installiert ist
- Ein MCP-Server (`uvx blender-mcp`) als OpenClaw-Subprozess gespawnt werden kann
- Das `ahujasid/blender-mcp` Add-on (Open Source, 21k⭐) in Blender aktiviert ist

**Nicht** für:
- Direkte `blender --background --python script.py`-Aufrufe (anderes Pattern, nutzt Standalone-Kontext)
- Reine Renderfarmen ohne MCP-Integration
- Blender < 4.x (API-Inkompatibilitäten)

---

## Setup-Pattern (one-time per Maschine)

### 1. Add-on installieren

```bash
# addon.py von GitHub holen
curl -sS "https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py" \
  -o /tmp/blender-mcp-addon.py

# In Blender-User-Addons kopieren
mkdir -p ~/.config/blender/4.3/scripts/addons/
cp /tmp/blender-mcp-addon.py ~/.config/blender/4.3/scripts/addons/blender_mcp.py
```

**Security-Hinweis vor Installation**: `addon.py` enthält ein `exec(code, namespace)` an Zeile 431 — das ist die Code-Execution-Feature und gewollt. Vorab-Scan auf verdächtige Patterns:
```bash
grep -nE "os\.system|subprocess|shell=True|base64.*decode.*exec" /tmp/blender-mcp-addon.py
grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/blender-mcp-addon.py  # keine hardcoded IPs
```

### 2. MCP-Server in openclaw.json registrieren

```json
"mcp": {
  "servers": {
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"]
    }
  }
}
```

Schema-Change → Gateway-Restart Pflicht (`systemctl --user restart openclaw-gateway.service`).

### 3. Auto-Start beim Blender-Launch (Persistenz)

Datei `~/.config/blender/4.3/scripts/startup/openclaw_mcp_autostart.py`:

```python
import bpy
import addon_utils

def _enable_and_start():
    try:
        addon_utils.enable("blender_mcp", default_set=True, persistent=True)
    except Exception as exc:
        print(f"[openclaw-autostart] addon_enable failed: {exc}")
        return None
    try:
        bpy.ops.blendermcp.start_server()
        print("[openclaw-autostart] blender_mcp server running on port 9876")
    except Exception as exc:
        print(f"[openclaw-autostart] start_server failed: {exc}")
    return None

bpy.app.timers.register(_enable_and_start, first_interval=1.0)
```

Bei nächstem Blender-Start wird Add-on aktiviert UND MCP-Server gestartet — kein "N-Panel öffnen, Connect klicken" mehr nötig.

### 4. Zwei-Stufen-Verbindung verstehen

```
OpenClaw-Gateway  ←─stdio MCP─→  uvx blender-mcp Subprozess  ←─TCP 9876─→  Blender Plugin
```

Stufe (1) wird lazy bei erstem Tool-Call gespawnt. Stufe (2) braucht laufendes Blender mit aktivem Plugin. Wenn Blender zu, sind alle Tools tot (ECONNREFUSED 127.0.0.1:9876).

---

## Patterns für execute_blender_code

### 🔴 KRITISCH: `bpy.ops` vs Data-API

Im MCP-`execute_blender_code`-Kontext gibt es **keinen aktiven 3D-Viewport-Context**. `bpy.ops`-Operatoren, die einen VIEW_3D-Area brauchen, scheitern mit "context is incorrect"-Fehlern.

**FALSCH** (typische Beispiele):
```python
bpy.ops.object.select_all(action='DESELECT')   # braucht VIEW_3D
bpy.ops.mesh.primitive_cube_add(location=...)  # ok in 3.x, problematisch 4.x
bpy.ops.object.delete()                         # braucht aktive Selection
bpy.ops.object.modifier_apply(modifier="Boolean")  # braucht aktives Objekt
```

**RICHTIG** (Data-API):
```python
# Cube via primitive_cube_add ist meistens OK, aber sicherer direkt mesh:
mesh = bpy.data.meshes.new(name)
obj = bpy.data.objects.new(name, mesh)
bpy.context.collection.objects.link(obj)
obj.location = (x, y, z)
obj.scale = (sx, sy, sz)

# Löschen via Data-API (kein bpy.ops):
bpy.data.objects.remove(obj, do_unlink=True)

# Modifier apply via Depsgraph (siehe nächster Pattern)
```

**`__file__` ist undefiniert** im exec()-Kontext — Skripte die `os.path.dirname(__file__)` nutzen scheitern. Vermeide.

### 🔴 Boolean-Door-Cuts via Depsgraph (statt modifier_apply)

```python
def boolean_cut(target, cutter):
    mod = target.modifiers.new(name="Cut", type='BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.object = cutter
    
    # Depsgraph-Apply ohne bpy.ops
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = target.evaluated_get(depsgraph)
    new_mesh = bpy.data.meshes.new_from_object(eval_obj)
    
    old_mesh = target.data
    target.data = new_mesh
    bpy.data.meshes.remove(old_mesh)
    target.modifiers.remove(mod)
    bpy.data.objects.remove(cutter, do_unlink=True)
```

Funktioniert **ohne** VIEW_3D-Context und ohne `bpy.ops.object.modifier_apply()`.

### 🟡 Workspace-Auto-Switch nach Render

Blender wechselt **automatisch** in den `"Rendering"`-Workspace nach `bpy.ops.render.opengl(animation=True)` oder ähnlichen Render-Operatoren. Der Rendering-Workspace hat **keinen VIEW_3D-Area**, nur IMAGE_EDITOR + PROPERTIES + DOPESHEET. Folge: weitere Operator-Aufrufe scheitern mit "kein VIEW_3D"-Fehler.

**Fix nach jedem Render**:
```python
bpy.context.window.screen = bpy.data.screens['Layout']
```

### 🟡 Animation-Play via temp_override

`bpy.ops.screen.animation_play()` braucht einen VIEW_3D-Area-Context. Mit `temp_override` patternsicher:

```python
for area in bpy.context.window.screen.areas:
    if area.type == 'VIEW_3D':
        with bpy.context.temp_override(area=area):
            bpy.context.scene.frame_set(1)
            bpy.ops.screen.animation_play()
        break
```

### 🟡 Camera-View aktivieren im Viewport

```python
for area in bpy.context.window.screen.areas:
    if area.type == 'VIEW_3D':
        for space in area.spaces:
            if space.type == 'VIEW_3D':
                space.region_3d.view_perspective = 'CAMERA'  # oder 'PERSP', 'ORTHO'
        break
```

### 🟡 TRACK_TO-Constraint mit animiertem Target-Empty (Walkthrough-Pattern)

Statt feste `rotation_euler`-Keyframes auf der Kamera (klippy bei Übergängen), nutze ein `Empty` als Look-At-Target und animiere beide:

```python
# Empty erstellen
target = bpy.data.objects.new("WalkthroughTarget", None)
bpy.context.collection.objects.link(target)

# TRACK_TO Constraint auf Kamera
con = cam.constraints.new(type='TRACK_TO')
con.target = target
con.track_axis = 'TRACK_NEGATIVE_Z'  # Kamera "schaut" -Z
con.up_axis = 'UP_Y'

# Keyframes: cam-location UND target-location parallel animieren
cam.location = (x_cam, y_cam, z_cam)
cam.keyframe_insert(data_path="location", frame=frame)
target.location = (x_tgt, y_tgt, z_tgt)
target.keyframe_insert(data_path="location", frame=frame)
```

Resultat: Kamera **dreht sich natürlich** zwischen Stops, weil sie kontinuierlich auf das mit-animierte Target schaut. Sehr viel angenehmer als feste Achs-Blickrichtungen.

### 🔵 Timeline-Markers für Navigations-Schnellzugriff

```python
bpy.context.scene.timeline_markers.new("Eingang", frame=1)
bpy.context.scene.timeline_markers.new("Wohnzimmer", frame=180)
```

User kann dann mit **Page-Up / Page-Down** direkt zwischen Markers springen — schneller als Frame-Slider, auch beim Pause/Step-Through.

---

## Render-Realität auf CPU-only-Hosts

Auf moltbot (Debian-VM ohne GPU): CPU-only-Rendering mit SwiftShader/Software-OpenGL.

| Engine | Sekunden pro Frame (1080p) | 840-Frame-Animation |
|--------|----------------------------|---------------------|
| **Workbench** (OpenGL playblast) | ~2-3 s | ~30 Min |
| **Eevee** | ~0.5-2 s | ~10-30 Min |
| **Cycles** mit Denoising | ~30-120 s | **mehrere Stunden** |

**Praxis-Empfehlung**: Vorschau-Renders mit `bpy.ops.render.opengl(animation=True)` (Workbench/Viewport-Engine, schnellste). Cycles nur für finale Renders auf einer GPU-Maschine.

**OpenGL-Render-Blockade**: Während `bpy.ops.render.opengl()` läuft, blockt Blender 30+ Minuten — MCP-Calls **timeouten** im Gateway, aber **Blender rendert weiter im Hintergrund**. Output-Datei wächst sukzessive. Beim Polling der File-Größe (`stat -c %s`) den Fortschritt verfolgen. Erst wenn die Datei stabil ist, ist der `moov`-Atom geschrieben und MP4 abspielbar.

---

## Architektur-Modelle: Bauplan-Skript vor Foto-Skizze

Bei prozedural gebauten Architektur-Modellen (z.B. Hausplan-Visualisierungen) gilt:

**Hierarchie der Datenquellen:**
1. **Build-Skript (Python, .py)** — wenn vorhanden, **hat Priorität**. Enthält präzise Bauplan-Konstanten (HAUS_B, HAUS_T, WALL, etc.) — das ist die ECHTE Architekten-Geometrie.
2. **CAD-Plan (DWG/SVG/PDF)** — wenn vorhanden, pixel-genau abmessbar.
3. **Foto-Skizze** (handgezeichnete Pläne, gescannt) — **letzte Wahl**. Linien sind ~20-30cm dick im Original, Maße schwer pixel-genau zu lesen. Typisch 15-25cm Toleranz auf abgeleitete Wandpositionen.

**Falsches Pattern** (in Session 2026-05-12 erlebt): aus Foto-Skizze Raum-Koordinaten raten, ohne nach dem zugehörigen Build-Skript zu suchen. Diana hatte 3× "kein Wiedererkennungswert" sagen müssen, bevor ich das `build_haus_v3.py`-Skript mit den **echten Bauplan-Konstanten** ausgewertet habe (`HAUS_B=6.19`, `HAUS_T=9.58`, `WALL=0.38`, etc.).

**Richtiger Workflow**:
1. `find . -name "*build*.py" -o -name "*house*.py"` — gibt's ein Build-Skript?
2. Wenn ja: `grep -nE "^[A-Z_]+\s*=" script.py` — Konstanten lesen.
3. Erst wenn (1)+(2) ergebnislos: aus Foto-Skizze ableiten **und** Diana darauf hinweisen dass ~85% Toleranz herrscht.

---

## Persistenz-Falle: WalkthroughTarget bei Bulk-Delete

Bei "Lösche alle Innenwand-Objekte"-Aktionen (z.B. via Name-Prefix-Match `W_EG_*`) kann das `WalkthroughTarget`-Empty mit gelöscht werden, wenn das Prefix breit gewählt ist (z.B. `W*`). Folge: TRACK_TO-Constraint auf der Kamera zeigt ins Leere, Kamera dreht nicht mehr richtig.

**Fix**: explizite Prefix-Liste (`W_EG_`, `Tuer_`, `Keller_` — NICHT `W*` alone), oder Empty in eine eigene Collection legen und beim Filter ausschließen.

---

## Lessons-Learned-Index

- 2026-05-12 — Skill angelegt: Setup-Pattern + alle Code-Execution-Patterns aus Bardenberg-Hausmodellierungs-Session (Diana's geplantes Haus an der Bardenberger Strasse 38).
- Verknüpfung: konkrete Modell-Daten zum Bardenberg-Projekt liegen im Auto-Memory `project_blender_walkthrough.md`, nicht in diesem Skill (Skill = wiederverwendbare Patterns, Memory = projekt-spezifische Fakten).
