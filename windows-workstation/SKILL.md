# Windows-Workstation Skill – Instanz-Skill für WS44 (Windows 11)

| name | description |
|------|-------------|
| windows-workstation | Instanz-spezifischer Skill für Diana's Windows-Arbeitsplatz WS44. Pfade, Netzlaufwerke, lokale Tools, PowerShell-Patterns. Aktiviert bei Windows-spezifischen Aufgaben. |

## Was ist dieser Skill?

Stell dir vor, du hast mehrere Computer — einen im Büro (Windows), einen Laptop (Linux) und einen Server (NAS). Jeder hat andere Programme, andere Ordner und andere Zugänge. Dieser Skill kennt den Büro-Computer genau: welche Laufwerke angeschlossen sind, welche Programme installiert sind, und wie man von hier aus auf die anderen Systeme zugreift.

---

## Trigger

Aktiviere diesen Skill bei:
- Windows-Pfade, Netzlaufwerke, SMB-Zugriff
- PowerShell-Scripting auf dem Arbeitsplatz
- Lokale Entwicklung (Python, Node.js)
- pywin32 / COM-Automation
- Büro-spezifische Aufgaben (Office, QM-Dokumente)
- SSH-Aliases (`nas`, `yoga7`, `nas-work`)

---

## System-Steckbrief

| Eigenschaft | Wert |
|-------------|------|
| **Hostname** | WS44 |
| **OS** | Microsoft Windows 11 Pro (64-Bit) |
| **User** | D.Göbel |
| **Home** | `C:\Users\D.Göbel` |
| **Shell** | Git Bash (Standard in Claude Code), PowerShell verfügbar |
| **Python** | 3.13.7 |
| **Node.js** | v22.20.0 |
| **Git** | 2.52.0.windows.1 |
| **Docker** | 28.4.0 (Docker Desktop) |

---

## Netzlaufwerke

| Laufwerk | Remote-Pfad | Zweck |
|----------|-------------|-------|
| Q: | `\\SERVER2012R2\QM-Handbuch` | QM-Dokumentation |
| V: | `\\Server2012r2\ki` | KI-Dateien |
| W: | `\\sql-server\MEDIFOX` | Medifox-Daten |
| X: | `\\sql-server\MEDIFOX` | Medifox-Daten (2. Mapping) |
| Y: | `\\SERVER2012R2\Dokumente` | Allgemeine Dokumente |
| (UNC) | `\\192.168.2.215\arche\` | NAS UGREEN (SMB) |
| (UNC) | `\\192.168.2.215\TimeMachineBackup` | NAS Backup |

**Wichtig:** NAS UGREEN ist auch über `\\192.168.2.215\arche\` erreichbar (kein Laufwerksbuchstabe zugeordnet).

---

## SSH-Aliases (über Git Bash)

Die `.bashrc` lädt SSH-Aliases beim Start:

| Alias | Ziel | Beschreibung |
|-------|------|--------------|
| `ssh nas` | sshd@192.168.2.215 | NAS UGREEN DXP4800PLUS |
| `ssh nas-work` | NAS WD EX2 Ultra | Zweites NAS |
| `ssh nas-ts` | NAS via Tailscale | Remote-Zugriff |
| `ssh yoga7` | Laptop (Kali Linux) | Entwicklungsmaschine |
| `mydevices` | - | Zeigt alle IPs |

---

## Installierte Python-Pakete (relevant)

| Paket | Version | Zweck |
|-------|---------|-------|
| `pywin32` | 311 | COM-Automation (Word, Excel, PowerPoint) |
| `python-docx` | 1.2.0 | .docx Bearbeitung |
| `openpyxl` | 3.1.5 | .xlsx Bearbeitung |
| `pdfplumber` | latest | PDF-Textextraktion (auch für UNC-Pfade) |
| `python-pptx` | 1.0.2 | .pptx Bearbeitung |
| `Pillow` | 11.0.0 | Bildbearbeitung (Skalieren, Zuschneiden, DPI, PNG→PDF) |
| `faster-whisper` | latest | Transkription (primaer, ersetzt openai-whisper seit 2026-04) |
| `openai-whisper` | 20250625 | Transkription (Legacy, nicht mehr aktiv genutzt) |
| `torch` | 2.8.0+cpu | PyTorch (CPU-only, GPU-Auto-Detection in whisper-direct-simple.py) |
| `mcp` | 1.16.0 | MCP SDK |
| `mcp-server-office` | 0.2.0 | Office MCP Server |
| `lxml` | 6.0.2 | XML-Verarbeitung |
| `beautifulsoup4` | 4.14.2 | HTML-Parsing |

---

## Wichtige Pfade

| Pfad | Inhalt |
|------|--------|
| `~/pflegeassist/` | PflegeAssist Pro PWA (Git-Repo) |
| `~/mcp-pflegeassist-server/` | MCP NAS-Deployment Server |
| `~/*.py` | QM-Handbuch Automatisierungs-Skripte |
| `~/.claude/skills/` | Skills-Repository |
| `Q:\Konzepte-Formulare BZWP\` | QM-Dokumente auf Server |
| `\\SERVER2012R2\Dokumente\Diana Göbel\` | Dianas persoenlicher Arbeitsbereich auf Y: (Flyer, Aushaenge, laufende Projekte) — haeufiger echter Arbeitsort als der Desktop |
| `\\SERVER2012R2\Dokumente\Auszubildende BZ+WP\` | Azubi-Verwaltung (auf Y:) — `Azubi-Übersicht.html` als Dashboard, je Person ein Ordner unter `Betreuungszentrum\|Wohnpark\` × `1-jährig\|3-jährig\` |
| `\\192.168.2.215\arche\QM-Handbuch\` | QM-Dokumente auf NAS |
| `D:\whisper_gui_portable\` | Whisper Transkriptions-Tool (faster-whisper + tkinter GUI) |

---

## Windows-spezifische Patterns

### Shell-Kontext
Claude Code verwendet Git Bash als Shell. Befehle werden als bash ausgeführt, aber Windows-Programme (PowerShell, Python, Docker) sind über PATH erreichbar.

```bash
# PowerShell aus Git Bash aufrufen
powershell -ExecutionPolicy Bypass -File script.ps1
powershell -Command "Get-ChildItem Q:\"

# Python-Skripte
python ~/qm_migration_tool.py --scan

# Windows-Programme
explorer.exe .          # Ordner in Explorer öffnen
notepad.exe file.txt    # Datei in Notepad
```

### Pfad-Konvertierung
Git Bash konvertiert Pfade automatisch:
- `C:\Users\D.Göbel` → `/c/Users/D.Göbel`
- UNC-Pfade: In Python immer raw-strings verwenden (`r"\\192.168.2.215\..."`)
- Nie `Path.resolve()` auf UNC-Pfade anwenden

### Netzwerk-Zugriff
```bash
# SMB-Status prüfen
net use

# NAS-Zugriff testen
ls "//192.168.2.215/arche/" 2>/dev/null    # Git Bash Syntax
ping 192.168.2.215
```

---

## Abgrenzung zu anderen Skills

| Aufgabe | Richtiger Skill |
|---------|-----------------|
| Docker auf NAS verwalten | `docker-admin` |
| Docker auf Windows (Docker Desktop) | `win-docker` |
| QM-Dokumente bearbeiten | `qm-word-automation` |
| NAS-Konfiguration (SSH, SMB-Shares) | `nas-homelab` |
| PflegeAssist auf NAS deployen | **dieser Skill** (SCP) oder MCP Server Tools |
| Lokale Entwicklung (Python, Node) | **dieser Skill** |
| Windows-Pfade, Laufwerke, Tools | **dieser Skill** |

---

## Constraints

### NIEMALS
1. Keine `Path.resolve()` oder `os.path.abspath()` auf UNC-Pfade — konvertiert `\\192.168.2.215\` zu `C:\192.168.2.215\`
2. Keine Hardcoded Passwörter in neuen Skripten — `.env` oder Environment-Variablen nutzen
3. Keine `rm -rf` auf Netzlaufwerken ohne explizite Bestätigung
4. **Kein `cmd.exe` wenn CWD ein UNC-Pfad ist** (`\\SERVER...`) — cmd.exe unterstützt keine UNC-Pfade als Arbeitsverzeichnis. IMMER `powershell.exe -Command "..."` verwenden
5. **Kein nacktes `npm` in PowerShell-Skripten** — der `npm.ps1`-Wrapper verschluckt in manchen Konstellationen das erste Argument-Zeichen (`npm install` → `pm install` → "Unknown command: 'pm'"). IMMER `npm.cmd install ...` (oder `npx.cmd`, `yarn.cmd`) explizit aufrufen
6. **Kein `schtasks.exe` wenn der Pfad Umlaute enthält** (z.B. `C:\Users\D.Göbel\...`) — Git-Bash-Pfadkonvertierung + Quoting machen das unlösbar. IMMER via PowerShell-Modul (`Register-ScheduledTask` / `New-ScheduledTaskAction`) registrieren
7. **Keine UNC-Pfade an `SendUserFile`** — wird hart abgelehnt (`is a UNC network path, which is not supported`). Datei erst nach lokal/Scratchpad kopieren, dann von dort senden
8. **Kein `.ps1` mit Nicht-ASCII-Zeichen ohne UTF-8-BOM ausführen** — das Write-Tool schreibt BOM-los, PowerShell 5.1 liest solche Dateien als cp1252. `Übersicht` wird zu `Ãœbersicht`, jeder Umlaut-Pfad läuft in `FileNotFoundException`, und Sonderzeichen in String-Literalen landen verstümmelt in der Zieldatei. BOM vor dem Aufruf ergänzen (siehe Lektion 2026-08-06)
9. **Kein `-Include` ohne Wildcard im `-Path`** — `Get-ChildItem -LiteralPath X -Recurse -Include *.jpg` filtert NICHT, sondern liefert den gesamten Baum. Entweder `-Path "X\*" -Include *.jpg` oder nachgelagert `Where-Object { $ext -contains $_.Extension.ToLower() }`
10. **Kein `git commit -m` mit Anführungszeichen in der Nachricht** — PowerShell 5.1 reicht auch ein Here-String (`@'…'@`) an `git.exe` weiter, wo die inneren `"` das Argument neu zerlegen (`error: pathspec '…' did not match any file(s)`). Nachricht in eine Datei schreiben und `git commit -F <datei>` nutzen

### BEVORZUGT
1. Git Bash für Dateisystem-Operationen, PowerShell für Windows-spezifische Aufgaben (COM, Registry)
2. Raw-Strings (`r"..."`) für alle Windows-/UNC-Pfade in Python
3. Lokale Kopie vor NAS-Bearbeitung (tempfile → bearbeiten → zurückkopieren)
4. **Bulk-Dokumentenanalyse via Python-Skript** — pdfplumber + python-docx + openpyxl, Output in UTF-8-Datei schreiben (nicht stdout)
5. **Bei „liegt im Ordner" IMMER erst den Ablageort verifizieren** — Diana arbeitet zwischen Desktop und Netzlaufwerk `Y:` (`\\SERVER2012R2\Dokumente\Diana Göbel\`). Nicht annehmen, dass der Ordner der Vorsession gemeint ist. Schnellster Test: Recent-Verknuepfungen aufloesen (siehe Lektion 2026-08-05)
6. **Skripte ortsunabhaengig schreiben** — `ORDNER = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent` statt hartkodiertem Pfad. Diana kopiert Skripte zwischen Desktop und Netzlaufwerk; feste Pfade erzeugen sonst genau die Divergenz, vor der CLAUDE.md bei `index.html` warnt
7. **Encoding-PFLICHT fuer alle Python-Skripte mit Unicode-Output** — Am Skriptanfang IMMER: `sys.stdout.reconfigure(encoding='utf-8', errors='replace')` + Dateien mit `open(..., encoding='utf-8')` schreiben. Windows-Konsole (cp1252) crasht sonst bei Unicode (z.B. koreanische Zeichen `\uac00` aus Whisper, oder Sonderzeichen `U+2610` aus PDFs)

### GUT ZU WISSEN
1. Docker Desktop ist installiert (v28.4), aber Docker-Workloads laufen primär auf NAS
2. faster-whisper + PyTorch (CPU-only) sind installiert fuer Transkription. GPU-Auto-Detection eingebaut — bei NVIDIA GPU wird CUDA automatisch genutzt
3. `mcp-server-office` ist installiert — Office-Dokumente können auch über MCP bearbeitet werden
4. Rechner-Name ist WS44, User ist D.Göbel (Domänen-User)
5. PowerShell-Einzeiler in Git Bash: `$`-Variablen (`$_`, `$r`, etc.) werden von Bash expandiert, bevor PowerShell sie sieht — komplexe PS-Befehle mit `try/catch` oder `$_` daher via `-File` oder als Script ausführen, nicht inline
6. `pip install` funktioniert OHNE Admin-Rechte, `choco install` BRAUCHT Admin/Elevation — bei fehlenden Tools erst pip-Alternative prüfen
7. **HuggingFace auf Windows ohne Developer Mode:** `os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"` setzen, sonst Symlink-Warnung bei jedem Modell-Download

---

## Gelernte Lektionen

### 2026-02-08 - Initiale Erstellung

**Instanz-Differenzierung:**
- Skills pro Maschine zu differenzieren ist wichtig in Multi-Device-Setups
- NAS hat andere Pfade, User und Dienste als der Windows-Arbeitsplatz
- Dieser Skill dokumentiert WS44-spezifische Konfiguration
- Netzlaufwerke Q:, V:, W:, X:, Y: sind fest gemappt und für QM/Medifox kritisch

### 2026-02-11 - PflegeAssist Deployment-Workflow

**Deployment-Pattern (PflegeAssist → NAS):**
```bash
# 1. Lokal bearbeiten
#    ~/pflegeassist/index.html editieren
# 2. Lokal testen
python -m http.server 8000  # http://localhost:8000
# 3. Auf NAS deployen
scp ~/pflegeassist/index.html sshd@192.168.2.215:/shares/Public/pflegeassist/index.html
# 4. Live prüfen: http://192.168.2.215/pflegeassist/
```

**Wichtig:** Nach lokalen Änderungen an PflegeAssist IMMER an NAS-Deployment denken — Diana erwartet, dass die Live-Version aktuell bleibt.

**PowerShell-Escape in Git Bash:**
- `$_`, `$r`, `$_.Exception` etc. werden von Bash als leere Variablen expandiert
- Workaround: Einfache PS-Befehle ohne `$`-Referenzen nutzen, oder `.ps1`-Datei erstellen

### 2026-02-12 - MD Stationär Ordner-Analyse

**UNC-Pfad + cmd.exe:**
- Claude Code CWD war `\\SERVER2012R2\Dokumente\MD Stationär` → alle cmd.exe-Aufrufe schlugen fehl
- Lösung: `powershell.exe -Command "..."` statt cmd.exe

**Bulk-Dokumentenextraktion:**
- Read-Tool kann keine binären Office-Dateien (XLSX, DOCX) und keine PDFs ohne pdftoppm lesen
- Lösung: Python-Skript mit pdfplumber + python-docx + openpyxl
- Output in UTF-8-Datei (`C:\Users\D.Göbel\md_stationaer_analyse.txt`), da stdout cp1252-Encoding hat

**Encoding-Problem:**
- `print()` nach stdout scheitert an Unicode-Zeichen (z.B. U+2610 BALLOT BOX)
- `sys.stdout.reconfigure(encoding='utf-8', errors='replace')` + Datei-Output löst das

**pip vs choco:**
- `choco install poppler` scheiterte (Lock-File + Admin-Rechte)
- `pip install pdfplumber python-docx openpyxl` funktionierte sofort (kein Admin nötig)

### 2026-04-12 - Whisper Tool Modernisierung

**faster-whisper Migration:**
- openai-whisper durch faster-whisper (CTranslate2-Backend) ersetzt: 4-8x schneller auf CPU
- Standard-Modell von `medium` auf `large-v3-turbo` geaendert (deepdml/faster-whisper-large-v3-turbo-ct2)
- VAD-Filter + `condition_on_previous_text=False` eliminiert Duplikate und Halluzinationen
- `initial_prompt` mit Pflege-Fachbegriffen fuer bessere Domainerkennung
- Neues Ausgabeformat: .srt Untertitel zusaetzlich zu .txt und _segments.txt

**cp1252 Encoding-Crash:**
- `verbose=True` in whisper laesst das Modell direkt nach stdout schreiben
- Koreanische Zeichen (`\uac00`) in Whisper-Metadaten crashen cp1252
- Fix: `sys.stdout.reconfigure(encoding='utf-8', errors='replace')` + `verbose=False` mit eigener Ausgabe

**GUI<->Subprocess Kommunikation via ##MARKER:**
- Pattern: Python-Subprocess gibt `##PROGRESS:47.3:182` aus (Prozent:ETA-Sekunden)
- GUI parst diese Marker, zeigt Progressbar + Restzeit, filtert sie aus dem Log
- Audio-Dauer via `ffprobe` ermitteln fuer prozentuale Fortschrittsberechnung
- Vorteil: Keine shared-memory oder IPC noetig, funktioniert auch im CLI-Modus

**HuggingFace Symlink-Warnung:**
- Windows ohne Developer Mode unterstuetzt keine Symlinks im HF-Cache
- `os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"` unterdrueckt die Warnung

### 2026-04-14 - Codex Plugin Setup + Einschränkungen

**Installierte Plugins (Claude Code auf WS44):**
- `codex@openai-codex` (v1.0.3) — Codex CLI Integration
- `superpowers` — automatisch mit-installiert beim Codex-Update
- Gesamt: 3 Plugins, 10 Skills, 7 Agents, 4 Hooks

**Codex CLI:**
- Version: codex-cli 0.60.1 (advanced runtime)
- Login: `! codex login` im Claude Code Prompt (öffnet Browser-Flow bei OpenAI)
- Direkte Nutzung: `! codex` startet interaktive Codex-Shell

**Codex Plugin Einschränkungen (KRITISCH):**
- `/codex:review` funktioniert NUR in Git-Repositories. QM-Dokumente auf Netzlaufwerken (Q:\) sind kein Git-Repo → schlägt dort IMMER fehl mit "This command must run inside a Git repository"
- Plugin v1.0.3 sendet `read-only` statt `readOnly` als Modus → bekannter Kompatibilitätsbug mit CLI 0.60.1. Workaround: Codex direkt im Terminal nutzen (`! codex`)
- Sub-Agenten können auf WS44 keine Bash/Write-Berechtigungen erhalten → Agent-Delegation für Dateierstellung scheitert, direkte Ausführung verwenden

### 2026-04-20 - Claude Code Auto-Update via Scheduled Task

**Claude Code Installation auf WS44:**
- Installiert via `npm install -g @anthropic-ai/claude-code` (NICHT Native Installer)
- Pfad: `C:\Users\D.Göbel\AppData\Roaming\npm\node_modules\@anthropic-ai\claude-code`
- Wrapper: `%AppData%\npm\claude` (Bash-Shim) + `claude.cmd` / `claude.ps1`
- Update-Befehl: `npm.cmd install -g @anthropic-ai/claude-code@latest` (KEIN nacktes `npm` in PS!)

**npm.ps1 First-Character-Bug (KRITISCH):**
- Symptom: `& npm install -g ...` → Output `Unknown command: "pm"`
- Ursache: `npm.ps1`-Wrapper verschluckt das "n" unter bestimmten PowerShell-Konstellationen (Argument-Parsing-Bug)
- Fix: IMMER `& npm.cmd install -g "@scope/package@latest"` — zwingt Windows zum Batch-Wrapper statt PS-Wrapper
- Betroffen vermutlich auch: `npx.ps1`, `yarn.ps1` → analog `.cmd`-Variante nutzen

**ONLOGON Auto-Update-Pattern (kein Admin nötig):**
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$trigger.Delay = "PT30S"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Limited
Register-ScheduledTask -TaskName "..." -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal -Force
```
- Funktioniert ohne Admin, solange das Ziel in `%AppData%` liegt
- 30 s Delay nach Login für Netzwerk-Stabilität
- ExecutionTimeLimit verhindert hängende Tasks

**schtasks.exe vs. PowerShell-Modul:**
- `schtasks.exe /Create ...` schlägt fehl bei Umlauten im Pfad (Git-Bash-Pfadkonvertierung + Doppel-Quoting)
- `Register-ScheduledTask` in PowerShell handhabt `C:\Users\D.Göbel\...` sauber
- Regel: Für Task-Management IMMER PowerShell-Modul, nicht schtasks.exe

**Aktive Scheduled Tasks (WS44, User D.Göbel):**
| Task-Name | Trigger | Zweck | Skript |
|-----------|---------|-------|--------|
| `ClaudeCodeAutoUpdate` | AtLogOn +30 s | Claude Code via npm auf latest | `~/claude-code-auto-update.ps1` |

**Log-Rotation in PS-Skripten:**
- Simple Pattern: Wenn Logfile > 1 MB → `Get-Content -Tail 200` + `Set-Content` zurückschreiben
- Vermeidet unbegrenztes Log-Wachstum ohne externe Rotation-Tools

### 2026-08-05 - Dateisuche über Netzlaufwerke, UNC-Grenzen, DIN-Aufbereitung

**🔴 „Die Datei liegt im Ordner" heißt NICHT der Ordner aus der Vorsession**
- Diana sagte zweimal „es befindet sich nun im Ordner", gemeint war `\\SERVER2012R2\Dokumente\Diana Göbel\Flyer\Herbstmarkt-Flyer\` — ich suchte beide Male in `C:\Users\D.Göbel\Desktop\Herbstmarkt-Flyer\`, wo wir am Vortag gearbeitet hatten. Kostete zwei Iterationen.
- Ursache: Desktop ist bei ihr Zwischenablage, das Netzlaufwerk `Y:` ist der eigentliche Arbeitsort. Beide Ordner hießen gleich und enthielten gleichnamige Dateien.
- **Regel:** Wenn eine angeblich neue Datei am erwarteten Ort fehlt → NICHT dort erneut suchen, sondern sofort Recent-Verknüpfungen auflösen.

**🔴 Recent-Verknüpfungen auflösen = schnellster Weg zum echten Arbeitsordner**
```powershell
$sh = New-Object -ComObject WScript.Shell
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent\*.lnk" -Force |
  Where-Object { $_.Name -match 'suchbegriff' } |
  ForEach-Object {
    $l = $sh.CreateShortcut($_.FullName)
    [PSCustomObject]@{ Geoeffnet=$_.LastWriteTime; Ziel=$l.TargetPath; Existiert=(Test-Path $l.TargetPath) }
  } | Sort-Object Geoeffnet -Descending | Format-Table -AutoSize -Wrap
```
- Zeigt Pfad UND Öffnungszeitpunkt — verrät sofort, auf welcher Maschine/welchem Share Diana zuletzt gearbeitet hat.
- Deutlich schneller als `Get-ChildItem -Recurse` über das Profil (das lief hier in Timeouts und lieferte nur AppData-Rauschen).

**🔴 `SendUserFile` lehnt UNC-Pfade hart ab**
- Fehler: `Attachment "\\SERVER2012R2\..." is a UNC network path, which is not supported.`
- Workaround: erst in den Session-Scratchpad kopieren (`Copy-Item`), dann von dort senden.
- Betrifft alle fünf gemappten Shares — auf WS44 der Normalfall, nicht die Ausnahme.

**🟡 Outlook-Anhangs-Cache als Fundort für „geöffnet, nie gespeichert"**
- Neues Outlook (Olk): `%LOCALAPPDATA%\Microsoft\Olk\Attachments\ooa-<guid>\<hash>\<Dateiname>`
- Dateiname bleibt im Klartext erhalten, `LastWriteTime` = Öffnungszeitpunkt.
- Nützlich, wenn Diana eine Datei per Mail bekommen/verschickt hat und sie „irgendwo" sucht.

**🟡 Zeitstempel-Manipulation zerstört die Neu-Erkennung**
- Auf Wunsch `CreationTime`/`LastWriteTime`/`LastAccessTime` auf einen Wunschzeitpunkt gesetzt (`$f.LastWriteTime = $ziel`).
- Folge: „ist diese Datei neu?" ließ sich danach nicht mehr am Datum ablesen — die Diagnose der falschen Ordner lief ins Leere.
- **Regel:** Vor/nach solchen Eingriffen SHA1 notieren (`Get-FileHash -Algorithm SHA1`), das ist danach das einzige verlässliche Identitätsmerkmal.
- Nebenaspekt für Diana: Kopieren auf andere Ziele (Mail, Cloud, NAS) setzt Zeitstempel oft neu — die Angabe überlebt den Transport nicht zuverlässig.

**🟡 Bildmaße + DPI in PowerShell ohne Zusatztools**
```powershell
Add-Type -AssemblyName System.Drawing
$i = [System.Drawing.Image]::FromFile($pfad)
"$($i.Width)x$($i.Height) @ $($i.HorizontalResolution) dpi"
$i.Dispose()   # Dispose nicht vergessen, sonst bleibt die Datei gesperrt
```
- PDF-Seitengröße prüfen ohne PDF-Bibliothek: `/MediaBox`-Regex über den ASCII-gelesenen Dateiinhalt. 595.2 × 841.92 pt = A4, 419.52 × 595.2 pt = A5.

**🔵 Rezept: KI-Flyer druckfertig auf DIN-Format bringen**
- Ausgangslage: Bildgeneratoren liefern PNGs um 1055 × 1491 px @ 96 dpi — Seitenverhältnis ist fast √2, aber die physische Größe stimmt nicht (27,9 × 39,4 cm statt A4).
- Zielmaße bei 300 dpi: **A4 = 2480 × 3508 px**, **A5 = 1748 × 2480 px**.
- Verfahren: „Cover"-Skalierung (`faktor = max(ziel_b/quell_b, ziel_h/quell_h)`) + LANCZOS + mittiges Zuschneiden → kein Verzerren, keine weißen Ränder. Der Beschnitt liegt typisch bei 2–7 px (< 0,6 mm).
- Immer PNG **und** PDF ausgeben: das PDF trägt die Seitengröße im `/MediaBox` und verhindert, dass der Druckertreiber auf „An Seite anpassen" skaliert.
- Skript: `auf_din_format.py`, liegt im jeweiligen Flyer-Ordner (Desktop + Netzlaufwerk).
- Ehrlich bleiben: 1055 px Breite sind real ~128 dpi auf A4. Das Hochrechnen auf 300 dpi erzeugt keine Schärfe, die nicht da war — auf A5 (~181 dpi) unkritisch, auf A4 aus der Nähe leicht weich.
- Für Druckereien fehlt der Anschnitt: 3 mm umlaufend → A4 = 216 × 303 mm. Nur auf Nachfrage anlegen.

**🟡 Git im Skills-Repo: `git -C <pfad>` statt `cd`**
- Nach `cd "C:\Users\D.Göbel\.claude\skills"; git status` kam `Shell cwd was reset to …` — die CWD überlebt den PowerShell-Aufruf nicht.
- Konsequent `git -C "C:\Users\D.Göbel\.claude\skills" <befehl>` verwenden. Gilt für add/commit/fetch/pull/push gleichermaßen.
- Mehrzeilige Commit-Messages per single-quoted Here-String (`@'` … `'@`), schliessendes `'@` MUSS in Spalte 0 stehen.

**🟡 Zeilenenden prüfen, bevor eine `.sh` von hier auf Linux läuft**
- `core.autocrlf=true` auf WS44 → Working Copy bekommt CRLF, das Repository speichert LF. Für Shell-Skripte, die auf NAS/VM laufen sollen, muss das verifiziert werden (sonst `\r`-Fehler).
- **Wertlos:** `git cat-file -p HEAD:datei | Out-String` und dann CR zählen — PowerShell fügt beim Rejoin selbst CRLF ein (meldete 53 CR bei sauberem Blob).
- **Richtig:** `git -C <repo> ls-files --eol <datei>` → `i/lf w/lf` (i = Index/Repository, w = Working Copy).

**🟡 Erreichbarkeit ins Heimlabor: nur über Tailscale**
- WS44 hängt im Arbeitsnetz `192.168.2.0/24` (`192.168.2.38`). Clawbot VM, NAS DXP4800 und Yoga7 liegen im `192.168.22.0/24` — **keine direkte Route**, `Test-NetConnection 192.168.22.206 -Port 22` schlägt fehl.
- Einziger Weg ist Tailscale (`100.115.38.98` = ws44). Vor jedem Cross-Netz-Versuch den Knotenstatus lesen:
  ```powershell
  & "C:\Program Files\Tailscale\tailscale.exe" status
  ```
  `-` = online, sonst `offline, last seen …`. Knoten: `ws44`, `yoga7-1`, `ugreen`, `moltbot-vm`, `lenovo-t450s`, `samsung-sm-s938b`.
- **Offene Frage (nicht verifiziert):** Dieser Skill führt das NAS unter `192.168.2.215`, der `reflect`-Skill ein „NAS DXP4800" unter `192.168.22.90` — beide mit derselben Modellbezeichnung. Ob das ein Gerät mit zwei Adressen oder zwei Geräte sind, ist ungeklärt. Verifiziert ist nur: `192.168.2.215` antwortet auf SSH (Port 22 offen, ICMP geblockt → `Test-NetConnection` meldet `Ping False, SSH22 True`), `192.168.22.90` ist von WS44 nicht erreichbar. Vor Aussagen über „das NAS" klären, welches gemeint ist.

**🔵 KI-generierte Flyer haben keine Quelldatei**
- Text ist ins Foto eingebrannt; es gibt kein Canva/PSD/InDesign-Original. Inhaltliche Änderungen sind Retusche und nicht sauber machbar.
- Richtiger Beitrag stattdessen: verdichtete **Textfassung** + fertiger **Generator-Prompt** (Stil, Farben, Bildelemente, exakte Texte), Diana erzeugt neu, ich mache die Druckaufbereitung.
- Nach jeder Generierung Umlaute Wort für Wort prüfen — Bildgeneratoren verschlucken Punkte auf ä/ö/ü und verdrehen ß.

### 2026-08-06 - Azubi-Übersicht: PS-Encoding, HTML-Dashboard-Pflege, PDF-Bilder

**🔴 Vom Write-Tool erzeugte `.ps1` läuft in PowerShell 5.1 als cp1252 — BOM ist Pflicht**
- Write schreibt UTF-8 **ohne** BOM. PS 5.1 (`powershell.exe`) interpretiert BOM-lose Dateien als ANSI/cp1252.
- Symptom 1: `\\SERVER2012R2\...\Azubi-Übersicht.html` → `Azubi-Ãœbersicht.html` → `FileNotFoundException`.
- Symptom 2 (heimtückischer): Sonderzeichen in **String-Literalen** werden mitverstümmelt. Ein `·` im Ersetzungstext hätte Mojibake in die Zieldatei geschrieben — der Fehler wäre erst beim Betrachten der HTML aufgefallen.
- **Immer vor `& $skript` voranstellen:**
  ```powershell
  $b = [System.IO.File]::ReadAllBytes($p)
  if (-not ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)) {
    [System.IO.File]::WriteAllBytes($p, ([byte[]](0xEF,0xBB,0xBF) + $b))
  }
  & $p
  ```
- Zweiter Schutz für Umlaut-Pfade: gar nicht erst literal schreiben, sondern auflösen —
  `$f = (Get-ChildItem -LiteralPath $root -Filter "Azubi-*bersicht.html").FullName`
- Beim Zurückschreiben das Original-BOM beibehalten: BOM-Zustand vorher prüfen, dann `New-Object System.Text.UTF8Encoding($hasBom)`.
- Nebenbei: der Typ heißt `[System.Text.Encoding]`, **nicht** `[System.IO.Text.Encoding]`.

**🔴 `git commit -m` scheitert an Anführungszeichen in der Nachricht — auch im Here-String**
- Das Here-String `@'…'@` schützt nur vor **PowerShell-eigener** Interpolation. Beim Weiterreichen an das native `git.exe` wird der String erneut nach Quoting-Regeln zerlegt, und jedes eingebettete `"` startet dort ein neues Argument.
- Symptom: `error: pathspec 'rebase' did not match any file(s) known to git` — git sieht Bruchstücke der Commit-Message als Dateinamen. Der vorangehende `git add` ist dann schon durch, der Commit fehlt.
- **Immer bei mehrzeiligen oder zitatehaltigen Nachrichten:**
  ```powershell
  # Message per Write-Tool in den Scratchpad, dann:
  git -C $repo commit -F "$scratch\msg.txt"
  ```
- Gleiche Familie wie die BOM- und `-Include`-Falle: der Fehler entsteht **zwischen** PowerShell und dem nativen Programm, nicht in einem der beiden.

**🔴 `-Include` ohne Wildcard im Pfad filtert stillschweigend gar nicht**
- `Get-ChildItem -LiteralPath $root -Recurse -File -Include *.jpg,*.png` gab den **kompletten** Baum zurück — 96 KB Output, abgeschnitten, kein Fehler.
- Verlässlich: `Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $ext -contains $_.Extension.ToLower() }`
- Als Gegenprobe immer die Trefferzahl mitloggen. „8 Bilddateien gefunden" hätte den Fehlschlag sofort gezeigt.

**🔴 Rabbit-Hole-Stopp: CCITTFax-Scans sind mit Bordmitteln nicht dekodierbar**
- Nach dem ersten Fund (ein Portraitfoto) habe ich vier weitere PDFs mit vier Skript-Iterationen bearbeitet — alle Bilder darin waren `/CCITTFaxDecode` (S/W-Fax-Kompression der Dokumentenscanner). Ohne poppler/Ghostscript prinzipiell nicht dekodierbar.
- **Regel:** Filter-Typ **zuerst** erheben, dann entscheiden, ob sich Extraktion überhaupt lohnt:
  ```powershell
  $s = [System.Text.Encoding]::GetEncoding(28591).GetString([System.IO.File]::ReadAllBytes($pdf))
  ([regex]::Matches($s, '/Subtype\s*/Image')).Count      # wie viele Bilder?
  ([regex]::Matches($s, '/CCITTFaxDecode')).Count        # davon S/W-Scans?
  ```
- Überwiegt CCITT → aufhören und dem User sagen, dass die Quelle nichts hergibt. Das war hier nach dem zweiten Fehlschlag klar.

**🟡 Rezept: Bilder aus PDF holen ohne poppler**
| Filter | Bedeutung | Vorgehen |
|--------|-----------|----------|
| `/DCTDecode` | eingebettetes JPEG | Bytes zwischen `FF D8 FF` und `FF D9` direkt rausschneiden, ist eine fertige .jpg |
| `/FlateDecode` | zlib-komprimiertes Raw-Bitmap | 2 Byte zlib-Header überspringen, `DeflateStream` → Rohpixel |
| `/CCITTFaxDecode` | S/W-Fax-Scan | nicht mit Bordmitteln machbar |

- Kanalzahl aus der Länge ableiten: `raw.Length / (Width * Height)` → 3 = RGB, 1 = Graustufen. Stimmt es nicht auf, ist `/BitsPerComponent` < 8.
- **GDI+ erwartet BGR, PDF liefert RGB** — beim Befüllen von `Format24bppRgb` die Kanäle tauschen, sonst sind Gesichter blau.
- Bild-Dictionary finden: **nicht** `<<[^<>]*?/Subtype/Image[^<>]*?>>` — scheitert an verschachtelten `/DecodeParms<<…>>`. Stattdessen auf `/Subtype\s*/Image` matchen und ein Kontextfenster (~900 Zeichen rückwärts bis `stream` vorwärts) auswerten.
- Downsampling beim Auslesen (`$step = [int]($w / $zielbreite)`, nur jeden n-ten Pixel) macht Sichtprüfungen 4–16× schneller — der Pixel-Loop in PS ist der Flaschenhals.
- Ein Bewerbungsfoto steckt oft im Lebenslauf-Scan, nicht als eigene Datei. Vorschau rendern → Foto-Rechteck ablesen → auf Originalmaße hochrechnen (`Faktor = Originalbreite / Vorschaubreite`) → zuschneiden.

**🟡 Rezept: Single-File-HTML-Dashboards mit Riesen-Datenzeile pflegen**
- Die `Azubi-Übersicht.html` hält alle Daten als JS-Array in **einer** 940-KB-Zeile (base64-Fotos inline). Read zeigt dort nur `[Omitted long matching line]`, das Edit-Tool ist damit unbrauchbar.
- **Analysieren** (Fotos maskieren, dann ist es sauberes JSON):
  ```powershell
  $c = $zeile -replace '"foto":\s*"data:image[^"]*"', '"foto": true'
  $s = $c.IndexOf('['); $e = $c.IndexOf('];', $s)
  $d = $c.Substring($s, $e - $s + 1) | ConvertFrom-Json
  ```
  Ohne das `];`-Ende schnappt sich `ConvertFrom-Json` die Folgezeilen mit und wirft „Ungültiger JSON-Primitiv".
- **Einfügen** per String-Splice direkt hinter `const DATA=[` — Reihenfolge egal, die Seite sortiert selbst.
- **Verifizieren** mit dem installierten Node: `<script>`-Block herausschneiden → `node --check`. Fängt jeden Quoting-Fehler ab, bevor Diana die Seite öffnet.
- Vorher **Backup neben die Datei legen** (`_Backup_<datum>.html`) — bei Netzlaufwerken ohne Git die einzige Rückfalloption.

**🟡 Vor dem Nachtragen von Daten prüfen, ob die Darstellung sie abbilden kann**
- In der Karten-Funktion stand `'<span class="tag neu">ab 09/2026</span>'` **fest verdrahtet**. Die neuen Azubis starten 08/26 und 10/26 — stumpfes Einfügen hätte drei Karten mit falschem Startmonat erzeugt.
- Fix: Datenfeld `start` einführen, Anzeige auf `esc(d.start||"09/2026")` umstellen, Bestandseinträge mit dem bisherigen Wert nachrüsten. Fallback erhalten, damit ältere Einträge ohne Feld nicht leer rendern.
- **Regel:** In generierten Dashboards immer erst die Render-Funktion lesen. Was als Konstante im Code steht, war zum Generierungszeitpunkt für alle gleich — genau das ändert sich beim ersten Nachtrag.

**🔵 Namens-Schreibweisen driften zwischen Ordner, Word-Liste und Dashboard**
- Gefunden: `Aarirsse`/`Aarisse`, `Schamo Karo`/`Schamo Caro`, `Dia Malekuly`/`Dia Malekudy`, `El Malih`/`El Mahli`, `Oumaima`/`Oumayma`.
- Naiver Substring-Abgleich erzeugt dadurch beides — Geister-Treffer und übersehene Personen. Beim Abgleich auf den Nachnamen-Stamm gehen und die Trefferliste einmal von Hand gegenlesen.
- **Ordnername als Kanon** verwenden, Abweichungen dem User melden statt still zu vereinheitlichen. Welche Schreibweise die amtliche ist, steht in keiner der drei Quellen.

**🔴 Farbstich per Referenzmessung diagnostizieren — Auto-Levels raten nur**
- Erster Versuch war eine Perzentil-Streckung pro Kanal (Auto-Levels). **Wirkungslos**, weil Schwarz- und Weißpunkt bereits neutral waren: Papier maß `R=253 G=253 B=254`, Passbild-Hintergrund `254/255/254`. Der Stich saß ausschließlich in den Mitteltönen.
- Erst das Messen der **Hauttöne** brachte die Diagnose: Wange `R=246 G=221 B=240` → **B/R = 0,97**. Der Blaukanal war massiv überhöht.
- **Sollwerte für neutrale Haut:** `G/R ≈ 0,80–0,85`, `B/R ≈ 0,70–0,78`. Weicht ein Verhältnis stark ab, ist der Kanal die Ursache.
- Messfunktion (Mittelwert über ein Rechteck im Rohbild):
  ```powershell
  function Probe($nx,$ny,$nw,$nh,$label) {
    $sr=0.0;$sg=0.0;$sb=0.0;$c=0
    for ($y=$ny; $y -lt $ny+$nh; $y++) { for ($x=$nx; $x -lt $nx+$nw; $x++) {
      $i=($y*$W+$x)*3; $sr+=$raw[$i]; $sg+=$raw[$i+1]; $sb+=$raw[$i+2]; $c++ } }
    "{0,-20} R={1,3:N0} G={2,3:N0} B={3,3:N0}  G/R={4:N2} B/R={5:N2}" -f $label,($sr/$c),($sg/$c),($sb/$c),($sg/$sr),($sb/$sr)
  }
  ```
- **Reihenfolge:** immer erst mehrere Referenzflächen messen (Papier, neutraler Hintergrund, Hautton), dann über die Korrektur entscheiden. Eine pauschale Auto-Korrektur verdeckt, wo das Problem wirklich sitzt.

**🟡 Irreparabler Farbstich → entsättigen statt Farbe erfinden**
- Ursache hier: das Original war ein **Farbausdruck mit ausgefallenem Gelb**. Die Information für echte Hauttöne existiert im Scan schlicht nicht — jede „Korrektur" hätte sie erfunden.
- Ein Gamma- oder Weißpunkt-Eingriff auf den Blaukanal hätte den Faktor 3,8–5,1 gebraucht; das zerstört die dunklen Bereiche (Haar) vollständig.
- **Robuster Weg:** Luminanz berechnen und auf niedrige Restsättigung ziehen —
  ```powershell
  $lum = 0.299*$r + 0.587*$g + 0.114*$b
  $nr = $lum + ($r - $lum) * 0.22      # 0.22 = Restsaettigung
  $nr = 128 + ($nr - 128) * 1.12       # leichter Kontrast danach
  ```
- Ergebnis ist ein fast neutrales Passbild — neben Farbfotos erkennbar anders, aber sachlich und ohne erfundene Information. Das dem User auch so sagen.

**🟡 Rezept: base64-Foto in eine Kartei der Übersicht einsetzen**
- Format wie im Bestand: `"foto": "data:image/jpeg;base64,<…>"`. JPEG bei Quality 82, ~330×400 px → 19 KB → 25.920 base64-Zeichen. Bleibt im Rahmen der übrigen Einträge.
- JPEG-Encoder in PowerShell (GDI+ speichert sonst mit Default-Qualität):
  ```powershell
  $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $par = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 82)
  $bmp.Save($pfad, $enc, $par)
  ```
- **Ankereindeutigkeit vor der Ersetzung erzwingen** — bei 77 gleichförmigen Einträgen trifft ein zu kurzer Anker sonst mehrere:
  ```powershell
  $treffer = ([regex]::Matches($t, [regex]::Escape($alt))).Count
  if ($treffer -ne 1) { throw "Anker nicht eindeutig: $treffer Treffer" }
  ```
  Als Anker mehrere Felder zusammen nehmen (`"nach"` + `"schule"` + `"foto": ""`), nicht nur den Namen.

**🔵 `git status | Select-Object -First N` liefert Exit 255 trotz Erfolg**
- PowerShell bricht die Pipeline ab, sobald `Select-Object` genug Elemente hat; das native `git.exe` bekommt einen Broken Pipe und der Tool-Aufruf meldet Exit 255 — obwohl die Ausgabe korrekt und vollständig ist.
- Betrifft jedes native Programm hinter `Select-Object -First`. Bei Prüfschritten daher entweder ungepipet aufrufen oder das Ergebnis in eine Variable nehmen und danach filtern:
  ```powershell
  $out = git -C $repo status; $out[0..2]
  ```

**🔵 DOCX-Tabellen ohne Word-COM und ohne python-docx lesen**
```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($docx, $tmp)
$xml = Get-Content "$tmp\word\document.xml" -Raw -Encoding UTF8
$t = $xml -replace '</w:p>', "`n" -replace '</w:tc>', ' | ' -replace '</w:tr>', "`n" -replace '<[^>]+>', ''
```
- Reicht für Tabellen-Übersichten und ist schneller als COM (kein Word-Start, keine Prozess-Leiche).
- Für saubere Zell-Struktur ist das installierte `python-docx` die bessere Wahl — der Regex-Weg plättet verbundene Zellen und leere Spalten zu `| | |`.
