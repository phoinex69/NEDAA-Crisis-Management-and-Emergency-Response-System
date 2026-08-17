import apiClient from './axios';

export async function getIncidents(params = {}) {
  const response = await apiClient.get('/incidents/', { params });
  return response.data;
}

export async function getIncident(id) {
  const response = await apiClient.get(`/incidents/${id}/`);
  return response.data;
}

export async function getIncidentHistory(id) {
  const response = await apiClient.get(`/incidents/${id}/history/`);
  return response.data;
}

export async function getIncidentReports(id) {
  const response = await apiClient.get(`/incidents/${id}/reports/`);
  return response.data;
}

export async function updateStatus(id, new_status, note) {
  const response = await apiClient.patch(`/incidents/${id}/status/`, { new_status, note });
  return response.data;
}

export async function closeIncident(id, severity, note) {
  const response = await apiClient.post(`/incidents/${id}/close/`, {
    actual_severity: severity,
    note,
  });
  return response.data;
}
