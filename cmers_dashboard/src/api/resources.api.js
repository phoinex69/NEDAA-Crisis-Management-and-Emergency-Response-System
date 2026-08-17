import apiClient from './axios';

export async function getOrganizations() {
  const response = await apiClient.get('/resources/organizations/');
  return response.data;
}

export async function createOrganization(data) {
  const response = await apiClient.post('/resources/organizations/', data);
  return response.data;
}

export async function updateOrganization(id, data) {
  const response = await apiClient.patch(`/resources/organizations/${id}/`, data);
  return response.data;
}

export async function getAccessRoles() {
  const response = await apiClient.get('/resources/roles/');
  return response.data;
}

export async function getUnitTypes() {
  const response = await apiClient.get('/resources/unit-types/');
  return response.data;
}

export async function getUnits(params = {}) {
  const response = await apiClient.get('/resources/units/', { params });
  return response.data;
}

export async function updateUnitLocation(id, latitude, longitude) {
  const response = await apiClient.patch(`/resources/units/${id}/location/`, {
    latitude,
    longitude,
  });
  return response.data;
}

export async function updateUnitStatus(id, status) {
  const response = await apiClient.patch(`/resources/units/${id}/status/`, { status });
  return response.data;
}

export async function getOfficialAccounts() {
  const response = await apiClient.get('/resources/accounts/');
  return response.data;
}

export async function createOfficialAccount(data) {
  const response = await apiClient.post('/resources/accounts/', data);
  return response.data;
}

export async function deleteOfficialAccount(id) {
  const response = await apiClient.delete(`/resources/accounts/${id}/`);
  return response.data;
}

export async function updateOfficialAccount(id, data) {
  const response = await apiClient.patch(`/resources/accounts/${id}/`, data);
  return response.data;
}
