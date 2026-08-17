import { SafetyCertificateOutlined } from '@ant-design/icons';
import { Button } from 'antd';
import { Component } from 'react';
import { COLORS } from '../../theme';

export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    // eslint-disable-next-line no-console
    console.error('Unhandled error caught by ErrorBoundary:', error, info);
  }

  render() {
    if (!this.state.error) return this.props.children;

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
          textAlign: 'center',
          padding: 24,
        }}
      >
        <SafetyCertificateOutlined style={{ fontSize: 56, color: '#fff' }} />
        <div style={{ color: '#fff', fontSize: 28, fontWeight: 700 }}>Something went wrong</div>
        <div style={{ color: 'rgba(255,255,255,0.6)', fontSize: 14, maxWidth: 480 }}>
          {this.state.error.message || 'An unexpected error occurred.'}
        </div>
        <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
          <Button
            size="large"
            onClick={() => window.location.reload()}
            style={{ height: 40 }}
          >
            Reload Page
          </Button>
          <Button
            type="primary"
            size="large"
            onClick={() => {
              this.setState({ error: null });
              window.location.href = '/';
            }}
            style={{ height: 40, background: COLORS.primaryBlue, borderColor: COLORS.primaryBlue }}
          >
            Go to Dashboard
          </Button>
        </div>
      </div>
    );
  }
}
