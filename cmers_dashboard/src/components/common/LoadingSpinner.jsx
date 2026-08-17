import { Spin } from 'antd';

export default function LoadingSpinner({ text = 'Loading data...' }) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '60px 0',
        gap: 12,
      }}
    >
      <Spin size="large" />
      <div style={{ color: '#94a3b8', fontSize: 13 }}>{text}</div>
    </div>
  );
}
