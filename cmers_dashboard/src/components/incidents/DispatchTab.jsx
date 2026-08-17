import { App, Button, Empty, List, Spin, Tag, Typography } from 'antd';
import { useEffect, useState } from 'react';
import {
  completeAssignment,
  confirmDispatch,
  getAssignment,
  getAssignments,
  getAvailableUnits,
  overrideDispatch,
} from '../../api/dispatch.api';
import { COLORS } from '../../theme';
import { formatDate, formatETA } from '../../utils/formatters';

const { Text, Title, Paragraph } = Typography;

const CONFIRMED_STATUSES = ['confirmed', 'dispatched'];

export default function DispatchTab({ incident, onDispatchAction }) {
  const { notification } = App.useApp();

  const [assignment, setAssignment] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);

  const [showOverride, setShowOverride] = useState(false);
  const [availableUnits, setAvailableUnits] = useState([]);
  const [loadingUnits, setLoadingUnits] = useState(false);

  function refetch() {
    setLoading(true);
    getAssignments({ cluster_id: incident.id })
      .then((data) => {
        const results = data.results ?? (Array.isArray(data) ? data : []);
        const latest = results[0];
        if (!latest) {
          setAssignment(null);
          return null;
        }
        return getAssignment(latest.id).then(setAssignment);
      })
      .catch(() => setAssignment(null))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    refetch();
    setShowOverride(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [incident.id]);

  function handleConfirm() {
    setActionLoading(true);
    confirmDispatch(assignment.id)
      .then(() => {
        notification.success({ message: 'Dispatch confirmed' });
        refetch();
        onDispatchAction?.();
      })
      .catch((err) => notification.error({ message: 'Confirm failed', description: err.message }))
      .finally(() => setActionLoading(false));
  }

  function handleComplete() {
    setActionLoading(true);
    completeAssignment(assignment.id)
      .then(() => {
        notification.success({ message: 'Assignment completed' });
        refetch();
        onDispatchAction?.();
      })
      .catch((err) => notification.error({ message: 'Complete failed', description: err.message }))
      .finally(() => setActionLoading(false));
  }

  function openOverride() {
    setShowOverride(true);
    setLoadingUnits(true);
    getAvailableUnits(incident.id)
      .then((data) => setAvailableUnits(Array.isArray(data) ? data : data.results ?? []))
      .catch(() => {})
      .finally(() => setLoadingUnits(false));
  }

  function handleOverride(unitId) {
    setActionLoading(true);
    overrideDispatch(assignment.id, unitId)
      .then(() => {
        notification.success({ message: 'Dispatch overridden' });
        setShowOverride(false);
        refetch();
        onDispatchAction?.();
      })
      .catch((err) => notification.error({ message: 'Override failed', description: err.message }))
      .finally(() => setActionLoading(false));
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 40 }}>
        <Spin />
      </div>
    );
  }

  if (!assignment) {
    return (
      <div style={{ textAlign: 'center', padding: 40 }}>
        <Spin style={{ marginBottom: 12 }} />
        <div style={{ marginBottom: 16 }}>
          <Text type="secondary">AI pipeline processing...</Text>
        </div>
        <Button onClick={refetch}>Refresh</Button>
      </div>
    );
  }

  if (assignment.status === 'completed') {
    return (
      <div style={{ background: '#F0FDF4', border: `1px solid ${COLORS.credibility.green}`, borderRadius: 8, padding: 16 }}>
        <Text strong>{assignment.unit_call_sign} — Completed</Text>
        <div style={{ fontSize: 12, color: '#64748B', marginTop: 4 }}>
          Completed at {formatDate(assignment.completed_at)}
        </div>
      </div>
    );
  }

  if (CONFIRMED_STATUSES.includes(assignment.status)) {
    return (
      <div>
        <div
          style={{
            background: '#F0FDF4',
            border: `1px solid ${COLORS.credibility.green}`,
            borderRadius: 8,
            padding: 16,
            marginBottom: 16,
          }}
        >
          <Text strong style={{ color: COLORS.credibility.green }}>
            {assignment.unit_call_sign} — Dispatched
          </Text>
          <div style={{ fontSize: 12, color: '#64748B', marginTop: 6 }}>
            Confirmed at {formatDate(assignment.confirmed_at)}
          </div>
          <div style={{ fontSize: 12, color: '#64748B' }}>
            Confirmed by {assignment.confirmed_by?.full_name ?? 'Unknown'}
          </div>
        </div>
        <Button type="primary" onClick={handleComplete} loading={actionLoading}>
          Complete Assignment
        </Button>
      </div>
    );
  }

  // status === 'suggested'
  return (
    <div>
      <div
        style={{
          border: `1px solid ${COLORS.border}`,
          borderRadius: 8,
          padding: 16,
          marginBottom: 16,
        }}
      >
        <Title level={5} style={{ marginTop: 0 }}>
          Suggested Unit
        </Title>
        <Text strong style={{ fontSize: 16 }}>
          {assignment.unit_call_sign}
        </Text>
        <div style={{ fontSize: 12, color: '#64748B', marginBottom: 8 }}>{assignment.unit_type_name}</div>
        <div style={{ display: 'flex', gap: 24, marginBottom: 10, fontSize: 13 }}>
          <div>
            <div style={{ color: '#94a3b8', fontSize: 11 }}>ETA</div>
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
            marginBottom: 0,
          }}
        >
          "{assignment.justification}"
        </Paragraph>
      </div>

      <div style={{ display: 'flex', gap: 12 }}>
        <Button type="primary" onClick={handleConfirm} loading={actionLoading} style={{ background: COLORS.primaryNavy }}>
          Confirm Dispatch
        </Button>
        <Button onClick={openOverride}>Override</Button>
      </div>

      {showOverride && (
        <div style={{ marginTop: 16 }}>
          <Title level={5}>Select a different unit</Title>
          {loadingUnits ? (
            <Spin />
          ) : availableUnits.length === 0 ? (
            <Empty description="No other available units." />
          ) : (
            <List
              dataSource={availableUnits}
              renderItem={(unit) => (
                <List.Item
                  style={{ cursor: 'pointer' }}
                  onClick={() => handleOverride(unit.id)}
                  actions={[<Tag key="status" color={COLORS.unitStatus[unit.status]}>{unit.status}</Tag>]}
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
