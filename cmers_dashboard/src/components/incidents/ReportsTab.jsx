import { AlertOutlined, AudioOutlined, EyeOutlined, FormOutlined } from '@ant-design/icons';
import { Empty, Tag, Typography } from 'antd';
import { useEffect, useState } from 'react';
import { getIncidentReports } from '../../api/incidents.api';
import LoadingSpinner from '../common/LoadingSpinner';
import { COLORS } from '../../theme';
import { formatDate, getSeverityLabel } from '../../utils/formatters';

const { Text } = Typography;

const SUBMISSION_ICONS = {
  form: FormOutlined,
  sos: AlertOutlined,
  voice: AudioOutlined,
  witness: EyeOutlined,
};

export default function ReportsTab({ incidentId, predictedSeverity }) {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getIncidentReports(incidentId)
      .then((data) => setReports(data.results ?? (Array.isArray(data) ? data : [])))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [incidentId]);

  if (loading) return <LoadingSpinner text="Loading reports..." />;
  if (reports.length === 0) return <Empty description="No reports in this cluster." />;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {reports.map((report) => {
        const Icon = SUBMISSION_ICONS[report.submission_method] ?? FormOutlined;
        const isSos = report.submission_method === 'sos';

        return (
          <div
            key={report.id}
            style={{
              border: `1px solid ${COLORS.border}`,
              borderRadius: 8,
              padding: 12,
              background: isSos ? '#FEF2F2' : '#fff',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Icon style={{ color: '#64748B' }} />
                <Text type="secondary" style={{ fontSize: 12, textTransform: 'capitalize' }}>
                  {report.submission_method}
                </Text>
                {isSos && <Tag color="red">SOS</Tag>}
              </div>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {formatDate(report.created_at)}
              </Text>
            </div>

            <div style={{ marginTop: 8 }}>
              {report.description || <Text type="secondary">No description provided.</Text>}
            </div>

            <div style={{ marginTop: 10, display: 'flex', gap: 24, fontSize: 12 }}>
              <div>
                <div style={{ color: '#94a3b8' }}>Citizen-reported severity</div>
                <Text strong>{getSeverityLabel(report.reported_severity)}</Text>
              </div>
              <div>
                {/* AI severity is computed per-cluster, not per-report, so every
                    report in this list shows the same current cluster-level value. */}
                <div style={{ color: '#94a3b8' }}>AI-predicted severity</div>
                <Text strong style={{ color: COLORS.severity[predictedSeverity] }}>
                  {predictedSeverity != null ? getSeverityLabel(predictedSeverity) : 'N/A'}
                </Text>
              </div>
              <div>
                <div style={{ color: '#94a3b8' }}>Victims</div>
                <Text strong>{report.victims_count}</Text>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
