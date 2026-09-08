import React from 'react';
import { Icon } from '@iconify/react';

export default function AdminEmptyState({
  icon = 'mdi:inbox-remove-outline',
  title = 'No records found',
  message = 'There are no items to display at the moment.',
  actionLabel,
  actionIcon,
  onAction,
}) {
  return (
    <div className="card border p-32 text-center">
      <div className="w-56-px h-56-px bg-neutral-100 radius-50 d-inline-flex align-items-center justify-content-center mx-auto mb-16">
        <Icon icon={icon} className="text-secondary-light text-2xl" />
      </div>
      <h6 className="fw-bold text-dark mb-8">{title}</h6>
      <p className="text-secondary-light text-sm max-w-400-px mx-auto mb-20">{message}</p>
      {actionLabel && onAction && (
        <div>
          <button
            type="button"
            className="btn btn-outline-primary btn-sm radius-8 d-inline-flex align-items-center gap-8"
            onClick={onAction}
          >
            {actionIcon && <Icon icon={actionIcon} />}
            <span>{actionLabel}</span>
          </button>
        </div>
      )}
    </div>
  );
}
