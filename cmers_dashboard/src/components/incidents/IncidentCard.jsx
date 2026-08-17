import { Tag } from 'antd';
import { memo } from 'react';
import { COLORS } from '../../theme';
import { INCIDENT_STATUS_LABELS, REPORT_TYPE_ICONS, REPORT_TYPE_LABELS } from '../../utils/constants';
import { formatRelative } from '../../utils/formatters';
import CredibilityBadge from './CredibilityBadge';
import SeverityBadge from './SeverityBadge';

function IncidentCard({ incident, onClick, isSelected }) {
  const severity = incident.predicted_severity ?? incident.actual_severity;
  const critical = severity === 4;
  const borderColor = COLORS.severity[severity] ?? '#94a3b8';
  const statusColor = COLORS.status[incident.status] ?? '#64748B';

  return (
    <div
      onClick={onClick}
      className={critical ? 'pulse-critical fade-in' : 'fade-in'}
      style={{
        background: critical ? '#FFF5F5' : '#fff',
        borderLeft: `4px solid ${borderColor}`,
        borderBottom: '1px solid #F1F5F9',
        padding: '12px 16px',
        cursor: 'pointer',
        outline: isSelected ? `2px solid ${COLORS.primaryBlue}` : 'none',
        outlineOffset: -2,
        transition: 'background-color 0.15s ease',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.backgroundColor = critical ? '#FFE9E9' : '#F8FAFC';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.backgroundColor = critical ? '#FFF5F5' : '#fff';
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, fontWeight: 600 }}>
          <span>{REPORT_TYPE_ICONS[incident.report_type] ?? '❗'}</span>
          {REPORT_TYPE_LABELS[incident.report_type] ?? incident.report_type ?? 'Incident'}
        </div>
        <SeverityBadge level={severity ?? 1} />
      </div>

      <div style={{ marginTop: 6, fontSize: 12, color: '#64748B' }}>
        {incident.report_count} reports · {incident.witness_count ?? 0} witnesses
      </div>
      <div style={{ fontSize: 12, color: '#94a3b8' }}>Opened {formatRelative(incident.opened_at)}</div>

      <div
        style={{
          marginTop: 8,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {incident.credibility_score ? (
          <CredibilityBadge
            band={incident.credibility_score.score_level}
            percent={incident.credibility_score.score_percent}
          />
        ) : (
          <span />
        )}
        <Tag color={statusColor}>{INCIDENT_STATUS_LABELS[incident.status] ?? incident.status}</Tag>
      </div>
    </div>
  );
}

export default memo(IncidentCard);
