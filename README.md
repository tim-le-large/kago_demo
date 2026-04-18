# KA Abfahrt

Flutter app + lightweight API proxy for live KVV transit data via the TRIAS API.

## API proxy (no Spring Boot)

Cloudflare Worker (TypeScript). Proxies the KVV TRIAS XML interface and exposes a JSON REST API.

### Setup

```bash
cd api-proxy
npm install
export TRIAS_ENDPOINT=https://projekte.kvv-efa.de/lelargetrias/trias
export TRIAS_REQUESTOR_REF=your-ref
npm run dev   # starts on http://127.0.0.1:8787
```

### API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/locations?q=Hbf&limit=10` | Search stops by name |
| `GET` | `/api/v1/departures?stopRef=de:08212:90&limit=15` | Departures at a stop |
| `POST` | `/api/v1/trips` | Trip search (JSON body) |

**Trip search body:**

```json
{
  "originRef": "de:08212:90",
  "destRef": "de:08212:1003",
  "departureTime": "2026-04-09T17:00:00Z"
}
```

`departureTime` is optional (defaults to now). Stop IDs come from the locations endpoint.

## Frontend

Flutter 3 / Dart / BLoC. Talks to the API proxy REST API.

### Setup

```bash
flutter pub get
flutter run
```

By default the app connects to `http://127.0.0.1:8787`. To change the API URL, edit `lib/config/api_config.dart` or set `--dart-define=API_BASE_URL=...`.

### GitHub Pages (kago.lelar.ge)

The web build is deployed via GitHub Actions to GitHub Pages.

- **Frontend**: `https://kago.lelar.ge`
- **API**: `https://api.kago.lelar.ge` (injected at build time via `--dart-define=API_BASE_URL=...`)

### Screens

- **Haltestellen** — search stops, tap to see departures
- **Abfahrten** — live departure board for a stop
- **Verbindung** — trip search

### Fake mode

Run without a backend using built-in test data:

```bash
flutter run --dart-define=USE_FAKE_LOCATIONS=true
```

## Security

- Never expose `TRIAS_REQUESTOR_REF` in the frontend or commit it to git.
- `.env` is gitignored. Use `.env.example` as a template.
