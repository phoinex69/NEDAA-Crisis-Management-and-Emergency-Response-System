import { App } from 'antd';
import { useEffect, useState } from 'react';
import { useConnectionStore } from '../store/connectionStore';
import { useIncidentStore } from '../store/incidentStore';
import { useUnitStore } from '../store/unitStore';
import { getAccessToken } from '../utils/tokenManager';
import { REPORT_TYPE_LABELS, WS_EVENT_TYPES } from '../utils/constants';

const RECONNECT_DELAY_MS = 3000;
const MAX_RECONNECT_ATTEMPTS = 5;

// NOTE: the backend serves incidents/units updates on two separate channels
// (ws/incidents/ and ws/units/), each requiring the JWT as ?token=... . This
// hook manages both connections but exposes a single combined status, since
// every page just needs "is live data flowing" rather than per-channel detail.
export function useWebSocket() {
  const { notification } = App.useApp();
  const addOrUpdateIncident = useIncidentStore((state) => state.addOrUpdateIncident);
  const setLastDispatchEvent = useIncidentStore((state) => state.setLastDispatchEvent);
  const setLastNewIncidentEvent = useIncidentStore((state) => state.setLastNewIncidentEvent);
  const updateUnitLocation = useUnitStore((state) => state.updateUnitLocation);
  const markMessageReceived = useConnectionStore((state) => state.markMessageReceived);

  const [incidentsConnected, setIncidentsConnected] = useState(false);
  const [unitsConnected, setUnitsConnected] = useState(false);
  const [reconnectCount, setReconnectCount] = useState(0);
  const [error, setError] = useState(null);

  useEffect(() => {
    const token = getAccessToken();
    if (!token) return undefined;

    const wsBase = import.meta.env.VITE_WS_URL;

    // Effects run twice in dev under React 18 StrictMode (mount -> cleanup ->
    // mount again). Without this guard, the first connection gets closed via
    // the cleanup function while it's still CONNECTING, which is exactly what
    // produces the browser's "WebSocket is closed before the connection is
    // established" console message. `cancelled` lets in-flight sockets defer
    // their close until they actually finish opening, and stops any pending
    // reconnect timers/attempts from a cleaned-up effect run from doing
    // anything once cancelled.
    let cancelled = false;
    const sockets = {};
    const timers = {};
    const attempts = { incidents: 0, units: 0 };

    function connectChannel(channel, setConnected, onMessage) {
      if (cancelled) return;
      const socket = new WebSocket(`${wsBase}/${channel}/?token=${token}`);
      sockets[channel] = socket;

      socket.onopen = () => {
        if (cancelled) {
          socket.close();
          return;
        }
        setConnected(true);
        attempts[channel] = 0;
        setError(null);
      };

      socket.onmessage = (event) => {
        if (cancelled) return;
        try {
          const parsed = JSON.parse(event.data);
          markMessageReceived();
          onMessage(parsed);
        } catch {
          // ignore malformed frames
        }
      };

      socket.onclose = () => {
        if (cancelled) return;
        setConnected(false);
        if (attempts[channel] < MAX_RECONNECT_ATTEMPTS) {
          timers[channel] = setTimeout(() => {
            if (cancelled) return;
            attempts[channel] += 1;
            setReconnectCount(attempts.incidents + attempts.units);
            connectChannel(channel, setConnected, onMessage);
          }, RECONNECT_DELAY_MS);
        } else {
          setError(`Lost connection to ${channel} feed after ${MAX_RECONNECT_ATTEMPTS} attempts.`);
        }
      };

      socket.onerror = () => {
        socket.close();
      };
    }

    connectChannel('incidents', setIncidentsConnected, (message) => {
      switch (message.type) {
        case WS_EVENT_TYPES.INCIDENT_NEW: {
          addOrUpdateIncident(message.data);
          setLastNewIncidentEvent(message.data);
          const typeLabel =
            REPORT_TYPE_LABELS[message.data.report_type] ?? message.data.report_type ?? 'Report';
          // incident.new fires before credibility/severity scoring runs (see
          // ai_pipeline/orchestrator.py), so severity isn't known yet at this
          // point -- always "info" here rather than guessing at criticality.
          notification.info({
            message: `New Incident — ${typeLabel}`,
            description: `Near ${message.data.center_latitude?.toFixed(4)}, ${message.data.center_longitude?.toFixed(4)}`,
            duration: 5,
          });
          break;
        }
        case WS_EVENT_TYPES.INCIDENT_UPDATED:
          addOrUpdateIncident(message.data);
          break;
        case WS_EVENT_TYPES.DISPATCH_UPDATED:
          addOrUpdateIncident({ id: message.data.cluster_id, ...message.data });
          setLastDispatchEvent(message.data);
          if (message.data.status === 'confirmed') {
            notification.info({
              message: 'Unit Dispatched',
              description: `${message.data.unit_call_sign} confirmed, ETA ${message.data.eta_minutes} min.`,
            });
          }
          break;
        case WS_EVENT_TYPES.ALERT_DANGER_ZONE:
          notification.warning({
            message: message.data.title,
            description: message.data.message,
            duration: 0,
          });
          break;
        default:
          break;
      }
    });

    connectChannel('units', setUnitsConnected, (message) => {
      if (message.type === WS_EVENT_TYPES.UNIT_LOCATION_UPDATED) {
        updateUnitLocation(message.data);
      }
    });

    return () => {
      cancelled = true;
      clearTimeout(timers.incidents);
      clearTimeout(timers.units);
      Object.values(sockets).forEach((socket) => {
        if (socket.readyState === WebSocket.OPEN) {
          socket.close();
        }
        // if still CONNECTING, the onopen handler above closes it once it
        // actually opens, instead of here.
      });
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const isConnected = incidentsConnected && unitsConnected;
  const setStatus = useConnectionStore((state) => state.setStatus);

  // Mirror this hook's status into a store so other components (e.g. the
  // Notifications page's status bar, TopBar's bell badge) can read "is the
  // socket up" without calling useWebSocket() again, which would open a
  // second, redundant set of connections.
  useEffect(() => {
    setStatus({ isConnected, reconnectCount, error });
  }, [isConnected, reconnectCount, error, setStatus]);

  return { isConnected, reconnectCount, error };
}
