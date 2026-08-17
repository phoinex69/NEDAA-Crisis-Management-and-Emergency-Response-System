import {
  LockOutlined,
  MailOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import { Alert, Button, Divider, Form, Input, Typography } from 'antd';
import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { COLORS } from '../theme';
import { isLoggedIn } from '../utils/tokenManager';

const { Title, Text } = Typography;

const STATUS_PILLS = [
  'System Online',
  'AI Pipeline Active',
  '5 Units Available',
];

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, isLoading } = useAuth();
  const [form] = Form.useForm();
  const [errorMessage, setErrorMessage] = useState(null);

  // Already-authenticated operators shouldn't see the login form again
  // (e.g. hitting Back after a successful login).
  if (isLoggedIn()) {
    return <Navigate to="/" replace />;
  }

  async function handleSubmit(values) {
    setErrorMessage(null);
    try {
      await login(values.email, values.password);
      navigate('/', { replace: true });
    } catch (err) {
      setErrorMessage(err.message);
      form.setFieldValue('password', '');
    }
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', width: '100%' }}>
      {/* LEFT — branding */}
      <div
        style={{
          flex: '0 0 40%',
          background: COLORS.sidebarBg,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '64px 40px',
        }}
      >
        <div />

        <div style={{ textAlign: 'center' }}>
          <SafetyCertificateOutlined style={{ fontSize: 48, color: '#fff' }} />
          <div style={{ color: '#fff', fontSize: 32, fontWeight: 700, marginTop: 16 }}>
            NEDAA
          </div>
          <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 13, marginTop: 6 }}>
            Crisis Management &amp; Emergency Response System
          </div>

          <div
            style={{
              marginTop: 40,
              display: 'flex',
              flexDirection: 'column',
              gap: 10,
              alignItems: 'stretch',
            }}
          >
            {STATUS_PILLS.map((label) => (
              <div
                key={label}
                style={{
                  background: COLORS.sidebarHover,
                  borderRadius: 999,
                  padding: '8px 18px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  fontSize: 13,
                  color: '#fff',
                }}
              >
                <span
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    background: COLORS.credibility.green,
                    flexShrink: 0,
                  }}
                />
                {label}
              </div>
            ))}
          </div>
        </div>

        <div style={{ textAlign: 'center' }}>
          <div
            style={{
              color: '#D97706',
              fontSize: 13,
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 6,
            }}
          >
            <LockOutlined />
            Authorized personnel only
          </div>
          <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11, marginTop: 6 }}>
            All access is monitored and logged
          </div>
        </div>
      </div>

      {/* RIGHT — login form */}
      <div
        style={{
          flex: '0 0 60%',
          background: COLORS.contentBg,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 24,
        }}
      >
        <div
          style={{
            background: '#fff',
            borderRadius: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)',
            padding: 48,
            width: '100%',
            maxWidth: 440,
          }}
        >
          <Text type="secondary" style={{ fontSize: 13 }}>
            Welcome back
          </Text>
          <Title level={3} style={{ marginTop: 4, marginBottom: 28 }}>
            Sign in to your account
          </Title>

          <Form
            form={form}
            layout="vertical"
            onFinish={handleSubmit}
            requiredMark={false}
          >
            <Form.Item
              label="Email address"
              name="email"
              rules={[
                { required: true, message: 'Email is required' },
                { type: 'email', message: 'Enter a valid email address' },
              ]}
            >
              <Input
                prefix={<MailOutlined style={{ color: '#94a3b8' }} />}
                placeholder="operator@cmers.gov"
                size="large"
                autoComplete="username"
              />
            </Form.Item>

            <Form.Item
              label="Password"
              name="password"
              rules={[
                { required: true, message: 'Password is required' },
                { min: 8, message: 'Password must be at least 8 characters' },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#94a3b8' }} />}
                size="large"
                autoComplete="current-password"
              />
            </Form.Item>

            {errorMessage && (
              <Alert
                type="error"
                message={errorMessage}
                showIcon
                closable={false}
                style={{ marginBottom: 20 }}
              />
            )}

            <Form.Item style={{ marginBottom: 0 }}>
              <Button
                type="primary"
                htmlType="submit"
                block
                loading={isLoading}
                style={{
                  height: 44,
                  background: COLORS.primaryNavy,
                  fontWeight: 600,
                }}
              >
                {isLoading ? 'Signing in...' : 'Sign In'}
              </Button>
            </Form.Item>
          </Form>

          <Divider style={{ margin: '28px 0 16px' }} />
          <Text type="secondary" style={{ display: 'block', textAlign: 'center', fontSize: 12 }}>
            NEDAA v1.0 &nbsp;·&nbsp; Secured connection
          </Text>
        </div>
      </div>
    </div>
  );
}
