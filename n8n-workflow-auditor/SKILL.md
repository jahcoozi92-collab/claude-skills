# n8n Workflow Auditor Skill

| name | description |
|------|-------------|
| n8n-workflow-auditor | Entwicklung und Wartung der n8n Workflow Auditor Web-App - Sicherheits- und Konfigurationsanalyse für n8n Workflows |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:**
Stell dir vor, du hast einen Roboter, der deine n8n-Workflows anschaut und dir sagt:
- "Hey, das ist unsicher!"
- "Dieser Teil funktioniert nicht richtig"
- "So macht man das besser"

Das ist der n8n Workflow Auditor - eine Web-App, die Workflows prüft und erklärt.

---

## Projekt-Info

| Info | Wert |
|------|------|
| **Pfad** | `/volume1/docker/n8n-workflow-auditor` |
| **URL** | http://192.168.22.90:3456 |
| **Stack** | React 18 + TypeScript + Vite + Tailwind CSS |
| **Container** | nginx:alpine (statische Dateien) |

---

## Architektur

```
src/
├── main.tsx                    # Entry Point mit ErrorBoundary
├── App.tsx                     # Upload/Paste UI, History
├── components/
│   ├── ResultSection.tsx       # Analyse-Ergebnisse, Tabs
│   ├── WorkflowVisualizer.tsx  # Interaktive Workflow-Grafik
│   └── ErrorBoundary.tsx       # React Error Boundary
├── services/
│   └── analysisService.ts      # Kern-Analyse-Logik (~2500 Zeilen)
└── types/
    └── index.ts                # TypeScript Definitionen
```

---

## Features

### Implementiert (v1.3.0+)
- Security Audit (SQL Injection, CORS, Auth, Credentials)
- OWASP Top 10 2021 Mapping
- DSGVO-Relevanz-Markierung
- Komplexitäts-Score
- Performance-Schätzung
- Duplikat-Erkennung
- Community-Node-Erkennung
- Zirkuläre Referenzen
- Robustness Score
- Workflow-Historie (localStorage)
- **Laienfreundliche Beschreibung** (humanDescription)

### Laienfreundliche Beschreibung enthält:
- `whatItDoes` - Was macht der Workflow? (einfache Sprache)
- `howItWorks` - Schritt-für-Schritt mit Emojis
- `whenItRuns` - Wann wird er ausgeführt?
- `whatYouNeed` - Voraussetzungen (Credentials, etc.)
- `realWorldExample` - Praktisches Alltagsbeispiel

---

## Constraints

### IMMER
- Deutsche UI-Texte verwenden
- Laienfreundliche Erklärungen (keine Fachbegriffe ohne Erklärung)
- Emojis für visuelle Orientierung in Schritt-für-Schritt-Anleitungen
- TypeScript strict mode beachten (keine unused variables)
- Tests laufen lassen vor Container-Update

### NIEMALS
- Englische UI-Texte in der Hauptansicht
- Technische Begriffe ohne Kontext für Laien
- Container updaten ohne Build-Verifizierung
- `docker-compose` (v1) verwenden → `docker compose` (v2) nutzen

---

## Container-Update Workflow

```bash
cd /volume1/docker/n8n-workflow-auditor

# 1. Build testen
npm run build

# 2. Tests laufen lassen
node test-runner.mjs

# 3. Container neu bauen
docker compose build --no-cache

# 4. Container neu starten
docker stop n8n-workflow-auditor 2>/dev/null
docker rm n8n-workflow-auditor 2>/dev/null
docker compose up -d

# 5. Verifizieren
docker ps --filter "name=n8n-workflow-auditor"
```

**Wichtig:** `docker-compose` (mit Bindestrich) hat Kompatibilitätsprobleme auf diesem System. Immer `docker compose` (ohne Bindestrich) verwenden!

---

## Test-Workflows

Im Verzeichnis `test-workflows/` befinden sich 8 Test-Dateien:
- `01-minimal.json` - Minimaler Workflow
- `02-complex-ai.json` - KI-Workflow mit vielen Nodes
- `03-security-issues.json` - Bekannte Sicherheitsprobleme
- `04-empty-and-edge.json` - Edge Cases
- `05-circular-refs.json` - Zirkuläre Referenzen
- `06-community-nodes.json` - Community Nodes
- `07-bulk-export.json` - Array-Export-Format
- `08-unicode-special.json` - Unicode-Zeichen

---

## Diana's Präferenzen

- Bevorzugt deutsche Texte in der UI
- Möchte "laienfreundliche" Erklärungen für Nicht-Techniker
- Schätzt praktische Beispiele aus dem Alltag
- Nutzt Emojis zur visuellen Strukturierung

---

## Gelernte Lektionen

### 2026-01-13 - Laienfreundliche Beschreibung

**Anforderung:** Diana wollte eine Beschreibung, die erklärt "was dieser Workflow kann"

**Lösung:**
- Neuer Typ `humanDescription` im `WorkflowUseCase`
- Funktion `generateHumanDescription()` analysiert Workflow und erstellt:
  - Einfache Erklärung des Zwecks
  - Schritt-für-Schritt Ablauf mit Emojis
  - Praktisches Alltagsbeispiel
- UI-Sektion "Einfach erklärt" mit aufklappbaren technischen Details

**Docker-Hinweis:** `docker-compose` (v1.29.2) hat Kompatibilitätsprobleme mit neueren Docker-Versionen. Workaround: Container manuell stoppen/entfernen, dann `docker compose up -d`.
