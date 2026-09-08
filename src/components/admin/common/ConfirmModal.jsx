import React from 'react';
import { Icon } from '@iconify/react';

export default function ConfirmModal({
  open,
  title = 'Confirm Action',
  message = 'Are you sure you want to proceed with this action?',
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'danger', // 'danger' | 'warning' | 'primary'
  loading = false,
  onConfirm,
  onCancel,
}) {
  if (!open) return null;

  const variantStyles = {
    danger: {
      btn: 'btn-danger',
      iconBg: 'bg-danger-focus',
      iconColor: 'text-danger-main',
      icon: 'mdi:alert-circle-outline',
    },
    warning: {
      btn: 'btn-warning text-dark',
      iconBg: 'bg-warning-focus',
      iconColor: 'text-warning-main',
      icon: 'mdi:alert-outline',
    },
    primary: {
      btn: 'btn-primary',
      iconBg: 'bg-primary-focus',
      iconColor: 'text-primary-600',
      icon: 'mdi:help-circle-outline',
    },
  }[variant] ?? {
    btn: 'btn-danger',
    iconBg: 'bg-danger-focus',
    iconColor: 'text-danger-main',
    icon: 'mdi:alert-circle-outline',
  };

  return (
    <>
      <div className="modal-backdrop fade show" style={{ zIndex: 1050 }} onClick={onCancel}></div>
      <div
        className="modal fade show d-block"
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        style={{ zIndex: 1055 }}
        onClick={onCancel}
      >
        <div
          className="modal-dialog modal-dialog-centered max-w-440-px"
          role="document"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="modal-content border radius-12 p-24 text-center">
            <div className={`w-56-px h-56-px radius-50 d-inline-flex align-items-center justify-content-center mx-auto mb-16 ${variantStyles.iconBg}`}>
              <Icon icon={variantStyles.icon} className={`text-2xl ${variantStyles.iconColor}`} />
            </div>

            <h5 className="fw-bold text-dark mb-8">{title}</h5>
            <p className="text-secondary-light text-sm mb-24 max-w-360-px mx-auto">{message}</p>

            <div className="d-flex align-items-center justify-content-center gap-12">
              <button
                type="button"
                className="btn btn-outline-secondary radius-8 px-20 py-10"
                onClick={onCancel}
                disabled={loading}
              >
                {cancelLabel}
              </button>
              <button
                type="button"
                className={`btn ${variantStyles.btn} radius-8 px-20 py-10 d-inline-flex align-items-center gap-8`}
                onClick={onConfirm}
                disabled={loading}
              >
                {loading && <Icon icon="mdi:loading" className="spin text-lg" />}
                <span>{confirmLabel}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
