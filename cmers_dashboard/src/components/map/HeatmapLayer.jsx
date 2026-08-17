import L from 'leaflet';
import { useEffect, useRef } from 'react';
import { useMap } from 'react-leaflet';

let heatPluginLoaded = false;

// leaflet.heat is a pre-ESM plugin that attaches itself to a *global* `L`
// (it does `L.heatLayer = ...` with no import/require of its own), which
// breaks under static ESM import hoisting -- by the time any module-level
// `window.L = L` assignment would run, the plugin has often already
// evaluated against an undefined L. A dynamic import() sidesteps this: it's
// a runtime expression, not hoisted, so `window.L = L` is guaranteed to run
// first.
function ensureHeatPlugin() {
  if (heatPluginLoaded) return Promise.resolve();
  window.L = L;
  return import('leaflet.heat').then(() => {
    heatPluginLoaded = true;
  });
}

const GRADIENT = {
  0.2: '#3B82F6',
  0.5: '#F59E0B',
  0.8: '#EF4444',
  1.0: '#991B1B',
};

export default function HeatmapLayer({ points = [] }) {
  const map = useMap();
  const layerRef = useRef(null);

  useEffect(() => {
    let cancelled = false;

    ensureHeatPlugin().then(() => {
      if (cancelled) return;

      const heatPoints = points
        .filter((p) => p.latitude != null && p.longitude != null)
        .map((p) => [p.latitude, p.longitude, p.weight ?? 1]);

      const layer = L.heatLayer(heatPoints, {
        radius: 35,
        blur: 25,
        maxZoom: 17,
        gradient: GRADIENT,
      });
      layer.addTo(map);
      layerRef.current = layer;
    });

    return () => {
      cancelled = true;
      if (layerRef.current) {
        map.removeLayer(layerRef.current);
        layerRef.current = null;
      }
    };
  }, [map, points]);

  return null;
}
