import { Drawer, Spin, Tabs } from 'antd';
import { useEffect, useState } from 'react';
import { getIncident } from '../../api/incidents.api';
import { useIncidentStore } from '../../store/incidentStore';
import { REPORT_TYPE_LABELS } from '../../utils/constants';
import CloseIncidentTab from './CloseIncidentTab';
import DispatchTab from './DispatchTab';
import OverviewTab from './OverviewTab';
import ReportsTab from './ReportsTab';

const CLOSEABLE_STATUSES = ['assigned', 'in_progress'];

export default function IncidentDetailDrawer({ incidentId, open, onClose }) {
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('overview');

  const lastDispatchEvent = useIncidentStore((state) => state.lastDispatchEvent);
  const addOrUpdateIncident = useIncidentStore((state) => state.addOrUpdateIncident);

  function refetch() {
    if (!incidentId) return;
    setLoading(true);
    getIncident(incidentId)
      .then(setDetail)
      .catch(() => {})
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    if (open && incidentId) {
      setActiveTab('overview');
      refetch();
    }
    if (!open) {
      setDetail(null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, incidentId]);

  // Live-refresh the drawer's detail (latest_assignment, status, etc.) if a
  // dispatch.updated event arrives for the incident currently being viewed.
  useEffect(() => {
    if (open && lastDispatchEvent?.cluster_id === incidentId) {
      refetch();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lastDispatchEvent]);

  function handleIncidentChanged(updated) {
    setDetail(updated);
    addOrUpdateIncident(updated);
  }

  const canClose = detail && CLOSEABLE_STATUSES.includes(detail.status);

  const items = [
    {
      key: 'overview',
      label: 'Overview',
      children: detail ? <OverviewTab incident={detail} /> : null,
    },
    {
      key: 'reports',
      label: 'Reports',
      children: detail ? (
        <ReportsTab
          incidentId={detail.id}
          predictedSeverity={detail.predicted_severity ?? detail.actual_severity}
        />
      ) : null,
    },
    {
      key: 'dispatch',
      label: 'Dispatch',
      children: detail ? (
        <DispatchTab incident={detail} onDispatchAction={refetch} />
      ) : null,
    },
    ...(canClose
      ? [
          {
            key: 'close',
            label: 'Close Incident',
            children: (
              <CloseIncidentTab
                incident={detail}
                onClosed={(updated) => {
                  handleIncidentChanged(updated);
                  onClose();
                }}
              />
            ),
          },
        ]
      : []),
  ];

  return (
    <Drawer
      title={
        detail
          ? `${REPORT_TYPE_LABELS[detail.report_type] ?? detail.report_type ?? 'Incident'} · #${detail.id.slice(0, 8)}`
          : 'Incident'
      }
      width={580}
      open={open}
      onClose={onClose}
      destroyOnHidden
    >
      {loading && !detail ? (
        <div style={{ textAlign: 'center', padding: 60 }}>
          <Spin size="large" />
        </div>
      ) : (
        <Tabs activeKey={activeTab} onChange={setActiveTab} items={items} />
      )}
    </Drawer>
  );
}
