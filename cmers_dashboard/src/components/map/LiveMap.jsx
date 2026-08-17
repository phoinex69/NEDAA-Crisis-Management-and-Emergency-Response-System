import {
  AimOutlined,
  FullscreenExitOutlined,
  FullscreenOutlined,
  LeftOutlined,
  RightOutlined,
} from '@ant-design/icons';
import { Button, Switch, Tooltip } from 'antd';
import { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, TileLayer, ZoomControl } from 'react-leaflet';
import { getHeatmap } from '../../api/analytics.api';
import { useIncidentStore } from '../../store/incidentStore';
import { useUnitStore } from '../../store/unitStore';
import { COLORS, MAP_DEFAULTS } from '../../theme';
import HeatmapLayer from './HeatmapLayer';
import IncidentMarker from './IncidentMarker';
import UnitMarker from './UnitMarker';

const MAP_STYLE_KEY = 'cmers_map_style';

const TILE_STYLES = {
  standard: {
    label: 'Standard',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  },
  light: {
    label: 'Light',
    url: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
  },
  dark: {
    label: 'Dark',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
  },
};

function getSavedMapStyle() {
  const saved = localStorage.getItem(MAP_STYLE_KEY);
  return TILE_STYLES[saved] ? saved : 'standard';
}

function LegendDot({ color, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <span style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0 }} />
      {label}
    </div>
  );
}

export default function LiveMap({
  height = '100%',
  showUnits = true,
  showHeatmap = false,
  showLegend = true,
  showIncidents = true,
  onIncidentClick,
  selectedIncidentId,
  selectedUnitId,
  incidents: incidentsOverride,
  heatmapData,
  center,
  zoom,
}) {
  const storeIncidents = useIncidentStore((state) => state.incidents);
  const incidents = incidentsOverride ?? storeIncidents;
  const units = useUnitStore((state) => state.units);

  const [unitsVisible, setUnitsVisible] = useState(showUnits);
  const [heatmapVisible, setHeatmapVisible] = useState(showHeatmap);
  const [fetchedHeatmapPoints, setFetchedHeatmapPoints] = useState([]);
  const [tilesLoading, setTilesLoading] = useState(true);
  const [legendCollapsed, setLegendCollapsed] = useState(false);
  const [mapStyle, setMapStyle] = useState(getSavedMapStyle);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const mapRef = useRef(null);
  const containerRef = useRef(null);

  // showUnits/showHeatmap only seed the initial state above (so pages using
  // the built-in legend switches can still toggle freely) -- but pages that
  // own their own external controls (e.g. Analytics, which renders its own
  // toggles above the map instead of using the legend) need prop changes to
  // actually take effect after mount too.
  useEffect(() => setUnitsVisible(showUnits), [showUnits]);
  useEffect(() => setHeatmapVisible(showHeatmap), [showHeatmap]);

  // If the caller passes its own heatmapData (already fetched with whatever
  // date range/filters that page cares about), use it directly instead of
  // fetching a separate, possibly-inconsistent copy internally.
  const heatmapPoints = heatmapData ?? fetchedHeatmapPoints;

  useEffect(() => {
    if (!heatmapVisible || heatmapData) return;
    getHeatmap()
      .then((data) => setFetchedHeatmapPoints(Array.isArray(data) ? data : []))
      .catch(() => {});
  }, [heatmapVisible, heatmapData]);

  // Fly to the incident whenever selection changes, however it was
  // selected (from the map itself, or from a list elsewhere on the page).
  useEffect(() => {
    if (!selectedIncidentId || !mapRef.current) return;
    const cluster = incidents.find((item) => item.id === selectedIncidentId);
    if (cluster?.center_latitude && cluster?.center_longitude) {
      mapRef.current.flyTo([cluster.center_latitude, cluster.center_longitude], 15);
    }
  }, [selectedIncidentId, incidents]);

  // Same idea, for the units page: fly to whichever unit is selected in the table.
  useEffect(() => {
    if (!selectedUnitId || !mapRef.current) return;
    const unit = units.find((item) => item.id === selectedUnitId);
    if (unit?.current_latitude != null && unit?.current_longitude != null) {
      mapRef.current.flyTo([unit.current_latitude, unit.current_longitude], 15);
    }
  }, [selectedUnitId, units]);

  // Sync the fullscreen button icon with the actual browser fullscreen
  // state -- this also catches the user pressing Escape, which the browser
  // handles natively without firing our click handler.
  useEffect(() => {
    function handleFullscreenChange() {
      setIsFullscreen(document.fullscreenElement === containerRef.current);
    }
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
  }, []);

  function toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      containerRef.current?.requestFullscreen();
    }
  }

  function handleMapStyleChange(styleKey) {
    setMapStyle(styleKey);
    localStorage.setItem(MAP_STYLE_KEY, styleKey);
  }

  function handleIncidentClick(cluster) {
    if (mapRef.current && cluster.center_latitude && cluster.center_longitude) {
      mapRef.current.flyTo([cluster.center_latitude, cluster.center_longitude], 15);
    }
    onIncidentClick?.(cluster);
  }

  const unitsWithLocation = useMemo(
    () => units.filter((unit) => unit.current_latitude != null && unit.current_longitude != null),
    [units]
  );

  const incidentCoords = useMemo(
    () =>
      incidents
        .filter((cluster) => cluster.center_latitude && cluster.center_longitude)
        .map((cluster) => [cluster.center_latitude, cluster.center_longitude]),
    [incidents]
  );

  function fitToIncidents() {
    if (!mapRef.current || incidentCoords.length === 0) return;
    mapRef.current.fitBounds(incidentCoords, { padding: [40, 40], maxZoom: 15 });
  }

  const activeTile = TILE_STYLES[mapStyle];

  return (
    <div
      ref={containerRef}
      style={{
        position: 'relative',
        height,
        width: '100%',
        overflow: 'hidden',
        borderRadius: isFullscreen ? 0 : 8,
        background: isFullscreen ? '#000' : 'transparent',
      }}
    >
      <MapContainer
        ref={mapRef}
        center={center ?? MAP_DEFAULTS.center}
        zoom={zoom ?? MAP_DEFAULTS.zoom}
        minZoom={8}
        maxZoom={18}
        zoomControl={false}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          key={mapStyle}
          attribution={activeTile.attribution}
          url={activeTile.url}
          eventHandlers={{ load: () => setTilesLoading(false) }}
        />
        <ZoomControl position="bottomright" />

        {heatmapVisible && <HeatmapLayer points={heatmapPoints} />}

        {unitsVisible &&
          unitsWithLocation.map((unit) => (
            <UnitMarker key={unit.id} unit={unit} isSelected={unit.id === selectedUnitId} />
          ))}

        {showIncidents &&
          incidents.map((cluster) => (
            <IncidentMarker
              key={cluster.id}
              cluster={cluster}
              onClick={handleIncidentClick}
              isSelected={cluster.id === selectedIncidentId}
            />
          ))}
      </MapContainer>

      {tilesLoading && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            pointerEvents: 'none',
            zIndex: 500,
          }}
        >
          <div
            style={{
              background: 'rgba(15,23,42,0.65)',
              color: '#fff',
              fontSize: 12,
              padding: '6px 14px',
              borderRadius: 999,
            }}
          >
            Loading map...
          </div>
        </div>
      )}

      {showLegend && (
        <div
          style={{
            position: 'absolute',
            top: 12,
            right: 12,
            zIndex: 1000,
            display: 'flex',
            alignItems: 'flex-start',
          }}
        >
          {/* Collapse/expand toggle -- sits on the legend's left edge */}
          <Tooltip title={legendCollapsed ? 'Show legend' : 'Hide legend'}>
            <button
              type="button"
              onClick={() => setLegendCollapsed((prev) => !prev)}
              style={{
                width: 24,
                height: 24,
                marginTop: 6,
                flexShrink: 0,
                background: '#fff',
                border: `1px solid ${COLORS.border}`,
                borderRadius: 6,
                boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#475569',
                fontSize: 11,
              }}
            >
              {legendCollapsed ? <LeftOutlined /> : <RightOutlined />}
            </button>
          </Tooltip>

          <div
            style={{
              background: '#fff',
              borderRadius: 8,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)',
              fontSize: 12,
              overflow: 'hidden',
              transition: 'width 0.25s ease, opacity 0.25s ease, margin 0.25s ease',
              width: legendCollapsed ? 0 : 178,
              opacity: legendCollapsed ? 0 : 1,
              marginLeft: legendCollapsed ? 0 : 6,
            }}
          >
            <div style={{ padding: 12, width: 178 }}>
              <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 8 }}>
                <Tooltip title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}>
                  <Button
                    size="small"
                    type="text"
                    icon={isFullscreen ? <FullscreenExitOutlined /> : <FullscreenOutlined />}
                    onClick={toggleFullscreen}
                    style={{ padding: '0 4px' }}
                  />
                </Tooltip>
              </div>

              <div style={{ fontWeight: 600, marginBottom: 6, color: '#334155' }}>Severity</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 3, marginBottom: 10 }}>
                <LegendDot color={COLORS.severity[1]} label="Low" />
                <LegendDot color={COLORS.severity[2]} label="Medium" />
                <LegendDot color={COLORS.severity[3]} label="High" />
                <LegendDot color={COLORS.severity[4]} label="Critical" />
              </div>

              <div style={{ fontWeight: 600, marginBottom: 6, color: '#334155' }}>Units</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 3, marginBottom: 12 }}>
                <LegendDot color={COLORS.unitStatus.available} label="Available" />
                <LegendDot color={COLORS.unitStatus.busy} label="Busy" />
                <LegendDot color={COLORS.unitStatus.out_of_service} label="Out of service" />
              </div>

              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  marginBottom: 6,
                }}
              >
                <span>Field Units</span>
                <Switch size="small" checked={unitsVisible} onChange={setUnitsVisible} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                <span>Heatmap</span>
                <Switch size="small" checked={heatmapVisible} onChange={setHeatmapVisible} />
              </div>

              <Tooltip title="Zoom and pan to show all incidents">
                <Button
                  size="small"
                  icon={<AimOutlined />}
                  block
                  onClick={fitToIncidents}
                  disabled={incidentCoords.length === 0}
                  style={{ marginBottom: 12 }}
                >
                  Fit to incidents
                </Button>
              </Tooltip>

              <div style={{ fontWeight: 600, marginBottom: 6, color: '#334155' }}>Map Style</div>
              <div style={{ display: 'flex', gap: 4 }}>
                {Object.entries(TILE_STYLES).map(([key, style]) => (
                  <button
                    key={key}
                    type="button"
                    onClick={() => handleMapStyleChange(key)}
                    style={{
                      flex: 1,
                      border: `1px solid ${mapStyle === key ? COLORS.primaryNavy : COLORS.border}`,
                      borderRadius: 6,
                      background: mapStyle === key ? COLORS.primaryNavy : '#fff',
                      color: mapStyle === key ? '#fff' : '#475569',
                      fontSize: 11,
                      padding: '4px 0',
                      cursor: 'pointer',
                    }}
                  >
                    {style.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
