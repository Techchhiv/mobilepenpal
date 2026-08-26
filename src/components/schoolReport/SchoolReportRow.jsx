import { useNavigate } from 'react-router-dom';

const STATUS_BADGE = {
  active:    { bg: 'bg-success-focus', text: 'text-success-main' },
  scheduled: { bg: 'bg-warning-focus', text: 'text-warning-main' },
  expired:   { bg: 'bg-danger-focus', text: 'text-danger-main' },
  inactive:  { bg: 'bg-neutral-200', text: 'text-secondary-light' },
  none:      { bg: 'bg-neutral-200', text: 'text-secondary-light' },
};

const PLAN_BADGE = {
  monthly: { bg: 'bg-primary-focus', text: 'text-primary-600' },
  yearly:  { bg: 'bg-info-focus', text: 'text-info-main' },
  none:    { bg: 'bg-neutral-200', text: 'text-secondary-light' },
};

function formatDate(isoString) {
  if (!isoString) return '-';
  return new Date(isoString).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export default function SchoolReportRow({ school }) {
  const navigate = useNavigate();
  const {
    schoolName,
    schoolCode,
    schoolEmail,
    totalStudents,
    totalTeachers,
    subscriptionPlan,
    subscriptionStatus,
    lastUpdatedAt,
  } = school;

  const statusBadge = STATUS_BADGE[subscriptionStatus] ?? STATUS_BADGE.none;
  const planBadge = PLAN_BADGE[subscriptionPlan] ?? PLAN_BADGE.none;
  const planLabel = subscriptionPlan || 'No plan';
  const statusLabel = subscriptionStatus === 'none' ? 'No subscription' : subscriptionStatus;

  return (
    <tr
      onClick={() => navigate(`/admin/reports/schools/${school.schoolId}`)}
      style={{ cursor: 'pointer' }}
    >
      <td>
        <span className="text-md fw-semibold text-primary-light">{schoolName}</span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{schoolCode || '-'}</span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{schoolEmail || '-'}</span>
      </td>
      <td>
        <span className="text-md fw-medium text-secondary-light">{totalStudents.toLocaleString()}</span>
      </td>
      <td>
        <span className="text-md fw-medium text-secondary-light">{totalTeachers.toLocaleString()}</span>
      </td>
      <td>
        <span className={`badge text-sm fw-semibold ${planBadge.bg} ${planBadge.text} px-12 py-6 radius-4 text-capitalize`}>
          {planLabel}
        </span>
      </td>
      <td>
        <span className={`badge text-sm fw-semibold ${statusBadge.bg} ${statusBadge.text} px-12 py-6 radius-4 text-capitalize`}>
          {statusLabel}
        </span>
      </td>
      <td>
        <span className="text-md fw-normal text-secondary-light">{formatDate(lastUpdatedAt)}</span>
      </td>
    </tr>
  );
}
