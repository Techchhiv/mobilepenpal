/**
 * Utility functions for Manage Clients page
 */

export function formatClientDate(dateStr) {
  if (!dateStr) return '-';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '-';
    return d.toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return '-';
  }
}

export function getClientStatusBadge(status, isActive) {
  const active = status === 'active' || isActive === true;
  if (active) {
    return {
      bg: 'bg-success-focus',
      text: 'text-success-main',
      label: 'Active',
    };
  }
  return {
    bg: 'bg-neutral-200',
    text: 'text-secondary-light',
    label: 'Inactive',
  };
}

export function getSubscriptionStatusBadge(status) {
  const s = (status || '').toLowerCase().trim();
  switch (s) {
    case 'active':
      return {
        bg: 'bg-success-focus',
        text: 'text-success-main',
        label: 'Active',
      };
    case 'expiring_soon':
    case 'expiring':
      return {
        bg: 'bg-warning-focus',
        text: 'text-warning-main',
        label: 'Expiring Soon',
      };
    case 'expired':
      return {
        bg: 'bg-danger-focus',
        text: 'text-danger-main',
        label: 'Expired',
      };
    case 'scheduled':
      return {
        bg: 'bg-info-focus',
        text: 'text-info-main',
        label: 'Scheduled',
      };
    case 'none':
    case 'no_subscription':
    case 'inactive':
    default:
      return {
        bg: 'bg-neutral-200',
        text: 'text-secondary-light',
        label: 'No Subscription',
      };
  }
}

export function getPlanBadge(plan) {
  if (!plan) {
    return {
      bg: '',
      text: 'text-secondary-light',
      label: '-',
    };
  }
  const p = plan.toLowerCase().trim();
  if (p === 'monthly') {
    return {
      bg: 'bg-primary-focus',
      text: 'text-primary-600',
      label: 'Monthly',
    };
  }
  if (p === 'yearly') {
    return {
      bg: 'bg-info-focus',
      text: 'text-info-main',
      label: 'Yearly',
    };
  }
  return {
    bg: 'bg-primary-focus',
    text: 'text-primary-600',
    label: plan.charAt(0).toUpperCase() + plan.slice(1),
  };
}

export function syncFiltersToURL(filters, setSearchParams) {
  const params = {};
  if (filters.search && filters.search.trim()) {
    params.search = filters.search.trim();
  }
  if (filters.schoolStatus) {
    params.school_status = filters.schoolStatus;
  }
  if (filters.subscriptionStatus) {
    params.subscription_status = filters.subscriptionStatus;
  }
  if (filters.plan) {
    params.plan = filters.plan;
  }
  if (filters.page && Number(filters.page) > 1) {
    params.page = String(filters.page);
  }
  setSearchParams(params, { replace: true });
}
