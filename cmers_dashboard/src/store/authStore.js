import { create } from 'zustand';
import * as authApi from '../api/auth.api';
import { clearTokens, isLoggedIn, saveTokens } from '../utils/tokenManager';

const ACCOUNT_KEY = 'cmers_account';

function saveAccount(account) {
  if (account) localStorage.setItem(ACCOUNT_KEY, JSON.stringify(account));
}

function readAccount() {
  try {
    const raw = localStorage.getItem(ACCOUNT_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export const useAuthStore = create((set) => ({
  account: null,
  isAuthenticated: false,
  isLoading: false,
  isInitializing: true,
  error: null,

  login: async (email, password) => {
    set({ isLoading: true, error: null });
    try {
      const data = await authApi.login(email, password);
      saveTokens(data.tokens?.access, data.tokens?.refresh);
      saveAccount(data.account);
      set({
        account: data.account,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
      return data;
    } catch (err) {
      set({ isLoading: false, error: err.message });
      throw err;
    }
  },

  logout: () => {
    clearTokens();
    localStorage.removeItem(ACCOUNT_KEY);
    set({ account: null, isAuthenticated: false, isLoading: false, error: null });
    window.location.href = '/login';
  },

  loadFromStorage: () => {
    if (isLoggedIn()) {
      set({ account: readAccount(), isAuthenticated: true, isInitializing: false });
    } else {
      set({ account: null, isAuthenticated: false, isInitializing: false });
    }
  },
}));
