# KaGo API proxy (Cloudflare Worker)

Minimal **TRIAS → JSON** bridge for the [KaGo](../README.md) Flutter app. Keeps `TRIAS_REQUESTOR_REF` on the server and exposes the REST shape the client expects.

## Endpoints

- `GET /api/v1/locations?q=…&limit=…`
- `GET /api/v1/departures?stopRef=…&when=…&limit=…`
- `POST /api/v1/trips`

Full context, architecture, and Flutter integration: **[root README](../README.md)**.

## Local development

```bash
cd api-proxy
npm install
export TRIAS_ENDPOINT="https://projekte.kvv-efa.de/lelargetrias/trias"
export TRIAS_REQUESTOR_REF="your-ref"
npm run dev
```

Worker URL defaults to `http://127.0.0.1:8787`.

## Deploy (Cloudflare)

```bash
cd api-proxy
npm install
npx wrangler secret put TRIAS_REQUESTOR_REF
npx wrangler deploy
```

Custom domains (e.g. `api.kago.lelar.ge`) can be attached in the Workers dashboard or via `routes` in `wrangler.toml`.
