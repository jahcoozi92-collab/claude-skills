# Medien-Schnitt Skill – Audio- und Video-Schnitt mit ffmpeg

| name | description |
| ---- | ----------- |
| medien-schnitt | Audio-Ausschnitte auf musikalischen Grenzen schneiden, Standbild-Videos für Social Media bauen (WhatsApp Status, Reels), Ken-Burns-Bewegung, Bildretusche. Trigger: "schneide den Song ab", "WhatsApp Status", "Video aus Bild und Musik", "langsam reinzoomen", ffmpeg-Fragen zu Schnitt/Fade/Zoom. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:** Wenn Diana aus einem Lied ein 30-Sekunden-Stück schneiden will und ein
Foto dazu, damit daraus ein kleines Video wird — dann steht hier drin, wie das geht, ohne dass es
schief klingt oder ruckelt. Und es steht drin, welche Fehler ich schon gemacht habe, damit ich sie
nicht nochmal mache.

---

## Umgebung (Yoga7, Stand 2026-08-13)

| Werkzeug | Status |
| --- | --- |
| ffmpeg / ffprobe | `/usr/bin`, Version 8.1.2 |
| numpy, scipy, Pillow | vorhanden (Pillow 12.3) |
| **librosa** | installiert, aber **unbrauchbar — `numba` fehlt** |
| Schriften | `NotoSans-{Regular,Medium,SemiBold,Bold}.ttf`, `NotoColorEmoji.ttf` |
| Zwischenablage | `wl-copy` / `wl-paste` (Wayland), `xclip`, `copyq` |

**librosa NICHT einplanen.** `librosa.load` wirft `ModuleNotFoundError: No module named 'numba'`.
Analyse stattdessen selbst bauen: WAV per ffmpeg dekodieren, `scipy.signal.stft` für das Spektrum,
Spectral Flux als Onset-Kurve, Autokorrelation für das Tempo. Das reicht für Beats, Phrasengrenzen
und Dynamik vollständig aus.

---

## NIEMALS (jede Regel steht für einen realen Fehlschlag)

### 1. `afade`/`fade` mit ABSOLUTEN Zeitstempeln nach `-ss` vor `-i`

`-ss 155.65 -i datei.mp3` setzt die Zeitstempel des Ausschnitts auf **0** zurück. Ein
`afade=t=in:st=155.65` startet damit nie — und weil `afade t=in` **vor** seinem Startzeitpunkt
stummschaltet, ist die **gesamte Datei still**.

```bash
# FALSCH — Ergebnis ist komplett stumm, ffmpeg meldet KEINEN Fehler
ffmpeg -ss 155.65 -to 215.62 -i in.mp3 -af "afade=t=in:st=155.65:d=0.06" out.mp3

# RICHTIG — Fades clip-relativ, Fade-out ab (Cliplänge - Fadedauer)
ffmpeg -ss 155.65 -to 215.62 -i in.mp3 \
  -af "afade=t=in:st=0:d=0.06,afade=t=out:st=58.97:d=1.0" out.mp3
```

Am 2026-08-13 lagen beide stummen MP3s bereits in `~/Downloads`, bevor die Pegelmessung es auffliegen
ließ. **Ohne Verifikation wäre das ausgeliefert worden.**

### 2. `-shortest` bei Standbild + Audio

`-loop 1` erzeugt einen endlosen Videostrom; `-shortest` schneidet ihn erst an der nächsten
GOP-Grenze ab. Ergebnis: **32,77 s Video zu 30,85 s Audio** — fast zwei Sekunden Standbild mit Stille.
Immer `-t <exakte_dauer>` setzen.

### 3. `zoompan` für Ken Burns auf Standbildern

`zoompan` rundet Ausschnittsgröße und -position auf ganze Eingangspixel. Der Zoom springt dadurch in
Stufen: gemessene Frame-Differenzen **0,007 bis 3,994** — Frames ohne jede Änderung, gefolgt von
sichtbaren Sprüngen. Vorskalieren mildert es, beseitigt es aber nicht. Siehe Rezept E.

### 4. Bilddateien mit Daten hinter dem Dateiende

Ein PNG aus einem Download hatte **1.902 Bytes Müll nach dem `IEND`-Chunk**. Anzeigeprogramme und
`ffprobe` ignorieren das, aber `-loop 1` liest den Rest als weiteres Bild:
`Invalid PNG signature 0x910D08000000` in Endlosschleife bis zum Timeout.

```python
d = open(pfad, 'rb').read()
open(ziel, 'wb').write(d[:d.find(b'IEND') + 8])   # 4 Byte Typ + 4 Byte CRC
```

Prüfen lohnt bei jeder Datei aus Browser-Downloads oder Chat-Uploads.

### 5. "Fertig" ohne Messung melden

Bei Audio und Video sagt ein fehlerfreier ffmpeg-Lauf **nichts** über das Ergebnis. Siehe Abschnitt
Verifikation — sie hat in einer einzigen Session drei Fehler gefunden, die sonst ausgeliefert worden wären.

---

## Musikkopplung: Dynamik schlägt Beat-Raster

**Gilt für Schnitt UND Bewegung UND Effekte.** Die Regel stand als Schnitt-Regel bereits in
`feedback_musikvideo_schnitt.md` ("energy profile für Phrasen-Grenzen, NICHT beat_track") — am
2026-08-13 wurde sie beim Schnitt befolgt, bei der Kamerabewegung aber nicht, und Diana musste sie
erneut einfordern ("gibt es nichts gefühlvolleres als pulsieren?").

| Wirkung | Falsch | Richtig |
| --- | --- | --- |
| Schnittpunkte | Beat-Raster, feste Sekundenzahl | Phrasengrenzen aus dem Pegelprofil |
| Kamerabewegung | Zoom-Puls auf jedem Beat | Bewegungsintensität folgt der geglätteten Dynamik |
| Bewegungstempo | konstant | beschleunigt dort, wo die Musik drängt |

Ein Beat-Puls erzeugt Bewegungsspitzen vom **50-Fachen** der Grundbewegung — das Bild steht zwischen
den Schlägen und ruckt dann. Das liest sich als Effekt. Bei organischer Bewegung liegt die Spitze
beim **1,2- bis 1,8-Fachen**, und die Intensität wächst zum musikalischen Höhepunkt hin (gemessen:
Ø 0,21 in ruhiger Passage gegen Ø 0,51 im Höhepunkt).

---

## Rezept A – Musikalische Struktur finden

```python
# WAV: ffmpeg -i in.mp3 -ac 1 -ar 22050 -c:a pcm_s16le mono.wav
sr, y = wavfile.read('mono.wav'); y = y.astype(np.float32)/32768.
f, t, Z = stft(y, fs=sr, nperseg=1024, noverlap=1024-256, boundary=None, padded=False)
logS = np.log1p(1000*np.abs(Z))
flux = np.concatenate([[0], np.maximum(0, np.diff(logS, axis=1)).sum(axis=0)])   # Onsets
ac = np.correlate(flux, flux, 'full')[len(flux)-1:]; ac /= ac[0]                 # Tempo
```

- **Tempo:** Autokorrelationsmaximum im Bereich 0,55–1,1 s (55–110 BPM). Der Bereich 0,3–0,55 s
  liefert oft einen stärkeren Peak — das ist die **halbe** Periode, nicht das Grundtempo.
- **Phrasengrenze:** kurzer Pegeleinbruch (3–5 dB über 0,3–0,5 s) direkt vor einem kräftigen Einsatz.
  In 50-ms-Fenstern messen; 0,5-s-Fenster verwischen sie.
- **Schnittkante:** direkt an den Onset legen, 20–30 ms davor, damit der Transient ganz drin ist.
- `astats` in ffmpeg ist für Pegelverläufe **untauglich** — ohne `reset` akkumuliert es über den
  ganzen Track und die Kurve bewegt sich kaum. In Python messen.

## Rezept B – Länge anpassen, ohne den Schnitt zu zerstören

Wenn ein musikalisch sauberer Ausschnitt eine harte Längengrenze knapp überschreitet: **nicht**
abschneiden, sondern minimal raffen. `atempo` hält die Tonhöhe.

```bash
# 30,85s -> 29,82s, beide Schnittkanten bleiben musikalisch
-af "atempo=1.035,afade=t=in:st=0:d=0.06,afade=t=out:st=29.52:d=0.29"
```

Bis etwa 3–4 % ist der Unterschied ohne direkten Vergleich nicht wahrnehmbar. **Immer offenlegen** —
es ist eine Manipulation am Original, auch wenn sie niemand hört.

## Rezept C – Standbild-Video für WhatsApp Status

```bash
ffmpeg -loop 1 -framerate 30 -i bild.png -i audio.mp3 \
 -filter_complex "\
 [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,\
gblur=sigma=50,eq=brightness=-0.06:saturation=0.9[bg];\
 [0:v]scale=1080:-2:flags=lanczos[fg];\
 [bg][fg]overlay=(W-w)/2:455,format=yuv420p[v]" \
 -map "[v]" -map 1:a -t 29.82 -c:v libx264 -profile:v high -preset medium -crf 20 \
 -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -ar 44100 -ac 2 -movflags +faststart out.mp4
```

| Punkt | Wert |
| --- | --- |
| Format | 1080×1920, H.264 High, yuv420p, AAC, `+faststart` |
| Länge normaler Status | **max. 30 s** (längeres wird gesplittet) |
| Hintergrund | weichgezeichnetes, leicht entsättigtes Bild — **nie** schwarze Balken |
| Vertikale Position | Foto **oberhalb** der Mitte (`overlay=…:455` statt `(H-h)/2`) |

Das Foto sitzt höher, weil WhatsApp unten die Antwortleiste über das Bild legt. Bei einem
Querformat-Foto ist ein formatfüllender 9:16-Ausschnitt meist unmöglich, ohne Personen anzuschneiden —
Blur-Hintergrund ist dann richtig, nicht Notlösung.

**Text/Spruch: nicht ungefragt einbrennen.** Es gibt zwei Wege — eingebrannt oder als Bildunterschrift
in WhatsApp. Diana wollte am 2026-08-13 die Bildunterschrift ("nein, nicht ins Video einbrennen").
Kurz fragen. Den Spruch per `wl-copy` in die Zwischenablage legen, das spart ihr das Abtippen.

**Das Posten selbst gehört Diana.** Ein Status geht an alle Kontakte — nie automatisieren wollen.

## Rezept D – Farb-Emoji rendern

`drawtext` kann `NotoColorEmoji.ttf` nicht (CBDT-Bitmap-Font). Über Pillow: Emoji separat in der
festen Größe 109 px mit `embedded_color=True` rendern, per `getbbox()` zuschneiden, auf die Textgröße
skalieren und ins Textbild komponieren.

## Rezept E – Ken Burns, subpixelgenau

Statt `zoompan`: Frames in Python rechnen und roh an ffmpeg pipen. `Image.resize(..., box=...)`
akzeptiert **Fließkomma-Koordinaten** — daher keine Pixelstufen.

```python
f = img.resize((W, H), Image.LANCZOS, box=(cx, cy, cx+cw, cy+ch))
sys.stdout.buffer.write(f.tobytes())
```

```bash
python3 zoom.py | ffmpeg -loop 1 -framerate 30 -i bild.png \
  -f rawvideo -pix_fmt rgb24 -s 1080x771 -framerate 30 -i - -i audio.mp3 \
  -filter_complex "[0:v]…[bg];[bg][1:v]overlay=(W-w)/2:455,…[v]" -map "[v]" -map 2:a …
```

- Zoom **7–11 %** über 30 s. Mehr wirkt als Effekt.
- **Smoothstep** (`e = p*p*(3-2*p)`) statt linear — linear setzt hart ein und stoppt hart.
- Startzoom **> 1.0** (z. B. 1,05), wenn zusätzlich gedriftet wird — bei 1,0 gibt es keinen Rand,
  die Drift würde am Bildrand klemmen.
- Nur den Vordergrund bewegen, den Blur-Hintergrund ruhig lassen.
- Kosten: ~23 s Rechenzeit für 895 Frames, etwa 5–7 MB statt 1,9 MB bei Standbild.

## Rezept F – Organische Kamerabewegung

```python
env = gaussian_filter1d(db_pro_frame, sigma=22)        # ~0,7 s -> Dynamik, keine Einzelschläge
dyn = np.clip((env - p5) / (p95 - p5), 0, 1)
staerke = 0.40 + 0.60*dyn                              # Bewegung atmet mit der Musik
tempo  = 0.45 + 0.55*dyn                               # Zoomfahrt beschleunigt im Höhepunkt
fort   = np.cumsum(tempo); fort = (fort-fort[0])/(fort[-1]-fort[0])
```

Drift aus **gefiltertem Rauschen in zwei Geschwindigkeiten** (`gaussian_filter1d`, sigma 70 und 25
Frames, zweite mit Gewicht 0,4) — das ergibt eine Bewegung wie bei gehaltener Kamera, die sich nie
wiederholt. Seed setzen, damit ein Rerender identisch bleibt. Amplituden: x ±17 px, y ±11 px,
Zoom ±0,35 %. Dazu ein Bild-Fade von 0,5 s am Anfang und 0,7 s am Ende, passend zum Audio-Ausklang.

## Rezept G – Bildretusche mit Maske und Helligkeitsschwelle

Beispiel Sonnenbrille abdunkeln: geometrische Maske **kombiniert** mit einer Helligkeitsschwelle.
Die Geometrie grenzt den Bereich ein, die Schwelle schützt alles Helle darin.

```python
def superellipse(cx, cy, ax, ay, n=3.0):        # n=3 passt zu abgerundet-eckigen Gläsern
    return (np.abs((xx-cx)/ax)**n + np.abs((yy-cy)/ay)**n) <= 1.0
maske = (glas & (lum < 105)).astype(np.float32)
maske = gaussian_filter(maske, sigma=2.0) * np.clip((105-lum)/25.0, 0, 1)   # weiche Kante + Rolloff
out = a * (1.0 - maske[..., None]*(1.0-0.50))
```

Vorher Stichproben messen (`Haut ~155-175, Glas ~12-57, Haare ~22-75`) und die Schwelle dazwischen
legen. Der Rolloff verhindert eine harte Kante zur Haut. Reflexe im Glas bleiben erhalten, weil sie
über der Schwelle liegen — das ist erwünscht, sonst wirkt die Fläche tot.

---

## Verifikation (Pflicht vor jeder "fertig"-Meldung)

**Audio — Pegel an den Rändern:**

```python
head = [20*np.log10(np.sqrt((y[i*w:(i+1)*w]**2).mean())+1e-9) for i in range(8)]
```

Erwartung: Anfang auf Nutzpegel (−10 bis −20 dB), Ende fallend. **−180 dB heißt stumm.**

**Video — Bewegung zwischen aufeinanderfolgenden Frames:**

```bash
ffmpeg -ss 10 -i out.mp4 -frames:v 24 -vf "crop=…,scale=270:-2" frames/f%03d.png
# je Paar: np.abs(a-prev).mean()
```

| Befund | Bedeutung |
| --- | --- |
| Werte gleichmäßig (Verhältnis max/min < 2) | flüssige Bewegung |
| einzelne Nullen, dann Sprünge | Pixelstufen — `zoompan`-Problem |
| Spitzen ≫ 10× Durchschnitt | ruckartiger Effekt, kein Fluss |

**Dauer beider Spuren einzeln prüfen** (`-select_streams v` und `a`), nicht nur `format=duration`.

**Bildergebnis wirklich ansehen** — Frame extrahieren und lesen. Zahlen zeigen nicht, ob ein Layout
stimmt.

---

## Was hier NICHT geht

- **Posten in soziale Netze.** Kein Zugriff auf WhatsApp; ein Status geht an alle Kontakte.
- **librosa.** Siehe Umgebung.
- **Dateien im Arbeitsverzeichnis ablegen und später wiederfinden** — in der Sandbox geschriebene
  Dateien können verschwinden. Zwischenergebnisse in das Scratchpad-Verzeichnis schreiben, absolute
  Pfade verwenden.
- **`for spec in "a b"; set -- $spec`** — zsh splittet nicht. Befehle einzeln schreiben.

## Verwandtes Wissen

- `feedback_musikvideo_schnitt.md` — Phrasen statt Beat-Raster, 1 Textzeile = 1 Clip
- `feedback_kreativ_level_eskalation.md` — mehr Technik ist selten die Antwort auf "kreativer"
- `reference_ffmpeg_xfade.md` — Crossfades, `LC_NUMERIC=C`, Color-Grading
- `reference_ffmpeg_segment_pipeline.md` — Pipeline für Videos mit vielen Segmenten
