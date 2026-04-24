# KaGo — Karlsruhe transit, as a Flutter demo

**KaGo** is a small, **production-shaped** Flutter client for the Karlsruhe region (**KVV**): search stops, browse live-style departures, and plan connections. It is written as a **clean reference demo**—clear layering, predictable state, Material 3 UI, and a tiny **Cloudflare Worker** that turns the official **TRIAS** XML API into simple JSON so the app stays readable and easy to fork.

Use it as a template for: **BLoC + repositories**, **multi-platform** targets (iOS, Android, web), and **real HTTP** without running a Java or Node “monolith” on your laptop.

---

## Why this repo exists

- **Flutter first:** One codebase, familiar patterns, no framework experiments in the UI layer.
- **Thin backend:** The Worker only translates TRIAS → JSON and hides credentials. All product logic worth reading lives in Dart.
- **Honest scope:** Three screens, a handful of blocs, and widgets you can reuse—easy to navigate in an afternoon.

---

## Features

| Area | What you get |
|------|----------------|
| **Stops** | Debounced search, list → detail navigation |
| **Departures** | Chronological board, pull-to-refresh, periodic UI refresh for “in N min” |
| **Trips** | Origin/destination search and connection results |
| **Settings** | Light / dark theme (persisted) |
| **Offline story** | Optional **fake** repositories for UI work without any network |

---

## Architecture

The app follows a classic **feature slice** layout under `lib/`:

```
lib/
  config/           # API base URL, compile-time toggles
  shell/            # Bottom navigation + tab bodies
  locations/        # data/ · bloc/ · presentation/
  departures/       # data/ · bloc/ · presentation/
  trips/            # data/ · bloc/ · presentation/
  settings/         # data/ · bloc/ · presentation/
  theme/              # Material 3 light/dark, scroll behavior
  widgets/            # Shared UI (badges, empty states)
```

**Data flow**

1. **Repositories** (`Http*Repository` / `Fake*Repository`) perform HTTP or return stub data.
2. **BLoC / Cubit** expose events and immutable states; UI only reacts to state.
3. **Presentation** widgets stay mostly stateless; navigation receives `RepositoryProvider` from `main.dart` via `context.read<>()`.

**Dependency injection**

- `MultiRepositoryProvider` registers shared repositories once in `main.dart`.
- **Departures** uses a `BlocProvider` created on the stop route so each screen owns a short-lived bloc and does not leak subscriptions across pops.

---

## State management (BLoC)

| Piece | Role |
|-------|------|
| `LocationsBloc` | Search stops; `bloc_concurrency` **restartable** transformer so only the latest query matters. |
| `DeparturesBloc` | Load and sort departures by time; same restartable pattern for refresh. |
| `TripsBloc` | Trip search with loading / success / failure states. |
| `SettingsCubit` | Theme mode; reads/writes via `SettingsRepository` + `shared_preferences`. |

States and events use **sealed-style patterns** with `equatable` where it helps value equality. The goal is boring, test-friendly state—not clever indirection.

---

## API usage

The mobile/web app talks **only** to JSON endpoints. It never parses TRIAS XML.

**Default base URL** is set in `lib/config/api_config.dart` (`ApiConfig.defaultBaseUrl`). Point it at your deployed Worker or, for local development, at `http://127.0.0.1:8787` while the proxy runs (see below).

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/v1/locations?q=…&limit=…` | Stop search |
| `GET` | `/api/v1/departures?stopRef=…&limit=…` | Departures at a stop (`when` optional on the proxy) |
| `POST` | `/api/v1/trips` | Connection search (JSON body) |

**Trip body example**

```json
{
  "originRef": "de:08212:90",
  "destRef": "de:08212:1003",
  "departureTime": "2026-04-09T17:00:00Z"
}
```

`departureTime` is optional. Stop IDs come from the locations response.

The **Worker** implementation, env vars, and deploy notes live in [`api-proxy/README.md`](api-proxy/README.md).

---

## Design & UX

- **Material 3** with a single teal seed color, generated light/dark **ColorScheme**s, and consistent radii (`AppTheme`).
- **NavigationBar** in a floating-style shell with soft elevation and clear selected states.
- **Typography:** Slightly tightened titles, tabular figures for times where it matters.
- **Feedback:** Pull-to-refresh, haptics on key taps, empty and error states that invite retry instead of dead ends.
- **Scrolling:** `AppScrollBehavior` enables drag-to-dismiss keyboard on mobile-style scroll views.

---

## Run locally

### 1. API proxy (optional if using fake data)

```bash
cd api-proxy
npm install
export TRIAS_ENDPOINT=https://projekte.kvv-efa.de/lelargetrias/trias
export TRIAS_REQUESTOR_REF=your-ref
npm run dev
```

Default listen address: `http://127.0.0.1:8787`.

### 2. Flutter app

```bash
flutter pub get
flutter run
```

**UI-only mode** (no backend):

```bash
flutter run --dart-define=USE_FAKE_LOCATIONS=true
```

---

## Tests

The repo includes **lightweight tests** you can extend as the app grows:

| File | What it covers |
|------|----------------|
| `test/departure_test.dart` | `Departure.fromJson`, `Departure.parsePlannedTime` (ISO + space-separated dates) |
| `test/location_test.dart` | `Location.fromJson` |
| `test/trip_model_test.dart` | `Leg.isWalk`, `Journey.fromJson` |
| `test/widget_test.dart` | App boots, **Haltestellen** empty state; switching to **Verbindung** shows the trip search subtitle (`SharedPreferences` mocked; surface size set for layout) |

Run everything:

```bash
flutter test
```

Run a single file:

```bash
flutter test test/departure_test.dart
```

Tests do **not** call the real API on load (search is idle until you type). No `dart-define` is required for `flutter test`.

---

## Security

Do **not** commit `TRIAS_REQUESTOR_REF` or embed it in the app. The Worker holds the secret; the Flutter client only sees public JSON. Copy `.env.example` to `.env` for local proxy usage (see `api-proxy` docs).

---

## Reference deployment

- **Web:** [kago.lelar.ge](https://kago.lelar.ge)  
- **API:** [api.kago.lelar.ge](https://api.kago.lelar.ge)  

CI builds the web target with GitHub Actions (see `.github/workflows/`).

---

## License

MIT — see [LICENSE](LICENSE).
