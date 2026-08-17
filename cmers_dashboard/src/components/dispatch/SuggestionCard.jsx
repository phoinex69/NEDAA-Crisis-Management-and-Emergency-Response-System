import { ClockCircleOutlined } from '@ant-design/icons';
import { Button, Empty, List, Spin, Typography } from 'antd';
import { useState } from 'react';
import { getAvailableUnits } from '../../api/dispatch.api';
import SeverityBadge from '../incidents/SeverityBadge';
import { COLORS } from '../../theme';
import { REPORT_TYPE_ICON_COMPONENTS, REPORT_TYPE_LABELS } from '../../utils/constants';
import { formatETA } from '../../utils/formatters';

const { Text, Paragraph } = Typography;

export default function SuggestionCard({ assignment, onConfirm, onOverride, actionLoading }) {
  const [showOverride, setShowOverride] = useState(false);
  const [units, setUnits] = useState([]);
  const [loadingUnits, setLoadingUnits] = useState(false);

  const Icon = REPORT_TYPE_ICON_COMPONENTS[assignment.cluster_report_type];

  function openOverride() {
    setShowOverride(true);
    setLoadingUnits(true);
    getAvailableUnits(assignment.cluster_id)
      .then((data) => setUnits(Array.isArray(data) ? data : data.results ?? []))
      .catch(() => {})
      .finally(() => setLoadingUnits(false));
  }

  return (
    <div
      className="fade-in"
      style={{
        background: '#fff',
        borderLeft: `4px solid ${COLORS.credibility.yellow}`,
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

      <Text strong style={{ fontSize: 16 }}>
        {assignment.unit_call_sign}
      </Text>
      <div style={{ fontSize: 12, color: '#64748B', marginBottom: 8 }}>{assignment.unit_type_name}</div>

      <div style={{ display: 'flex', gap: 24, marginBottom: 10 }}>
        <div>
          <div style={{ color: '#94a3b8', fontSize: 11 }}>
            <ClockCircleOutlined /> ETA
          </div>
          <Text strong>{formatETA(assignment.eta_minutes)}</Text>
        </div>
        <div>
          <div style={{ color: '#94a3b8', fontSize: 11 }}>Priority Score</div>
          <Text strong>{assignment.priority_score}</Text>
        </div>
      </div>

      <Paragraph
        italic
        style={{
          background: '#F8FAFC',
          borderLeft: `3px solid ${COLORS.primaryBlue}`,
          padding: '8px 12px',
          fontSize: 12,
          marginBottom: 12,
        }}
      >
        "{assignment.justification}"
      </Paragraph>

      <Button
        block
        type="primary"
        style={{ background: COLORS.credibility.green, borderColor: COLORS.credibility.green, marginBottom: 8 }}
        loading={actionLoading}
        onClick={() => onConfirm(assignment)}
      >
        ✓ Confirm Dispatch
      </Button>
      <Button block onClick={openOverride} disabled={actionLoading}>
        ↕ Override
      </Button>

      {showOverride && (
        <div style={{ marginTop: 12 }}>
          {loadingUnits ? (
            <Spin size="small" />
          ) : units.length === 0 ? (
            <Empty description="No other available units." image={Empty.PRESENTED_IMAGE_SIMPLE} />
          ) : (
            <List
              size="small"
              dataSource={units}
              renderItem={(unit) => (
                <List.Item
                  style={{ cursor: 'pointer' }}
                  onClick={() => onOverride(assignment, unit.id)}
                  actions={[
                    <span key="status" style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12 }}>
                      <span
                        style={{
                          width: 6,
                          height: 6,
                          borderRadius: '50%',
                          background: COLORS.unitStatus[unit.status],
                          display: 'inline-block',
                        }}
                      />
                      {unit.status}
                    </span>,
                  ]}
                >
                  <List.Item.Meta
                    title={unit.call_sign}
                    description={`${unit.unit_type_name} · ETA ${formatETA(unit.eta_minutes)}`}
                  />
                </List.Item>
              )}
            />
          )}
        </div>
      )}
    </div>
  );
}
