import L from 'leaflet';
import { memo } from 'react';
import { Marker, Tooltip } from 'react-leaflet';
import { COLORS } from '../../theme';
import { UNIT_STATUS_LABELS } from '../../utils/constants';
import { formatRelative } from '../../utils/formatters';

const UNIT_TYPE_EMOJI = {
  ambulance: '🚑',
  fire_truck: '🚒',
  rescue_team: '🚁',
  shelter: '🏠',
};

function buildIcon(unitType, status, isSelected) {
  const color = COLORS.unitStatus[status] ?? COLORS.unitStatus.available;
  const emoji = UNIT_TYPE_EMOJI[unitType] ?? '🚓';
  const size = isSelected ? 38 : 28;
  const borderWidth = isSelected ? 3 : 2;

  return L.divIcon({
    className: '',
    html: `<div style="
      width:${size}px;height:${size}px;border-radius:6px;
      background:${color};border:${borderWidth}px solid #fff;
      box-shadow:0 2px 6px rgba(0,0,0,0.35);
      display:flex;align-items:center;justify-content:center;
      font-size:${isSelected ? 18 : 14}px;line-height:1;
    ">${emoji}</div>`,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function UnitMarker({ unit, isSelected }) {
  if (unit?.current_latitude == null || unit?.current_longitude == null) return null;

  const statusColor = COLORS.unitStatus[unit.status] ?? COLORS.unitStatus.available;
  const icon = buildIcon(unit.unit_type_name, unit.status, isSelected);

  return (
    <Marker
      position={[unit.current_latitude, unit.current_longitude]}
      icon={icon}
      zIndexOffset={isSelected ? 1000 : 0}
    >
      <Tooltip direction="top" offset={[0, -14]}>
        <div style={{ fontSize: 12 }}>
          <div style={{ fontWeight: 700 }}>{unit.call_sign}</div>
          <div style={{ color: '#64748B' }}>{unit.unit_type_name}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
            <span
              style={{
                width: 6,
                height: 6,
                borderRadius: '50%',
                background: statusColor,
                display: 'inline-block',
              }}
            />
            {UNIT_STATUS_LABELS[unit.status] ?? unit.status}
          </div>
          <div style={{ color: '#94a3b8', marginTop: 2 }}>
            Updated {formatRelative(unit.last_location_update)}
          </div>
        </div>
      </Tooltip>
    </Marker>
  );
}

export default memo(UnitMarker);
