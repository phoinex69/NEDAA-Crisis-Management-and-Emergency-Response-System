import apiClient from './axios';

export async function login(email, password) {
  const response = await apiClient.post('/resources/auth/login/', { email, password });
  return response.data;
}

export async function refreshToken(refresh) {
  const response = await apiClient.post('/users/token/refresh/', { refresh });
  return response.data;
}
