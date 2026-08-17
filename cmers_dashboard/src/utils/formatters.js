import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

dayjs.extend(relativeTime);

export function formatDate(str) {
  if (!str) return 'N/A';
  return dayjs(str).format('DD/MM/YYYY HH:mm');
}

export function formatRelative(str) {
  if (!str) return 'N/A';
  return dayjs(str).fromNow();
}

export function formatETA(mins) {
  if (mins === null || mins === undefined || Number.isNaN(mins)) return 'N/A';
  if (mins < 60) return `${Math.round(mins)} min`;
  const hours = Math.floor(mins / 60);
  const remainder = Math.round(mins % 60);
  return remainder > 0 ? `${hours}h ${remainder}min` : `${hours}h`;
}

export function formatDistance(km) {
  if (km === null || km === undefined || Number.isNaN(km)) return 'N/A';
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1)} km`;
}

const SEVERITY_LABELS = {
  en: { 1: 'Low', 2: 'Medium', 3: 'High', 4: 'Critical' },
  ar: { 1: 'منخفض', 2: 'متوسط', 3: 'مرتفع', 4: 'حرج' },
};

export function getSeverityLabel(level, lang = 'en') {
  const labels = SEVERITY_LABELS[lang] || SEVERITY_LABELS.en;
  return labels[level] || 'Unknown';
}
