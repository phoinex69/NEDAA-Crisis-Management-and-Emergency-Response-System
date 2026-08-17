export const COLORS = {
  primaryNavy: '#0C447C',
  primaryBlue: '#185FA5',
  lightBlue: '#E6F1FB',
  darkBg: '#0A1628',
  sidebarBg: '#0D1F3C',
  sidebarHover: '#1A3255',
  headerBg: '#FFFFFF',
  contentBg: '#F0F2F5',
  cardBg: '#FFFFFF',
  border: '#E2E8F0',

  severity: {
    1: '#2563EB',
    2: '#D97706',
    3: '#DC2626',
    4: '#991B1B',
  },
  severityBg: {
    4: '#FEF2F2',
  },

  credibility: {
    green: '#16A34A',
    greenBg: '#F0FDF4',
    yellow: '#CA8A04',
    yellowBg: '#FEFCE8',
    red: '#DC2626',
    redBg: '#FEF2F2',
  },

  status: {
    received: '#64748B',
    under_review: '#CA8A04',
    assigned: '#2563EB',
    in_progress: '#7C3AED',
    closed: '#16A34A',
    rejected: '#DC2626',
    active: '#DC2626',
  },

  unitStatus: {
    available: '#16A34A',
    busy: '#CA8A04',
    out_of_service: '#DC2626',
  },

  reportType: {
    accident: '#2563EB',
    fire: '#F97316',
    medical: '#DC2626',
    flood: '#0EA5E9',
    security: '#7C3AED',
    hazmat: '#CA8A04',
    weather: '#64748B',
    sos: '#991B1B',
    other: '#94A3B8',
  },
};

export const MAP_DEFAULTS = {
  center: [33.5138, 36.2765],
  zoom: 13,
};

export const ANT_THEME = {
  token: {
    colorPrimary: COLORS.primaryNavy,
    colorLink: COLORS.primaryBlue,
    borderRadius: 8,
    colorBgContainer: '#FFFFFF',
    colorBgLayout: '#F0F2F5',
    fontFamily: 'Inter, system-ui, sans-serif',
    fontSize: 14,
    colorSuccess: COLORS.credibility.green,
    colorWarning: COLORS.credibility.yellow,
    colorError: COLORS.credibility.red,
  },
};
