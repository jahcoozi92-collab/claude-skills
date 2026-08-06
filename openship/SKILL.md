# OpenShip Skill – Deployment-Plattform auf der NAS

| name     | description                                                                                                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| openship | Betrieb der OpenShip-Deployment-Plattform auf Dianas NAS. Apps deployen, Katalog-Dienste installieren, Projekte aufraeumen, Tunnel-Routen setzen. Enthaelt die Fallen, die NICHT in der offiziellen Doku stehen. |

## Was ist dieser Skill?

**Für 12-Jährige erklärt:** Wenn du ein Programm geschrieben hast, muss es auf einem Computer
laufen, der immer an ist — sonst kann es niemand benutzen. Bisher hiess das: Ordner anlegen,
Konfigurationsdatei schreiben, Ports aussuchen, Container starten, hoffen dass nichts kollidiert.

OpenShip ist der Knopf, der das übernimmt. Du sagst „nimm dieses Programm und mach es
lauffähig" — es baut, startet und überwacht. Wie ein Hausmeister für deine Programme.

Es ist ein selbstgehostetes Vercel/Heroku, nur dass alles auf der NAS bleibt.

> **Warum dieser Skill existiert:** Die offizielle Doku und der bekannte
> `Rishflips/OpenShip-Hermes-Agent`-Skill beschreiben den **Idealzustand** — CLI, automatisches
> Let's Encrypt, Ports 3001/4000. Auf dieser NAS stimmt davon fast nichts. Hier steht, was
> **wirklich** gilt.

---

## Diana's Installation

| Was | Wert |
|---|---|
| Pfad | `/volume1/docker/top10/src/openship` |
| Version | 0.5.0 (from source gebaut, nicht gepullt) |
| Dashboard | **20151** → http://192.168.22.90:20151 |
| API | **20152** (Health: `/api/health`) |
| Landingpage | 20150 (Marketing-Seite von openship.io, ohne Nutzen) |
| Extern | https://openship.forensikzentrum.com → 20151, **ohne Access-Schutz** |
| Anmeldung | `diana.goebel@proton.me` (nicht die Google-Adresse!) |
| Container | `openship-{api,dashboard,web,postgres,redis}-1` |
| Betriebsdoku | `openship/README-NAS.md` |

**Zwei Compose-Dateien, nur eine ist aktiv:**

| Datei | Rolle | Status |
|---|---|---|
| `docker-compose.yml` (Root) | from-source Control Plane | ✅ **aktiv** |
| `docker/docker-compose.yml` | Self-Hosting mit Edge auf 80/443 | ❌ unbrauchbar |
| `docker-compose.override.yml` | NAS-Anpassungen (Socket, CLI, Limits) | ✅ aktiv |

Der Self-Hosting-Stack scheidet aus, weil sein Edge die Ports **80/443** braucht — die hält der
UGOS-System-nginx. Die Ports sind auch nicht umkonfigurierbar (`listen 80` steht fest in
`packages/adapters/src/infra/nginx.ts:944`).

---

## 🔴 NIEMALS (jede Regel = ein realer Fehlschlag)

1. **NIEMALS `docker compose up -d` zum blossen Starten.**
   Das zieht bei `:latest` ein neues Image und macht ein Recreate — ein ungeplantes Update.
   Zum Wiederanlaufen: `docker compose start <service>`.

2. **NIEMALS annehmen, der Docker-Socket genüge.**
   OpenShip ruft fuer Compose-Deployments die docker-**CLI** als Prozess auf. Fehlt sie:
   `/bin/sh: 1: docker: not found` nach 2 Millisekunden. Die Override mountet
   `/usr/bin/docker` + Compose-Plugin read-only. Nach einem Docker-Update Pfade pruefen.

3. **NIEMALS `auth_mode` auf `none` lassen.**
   Dann leitet das Dashboard per JavaScript auf `http://localhost:4000/api/auth/desktop-login`
   → beim Anwender `ERR_CONNECTION_REFUSED`. Fix: `OPENSHIP_AUTH_MODE=local` in der Override
   (autoritativ, aendert den DB-Wert nicht). **Vorher pruefen, ob das Konto ein Passwort hat**,
   sonst sperrt man sich aus:
   ```bash
   docker exec openship-postgres-1 psql -U openship -d openship \
     -c "select provider_id, (password is null) from account;"
   ```

4. **NIEMALS Tunnel-Routen fuer OpenShip-Apps auf `192.168.22.90` legen.**
   Deployte Apps binden **nur an 127.0.0.1** (z.B. `127.0.0.1:20000->80/tcp`). Die Route muss
   `http://127.0.0.1:<port>` lauten — traegt, weil `cloudflared` im Netzwerkmodus `host` laeuft.

5. **NIEMALS `cloudflared/api-upload-routes-v2.sh` laufen lassen.**
   Es pusht die komplette Ingress-Liste aus `config.yml` und setzt die im Dashboard
   korrigierten Routen zurueck. Routen **additiv** aendern (siehe Rezept unten).

6. **NIEMALS erwarten, dass ein Projekt mit Custom-Domain sich normal loeschen laesst.**
   Das Teardown will die Route entfernen, findet kein OpenResty → `PROJECT_TEARDOWN_FAILED`.
   Loesung: `?forceOrphan=true`, danach das Netzwerk von Hand entfernen.

7. **NIEMALS Benachrichtigungen an LAN-Ziele ohne `NOTIFY_WEBHOOK_ALLOW_INTERNAL=true`.**
   Der Kanal laesst sich anlegen, aber jede Zustellung scheitert mit
   „Only https URLs are allowed" (`notification-workers.ts:217`).

---

## Rezepte

### App aus einem Git-Repo deployen

```bash
# Ueber MCP (bevorzugt, ich mache das direkt):
#   mcp__openship__post_projects   { name, gitOwner, gitRepo, gitBranch, framework }
#   mcp__openship__post_deployments { projectId, environment: "production" }
```
Erkannt werden u.a. Next.js, Nuxt, SvelteKit, Astro, Express, FastAPI, Django, Go, Rust,
Laravel, Rails, .NET — sowie eigenes `Dockerfile` / `docker-compose.yml`.

### Katalog-App installieren (Supabase, Qdrant, MinIO, Grafana, n8n, Kafka, MongoDB, Convex, Excalidraw)

```
1. mcp__openship__post_apps { templateId: "qdrant", name: "..." }
2. Service holen:  mcp__openship__get_projects_by_id_services
3. ⚠ PFLICHT: Custom-Domain setzen, sonst scheitert der Preflight mit
   CLOUD_REQUIRED_MANAGED_COMPOSE_DOMAINS (exponierte Services wollen eine
   .opsh.io-Cloud-Domain):
   mcp__openship__patch_projects_by_id_services_by_serviceId
     { domainType: "custom", customDomain: "<app>.forensikzentrum.com" }
   Ein DNS-Eintrag muss NICHT existieren — fehlender Record ist nur `warn`
   (preflight.ts:1134).
4. mcp__openship__post_deployments { projectId }
5. Host-Port ablesen: docker ps | grep <slug>
```

Der Deploy meldet danach eine Warnung (`openresty: not found`) — das ist der fehlende Edge
und **erwartet**. Die App laeuft trotzdem.

**Nicht verfuegbar** (im Katalog als „comingSoon"): Ghost, Directus, NocoDB, Metabase, Gitea,
code-server, Uptime Kuma, Vaultwarden, FreshRSS, Stirling PDF, IT-Tools, Buzz.

### Tunnel-Route fuer eine App anlegen (additiv!)

```bash
set -a; . /volume1/docker/cloudflared/.env; set +a
TOKEN="${CLOUDFLARE_API_TOKEN:-$CF_API_TOKEN}"
API=https://api.cloudflare.com/client/v4
ACC=fe9ccc0b8c75b763124554a9f0bab48c
TUN=d770b289-dc1b-498e-9387-dff9edbea572
ZONE=772684b736f745da1fc16def3a83b547
cf(){ curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

# 1) DNS-CNAME (proxied) auf den Tunnel
cf -X POST "$API/zones/$ZONE/dns_records" -d "$(jq -n --arg h "app.forensikzentrum.com" \
  --arg t "$TUN.cfargotunnel.com" '{type:"CNAME",name:$h,content:$t,proxied:true}')"

# 2) Ingress ADDITIV: Live-Config holen, vor die catch-all splicen, PUT
CUR=$(cf "$API/accounts/$ACC/cfd_tunnel/$TUN/configurations" | jq '.result.config')
NEW=$(echo "$CUR" | jq --arg h "app.forensikzentrum.com" --arg s "http://127.0.0.1:20000" \
  '.ingress = ((.ingress[:-1]) + [{hostname:$h, service:$s}] + [.ingress[-1]])')
cf -X PUT "$API/accounts/$ACC/cfd_tunnel/$TUN/configurations" \
  -d "$(jq -n --argjson c "$NEW" '{config:$c}')"
```
Danach Stichprobe auf bestehende Hostnamen, dass nichts kaputtging.
Der Token darf Tunnel, DNS **und** Access schreiben (Access-Recht wurde 2026-08-06 ergaenzt).

### Projekt restlos entfernen

```bash
TOKEN=$(jq -r '.projects."/volume1/docker".mcpServers.openship.headers.Authorization' \
  /home/Jahcoozi/.claude.json | sed 's/^Bearer //')
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" \
  "http://192.168.22.90:20152/api/projects/<projectId>?forceOrphan=true" | jq -c '{ok,orphaned}'
docker network rm openship-<slug>        # bleibt sonst liegen!
docker rmi <image>                       # falls nur fuer den Test gezogen
```
Die Antwort listet unter `orphaned` alles, was liegen geblieben ist — **durchgehen und
selbst aufraeumen**.

---

## Betrieb

```bash
cd /volume1/docker/top10/src/openship

docker compose ps                  # Status (Override wird automatisch geladen)
docker compose logs -f api
docker compose start api           # STARTEN (nicht up -d!)
docker compose restart api

git pull && docker compose up -d --build    # Update: baut aus Quellcode, dauert
docker exec openship-postgres-1 pg_dump -U openship -d openship > backup.sql
```

**Speicherlimits** stehen in der Override (api 2 GB, postgres 1 GB, dashboard 512 MB,
redis 512 MB, web 256 MB) — `docker update` wirkt nur zur Laufzeit und geht bei jedem
Recreate verloren.

**Sicherung:** `daily-backup.sh` macht seit 2026-08-06 einen `pg_dump` von
`openship-postgres-1`. Noetig, weil die DB im Named Volume `openship_postgres_data` liegt und
der rsync auf `/volume1/docker/` sie nicht erfasst.

**Benachrichtigungen:** Kanal `nch_5_LMRduq4VKoSOcH` (webhook) → n8n-Workflow
`FDJsUQnHjuCfpQKr` („OpenShip Alerts") → Telegram. Abonniert: `deploy.failed`,
`backup.failed`, `job.run.failed`, `backup.restore_completed`.

---

## Was hier NICHT geht

| Feature | Warum |
|---|---|
| Automatische Domains + Let's Encrypt | Kein Edge (Ports 80/443 belegt, im Code hartcodiert) |
| Zero-Downtime-Deploys | `routeStrategy=loopback-port` → fester Host-Port kann nicht doppelt gebunden werden |
| Openship Cloud, GitHub-App | Braucht ein Cloud-Konto (`requiresCloud: true`) |
| `openship`-CLI | Nicht installiert; alles laeuft ueber MCP oder die REST-API |
| Push-to-Deploy | Erst nach einer Access-Bypass-Regel fuer `/api/proxy/api/webhooks/*` |

**Webhook-URLs** laufen ueber den Dashboard-Proxy:
`https://openship.forensikzentrum.com/api/proxy/api/webhooks/github` — deshalb genuegt **eine**
Tunnel-Route auf 20151, die API braucht keine eigene.

---

## ⚠ Sicherheitslage

Der api-Container laeuft als root und hat ueber den Docker-Socket **Vollzugriff auf alle ~50
Container dieser NAS**. Wer sich am Dashboard anmeldet, kontrolliert faktisch die ganze NAS.

Cloudflare Access wurde am 2026-08-06 auf ausdruecklichen Wunsch **entfernt** (Code-Eingabe war
zu umstaendlich). Damit steht zwischen dem offenen Internet und dem Socket **nur noch das
OpenShip-Passwort**. Der MCP-Token (`opsh_pat_…` in `~/.claude.json`) ist wie ein Root-Zugang zu
behandeln.

Wieder absichern: Access-App fuer den Hostnamen anlegen (Typ `self_hosted`) + Allow-Policy auf
`jahcoozi92@gmail.com`. Vorlage: App `nas-dashboard`. Der Token hat die Rechte inzwischen.

---

## Diagnose

**„Im Browser kaputt, per curl heil"** → nicht weiter greppen. Die Ziel-URL wird im Browser zur
Laufzeit zusammengesetzt und steht in **keiner** Bundle-Datei. Seite im echten Browser oeffnen
(`mcp__claude-in-chrome`) und die tatsaechliche Adresse auslesen. So wurde der
`localhost:4000`-Sprung gefunden, nachdem HTML, 741 Bundle-Dateien und alle API-Antworten
sauber aussahen.

**Pruefmuster eindeutig waehlen:** `grep -i openship` trifft auch auf der Cloudflare-Access-
Anmeldeseite (der App-Name steht dort). Auf `_next/static` oder `__NEXT_DATA__` pruefen.

**Docker-Zugriff der API testen:**
```bash
docker exec openship-api-1 sh -c 'docker version --format "{{.Server.Version}}"; docker compose version --short'
```

---

## Projekt-Reife (Stand 2026-08-06)

`oblien/openship`: 10.371 ★, **erst seit Maerz 2026**, 44 Contributors — aber ein Entwickler hat
382 Commits, der zweite 43. Apache-2.0, sehr aktiv.

Zum Vergleich: Coolify 60k (seit 2021), Dokploy 36k (2024), Dokku 32k (2013).

**Konsequenz:** Gut fuer Neues, Experimente und Wegwerfbares. Nichts Geschaeftskritisches allein
darauf stellen. Bestehende Stacks (Nextcloud, Vaultwarden, Home Assistant, n8n) NICHT umziehen —
sie laufen stabil, ein Umzug bringt nur Risiko.

> ⚠ **Namensverwechslung:** `openshiporg/openship` (1.586 ★) ist ein voellig anderes Projekt
> (Shopify-Fulfillment). Immer `oblien/openship` meinen.
