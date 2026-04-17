#!/usr/bin/env python3
"""
Bereinigt Open WebUI Modelle auf 17 kuratierte Eintraege + aktualisiert Model Cards.
Setzt is_active=1 fuer KEEP, is_active=0 fuer alle anderen.
Schreibt vollstaendige meta (Beschreibung, Capabilities, Tags, Suggestion-Prompts).
Druckt keine Secrets.
"""
import sqlite3
import json
import sys
import time

DB_PATH = "/app/backend/data/webui.db"

# === KURATIERTE MODELL-LISTE (17 Modelle) ===
# Jeder Eintrag: (id, name, description, capabilities, tags, suggestion_prompts)

KEEP = {
    # ======== CLOUD FLAGSHIP ========
    "openrouter.anthropic/claude-opus-4.7": {
        "name": "✦ Claude Opus 4.7",
        "description": "Flagship-Modell (April 2026). Beste Leistung bei Coding, komplexer Analyse, Multi-Step-Agenten. Referenz-Niveau fuer alle anderen Modelle. Teuerster Cloud-Call, daher fuer wirklich anspruchsvolle Tasks nutzen.\n\nVergleich: = 100% (Referenz). Besser als GPT-5 bei Code und langen Kontexten, vergleichbar bei kreativen Texten.",
        "capabilities": {"vision": True, "usage": True, "citations": True},
        "tags": [{"name": "flagship"}, {"name": "anthropic"}, {"name": "coding"}, {"name": "long-context"}],
        "suggestion_prompts": [
            {"content": "🏗️ Analysiere diese komplexe Codebase und erstelle einen Refactoring-Plan"},
            {"content": "📊 Review diesen Architektur-Entwurf auf Skalierungsprobleme"},
            {"content": "🧩 Debugge dieses schwierige Concurrency-Problem Schritt fuer Schritt"},
        ],
    },
    "openrouter.anthropic/claude-opus-4.5": {
        "name": "✧ Claude Opus 4.5",
        "description": "Opus 4.7 Vorgaenger, etwa 3x guenstiger bei ~95% Qualitaet. Gute Wahl fuer Volume-Tasks die Opus-Qualitaet brauchen aber nicht das allerneueste.\n\nVergleich: ≈ 95% Opus 4.7, ≈ 115% GPT-5 bei Code.",
        "capabilities": {"vision": True, "usage": True, "citations": True},
        "tags": [{"name": "flagship"}, {"name": "anthropic"}, {"name": "cost-effective"}],
        "suggestion_prompts": [
            {"content": "📝 Erstelle ausfuehrliche technische Dokumentation zu diesem Thema"},
            {"content": "🔍 Analysiere diesen Text auf Inkonsistenzen und logische Fehler"},
        ],
    },
    "openrouter.anthropic/claude-sonnet-4.6": {
        "name": "◆ Claude Sonnet 4.6",
        "description": "DER Daily Driver — 90% der Tasks. Beste Balance aus Qualitaet, Geschwindigkeit und Preis. Etwa 8x guenstiger als Opus 4.7.\n\nVergleich: ≈ 85% Opus 4.7, ≈ GPT-5 Mini Niveau bei Code.",
        "capabilities": {"vision": True, "usage": True, "citations": True},
        "tags": [{"name": "balanced"}, {"name": "anthropic"}, {"name": "daily-driver"}],
        "suggestion_prompts": [
            {"content": "✍️ Schreibe einen professionellen E-Mail-Text"},
            {"content": "💡 Brainstorme Ideen fuer dieses Projekt"},
            {"content": "📋 Fasse dieses Meeting-Protokoll in Stichpunkten zusammen"},
        ],
    },
    "gpt-5": {
        "name": "🚀 GPT-5",
        "description": "OpenAI Flagship (April 2026). Sehr guter Allrounder, kreativ, breites Wissen. Etwas schwaecher als Opus 4.7 bei reinem Coding, dafuer staerker bei kreativen Texten.\n\nVergleich: ≈ 92% Opus 4.7, = Opus 4.6 Level.",
        "capabilities": {"vision": True, "usage": True, "citations": False},
        "tags": [{"name": "flagship"}, {"name": "openai"}, {"name": "creative"}],
        "suggestion_prompts": [
            {"content": "🎨 Entwirf eine kreative Marketingkampagne fuer dieses Produkt"},
            {"content": "📖 Schreibe eine Kurzgeschichte im Stil von..."},
            {"content": "🧠 Erklaere dieses komplexe Thema fuer verschiedene Zielgruppen"},
        ],
    },
    "gpt-5-mini": {
        "name": "⚡ GPT-5 Mini",
        "description": "Schnell + guenstig, gut fuer hohe Volumen. Etwa 5x schneller als GPT-5 bei ~80% Qualitaet.\n\nVergleich: ≈ 80% Opus 4.7, ≈ Sonnet 4.6 Niveau.",
        "capabilities": {"vision": True, "usage": True, "citations": False},
        "tags": [{"name": "fast"}, {"name": "openai"}, {"name": "cost-effective"}],
        "suggestion_prompts": [
            {"content": "🔄 Uebersetze diesen Text ins Englische"},
            {"content": "📊 Klassifiziere diese Daten nach Kategorien"},
        ],
    },
    "gpt-5-nano": {
        "name": "💨 GPT-5 Nano",
        "description": "Ultra-guenstig fuer Massenverarbeitung, Klassifikation, einfache Extraktion. Ca 20x guenstiger als GPT-5.\n\nVergleich: ≈ 55% Opus 4.7, ≈ Claude Haiku Niveau.",
        "capabilities": {"vision": False, "usage": True, "citations": False},
        "tags": [{"name": "ultra-fast"}, {"name": "openai"}, {"name": "volume"}],
        "suggestion_prompts": [
            {"content": "🏷️ Extrahiere Stichwoerter aus diesem Text"},
            {"content": "✂️ Kuerze diesen Text auf 3 Stichpunkte"},
        ],
    },
    "o1": {
        "name": "🧠 o1 Reasoning",
        "description": "Tiefes Reasoning-Modell fuer Mathematik, Logik-Puzzles, komplexe Analysen. Laengere Antwortzeit, dafuer Chain-of-Thought qualitativ auf Top-Niveau.\n\nVergleich: ≈ 95% Opus 4.7 bei Mathe/Logik, schwaecher bei allgemeiner Konversation.",
        "capabilities": {"vision": False, "usage": True, "citations": False},
        "tags": [{"name": "reasoning"}, {"name": "openai"}, {"name": "math"}],
        "suggestion_prompts": [
            {"content": "🔢 Loese dieses Mathematikproblem Schritt fuer Schritt"},
            {"content": "🎯 Analysiere dieses Logikraetsel und erklaere die Loesung"},
        ],
    },
    "openrouter.google/gemini-2.5-pro-preview": {
        "name": "🔮 Gemini 2.5 Pro",
        "description": "1M Token Kontext (!) — ideal fuer ganze Codebases, lange PDFs, Video-Analyse. Multimodal stark. Etwas hinter Opus 4.7 bei Code-Reasoning.\n\nVergleich: ≈ 88% Opus 4.7, aber ALLEINSTELLUNGSMERKMAL: 1M Kontext.",
        "capabilities": {"vision": True, "usage": True, "citations": True},
        "tags": [{"name": "long-context"}, {"name": "google"}, {"name": "multimodal"}],
        "suggestion_prompts": [
            {"content": "📚 Analysiere diese gesamte Codebase und erstelle eine Architektur-Uebersicht"},
            {"content": "🎥 Beschreibe was in diesem Video passiert"},
            {"content": "📄 Fasse dieses 200-Seiten Dokument zusammen"},
        ],
    },
    "openrouter.deepseek/deepseek-v3.2": {
        "name": "🌊 DeepSeek V3.2",
        "description": "Sehr stark bei Code und Mathematik, extrem guenstig. DSGVO-bedenklich (China-Hosting) — nicht fuer sensible EU-Daten.\n\nVergleich: ≈ 78% Opus 4.7, bei reinem Code nahe Sonnet 4.6 Niveau. Preis: ~20x guenstiger als Opus.",
        "capabilities": {"vision": False, "usage": True, "citations": False},
        "tags": [{"name": "code"}, {"name": "math"}, {"name": "cost-effective"}, {"name": "china-host"}],
        "suggestion_prompts": [
            {"content": "💻 Schreibe diese Funktion in Python"},
            {"content": "🐛 Finde den Bug in diesem Code"},
        ],
    },
    "openrouter.deepseek/deepseek-r1-distill-llama-70b": {
        "name": "🧮 DeepSeek R1 70B",
        "description": "Reasoning-Modell mit sichtbarer Chain-of-Thought. Sehr gut bei Mathe und Logik, o1-aehnlich aber deutlich guenstiger.\n\nVergleich: ≈ 82% Opus 4.7 bei Reasoning, ≈ 85% o1 bei Mathe.",
        "capabilities": {"vision": False, "usage": True, "citations": False},
        "tags": [{"name": "reasoning"}, {"name": "deepseek"}, {"name": "cost-effective"}],
        "suggestion_prompts": [
            {"content": "🎯 Loese dieses Problem mit sichtbarer Gedankenkette"},
            {"content": "⚖️ Bewerte verschiedene Loesungsansaetze fuer..."},
        ],
    },
    "openrouter.mistralai/mistral-large-2512": {
        "name": "🌪️ Mistral Large 3",
        "description": "DSGVO-konform (EU-Hosting, Frankreich). Die Wahl fuer sensible Geschaefts-/Pflegedaten die in der EU bleiben muessen.\n\nVergleich: ≈ 75% Opus 4.7, aber UNIQUE: rechtssicheres EU-Hosting.",
        "capabilities": {"vision": False, "usage": True, "citations": False},
        "tags": [{"name": "dsgvo"}, {"name": "eu-host"}, {"name": "business"}],
        "suggestion_prompts": [
            {"content": "📋 Erstelle eine DSGVO-konforme Datenschutzerklaerung"},
            {"content": "✍️ Formuliere professionelle Geschaeftskorrespondenz"},
        ],
    },
    "openrouter.perplexity/sonar-pro-search": {
        "name": "🔍 Perplexity Sonar Pro",
        "description": "Web-Recherche mit automatischen Quellenangaben — etwas das Claude nativ NICHT kann. Perfekt fuer aktuelle Themen, Faktenrecherche, News.\n\nVergleich: Einzigartig (kein anderes Modell hat Web-Zugriff + Quellen standardmaessig).",
        "capabilities": {"vision": False, "usage": True, "citations": True},
        "tags": [{"name": "web"}, {"name": "research"}, {"name": "citations"}],
        "suggestion_prompts": [
            {"content": "🌐 Was sind die neuesten Entwicklungen zu..."},
            {"content": "📰 Fasse die Berichterstattung zu diesem Thema zusammen"},
            {"content": "📊 Recherchiere aktuelle Statistiken zu..."},
        ],
    },
    # ======== LOKAL (Ollama auf NAS) ========
    "qwen3:8b": {
        "name": "🚀 Qwen3 8B • Lokal",
        "description": "Lokaler Allrounder. Laeuft offline auf der NAS. Gut fuer taegliche Aufgaben wenn Cloud nicht gewollt/moeglich. ~6 GB RAM, ~5 t/s auf CPU.\n\nVergleich: ≈ 40% Opus 4.7, ≈ Haiku 4.5 Niveau. UNIQUE: komplett offline, DSGVO-safe.",
        "capabilities": {"vision": False, "usage": False, "citations": False},
        "tags": [{"name": "local"}, {"name": "offline"}, {"name": "dsgvo-safe"}],
        "suggestion_prompts": [
            {"content": "🔒 Analysiere diesen Text offline (kein Cloud-Call)"},
            {"content": "💭 Beantworte diese allgemeine Frage lokal"},
        ],
    },
    "qwen2.5-coder:14b": {
        "name": "⚙️ Qwen Coder 14B • Lokal",
        "description": "Lokaler Code-Spezialist. Gut fuer Fill-in-the-Middle, Code-Reviews, kleine Funktionen. ~9 GB RAM, ~3 t/s auf CPU.\n\nVergleich: ≈ 55% Opus 4.7 bei Code, ≈ Codestral Cloud Niveau offline.",
        "capabilities": {"vision": False, "usage": False, "citations": False},
        "tags": [{"name": "local"}, {"name": "code"}, {"name": "offline"}],
        "suggestion_prompts": [
            {"content": "💻 Schreibe diese Funktion offline"},
            {"content": "🔧 Refactore diesen Code-Block"},
        ],
    },
    "gemma3:12b": {
        "name": "💨 Gemma 3 12B • Lokal",
        "description": "Lokales Universal-Modell von Google. Gute Allgemeinbildung, solide Schreibqualitaet. ~8 GB RAM, ~3 t/s auf CPU.\n\nVergleich: ≈ 50% Opus 4.7, ideale Backup-Loesung wenn Cloud-APIs down sind.",
        "capabilities": {"vision": False, "usage": False, "citations": False},
        "tags": [{"name": "local"}, {"name": "google"}, {"name": "offline"}],
        "suggestion_prompts": [
            {"content": "📝 Verfasse einen Text zu diesem Thema"},
            {"content": "💬 Beantworte diese allgemeine Frage"},
        ],
    },
    "llama3.2-vision:latest": {
        "name": "👁️ Llama Vision 11B • Lokal",
        "description": "Lokale Bildanalyse. Gut fuer OCR, Bildbeschreibung, Diagramme. ~8 GB RAM, ~2 t/s auf CPU.\n\nVergleich: ≈ Gemini Flash Vision Niveau offline. UNIQUE: Bildanalyse ohne Cloud-Upload.",
        "capabilities": {"vision": True, "usage": False, "citations": False},
        "tags": [{"name": "local"}, {"name": "vision"}, {"name": "offline"}],
        "suggestion_prompts": [
            {"content": "📸 Beschreibe was auf diesem Bild zu sehen ist"},
            {"content": "📝 Extrahiere Text aus diesem Bild (OCR)"},
        ],
    },
    "bge-m3:latest": {
        "name": "🔗 bge-m3 Embedding",
        "description": "Industry-Standard Embedding-Modell fuer RAG und semantische Suche. Nicht fuer Chat, sondern fuer Vektor-DB Integration. ~1.2 GB RAM.\n\nEinsatz: Supabase pgvector, Chroma, Qdrant, etc.",
        "capabilities": {"vision": False, "usage": False, "citations": False},
        "tags": [{"name": "embedding"}, {"name": "local"}, {"name": "rag"}],
        "suggestion_prompts": [],
    },
}

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("PRAGMA table_info(model)")
cols = [r[1] for r in cur.fetchall()]

# Zaehler
activated = 0
deactivated = 0
meta_updated = 0
not_found = []

now_ts = int(time.time())

# 1. Alle auf is_active=0 setzen
cur.execute("UPDATE model SET is_active = 0 WHERE is_active = 1")
print(f"Initial alle auf is_active=0: {cur.rowcount} betroffen", file=sys.stderr)

# 2. Fuer jede KEEP-ID: aktivieren + meta schreiben
for mid, config in KEEP.items():
    cur.execute("SELECT id, meta, name FROM model WHERE id = ?", (mid,))
    row = cur.fetchone()
    if not row:
        not_found.append(mid)
        print(f"  ✗ NICHT GEFUNDEN: {mid}", file=sys.stderr)
        continue

    # Meta bauen (komplett ueberschreiben)
    new_meta = {
        "description": config["description"],
        "capabilities": config["capabilities"],
        "tags": config["tags"],
        "suggestion_prompts": config["suggestion_prompts"],
    }
    new_meta_json = json.dumps(new_meta, ensure_ascii=False)

    cur.execute(
        "UPDATE model SET is_active = 1, name = ?, meta = ?, updated_at = ? WHERE id = ?",
        (config["name"], new_meta_json, now_ts, mid)
    )
    if cur.rowcount:
        activated += 1
        meta_updated += 1
        print(f"  ✓ {config['name']} ({mid})", file=sys.stderr)

# 3. Zaehlen was deaktiviert wurde
cur.execute("SELECT COUNT(*) FROM model WHERE is_active = 0")
deactivated = cur.fetchone()[0]

conn.commit()
conn.close()

print(f"\n=== ERGEBNIS ===", file=sys.stderr)
print(f"  Aktiviert:      {activated}", file=sys.stderr)
print(f"  Meta updated:   {meta_updated}", file=sys.stderr)
print(f"  Deaktiviert:    {deactivated}", file=sys.stderr)
print(f"  Nicht gefunden: {len(not_found)}", file=sys.stderr)
if not_found:
    print(f"\n  Fehlende IDs (evtl. erst Provider konfigurieren):", file=sys.stderr)
    for mid in not_found:
        print(f"    {mid}", file=sys.stderr)
