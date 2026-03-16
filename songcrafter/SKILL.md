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
1. **StepStyle.tsx** - Genre, Mood, Vocals, Referenz-Audio, **World Hit Remix**
2. **StepLyrics.tsx** - Lyrics-Editor mit Sektionen
3. **StepGenerate.tsx** - Prompt-Optimierung + Audio-Generierung

### World Hit Remix Feature
- Upload beliebiges Audio als Remix-Grundlage
- Drei Remix-Styles: Faithful, Reimagined, Genre-Flip
- Intensitäts-Regler (1-5): 1=subtil, 5=komplett neu
- Automatische Analyse von BPM, Genre, Mood, Energy
- Spezieller Remix-Prompt-Generator: `generateRemixPrompt()` in geminiService.ts

#### Remix State-Felder (types.ts)
```typescript
isRemixMode?: boolean;
remixStyle?: 'faithful' | 'reimagined' | 'genre-flip';
remixIntensity?: number; // 1-5
referenceAnalysis?: {
  originalBpm?: number;
  originalKey?: string;
  originalGenre?: string;
  originalMood?: string;
  originalEnergy?: number;
};
```

### URL-Analyse (3-Schritt-Verfahren)
1. **Metadaten-Recherche**: Songbpm.com, Tunebat.com → BPM, Key, Genre
2. **Lyrics-Recherche**: Genius.com, AZLyrics → Original-Lyrics
3. **Strukturierte Kombination**: Validierung gegen `constants.ts`

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

### Prompt-Optimierung (KRITISCH!)
- ❌ NIEMALS User-Lyrics durch Gemini-generierte Lyrics ersetzen
- ❌ NIEMALS `lyrics_prompt` von Gemini generieren lassen wenn User Lyrics eingegeben hat
- ✅ `optimizePromptWithGemini()` MUSS Original-User-Lyrics als `lyrics_prompt` zurückgeben
- ✅ Gemini generiert NUR den Musik-Prompt, NICHT die Lyrics

### URL-Analyse (Web-Einstufung)
- ❌ NIEMALS nur einen API-Call für Metadaten + Lyrics machen
- ❌ NIEMALS BPM raten ohne Musik-Datenbanken zu konsultieren
- ✅ IMMER 3-Schritt-Analyse: 1) Metadaten, 2) Lyrics, 3) Kombination
- ✅ IMMER auf Songbpm.com, Tunebat.com, GetSongKey.com nach BPM/Key suchen
- ✅ IMMER Genre/Substyle gegen `constants.ts` GENRES validieren
- ✅ IMMER BPM-Fallback basierend auf Genre-Defaults

### MiniMax Music Lyrics-Sprache (KRITISCH!)
- ❌ NIEMALS davon ausgehen, dass MiniMax die Lyrics-Sprache automatisch erkennt
- ❌ NIEMALS `prompt` ohne expliziten Sprach-Hinweis bei nicht-englischen Lyrics
- ✅ IMMER Spracherkennung aus Lyrics durchführen (Umlaute, deutsche Wörter)
- ✅ IMMER "German vocals, sung in German" in `prompt` wenn deutsche Lyrics
- ✅ IMMER `lyrics_prompt` mit Sprach-Prefix: `[GERMAN LYRICS - SING IN GERMAN]`

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

### MiniMax Music ignoriert Lyrics-Sprache
**Symptom:** Deutsche Lyrics werden auf Englisch gesungen, Prompt wird ignoriert
**Ursache:** MiniMax Music braucht explizite Sprach-Anweisung im `prompt`-Feld
**Lösung:**
- `geminiService.ts`: Automatische Spracherkennung aus Lyrics
- Prompt-Generierung fügt "German vocals, sung in German" hinzu
- `falService.ts`: Double-Check und Prefix `[GERMAN LYRICS - SING IN GERMAN]`

---

## Suno Audio Post-Processing & Remastering

### Suno-spezifische Artefakte

Suno's "Extend"-Feature erzeugt charakteristische Splice-Artefakte:

| Artefakt | Symptom | Erkennung |
|----------|---------|-----------|
| **Stereo-Kollaps** | L/R-Korrelation fällt auf -0.39 (Anti-Phase!) | Frame-Korrelation < 0.3 |
| **L/R Balance-Drift** | Ein Kanal bis +7.8dB lauter | \|Balance\| > 3dB |
| **Spectral Holes** | Ganze Frequenzbänder fehlen am Splice | Multi-Band STFT-Analyse |
| **Level-Dips** | 5-11dB Löcher an Sektions-Grenzen | RMS < Median - 5dB |
| **Über-Kompression** | LRA 3.8-4.4 LU, Crest Factor ~5 | Loudnorm Pass 1 |

### Analyse-Pipeline (Godmode)

```
Phase 1: STFT Deep-Analysis
  - 20ms Blöcke, 2049 Freq-Bins (0-24kHz)
  - 4-Band RMS-Envelope (Sub/Low/Mid/High)
  - Onset-Detection via Spectral Flux
  - Frame-Level Stereo-Korrelation + Balance
  - Multi-dimensionaler Anomalie-Score

Phase 2: Surgical Repair (Frequenzdomäne!)
  - Per-Frequency-Bin Volume Correction (Target = 70% Referenz-Median)
  - Adaptive Spectral Crossblend bei Korr < 0.6
  - Spectral Interpolation aus Nachbar-Frames bei Holes
  - ISTFT Rekonstruktion

Phase 3: Musical Mastering
  - Cubic-Spline Gain-Automation (NICHT Stufen-Funktion!)
  - Automatische Sektions-Erkennung (Onset-Density + Energie-Perzentile)
  - Multi-Band Spectral Balance Verifikation
  - Soft-Knee tanh-Limiter

Phase 4: EBU R128 Normalisierung
  - Loudnorm Pass 1 (Messung)
  - Loudnorm Pass 2 (linear=true, kein Re-Compress)
  - Ziel: -14 LUFS, -1dB TP, LRA 8-11 LU
```

### Constraints (Audio-Mastering)

- ❌ NIEMALS nur RMS für Anomalie-Erkennung — IMMER Stereo-Korrelation + Balance + Spectral
- ❌ NIEMALS überlappende Gaussians multiplizieren — Envelope-basiert (Target vs Ist)
- ❌ NIEMALS ffmpeg `compand` für Sektions-Dynamik — arbeitet auf Sample-Ebene, nicht Sektions-Ebene
- ❌ NIEMALS `loudnorm` ohne `linear=true` im Pass 2 — komprimiert die Expansion zurück
- ✅ IMMER Stereo-Phase reparieren VOR Volume-Korrektur
- ✅ IMMER in Frequenzdomäne (STFT) arbeiten statt Zeitdomäne für Artefakt-Reparatur
- ✅ IMMER Section-Dynamics mit smooth Gain-Automation (Gaussian-Smoothing, Cubic Spline)
- ✅ IMMER Soft-Knee Limiter (tanh) statt Hard-Clip

### Preview-Schnitt Strategie

Für Geburtstagslieder / Überraschungs-Teaser:
- **Bridge bevorzugen**: Persönlich, intim, verrät nicht den Chorus-Hook
- **Verse 2 als Alternative**: Poetisch, nicht repetitiv
- **NICHT**: Intro (zu erwartbar), Chorus (Überraschung bewahren), Climax (Höhepunkt aufsparen)
- Fade: 2s In, 3s Out — länger Out für Mystery-Effekt
- Länge: 20-25s

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

**MiniMax Music Sprach-Enforcement:**
- MiniMax Music v2 ignoriert `lyrics_prompt` Sprache wenn `prompt` keine Anweisung enthält
- IMMER Spracherkennung aus Lyrics durchführen
- Bei deutschen Lyrics: `prompt` MUSS "German vocals" oder "sung in German" enthalten
- Zusätzlich: `lyrics_prompt` mit Sprach-Prefix versehen: `[GERMAN LYRICS - SING IN GERMAN]`
- Dreifache Absicherung: Gemini-Prompt, Fallback-Check, fal.ai-Service-Check

### 2026-03-16 - Suno Audio Remastering Session

**Suno Artefakt-Erkennung (3 Analyse-Levels):**
- Level 1 (RMS only): Findet 3 von 19 Artefakten — unzureichend
- Level 2 (RMS + Stereo + Balance, 50ms): Findet 9 von 19 — besser
- Godmode (STFT + Multi-Band + Onset + M/S, 20ms): Findet alle 19 — vollständig
- Lektion: Multi-dimensionale Analyse ist PFLICHT, nicht optional

**Stereo-Reparatur ist kritisch:**
- Suno Extend erzeugt Anti-Phase (Korrelation bis -0.39!)
- Volume-Boost allein hilft NICHT bei Phase-Problemen
- STFT-Domain Crossblend repariert Stereo ohne Artefakte
- Korrelation 0.03 → 0.95 möglich mit spectral crossblend

**Section-Based Dynamics funktioniert, compand nicht:**
- ffmpeg `compand` arbeitet auf Sample-Ebene → kann Sektions-Kompression nicht aufbrechen
- LRA-Verbesserung mit compand: 3.8 → 4.3 LU (marginal)
- LRA-Verbesserung mit Section-Gains: 3.8 → 9.7 LU (massiv)
- Cubic-Spline Automation statt Step-Functions für unhörbare Übergänge

**Gaussian-Stacking Bug:**
- Mehrere Gaussians im Volume-Filter MULTIPLIZIEREN sich
- Peak bei 4.24x FS (statt erwartet ~1.0x) weil 5 Gaussians überlappten
- Lösung: Envelope-basiert arbeiten (Target vs Ist pro Block, max-Operator statt Multiplikation)

**Spectral Interpolation:**
- Bei Splice-Artefakten fehlen ganze Frequenzbänder
- Nachbar-Frames (±2) können als Interpolations-Quelle dienen
- Gewichtung: 30% × fade / Abstand — natürlich klingend

### 2026-01-31 - Lyrics & URL-Analyse Session

**User-Lyrics Preservation (KRITISCH):**
- `optimizePromptWithGemini()` hat fälschlicherweise Gemini-generierte Lyrics zurückgegeben
- User-Lyrics wurden überschrieben → englische Lyrics statt deutscher
- FIX: Gemini generiert NUR den Musik-Prompt, Original-Lyrics werden durchgereicht
- `lyrics_prompt: userLyrics || "[Instrumental]"` am Ende der Funktion

**URL-Analyse Verbesserung:**
- Alte 2-Schritt-Analyse war ungenau für BPM/Genre
- Neue 3-Schritt-Analyse:
  1. Metadaten von Songbpm.com, Tunebat.com, GetSongKey.com
  2. Lyrics von Genius.com, AZLyrics (separat!)
  3. Strukturierte Kombination mit Validierung
- BPM-Extraktion aus Text: `/BPM[:\s]*(\d{2,3})/i`
- Fallback-BPM pro Genre in `genreBpmDefaults`

**World Hit Remix Feature:**
- Prominente UI-Box in StepStyle.tsx
- Drei Remix-Styles mit unterschiedlichen Prompt-Strategien
- Intensitäts-Slider (1-5) beeinflusst Prompt-Formulierung
- `generateRemixPrompt()` nutzt Original-Analyse als Referenz
- Remix-Badge in StepGenerate.tsx zeigt aktiven Modus
