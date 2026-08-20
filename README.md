# NEDAA — نظام إدارة الأزمات والاستجابة للطوارئ
### Crisis Management and Emergency Response System

NEDAA is a full-stack emergency response platform. Citizens report incidents (fire, medical,
accidents, SOS, witness statements) through a mobile-facing API; an AI pipeline automatically
clusters nearby reports into incidents, scores their credibility, predicts severity, and
suggests the nearest available field unit using real road-network ETAs. Officials work from a
bilingual (English/Arabic, full RTL) operator dashboard to review live incidents on a map,
confirm or override AI dispatch suggestions, track field units in real time, broadcast
emergency alerts, and audit every action taken in the system.

This repository is a monorepo containing both halves of the system:

| Folder | What it is | Stack |
|---|---|---|
| [`cmers_backend/`](cmers_backend) | REST API, AI pipeline, WebSocket server | Django, DRF, PostGIS, Channels, Celery, Redis, OSRM |
| [`cmers_dashboard/`](cmers_dashboard) | Operator web dashboard | React, Vite, Ant Design, Zustand, Leaflet |

---

## Contents

- [Key features](#key-features)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
  - [1. Clone](#1-clone)
  - [2. Backend setup](#2-backend-setup)
  - [3. Frontend setup](#3-frontend-setup)
- [Environment variables](#environment-variables)
- [Demo accounts](#demo-accounts)
- [Demo Mode (live defense/demo simulation)](#demo-mode-live-defensedemo-simulation)
- [Running tests](#running-tests)
- [API documentation](#api-documentation)
- [WebSocket channels](#websocket-channels)
- [Containers and ports](#containers-and-ports)
- [Known limitations](#known-limitations)
- [License](#license)

---

## Key features

**Citizen-facing**
- Phone/OTP registration and login, medical profile, emergency contacts
- Report submission (form, SOS, witness, voice) with photo/audio attachments
- Live status updates on submitted reports over WebSocket
- Push-style broadcast alerts (danger zones, road closures, weather, general)

**AI pipeline**
- DBSCAN clustering of nearby reports into incidents
- Random Forest credibility scoring (green/yellow/red confidence bands)
- XGBoost severity prediction (low/medium/high/critical, with probabilities)
- Greedy nearest-unit dispatch suggestion using real OSRM road-network ETAs

**Official/operator dashboard** (8 pages, all live over REST + WebSocket)
- **Dashboard** — live map, stat cards, critical-incident banner, system health, recent activity
- **Incidents** — filterable table + detail drawer (AI scores, report/witness breakdown, status history)
- **Dispatch Center** — pending AI suggestions, active assignments, completed-today, confirm/override
- **Field Units** — live status/location, manual status changes, assignment history
- **Analytics** — response times, severity distribution, AI accuracy vs. ground truth, incident heatmap
- **Notifications** — broadcast composer + history, quick templates
- **Audit Logs** — full/self-scoped action log depending on role, filterable, exportable
- **Settings** — organizations, official accounts, system info (role-gated)

**Platform-level**
- Role-based access control (admin/operator/viewer) enforced server-side, not just hidden in the UI
- Full audit logging of every sensitive action
- Rate limiting on auth and report-submission endpoints
- English/Arabic bilingual UI with full RTL layout support
- Production-ready polish: error boundaries, loading skeletons, code-split lazy routes, in-memory API caching
- **Demo Mode** — simulates live citizen activity automatically, for presentations (see below)

## Architecture

```
Citizen (mobile/web) ─┐
                       ├─▶ Django REST API ─▶ PostGIS ─▶ Celery ─▶ AI Pipeline (RF + XGBoost)
Official (dashboard) ──┘         │                                        │
                                  ├─▶ Channels/WebSocket (live updates)    │
                                  └─▶ OSRM (real road-network ETAs) ◀──────┘
```

- **Auth is fully separated**: citizens and officials use different JWT token spaces. A citizen
  token cannot touch official-only endpoints and vice versa.
- **Async AI processing**: report submission returns immediately; clustering/scoring/dispatch
  run in a Celery worker and push results to connected dashboards over WebSocket.
- **Real routing, not straight-line distance**: dispatch ETAs come from a self-hosted OSRM
  instance running an actual Syria road-network extract.

## Project structure

```
NEDAA-Crisis-Management-and-Emergency-Response-System/
├── cmers_backend/
│   ├── backend/
│   │   ├── ai_pipeline/       # DBSCAN clustering, RF credibility, XGBoost severity, greedy dispatch
│   │   ├── analytics/         # Response times, heatmap, AI accuracy, unit performance
│   │   ├── audit/             # Audit log model + role-scoped views
│   │   ├── config/            # Django settings, ASGI, Celery app
│   │   ├── core/              # Shared permissions, rate limiting, management commands
│   │   ├── dispatch/          # Resource assignments, confirm/override/complete
│   │   ├── incidents/         # Incident clusters, status history
│   │   ├── notifications/     # Push notifications, broadcast alerts
│   │   ├── reports/           # Citizen report submission (form/SOS/witness/voice)
│   │   ├── resources/         # Organizations, field units, official accounts, roles
│   │   ├── routing/           # OSRM integration
│   │   ├── users/             # Citizen auth, profile, medical info, emergency contacts
│   │   └── websocket/         # Channels consumers (incidents/units/citizen feeds)
│   ├── scripts/api_test_suite.py   # End-to-end Python test suite (150+ checks)
│   ├── osrm_data/              # NOT included in git (see Known limitations) — Syria OSRM extract
│   ├── docker-compose.yml
│   └── .env.example
└── cmers_dashboard/
    ├── src/
    │   ├── api/                # Thin axios wrappers per backend app
    │   ├── components/         # map/, incidents/, dispatch/, layout/, common/
    │   ├── hooks/               # useAuth, useWebSocket, useTranslation
    │   ├── pages/                # One file per dashboard page
    │   ├── store/                # Zustand stores (auth, incidents, units, connection)
    │   └── utils/                # constants, formatters, translations
    └── .env.example
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running, for the backend stack)
- [Node.js](https://nodejs.org/) 18+ and npm (for the dashboard)
- Git

## Getting started

> Already set up and just need to bring the stack back up? See [STARTUP.md](STARTUP.md) for the
> condensed quick-start.

### 1. Clone

```powershell
git clone https://github.com/phoinex69/NEDAA-Crisis-Management-and-Emergency-Response-System.git
cd NEDAA-Crisis-Management-and-Emergency-Response-System
```

### 2. Backend setup

Run from PowerShell, inside `cmers_backend/`:

```powershell
cd cmers_backend
copy .env.example .env
# then fill in .env — see Environment variables below

# Download the Syria OSM map extract (~78MB) and preprocess it for OSRM.
# This step is required once; see "Known limitations" for why it isn't in git.
mkdir osrm_data
Invoke-WebRequest `
  -Uri "https://download.geofabrik.de/asia/syria-latest.osm.pbf" `
  -OutFile "osrm_data/syria-latest.osm.pbf"

docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-extract -p /opt/car.lua /data/syria-latest.osm.pbf
docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-partition /data/syria-latest.osrm
docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-customize /data/syria-latest.osrm

# Build and start Postgres, Redis, OSRM, the API, and the Celery worker
docker-compose up --build -d

# Wait ~30s for all containers to be healthy, then:
docker-compose exec backend python backend/manage.py migrate
docker-compose exec backend python backend/manage.py train_models
docker-compose exec backend python backend/manage.py seed_demo_data
```

The API is now live at `http://localhost:8000/api/v1/`.

### 3. Frontend setup

Run from a separate terminal, inside `cmers_dashboard/`:

```powershell
cd cmers_dashboard
copy .env.example .env
npm install
npm run dev
```

The dashboard is now live at `http://localhost:5173/` (or the port Vite prints) and points at
the backend from step 2 by default.

## Environment variables

**`cmers_backend/.env`**

| Variable | Purpose |
|---|---|
| `DEBUG` | Django debug mode (`True`/`False`) |
| `SECRET_KEY` | Django secret key |
| `ALLOWED_HOSTS` | Comma-separated allowed hosts |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` | PostgreSQL/PostGIS connection (matches `docker-compose.yml`'s `db` service by default) |
| `REDIS_URL` | Redis connection (cache, Celery broker, Channels layer, rate limiting) |
| `OSRM_URL` | URL of the OSRM routing container |
| `CORS_ALLOWED_ORIGINS` | Origins allowed to call the API — include the dashboard's dev URL |

**`cmers_dashboard/.env`**

| Variable | Purpose |
|---|---|
| `VITE_API_URL` | Base URL of the backend REST API, e.g. `http://localhost:8000/api/v1` |
| `VITE_WS_URL` | Base URL of the backend WebSocket server, e.g. `ws://localhost:8000/ws` |
| `VITE_APP_NAME` | Display name shown in the browser tab |

## Demo accounts

Seeded by `seed_demo_data` — passwords below are exact.

| Role | Login endpoint | Email | Password |
|---|---|---|---|
| Citizen | `POST /api/v1/users/login/` | `ahmed@citizen.com` (also sara/omar/lina/karim `@citizen.com`) | `Citizen1234!` |
| Admin | `POST /api/v1/resources/auth/login/` | `admin@cmers.com` | `Admin1234!` |
| Operator | `POST /api/v1/resources/auth/login/` | `operator1@cmers.com` | `Operator1234!` |
| Operator | `POST /api/v1/resources/auth/login/` | `operator2@cmers.com` | `Operator1234!` |
| Viewer | `POST /api/v1/resources/auth/login/` | `viewer@cmers.com` | `Viewer1234!` |

Citizens and officials are two entirely separate authentication systems — a citizen JWT cannot
access official-only endpoints and vice versa.

## Demo Mode (live defense/demo simulation)

The dashboard has a built-in **Demo Mode**, visible only to admin accounts (top bar, next to the
language toggle). When enabled it:

- Shows an amber border and a **DEMO** badge around the app
- Automatically submits a random citizen report every 30 seconds (random type, severity, and
  Damascus-area coordinates), rotating across all 5 seeded citizen accounts to stay well under
  the report-submission rate limit
- Makes new incidents appear live on the map without anyone manually submitting anything —
  useful for keeping a presentation visually active

Toggle it off any time to stop the automatic submissions.

## Running tests

**Backend unit tests:**

```powershell
docker-compose exec backend python backend/manage.py test core --verbosity=2
```

**Full end-to-end API test suite** (150+ checks across every endpoint, run from the host):

```powershell
cd cmers_backend
python scripts/api_test_suite.py
```

**Performance check** (verifies API/AI-pipeline response times against the <3000ms target):

```powershell
docker-compose exec backend python backend/manage.py check_performance
```

**Frontend lint:**

```powershell
cd cmers_dashboard
npm run lint
```

## API documentation

Interactive Swagger UI, generated from the live schema:

http://localhost:8000/api/docs/

Raw OpenAPI schema: http://localhost:8000/api/schema/

Health check: http://localhost:8000/health/

## WebSocket channels

| Channel | Who connects | Purpose |
|---|---|---|
| `ws://localhost:8000/ws/incidents/?token=<jwt>` | Officials | New incidents, status changes, dispatch updates, danger-zone alerts |
| `ws://localhost:8000/ws/units/?token=<jwt>` | Officials | Live field unit location updates |
| `ws://localhost:8000/ws/citizen/<report_id>/?token=<jwt>` | Citizens | Live status updates for their own report |

Quick manual check with [`wscat`](https://www.npmjs.com/package/wscat):

```
wscat -c "ws://localhost:8000/ws/incidents/?token=<jwt>"
```

## Containers and ports

| Service | Image | Purpose | Port |
|---|---|---|---|
| `db` | postgis/postgis:15-3.3 | PostgreSQL + PostGIS | 5432 |
| `redis` | redis:7-alpine | Cache, Celery broker, Channels layer, rate limiting | 6379 |
| `backend` | Django + Daphne (ASGI) | REST API + WebSockets | 8000 |
| `celery_worker` | Django + Celery | Async AI pipeline execution | — |
| `osrm` | osrm/osrm-backend | Real road-network routing (Syria map) | 5000 |
| dashboard (`npm run dev`) | Vite dev server | Operator web dashboard | 5173 |

## Known limitations

- **`osrm_data/` is not tracked in git.** The processed Syria OSRM extract is ~780MB — well
  over what belongs in a source repo (and over GitHub's 100MB per-file hard limit for some of
  the individual files inside it). Regenerate it with the three `docker run osrm-backend`
  commands in [Getting started](#2-backend-setup) before starting the stack.
- **Report submission is rate-limited to 20/hour per citizen** (and login endpoints are
  similarly limited). This is intentional anti-abuse protection, but it means heavy manual
  testing or a long Demo Mode session can exhaust a single account's quota — Demo Mode already
  rotates across 5 accounts to absorb this.
- Voice report transcription runs locally and requires the relevant model/dependencies to be
  available in the backend container; see `backend/reports/services.py`.

## License

Academic capstone project. Not currently licensed for external reuse — contact the repository
owner before reusing any part of this code.
