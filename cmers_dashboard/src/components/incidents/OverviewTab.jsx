import { Empty, Progress, Timeline, Typography } from 'antd';
import { useEffect, useState } from 'react';
import { getIncidentHistory } from '../../api/incidents.api';
import LiveMap from '../map/LiveMap';
import { COLORS } from '../../theme';
import { getSeverityLabel } from '../../utils/formatters';
import CredibilityBadge from './CredibilityBadge';
import SeverityBadge from './SeverityBadge';

const { Text, Title } = Typography;

const PROBABILITY_ROWS = [
  { key: 'probability_low', label: 'Low', level: 1 },
  { key: 'probability_medium', label: 'Medium', level: 2 },
  { key: 'probability_high', label: 'High', level: 3 },
  { key: 'probability_critical', label: 'Critical', level: 4 },
];

const CREDIBILITY_EXPLANATIONS = {
  green: 'High confidence report — auto-processed.',
  yellow: 'Needs manual review before dispatch.',
  red: 'Low confidence — likely inaccurate or duplicate.',
};

function useRunningDuration(openedAt, closedAt) {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (closedAt) return undefined;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [closedAt]);

  const end = closedAt ? new Date(closedAt).getTime() : now;
  const start = new Date(openedAt).getTime();
  const totalSeconds = Math.max(0, Math.floor((end - start) / 1000));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return `${hours > 0 ? `${hours}h ` : ''}${minutes}m ${seconds}s`;
}

export default function OverviewTab({ incident }) {
  const [history, setHistory] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(true);

  useEffect(() => {
    setLoadingHistory(true);
    getIncidentHistory(incident.id)
      .then((data) => setHistory(data.results ?? (Array.isArray(data) ? data : [])))
      .catch(() => {})
      .finally(() => setLoadingHistory(false));
  }, [incident.id]);

  const duration = useRunningDuration(incident.opened_at, incident.closed_at);
  const severity = incident.predicted_severity ?? incident.actual_severity;
  const prediction = incident.severity_prediction;
  const credibility = incident.credibility_score;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* Key metrics */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
        <Metric label="AI Severity">
          <SeverityBadge level={severity ?? 1} />
        </Metric>
        <Metric label="Credibility">
          {credibility ? (
            <CredibilityBadge band={credibility.score_level} percent={credibility.score_percent} />
          ) : (
            <Text type="secondary">N/A</Text>
          )}
        </Metric>
        <Metric label="Reports">
          <Text strong>
            {incident.report_count} · {incident.witness_count ?? 0} witnesses
          </Text>
        </Metric>
        <Metric label={incident.closed_at ? 'Time to close' : 'Time open'}>
          <Text strong style={{ fontFamily: 'monospace' }}>
            {duration}
          </Text>
        </Metric>
      </div>

      {/* AI Assessment */}
      <div
        style={{
          border: `1px solid ${COLORS.border}`,
          borderRadius: 8,
          padding: 16,
          background: '#fff',
        }}
      >
        <Title level={5} style={{ marginTop: 0 }}>
          AI Assessment
        </Title>

        {prediction ? (
          <>
            {PROBABILITY_ROWS.map((row) => (
              <div key={row.key} style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12 }}>
                  <span>{row.label}</span>
                  <span>{Math.round((prediction[row.key] ?? 0) * 100)}%</span>
                </div>
                <Progress
                  percent={Math.round((prediction[row.key] ?? 0) * 100)}
                  showInfo={false}
                  strokeColor={COLORS.severity[row.level]}
                  size="small"
                />
              </div>
            ))}
            <Text strong style={{ color: COLORS.severity[severity], display: 'block', marginTop: 8 }}>
              Predicted: {getSeverityLabel(severity)}
              {prediction && PROBABILITY_ROWS.find((r) => r.level === severity)
                ? ` (${Math.round((prediction[PROBABILITY_ROWS.find((r) => r.level === severity).key] ?? 0) * 100)}%)`
                : ''}
            </Text>
          </>
        ) : (
          <Text type="secondary">AI severity prediction not available yet.</Text>
        )}

        {credibility && (
          <div style={{ marginTop: 12, paddingTop: 12, borderTop: `1px solid ${COLORS.border}` }}>
            <CredibilityBadge band={credibility.score_level} percent={credibility.score_percent} />
            <div style={{ fontSize: 12, color: '#64748B', marginTop: 6 }}>
              {CREDIBILITY_EXPLANATIONS[credibility.score_level] ?? ''}
            </div>
          </div>
        )}
      </div>

      {/* Location */}
      <div>
        <Title level={5}>Location</Title>
        <LiveMap
          height={200}
          incidents={[incident]}
          center={[incident.center_latitude, incident.center_longitude]}
          zoom={15}
          showUnits={false}
          showHeatmap={false}
          showLegend={false}
        />
        <div style={{ fontSize: 12, color: '#64748B', marginTop: 6 }}>
          {incident.center_latitude?.toFixed(4)}, {incident.center_longitude?.toFixed(4)} ·{' '}
          <a href={incident.osm_link} target="_blank" rel="noreferrer">
            View on OpenStreetMap
          </a>
        </div>
      </div>

      {/* Timeline */}
      <div>
        <Title level={5}>Status History</Title>
        {!loadingHistory && history.length === 0 && <Empty description="No status changes yet." />}
        {history.length > 0 && (
          <Timeline
            items={history.map((entry) => ({
              children: (
                <div key={entry.id}>
                  <Text strong>
                    {entry.old_status} → {entry.new_status}
                  </Text>
                  <div style={{ fontSize: 12, color: '#64748B' }}>
                    {entry.updated_by_name ?? 'System'} · {new Date(entry.updated_at).toLocaleString()}
                  </div>
                  {entry.note && <div style={{ fontSize: 12, marginTop: 2 }}>{entry.note}</div>}
                </div>
              ),
            }))}
          />
        )}
      </div>
    </div>
  );
}

function Metric({ label, children }) {
  return (
    <div>
      <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 4 }}>{label}</div>
      {children}
    </div>
  );
}
