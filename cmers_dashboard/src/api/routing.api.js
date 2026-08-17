import apiClient from './axios';

export async function getETA(unitId, clusterId) {
  const response = await apiClient.get('/routing/eta/', {
    params: { unit_id: unitId, cluster_id: clusterId },
  });
  return response.data;
}
