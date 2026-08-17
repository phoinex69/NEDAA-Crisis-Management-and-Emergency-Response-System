import { BellOutlined } from '@ant-design/icons';
import { App, Badge, Tag } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useRef, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { submitRandomDemoReport } from '../../api/demoMode';
import { useAuth } from '../../hooks/useAuth';
import { useTranslation } from '../../hooks/useTranslation';
import { COLORS } from '../../theme';
import { getRoleTagColor } from '../../utils/constants';

const DEMO_INTERVAL_MS = 30000;

function pageTitleKey(pathname) {
  const keys = {
    '/': 'dashboard',
    '/incidents': 'incidents',
    '/dispatch': 'dispatchNav',
    '/units': 'units',
    '/analytics': 'analytics',
    '/notifications': 'notifications',
    '/audit': 'audit',
    '/settings': 'settings',
  };
  if (keys[pathname]) return keys[pathname];
  const match = Object.keys(keys).find((key) => key !== '/' && pathname.startsWith(key));
  return match ? keys[match] : null;
}

export default function TopBar({ isConnected }) {
  const location = useLocation();
  const navigate = useNavigate();
  const { account } = useAuth();
  const { t, language, setLanguage } = useTranslation();
  const { notification } = App.useApp();
  const titleKey = pageTitleKey(location.pathname);
  const title = titleKey ? t(titleKey) : 'NEDAA Dashboard';
  const breadcrumb = titleKey ? `Home / ${title}` : 'Home';

  const [now, setNow] = useState(dayjs());
  const [demoMode, setDemoMode] = useState(false);
  const demoIntervalRef = useRef(null);

  useEffect(() => {
    const timer = setInterval(() => setNow(dayjs()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Demo mode is local, session-only state (resets on refresh, which is fine
  // for a defense run). The amber border is rendered directly below as a
  // fixed-position overlay rather than a body-level CSS outline -- outline
  // with a negative offset rendered inconsistently across this layout's
  // nested sticky/flex containers (showed up as a stray amber rectangle
  // instead of framing the whole viewport).
  useEffect(() => {
    if (!demoMode) {
      clearInterval(demoIntervalRef.current);
      return undefined;
    }

    demoIntervalRef.current = setInterval(() => {
      submitRandomDemoReport().catch((err) => {
        notification.warning({
          message: 'Demo submission skipped',
          description: err.response?.status === 429 ? 'Rate limit reached for this hour.' : err.message,
        });
      });
    }, DEMO_INTERVAL_MS);

    return () => clearInterval(demoIntervalRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [demoMode]);

  return (
    <>
      {demoMode && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            border: '3px solid #D97706',
            pointerEvents: 'none',
            zIndex: 2000,
          }}
        />
      )}
      <div
        style={{
          height: 56,
          background: COLORS.headerBg,
          boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 24px',
          position: 'sticky',
          top: 0,
          zIndex: 10,
        }}
      >
      <div>
        <div style={{ fontWeight: 700, fontSize: 18, lineHeight: 1.2 }}>{title}</div>
        <div style={{ fontSize: 12, color: '#94a3b8' }}>{breadcrumb}</div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              background: isConnected ? '#16A34A' : '#DC2626',
              transition: 'background-color 0.3s ease',
              animation: isConnected ? 'pulse-critical 1.8s ease-in-out infinite' : 'none',
            }}
          />
          <span style={{ color: isConnected ? '#16A34A' : '#DC2626' }}>
            {isConnected ? 'Live' : 'Disconnected'}
          </span>
        </div>

        <div style={{ fontSize: 13, color: '#475569', whiteSpace: 'nowrap' }}>
          {now.format('dddd, DD MMM YYYY')}{'  '}
          <span style={{ fontFamily: 'monospace' }}>{now.format('HH:mm:ss')}</span>
        </div>

        {/* Language toggle */}
        <div style={{ display: 'flex', border: `1px solid ${COLORS.border}`, borderRadius: 6, overflow: 'hidden' }}>
          {['en', 'ar'].map((lang) => (
            <button
              key={lang}
              type="button"
              onClick={() => setLanguage(lang)}
              style={{
                border: 'none',
                cursor: 'pointer',
                padding: '5px 12px',
                fontSize: 12,
                fontWeight: 600,
                background: language === lang ? COLORS.primaryNavy : 'transparent',
                color: language === lang ? '#fff' : '#64748B',
              }}
            >
              {lang === 'en' ? t('langEn') : t('langAr')}
            </button>
          ))}
        </div>

        {account?.role_name === 'admin' && (
          <button
            type="button"
            onClick={() => setDemoMode((prev) => !prev)}
            title="Simulate live activity for a defense demo"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              border: `1px solid ${demoMode ? '#D97706' : COLORS.border}`,
              borderRadius: 6,
              cursor: 'pointer',
              padding: '5px 10px',
              fontSize: 12,
              fontWeight: 600,
              background: demoMode ? '#FFFBEB' : 'transparent',
              color: demoMode ? '#D97706' : '#64748B',
            }}
          >
            {demoMode && (
              <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#D97706' }} className="pulse-critical" />
            )}
            {t('demoMode')}
          </button>
        )}

        {demoMode && (
          <Tag color="gold" style={{ fontWeight: 700, letterSpacing: 0.5 }}>
            {t('demo')}
          </Tag>
        )}

        {/* Officials don't have a personal notification inbox (that's citizen-only,
            GET /notifications/unread-count/ always 403s for official accounts) --
            the bell is a shortcut to the broadcast-alerts page. The "!" badge isn't
            an unread count, it's a reminder that the live broadcast system is up
            and ready (mirrors the WebSocket connection state). */}
        <Badge count={isConnected ? '!' : 0} size="small" color={COLORS.credibility.red} offset={[-2, 2]}>
          <BellOutlined
            style={{ fontSize: 18, cursor: 'pointer', color: '#475569' }}
            onClick={() => navigate('/notifications')}
          />
        </Badge>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 13, fontWeight: 500 }}>
            {account?.full_name || account?.email}
          </span>
          <Tag color={getRoleTagColor(account?.role_name)}>
            {account?.role_name ?? 'official'}
          </Tag>
        </div>
      </div>
      </div>
    </>
  );
}
