import { ClockCircleOutlined, UserOutlined } from '@ant-design/icons';
import { Button, Typography } from 'antd';
import SeverityBadge from '../incidents/SeverityBadge';
import { COLORS } from '../../theme';
import { REPORT_TYPE_ICON_COMPONENTS, REPORT_TYPE_LABELS } from '../../utils/constants';
import { formatDate, formatETA } from '../../utils/formatters';

const { Text } = Typography;

export default function ActiveAssignmentCard({ assignment, onComplete, actionLoading }) {
  const Icon = REPORT_TYPE_ICON_COMPONENTS[assignment.cluster_report_type];
  const onScene = assignment.eta_minutes != null && assignment.eta_minutes <= 1;
  const statusLabel = assignment.status === 'dispatched' ? 'Dispatched' : 'Confirmed';

  return (
    <div
      className="fade-in"
      style={{
        background: '#fff',
        borderLeft: `4px solid ${COLORS.primaryBlue}`,
        borderRadius: 6,
        padding: 16,
        marginBottom: 12,
        boxShadow: 'var(--card-shadow)',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
          {Icon && <Icon />}
          {REPORT_TYPE_LABELS[assignment.cluster_report_type] ?? assignment.cluster_report_type ?? 'Incident'}
        </div>
        <SeverityBadge level={assignment.cluster_predicted_severity ?? 1} />
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <Text strong>{assignment.unit_call_sign}</Text>
        <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, color: COLORS.primaryBlue }}>
          <span
            style={{ width: 6, height: 6, borderRadius: '50%', background: COLORS.primaryBlue, display: 'inline-block' }}
          />
          {statusLabel}
        </span>
      </div>
      <div style={{ fontSize: 12, color: '#94a3b8', marginBottom: 10 }}>
        Confirmed at {formatDate(assignment.confirmed_at)}
      </div>

      <div style={{ fontSize: 13, marginBottom: 6 }}>
        <ClockCircleOutlined style={{ color: '#94a3b8', marginRight: 6 }} />
        {onScene ? <Text strong>On Scene</Text> : <Text strong>ETA: {formatETA(assignment.eta_minutes)}</Text>}
      </div>
      <div style={{ fontSize: 13, marginBottom: 12 }}>
        <UserOutlined style={{ color: '#94a3b8', marginRight: 6 }} />
        {assignment.confirmed_by?.full_name ?? 'Unknown'}
      </div>

      <Button block loading={actionLoading} onClick={() => onComplete(assignment)}>
        Mark Complete
      </Button>
    </div>
  );
}
