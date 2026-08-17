import { Button, Typography } from 'antd';
import { useNavigate } from 'react-router-dom';
import { COLORS } from '../theme';

const { Text } = Typography;

export default function NotFoundPage() {
  const navigate = useNavigate();

  return (
    <div
      style={{
        height: '100vh',
        width: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        padding: 24,
        background: COLORS.contentBg,
      }}
    >
      <div style={{ fontSize: 96, fontWeight: 800, color: COLORS.primaryNavy, lineHeight: 1 }}>404</div>
      <div style={{ fontSize: 22, fontWeight: 700, color: '#1E293B', marginTop: 8 }}>Page not found</div>
      <Text type="secondary" style={{ fontSize: 14, maxWidth: 420, marginTop: 8, display: 'block' }}>
        The page you are looking for does not exist or you do not have permission to access it.
      </Text>
      <Button
        type="primary"
        size="large"
        onClick={() => navigate('/')}
        style={{ marginTop: 24, height: 40, background: COLORS.primaryNavy, borderColor: COLORS.primaryNavy }}
      >
        Back to Dashboard
      </Button>
    </div>
  );
}
