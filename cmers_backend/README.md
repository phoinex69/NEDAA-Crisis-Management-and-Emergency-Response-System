# NEDAA — نظام إدارة الأزمات والاستجابة للطوارئ
# Crisis Management and Emergency Response System

## Description

NEDAA is a backend system for coordinating emergency response during crises. Citizens report
incidents (fire, medical emergencies, accidents, SOS alerts, witness statements) through a
mobile-facing API, and an AI pipeline automatically clusters nearby reports into incidents,
scores their credibility (Random Forest), predicts severity (XGBoost), and suggests the nearest
available field unit using a greedy dispatch algorithm with real road-network ETAs from a
self-hosted OSRM instance running a Syria map extract. Officials (admins, operators, viewers)
use a separate authentication system to review incidents, confirm or override AI dispatch
suggestions, track units live over WebSockets, and review analytics — response times, a live
heatmap, unit performance, and AI accuracy against ground truth. Every sensitive action is
audit-logged, rate-limited, and RBAC-enforced between the citizen and official token spaces.

## Prerequisites

- Docker Desktop installed and running
- Git installed
- `wscat` for manual WebSocket testing: `npm install -g wscat`

## First-time setup

Run these from PowerShell.

```powershell
# 1. Clone the repository
git clone <repo-url>

# 2. Enter the backend project folder
cd cmers_backend

# 3. Download the Syria OSM map extract (~78MB)
Invoke-WebRequest `
  -Uri "https://download.geofabrik.de/asia/syria-latest.osm.pbf" `
  -OutFile "osrm_data/syria-latest.osm.pbf"

# 4. Preprocess the map for OSRM — run each command in order, wait for each to finish
docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-extract -p /opt/car.lua /data/syria-latest.osm.pbf

docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-partition /data/syria-latest.osrm

docker run -t -v ${PWD}/osrm_data:/data osrm/osrm-backend:latest `
  osrm-customize /data/syria-latest.osrm

# 5. Build and start the full stack
docker-compose up --build -d

# 6. Wait ~30 seconds for all containers (Postgres, OSRM) to finish starting

# 7. Apply database migrations
docker-compose exec backend python backend/manage.py migrate

# 8. Train the AI models (Random Forest credibility + XGBoost severity)
docker-compose exec backend python backend/manage.py train_models

# 9. Seed realistic demo data (Damascus-area incidents, units, officials, citizens)
docker-compose exec backend python backend/manage.py seed_demo_data
```

## Run tests

```powershell
docker-compose exec backend python backend/manage.py test core --verbosity=2
```

## Check performance

Verifies API and AI-pipeline response times against the < 3000ms NFR target:

```powershell
docker-compose exec backend python backend/manage.py check_performance
```

## Demo accounts

Seeded by `seed_demo_data` — all passwords below are exact.

| Role | Login | Email | Password |
|---|---|---|---|
| Citizen | `POST /api/v1/users/login/` | `ahmed@citizen.com` | `Citizen1234!` |
| Admin | `POST /api/v1/resources/auth/login/` | `admin@cmers.com` | `Admin1234!` |
| Operator | `POST /api/v1/resources/auth/login/` | `operator1@cmers.com` | `Operator1234!` |
| Operator | `POST /api/v1/resources/auth/login/` | `operator2@cmers.com` | `Operator1234!` |
| Viewer | `POST /api/v1/resources/auth/login/` | `viewer@cmers.com` | `Viewer1234!` |

Citizens and officials are two entirely separate authentication systems — a citizen JWT cannot
access official-only endpoints and vice versa.

## API documentation

Interactive Swagger UI, generated from the live schema — use this during defense to walk
supervisors through every endpoint:

http://localhost:8000/api/docs/

Raw OpenAPI schema: http://localhost:8000/api/schema/

## Health check

http://localhost:8000/health/

## Containers and ports

| Service | Image | Purpose | Port |
|---|---|---|---|
| `db` | postgis/postgis:15-3.3 | PostgreSQL + PostGIS | 5432 |
| `redis` | redis:7-alpine | Cache, Celery broker, Channels layer, rate limiting | 6379 |
| `backend` | Django + Daphne (ASGI) | REST API + WebSockets | 8000 |
| `celery_worker` | Django + Celery | Async AI pipeline execution | — |
| `osrm` | osrm/osrm-backend | Real road-network routing (Syria map) | 5000 |

## WebSocket channels

| Channel | Who connects | Purpose |
|---|---|---|
| `ws://localhost:8000/ws/incidents/` | Officials | New incidents, status changes, dispatch updates, danger-zone alerts |
| `ws://localhost:8000/ws/units/` | Officials | Live field unit location updates |
| `ws://localhost:8000/ws/citizen/<report_id>/` | Citizens | Live status updates for their own report |

Quick manual check with `wscat`:

```
wscat -c ws://localhost:8000/ws/incidents/
```
