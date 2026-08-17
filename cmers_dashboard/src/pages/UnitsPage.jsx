import { CarOutlined, CloseOutlined, EnvironmentOutlined, TeamOutlined, WarningOutlined } from '@ant-design/icons';
import { App, Select, Skeleton, Table, Tag, Typography } from 'antd';
import { useEffect, useMemo, useState } from 'react';
import { getAssignments } from '../api/dispatch.api';
import { updateUnitStatus } from '../api/resources.api';
import StatCard from '../components/common/StatCard';
import { useUnitStore } from '../store/unitStore';
import { COLORS } from '../theme';
import { REPORT_TYPE_LABELS, UNIT_STATUS_LABELS, UNIT_TYPE_ICON_COMPONENTS } from '../utils/constants';
import { formatDate, formatRelative } from '../utils/formatters';

const { Title, Text } = Typography;

const STATUS_OPTIONS = [
  { value: 'available', label: 'Available' },
  { value: 'busy', label: 'Busy' },
  { value: 'out_of_service', label: 'Out of Service' },
];

const STALE_MINUTES = 10;

export default function UnitsPage() {
  const { notification } = App.useApp();
  const units = useUnitStore((state) => state.units);
  const unitsLoading = useUnitStore((state) => state.isLoading);
  const updateUnitInPlace = useUnitStore((state) => state.updateUnitInPlace);

  const [selectedUnitId, setSelectedUnitId] = useState(null);
  const [statusUpdatingId, setStatusUpdatingId] = useState(null);
  const [history, setHistory] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  const selectedUnit = units.find((u) => u.id === selectedUnitId) ?? null;

  useEffect(() => {
    if (!selectedUnitId) return;
    setLoadingHistory(true);
    getAssignments({ unit_id: selectedUnitId, status: 'completed', page_size: 3 })
      .then((data) => setHistory(data.results ?? (Array.isArray(data) ? data : [])))
      .catch(() => {})
      .finally(() => setLoadingHistory(false));
  }, [selectedUnitId]);

  const stats = useMemo(
    () => ({
      total: units.length,
      available: units.filter((u) => u.status === 'available').length,
      busy: units.filter((u) => u.status === 'busy').length,
      out_of_service: units.filter((u) => u.status === 'out_of_service').length,
    }),
    [units]
  );

  function handleStatusChange(unit, status) {
    setStatusUpdatingId(unit.id);
    updateUnitStatus(unit.id, status)
      .then((updated) => {
        updateUnitInPlace(unit.id, updated);
        notification.success({ message: `${unit.call_sign} status updated` });
      })
      .catch((err) => notification.error({ message: 'Update failed', description: err.message }))
      .finally(() => setStatusUpdatingId(null));
  }

  const columns = [
    {
      title: 'Status',
      key: 'status',
      width: 130,
      render: (_, unit) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span
            style={{
              width: 9,
              height: 9,
              borderRadius: '50%',
              background: COLORS.unitStatus[unit.status],
              display: 'inline-block',
              flexShrink: 0,
            }}
          />
          {UNIT_STATUS_LABELS[unit.status] ?? unit.status}
        </span>
      ),
    },
    {
      title: 'Call Sign',
      dataIndex: 'call_sign',
      key: 'call_sign',
      width: 160,
      render: (value) => (
        <Text strong style={{ fontFamily: 'monospace', fontSize: 14 }}>
          {value}
        </Text>
      ),
    },
    {
      title: 'Type',
      key: 'type',
      width: 170,
      render: (_, unit) => {
        const Icon = UNIT_TYPE_ICON_COMPONENTS[unit.unit_type_name];
        return (
          <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {Icon && <Icon style={{ color: '#64748B' }} />}
            {unit.unit_type_name}
          </span>
        );
      },
    },
    {
      title: 'Organization',
      dataIndex: 'organization_name',
      key: 'organization_name',
    },
    {
      title: 'Location',
      key: 'location',
      width: 260,
      render: (_, unit) => {
        if (unit.current_latitude == null || unit.current_longitude == null) {
          return (
            <Text type="danger" style={{ fontSize: 13 }}>
              No GPS signal
            </Text>
          );
        }
        return (
          <a
            href={`https://www.openstreetmap.org/?mlat=${unit.current_latitude}&mlon=${unit.current_longitude}&zoom=16`}
            target="_blank"
            rel="noreferrer"
            onClick={(e) => e.stopPropagation()}
            style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: '#475569' }}
          >
            <EnvironmentOutlined style={{ color: '#94a3b8' }} />
            {unit.current_latitude.toFixed(4)}, {unit.current_longitude.toFixed(4)}
          </a>
        );
      },
    },
    {
      title: 'Last Update',
      key: 'last_update',
      width: 160,
      render: (_, unit) => {
        const stale = unit.last_location_update && dayjsDiffMinutes(unit.last_location_update) > STALE_MINUTES;
        return (
          <Text type={stale ? 'danger' : 'secondary'} style={{ fontSize: 13 }}>
            {formatRelative(unit.last_location_update)}
          </Text>
        );
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 170,
      render: (_, unit) => (
        <Select
          style={{ width: 150 }}
          value={unit.status}
          loading={statusUpdatingId === unit.id}
          options={STATUS_OPTIONS}
          onClick={(e) => e.stopPropagation()}
          onChange={(value) => handleStatusChange(unit, value)}
        />
      ),
    },
  ];

  return (
    <div>
      <Title level={3} style={{ marginBottom: 16 }}>
        Field Units
      </Title>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
        <StatCard title="Total Units" value={stats.total} icon={<TeamOutlined />} color={COLORS.primaryBlue} />
        <StatCard
          title="Available"
          value={stats.available}
          icon={<CarOutlined />}
          color={COLORS.unitStatus.available}
        />
        <StatCard title="Busy" value={stats.busy} icon={<CarOutlined />} color={COLORS.unitStatus.busy} />
        <StatCard
          title="Out of Service"
          value={stats.out_of_service}
          icon={<WarningOutlined />}
          color={COLORS.unitStatus.out_of_service}
        />
      </div>

      {selectedUnit && (
        <div
          className="fade-in"
          style={{
            background: '#fff',
            borderRadius: 8,
            boxShadow: 'var(--card-shadow)',
            padding: 20,
            marginBottom: 16,
            position: 'relative',
          }}
        >
          <CloseOutlined
            style={{ position: 'absolute', top: 16, right: 16, cursor: 'pointer', color: '#94a3b8' }}
            onClick={() => setSelectedUnitId(null)}
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1.4fr', gap: 32 }}>
            <div>
              <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 6 }}>UNIT</div>
              <Text strong style={{ fontSize: 24, fontFamily: 'monospace', display: 'block' }}>
                {selectedUnit.call_sign}
              </Text>
              <div style={{ color: '#64748B', fontSize: 13, marginTop: 6 }}>
                {selectedUnit.unit_type_name} · {selectedUnit.organization_name}
              </div>
              <Tag color={COLORS.unitStatus[selectedUnit.status]} style={{ marginTop: 10 }}>
                {UNIT_STATUS_LABELS[selectedUnit.status] ?? selectedUnit.status}
              </Tag>
            </div>

            <div>
              <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 6 }}>LOCATION</div>
              {selectedUnit.current_latitude != null ? (
                <>
                  <Text strong style={{ fontSize: 14 }}>
                    {selectedUnit.current_latitude.toFixed(4)}, {selectedUnit.current_longitude.toFixed(4)}
                  </Text>
                  <div style={{ marginTop: 4 }}>
                    <a
                      href={`https://www.openstreetmap.org/?mlat=${selectedUnit.current_latitude}&mlon=${selectedUnit.current_longitude}&zoom=16`}
                      target="_blank"
                      rel="noreferrer"
                    >
                      View on OpenStreetMap
                    </a>
                  </div>
                </>
              ) : (
                <Text type="danger" strong>
                  No GPS signal
                </Text>
              )}
              <div style={{ color: '#94a3b8', marginTop: 8, fontSize: 12 }}>
                Updated {formatDate(selectedUnit.last_location_update)}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 6 }}>RECENT ASSIGNMENTS</div>
              {!loadingHistory && history.length === 0 && (
                <div style={{ color: '#94a3b8', fontSize: 13 }}>No completed assignments yet.</div>
              )}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {history.map((a) => (
                  <div
                    key={a.id}
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      fontSize: 13,
                      borderBottom: `1px solid ${COLORS.border}`,
                      paddingBottom: 6,
                    }}
                  >
                    <Text strong>{REPORT_TYPE_LABELS[a.cluster_report_type] ?? a.cluster_report_type}</Text>
                    <span style={{ color: '#94a3b8' }}>{formatDate(a.completed_at)}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {unitsLoading && units.length === 0 ? (
        <div style={{ background: '#fff', borderRadius: 8, boxShadow: 'var(--card-shadow)', padding: 20 }}>
          <Skeleton active paragraph={{ rows: 8 }} />
        </div>
      ) : (
        <div className="fade-in">
          <Table
            className="clickable-table"
            columns={columns}
            dataSource={units}
            rowKey="id"
            pagination={false}
            onRow={(unit) => ({ onClick: () => setSelectedUnitId(unit.id) })}
            rowClassName={(unit) => (unit.id === selectedUnitId ? 'row-selected' : '')}
          />
        </div>
      )}
    </div>
  );
}

function dayjsDiffMinutes(isoString) {
  return (Date.now() - new Date(isoString).getTime()) / 60000;
}
