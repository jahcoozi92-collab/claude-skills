# Beobachtungen zur späteren Überprüfung

Hier werden Beobachtungen gespeichert, die beim `/reflect`-Befehl abgelehnt wurden, aber für spätere Überprüfung interessant sein könnten.

---

## Format

```
### [DATUM] - Session-Kontext

**Konfidenz:** LOW/MEDIUM
**Beobachtung:** Was wurde bemerkt
**Mögliche Änderung:** Was könnte man tun
**Grund für Ablehnung:** Warum wurde es nicht übernommen
```

---

## Einträge

### 2026-05-29 — Eigene Lesson sofort falsifiziert (Pfad-Länge, nicht `&&`)

**Konfidenz:** MEDIUM
**Beobachtung:** Im Commit `e419f52` wurde die Lesson kodifiziert: „KEIN `&&` in User-Befehlen — bricht auch unter 100 Zeichen". 10 Minuten später lief `scp Jahcoozi@192.168.22.90:/tmp/o.sh /tmp/ && bash /tmp/o.sh` (~58 Zeichen) sauber durch. Falsifikation: nicht `&&` ist der Bruch-Trigger, sondern **Pfad-Länge → Terminal-Auto-Wrap, das zufällig vor `&&` landet** wenn die Zeile lang genug ist. `&&` ist Symptom, nicht Ursache.
**Mögliche Änderung:** Lesson in `reflect/SKILL.md` (Step 5) verfeinern: statt absoluter `&&`-Verbot besser „Befehle so kurz halten, dass keine Terminal-Auto-Wrap-Position vor strukturellen Tokens (`&&`, `||`, `;`) entsteht". Praktische Faustregel weiterhin: separate Zeilen sicherer als Verkettung.
**Grund für Ablehnung:** Eine einzelne Falsifikation ist noch kein Pattern. Wenn der Fall mehrfach in den nächsten Reflect-Runden wiederkommt → in Skill übernehmen. Bis dahin als ehrliche Beobachtung hier ablegen.

### 2026-05-29 — Reflect-Frequenz: 3× pro Session ist hochfrequent

**Konfidenz:** LOW
**Beobachtung:** Diese Session hatte drei `/reflect`-Aufrufe hintereinander. Erster brachte 16 substanzielle Lessons (rag-system + nas-instance), zweiter 3 Meta-Lessons über reflect selbst, dritter eine Lesson-Falsifikation. Abnehmender Grenznutzen erkennbar.
**Mögliche Änderung:** Workflow könnte eine Heuristik bekommen — z.B. „bei < 3 echten Korrekturen/Erfolgen seit letztem Reflect-Commit: OBSERVATIONS statt Commit empfehlen". Aktuell muss Claude das ad-hoc abwägen.
**Grund für Ablehnung:** Nicht generalisierbar nach einer Session. Wenn Diana das Muster über mehrere Wochen bestätigt → in Skill übernehmen.
