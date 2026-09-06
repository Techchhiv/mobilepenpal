import React from 'react';
import { Icon } from '@iconify/react';
import {
  formatClientDate,
  getClientStatusBadge,
  getSubscriptionStatusBadge,
  getPlanBadge,
} from '../../../utils/clientUtils';
import ClientActionMenu from './ClientActionMenu';

export default function ClientRow({
  school,
  onToggleStatus,
  onEditSchool,
  onDeleteSchool,
}) {
  const schoolStatus = getClientStatusBadge(school.status, school.is_active);
  const subStatus = getSubscriptionStatusBadge(school.subscription_status);
  const plan = getPlanBadge(school.subscription_plan);
  const adminEmail = school.admin_email || school.admin?.email || '-';

  return (
    <tr>
      {/* 1. School Name */}
      <td>
        <div className="d-flex align-items-center gap-12">
          <div className="school-avatar">
            <Icon icon="mdi:school" />
          </div>
          <div>
            <span className="d-block fw-semibold text-primary-light">
              {school.name}
            </span>
            {school.slug && (
              <span className="d-block text-secondary-light text-xs">
                {school.slug}
              </span>
            )}
          </div>
        </div>
      </td>

      {/* 2. School Key */}
      <td className="text-nowrap">
        <span className="school-key-badge" title="School Key">
          <Icon icon="mdi:key-variant" className="text-secondary-light" />
          {school.school_key || '-'}
        </span>
      </td>

      {/* 3. Admin Email */}
      <td>
        <span className="client-email-text" title={adminEmail}>
          {adminEmail}
        </span>
      </td>

      {/* 4. School Status */}
      <td>
        <span
          className={`badge text-xs fw-semibold ${schoolStatus.bg} ${schoolStatus.text} px-10 py-4 radius-4`}
        >
          {schoolStatus.label}
        </span>
      </td>

      {/* 5. Subscription Plan */}
      <td>
        {plan.bg ? (
          <span
            className={`badge text-xs fw-semibold ${plan.bg} ${plan.text} px-10 py-4 radius-4`}
          >
            {plan.label}
          </span>
        ) : (
          <span className="text-secondary-light text-xs">-</span>
        )}
      </td>

      {/* 6. Subscription Status */}
      <td>
        <span
          className={`badge text-xs fw-semibold ${subStatus.bg} ${subStatus.text} px-10 py-4 radius-4`}
        >
          {subStatus.label}
        </span>
      </td>

      {/* 7. Subscription End Date */}
      <td className="text-nowrap">
        <span className="text-secondary-light text-xs">
          {formatClientDate(school.subscription_end_date)}
        </span>
      </td>

      {/* 8. Students */}
      <td className="text-nowrap">
        <span className="fw-medium text-xs text-secondary-light">
          {Number(school.students_count || 0).toLocaleString()}
        </span>
      </td>

      {/* 9. Teachers */}
      <td className="text-nowrap">
        <span className="fw-medium text-xs text-secondary-light">
          {Number(school.teachers_count || 0).toLocaleString()}
        </span>
      </td>

      {/* 10. Actions */}
      <td className="text-end">
        <ClientActionMenu
          school={school}
          onToggleStatus={onToggleStatus}
          onEditSchool={onEditSchool}
          onDeleteSchool={onDeleteSchool}
        />
      </td>
    </tr>
  );
}
