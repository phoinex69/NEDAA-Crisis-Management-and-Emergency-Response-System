import { ArrowDownOutlined, ArrowUpOutlined } from '@ant-design/icons';
import { Card } from 'antd';
import { memo } from 'react';
import { COLORS } from '../../theme';

function StatCard({
  title,
  value,
  icon,
  color = COLORS.primaryBlue,
  trend,
  suffix,
  background,
  valueColor,
}) {
  const trendUp = typeof trend === 'number' && trend >= 0;

  return (
    <Card
      styles={{ body: { padding: '18px 20px' } }}
      style={{
        borderLeft: `4px solid ${color}`,
        boxShadow: 'var(--card-shadow)',
        borderRadius: 8,
        background,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 12, color: '#64748B', marginBottom: 6 }}>{title}</div>
          <div style={{ fontSize: 26, fontWeight: 700, color: valueColor ?? '#1E293B', lineHeight: 1.2 }}>
            {value}
            {suffix && (
              <span style={{ fontSize: 13, fontWeight: 400, color: '#94a3b8', marginLeft: 4 }}>
                {suffix}
              </span>
            )}
          </div>
          {typeof trend === 'number' && (
            <div
              style={{
                marginTop: 6,
                fontSize: 12,
                color: trendUp ? COLORS.credibility.green : COLORS.credibility.red,
                display: 'flex',
                alignItems: 'center',
                gap: 4,
              }}
            >
              {trendUp ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
              {Math.abs(trend)}%
            </div>
          )}
        </div>
        {icon && (
          <div style={{ fontSize: 28, color, opacity: 0.85 }}>{icon}</div>
        )}
      </div>
    </Card>
  );
}

export default memo(StatCard);
