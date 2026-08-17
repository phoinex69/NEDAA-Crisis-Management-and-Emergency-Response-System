import { DownloadOutlined, ReloadOutlined } from '@ant-design/icons';
import { Alert, Button, DatePicker, Input, Select, Table, Tag, Tooltip, Typography } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useState } from 'react';
import { getLogs } from '../api/audit.api';
import EmptyState from '../components/common/EmptyState';
import { useAuth } from '../hooks/useAuth';
import { ACTOR_TYPE_TAG_COLORS, AUDIT_ACTION_OPTIONS, AUDIT_RESOURCE_TYPE_OPTIONS, getAuditActionTag } from '../utils/constants';

const { Title, Text, Link: TextLink } = Typography;
const { RangePicker } = DatePicker;

const SEARCH_DEBOUNCE_MS = 400;
const PAGE_SIZE = 20;

export default function AuditPage() {
  const { account } = useAuth();
  const isAdmin = account?.role_name === 'admin';

  const [actionFilter, setActionFilter] = useState('');
  const [resourceTypeFilter, setResourceTypeFilter] = useState('');
  const [actorEmail, setActorEmail] = useState('');
  const [debouncedActorEmail, setDebouncedActorEmail] = useState('');
  const [dateRange, setDateRange] = useState([dayjs().subtract(7, 'day'), dayjs()]);

  const [logs, setLogs] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedActorEmail(actorEmail), SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [actorEmail]);

  function buildParams() {
    const params = { page, page_size: PAGE_SIZE };
    if (actionFilter) params.action = actionFilter;
    if (resourceTypeFilter) params.resource_type = resourceTypeFilter;
    if (debouncedActorEmail) params.actor_email = debouncedActorEmail;
    if (dateRange?.[0]) params.date_from = dateRange[0].format('YYYY-MM-DD');
    if (dateRange?.[1]) params.date_to = dateRange[1].format('YYYY-MM-DD');
    return params;
  }

  function doFetch() {
    setLoading(true);
    getLogs(buildParams())
      .then((data) => {
        setLogs(data.results ?? (Array.isArray(data) ? data : []));
        setTotalCount(data.count ?? (Array.isArray(data) ? data.length : 0));
      })
      .catch(() => {
        setLogs([]);
        setTotalCount(0);
      })
      .finally(() => setLoading(false));
  }

  useEffect(doFetch, [actionFilter, resourceTypeFilter, debouncedActorEmail, dateRange, page]);

  function clearFilters() {
    setActionFilter('');
    setResourceTypeFilter('');
    setActorEmail('');
    setDateRange([dayjs().subtract(7, 'day'), dayjs()]);
    setPage(1);
  }

  function handleExport() {
    const blob = new Blob([JSON.stringify(logs, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `nedaa_audit_${dayjs().format('YYYY-MM-DD')}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  const columns = [
    {
      title: 'Time',
      dataIndex: 'created_at',
      width: 170,
      sorter: (a, b) => dayjs(a.created_at).unix() - dayjs(b.created_at).unix(),
      defaultSortOrder: 'descend',
      render: (value) => <span style={{ fontFamily: 'monospace', fontSize: 12 }}>{dayjs(value).format('DD/MM/YYYY HH:mm:ss')}</span>,
    },
    {
      title: 'Actor',
      key: 'actor',
      width: 220,
      render: (_, record) => (
        <div>
          <div style={{ fontSize: 13 }}>{record.actor_email}</div>
          <Tag color={ACTOR_TYPE_TAG_COLORS[record.actor_type] ?? 'default'} style={{ marginTop: 2, fontSize: 10 }}>
            {record.actor_type}
          </Tag>
        </div>
      ),
    },
    {
      title: 'Action',
      dataIndex: 'action',
      width: 190,
      render: (value) => {
        const tag = getAuditActionTag(value);
        return <Tag color={tag.color}>{tag.label}</Tag>;
      },
    },
    {
      title: 'Resource',
      key: 'resource',
      width: 200,
      render: (_, record) => (
        <span style={{ fontSize: 12 }}>
          <Text type="secondary">{record.resource_type}</Text>
          {record.resource_id && (
            <span style={{ fontFamily: 'monospace', marginLeft: 6 }}>{String(record.resource_id).slice(0, 8)}</span>
          )}
        </span>
      ),
    },
    {
      title: 'Note',
      dataIndex: 'note',
      ellipsis: { showTitle: false },
      render: (value) =>
        value ? (
          <Tooltip title={value}>
            <span>{value}</span>
          </Tooltip>
        ) : (
          <Text type="secondary">—</Text>
        ),
    },
    {
      title: 'IP Address',
      dataIndex: 'ip_address',
      width: 130,
      render: (value) => <span style={{ fontFamily: 'monospace', fontSize: 12 }}>{value || 'N/A'}</span>,
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
        <div>
          <Title level={3} style={{ marginBottom: 4 }}>
            Audit Logs
          </Title>
          <Text type="secondary">Track official actions across the system</Text>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <Button icon={<ReloadOutlined />} onClick={doFetch} loading={loading}>
            Refresh
          </Button>
          <Button icon={<DownloadOutlined />} onClick={handleExport} disabled={logs.length === 0}>
            Export
          </Button>
        </div>
      </div>

      {!isAdmin && (
        <Alert
          type="warning"
          showIcon
          style={{ marginBottom: 16 }}
          message="Limited view"
          description="You're viewing only your own dispatch-related actions. Full system audit history is visible to admins only."
        />
      )}

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
          style={{ width: 200 }}
          value={actionFilter}
          onChange={(v) => {
            setActionFilter(v);
            setPage(1);
          }}
          options={AUDIT_ACTION_OPTIONS}
        />
        <Select
          style={{ width: 180 }}
          value={resourceTypeFilter}
          onChange={(v) => {
            setResourceTypeFilter(v);
            setPage(1);
          }}
          options={AUDIT_RESOURCE_TYPE_OPTIONS}
        />
        <Input
          placeholder="Filter by actor email..."
          style={{ width: 220 }}
          value={actorEmail}
          onChange={(e) => {
            setActorEmail(e.target.value);
            setPage(1);
          }}
          allowClear
        />
        <RangePicker
          value={dateRange}
          onChange={(range) => {
            setDateRange(range ?? [dayjs().subtract(7, 'day'), dayjs()]);
            setPage(1);
          }}
          presets={[
            { label: 'Today', value: [dayjs(), dayjs()] },
            { label: 'Last 7 Days', value: [dayjs().subtract(7, 'day'), dayjs()] },
            { label: 'Last 30 Days', value: [dayjs().subtract(30, 'day'), dayjs()] },
          ]}
        />
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
          <TextLink onClick={clearFilters} style={{ fontSize: 13 }}>
            Clear filters
          </TextLink>
        </div>
      </div>

      <Text type="secondary" style={{ fontSize: 12, marginBottom: 8, display: 'block' }}>
        Showing {logs.length} of {totalCount} log entries
      </Text>

      <Table
        columns={columns}
        dataSource={logs}
        rowKey="id"
        loading={loading}
        size="small"
        sticky
        pagination={{
          current: page,
          pageSize: PAGE_SIZE,
          total: totalCount,
          onChange: setPage,
          showSizeChanger: false,
        }}
        rowClassName={(_, index) => (index % 2 === 1 ? 'row-striped' : '')}
        locale={{ emptyText: <EmptyState message="No audit log entries match these filters." /> }}
      />
    </div>
  );
}
