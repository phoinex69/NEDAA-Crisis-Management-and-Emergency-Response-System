# Defense Day — Quick Start

Everything is already built and working as of tonight. If your PC restarts or you unplug the phone, here's how to bring it all back.

## 1. Backend (Docker Desktop must be running first)
```
cd "C:\Users\mhdta\Desktop\Project 1\cmers_backend"
docker-compose up -d
```
Wait ~10s, then check: http://localhost:8000/health/ should return `{"status": "ok", ...}`

## 2. Dashboard
```
cd "C:\Users\mhdta\Desktop\Project 1\cmers_dashboard"
npm run dev
```
Open http://localhost:3000

## 3. Phone app
1. Plug the phone into the PC via USB.
2. If a popup asks to allow USB debugging, tap **Allow**.
3. Reconnect the backend tunnel (needed every time the phone reconnects):
   ```
   C:\Users\mhdta\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
   ```
4. Open the **Nidaa** app on the phone (already installed — no rebuild needed).

## Login credentials
| Role | Login | Email/Identifier | Password |
|---|---|---|---|
| Admin | dashboard | admin@cmers.com | Admin1234! |
| Operator | dashboard | operator1@cmers.com | Operator1234! |
| Citizen (demo) | app | ahmed@citizen.com | Citizen1234! |
| Your real account | app | +963938494786 | (your password) |

## Current demo data (already seeded)
- **3 closed/historical incidents**: medical, flood, weather — each fully dispatched and completed.
- **2 active/in-progress**: fire, accident — unit confirmed and en route.
- **3 pending AI suggestions**: security, sos, hazmat — ready for you to confirm live in the Dispatch tab to demo the recommendation flow.
- All demo report locations are scattered near real field units for realistic ETA/recommendation behavior.

## If something looks broken
Check container logs:
```
docker logs cmers_backend-backend-1 --tail 50
docker logs cmers_backend-celery_worker-1 --tail 50
```
OTP codes (dev mode, no real SMS) print to the backend log:
```
docker logs cmers_backend-backend-1 --tail 20 | grep OTP
```
