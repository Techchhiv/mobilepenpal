import { Icon } from '@iconify/react';

const STATUS_BADGE = {
  active: 'success',
  scheduled: 'warning',
  expired: 'danger',
  inactive: 'secondary',
  none: 'secondary',
};

function formatDate(isoString) {
  if (!isoString) return '-';
  return new Date(isoString).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatCount(value) {
  return typeof value === 'number' ? value.toLocaleString() : '-';
}

function StatusBadge({ status }) {
  const variant = STATUS_BADGE[status] ?? 'secondary';
  const label = status === 'none' ? 'No subscription' : status;

  return (
    <span className={`badge bg-${variant}-subtle text-${variant}-emphasis text-capitalize`}>
      {label}
    </span>
  );
}

function Row({ label, value }) {
  return (
    <li className="list-group-item d-flex justify-content-between align-items-start px-0 py-2 border-0 border-bottom">
      <span className="text-secondary small">{label}</span>
      <span className="fw-medium small text-end ms-2">{value ?? '-'}</span>
    </li>
  );
}

function Section({ title, icon, children }) {
  return (
    <div className="mb-3">
      <div className="d-flex align-items-center gap-2 mb-2">
        <Icon icon={icon} className="text-primary fs-5" />
        <h6 className="mb-0 fw-semibold">{title}</h6>
      </div>
      <ul className="list-group list-group-flush">
        {children}
      </ul>
    </div>
  );
}

export default function SchoolDetailSidebar({ school, loading = false, onClose }) {
  if (!school && !loading) return null;

  return (
    <div
      className="card school-detail-sidebar shadow-sm h-100"
      style={{ overflowY: 'auto', maxHeight: '80vh' }}
    >
      <div className="school-detail-sidebar-header">
        <h6 className="mb-0 fw-semibold text-truncate me-2">
          {school?.schoolName ?? 'Loading school...'}
        </h6>
        <button
          type="button"
          className="btn-close"
          aria-label="Close"
          onClick={onClose}
        />
      </div>

      <div className="card-body pt-3">
        {loading && !school ? (
          <div className="d-flex justify-content-center align-items-center py-5">
            <div className="spinner-border text-primary" role="status" aria-label="Loading school details">
              <span className="visually-hidden">Loading...</span>
            </div>
          </div>
        ) : (
          <>
            <Section title="School Overview" icon="mdi:school">
              <Row label="School Key" value={school.schoolCode} />
              <Row label="Slug" value={school.schoolSlug || '-'} />
              <Row label="Status" value={<StatusBadge status={school.status} />} />
            </Section>

            <Section title="Admin Contact" icon="mdi:card-account-details">
              <Row label="Admin Name" value={school.adminContactName || '-'} />
              <Row label="Email" value={school.schoolEmail || '-'} />
            </Section>

            <Section title="Student Statistics" icon="fluent:people-20-filled">
              <Row label="Total Students" value={formatCount(school.totalStudents)} />
              <Row label="Active" value={formatCount(school.activeStudents)} />
              <Row label="Inactive" value={formatCount(school.inactiveStudents)} />
              <Row label="Male" value={formatCount(school.maleStudents)} />
              <Row label="Female" value={formatCount(school.femaleStudents)} />
            </Section>

            <Section title="Teacher Statistics" icon="ph:chalkboard-teacher-fill">
              <Row label="Total Teachers" value={formatCount(school.totalTeachers)} />
              <Row label="Active" value={formatCount(school.activeTeachers)} />
              <Row label="Inactive" value={formatCount(school.inactiveTeachers)} />
            </Section>

            <Section title="Subscription Details" icon="mdi:credit-card">
              <Row
                label="Current Plan"
                value={school.subscriptionPlan ? (
                  <span className="text-capitalize">{school.subscriptionPlan}</span>
                ) : '-'}
              />
              <Row label="Current Status" value={<StatusBadge status={school.subscriptionStatus} />} />
              <Row label="Start Date" value={formatDate(school.subscriptionStartDate)} />
              <Row label="End Date" value={formatDate(school.subscriptionEndDate)} />
              <Row
                label="Latest Subscription"
                value={school.latestSubscription ? (
                  <span className="text-capitalize">
                    {school.latestSubscription.plan} ({school.latestSubscription.status})
                  </span>
                ) : '-'}
              />
            </Section>

            <Section title="System Overview" icon="mdi:chart-bar">
              <Row label="Users Count" value={formatCount(school.totalUsers)} />
              <Row label="Branches Count" value={formatCount(school.totalBranches)} />
              <Row label="Subscriptions Count" value={formatCount(school.totalSubscriptions)} />
              <Row label="Created At" value={formatDate(school.createdAt)} />
              <Row label="Last Updated" value={formatDate(school.lastUpdatedAt)} />
            </Section>

            {school.subscriptionHistory?.length > 0 && (
              <Section title="Subscription History" icon="mdi:history">
                {school.subscriptionHistory.map((subscription) => (
                  <li
                    key={subscription.id}
                    className="list-group-item px-0 py-2 border-0 border-bottom"
                  >
                    <div className="d-flex justify-content-between align-items-center gap-2">
                      <span className="small text-secondary text-capitalize">
                        {subscription.plan}
                      </span>
                      <StatusBadge status={subscription.status} />
                    </div>
                    <div className="small text-secondary mt-1">
                      {formatDate(subscription.startDate)} to {formatDate(subscription.endDate)}
                    </div>
                  </li>
                ))}
              </Section>
            )}
          </>
        )}
      </div>
    </div>
  );
}
