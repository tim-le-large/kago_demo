## ka_abfahrt API Proxy (Cloudflare Worker)

This replaces the former Spring Boot backend. It keeps `TRIAS_REQUESTOR_REF` server-side and exposes the same JSON REST API used by the Flutter app:

- `GET /api/v1/locations?q=...&limit=...`
- `GET /api/v1/departures?stopRef=...&when=...&limit=...`
- `POST /api/v1/trips`

### Local dev

```bash
cd api-proxy
npm install
export TRIAS_ENDPOINT="https://projekte.kvv-efa.de/lelargetrias/trias"
export TRIAS_REQUESTOR_REF="your-ref"
npm run dev
```

The worker will be available at `http://127.0.0.1:8787`.

### Deploy (Cloudflare)

```bash
cd api-proxy
npm install
npx wrangler secret put TRIAS_REQUESTOR_REF
npx wrangler deploy
```

