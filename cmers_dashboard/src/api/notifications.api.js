import apiClient from './axios';

export async function getNotifications() {
  const response = await apiClient.get('/notifications/');
  return response.data;
}

export async function getUnreadCount() {
  const response = await apiClient.get('/notifications/unread-count/');
  return response.data;
}

export async function markRead(id) {
  const response = await apiClient.post(`/notifications/${id}/read/`);
  return response.data;
}

export async function markAllRead() {
  const response = await apiClient.post('/notifications/read-all/');
  return response.data;
}

export async function broadcastAlert(data) {
  const response = await apiClient.post('/notifications/broadcast/', data);
  return response.data;
}

export async function getBroadcastHistory(params = {}) {
  const response = await apiClient.get('/notifications/broadcasts/', { params });
  return response.data;
}
