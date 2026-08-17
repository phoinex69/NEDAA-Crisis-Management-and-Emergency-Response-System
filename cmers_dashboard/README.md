# NEDAA Dashboard

### Crisis Management and Emergency Response System — Operator Web Dashboard

> This is the React/Vite frontend half of NEDAA. For the overall project (including the Django
> backend) see the [repository root README](../README.md).

Bilingual (English/Arabic, full RTL) operator dashboard for reviewing live incidents on a map,
confirming or overriding AI dispatch suggestions, tracking field units in real time,
broadcasting emergency alerts, and reviewing analytics and audit logs.

## Stack

React 19 · Vite · Ant Design · Zustand · react-leaflet · Recharts · native WebSocket

## Setup

```powershell
copy .env.example .env
npm install
npm run dev
```

Requires the [backend](../cmers_backend) to be running first — see its `.env` for
`CORS_ALLOWED_ORIGINS` and make sure it includes this app's dev URL.

## Scripts

| Command | Purpose |
|---|---|
| `npm run dev` | Start the Vite dev server |
| `npm run build` | Production build (`dist/`) |
| `npm run preview` | Serve the production build locally |
| `npm run lint` | Lint with oxlint |

## Pages

Dashboard · Incidents · Dispatch Center · Field Units · Analytics · Notifications · Audit Logs ·
Settings — full description of each in the [repository root README](../README.md#key-features).

## Notable features

- **Demo Mode** (admin-only, top bar): simulates live citizen activity automatically for
  presentations — see the [root README](../README.md#demo-mode-live-defensedemo-simulation).
- **Language toggle** (EN/AR): flips the entire UI direction via Ant Design's `ConfigProvider`,
  preference saved to `localStorage`.
- Role-gated UI (admin/operator/viewer) that mirrors the backend's actual permissions rather
  than just hiding buttons client-side.
