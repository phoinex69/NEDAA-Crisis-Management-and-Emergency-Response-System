import { App, Button, Empty, Form, Input, InputNumber, Pagination, Select, Skeleton, Tag, Typography } from 'antd';
import { useEffect, useRef, useState } from 'react';
import { broadcastAlert, getBroadcastHistory } from '../api/notifications.api';
import { useConnectionStore } from '../store/connectionStore';
import { COLORS } from '../theme';
import { BROADCAST_TYPE_BORDER_COLORS, BROADCAST_TYPE_LABELS, BROADCAST_TYPE_OPTIONS } from '../utils/constants';
import { formatRelative } from '../utils/formatters';

const { Title, Text } = Typography;
const { TextArea } = Input;

const HISTORY_PAGE_SIZE = 20;

const TEMPLATES = [
  {
    key: 'danger',
    name: 'Danger Zone',
    type: 'danger_zone',
    title: 'Danger Zone Active',
    message: 'تحذير: المنطقة خطرة يرجى الابتعاد فوراً',
  },
  {
    key: 'road',
    name: 'Road Closure',
    type: 'road_closure',
    title: 'Road Closure',
    message: 'إغلاق الطريق بسبب عمليات الطوارئ',
  },
  {
    key: 'evac',
    name: 'Evacuation',
    type: 'danger_zone',
    title: 'Evacuation Required',
    message: 'يرجى إخلاء المنطقة فوراً والتوجه لأقرب ملجأ',
  },
  {
    key: 'clear',
    name: 'All Clear',
    type: 'general',
    title: 'All Clear',
    message: 'تم السيطرة على الوضع يمكن العودة للمنطقة بأمان',
  },
];

function BroadcastCard({ item }) {
  const borderColor = BROADCAST_TYPE_BORDER_COLORS[item.type] ?? '#64748B';
  const option = BROADCAST_TYPE_OPTIONS.find((o) => o.value === item.type);
  const hasTarget = item.target_latitude != null && item.target_longitude != null;

  return (
    <div
      className="fade-in"
      style={{
        borderLeft: `4px solid ${borderColor}`,
        border: `1px solid ${COLORS.border}`,
        borderRadius: 8,
        padding: 14,
        marginBottom: 12,
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <Tag color={option?.tagColor}>
          {option?.emoji} {BROADCAST_TYPE_LABELS[item.type] ?? item.type}
        </Tag>
        <Text type="secondary" style={{ fontSize: 12 }}>
          {formatRelative(item.created_at)}
        </Text>
      </div>
      <Text strong>{item.title}</Text>
      <div style={{ color: '#64748B', fontSize: 13, marginTop: 4 }}>{item.message}</div>
      <div style={{ marginTop: 8, fontSize: 12, color: '#94a3b8' }}>
        {hasTarget
          ? `📍 ${item.target_latitude.toFixed(4)}, ${item.target_longitude.toFixed(4)} · ${item.target_radius_km}km radius`
          : '📡 Broadcast to all citizens'}
      </div>
    </div>
  );
}

export default function NotificationsPage() {
  const { notification } = App.useApp();
  const [form] = Form.useForm();
  const formCardRef = useRef(null);
  const isConnected = useConnectionStore((state) => state.isConnected);

  const [submitting, setSubmitting] = useState(false);
  const [history, setHistory] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [historyPage, setHistoryPage] = useState(1);

  const latValue = Form.useWatch('target_latitude', form);
  const lngValue = Form.useWatch('target_longitude', form);

  function loadHistory() {
    setHistoryLoading(true);
    getBroadcastHistory({ page_size: 100 })
      .then((data) => setHistory(data.results ?? (Array.isArray(data) ? data : [])))
      .catch(() => {})
      .finally(() => setHistoryLoading(false));
  }

  useEffect(loadHistory, []);

  function handleSubmit(values) {
    setSubmitting(true);
    broadcastAlert({
      type: values.type,
      title: values.title,
      message: values.message,
      target_latitude: values.target_latitude ?? null,
      target_longitude: values.target_longitude ?? null,
      target_radius_km: values.target_radius_km ?? undefined,
    })
      .then((res) => {
        notification.success({ message: `Alert sent to ${res.citizens_notified} citizens` });
        form.resetFields();
        setHistoryPage(1);
        loadHistory();
      })
      .catch((err) => notification.error({ message: 'Broadcast failed', description: err.message }))
      .finally(() => setSubmitting(false));
  }

  function applyTemplate(template) {
    form.setFieldsValue({ type: template.type, title: template.title, message: template.message });
    formCardRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  const pagedHistory = history.slice((historyPage - 1) * HISTORY_PAGE_SIZE, historyPage * HISTORY_PAGE_SIZE);

  return (
    <div>
      {/* WebSocket status bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          background: '#fff',
          borderRadius: 8,
          padding: '12px 20px',
          marginBottom: 20,
          boxShadow: 'var(--card-shadow)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
          <span
            className={isConnected ? 'pulse-critical' : ''}
            style={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              background: isConnected ? COLORS.credibility.green : COLORS.credibility.red,
              flexShrink: 0,
            }}
          />
          <span style={{ color: isConnected ? COLORS.credibility.green : COLORS.credibility.red }}>
            {isConnected
              ? 'WebSocket active — alerts will be pushed to connected citizens instantly'
              : 'WebSocket disconnected — alerts will still be sent via the API'}
          </span>
        </div>
        <Text type="secondary" style={{ fontSize: 12 }}>
          Alerts broadcast to all connected mobile users
        </Text>
      </div>

      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        {/* Left column -- form + templates */}
        <div style={{ flex: '0 0 40%', minWidth: 0 }}>
          <div
            ref={formCardRef}
            style={{
              background: '#fff',
              borderLeft: '4px solid #DC2626',
              borderRadius: 8,
              boxShadow: 'var(--card-shadow)',
              padding: 20,
              marginBottom: 20,
            }}
          >
            <Title level={4} style={{ marginBottom: 0 }}>
              Send Emergency Alert
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Broadcast to citizens in a geographic area
            </Text>

            <Form form={form} layout="vertical" onFinish={handleSubmit} style={{ marginTop: 16 }} requiredMark={false}>
              <Form.Item name="type" label="Alert Type" rules={[{ required: true, message: 'Alert type is required' }]}>
                <Select
                  placeholder="Select alert type"
                  options={BROADCAST_TYPE_OPTIONS.map((o) => ({ value: o.value, label: `${o.emoji} ${o.label}` }))}
                />
              </Form.Item>

              <Form.Item name="title" label="Title" rules={[{ required: true, message: 'Title is required' }]}>
                <Input placeholder="Alert title (shown to citizens)" maxLength={255} showCount />
              </Form.Item>

              <Form.Item name="message" label="Message" rules={[{ required: true, message: 'Message is required' }]}>
                <TextArea placeholder="Alert message in Arabic or English..." rows={4} maxLength={500} showCount />
              </Form.Item>

              <div style={{ marginBottom: 8 }}>
                <Text strong style={{ fontSize: 13 }}>
                  Target Area (optional)
                </Text>
                <div style={{ fontSize: 12, color: '#94a3b8' }}>
                  Leave empty to broadcast to all connected citizens
                </div>
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
                <Form.Item name="target_latitude" label="Latitude" style={{ flex: 1 }}>
                  <InputNumber placeholder="33.5138" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="target_longitude" label="Longitude" style={{ flex: 1 }}>
                  <InputNumber placeholder="36.2765" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="target_radius_km" label="Radius km" style={{ flex: 1 }}>
                  <InputNumber placeholder="5.0" min={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </div>

              {latValue != null && lngValue != null && (
                <a
                  href={`https://www.openstreetmap.org/?mlat=${latValue}&mlon=${lngValue}&zoom=14`}
                  target="_blank"
                  rel="noreferrer"
                  style={{ fontSize: 12, display: 'block', marginBottom: 12 }}
                >
                  Preview area on map →
                </a>
              )}

              <Button
                type="primary"
                htmlType="submit"
                block
                loading={submitting}
                style={{ height: 44, background: '#DC2626', borderColor: '#DC2626', fontWeight: 700, marginTop: 8 }}
              >
                🔔 Send Alert to Citizens
              </Button>
            </Form>
          </div>

          <div
            style={{
              background: '#fff',
              borderRadius: 8,
              boxShadow: 'var(--card-shadow)',
              padding: 20,
            }}
          >
            <Title level={5} style={{ marginBottom: 0 }}>
              Quick Templates
            </Title>
            <Text type="secondary" style={{ fontSize: 12 }}>
              Click to pre-fill the form
            </Text>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 12, minWidth: 0 }}>
              {TEMPLATES.map((template) => (
                <div
                  key={template.key}
                  onClick={() => applyTemplate(template)}
                  style={{
                    border: `1px solid ${COLORS.border}`,
                    borderRadius: 8,
                    padding: 12,
                    cursor: 'pointer',
                    minWidth: 0,
                    overflow: 'hidden',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  <Text strong style={{ fontSize: 13 }}>
                    {template.name}
                  </Text>
                  <div
                    style={{
                      fontSize: 11,
                      color: '#94a3b8',
                      marginTop: 4,
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {template.message}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right column -- history */}
        <div style={{ flex: '0 0 60%', minWidth: 0 }}>
          <div style={{ background: '#fff', borderRadius: 8, boxShadow: 'var(--card-shadow)', padding: 20 }}>
            <Title level={4} style={{ marginBottom: 0 }}>
              Broadcast History
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Recent alerts sent to citizens
            </Text>

            <div style={{ marginTop: 16 }}>
              {historyLoading ? (
                <Skeleton active paragraph={{ rows: 4 }} />
              ) : history.length === 0 ? (
                <Empty description="No alerts have been sent yet." />
              ) : (
                <>
                  {pagedHistory.map((item) => (
                    <BroadcastCard key={item.id} item={item} />
                  ))}
                  {history.length > HISTORY_PAGE_SIZE && (
                    <Pagination
                      current={historyPage}
                      pageSize={HISTORY_PAGE_SIZE}
                      total={history.length}
                      onChange={setHistoryPage}
                      style={{ marginTop: 16, textAlign: 'center' }}
                    />
                  )}
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
