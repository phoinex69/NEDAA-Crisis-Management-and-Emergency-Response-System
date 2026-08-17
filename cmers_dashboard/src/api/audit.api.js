import apiClient from './axios';

export async function getLogs(params = {}) {
  const response = await apiClient.get('/audit/logs/', { params });
  return response.data;
}
