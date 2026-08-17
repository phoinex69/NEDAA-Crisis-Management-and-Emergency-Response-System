import { Layout } from 'antd';
import { useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import { useWebSocket } from '../../hooks/useWebSocket';
import { useIncidentStore } from '../../store/incidentStore';
import { useUnitStore } from '../../store/unitStore';
import { COLORS } from '../../theme';
import Sidebar from './Sidebar';
import TopBar from './TopBar';

const { Content } = Layout;

export default function AppLayout() {
  const { isConnected } = useWebSocket();
  const fetchIncidents = useIncidentStore((state) => state.fetchIncidents);
  const fetchUnits = useUnitStore((state) => state.fetchUnits);

  useEffect(() => {
    fetchIncidents().catch(() => {});
    fetchUnits().catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar />
      <Layout>
        <TopBar isConnected={isConnected} />
        <Content
          style={{
            padding: 24,
            background: COLORS.contentBg,
            overflow: 'auto',
          }}
        >
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
