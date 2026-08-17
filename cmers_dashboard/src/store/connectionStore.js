import { create } from 'zustand';

// Populated by the single useWebSocket() call in AppLayout. Any component
// that just needs to know "is the socket up" (TopBar's bell, the
// Notifications page status bar, etc.) reads from here instead of calling
// useWebSocket() itself, which would open a second set of connections.
export const useConnectionStore = create((set) => ({
  isConnected: false,
  reconnectCount: 0,
  error: null,
  lastMessageAt: null,

  setStatus: (status) => set(status),
  markMessageReceived: () => set({ lastMessageAt: Date.now() }),
}));
