const STATUS_BADGE = {
  active:    { bg: 'bg-success-focus', text: 'text-success-main' },
  trial:     { bg: 'bg-warning-focus', text: 'text-warning-main' },
  expired:   { bg: 'bg-danger-focus',  text: 'text-danger-main'  },
  cancelled: { bg: 'bg-neutral-200',   text: 'text-secondary-light' },
};

const PLAN_BADGE = {
  basic:      { bg: 'bg-neutral-200',   text: 'text-secondary-light' },
  pro:        { bg: 'bg-primary-focus', text: 'text-primary-600'     },
  enterprise: { bg: 'bg-info-focus',    text: 'text-info-main'       },
};

function formatDate(isoString) {
  if (!isoString) return '—';
  return new Date(isoString).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

/**
 * SchoolReportRow renders a single clickable row in the school report table.
 *
 * Props:
 *   school     — SchoolReport object
 *   isSelected — boolean; applies highlight when true
 *   onSelect   — () => void; called when the row is clicked
 */
export default function SchoolReportRow({ school, isSelected, onSelect }) {
  const {
    schoolName,
    city,
    country,
    totalStudents,
    totalTeachers,
    subscriptionPlan,
    subscriptionStatus,
    createdAt,
    lastLoginAt,
  } = school;

  const statusBadge = STATUS_BADGE[subscriptionStatus] ?? STATUS_BADGE.cancelled;
  const planBadge   = PLAN_BADGE[subscriptionPlan]      ?? PLAN_BADGE.basic;

  return (
    <tr
      className={isSelected ? 'bg-primary-focus' : ''}
      onClick={onSelect}
      style={{ cursor: 'pointer' }}
    >
      <td>
        <span className="text-md fw-semibold text-primary-light">{schoolName}</span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{city}, {country}</span>
      </td>
      <td>
        <span className="text-md fw-medium text-secondary-light">{totalStudents.toLocaleString()}</span>
      </td>
      <td>
        <span className="text-md fw-medium text-secondary-light">{totalTeachers.toLocaleString()}</span>
      </td>
      <td>
        <span className={`badge text-sm fw-semibold ${planBadge.bg} ${planBadge.text} px-12 py-6 radius-4 text-capitalize`}>
          {subscriptionPlan}
        </span>
      </td>
      <td>
        <span className={`badge text-sm fw-semibold ${statusBadge.bg} ${statusBadge.text} px-12 py-6 radius-4 text-capitalize`}>
          {subscriptionStatus}
        </span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{formatDate(createdAt)}</span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{formatDate(lastLoginAt)}</span>
      </td>
    </tr>
  );
}
