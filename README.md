# KA Abfahrt

Flutter app + Spring Boot backend for live KVV transit data via the TRIAS API.

## Backend

Java 17 / Spring Boot 4 / Gradle. Proxies the KVV TRIAS XML interface and exposes a JSON REST API.

### Setup

```bash
cd backend
cp .env.example .env   # then fill in TRIAS_REQUESTOR_REF
./gradlew bootRun       # starts on http://localhost:8080
```

The `.env` file is loaded automatically by the `bootRun` task.

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

### Tests

```bash
cd backend
./gradlew test
```

Tests use a mock HTTP server and fixture XML — no live KVV access needed.

### Render (Docker)

Render has no native Java runtime; deploy the API as a **Docker** Web Service.

1. **New → Web Service** → connect this repo.
2. **Root Directory:** `backend`
3. **Dockerfile Path:** `Dockerfile` (default when root is `backend`).
4. **Environment** (Render dashboard):  
   `TRIAS_ENDPOINT`, `TRIAS_REQUESTOR_REF` (secret), optionally `TRIAS_DUMP_REQUESTS=false`.  
   Render sets `PORT`; the image listens via `server.port=${PORT:8080}` in `application.properties`.

Local smoke test (requires Docker):

```bash
cd backend
docker build -t ka-abfahrt-api .
docker run --rm -p 8080:8080 \
  -e TRIAS_REQUESTOR_REF=your-ref \
  -e TRIAS_ENDPOINT=https://projekte.kvv-efa.de/lelargetrias/trias \
  ka-abfahrt-api
```

## Frontend

Flutter 3 / Dart / BLoC. Talks to the backend REST API.

### Setup

```bash
cd frontend
flutter pub get
flutter run
```

By default the app connects to `http://localhost:8080`. To change the backend URL, edit `lib/config/api_config.dart`.

### GitHub Pages (kago.lelar.ge)

The web build is deployed via GitHub Actions to GitHub Pages.

- **Frontend**: `https://kago.lelar.ge`
- **Backend API**: `https://api.kago.lelar.ge` (injected at build time via `--dart-define=API_BASE_URL=...`)

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
