import {
  AlertOutlined,
  AuditOutlined,
  BarChartOutlined,
  BellOutlined,
  CarOutlined,
  DashboardOutlined,
  LogoutOutlined,
  SafetyCertificateOutlined,
  SettingOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { Avatar, Badge, Layout, Menu, Tag } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { getBroadcastHistory } from '../../api/notifications.api';
import { useAuth } from '../../hooks/useAuth';
import { useTranslation } from '../../hooks/useTranslation';
import { COLORS } from '../../theme';
import { getRoleTagColor } from '../../utils/constants';

const { Sider } = Layout;

function buildNavItems(t) {
  return [
    { key: '/', icon: <DashboardOutlined />, label: t('dashboard') },
    { key: '/incidents', icon: <AlertOutlined />, label: t('incidents') },
    { key: '/dispatch', icon: <CarOutlined />, label: t('dispatchNav') },
    { key: '/units', icon: <TeamOutlined />, label: t('units') },
    { key: '/analytics', icon: <BarChartOutlined />, label: t('analytics') },
    { key: '/notifications', icon: <BellOutlined />, label: t('notifications') },
    { key: '/audit', icon: <AuditOutlined />, label: t('audit') },
    { key: '/settings', icon: <SettingOutlined />, label: t('settings') },
  ];
}

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const [broadcastsToday, setBroadcastsToday] = useState(0);
  const navigate = useNavigate();
  const location = useLocation();
  const { account, logout } = useAuth();
  const { t } = useTranslation();
  const NAV_ITEMS = buildNavItems(t);

  useEffect(() => {
    // Not /audit/logs/ (IsAdmin-only -- an operator account would 403) --
    // reuses the same officials-facing broadcast-history endpoint the
    // Notifications page uses, which any official can read.
    const today = dayjs().format('YYYY-MM-DD');
    getBroadcastHistory({ date_from: today, date_to: today, page_size: 1 })
      .then((data) => setBroadcastsToday(data.count ?? 0))
      .catch(() => setBroadcastsToday(0));
  }, []);

  const selectedKey =
    NAV_ITEMS.find(
      (item) => item.key !== '/' && location.pathname.startsWith(item.key)
    )?.key ?? '/';

  const displayName = account?.full_name || account?.email || 'Official';
  const initial = displayName.charAt(0).toUpperCase();

  const menuItems = NAV_ITEMS.map((item) => {
    if (item.key === '/notifications' && broadcastsToday > 0 && !collapsed) {
      return {
        ...item,
        label: (
          <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
            {item.label}
            <Badge count={broadcastsToday} size="small" color={COLORS.primaryBlue} />
          </span>
        ),
      };
    }
    if (item.key === '/settings' && account?.role_name === 'admin' && !collapsed) {
      return {
        ...item,
        label: (
          <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
            {item.label}
            <Tag color="red" style={{ fontSize: 10, lineHeight: '16px', padding: '0 6px', marginRight: 0 }}>
              ADMIN
            </Tag>
          </span>
        ),
      };
    }
    return item;
  });

  return (
    <Sider
      collapsible
      collapsed={collapsed}
      onCollapse={setCollapsed}
      width={240}
      collapsedWidth={64}
      className="cmers-sidebar"
      style={{
        background: COLORS.sidebarBg,
        display: 'flex',
        flexDirection: 'column',
        height: '100vh',
        position: 'sticky',
        top: 0,
        left: 0,
      }}
    >
      <div
        style={{
          padding: collapsed ? '20px 12px' : '20px 20px',
          borderBottom: '1px solid rgba(255,255,255,0.1)',
          display: 'flex',
          alignItems: 'center',
          gap: 10,
        }}
      >
        <SafetyCertificateOutlined style={{ fontSize: 26, color: COLORS.primaryBlue }} />
        {!collapsed && (
          <div>
            <div style={{ color: '#fff', fontWeight: 700, fontSize: 16, lineHeight: 1.2 }}>
              NEDAA
            </div>
            <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11 }}>
              Emergency Response
            </div>
          </div>
        )}
      </div>

      <Menu
        theme="dark"
        mode="inline"
        selectedKeys={[selectedKey]}
        items={menuItems}
        onClick={({ key }) => navigate(key)}
        style={{ flex: 1, background: 'transparent', paddingTop: 8 }}
      />

      <div
        style={{
          borderTop: '1px solid rgba(255,255,255,0.1)',
          padding: collapsed ? '16px 12px' : '16px 20px',
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Avatar style={{ backgroundColor: COLORS.primaryBlue, flexShrink: 0 }}>
            {initial}
          </Avatar>
          {!collapsed && (
            <div style={{ overflow: 'hidden' }}>
              <div
                style={{
                  color: '#fff',
                  fontSize: 13,
                  fontWeight: 600,
                  whiteSpace: 'nowrap',
                  textOverflow: 'ellipsis',
                  overflow: 'hidden',
                }}
              >
                {displayName}
              </div>
              {account?.organization_name && (
                <div
                  style={{
                    color: 'rgba(255,255,255,0.45)',
                    fontSize: 11,
                    whiteSpace: 'nowrap',
                    textOverflow: 'ellipsis',
                    overflow: 'hidden',
                  }}
                >
                  {account.organization_name}
                </div>
              )}
              <Tag
                color={getRoleTagColor(account?.role_name)}
                style={{ marginTop: 2, fontSize: 10, lineHeight: '16px', padding: '0 6px' }}
              >
                {account?.role_name ?? 'official'}
              </Tag>
            </div>
          )}
        </div>
        <div
          onClick={logout}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            color: 'rgba(255,255,255,0.65)',
            cursor: 'pointer',
            fontSize: 13,
            padding: '6px 0',
          }}
        >
          <LogoutOutlined />
          {!collapsed && <span>{t('logout')}</span>}
        </div>
      </div>
    </Sider>
  );
}
