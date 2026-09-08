import React from 'react';
import { Icon } from '@iconify/react';
import { Link } from 'react-router-dom';

export default function AdminPageHeader({
  title,
  subtitle,
  actionLabel,
  actionIcon,
  onAction,
  actionDisabled = false,
  primaryAction,
  className = '',
}) {
  const action = primaryAction || (actionLabel ? { label: actionLabel, icon: actionIcon, onClick: onAction, disabled: actionDisabled } : null);

  return (
    <div className={`d-flex align-items-center justify-content-between flex-wrap gap-16 mb-24 ${className}`}>
      <div className="min-w-0">
        <h4 className="fw-bold text-dark mb-2 text-truncate">{title}</h4>
        {subtitle && <p className="text-secondary-light text-sm mb-0">{subtitle}</p>}
      </div>

      {action && action.to ? (
        <Link
          to={action.to}
          className="btn btn-primary radius-8 d-inline-flex align-items-center gap-8 shadow-none"
        >
          {action.icon && <Icon icon={action.icon} className="text-lg" />}
          <span>{action.label}</span>
        </Link>
      ) : action && (action.onClick || action.onAction) ? (
        <button
          type="button"
          className="btn btn-primary radius-8 d-inline-flex align-items-center gap-8 shadow-none"
          onClick={action.onClick || action.onAction}
          disabled={action.disabled || actionDisabled}
        >
          {action.icon && <Icon icon={action.icon} className="text-lg" />}
          <span>{action.label}</span>
        </button>
      ) : null}
    </div>
  );
}
