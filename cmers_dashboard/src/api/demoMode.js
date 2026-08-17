import axios from 'axios';

// Demo mode submits reports as a real citizen (the backend's report-submission
// endpoint requires citizen auth, not an official token), so it logs in with a
// seeded demo citizen account and reuses that token, bypassing the shared
// apiClient instance entirely (it always attaches the official Bearer token
// via its request interceptor).
//
// Report submission is rate-limited to 20/hour PER CITIZEN on the backend.
// A single account would exhaust its quota after ~10 minutes of continuous
// demo mode (30s interval), so this rotates across all 5 seeded citizens --
// giving ~100 submissions/hour of combined headroom instead of 20.
const DEMO_CITIZENS = [
  { identifier: 'ahmed@citizen.com', password: 'Citizen1234!' },
  { identifier: 'sara@citizen.com', password: 'Citizen1234!' },
  { identifier: 'omar@citizen.com', password: 'Citizen1234!' },
  { identifier: 'lina@citizen.com', password: 'Citizen1234!' },
  { identifier: 'karim@citizen.com', password: 'Citizen1234!' },
];

// Damascus bounding box, matches the seed data's geographic spread.
const BOUNDS = { latMin: 33.44, latMax: 33.58, lngMin: 36.2, lngMax: 36.35 };
const REPORT_TYPES = ['accident', 'fire', 'medical', 'flood', 'security', 'hazmat', 'weather'];

const citizenTokens = new Map();
let nextCitizenIndex = 0;

function apiBase() {
  return import.meta.env.VITE_API_URL;
}

async function loginCitizen(citizen) {
  const res = await axios.post(`${apiBase()}/users/login/`, citizen);
  const token = res.data.tokens.access;
  citizenTokens.set(citizen.identifier, token);
  return token;
}

function randomInRange(min, max) {
  return min + Math.random() * (max - min);
}

function randomReportPayload() {
  return {
    report_type: REPORT_TYPES[Math.floor(Math.random() * REPORT_TYPES.length)],
    latitude: randomInRange(BOUNDS.latMin, BOUNDS.latMax),
    longitude: randomInRange(BOUNDS.lngMin, BOUNDS.lngMax),
    reported_severity: 2 + Math.floor(Math.random() * 3),
    description: 'Demo mode simulated report for defense presentation.',
    submission_method: 'form',
    idempotency_key: `demo-${Date.now()}`,
  };
}

export async function submitRandomDemoReport() {
  const citizen = DEMO_CITIZENS[nextCitizenIndex];
  nextCitizenIndex = (nextCitizenIndex + 1) % DEMO_CITIZENS.length;

  const payload = randomReportPayload();
  let token = citizenTokens.get(citizen.identifier) ?? (await loginCitizen(citizen));

  try {
    return await axios.post(`${apiBase()}/reports/`, payload, {
      headers: { Authorization: `Bearer ${token}` },
    });
  } catch (err) {
    if (err.response?.status === 401) {
      token = await loginCitizen(citizen);
      return axios.post(`${apiBase()}/reports/`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
    }
    throw err;
  }
}
