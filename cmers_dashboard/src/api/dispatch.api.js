import apiClient from './axios';

export async function getAssignments(params = {}) {
  const response = await apiClient.get('/dispatch/assignments/', { params });
  return response.data;
}

export async function getAssignment(id) {
  const response = await apiClient.get(`/dispatch/assignments/${id}/`);
  return response.data;
}

export async function getSuggestion(clusterId) {
  const response = await apiClient.get(`/dispatch/incidents/${clusterId}/suggestion/`);
  return response.data;
}

export async function getAvailableUnits(clusterId) {
  const response = await apiClient.get(`/dispatch/incidents/${clusterId}/units/`);
  return response.data;
}

export async function confirmDispatch(assignmentId) {
  const response = await apiClient.post(`/dispatch/assignments/${assignmentId}/confirm/`, {});
  return response.data;
}

export async function overrideDispatch(assignmentId, unitId) {
  const response = await apiClient.post(`/dispatch/assignments/${assignmentId}/override/`, {
    unit_id: unitId,
  });
  return response.data;
}

export async function completeAssignment(assignmentId) {
  const response = await apiClient.post(`/dispatch/assignments/${assignmentId}/complete/`, {});
  return response.data;
}
