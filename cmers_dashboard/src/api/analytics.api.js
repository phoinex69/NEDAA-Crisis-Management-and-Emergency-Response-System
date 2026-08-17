import apiClient from './axios';

export async function getStats(params = {}) {
  const response = await apiClient.get('/analytics/stats/', { params });
  return response.data;
}

export async function getHeatmap(params = {}) {
  const response = await apiClient.get('/analytics/heatmap/', { params });
  return response.data;
}

export async function getResponseTimes(params = {}) {
  const response = await apiClient.get('/analytics/response-times/', { params });
  return response.data;
}

export async function getUnitPerformance(params = {}) {
  const response = await apiClient.get('/analytics/units/performance/', { params });
  return response.data;
}

export async function getSeverityComparison(params = {}) {
  const response = await apiClient.get('/analytics/severity/comparison/', { params });
  return response.data;
}

export async function getAIAccuracy(params = {}) {
  const response = await apiClient.get('/analytics/ai/accuracy/', { params });
  return response.data;
}
