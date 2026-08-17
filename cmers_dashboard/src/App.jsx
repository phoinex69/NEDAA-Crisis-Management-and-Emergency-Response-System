import { StyleProvider } from '@ant-design/cssinjs';
import { App as AntApp, ConfigProvider, Spin } from 'antd';
import arEG from 'antd/locale/ar_EG';
import enUS from 'antd/locale/en_US';
import { lazy, Suspense, useEffect } from 'react';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import AppLayout from './components/layout/AppLayout';
import PrivateRoute from './components/layout/PrivateRoute';
import AppLoadingScreen from './components/common/AppLoadingScreen';
import ErrorBoundary from './components/common/ErrorBoundary';
import { useTranslation } from './hooks/useTranslation';
import { useAuthStore } from './store/authStore';
import { ANT_THEME } from './theme';

import DashboardPage from './pages/DashboardPage';
import DispatchPage from './pages/DispatchPage';
import IncidentDetailPage from './pages/IncidentDetailPage';
import IncidentsPage from './pages/IncidentsPage';
import LoginPage from './pages/LoginPage';
import NotFoundPage from './pages/NotFoundPage';
import NotificationsPage from './pages/NotificationsPage';
import UnitsPage from './pages/UnitsPage';

// Lazy-loaded: these are the heaviest pages (charts, audit tables, settings
// forms) and are not needed on the first paint after login, so keeping them
// out of the main bundle makes the initial dashboard load feel instant.
const AnalyticsPage = lazy(() => import('./pages/AnalyticsPage'));
const AuditPage = lazy(() => import('./pages/AuditPage'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));

function PageLoadingFallback() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: '80px 0' }}>
      <Spin size="large" />
    </div>
  );
}

function AppRoutes() {
  const isInitializing = useAuthStore((state) => state.isInitializing);
  const loadFromStorage = useAuthStore((state) => state.loadFromStorage);

  useEffect(() => {
    loadFromStorage();
  }, [loadFromStorage]);

  // Avoids a flash of the login page for already-authenticated operators
  // while we hydrate account info from localStorage.
  if (isInitializing) {
    return <AppLoadingScreen />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/*"
          element={
            <PrivateRoute>
              <AppLayout />
            </PrivateRoute>
          }
        >
          <Route index element={<DashboardPage />} />
          <Route path="incidents" element={<IncidentsPage />} />
          <Route path="incidents/:id" element={<IncidentDetailPage />} />
          <Route path="dispatch" element={<DispatchPage />} />
          <Route path="units" element={<UnitsPage />} />
          <Route
            path="analytics"
            element={
              <Suspense fallback={<PageLoadingFallback />}>
                <AnalyticsPage />
              </Suspense>
            }
          />
          <Route path="notifications" element={<NotificationsPage />} />
          <Route
            path="audit"
            element={
              <Suspense fallback={<PageLoadingFallback />}>
                <AuditPage />
              </Suspense>
            }
          />
          <Route
            path="settings"
            element={
              <Suspense fallback={<PageLoadingFallback />}>
                <SettingsPage />
              </Suspense>
            }
          />
        </Route>
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}

export default function App() {
  const { language, isRTL } = useTranslation();

  useEffect(() => {
    document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
    document.documentElement.lang = language;
  }, [language, isRTL]);

  return (
    <StyleProvider hashPriority="high">
      <ConfigProvider
        theme={ANT_THEME}
        direction={isRTL ? 'rtl' : 'ltr'}
        locale={isRTL ? arEG : enUS}
      >
        <AntApp>
          <ErrorBoundary>
            <AppRoutes />
          </ErrorBoundary>
        </AntApp>
      </ConfigProvider>
    </StyleProvider>
  );
}
