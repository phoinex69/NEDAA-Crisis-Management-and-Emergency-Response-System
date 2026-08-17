import axios from 'axios';
import { clearTokens, getAccessToken } from '../utils/tokenManager';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// These endpoints back near-static reference data (report types, unit types,
// organizations) that every page hitting them re-fetches on mount. A simple
// in-memory TTL cache avoids repeat round-trips within a session -- it's not
// meant to survive a refresh, just to cut redundant calls during normal
// navigation.
const CACHE_RULES = [
  { pattern: /\/reports\/types\/?$/, ttlMs: 60 * 60 * 1000 },
  { pattern: /\/resources\/unit-types\/?$/, ttlMs: 60 * 60 * 1000 },
  { pattern: /\/resources\/organizations\/?$/, ttlMs: 5 * 60 * 1000 },
];
const responseCache = new Map();

function matchCacheRule(url) {
  return CACHE_RULES.find((rule) => rule.pattern.test(url ?? ''));
}

apiClient.interceptors.request.use((config) => {
  const token = getAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  if ((config.method ?? 'get').toLowerCase() === 'get') {
    const rule = matchCacheRule(config.url);
    if (rule) {
      const cached = responseCache.get(config.url);
      if (cached && Date.now() - cached.timestamp < rule.ttlMs) {
        config.adapter = () =>
          Promise.resolve({
            data: cached.data,
            status: 200,
            statusText: 'OK (cached)',
            headers: {},
            config,
          });
      }
    }
  }

  return config;
});

apiClient.interceptors.response.use((response) => {
  if ((response.config.method ?? 'get').toLowerCase() === 'get' && matchCacheRule(response.config.url)) {
    responseCache.set(response.config.url, { data: response.data, timestamp: Date.now() });
  }
  return response;
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearTokens();
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }

    const message =
      error.response?.data?.error ||
      error.response?.data?.detail ||
      error.message ||
      'Something went wrong. Please try again.';

    return Promise.reject(new Error(message));
  }
);

export default apiClient;
