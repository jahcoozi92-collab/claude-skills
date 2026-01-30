# SongCrafter Pro Skill

Projektspezifischer Skill für die SongCrafter Pro AI Music Production App.

## Projekt-Info

| Key | Value |
|-----|-------|
| Pfad | `/volume1/docker/songcrafter` |
| URL | `https://songcraft.forensikzentrum.com` |
| Port | 3080 (Docker) → 80 (intern) |
| Stack | React 19 + TypeScript + Vite + Tailwind CSS 4 |
| APIs | Google Gemini (Analyse), fal.ai MiniMax Music v2 (Audio) |

---

## Architektur

### 3-Schritt-Wizard
1. **StepStyle.tsx** - Genre, Mood, Vocals, Referenz-Audio
2. **StepLyrics.tsx** - Lyrics-Editor mit Sektionen
3. **StepGenerate.tsx** - Prompt-Optimierung + Audio-Generierung

### Wichtige Services
- `geminiService.ts` - Audio-Analyse, Prompt-Optimierung, Lyrics-Generator
- `falService.ts` - Musik-Generierung, Upload, Status-Polling
- `storageService.ts` - LocalStorage für Presets, History, API-Keys

---

## Constraints (NIEMALS)

### fal.ai Integration
- ❌ NIEMALS davon ausgehen, dass fal.ai Storage sofort funktioniert
- ❌ NIEMALS Upload-Fehler die Generierung blockieren lassen
- ✅ IMMER FAL_STORAGE_INITIALIZATION_ERROR graceful abfangen
- ✅ IMMER Fallback ohne Referenz-Audio ermöglichen

### Tailwind CSS
- ❌ NIEMALS `cdn.tailwindcss.com` in Production verwenden
- ✅ IMMER PostCSS + `@tailwindcss/postcss` für Vite nutzen
- ✅ IMMER `styles.css` mit `@import "tailwindcss"` erstellen

### Formular-Felder
- ❌ NIEMALS `type="password"` außerhalb von `<form>` verwenden
- ✅ IMMER `autoComplete="off"` für API-Key-Inputs setzen
- ✅ IMMER `spellCheck="false"` für technische Inputs

### Gemini API
- ❌ NIEMALS ohne Retry-Logik API-Calls machen
- ❌ NIEMALS ohne Fallback-Prompt bei API-Fehlern
- ✅ IMMER Ergebnisse gegen bekannte Genre/Substyle-Listen validieren
- ✅ IMMER deutsche Fehlermeldungen für deutsche UI

---

## Präferenzen

### Sprache
- UI: Deutsch
- Fehlermeldungen: Deutsch
- API-Prompts: Englisch (für bessere KI-Ergebnisse)
- System-Instructions: Deutsch/Englisch gemischt OK

### Code-Stil
- TypeScript strict mode
- Funktionale React-Komponenten
- Services als separate Dateien
- Keine Klassen, nur Funktionen

### Audio-Einstellungen (Defaults)
- Format: FLAC (verlustfrei) oder MP3 256kbps
- Sample Rate: 44100 Hz
- Bitrate: 256000 bps

---

## Häufige Befehle

```bash
# Entwicklung
npm run dev              # Dev-Server auf Port 3000

# Build & Deploy
npm run build            # Production Build
docker compose up -d --build  # Deploy auf Port 3080

# Logs
docker logs songcrafter-pro -f
```

---

## API-Keys

| Service | Wo konfigurieren |
|---------|------------------|
| Gemini | `.env.local` → `GEMINI_API_KEY` |
| fal.ai | In der App: Menü → Settings |

### fal.ai Storage aktivieren
Beim ersten Mal muss der User manuell einen Test auf fal.ai durchführen:
1. https://fal.ai/models/fal-ai/minimax-music/playground
2. Audio-Datei hochladen (mind. 15 Sekunden)
3. Test-Run durchführen
4. Danach funktioniert Upload in SongCrafter

---

## Bekannte Issues

### Upload-Fehler bei fal.ai
**Symptom:** `FAL_STORAGE_INITIALIZATION_ERROR`
**Ursache:** Cloud-Speicher für Account nicht aktiviert
**Lösung:** Manueller Test auf fal.ai Playground (siehe oben)
**Workaround:** App generiert ohne Referenz-Audio weiter

### Transkription/Kategorisierung ungenau
**Symptom:** Falsches Genre, englische Lyrics für deutsche Songs
**Ursache:** Gemini rät statt zu transkribieren
**Lösung:** Verbesserte System-Instructions, Validierung gegen bekannte Listen

---

## Gelernte Lektionen

### 2026-01-30 - Initiale Session

**fal.ai:**
- Storage muss einmalig manuell aktiviert werden
- Upload-Fehler graceful abfangen, Generierung fortsetzen
- Playground-URL: `fal.ai/models/fal-ai/minimax-music/playground`

**Tailwind CSS:**
- CDN nur für Prototyping, NIE für Production
- Tailwind v4 nutzt `@tailwindcss/postcss` statt altem `tailwindcss` PostCSS-Plugin
- `@import "tailwindcss"` statt `@tailwind base/components/utilities`

**DOM-Warnungen:**
- Password-Felder müssen in `<form>` sein
- `autoComplete="off"` verhindert Browser-Autofill für API-Keys

**Gemini Service:**
- Singleton-Pattern für AI-Instanz
- Retry-Wrapper für alle API-Calls
- Fallback-Prompts wenn API fehlschlägt
- Genre/Substyle-Validierung gegen Constants
