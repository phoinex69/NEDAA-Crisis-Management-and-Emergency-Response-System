import {
  AlertOutlined,
  CarOutlined,
  CloudOutlined,
  EnvironmentOutlined,
  FireOutlined,
  HomeOutlined,
  MedicineBoxOutlined,
  SafetyOutlined,
  TeamOutlined,
  ThunderboltOutlined,
  WarningOutlined,
} from '@ant-design/icons';

export const REPORT_TYPE_ICON_COMPONENTS = {
  accident: CarOutlined,
  fire: FireOutlined,
  medical: MedicineBoxOutlined,
  flood: CloudOutlined,
  security: SafetyOutlined,
  hazmat: WarningOutlined,
  weather: ThunderboltOutlined,
  sos: AlertOutlined,
  other: EnvironmentOutlined,
};

export const UNIT_TYPE_ICON_COMPONENTS = {
  ambulance: MedicineBoxOutlined,
  fire_truck: FireOutlined,
  rescue_team: TeamOutlined,
  shelter: HomeOutlined,
};

export const INCIDENT_STATUS_LABELS = {
  new: 'New',
  active: 'Active',
  assigned: 'Assigned',
  in_progress: 'In Progress',
  closed: 'Closed',
};

export const REPORT_STATUS_LABELS = {
  received: 'Received',
  under_review: 'Under Review',
  assigned: 'Assigned',
  in_progress: 'In Progress',
  closed: 'Closed',
  rejected: 'Rejected',
};

export const UNIT_STATUS_LABELS = {
  available: 'Available',
  busy: 'Busy',
  out_of_service: 'Out of Service',
};

export const CREDIBILITY_LABELS = {
  green: 'High Confidence',
  yellow: 'Needs Review',
  red: 'Low Confidence',
};

export const REPORT_TYPE_LABELS = {
  accident: 'Accident',
  fire: 'Fire',
  medical: 'Medical',
  flood: 'Flood',
  security: 'Security',
  hazmat: 'HazMat',
  weather: 'Weather',
  sos: 'SOS',
  other: 'Other',
};

export const REPORT_TYPE_ICONS = {
  accident: '🚗',
  fire: '🔥',
  medical: '⛑️',
  flood: '🌊',
  security: '🛡️',
  hazmat: '☣️',
  weather: '⛈️',
  sos: '🆘',
  other: '❗',
};

export const STATUS_FILTER_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'assigned', label: 'Assigned' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'closed', label: 'Closed' },
];

export const SEVERITY_FILTER_OPTIONS = [
  { value: '', label: 'All Severities' },
  { value: 1, label: 'Low' },
  { value: 2, label: 'Medium' },
  { value: 3, label: 'High' },
  { value: 4, label: 'Critical' },
];

export const CLOSE_SEVERITY_OPTIONS = [
  { value: 1, label: 'Low' },
  { value: 2, label: 'Medium' },
  { value: 3, label: 'High' },
  { value: 4, label: 'Critical' },
];

export const BROADCAST_TYPE_OPTIONS = [
  { value: 'danger_zone', label: 'Danger Zone', emoji: '🔴', tagColor: 'red' },
  { value: 'road_closure', label: 'Road Closure', emoji: '🚧', tagColor: 'orange' },
  { value: 'weather', label: 'Weather Warning', emoji: '🌩️', tagColor: 'blue' },
  { value: 'general', label: 'General Alert', emoji: '📢', tagColor: 'default' },
];

export const BROADCAST_TYPE_BORDER_COLORS = {
  danger_zone: '#DC2626',
  road_closure: '#CA8A04',
  weather: '#2563EB',
  general: '#64748B',
};

export const BROADCAST_TYPE_LABELS = {
  danger_zone: 'Danger Zone',
  road_closure: 'Road Closure',
  weather: 'Weather Warning',
  general: 'General Alert',
};

// Real backend choices (resources/models.py Organization.ORG_TYPE_CHOICES) are
// fire_service/police/medical/government/ngo/private -- not the government/humanitarian
// pair the spec assumed. "Humanitarian" maps onto 'ngo' (what the seeded Red Crescent
// org actually uses), and the rest are exposed for real-world accuracy.
export const ORG_TYPE_OPTIONS = [
  { value: 'government', label: 'Government', tagColor: 'blue' },
  { value: 'ngo', label: 'NGO / Humanitarian', tagColor: 'green' },
  { value: 'fire_service', label: 'Fire Service', tagColor: 'orange' },
  { value: 'police', label: 'Police', tagColor: 'purple' },
  { value: 'medical', label: 'Medical', tagColor: 'red' },
  { value: 'private', label: 'Private', tagColor: 'default' },
];

export function getOrgTypeTag(type) {
  return ORG_TYPE_OPTIONS.find((o) => o.value === type) ?? { label: type, tagColor: 'default' };
}

export const AUDIT_ACTION_OPTIONS = [
  { value: '', label: 'All Actions' },
  { value: 'dispatch_confirmed', label: 'Dispatch Confirmed', color: 'green' },
  { value: 'dispatch_overridden', label: 'Dispatch Overridden', color: 'gold' },
  { value: 'incident_closed', label: 'Incident Closed', color: 'blue' },
  { value: 'official_login', label: 'Official Login', color: 'default' },
  { value: 'broadcast_sent', label: 'Broadcast Sent', color: 'orange' },
  { value: 'medical_card_accessed', label: 'Medical Card Accessed', color: 'red' },
  { value: 'citizen_registered', label: 'Citizen Registered', color: 'cyan' },
  { value: 'account_created', label: 'Account Created', color: 'purple' },
];

export function getAuditActionTag(action) {
  return AUDIT_ACTION_OPTIONS.find((o) => o.value === action) ?? { label: action, color: 'default' };
}

export const AUDIT_RESOURCE_TYPE_OPTIONS = [
  { value: '', label: 'All Resources' },
  { value: 'assignment', label: 'Assignment' },
  { value: 'cluster', label: 'Cluster' },
  { value: 'official_account', label: 'Official Account' },
  { value: 'notification', label: 'Notification' },
  { value: 'medical_profile', label: 'Medical Profile' },
  { value: 'user', label: 'User' },
];

export const ACTOR_TYPE_TAG_COLORS = {
  citizen: 'default',
  official: 'blue',
  system: 'purple',
};

export const WS_EVENT_TYPES = {
  INCIDENT_NEW: 'incident.new',
  INCIDENT_UPDATED: 'incident.updated',
  DISPATCH_UPDATED: 'dispatch.updated',
  UNIT_LOCATION_UPDATED: 'unit.location_updated',
  ALERT_DANGER_ZONE: 'alert.danger_zone',
  CONNECTED: 'connected',
  PONG: 'pong',
};

export const ROLES = {
  ADMIN: 'admin',
  OPERATOR: 'operator',
};

const ROLE_TAG_COLORS = {
  admin: 'red',
  operator: 'blue',
  viewer: 'default',
};

export function getRoleTagColor(roleName) {
  return ROLE_TAG_COLORS[roleName] ?? 'default';
}
