# Quick Start

This is a condensed local run guide. For full setup from scratch (first-time install,
OSRM map data, environment variables), see the [main README](README.md#getting-started).

## 1. Backend

Requires Docker Desktop running.

```bash
cd cmers_backend
docker-compose up -d
```

Wait ~10s for containers to become healthy, then verify:

```bash
curl http://localhost:8000/health/
```

Should return `{"status": "ok", ...}`.

If this is a fresh database, seed it with demo data:

```bash
docker-compose exec backend python backend/manage.py migrate
docker-compose exec backend python backend/manage.py train_models
docker-compose exec backend python backend/manage.py seed_demo_data
```

## 2. Dashboard

```bash
cd cmers_dashboard
npm install
npm run dev
```

Open http://localhost:3000

## 3. Mobile app (optional)

Only needed if you're testing the citizen-facing app. Requires the [Flutter SDK](https://flutter.dev).

```bash
cd cmers_mobile
flutter pub get
flutter run
```

By default it points at `http://127.0.0.1:8000/api/v1` (see `lib/core/config/app_config.dart`).

- **Android emulator**: change the host to `10.0.2.2` instead of `127.0.0.1`.
- **Physical device**: connect via USB, enable USB debugging, then forward the backend port:
  ```bash
  adb reverse tcp:8000 tcp:8000
  ```

See [`cmers_mobile/README.md`](cmers_mobile/README.md) for the full architecture and setup notes.

## Demo accounts

Seeded by `seed_demo_data` — see [README § Demo accounts](README.md#demo-accounts) for the full
list.

| Role | Email | Password |
|---|---|---|
| Admin | admin@cmers.com | Admin1234! |
| Operator | operator1@cmers.com | Operator1234! |
| Citizen (demo) | ahmed@citizen.com | Citizen1234! |

## Current demo data (seeded by default)

- **3 closed/historical incidents**: medical, flood, weather — each fully dispatched and completed.
- **2 active/in-progress**: fire, accident — unit confirmed and en route.
- **3 pending AI suggestions**: security, sos, hazmat — ready to confirm live in the Dispatch tab
  to demo the recommendation flow.
- All demo report locations are scattered near seeded field units for realistic ETA/recommendation
  behavior.

## Troubleshooting

Check container logs:

```bash
docker logs cmers_backend-backend-1 --tail 50
docker logs cmers_backend-celery_worker-1 --tail 50
```

OTP codes (dev mode, no real SMS) print to the backend log:

```bash
docker logs cmers_backend-backend-1 --tail 20 | grep OTP
```
