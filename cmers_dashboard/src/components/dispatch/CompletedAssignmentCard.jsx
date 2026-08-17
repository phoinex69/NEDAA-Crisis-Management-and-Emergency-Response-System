import dayjs from 'dayjs';
import { Typography } from 'antd';
import { COLORS } from '../../theme';
import { REPORT_TYPE_LABELS } from '../../utils/constants';
import { formatDate } from '../../utils/formatters';

const { Text } = Typography;

export default function CompletedAssignmentCard({ assignment }) {
  const responseMinutes =
    assignment.confirmed_at && assignment.completed_at
      ? dayjs(assignment.completed_at).diff(dayjs(assignment.confirmed_at), 'minute')
      : null;

  return (
    <div
      className="fade-in"
      style={{
        background: 'rgba(255,255,255,0.85)',
        borderLeft: `4px solid ${COLORS.credibility.green}`,
        borderRadius: 6,
        padding: 12,
        marginBottom: 10,
        boxShadow: 'var(--card-shadow)',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
        <Text strong>{assignment.unit_call_sign}</Text>
        <Text type="secondary" style={{ fontSize: 12 }}>
          {REPORT_TYPE_LABELS[assignment.cluster_report_type] ?? assignment.cluster_report_type}
        </Text>
      </div>
      <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 4 }}>
        Completed {formatDate(assignment.completed_at)}
      </div>
      {responseMinutes != null && (
        <div style={{ fontSize: 11, color: '#94a3b8' }}>Response time: {responseMinutes} min</div>
      )}
    </div>
  );
}
