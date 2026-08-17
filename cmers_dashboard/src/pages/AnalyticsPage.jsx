import {
  AlertOutlined,
  CheckCircleOutlined,
  CheckOutlined,
  ClockCircleOutlined,
  CloseOutlined,
  DownloadOutlined,
  ExclamationCircleOutlined,
  FileTextOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Button, DatePicker, Progress, Switch, Table, Typography } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useMemo, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip as RechartsTooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  getAIAccuracy,
  getHeatmap,
  getResponseTimes,
  getSeverityComparison,
  getStats,
  getUnitPerformance,
} from '../api/analytics.api';
import SectionCard from '../components/analytics/SectionCard';
import SeverityBadge from '../components/incidents/SeverityBadge';
import StatCard from '../components/common/StatCard';
import LiveMap from '../components/map/LiveMap';
import { COLORS } from '../theme';
import { REPORT_TYPE_ICON_COMPONENTS, REPORT_TYPE_LABELS, UNIT_TYPE_ICON_COMPONENTS } from '../utils/constants';
import { formatETA } from '../utils/formatters';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const SEVERITY_LABELS = { 1: 'Low', 2: 'Medium', 3: 'High', 4: 'Critical' };

function useSectionData(fetcher, deps) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  function load() {
    setLoading(true);
    setError(null);
    fetcher()
      .then(setData)
      .catch((err) => setError(err.message ?? 'Failed to load.'))
      .finally(() => setLoading(false));
  }

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(load, deps);

  return { data, loading, error, reload: load };
}

function accuracyColor(percent) {
  if (percent > 70) return COLORS.credibility.green;
  if (percent >= 50) return COLORS.credibility.yellow;
  return COLORS.credibility.red;
}

function responseTimeColor(minutes) {
  if (minutes < 10) return COLORS.credibility.green;
  if (minutes <= 20) return COLORS.credibility.yellow;
  return COLORS.credibility.red;
}

function completionRateColor(rate) {
  if (rate > 80) return COLORS.credibility.green;
  if (rate >= 50) return COLORS.credibility.yellow;
  return COLORS.credibility.red;
}

function buildSeverityPieData(reportsBySeverity) {
  const buckets = { 1: 0, 2: 0, 3: 0, 4: 0 };
  Object.entries(reportsBySeverity ?? {}).forEach(([key, count]) => {
    // The model allows severity up to 5, but the chart only wants 4 buckets
    // (Low/Medium/High/Critical) -- fold 5 into Critical rather than drop it.
    const level = Math.min(Number(key), 4);
    if (buckets[level] != null) buckets[level] += count;
  });
  return [1, 2, 3, 4].map((level) => ({
    level,
    name: SEVERITY_LABELS[level],
    value: buckets[level],
    color: COLORS.severity[level],
  }));
}

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState([dayjs().subtract(30, 'day'), dayjs()]);
  const [heatmapOn, setHeatmapOn] = useState(true);
  const [incidentsOn, setIncidentsOn] = useState(true);

  const dateParams = useMemo(
    () => ({
      date_from: dateRange[0].format('YYYY-MM-DD'),
      date_to: dateRange[1].format('YYYY-MM-DD'),
    }),
    [dateRange]
  );

  const stats = useSectionData(() => getStats(dateParams), [dateParams]);
  const heatmap = useSectionData(() => getHeatmap(dateParams), [dateParams]);
  const responseTimes = useSectionData(() => getResponseTimes(dateParams), [dateParams]);
  const aiAccuracy = useSectionData(() => getAIAccuracy(dateParams), [dateParams]);
  const unitPerformance = useSectionData(() => getUnitPerformance(dateParams), [dateParams]);
  const severityComparison = useSectionData(
    () => getSeverityComparison(dateParams).then((data) => data.results ?? (Array.isArray(data) ? data : [])),
    [dateParams]
  );

  function handleExport() {
    if (!stats.data) return;
    const blob = new Blob([JSON.stringify(stats.data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `nedaa_analytics_${dayjs().format('YYYY-MM-DD')}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  const barData = useMemo(
    () =>
      Object.entries(stats.data?.reports_by_type ?? {}).map(([type, count]) => ({
        type,
        label: REPORT_TYPE_LABELS[type] ?? type,
        count,
        color: COLORS.reportType[type] ?? COLORS.primaryBlue,
      })),
    [stats.data]
  );

  const pieData = useMemo(() => buildSeverityPieData(stats.data?.reports_by_severity), [stats.data]);
  const pieTotal = pieData.reduce((sum, d) => sum + d.value, 0);

  const sortedResponseTimes = useMemo(
    () => [...(responseTimes.data ?? [])].sort((a, b) => a.avg_response_minutes - b.avg_response_minutes),
    [responseTimes.data]
  );

  const severityCorrectCount = (severityComparison.data ?? []).filter((r) => r.ai_was_correct).length;
  const severityTotal = severityComparison.data?.length ?? 0;

  return (
    <div>
      {/* Row 1 -- header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <Title level={3} style={{ margin: 0 }}>
          Analytics &amp; Reporting
        </Title>
        <div style={{ display: 'flex', gap: 12 }}>
          <RangePicker
            value={dateRange}
            onChange={(range) => setDateRange(range ?? [dayjs().subtract(30, 'day'), dayjs()])}
            presets={[
              { label: 'Today', value: [dayjs(), dayjs()] },
              { label: 'Last 7 Days', value: [dayjs().subtract(7, 'day'), dayjs()] },
              { label: 'Last 30 Days', value: [dayjs().subtract(30, 'day'), dayjs()] },
            ]}
          />
          <Button icon={<DownloadOutlined />} onClick={handleExport} disabled={!stats.data}>
            Export
          </Button>
        </div>
      </div>

      {/* Row 2 -- stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 16, marginBottom: 20 }}>
        <StatCard
          title="Total Reports"
          value={stats.loading ? '—' : stats.data?.total_reports ?? 0}
          icon={<FileTextOutlined />}
          color="#2563EB"
        />
        <StatCard
          title="Total Incidents"
          value={stats.loading ? '—' : stats.data?.total_incidents ?? 0}
          icon={<AlertOutlined />}
          color="#DC2626"
        />
        <StatCard
          title="Closed Incidents"
          value={stats.loading ? '—' : stats.data?.closed_incidents ?? 0}
          icon={<CheckCircleOutlined />}
          color="#16A34A"
        />
        <StatCard
          title="False Report Rate"
          value={stats.loading ? '—' : `${stats.data?.false_report_rate ?? 0}%`}
          icon={<WarningOutlined />}
          color="#CA8A04"
          valueColor={
            !stats.loading && (stats.data?.false_report_rate ?? 0) > 20 ? COLORS.credibility.red : undefined
          }
        />
        <StatCard
          title="Avg Response Time"
          value={stats.loading ? '—' : stats.data?.avg_response_time_minutes ?? 'N/A'}
          suffix={!stats.loading && stats.data?.avg_response_time_minutes != null ? 'min' : undefined}
          icon={<ClockCircleOutlined />}
          color="#7C3AED"
        />
        <StatCard
          title="Total SOS Alerts"
          value={stats.loading ? '—' : stats.data?.total_sos ?? 0}
          icon={<ExclamationCircleOutlined />}
          color="#DC2626"
          background={!stats.loading && (stats.data?.total_sos ?? 0) > 0 ? COLORS.severityBg[4] : undefined}
        />
      </div>

      {/* Row 3 -- bar + pie charts */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 20 }}>
        <div style={{ flex: '0 0 60%', minWidth: 0 }}>
          <SectionCard title="Reports by Type" loading={stats.loading} error={stats.error} onRetry={stats.reload}>
            {barData.length === 0 ? (
              <Text type="secondary">No reports in this range.</Text>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={barData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                  <RechartsTooltip />
                  <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                    {barData.map((entry) => (
                      <Cell key={entry.type} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </SectionCard>
        </div>

        <div style={{ flex: '0 0 40%', minWidth: 0 }}>
          <SectionCard title="Reports by Severity" loading={stats.loading} error={stats.error} onRetry={stats.reload}>
            {pieTotal === 0 ? (
              <Text type="secondary">No reports in this range.</Text>
            ) : (
              <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                <ResponsiveContainer width="55%" height={220}>
                  <PieChart>
                    <Pie data={pieData} dataKey="value" nameKey="name" innerRadius={45} outerRadius={80}>
                      {pieData.map((entry) => (
                        <Cell key={entry.level} fill={entry.color} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ flex: 1, fontSize: 13 }}>
                  {pieData.map((entry) => (
                    <div
                      key={entry.level}
                      style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}
                    >
                      <span
                        style={{ width: 10, height: 10, borderRadius: '50%', background: entry.color, flexShrink: 0 }}
                      />
                      <span style={{ flex: 1 }}>{entry.name}</span>
                      <Text strong>{entry.value}</Text>
                      <Text type="secondary" style={{ fontSize: 12 }}>
                        ({pieTotal ? Math.round((entry.value / pieTotal) * 100) : 0}%)
                      </Text>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </SectionCard>
        </div>
      </div>

      {/* Row 4 -- heatmap */}
      <div style={{ marginBottom: 20 }}>
        <SectionCard
          title="Incident Density Map"
          loading={heatmap.loading}
          error={heatmap.error}
          onRetry={heatmap.reload}
          extra={
            <div style={{ display: 'flex', gap: 20 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
                Heatmap
                <Switch size="small" checked={heatmapOn} onChange={setHeatmapOn} />
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
                Incidents
                <Switch size="small" checked={incidentsOn} onChange={setIncidentsOn} />
              </label>
            </div>
          }
        >
          <LiveMap
            height={400}
            showHeatmap={heatmapOn}
            showIncidents={incidentsOn}
            showUnits={false}
            showLegend={false}
            heatmapData={heatmap.data ?? []}
          />
        </SectionCard>
      </div>

      {/* Row 5 -- response times + AI accuracy */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 20 }}>
        <div style={{ flex: '0 0 55%', minWidth: 0 }}>
          <SectionCard
            title="Response Time by Type"
            loading={responseTimes.loading}
            error={responseTimes.error}
            onRetry={responseTimes.reload}
          >
            <Table
              size="small"
              pagination={false}
              rowKey="report_type"
              dataSource={sortedResponseTimes}
              locale={{ emptyText: 'No closed incidents with response times in this range.' }}
              columns={[
                {
                  title: 'Incident Type',
                  key: 'type',
                  render: (_, row) => {
                    const Icon = REPORT_TYPE_ICON_COMPONENTS[row.report_type];
                    return (
                      <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        {Icon && <Icon />}
                        {REPORT_TYPE_LABELS[row.report_type] ?? row.report_type}
                      </span>
                    );
                  },
                },
                {
                  title: 'Avg Response',
                  dataIndex: 'avg_response_minutes',
                  render: (value) => (
                    <Text strong style={{ color: responseTimeColor(value) }}>
                      {value} min
                    </Text>
                  ),
                },
                { title: 'Min', dataIndex: 'min_response_minutes', render: (v) => `${v} min` },
                { title: 'Max', dataIndex: 'max_response_minutes', render: (v) => `${v} min` },
                { title: 'Incidents', dataIndex: 'total_incidents' },
              ]}
            />
          </SectionCard>
        </div>

        <div style={{ flex: '0 0 45%', minWidth: 0 }}>
          <SectionCard
            title="AI Model Performance"
            subtitle="Based on closed incidents where actual severity was recorded"
            loading={aiAccuracy.loading}
            error={aiAccuracy.error}
            onRetry={aiAccuracy.reload}
          >
            {aiAccuracy.data?.total_evaluated === 0 ? (
              <Text type="secondary">
                No closed incidents to evaluate yet. Close some incidents and set actual severity to see AI
                accuracy.
              </Text>
            ) : (
              <>
                <AccuracyBlock label="Credibility Model (RF)" percent={aiAccuracy.data?.rf_accuracy_percent ?? 0} />
                <AccuracyBlock
                  label="Severity Model (XGBoost)"
                  percent={aiAccuracy.data?.xgb_accuracy_percent ?? 0}
                  style={{ marginTop: 20 }}
                />
                <div style={{ marginTop: 16, fontSize: 12, color: '#94a3b8' }}>
                  Based on {aiAccuracy.data?.total_evaluated ?? 0} closed incidents
                </div>
              </>
            )}
          </SectionCard>
        </div>
      </div>

      {/* Row 6 -- unit performance */}
      <div style={{ marginBottom: 20 }}>
        <SectionCard
          title="Field Unit Performance"
          loading={unitPerformance.loading}
          error={unitPerformance.error}
          onRetry={unitPerformance.reload}
        >
          <Table
            size="small"
            pagination={false}
            rowKey="unit_id"
            dataSource={unitPerformance.data ?? []}
            columns={[
              {
                title: 'Unit',
                dataIndex: 'call_sign',
                render: (value) => (
                  <Text strong style={{ fontFamily: 'monospace' }}>
                    {value}
                  </Text>
                ),
              },
              {
                title: 'Type',
                dataIndex: 'unit_type',
                render: (value) => {
                  const Icon = UNIT_TYPE_ICON_COMPONENTS[value];
                  return (
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      {Icon && <Icon />}
                      {value}
                    </span>
                  );
                },
              },
              { title: 'Total Assignments', dataIndex: 'total_assignments' },
              { title: 'Completed', dataIndex: 'completed_assignments' },
              {
                title: 'Completion Rate',
                key: 'completion_rate',
                render: (_, row) => {
                  const rate = row.total_assignments > 0 ? (row.completed_assignments / row.total_assignments) * 100 : 0;
                  return (
                    <Text strong style={{ color: completionRateColor(rate) }}>
                      {Math.round(rate)}%
                    </Text>
                  );
                },
              },
              {
                title: 'Avg ETA',
                dataIndex: 'avg_eta_minutes',
                render: (value) => formatETA(value),
              },
              {
                title: 'Times Overridden',
                dataIndex: 'overridden_count',
                render: (value) => (
                  <Text style={{ color: value > 0 ? COLORS.credibility.yellow : undefined }}>{value}</Text>
                ),
              },
            ]}
          />
        </SectionCard>
      </div>

      {/* Row 7 -- severity comparison */}
      <div>
        <SectionCard
          title="AI vs Citizen Severity"
          subtitle="How citizen estimates compare to AI predictions and actual severity"
          loading={severityComparison.loading}
          error={severityComparison.error}
          onRetry={severityComparison.reload}
        >
          <Table
            size="small"
            pagination={false}
            rowKey="cluster_id"
            dataSource={severityComparison.data ?? []}
            locale={{ emptyText: 'No closed incidents in this range.' }}
            columns={[
              { title: 'Cluster ID', dataIndex: 'cluster_id', render: (v) => v.slice(0, 8) },
              {
                title: 'Citizen Reported',
                dataIndex: 'citizen_severity',
                render: (v) => (v != null ? <SeverityBadge level={Math.min(v, 4)} /> : <Text type="secondary">N/A</Text>),
              },
              {
                title: 'AI Predicted',
                dataIndex: 'ai_predicted_severity',
                render: (v) => (v != null ? <SeverityBadge level={v} /> : <Text type="secondary">N/A</Text>),
              },
              {
                title: 'Actual',
                dataIndex: 'actual_severity',
                render: (v) => (v != null ? <SeverityBadge level={v} /> : <Text type="secondary">N/A</Text>),
              },
              {
                title: 'AI Correct',
                dataIndex: 'ai_was_correct',
                render: (v) =>
                  v ? (
                    <CheckOutlined style={{ color: COLORS.credibility.green }} />
                  ) : (
                    <CloseOutlined style={{ color: COLORS.credibility.red }} />
                  ),
              },
            ]}
          />
          {severityTotal > 0 && (
            <div style={{ marginTop: 16, fontSize: 14 }}>
              <Text strong>
                AI severity prediction matched actual in {severityCorrectCount} out of {severityTotal} closed
                incidents ({Math.round((severityCorrectCount / severityTotal) * 100)}%)
              </Text>
            </div>
          )}
        </SectionCard>
      </div>
    </div>
  );
}

function AccuracyBlock({ label, percent, style }) {
  const color = accuracyColor(percent);
  return (
    <div style={style}>
      <Text style={{ fontSize: 13, color: '#64748B' }}>{label}</Text>
      <div style={{ fontSize: 28, fontWeight: 700, color, lineHeight: 1.3 }}>{percent}%</div>
      <Progress percent={percent} showInfo={false} strokeColor={color} />
    </div>
  );
}
