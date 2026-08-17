import {
  AlertOutlined,
  CarOutlined,
  ClockCircleOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Badge, Typography } from 'antd';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { getStats } from '../api/analytics.api';
import IncidentCard from '../components/incidents/IncidentCard';
import LiveMap from '../components/map/LiveMap';
import StatCard from '../components/common/StatCard';
import { useConnectionStore } from '../store/connectionStore';
import { useIncidentStore } from '../store/incidentStore';
import { useUnitStore } from '../store/unitStore';
import { COLORS } from '../theme';
import { REPORT_TYPE_ICONS } from '../utils/constants';
import { formatRelative } from '../utils/formatters';

const { Title, Text } = Typography;

const ACTIVE_STATUSES = ['active', 'assigned', 'in_progress'];

function HealthDot({ ok }) {
  return (
    <span
      style={{
        width: 8,
        height: 8,
        borderRadius: '50%',
        background: ok ? '#16A34A' : '#DC2626',
        display: 'inline-block',
        marginRight: 6,
      }}
    />
  );
}

function SystemHealthCard() {
  const isConnected = useConnectionStore((state) => state.isConnected);
  const lastMessageAt = useConnectionStore((state) => state.lastMessageAt);
  const [, forceTick] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => forceTick((n) => n + 1), 5000);
    return () => clearInterval(timer);
  }, []);

  const lastSyncLabel = lastMessageAt ? formatRelative(new Date(lastMessageAt).toISOString()) : 'No messages yet';

  return (
    <div
      style={{
        background: '#fff',
        borderRadius: 8,
        boxShadow: 'var(--card-shadow)',
        padding: '14px 16px',
        marginTop: 16,
        fontSize: 13,
      }}
    >
      <Text strong style={{ fontSize: 13, display: 'block', marginBottom: 10 }}>
        System Health
      </Text>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span>
            <HealthDot ok />
            API
          </span>
          <Text type="secondary">Connected</Text>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span>
            <HealthDot ok={isConnected} />
            WebSocket
          </span>
          <Text type="secondary">{isConnected ? 'Live' : 'Offline'}</Text>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span>
            <HealthDot ok />
            AI Pipeline
          </span>
          <Text type="secondary">Active</Text>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <Text type="secondary">Last sync</Text>
          <Text type="secondary">{lastSyncLabel}</Text>
        </div>
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const navigate = useNavigate();
  const incidents = useIncidentStore((state) => state.incidents);
  const fetchIncidents = useIncidentStore((state) => state.fetchIncidents);
  const units = useUnitStore((state) => state.units);
  const bannerRef = useRef(null);

  const [selectedIncidentId, setSelectedIncidentId] = useState(null);
  const [avgResponseTime, setAvgResponseTime] = useState(null);

  useEffect(() => {
    getStats()
      .then((data) => setAvgResponseTime(data.avg_response_time_minutes))
      .catch(() => {});
    // incidentStore is shared with IncidentsPage, which overwrites `incidents`
    // with its own filtered view. AppLayout only fetches once on first mount,
    // so re-fetch the unfiltered default view here every time this page is
    // actually shown, rather than trusting whatever the store last held.
    fetchIncidents().catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const activeIncidents = useMemo(
    () => incidents.filter((i) => ACTIVE_STATUSES.includes(i.status)),
    [incidents]
  );
  const criticalCount = useMemo(
    () => incidents.filter((i) => (i.predicted_severity ?? i.actual_severity) === 4).length,
    [incidents]
  );
  const unitsAvailable = useMemo(
    () => units.filter((u) => u.status === 'available').length,
    [units]
  );
  const recentActivity = useMemo(
    () =>
      [...incidents]
        .sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at))
        .slice(0, 5),
    [incidents]
  );

  return (
    <div>
      {/* Live incident counter */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
        <span
          style={{
            width: 8,
            height: 8,
            borderRadius: '50%',
            background: activeIncidents.length > 0 ? COLORS.credibility.red : COLORS.credibility.green,
          }}
          className={activeIncidents.length > 0 ? 'pulse-critical' : ''}
        />
        <Text strong style={{ color: activeIncidents.length > 0 ? COLORS.credibility.red : COLORS.credibility.green }}>
          {activeIncidents.length > 0 ? `${activeIncidents.length} active incidents` : 'All clear'}
        </Text>
      </div>

      {/* Critical incident banner */}
      {criticalCount > 0 && (
        <div
          ref={bannerRef}
          onClick={() => navigate('/incidents?severity=4')}
          className="fade-in"
          style={{
            background: '#DC2626',
            color: '#fff',
            borderRadius: 8,
            padding: '12px 20px',
            marginBottom: 16,
            cursor: 'pointer',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: 10,
          }}
        >
          <WarningOutlined />
          ⚠ {criticalCount} Critical Incident{criticalCount > 1 ? 's' : ''} Require Immediate Attention
        </div>
      )}

      {/* Row 1 — stat cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          gap: 16,
          marginBottom: 20,
        }}
      >
        <StatCard
          title="Total Active Incidents"
          value={activeIncidents.length}
          icon={<AlertOutlined />}
          color={COLORS.severity[3]}
          trend={3}
        />
        <StatCard
          title="Units Available"
          value={unitsAvailable}
          icon={<CarOutlined />}
          color={COLORS.credibility.green}
        />
        <StatCard
          title="Critical Incidents"
          value={criticalCount}
          icon={<WarningOutlined />}
          color={COLORS.severity[4]}
          background={criticalCount > 0 ? COLORS.severityBg[4] : undefined}
        />
        <StatCard
          title="Avg Response Time"
          value={avgResponseTime != null ? Math.round(avgResponseTime) : 'N/A'}
          suffix={avgResponseTime != null ? 'min' : undefined}
          icon={<ClockCircleOutlined />}
          color={COLORS.severity[1]}
        />
      </div>

      {/* Row 2 — map + incidents list */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 20 }}>
        <div style={{ flex: '0 0 65%', minWidth: 0 }}>
          <LiveMap
            height={520}
            showUnits
            showHeatmap={false}
            selectedIncidentId={selectedIncidentId}
            // This fires from the marker popup's "View Details" button (see
            // IncidentMarker.jsx) -- navigate to the Incidents page and deep-link
            // straight into that incident's detail drawer.
            onIncidentClick={(cluster) => navigate(`/incidents?open=${cluster.id}`)}
          />
        </div>

        <div style={{ flex: '0 0 35%', minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <div
            style={{
              background: '#fff',
              borderRadius: 8,
              boxShadow: 'var(--card-shadow)',
              display: 'flex',
              flexDirection: 'column',
              height: 520,
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '14px 16px',
                borderBottom: `1px solid ${COLORS.border}`,
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Title level={5} style={{ margin: 0 }}>
                  Active Incidents
                </Title>
                <Badge count={activeIncidents.length} showZero color={COLORS.primaryBlue} />
              </div>
              <Link to="/incidents" style={{ fontSize: 12 }}>
                View all →
              </Link>
            </div>

            <div style={{ flex: 1, overflowY: 'auto' }}>
              {activeIncidents.length === 0 ? (
                <div style={{ padding: 24, textAlign: 'center' }}>
                  <Text type="secondary">No active incidents.</Text>
                </div>
              ) : (
                activeIncidents.map((incident) => (
                  <IncidentCard
                    key={incident.id}
                    incident={incident}
                    isSelected={incident.id === selectedIncidentId}
                    onClick={() => setSelectedIncidentId(incident.id)}
                  />
                ))
              )}
            </div>
          </div>

          <SystemHealthCard />
        </div>
      </div>

      {/* Row 3 — recent activity strip */}
      <div>
        <Title level={5} style={{ marginBottom: 10 }}>
          Recent Activity
        </Title>
        <div style={{ display: 'flex', gap: 12, overflowX: 'auto', paddingBottom: 4 }}>
          {recentActivity.length === 0 && <Text type="secondary">No recent activity.</Text>}
          {recentActivity.map((incident) => (
            <div
              key={incident.id}
              onClick={() => navigate(`/incidents?open=${incident.id}`)}
              style={{
                flex: '0 0 220px',
                background: '#fff',
                borderRadius: 8,
                boxShadow: 'var(--card-shadow)',
                padding: '10px 14px',
                fontSize: 12,
                cursor: 'pointer',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
                <span>{REPORT_TYPE_ICONS[incident.report_type] ?? '❗'}</span>
                {incident.report_type ?? 'Incident'}
              </div>
              <div style={{ color: '#64748B', marginTop: 4 }}>
                Status changed to <strong>{incident.status}</strong>
              </div>
              <div style={{ color: '#94a3b8', marginTop: 2 }}>
                {formatRelative(incident.updated_at)}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
