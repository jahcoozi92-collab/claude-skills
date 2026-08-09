# OpenCut Skill – Self-Hosted Video-Editor

| name     | description                                                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| opencut  | Installation und Betrieb von OpenCut (Open-Source CapCut-Alternative) via Docker Compose auf Diana's NAS oder als Dev-Setup auf Yoga7. |

## Trigger

Aktiviere diesen Skill bei:
- "OpenCut installieren", "OpenCut Setup"
- "CapCut Alternative", "Video-Editor self-hosted"
- Fragen zu `opencut-classic` / `opencut-app/opencut`

---

## Was ist OpenCut?

OpenCut ist ein kostenloser, quelloffener Video-Editor (Next.js/React, MIT-Lizenz) – eine
selbst-hostbare Alternative zu CapCut. Videos werden clientseitig verarbeitet (Privacy-Fokus),
Timeline-Editing, Multi-Track, Export ohne Wasserzeichen/Abo.

**⚠️ Wichtig – zwei Repos, nicht verwechseln:**

| Repo | Status | Für Diana relevant? |
| --- | --- | --- |
| [`opencut-app/opencut-classic`](https://github.com/opencut-app/opencut-classic) | "Legacy", aber funktionsfähig – läuft produktiv hinter opencut.app | ✅ **Dieses Repo für Self-Hosting nutzen** |
| [`opencut-app/opencut`](https://github.com/opencut-app/opencut) | Kompletter Rewrite (Rust-Core, Cloudflare Workers, `proto`/`moon`/`bun`-Toolchain) | ❌ Kein Docker-Self-Hosting, nur für Contributor-Dev-Setup gedacht, aktuell keine externen Contributions |

Alle Anleitungen unten beziehen sich auf **`opencut-classic`**.

---

## Self-Hosting auf dem NAS (Docker Compose)

### 1. Port-Kollision vorab prüfen

```bash
ssh Jahcoozi@192.168.22.90
docker ps --format "{{.Ports}}" | tr ',' '\n' | grep -oE ':[0-9]+' | sort -u
```

OpenCut braucht extern **einen freien Web-Port** (Vorschlag: `3100`) sowie intern `5432`
(Postgres), `6379` (Redis) und `8079` (serverless-redis-http) – diese NICHT nach außen mappen,
falls sie mit anderen NAS-Diensten kollidieren (z. B. bereits laufendes Postgres).

### 2. Repo klonen

```bash
cd /volume1/docker
git clone https://github.com/opencut-app/opencut-classic.git opencut
cd opencut
```

### 3. Secrets statt Klartext (Docker-Admin-Konvention beachten!)

```bash
mkdir -p secrets && chmod 700 secrets
openssl rand -hex 32 > secrets/better_auth_secret.txt
chmod 600 secrets/*.txt
```

`.env` anlegen (NICHT ins Repo committen):

```bash
cp apps/web/.env.example .env
```

Relevante Variablen in `.env`:

| Variable | Zweck | Woher |
| --- | --- | --- |
| `DATABASE_URL` | Postgres-Connection | Default aus `docker-compose.yml` passt (`postgresql://opencut:opencut@db:5432/opencut`) |
| `BETTER_AUTH_SECRET` | Session/Auth-Signing | `openssl rand -hex 32` |
| `UPSTASH_REDIS_REST_URL` / `_TOKEN` | Redis-REST-Bridge (für Serverless-kompatible Libs) | Default passt (`http://serverless-redis-http:80`, Token `example_token`) |
| `NEXT_PUBLIC_SITE_URL` | Öffentliche URL | z. B. `https://opencut.forensikzentrum.com` |
| `FREESOUND_CLIENT_ID` / `FREESOUND_API_KEY` | Sound-Effekt-Suche im Editor | Kostenloser Account auf [freesound.org/apiv2/apply](https://freesound.org/apiv2/apply/) – optional, ohne Key läuft der Editor trotzdem |
| `MARBLE_WORKSPACE_KEY` | Blog/CMS-Anbindung (marblecms.com) | Optional, `build-placeholder` funktioniert |

### 4. Docker-Compose anpassen (Ports + Restart-Policy)

Das mitgelieferte `docker-compose.yml` bringt bereits `restart: unless-stopped` und Healthchecks
mit – passt zu Diana's Standard. Nur externen Web-Port bei Bedarf ändern (Default `3100:3000`)
und `postgres`/`redis`-Ports NICHT nach außen exposen, falls Konflikte:

```yaml
services:
  db:
    ports: []          # nur intern, nicht 5432:5432 nach außen
  redis:
    ports: []          # nur intern, nicht 6379:6379 nach außen
```

### 5. Starten

```bash
docker compose up -d
```

App läuft auf `http://192.168.22.90:3100`.

### 6. Cloudflare Tunnel (analog zu anderen NAS-Diensten)

1. Route in `cloudflared`-Config bzw. via API hinzufügen (siehe `docker-admin` Skill –
   Tunnel-Routes brauchen einen **Custom Token** mit "Cloudflare Tunnel: Edit", DNS-CNAME einen
   **separaten Token** mit "Zone DNS: Edit").
2. Subdomain-Vorschlag: `opencut.forensikzentrum.com` → Ziel `192.168.22.90:3100`
3. `docker restart cloudflared` nach Config-Änderung.

---

## Dev-Setup auf Yoga7 (nur zum Entwickeln/Testen, nicht produktiv)

```bash
git clone https://github.com/opencut-app/opencut-classic.git
cd opencut-classic
cp apps/web/.env.example apps/web/.env.local

# Nur DB + Redis in Docker, App läuft lokal mit bun
docker compose up -d db redis serverless-redis-http

bun install
bun dev:web
```

Editor läuft auf `http://localhost:3000`. `.env.example`-Defaults matchen die
Docker-Compose-Werte, funktioniert "out of the box".

---

## Constraints

### 🔴 NIEMALS
- `BETTER_AUTH_SECRET` als Default-Wert (`your-production-secret-key-here`) in Produktion stehen lassen
- Postgres/Redis-Ports ungeschützt nach außen exposen, wenn nicht zwingend nötig
- `opencut-app/opencut` (Rewrite) für Self-Hosting verwenden – hat aktuell keine Docker-Unterstützung

### 🟡 BEVORZUGT
- Secrets über `.env` + `chmod 600`, nicht in `docker-compose.yml`
- Update-Workflow wie bei anderen NAS-Containern: `git pull && docker compose up -d --build`
- Vor Erstinstallation Port-Kollisionen prüfen (siehe oben)

---

## Troubleshooting

| Problem | Ursache | Lösung |
| --- | --- | --- |
| `web`-Container startet nicht, Healthcheck failed | DB/Redis noch nicht bereit | `docker compose logs web` – Healthchecks in Compose sorgen normalerweise für korrekte Startreihenfolge (`depends_on: condition: service_healthy`) |
| Login/Auth schlägt fehl | `BETTER_AUTH_SECRET` leer oder nach Neustart geändert | Secret fix in `.env` setzen, nicht bei jedem Deploy neu generieren |
| Sound-Suche im Editor liefert nichts | `FREESOUND_CLIENT_ID`/`FREESOUND_API_KEY` fehlt | Optional – Key unter freesound.org/apiv2/apply beantragen |
| Port `3100` bereits belegt | Kollision mit anderem NAS-Container | Externen Port in `docker-compose.yml` unter `web.ports` ändern |

---

## Gelernte Lektionen

<!-- Dieser Abschnitt wird automatisch durch Reflect-Sessions aktualisiert -->
