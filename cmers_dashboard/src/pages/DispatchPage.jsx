import { App, Badge, Skeleton, Typography } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useRef, useState } from 'react';
import {
  completeAssignment,
  confirmDispatch,
  getAssignments,
  overrideDispatch,
} from '../api/dispatch.api';
import ActiveAssignmentCard from '../components/dispatch/ActiveAssignmentCard';
import CompletedAssignmentCard from '../components/dispatch/CompletedAssignmentCard';
import SuggestionCard from '../components/dispatch/SuggestionCard';
import EmptyState from '../components/common/EmptyState';
import { useIncidentStore } from '../store/incidentStore';
import { COLORS } from '../theme';

const { Title, Text } = Typography;

const AUTO_REFRESH_MS = 15000;
const PIPELINE_DELAY_MS = 6000;

function unwrap(data) {
  return data?.results ?? (Array.isArray(data) ? data : []);
}

export default function DispatchPage() {
  const { notification } = App.useApp();
  const lastDispatchEvent = useIncidentStore((state) => state.lastDispatchEvent);
  const lastNewIncidentEvent = useIncidentStore((state) => state.lastNewIncidentEvent);

  const [pending, setPending] = useState([]);
  const [active, setActive] = useState([]);
  const [completed, setCompleted] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState(null);

  const seenDispatchEventRef = useRef(null);
  const seenNewIncidentEventRef = useRef(null);

  // Fetches all three (four, counting 'dispatched' separately from
  // 'confirmed' -- both are real active-assignment statuses, seed data
  // includes a 'dispatched' one) columns in parallel and replaces their
  // state directly, so a card that got cancelled server-side (e.g. a stale
  // suggestion pointing at a unit that just became busy) simply stops
  // appearing next time this runs -- no manual page refresh needed.
  function refreshAllLists() {
    setLoading(true);
    Promise.all([
      getAssignments({ status: 'suggested', page_size: 100 }),
      getAssignments({ status: 'confirmed', page_size: 100 }),
      getAssignments({ status: 'dispatched', page_size: 100 }),
      getAssignments({ status: 'completed', page_size: 100 }),
    ])
      .then(([suggestedData, confirmedData, dispatchedData, completedData]) => {
        setPending(unwrap(suggestedData));
        setActive([...unwrap(confirmedData), ...unwrap(dispatchedData)]);
        setCompleted(unwrap(completedData));
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    refreshAllLists();
    const timer = setInterval(refreshAllLists, AUTO_REFRESH_MS);
    return () => clearInterval(timer);
  }, []);

  // dispatch.updated (confirm/override/complete anywhere) -> refresh now.
  useEffect(() => {
    if (lastDispatchEvent && lastDispatchEvent.receivedAt !== seenDispatchEventRef.current) {
      seenDispatchEventRef.current = lastDispatchEvent.receivedAt;
      refreshAllLists();
    }
  }, [lastDispatchEvent]);

  // incident.new -> the AI pipeline needs a few seconds to score + suggest a
  // unit, so schedule one delayed refresh rather than refreshing immediately.
  useEffect(() => {
    if (lastNewIncidentEvent && lastNewIncidentEvent.receivedAt !== seenNewIncidentEventRef.current) {
      seenNewIncidentEventRef.current = lastNewIncidentEvent.receivedAt;
      const timer = setTimeout(refreshAllLists, PIPELINE_DELAY_MS);
      return () => clearTimeout(timer);
    }
    return undefined;
  }, [lastNewIncidentEvent]);

  const completedToday = completed.filter(
    (a) => a.completed_at && dayjs(a.completed_at).isSame(dayjs(), 'day')
  );

  function handleConfirm(assignment) {
    setActionLoadingId(assignment.id);
    confirmDispatch(assignment.id)
      .then(() => {
        notification.success({ message: `Unit ${assignment.unit_call_sign} dispatched` });
        refreshAllLists();
      })
      .catch((err) => notification.error({ message: 'Confirm failed', description: err.message }))
      .finally(() => setActionLoadingId(null));
  }

  function handleOverride(assignment, unitId) {
    setActionLoadingId(assignment.id);
    overrideDispatch(assignment.id, unitId)
      .then((updated) => {
        notification.success({ message: `Unit ${updated.unit_call_sign ?? ''} dispatched` });
        refreshAllLists();
      })
      .catch((err) => notification.error({ message: 'Override failed', description: err.message }))
      .finally(() => setActionLoadingId(null));
  }

  function handleComplete(assignment) {
    setActionLoadingId(assignment.id);
    completeAssignment(assignment.id)
      .then(() => {
        notification.success({ message: `${assignment.unit_call_sign} marked complete` });
        refreshAllLists();
      })
      .catch((err) => notification.error({ message: 'Complete failed', description: err.message }))
      .finally(() => setActionLoadingId(null));
  }

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <Title level={3} style={{ margin: 0 }}>
          Dispatch Center
        </Title>
        {pending.length > 0 && <Badge count={pending.length} color={COLORS.credibility.red} />}
      </div>

      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        <Panel
          title="Pending Suggestions"
          count={pending.length}
          badgeColor={COLORS.credibility.yellow}
          pulsing={pending.length > 0}
          flex="0 0 30%"
          loading={loading}
          emptyMessage="No pending suggestions"
        >
          {pending.map((assignment) => (
            <SuggestionCard
              key={assignment.id}
              assignment={assignment}
              onConfirm={handleConfirm}
              onOverride={handleOverride}
              actionLoading={actionLoadingId === assignment.id}
            />
          ))}
        </Panel>

        <Panel
          title="Active Assignments"
          count={active.length}
          badgeColor={COLORS.primaryBlue}
          flex="0 0 40%"
          loading={loading}
          emptyMessage="No active dispatches"
        >
          {active.map((assignment) => (
            <ActiveAssignmentCard
              key={assignment.id}
              assignment={assignment}
              onComplete={handleComplete}
              actionLoading={actionLoadingId === assignment.id}
            />
          ))}
        </Panel>

        <Panel
          title="Completed Today"
          count={completedToday.length}
          badgeColor={COLORS.credibility.green}
          flex="0 0 30%"
          loading={loading}
          emptyMessage="No completed today"
        >
          {completedToday.map((assignment) => (
            <CompletedAssignmentCard key={assignment.id} assignment={assignment} />
          ))}
        </Panel>
      </div>
    </div>
  );
}

function Panel({ title, count, badgeColor, pulsing, flex, loading, emptyMessage, children }) {
  return (
    <div style={{ flex, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <Text strong style={{ fontSize: 15 }}>
          {title}
        </Text>
        <Badge count={count} showZero color={badgeColor} />
        {pulsing && (
          <span
            className="pulse-critical"
            style={{ width: 8, height: 8, borderRadius: '50%', background: badgeColor, display: 'inline-block' }}
          />
        )}
      </div>
      {loading && count === 0 && <Skeleton active paragraph={{ rows: 3 }} style={{ padding: '4px 0' }} />}
      {!loading && count === 0 && <EmptyState message={emptyMessage} />}
      <div className={!loading ? 'fade-in' : undefined}>{children}</div>
    </div>
  );
}
