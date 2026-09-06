import React from 'react';
import { Icon } from '@iconify/react';

export default function StatusConfirmModal({
  isOpen,
  school,
  submitting,
  onConfirm,
  onClose,
}) {
  if (!isOpen || !school) return null;

  const isCurrentlyActive = Boolean(school.is_active || school.status === 'active');
  const targetAction = isCurrentlyActive ? 'Deactivate' : 'Activate';
  const actionColor = isCurrentlyActive ? 'danger' : 'success';
  const icon = isCurrentlyActive
    ? 'mdi:alert-circle-outline'
    : 'mdi:check-circle-outline';

  return (
    <div className="client-modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div
        className="client-modal-content"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="client-modal-header">
          <div className="d-flex align-items-center gap-8">
            <span className={`text-${actionColor} text-xl d-flex align-items-center`}>
              <Icon icon={icon} />
            </span>
            <h6 className="mb-0 fw-semibold">
              {targetAction} {school.name}?
            </h6>
          </div>
          <button
            type="button"
            className="btn btn-sm btn-link text-secondary-light p-0"
            onClick={onClose}
            disabled={submitting}
            aria-label="Close"
          >
            <Icon icon="mdi:close" className="text-lg" />
          </button>
        </div>

        <div className="client-modal-body py-24">
          <p className="text-secondary-light mb-16">
            This will change the school's account status to{' '}
            <strong className={`text-${actionColor}`}>
              {isCurrentlyActive ? 'Inactive' : 'Active'}
            </strong>
            .
          </p>
          <div className="p-12 radius-8 bg-neutral-100 border text-xs text-secondary-light">
            <div className="d-flex justify-content-between mb-4">
              <span>School Key:</span>
              <span className="fw-semibold text-primary-light">{school.school_key || '-'}</span>
            </div>
            <div className="d-flex justify-content-between">
              <span>Admin Email:</span>
              <span className="fw-medium">{school.admin_email || '-'}</span>
            </div>
          </div>
        </div>

        <div className="client-modal-footer">
          <button
            type="button"
            className="btn btn-light radius-8 px-16 py-8"
            onClick={onClose}
            disabled={submitting}
          >
            Cancel
          </button>
          <button
            type="button"
            className={`btn btn-${actionColor} radius-8 px-16 py-8 d-inline-flex align-items-center gap-6`}
            onClick={() => onConfirm(school, !isCurrentlyActive)}
            disabled={submitting}
          >
            {submitting ? (
              <>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                Updating...
              </>
            ) : (
              <>
                <Icon icon={isCurrentlyActive ? 'mdi:account-cancel-outline' : 'mdi:account-check-outline'} />
                {targetAction}
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
