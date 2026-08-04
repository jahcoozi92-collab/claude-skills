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

*Noch keine Einträge. Beobachtungen werden hier gespeichert, wenn du bei `/reflect` wählst, sie für später aufzuheben.*

## 2026-08-04 — Ontology-Standort-Angabe für Yoga7 ist falsch (User-bestätigt: beim nächsten Reflect korrigieren)

- SKILL.md Step 4 behauptet: "Yoga7: Ontology ist LOKAL verfügbar — cd ~/clawd && python3 …"
- Realität (verifiziert 2026-08-04): Yoga7-lokaler Store ist LEER (0 Software/Pattern/Task) —
  der kanonische Graph liegt auf der Clawbot VM (192.168.22.206, 213 Software-Entities)
- Lokales Schreiben auf Yoga7 würde einen divergenten Fork erzeugen
- Funktionierender Weg von Yoga7: `ssh -o BatchMode=yes moltbotadmin@192.168.22.206 'bash -s' < skript.sh`
  (passwortlos, verifiziert) — Skill entsprechend umformulieren: ALLE Maschinen schreiben via SSH zur VM
→ UMGESETZT 2026-08-04: Step 5 in SKILL.md korrigiert (kanonischer Graph nur auf Clawbot VM).
