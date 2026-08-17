import { SafetyCertificateOutlined } from '@ant-design/icons';
import { Spin } from 'antd';
import { COLORS } from '../../theme';

export default function AppLoadingScreen() {
  return (
    <div
      style={{
        height: '100vh',
        width: '100%',
        background: COLORS.sidebarBg,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 16,
      }}
    >
      <SafetyCertificateOutlined style={{ fontSize: 48, color: '#fff' }} />
      <Spin size="large" />
      <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13 }}>Loading NEDAA...</div>
    </div>
  );
}
