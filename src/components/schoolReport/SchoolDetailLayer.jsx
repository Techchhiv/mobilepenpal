import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Icon } from '@iconify/react';
import { useAuth } from '../../context/AuthContext';
import '../../assets/css/adminReport.css';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatDate(dateStr) {
  if (!dateStr) return '-';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

function formatCurrency(amount) {
  if (amount === null || amount === undefined || isNaN(Number(amount))) return '-';
  return `$${Number(amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

// ─── Small UI Components ──────────────────────────────────────────────────────

function StatusBadge({ status, className = '' }) {
  const normStatus = (status || '').toLowerCase();
  const config = {
    active:    { badge: 'status-badge-active', label: 'Active', icon: 'mdi:check-circle-outline' },
    inactive:  { badge: 'status-badge-inactive', label: 'Inactive', icon: 'mdi:close-circle-outline' },
    scheduled: { badge: 'status-badge-scheduled', label: 'Scheduled', icon: 'mdi:clock-outline' },
    expired:   { badge: 'status-badge-expired', label: 'Expired', icon: 'mdi:alert-circle-outline' },
    none:      { badge: 'status-badge-none', label: 'No Subscription', icon: 'mdi:help-circle-outline' },
  }[normStatus] ?? {
    badge: 'status-badge-none',
    label: status ? status.charAt(0).toUpperCase() + status.slice(1) : 'Unknown',
    icon: 'mdi:information-outline',
  };

  return (
    <span className={`status-badge ${config.badge} ${className}`}>
      <Icon icon={config.icon} className="text-base flex-shrink-0" />
      <span>{config.label}</span>
    </span>
  );
}

function PlanBadge({ plan, className = '' }) {
  if (!plan) return <span className="text-secondary-light">-</span>;
  const normPlan = plan.toLowerCase();
  const badgeClass = {
    monthly: 'plan-badge-monthly',
    yearly: 'plan-badge-yearly',
    standard: 'plan-badge-standard',
    premium: 'plan-badge-premium',
  }[normPlan] ?? 'plan-badge-monthly';

  const label = plan.charAt(0).toUpperCase() + plan.slice(1);

  return (
    <span className={`plan-badge ${badgeClass} ${className}`}>
      {label}
    </span>
  );
}

function SectionHeader({ icon, title, subtitle }) {
  return (
    <div className="d-flex align-items-center gap-12 mb-20 pb-12 border-bottom">
      <div className="icon-box-sm">
        <Icon icon={icon} />
      </div>
      <div>
        <h6 className="fw-bold mb-0 text-dark">{title}</h6>
        {subtitle && <p className="text-secondary-light text-xs mb-0 mt-2">{subtitle}</p>}
      </div>
    </div>
  );
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

function SchoolDetailSkeleton() {
  return (
    <div className="school-detail-page py-12">
      <div className="card border radius-12 p-24 mb-20">
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-16">
          <div className="d-flex align-items-center gap-16">
            <div className="placeholder-glow">
              <span className="placeholder rounded-12" style={{ width: '60px', height: '60px', display: 'block' }}></span>
            </div>
            <div>
              <div className="placeholder-glow mb-8">
                <span className="placeholder col-8" style={{ width: '220px', height: '24px', display: 'block' }}></span>
              </div>
              <div className="placeholder-glow">
                <span className="placeholder col-6" style={{ width: '140px', height: '16px', display: 'block' }}></span>
              </div>
            </div>
          </div>
          <div className="placeholder-glow">
            <span className="placeholder rounded-8" style={{ width: '100px', height: '36px', display: 'inline-block' }}></span>
          </div>
        </div>
      </div>

      <div className="row g-20 mb-20">
        <div className="col-xl-7 col-12">
          <div className="card border radius-12 p-24 placeholder-glow">
            <span className="placeholder col-4 mb-16" style={{ height: '20px', display: 'block' }}></span>
            <div className="d-flex flex-column gap-12">
              {[1, 2, 3, 4, 5, 6, 7, 8].map(i => (
                <span key={i} className="placeholder col-12 radius-8" style={{ height: '40px', display: 'block' }}></span>
              ))}
            </div>
          </div>
        </div>
        <div className="col-xl-5 col-12">
          <div className="card border radius-12 p-24 placeholder-glow">
            <span className="placeholder col-5 mb-16" style={{ height: '20px', display: 'block' }}></span>
            <div className="d-flex flex-column gap-12">
              {[1, 2, 3, 4, 5].map(i => (
                <span key={i} className="placeholder col-12 radius-8" style={{ height: '40px', display: 'block' }}></span>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="card border radius-12 p-24 placeholder-glow">
        <span className="placeholder col-3 mb-16" style={{ height: '20px', display: 'block' }}></span>
        <span className="placeholder col-12 mb-8" style={{ height: '36px', display: 'block' }}></span>
        <span className="placeholder col-12" style={{ height: '36px', display: 'block' }}></span>
      </div>
    </div>
  );
}

// ─── Sections ─────────────────────────────────────────────────────────────────

function SchoolInfoSection({ school }) {
  const infoItems = [
    { label: 'School Name',  value: <span className="fw-bold text-dark">{school.schoolName || '-'}</span>, icon: 'mdi:school-outline' },
    { label: 'School Key',   value: <span className="fw-bold font-monospace text-primary-600 bg-primary-light px-10 py-4 radius-6">{school.schoolCode || '-'}</span>, icon: 'mdi:key-outline' },
    { label: 'School Status', value: <StatusBadge status={school.status} />, icon: 'mdi:shield-check-outline' },
    { label: 'Admin Name',   value: <span className="fw-medium text-dark">{school.adminName || '-'}</span>, icon: 'mdi:account-tie-outline' },
    { label: 'Admin Email',  value: school.adminEmail ? <a href={`mailto:${school.adminEmail}`} className="text-primary-600 text-decoration-none hover-underline fw-medium">{school.adminEmail}</a> : '-', icon: 'mdi:email-outline' },
    { label: 'Total Students', value: <span className="fw-bold text-dark">{Number(school.totalStudents ?? 0).toLocaleString()}</span>, icon: 'fluent:people-20-filled' },
    { label: 'Total Teachers', value: <span className="fw-bold text-dark">{Number(school.totalTeachers ?? 0).toLocaleString()}</span>, icon: 'ph:chalkboard-teacher-fill' },
    { label: 'Total Branches', value: <span className="fw-bold text-dark">{Number(school.totalBranches ?? 0).toLocaleString()}</span>, icon: 'mdi:source-branch' },
    { label: 'Date Created', value: <span className="fw-medium text-dark">{formatDate(school.createdAt)}</span>, icon: 'mdi:calendar-plus' },
  ];

  return (
    <div className="card border radius-12 h-100 shadow-none">
      <div className="card-body p-24">
        <SectionHeader
          icon="mdi:school-outline"
          title="School Information"
          subtitle="Detailed overview of school administration and capacity"
        />

        <div className="d-flex flex-column">
          {infoItems.map(({ label, value, icon }, idx) => (
            <div
              key={label || idx}
              className={`d-flex align-items-center justify-content-between py-14 px-12 ${
                idx < infoItems.length - 1 ? 'border-bottom' : ''
              } info-row-item`}
            >
              <div className="d-flex align-items-center gap-12 min-w-0">
                <div className="icon-box-sm">
                  <Icon icon={icon} />
                </div>
                <span className="text-secondary-light text-sm fw-medium">{label}</span>
              </div>
              <div className="text-end text-sm ms-16 text-break">
                {value}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function CurrentSubscriptionSection({ subscription }) {
  if (!subscription) {
    return (
      <div className="card border radius-12 h-100 shadow-none">
        <div className="card-body p-24 d-flex flex-column">
          <SectionHeader
            icon="mdi:credit-card-outline"
            title="Current Subscription"
            subtitle="Active plan and validity status"
          />
          <div className="d-flex flex-column align-items-center justify-content-center py-40 my-auto text-center">
            <div className="w-56-px h-56-px bg-neutral-100 radius-50 d-flex align-items-center justify-content-center mb-12">
              <Icon icon="mdi:credit-card-off-outline" className="text-secondary-light text-2xl" />
            </div>
            <h6 className="fw-semibold mb-4 text-secondary">No active subscription found.</h6>
            <p className="text-secondary-light text-xs mb-0">This school currently does not have an active subscription package.</p>
          </div>
        </div>
      </div>
    );
  }

  const planTitle = subscription.plan
    ? `${subscription.plan.charAt(0).toUpperCase() + subscription.plan.slice(1)} Plan`
    : 'Standard Plan';

  const subItems = [
    { label: 'Amount',     value: <span className="fw-bold text-primary-600 text-base">{formatCurrency(subscription.amount)}</span>, icon: 'mdi:currency-usd' },
    { label: 'Start Date', value: <span className="fw-semibold text-dark text-sm">{formatDate(subscription.startDate)}</span>, icon: 'mdi:calendar-start' },
    { label: 'End Date',   value: <span className="fw-semibold text-dark text-sm">{formatDate(subscription.endDate)}</span>, icon: 'mdi:calendar-end' },
  ];

  return (
    <div className="card border radius-12 h-100 shadow-none">
      <div className="card-body p-24 d-flex flex-column justify-content-between">
        <div>
          <SectionHeader
            icon="mdi:credit-card-outline"
            title="Current Subscription"
            subtitle="Active plan and validity status"
          />

          {/* Plan Name & Status Badge Header Row (as requested in requirement layout) */}
          <div className="d-flex align-items-center justify-content-between pb-16 mb-16 border-bottom">
            <div>
              <span className="text-xs text-secondary-light text-uppercase fw-semibold tracking-wider d-block mb-2">Subscription Plan</span>
              <h5 className="fw-bold mb-0 text-dark">{planTitle}</h5>
            </div>
            <StatusBadge status={subscription.status} />
          </div>

          {/* Subscription Details: Amount, Start Date, End Date */}
          <div className="d-flex flex-column">
            {subItems.map(({ label, value, icon }, idx) => (
              <div
                key={label}
                className={`d-flex align-items-center justify-content-between py-12 px-8 ${
                  idx < subItems.length - 1 ? 'border-bottom' : ''
                } info-row-item`}
              >
                <div className="d-flex align-items-center gap-12 min-w-0">
                  <div className="icon-box-sm">
                    <Icon icon={icon} />
                  </div>
                  <span className="text-secondary-light text-sm fw-medium">{label}</span>
                </div>
                <div className="text-end text-sm ms-16">{value}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function SubscriptionHistorySection({ history = [] }) {
  return (
    <div className="card border radius-12 shadow-none mb-20">
      <div className="card-body p-24">
        <SectionHeader
          icon="mdi:history"
          title="Subscription History"
          subtitle="Record of past and recurring subscription cycles"
        />

        {history.length === 0 ? (
          <div className="d-flex flex-column align-items-center justify-content-center py-40 text-center">
            <div className="w-56-px h-56-px bg-neutral-100 radius-50 d-flex align-items-center justify-content-center mb-12">
              <Icon icon="mdi:calendar-blank-outline" className="text-secondary-light text-2xl" />
            </div>
            <h6 className="fw-semibold mb-4 text-secondary">No previous subscription history found.</h6>
            <p className="text-secondary-light text-xs mb-0">Previous subscription cycles will appear here once recorded.</p>
          </div>
        ) : (
          <div className="table-responsive">
            <table className="table sm-table align-middle mb-0">
              <thead className="table-light">
                <tr>
                  <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Plan</th>
                  <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Amount</th>
                  <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Status</th>
                  <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Start Date</th>
                  <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">End Date</th>
                </tr>
              </thead>
              <tbody>
                {history.map((sub, idx) => (
                  <tr key={sub?.id ?? idx} className="hover-bg-neutral-50 transition-1">
                    <td className="py-12 px-16">
                      <PlanBadge plan={sub?.plan} />
                    </td>
                    <td className="py-12 px-16 text-sm fw-bold text-dark">
                      {formatCurrency(sub?.amount)}
                    </td>
                    <td className="py-12 px-16">
                      <StatusBadge status={sub?.status ?? 'none'} />
                    </td>
                    <td className="py-12 px-16 text-sm text-secondary-light font-monospace">
                      {formatDate(sub?.startDate)}
                    </td>
                    <td className="py-12 px-16 text-sm text-secondary-light font-monospace">
                      {formatDate(sub?.endDate)}
                    </td>
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

function BillingActionsSection({ school, canViewPayments, canViewInvoices, navigate }) {
  if (!canViewPayments && !canViewInvoices) return null;

  return (
    <div className="card border radius-12 shadow-none mb-20">
      <div className="card-body p-24">
        <SectionHeader
          icon="mdi:cash-fast"
          title="Billing Actions"
          subtitle="Direct links to manage school financial records and billing history"
        />

        <div className="d-flex align-items-center gap-16 flex-wrap">
          {canViewPayments && (
            <button
              type="button"
              className="btn btn-outline-primary radius-8 d-inline-flex align-items-center gap-8 px-20 py-10"
              onClick={() => navigate(`/admin/schools/${school.schoolId}/payments`)}
            >
              <Icon icon="mdi:cash-multiple" className="text-lg" />
              <span>View Payments</span>
            </button>
          )}

          {canViewInvoices && (
            <button
              type="button"
              className="btn btn-outline-secondary radius-8 d-inline-flex align-items-center gap-8 px-20 py-10"
              onClick={() => navigate('/admin/invoices')}
            >
              <Icon icon="mdi:file-document-outline" className="text-lg" />
              <span>View Invoices</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function SchoolDetailLayer({ school, loading, error, onRetry }) {
  const navigate   = useNavigate();
  const location   = useLocation();
  const { isSuperAdmin, hasPermission } = useAuth();

  // Resolve back URL
  const backSearch = location.search || '';
  const backTo     = `/admin/reports${backSearch}`;

  // Billing permissions
  const canViewPayments = isSuperAdmin || hasPermission('menu.payments');
  const canViewInvoices = isSuperAdmin || hasPermission('billing.view') || hasPermission('menu.payments');

  if (loading) {
    return <SchoolDetailSkeleton />;
  }

  if (error) {
    return (
      <div className="card border radius-12 p-32 text-center my-24 border-danger-200 bg-danger-50">
        <div className="w-56-px h-56-px bg-danger-focus radius-50 d-inline-flex align-items-center justify-content-center mx-auto mb-16">
          <Icon icon="mdi:alert-circle" className="text-danger-main text-2xl" />
        </div>
        <h5 className="fw-bold text-danger-main mb-8">Failed to Load School Details</h5>
        <p className="text-secondary-light text-sm max-w-500 mx-auto mb-20">{error}</p>
        <div className="d-flex justify-content-center gap-12 flex-wrap">
          {onRetry && (
            <button
              type="button"
              className="btn btn-primary btn-sm radius-8 d-inline-flex align-items-center gap-8"
              onClick={onRetry}
            >
              <Icon icon="mdi:refresh" />
              Try Again
            </button>
          )}
          <button
            type="button"
            className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-8"
            onClick={() => navigate(backTo)}
          >
            <Icon icon="mdi:arrow-left" />
            Back to School Reports
          </button>
        </div>
      </div>
    );
  }

  if (!school) {
    return (
      <div className="card border radius-12 p-32 text-center my-24">
        <Icon icon="mdi:school-outline" className="text-secondary-light text-4xl mb-12" />
        <h5 className="fw-bold mb-8">No School Found</h5>
        <p className="text-secondary-light text-sm mb-16">The requested school record could not be found.</p>
        <div>
          <button
            type="button"
            className="btn btn-outline-primary btn-sm radius-8 d-inline-flex align-items-center gap-8"
            onClick={() => navigate(backTo)}
          >
            <Icon icon="mdi:arrow-left" />
            Back to School Reports
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="school-detail-page py-12">
      {/* Navigation Top Bar */}
      <div className="d-flex align-items-center justify-content-between flex-wrap gap-12 mb-20">
        <button
          type="button"
          className="btn btn-sm btn-outline-primary radius-8 d-inline-flex align-items-center gap-8 shadow-none"
          onClick={() => navigate(backTo)}
        >
          <Icon icon="mdi:arrow-left" />
          Back to School Reports
        </button>
      </div>

      {/* Main School Header Card */}
      <div className="card border radius-12 mb-20 shadow-none">
        <div className="card-body p-24">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-16">
            <div className="d-flex align-items-center gap-16 min-w-0">
              <div className="w-56-px h-56-px bg-primary-light radius-12 d-flex justify-content-center align-items-center flex-shrink-0">
                <Icon icon="mdi:school" className="text-primary-600 text-3xl" />
              </div>
              <div className="min-w-0">
                <h4 className="fw-bold mb-4 text-dark text-truncate">{school.schoolName}</h4>
                <div className="d-flex align-items-center gap-8 flex-wrap text-sm text-secondary-light">
                  <span>School Key:</span>
                  <strong className="text-dark font-monospace">{school.schoolCode || '-'}</strong>
                </div>
              </div>
            </div>

            <div>
              <StatusBadge status={school.status} />
            </div>
          </div>
        </div>
      </div>

      {/* Main Grid: School Information & Current Subscription */}
      <div className="row g-20 mb-20">
        <div className="col-xl-7 col-12">
          <SchoolInfoSection school={school} />
        </div>
        <div className="col-xl-5 col-12">
          <CurrentSubscriptionSection subscription={school.currentSubscription} />
        </div>
      </div>

      {/* Subscription History Section */}
      <SubscriptionHistorySection history={school.subscriptionHistory} />

      {/* Billing Actions Section */}
      <BillingActionsSection
        school={school}
        canViewPayments={canViewPayments}
        canViewInvoices={canViewInvoices}
        navigate={navigate}
      />
    </div>
  );
}
