import { Empty } from 'antd';

export default function EmptyState({ message = 'No data available' }) {
  return (
    <div style={{ padding: '60px 0', display: 'flex', justifyContent: 'center' }}>
      <Empty description={message} />
    </div>
  );
}
