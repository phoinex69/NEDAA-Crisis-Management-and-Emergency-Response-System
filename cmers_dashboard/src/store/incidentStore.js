import { create } from 'zustand';
import * as incidentsApi from '../api/incidents.api';

export const useIncidentStore = create((set, get) => ({
  incidents: [],
  selectedIncident: null,
  isLoading: false,
  totalCount: 0,
  filters: {},
  // Set by useWebSocket on dispatch.updated. An open IncidentDetailDrawer
  // watches this to know when to refetch its own dispatch data live,
  // without every component needing its own WebSocket subscription.
  lastDispatchEvent: null,
  // Set by useWebSocket on incident.new. DispatchPage watches this to schedule
  // a delayed refetch of pending suggestions -- the AI pipeline (credibility +
  // severity scoring, then greedy unit suggestion) runs a few seconds *after*
  // this event fires, so a suggestion for a brand-new incident isn't there yet
  // at the moment the event arrives.
  lastNewIncidentEvent: null,

  fetchIncidents: async (params) => {
    set({ isLoading: true });
    try {
      const query = params ?? get().filters;
      const data = await incidentsApi.getIncidents(query);
      const results = data.results ?? (Array.isArray(data) ? data : []);
      set({
        incidents: results,
        totalCount: data.count ?? results.length,
        isLoading: false,
      });
    } catch (err) {
      set({ isLoading: false });
      throw err;
    }
  },

  // WebSocket handler: merges partial (incident.updated) or full (incident.new)
  // cluster payloads into the list by id, without clobbering fields the event
  // didn't include.
  addOrUpdateIncident: (cluster) =>
    set((state) => {
      if (!cluster?.id) return state;
      const idx = state.incidents.findIndex((item) => item.id === cluster.id);
      if (idx === -1) {
        if (cluster.center_latitude === undefined) return state;
        return {
          incidents: [cluster, ...state.incidents],
          totalCount: state.totalCount + 1,
        };
      }
      const updated = [...state.incidents];
      updated[idx] = { ...updated[idx], ...cluster };
      return { incidents: updated };
    }),

  selectIncident: (cluster) => set({ selectedIncident: cluster }),

  setLastDispatchEvent: (event) => set({ lastDispatchEvent: { ...event, receivedAt: Date.now() } }),

  setLastNewIncidentEvent: (event) => set({ lastNewIncidentEvent: { ...event, receivedAt: Date.now() } }),

  setFilter: (key, value) => {
    const filters = { ...get().filters, [key]: value };
    set({ filters });
    get().fetchIncidents(filters);
  },
}));
