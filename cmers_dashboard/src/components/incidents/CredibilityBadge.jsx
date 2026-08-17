import { memo } from 'react';
import { COLORS } from '../../theme';
import { CREDIBILITY_LABELS } from '../../utils/constants';

const BAND_KEY = { green: 'green', yellow: 'yellow', red: 'red' };

function CredibilityBadge({ band, percent }) {
  const key = BAND_KEY[band] ?? 'yellow';
  const color = COLORS.credibility[key];
  const bg = COLORS.credibility[`${key}Bg`];

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        padding: '2px 10px',
        borderRadius: 999,
        background: bg,
        color,
        fontSize: 12,
      }}
    >
      <strong>{percent != null ? `${Math.round(percent)}%` : 'N/A'}</strong>
      <span>{CREDIBILITY_LABELS[key]}</span>
    </span>
  );
}

export default memo(CredibilityBadge);
