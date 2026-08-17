import { create } from 'zustand';
import * as resourcesApi from '../api/resources.api';

const LOCATION_DEBOUNCE_MS = 300;

// Rapid-fire unit.location_updated WebSocket events (many units moving at
// once) would otherwise trigger a store update -- and a map re-render --
// per event, causing visible marker flicker. Buffer updates per unit and
// flush them in a single batched `set` call after a quiet window instead.
let pendingUpdates = {};
let flushTimer = null;

export const useUnitStore = create((set) => {
  function flushPendingUpdates() {
    const updates = pendingUpdates;
    pendingUpdates = {};
    flushTimer = null;
    set((state) => ({
      units: state.units.map((unit) => (updates[unit.id] ? { ...unit, ...updates[unit.id] } : unit)),
    }));
  }

  return {
    units: [],
    isLoading: false,

    fetchUnits: async () => {
      set({ isLoading: true });
      try {
        const data = await resourcesApi.getUnits();
        const results = data.results ?? (Array.isArray(data) ? data : []);
        set({ units: results, isLoading: false });
      } catch (err) {
        set({ isLoading: false });
        throw err;
      }
    },

    // WebSocket handler for unit.location_updated -- debounced by 300ms.
    updateUnitLocation: (data) => {
      pendingUpdates[data.id] = {
        ...pendingUpdates[data.id],
        status: data.status,
        current_latitude: data.latitude,
        current_longitude: data.longitude,
        last_location_update: data.updated_at,
      };
      Object.keys(pendingUpdates[data.id]).forEach((key) => {
        if (pendingUpdates[data.id][key] === undefined) delete pendingUpdates[data.id][key];
      });
      clearTimeout(flushTimer);
      flushTimer = setTimeout(flushPendingUpdates, LOCATION_DEBOUNCE_MS);
    },

    // Merge a partial update (e.g. after a status-change API call succeeds)
    // into the matching unit without refetching the whole list.
    updateUnitInPlace: (id, patch) =>
      set((state) => ({
        units: state.units.map((unit) => (unit.id === id ? { ...unit, ...patch } : unit)),
      })),
  };
});
