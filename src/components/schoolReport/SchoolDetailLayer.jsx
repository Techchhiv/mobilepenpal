import { useNavigate, useLocation } from 'react-router-dom';
import { Icon } from '@iconify/react';
import { useAuth } from '../../context/AuthContext';

// ─── Constants ───────────────────────────────────────────────────────────────

const STATUS_CONFIG = {
  active:    { badge: 'bg-success-focus text-success-main', label: 'Active' },
  inactive:  { badge: 'bg-neutral-200 text-secondary-light', label: 'Inactive' },
  scheduled: { badge: 'bg-warning-focus text-warning-main', label: 'Scheduled' },
  expired:   { badge: 'bg-danger-focus text-danger-main', label: 'Expired' },
  none:      { badge: 'bg-neutral-200 text-secondary-light', label: 'No Subscription' },
};

const PLAN_CONFIG = {
  monthly: { badge: 'bg-primary-focus text-primary-600', label: 'Monthly' },
  yearly:  { badge: 'bg-info-focus text-info-main', label: 'Yearly' },
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatDate(dateStr) {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatCurrency(amount) {
  if (amount === null || amount === undefined) return '-';
  return `$${Number(amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

// ─── Small Components ─────────────────────────────────────────────────────────

function StatusBadge({ status }) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.none;
  return (
    <span className={`badge text-sm fw-semibold px-12 py-6 radius-4 text-capitalize ${config.badge}`}>
      {config.label}
    </span>
  );
}

function PlanBadge({ plan }) {
  const config = PLAN_CONFIG[plan];
  if (!config) return <span className="text-secondary-light">-</span>;
  return (
    <span className={`badge text-sm fw-semibold px-12 py-6 radius-4 ${config.badge}`}>
      {config.label}
    </span>
  );
}

function StatCard({ icon, label, value, sub }) {
  return (
    <div className="col-xxl-3 col-sm-6">
      <div className="card border radius-12 h-100">
        <div className="card-body p-20 d-flex align-items-center gap-16">
          <div className="w-48-px h-48-px d-flex justify-content-center align-items-center bg-primary-light radius-8 flex-shrink-0">
            <Icon icon={icon} className="text-primary-600 text-xxl" />
          </div>
          <div>
            <p className="text-secondary-light text-sm mb-4">{label}</p>
            <h6 className="fw-semibold mb-0">{value}</h6>
            {sub && <p className="text-xs text-secondary-light mb-0 mt-2">{sub}</p>}
          </div>
        </div>
      </div>
    </div>
  );
}

function SectionHeader({ icon, title }) {
  return (
    <div className="d-flex align-items-center gap-12 mb-16">
      <div className="w-36-px h-36-px bg-primary-light radius-8 d-flex justify-content-center align-items-center">
        <Icon icon={icon} className="text-primary-600 text-lg" />
      </div>
      <h6 className="fw-semibold mb-0">{title}</h6>
    </div>
  );
}

// ─── Sections ─────────────────────────────────────────────────────────────────

function SchoolInfoSection({ school }) {
  const rows = [
    { label: 'Admin Name', value: school.adminName || '-' },
    { label: 'Admin Email', value: school.adminEmail || '-' },
    { label: 'School Key', value: school.schoolCode || '-' },
    { label: 'Date Created', value: formatDate(school.createdAt) },
    { label: 'Last Updated', value: formatDate(school.updatedAt) },
  ];

  return (
    <div className="card border radius-12 mb-20">
      <div className="card-body p-24">
        <SectionHeader icon="mdi:school-outline" title="School Information" />
        <div className="row g-16 mb-20">
          <StatCard
            icon="fluent:people-20-filled"
            label="Total Students"
            value={school.totalStudents.toLocaleString()}
            sub={`Active: ${school.activeStudents.toLocaleString()}`}
          />
          <StatCard
            icon="ph:chalkboard-teacher-fill"
            label="Total Teachers"
            value={school.totalTeachers.toLocaleString()}
            sub={`Active: ${school.activeTeachers.toLocaleString()}`}
          />
          <StatCard
            icon="mdi:source-branch"
            label="Branches"
            value={school.totalBranches.toLocaleString()}
          />
          <StatCard
            icon="mdi:account-group-outline"
            label="Total Users"
            value={school.totalUsers.toLocaleString()}
          />
        </div>
        <ul className="list-group list-group-flush">
          {rows.map(({ label, value }) => (
            <li
              key={label}
              className="list-group-item px-0 d-flex justify-content-between align-items-center border-0 border-bottom py-12"
            >
              <span className="text-secondary-light text-sm">{label}</span>
              <span className="fw-medium text-sm text-end ms-2">{value}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

function CurrentSubscriptionSection({ subscription }) {
  if (!subscription) {
    return (
      <div className="card border radius-12 mb-20">
        <div className="card-body p-24">
          <SectionHeader icon="mdi:credit-card-outline" title="Current Subscription" />
          <div className="d-flex align-items-center gap-12 py-20 text-secondary-light">
            <Icon icon="mdi:information-outline" className="text-xl" />
            <span className="text-sm">No active subscription at the moment.</span>
          </div>
        </div>
      </div>
    );
  }

  const fields = [
    { label: 'Plan',       value: <PlanBadge plan={subscription.plan} /> },
    { label: 'Amount',     value: formatCurrency(subscription.amount) },
    { label: 'Status',     value: <StatusBadge status={subscription.status} /> },
    { label: 'Start Date', value: formatDate(subscription.startDate) },
    { label: 'End Date',   value: formatDate(subscription.endDate) },
  ];

  return (
    <div className="card border radius-12 mb-20">
      <div className="card-body p-24">
        <SectionHeader icon="mdi:credit-card-outline" title="Current Subscription" />
        <ul className="list-group list-group-flush">
          {fields.map(({ label, value }) => (
            <li
              key={label}
              className="list-group-item px-0 d-flex justify-content-between align-items-center border-0 border-bottom py-12"
            >
              <span className="text-secondary-light text-sm">{label}</span>
              <span className="fw-medium text-sm text-end ms-2">{value}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

function SubscriptionHistorySection({ history = [] }) {
  return (
    <div className="card border radius-12 mb-20">
      <div className="card-body p-24">
        <SectionHeader icon="mdi:history" title="Subscription History" />
        {history.length === 0 ? (
          <div className="d-flex align-items-center gap-12 py-20 text-secondary-light">
            <Icon icon="mdi:information-outline" className="text-xl" />
            <span className="text-sm">No subscription history found.</span>
          </div>
        ) : (
          <div className="table-responsive">
            <table className="table sm-table mb-0">
              <thead>
                <tr>
                  <th scope="col">Plan</th>
                  <th scope="col">Amount</th>
                  <th scope="col">Status</th>
                  <th scope="col">Start Date</th>
                  <th scope="col">End Date</th>
                </tr>
              </thead>
              <tbody>
                {history.map((sub, idx) => (
                  <tr key={sub?.id ?? idx}>
                    <td><PlanBadge plan={sub?.plan} /></td>
                    <td className="text-sm fw-medium">{formatCurrency(sub?.amount)}</td>
                    <td><StatusBadge status={sub?.status ?? 'none'} /></td>
                    <td className="text-sm text-secondary-light">{formatDate(sub?.startDate)}</td>
                    <td className="text-sm text-secondary-light">{formatDate(sub?.endDate)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function SchoolDetailLayer({ school, loading, error }) {
  const navigate   = useNavigate();
  const location   = useLocation();
  const { isSuperAdmin, hasPermission } = useAuth();

  // Resolve the "back" URL: use the query string stored in the current URL
  // (placed there by SchoolReportRow when navigating here), fall back to /admin/reports
  const backSearch = location.search || '';
  const backTo     = `/admin/reports${backSearch}`;

  // Billing shortcut permissions (mirror route gates in App.js)
  const canViewPayments = isSuperAdmin || hasPermission('menu.payments');
  const canViewInvoices = isSuperAdmin || hasPermission('billing.view') || hasPermission('menu.payments');

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center py-80">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="alert alert-danger mt-3" role="alert">
        <Icon icon="mdi:alert-circle-outline" className="me-2" />
        {error}
      </div>
    );
  }

  if (!school) return null;

  return (
    <div className="school-detail-page">
      {/* Back Button */}
      <div className="mb-20">
        <button
          type="button"
          className="btn btn-sm btn-outline-primary radius-8 d-inline-flex align-items-center gap-8"
          onClick={() => navigate(backTo)}
        >
          <Icon icon="mdi:arrow-left" />
          Back to School Reports
        </button>
      </div>

      {/* School Header */}
      <div className="card border radius-12 mb-20">
        <div className="card-body p-24 d-flex align-items-center justify-content-between flex-wrap gap-16">
          <div className="d-flex align-items-center gap-16">
            <div className="w-56-px h-56-px bg-primary-light radius-12 d-flex justify-content-center align-items-center flex-shrink-0">
              <Icon icon="mdi:school" className="text-primary-600 text-2xl" />
            </div>
            <div>
              <h5 className="fw-bold mb-4">{school.schoolName}</h5>
              <p className="text-secondary-light text-sm mb-0">
                Key: <span className="fw-medium text-primary-light">{school.schoolCode || '-'}</span>
              </p>
            </div>
          </div>

          {/* Right side: Status badge + Billing Shortcuts */}
          <div className="d-flex align-items-center gap-12 flex-wrap">
            <StatusBadge status={school.status} />

            {/* Billing Shortcuts — only visible when user has permission */}
            {canViewPayments && (
              <button
                type="button"
                className="btn btn-sm btn-outline-primary radius-8 d-inline-flex align-items-center gap-6"
                onClick={() => navigate(`/admin/schools/${school.schoolId}/payments`)}
                title="View school payments"
              >
                <Icon icon="mdi:cash-multiple" className="text-sm" />
                View Payments
              </button>
            )}
            {canViewInvoices && (
              <button
                type="button"
                className="btn btn-sm btn-outline-secondary radius-8 d-inline-flex align-items-center gap-6"
                onClick={() => navigate('/admin/invoices')}
                title="View invoices"
              >
                <Icon icon="mdi:file-document-outline" className="text-sm" />
                View Invoices
              </button>
            )}
          </div>
        </div>
      </div>

      {/* School Information */}
      <SchoolInfoSection school={school} />

      {/* Current Subscription */}
      <CurrentSubscriptionSection subscription={school.currentSubscription} />

      {/* Subscription History */}
      <SubscriptionHistorySection history={school.subscriptionHistory} />
    </div>
  );
}
