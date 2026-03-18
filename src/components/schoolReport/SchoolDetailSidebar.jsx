import { Icon } from '@iconify/react';

const STATUS_BADGE = {
  active: 'success',
  trial: 'warning',
  expired: 'danger',
  cancelled: 'secondary',
};

const PAYMENT_BADGE = {
  paid: 'success',
  unpaid: 'warning',
  overdue: 'danger',
};

function formatDate(isoString) {
  if (!isoString) return '—';
  return new Date(isoString).toLocaleDateString(undefined, {
    year: 'numeric', month: 'short', day: 'numeric',
  });
}

function Row({ label, value }) {
  return (
    <li className="list-group-item d-flex justify-content-between align-items-start px-0 py-2 border-0 border-bottom">
      <span className="text-secondary small">{label}</span>
      <span className="fw-medium small text-end ms-2">{value ?? '—'}</span>
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

/**
 * SchoolDetailSidebar renders a scrollable detail panel for a selected school.
 *
 * Props:
 *   school  — SchoolReport object or null; renders nothing when null
 *   onClose — () => void; called when the close button is clicked
 */
export default function SchoolDetailSidebar({ school, onClose }) {
  if (!school) return null;

  const subStatusVariant = STATUS_BADGE[school.subscriptionStatus] ?? 'secondary';
  const paymentVariant = PAYMENT_BADGE[school.paymentStatus] ?? 'secondary';

  return (
    <div
      className="card school-detail-sidebar shadow-sm h-100"
      style={{ overflowY: 'auto', maxHeight: '80vh' }}
    >
      {/* Header */}
      <div className="school-detail-sidebar-header">
        <h6 className="mb-0 fw-semibold text-truncate me-2">{school.schoolName}</h6>
        <button
          type="button"
          className="btn-close"
          aria-label="Close"
          onClick={onClose}
        />
      </div>

      <div className="card-body pt-3">
        {/* 1. School Overview */}
        <Section title="School Overview" icon="mdi:school">
          <Row label="School Code" value={school.schoolCode} />
          <Row label="Type" value={<span className="text-capitalize">{school.schoolType}</span>} />
          <Row label="Founded" value={school.foundedYear} />
          <Row label="Status" value={
            <span className={`badge bg-${school.status === 'active' ? 'success' : 'secondary'}-subtle text-${school.status === 'active' ? 'success' : 'secondary'}-emphasis text-capitalize`}>
              {school.status}
            </span>
          } />
        </Section>


        {/* 2. Location */}
        <Section title="Location" icon="mdi:map-marker">
          <Row label="Country" value={school.country} />
          <Row label="Province / State" value={school.provinceOrState} />
          <Row label="City" value={school.city} />
          <Row label="District" value={school.district} />
          <Row label="Address" value={school.address} />
          <Row label="Postal Code" value={school.postalCode} />
        </Section>

        {/* 3. Contact Information */}
        <Section title="Contact Information" icon="mdi:card-account-details">
          <Row label="Email" value={school.schoolEmail} />
          <Row label="Phone" value={school.phoneNumber} />
          <Row label="Website" value={school.website} />
          <Row label="Principal" value={school.principalName} />
          <Row label="Admin Contact" value={school.adminContactName} />
          <Row label="Admin Email" value={school.adminContactEmail} />
        </Section>

       

        {/* 4. Student Statistics */}
        <Section title="Student Statistics" icon="fluent:people-20-filled">
          <Row label="Total Students" value={school.totalStudents?.toLocaleString()} />
          <Row label="Active" value={school.activeStudents?.toLocaleString()} />
          <Row label="Inactive" value={school.inactiveStudents?.toLocaleString()} />
          <Row label="Male" value={school.maleStudents?.toLocaleString()} />
          <Row label="Female" value={school.femaleStudents?.toLocaleString()} />
          <Row label="Grade Levels" value={school.gradeLevels?.join(', ')} />
        </Section>

    

        {/* 5. Teacher Statistics */}
        <Section title="Teacher Statistics" icon="ph:chalkboard-teacher-fill">
          <Row label="Total Teachers" value={school.totalTeachers?.toLocaleString()} />
          <Row label="Full-Time" value={school.fullTimeTeachers?.toLocaleString()} />
          <Row label="Part-Time" value={school.partTimeTeachers?.toLocaleString()} />
          <Row label="Teacher-Student Ratio" value={school.teacherStudentRatio} />
        </Section>

     

        {/* 6. Subscription Details */}
        <Section title="Subscription Details" icon="mdi:credit-card">
          <Row label="Plan" value={<span className="text-capitalize">{school.subscriptionPlan}</span>} />
          <Row label="Status" value={
            <span className={`badge bg-${subStatusVariant}-subtle text-${subStatusVariant}-emphasis text-capitalize`}>
              {school.subscriptionStatus}
            </span>
          } />
          <Row label="Billing Cycle" value={<span className="text-capitalize">{school.billingCycle}</span>} />
          <Row label="Payment Status" value={
            <span className={`badge bg-${paymentVariant}-subtle text-${paymentVariant}-emphasis text-capitalize`}>
              {school.paymentStatus}
            </span>
          } />
          <Row label="Start Date" value={formatDate(school.subscriptionStartDate)} />
          <Row label="End Date" value={formatDate(school.subscriptionEndDate)} />
        </Section>


        {/* 7. System Usage Metrics */}
        <Section title="System Usage Metrics" icon="mdi:chart-bar">
          <Row label="Active Users" value={school.numberOfActiveUsers?.toLocaleString()} />
          <Row label="Admin Users" value={school.numberOfAdminUsers?.toLocaleString()} />
          <Row label="Created At" value={formatDate(school.createdAt)} />
          <Row label="Last Login" value={formatDate(school.lastLoginAt)} />
          <Row label="Last Updated" value={formatDate(school.lastUpdatedAt)} />
        </Section>
      </div>
    </div>
  );
}
