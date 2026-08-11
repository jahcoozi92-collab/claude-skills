# QM-Handbuch Chat (Frontend)

Eigenständige HTML-Chatseite für den QM-Handbuch Assistenten, im gleichen Stil
wie `medifox-chat.html`. Ruft **nicht** einen neuen Backend-Endpunkt auf,
sondern denselben produktiven n8n-Workflow, der bereits MediFox- und
QM-Handbuch-Inhalte gemeinsam bedient:

- Workflow: `RAG_Masterclass_Chat_hybrid`
- Workflow-ID: `SJ47UX9mv8wh1Wwy`
- Aufgerufener Endpoint: `POST /webhook/rag-chat-api` (JSON, nicht die HTML-Variante `/webhook/medifox-chat`)
- Payload: `{"sessionId": "...", "chatInput": "..."}`

## Bekannte Unsicherheit

Das JSON-Antwortformat des Webhooks war zum Zeitpunkt der Erstellung nicht
exakt dokumentiert. `index.html` versucht beim Parsen mehrere gängige Keys
(`output`, `response`, `text`, `answer`, `message`). Nach dem ersten echten
Testaufruf prüfen, welcher Key tatsächlich zurückkommt, und `extractAnswer()`
in `index.html` ggf. anpassen.

## Deployment

Analog zu `medifox-chat.html` (liegt auf dem NAS unter
`/volume1/docker/n8n/medifox-chat.html`, wird aber von keinem NAS-Container
automatisch ausgeliefert) muss auch diese Datei bewusst irgendwo gehostet
werden, z. B.:

- Als statische Datei auf dem NAS + Reverse-Proxy-Route, oder
- Als Cloudflare-Pages-Deploy, oder
- Inline als HTML-Response in einem eigenen n8n-Webhook-Node (dann auf CORS
  `*` in der Response achten, siehe `rag-system/SKILL.md`, Abschnitt
  „NIEMALS CORS auf spezifische Domain setzen").

## Live-Zugriff auf den n8n-Workflow

Diese Cloud-Session hat keinen Netzwerkzugriff auf `n8n.forensikzentrum.com`
(Proxy blockiert den Connect, kein `N8N_API_KEY` im Environment) und auch
nicht auf die interne NAS-Adresse `192.168.22.90:5678`. Die Workflow-Struktur
oben stammt aus den Notizen in `rag-system/SKILL.md`, nicht aus einem frischen
API-Abruf. Für eine Live-Ansicht: von einer Session mit NAS-Netzwerkzugriff
(z. B. Yoga7) oder mit gesetztem `N8N_API_KEY` gegen
`https://n8n.forensikzentrum.com/api/v1/workflows/SJ47UX9mv8wh1Wwy` abfragen.
