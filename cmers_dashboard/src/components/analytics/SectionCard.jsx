import { Button, Skeleton, Typography } from 'antd';

const { Text } = Typography;

export default function SectionCard({ title, subtitle, loading, error, onRetry, extra, children, style }) {
  return (
    <div
      style={{
        background: '#fff',
        borderRadius: 8,
        boxShadow: 'var(--card-shadow)',
        padding: 20,
        ...style,
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          marginBottom: 16,
        }}
      >
        <div>
          <Text strong style={{ fontSize: 15 }}>
            {title}
          </Text>
          {subtitle && <div style={{ fontSize: 12, color: '#94a3b8', marginTop: 2 }}>{subtitle}</div>}
        </div>
        {extra}
      </div>

      {loading && <Skeleton active paragraph={{ rows: 4 }} />}

      {!loading && error && (
        <div style={{ textAlign: 'center', padding: '24px 0' }}>
          <Text type="danger" style={{ fontSize: 13 }}>
            {error}
          </Text>
          <div style={{ marginTop: 10 }}>
            <Button size="small" onClick={onRetry}>
              Retry
            </Button>
          </div>
        </div>
      )}

      {!loading && !error && children}
    </div>
  );
}
