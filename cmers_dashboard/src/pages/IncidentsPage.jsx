import { EyeOutlined, ReloadOutlined } from '@ant-design/icons';
import { Button, DatePicker, Input, Select, Table, Tag, Tooltip, Typography } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import IncidentDetailDrawer from '../components/incidents/IncidentDetailDrawer';
import CredibilityBadge from '../components/incidents/CredibilityBadge';
import SeverityBadge from '../components/incidents/SeverityBadge';
import EmptyState from '../components/common/EmptyState';
import { useIncidentStore } from '../store/incidentStore';
import { COLORS } from '../theme';
import {
  INCIDENT_STATUS_LABELS,
  REPORT_TYPE_ICON_COMPONENTS,
  REPORT_TYPE_LABELS,
  SEVERITY_FILTER_OPTIONS,
  STATUS_FILTER_OPTIONS,
} from '../utils/constants';
import { formatDate, formatRelative, getSeverityLabel } from '../utils/formatters';

const { Title, Text, Link: TextLink } = Typography;
const { RangePicker } = DatePicker;

const AUTO_REFRESH_SECONDS = 30;
const SEARCH_DEBOUNCE_MS = 400;

export default function IncidentsPage() {
  const incidents = useIncidentStore((state) => state.incidents);
  const totalCount = useIncidentStore((state) => state.totalCount);
  const isLoading = useIncidentStore((state) => state.isLoading);
  const fetchIncidents = useIncidentStore((state) => state.fetchIncidents);

  const [searchParams, setSearchParams] = useSearchParams();

  const [statusFilter, setStatusFilter] = useState('');
  const [severityFilter, setSeverityFilter] = useState('');
  const [dateRange, setDateRange] = useState([dayjs().subtract(24, 'hour'), dayjs()]);
  // Tracks whether the user explicitly picked a date range vs. still on the
  // default "last 24h" view. The default view's upper bound is a snapshot
  // taken at mount, so if we always sent it as date_to, any incident created
  // after that moment would get excluded by every auto-refresh's REST fetch
  // even though it just arrived live over the WebSocket -- it would flash in
  // via the socket then vanish on the next 30s poll. Only apply an upper
  // bound once the user has actually chosen one.
  const [dateRangeTouched, setDateRangeTouched] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const [selectedIncidentId, setSelectedIncidentId] = useState(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const [lastRefreshed, setLastRefreshed] = useState(null);
  const [countdown, setCountdown] = useState(AUTO_REFRESH_SECONDS);

  const [highlightedIds, setHighlightedIds] = useState(new Set());
  const knownIdsRef = useRef(new Set());

  // --- debounce search input ---
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchText), SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [searchText]);

  // --- build params and (re)fetch whenever a server-side filter changes ---
  function buildParams() {
    const params = { page_size: 100 };
    if (statusFilter) params.status = statusFilter;
    if (dateRange?.[0]) params.date_from = dateRange[0].toISOString();
    if (dateRange?.[1] && dateRangeTouched) params.date_to = dateRange[1].toISOString();
    if (debouncedSearch) params.search = debouncedSearch;
    return params;
  }

  function doFetch() {
    fetchIncidents(buildParams())
      .then(() => setLastRefreshed(dayjs()))
      .catch(() => {});
    setCountdown(AUTO_REFRESH_SECONDS);
  }

  useEffect(() => {
    doFetch();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, dateRange, debouncedSearch]);

  // --- auto-refresh countdown ---
  useEffect(() => {
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          doFetch();
          return AUTO_REFRESH_SECONDS;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, dateRange, debouncedSearch]);

  // --- deep link: /incidents?open=<cluster_id> and/or ?severity=4 ---
  useEffect(() => {
    const openId = searchParams.get('open');
    const severityParam = searchParams.get('severity');
    if (openId) {
      setSelectedIncidentId(openId);
      setDrawerOpen(true);
    }
    if (severityParam) {
      setSeverityFilter(Number(severityParam));
    }
    if (openId || severityParam) {
      const next = new URLSearchParams(searchParams);
      next.delete('open');
      next.delete('severity');
      setSearchParams(next, { replace: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // --- detect newly-arrived rows (via WebSocket) for the flash animation ---
  useEffect(() => {
    const currentIds = new Set(incidents.map((i) => i.id));
    const newlyArrived = [...currentIds].filter((id) => !knownIdsRef.current.has(id));
    if (knownIdsRef.current.size > 0 && newlyArrived.length > 0) {
      setHighlightedIds((prev) => new Set([...prev, ...newlyArrived]));
      setTimeout(() => {
        setHighlightedIds((prev) => {
          const next = new Set(prev);
          newlyArrived.forEach((id) => next.delete(id));
          return next;
        });
      }, 2500);
    }
    knownIdsRef.current = currentIds;
  }, [incidents]);

  function clearFilters() {
    setStatusFilter('');
    setSeverityFilter('');
    setDateRange([dayjs().subtract(24, 'hour'), dayjs()]);
    setDateRangeTouched(false);
    setSearchText('');
  }

  // Status "All" behaves as "all except closed" per spec's default -- closed
  // incidents are historical/low-urgency, so they're opt-in via the explicit
  // "Closed" option rather than mixed into the default view.
  // Severity filtering happens client-side: the backend's severity filter
  // matches actual_severity, which is null until an incident closes, so it
  // would silently return nothing for the active incidents this page mostly
  // shows. predicted_severity (AI severity) is what operators actually see.
  const visibleIncidents = useMemo(() => {
    let list = incidents;
    if (!statusFilter) {
      list = list.filter((i) => i.status !== 'closed');
    }
    if (severityFilter) {
      list = list.filter((i) => (i.predicted_severity ?? i.actual_severity) === severityFilter);
    }
    return list;
  }, [incidents, statusFilter, severityFilter]);

  function openDrawer(id) {
    setSelectedIncidentId(id);
    setDrawerOpen(true);
  }

  const columns = [
    {
      title: 'Severity',
      key: 'severity',
      width: 90,
      sorter: (a, b) =>
        (a.predicted_severity ?? a.actual_severity ?? 0) - (b.predicted_severity ?? b.actual_severity ?? 0),
      render: (_, record) => (
        <SeverityBadge level={record.predicted_severity ?? record.actual_severity ?? 1} />
      ),
    },
    {
      title: 'Type',
      key: 'type',
      width: 120,
      render: (_, record) => {
        const Icon = REPORT_TYPE_ICON_COMPONENTS[record.report_type];
        return (
          <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            {Icon && <Icon />}
            {REPORT_TYPE_LABELS[record.report_type] ?? record.report_type ?? 'Unknown'}
          </span>
        );
      },
    },
    {
      title: 'Reports',
      key: 'reports',
      width: 90,
      render: (_, record) => (
        <div>
          <div style={{ color: '#64748B' }}>{record.report_count} reports</div>
          <div style={{ color: '#94a3b8', fontSize: 11 }}>{record.witness_count ?? 0} witnesses</div>
        </div>
      ),
    },
    {
      title: 'Credibility',
      key: 'credibility',
      width: 110,
      render: (_, record) =>
        record.credibility_score ? (
          <CredibilityBadge
            band={record.credibility_score.score_level}
            percent={record.credibility_score.score_percent}
          />
        ) : (
          <Text type="secondary">N/A</Text>
        ),
    },
    {
      title: 'AI Severity',
      key: 'ai_severity',
      width: 110,
      render: (_, record) => {
        if (record.predicted_severity == null) return <Text type="secondary">N/A</Text>;
        const color = COLORS.severity[record.predicted_severity];
        const pct =
          record.predicted_severity_probability != null
            ? ` (${Math.round(record.predicted_severity_probability * 100)}%)`
            : '';
        return (
          <span style={{ color, fontWeight: 600 }}>
            {getSeverityLabel(record.predicted_severity)}
            {pct}
          </span>
        );
      },
    },
    {
      title: 'Status',
      key: 'status',
      width: 110,
      render: (_, record) => (
        <Tag color={COLORS.status[record.status] ?? '#64748B'}>
          {INCIDENT_STATUS_LABELS[record.status] ?? record.status}
        </Tag>
      ),
    },
    {
      title: 'Opened',
      key: 'opened',
      width: 120,
      render: (_, record) => (
        <Tooltip title={formatDate(record.opened_at)}>{formatRelative(record.opened_at)}</Tooltip>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 80,
      render: (_, record) => (
        <Button
          size="small"
          icon={<EyeOutlined />}
          onClick={(e) => {
            e.stopPropagation();
            openDrawer(record.id);
          }}
        >
          View
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
        <div>
          <Title level={3} style={{ marginBottom: 4 }}>
            Incidents
          </Title>
          <Text type="secondary">
            Showing {visibleIncidents.length} of {totalCount} incidents
            {!statusFilter && totalCount > visibleIncidents.length && (
              <> ({totalCount - visibleIncidents.length} closed hidden — select "Closed" above to view)</>
            )}
          </Text>
        </div>
        <div style={{ textAlign: 'right' }}>
          <Button icon={<ReloadOutlined />} onClick={doFetch} loading={isLoading}>
            Refresh
          </Button>
          <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 4 }}>
            {lastRefreshed ? `Updated ${formatRelative(lastRefreshed.toISOString())}` : ''} · next in {countdown}s
          </div>
        </div>
      </div>

      {/* Filter bar */}
      <div
        style={{
          background: '#fff',
          borderRadius: 8,
          boxShadow: 'var(--card-shadow)',
          padding: 16,
          marginBottom: 16,
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          flexWrap: 'wrap',
        }}
      >
        <Select
          style={{ width: 160 }}
          value={statusFilter}
          onChange={setStatusFilter}
          options={STATUS_FILTER_OPTIONS}
        />
        <Select
          style={{ width: 160 }}
          value={severityFilter}
          onChange={setSeverityFilter}
          options={SEVERITY_FILTER_OPTIONS}
        />
        <RangePicker
          value={dateRange}
          onChange={(range) => {
            setDateRange(range ?? [dayjs().subtract(24, 'hour'), dayjs()]);
            setDateRangeTouched(Boolean(range));
          }}
          presets={[
            { label: 'Last 24h', value: [dayjs().subtract(24, 'hour'), dayjs()] },
            { label: 'Last 7 days', value: [dayjs().subtract(7, 'day'), dayjs()] },
          ]}
        />
        <Input.Search
          placeholder="Search description..."
          style={{ width: 220 }}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          allowClear
        />
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
          <TextLink onClick={clearFilters} style={{ fontSize: 13 }}>
            Clear filters
          </TextLink>
          <Tag>{visibleIncidents.length} results</Tag>
        </div>
      </div>

      <Table
        className="incidents-table"
        columns={columns}
        dataSource={visibleIncidents}
        rowKey="id"
        loading={isLoading}
        sticky
        pagination={{ pageSize: 20 }}
        locale={{ emptyText: <EmptyState message="No incidents match these filters." /> }}
        rowClassName={(record) => {
          const classes = [];
          if ((record.predicted_severity ?? record.actual_severity) === 4) classes.push('row-critical');
          if (highlightedIds.has(record.id)) classes.push('row-flash');
          return classes.join(' ');
        }}
        onRow={(record) => ({ onClick: () => openDrawer(record.id) })}
      />

      <IncidentDetailDrawer
        incidentId={selectedIncidentId}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
      />
    </div>
  );
}
