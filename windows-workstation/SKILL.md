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

### BEVORZUGT
1. Git Bash für Dateisystem-Operationen, PowerShell für Windows-spezifische Aufgaben (COM, Registry)
2. Raw-Strings (`r"..."`) für alle Windows-/UNC-Pfade in Python
3. Lokale Kopie vor NAS-Bearbeitung (tempfile → bearbeiten → zurückkopieren)
4. **Bulk-Dokumentenanalyse via Python-Skript** — pdfplumber + python-docx + openpyxl, Output in UTF-8-Datei schreiben (nicht stdout)
5. **Encoding-PFLICHT fuer alle Python-Skripte mit Unicode-Output** — Am Skriptanfang IMMER: `sys.stdout.reconfigure(encoding='utf-8', errors='replace')` + Dateien mit `open(..., encoding='utf-8')` schreiben. Windows-Konsole (cp1252) crasht sonst bei Unicode (z.B. koreanische Zeichen `\uac00` aus Whisper, oder Sonderzeichen `U+2610` aus PDFs)

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
