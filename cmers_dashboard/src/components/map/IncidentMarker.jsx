import L from 'leaflet';
import { memo, useState } from 'react';
import { Marker, Popup, useMapEvents } from 'react-leaflet';
import { Button, Spin } from 'antd';
import { getIncident } from '../../api/incidents.api';
import CredibilityBadge from '../incidents/CredibilityBadge';
import SeverityBadge from '../incidents/SeverityBadge';
import { COLORS } from '../../theme';
import { REPORT_TYPE_LABELS } from '../../utils/constants';
import { formatRelative } from '../../utils/formatters';

const PROBABILITY_FIELD = {
  low: 'probability_low',
  moderate: 'probability_medium',
  high: 'probability_high',
  critical: 'probability_critical',
};

// Zoomed-out views cram many markers into a small area -- shrinking them
// keeps the map readable instead of a wall of overlapping 36px circles.
function baseSizeForZoom(zoom) {
  if (zoom >= 15) return 32;
  if (zoom >= 13) return 26;
  if (zoom >= 11) return 20;
  return 14;
}

function fontSizeForBaseSize(baseSize) {
  if (baseSize === 32) return 11;
  if (baseSize === 26) return 10;
  if (baseSize === 20) return 9;
  return null; // smallest tier: just a colored dot, no count label
}

function buildIcon(severity, isSelected, reportCount, zoomLevel) {
  const baseSize = baseSizeForZoom(zoomLevel);
  const size = isSelected ? baseSize + 8 : baseSize;
  const color = COLORS.severity[severity] ?? '#64748B';
  const borderWidth = isSelected ? 3 : 2;
  const critical = severity === 4;
  const fontSize = fontSizeForBaseSize(baseSize);

  return L.divIcon({
    className: '',
    html: `
      <div class="${critical ? 'pulse-critical' : ''}" style="
        width:${size}px;height:${size}px;border-radius:50%;
        background:${color};
        border:${borderWidth}px solid #fff;
        box-shadow:0 2px 6px rgba(0,0,0,0.35);
        display:flex;align-items:center;justify-content:center;
        color:#fff;font-weight:700;font-size:${fontSize ?? 0}px;
      ">${fontSize != null ? reportCount ?? '' : ''}</div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function IncidentMarker({ cluster, onClick, isSelected }) {
  // credibility_score/predicted_severity are already on the list payload (cheap,
  // prefetched). Only the full probability breakdown is detail-only, so that's
  // the one thing fetched lazily when the popup actually opens.
  const [detail, setDetail] = useState(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const map = useMapEvents({ zoomend: () => setZoomLevel(map.getZoom()) });
  const [zoomLevel, setZoomLevel] = useState(() => map.getZoom());

  if (!cluster?.center_latitude || !cluster?.center_longitude) return null;

  const severity = cluster.predicted_severity ?? cluster.actual_severity;
  const icon = buildIcon(severity, isSelected, cluster.report_count, zoomLevel);

  function handleOpen() {
    if (detail || loadingDetail) return;
    setLoadingDetail(true);
    getIncident(cluster.id)
      .then(setDetail)
      .catch(() => {})
      .finally(() => setLoadingDetail(false));
  }

  const prediction = detail?.severity_prediction;
  const probabilityField = prediction ? PROBABILITY_FIELD[prediction.predicted_level] : null;
  const probability = probabilityField ? prediction[probabilityField] : null;
  const credibility = cluster.credibility_score;

  return (
    <Marker
      position={[cluster.center_latitude, cluster.center_longitude]}
      icon={icon}
      zIndexOffset={isSelected ? 1000 : 0}
      eventHandlers={{ click: handleOpen }}
    >
      <Popup minWidth={220}>
        <div style={{ fontSize: 13, lineHeight: 1.5 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
            <strong>{REPORT_TYPE_LABELS[cluster.report_type] ?? cluster.report_type ?? 'Incident'}</strong>
            <SeverityBadge level={severity ?? 1} />
          </div>

          <div style={{ color: '#64748B', marginBottom: 4 }}>
            {cluster.report_count} reports · {cluster.witness_count ?? 0} witnesses
          </div>
          <div style={{ color: '#94a3b8', marginBottom: 8, fontSize: 12 }}>
            Opened {formatRelative(cluster.opened_at)}
          </div>

          {severity != null && (
            <div style={{ marginBottom: 6 }}>
              AI predicted severity: <strong>{severity}</strong>
              {loadingDetail && <Spin size="small" style={{ marginLeft: 8 }} />}
              {probability != null && ` (${Math.round(probability * 100)}%)`}
            </div>
          )}

          {credibility && (
            <div style={{ marginBottom: 10 }}>
              <CredibilityBadge band={credibility.score_level} percent={credibility.score_percent} />
            </div>
          )}

          <Button
            type="primary"
            size="small"
            block
            onClick={() => onClick?.(cluster)}
            style={{ background: COLORS.primaryNavy }}
          >
            View Details
          </Button>
        </div>
      </Popup>
    </Marker>
  );
}

export default memo(IncidentMarker);
