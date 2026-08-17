import { memo } from 'react';
import { COLORS } from '../../theme';
import { getSeverityLabel } from '../../utils/formatters';

function SeverityBadge({ level, lang = 'en' }) {
  const color = COLORS.severity[level] ?? '#64748B';

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        padding: '2px 10px',
        borderRadius: 999,
        background: '#F8FAFC',
        border: `1px solid ${COLORS.border}`,
        fontSize: 12,
      }}
    >
      <span style={{ width: 8, height: 8, borderRadius: '50%', background: color }} />
      <strong style={{ color }}>{getSeverityLabel(level, lang)}</strong>
    </span>
  );
}

export default memo(SeverityBadge);
