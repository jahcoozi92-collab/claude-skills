# Pending-Ontologie-Eintrag: 2026-08-19 — Jarvis-Lagebericht-Session

Anlass: /reflect am 2026-08-20; Clawbot-VM (192.168.22.206) per SSH nicht
erreichbar — der Key aus `/volume1/docker/.claude-automation/` wird für
Jahcoozi/clawbot/diana/root mit „Permission denied (publickey)" abgelehnt.
Der SSH-Zugang selbst gehört geprüft (Memory `nas_vm_ssh_zugang` ist
möglicherweise veraltet).

Beim nächsten erreichbaren Graphen einzupflegen:

## Konzepte / Muster
- **Muster „Formvarianz statt Wortlisten"** (betrifft: Sprachberichte,
  LLM-Prompts): Wiedererkannt wird der Aufbau, nicht der Wortlaut.
  Umsetzungen: gewürfelte Themen-Reihenfolge aus geprüften Plänen,
  optionale Einleitung, Telegramm-Knappformen; bei LLM-Berichten eine pro
  Lauf gewürfelte Bau-Anweisung („Tagesform").
- **Falle „Jinja-Kommentar-Endezeichen im Kommentartext"** → Kommentar
  endet mittendrin, Rest wird Ausgabe. Prüfweg: Makro rendern
  (ha_eval_template), nie nur lesen.
- **Falle „Trim-Tags fressen Leerraum"** → nötige Leerzeichen in den
  Ausdruck (`' ' ~ …`), nie als bloßes Zeichen neben `{{`.
- **Falle „Deutscher Tausendertrenner im LLM"** → „1.6" wird als 1600
  gelesen; Dezimalzahlen in deutschen Prompts/Fakten immer mit Komma.
- **Falle „LLM-Paraphrasen-Drift"** → Modell ersetzt Fachbegriffe durch
  Beinahe-Synonyme (Rollos→Fenster) und kippt damit Aussagen; Begriffs-
  paare im Prompt festnageln, beim Gegenlesen gezielt prüfen.
- **Prüfmuster „Würfel-Gates über ~20 Ziehungen"** statt weniger
  Integrationsläufe.

Quelle: `home-assistant/SKILL.md`, Sektion „2026-08-19", Commit fbd6521.
