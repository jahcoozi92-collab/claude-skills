---
name: reflect
description: Analysiert die aktuelle Session und schlägt Verbesserungen für andere Skills vor. Nutze, wenn der Nutzer "reflect", "lerne daraus", "merk dir das" sagt, oder am Ende skill-intensiver Sessions.
---

# Reflect — Selbstverbesserung für dein Skill-System

## Was dieser Skill tut

Er ist der Regelkreis, der das ganze Kit am Leben hält: Nach einer Session schaut er
zurück — was wurde korrigiert, was hat funktioniert, was fehlte — und schreibt daraus
konkrete Regeln in die betroffenen Skills. Ohne ihn sind Skills Schnappschüsse, die
veralten. Mit ihm lernt das System aus jeder echten Nutzung.

---

## Trigger

Führe `/reflect` oder `/reflect [skill-name]` am Ende einer Session aus, in der du einen
Skill genutzt hast.

```
/reflect                 → fragt, welchen Skill analysieren
/reflect prompt-coach    → analysiert direkt diesen Skill
```

---

## Workflow

### Schritt 1: Skill identifizieren

Ohne Angabe fragen, welcher Skill/Bereich gemeint ist.

### Schritt 2: Konversation analysieren

Suche nach vier Signaltypen:

**Korrekturen (hohe Konfidenz)** — "Nein", "so nicht", explizite Änderungen am Output,
sofortige Nachbesserung nach Generierung.

**Erfolge (mittlere Konfidenz)** — "perfekt", "genau so", Output ohne Änderung
übernommen oder weiterverwendet.

**Edge Cases (mittlere Konfidenz)** — Fragen, die der Skill nicht vorhergesehen hat;
Workarounds; gewünschte, aber nicht abgedeckte Fälle.

**Präferenzen (akkumulieren über Sessions)** — wiederkehrende Muster in Entscheidungen,
Stil- und Tool-Präferenzen.

### Schritt 3: Änderungen vorschlagen

Präsentiere die Erkenntnisse klar priorisiert (hoch/mittel/niedrig) mit konkretem
Vorschlagstext pro Änderung — nie vage. Frage explizit nach Freigabe, bevor etwas
geschrieben wird.

### Schritt 4: Bei Freigabe

1. Aktuelle Skill-Datei lesen
2. Änderung mit dem Edit-Tool anwenden
3. Lokal committen mit kurzer, beschreibender Commit-Message
4. Push als eigenen, separat bestätigten Schritt behandeln — Freigabe einer
   Skill-Änderung ist nicht automatisch Freigabe für einen Push auf den Hauptbranch
5. Bestätigen, was geändert und gepusht wurde

### Schritt 5: Bei Ablehnung

Fragen, ob die Beobachtung trotzdem für später in einer Notizdatei festgehalten werden
soll, statt sie zu verwerfen.

---

## Beispiel-Session

```
Nutzer: "Erstelle mir eine Übersicht der offenen Aufgaben als Tabelle."
Claude: *liefert Tabelle mit 4 Spalten*
Nutzer: "Nein, ich brauche eine fünfte Spalte für die Priorität."
Claude: *korrigiert*
Nutzer: "Perfekt. Und sortiere immer nach Fälligkeit, nicht alphabetisch."
```

```
/reflect

┌─ Skill-Reflexion ─────────────────────────────────────────┐
│ Signale: 1 Korrektur, 1 Erfolg                             │
│                                                             │
│ Vorgeschlagene Änderungen:                                 │
│ [HOCH]   + Tabellen-Format braucht immer eine               │
│            Prioritäts-Spalte                                │
│ [MITTEL] + Standard-Sortierung: nach Fälligkeit             │
│                                                             │
│ Diese Änderungen anwenden? [J]a / [N]ein / Anpassen         │
└─────────────────────────────────────────────────────────────┘
```

---

## Wichtige Regeln

1. Immer die exakte Änderung zeigen, bevor sie angewendet wird
2. Nie Skills ohne explizite Zustimmung ändern
3. Commit-Messages kurz und beschreibend halten
4. Push ist ein eigener, bestätigter Schritt — nicht Teil der stillschweigenden Freigabe
5. Skill-übergreifende Regeln, die immer gelten sollen, gehören nicht in einen einzelnen
   Skill, sondern in eine projektweite Konfigurationsdatei (z. B. `CLAUDE.md`)

---

## Wie dieser Skill mit der Zeit wächst

Jede Session, in der du `/reflect` aufrufst, ist ein Datenpunkt. Nach einigen Sessions
bekommt jeder Skill in diesem Kit eine eigene, aus echter Nutzung gewachsene
Lektionen-Sektion — das ist der Teil, den kein generisches Template vorwegnehmen kann,
weil er aus deiner tatsächlichen Arbeit entsteht.
