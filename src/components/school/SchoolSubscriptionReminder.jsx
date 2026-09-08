import React from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import {
  calculateRemainingDays,
  getExpirationLevel,
  formatSubscriptionDate,
  formatPlanName,
} from "../../utils/subscriptionUtils";

/**
 * SchoolSubscriptionReminder Component
 *
 * Clean, simple, and harmonious Subscription Expiry Reminder for the School Admin Dashboard.
 * Aligned with WowDash design tokens and responsive across all devices.
 *
 * @param {Object} props
 * @param {Object|null} props.subscription - Subscription data from backend
 * @param {boolean} props.loading - Whether dashboard/subscription data is loading
 * @param {string|null} props.error - Error message if subscription loading failed
 * @param {string} [props.targetRoute="/school/subscription"] - Route to navigate to on "View Subscription"
 */
export default function SchoolSubscriptionReminder({
  subscription,
  loading = false,
  error = null,
  targetRoute = "/school/subscription",
}) {
  // 1. Loading State (Shimmering skeleton, never flashes "No Subscription" or "0 days")
  if (loading) {
    return (
      <div className="card border radius-12 shadow-none mb-24 bg-white" data-testid="subscription-loading">
        <div className="card-body p-20">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle placeholder-glow bg-neutral-100 flex-shrink-0"></div>
              <div>
                <div className="placeholder-glow" style={{ width: "120px" }}>
                  <span className="placeholder col-12 rounded" style={{ height: "14px" }}></span>
                </div>
                <div className="placeholder-glow mt-1" style={{ width: "160px" }}>
                  <span className="placeholder col-12 rounded" style={{ height: "18px" }}></span>
                </div>
              </div>
            </div>
            <div className="placeholder-glow" style={{ width: "140px" }}>
              <span className="placeholder col-12 radius-8" style={{ height: "36px" }}></span>
            </div>
          </div>
          <div className="placeholder-glow" style={{ maxWidth: "340px" }}>
            <span className="placeholder col-10 rounded" style={{ height: "14px" }}></span>
          </div>
        </div>
      </div>
    );
  }

  // 2. Error State (Non-disruptive, does not break dashboard)
  if (error) {
    return (
      <div className="card border border-danger-subtle radius-12 shadow-none mb-24 bg-white" data-testid="subscription-error">
        <div className="card-body p-20">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle bg-danger-50 text-danger d-flex align-items-center justify-content-center flex-shrink-0">
                <Icon icon="solar:danger-triangle-bold" className="text-xl" />
              </div>
              <div className="flex-grow-1">
                <h6 className="mb-1 text-danger fw-semibold text-sm">Subscription Status Unavailable</h6>
                <p className="mb-0 text-muted text-xs">
                  Unable to load subscription information. Please try again later.
                </p>
              </div>
            </div>
            <div>
              <Link
                to={targetRoute}
                className="btn btn-sm btn-outline-secondary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium"
              >
                <span>View Subscription</span>
                <Icon icon="solar:arrow-right-linear" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Determine actual values from backend payload
  const hasSubscription = Boolean(
    subscription &&
      (subscription.has_subscription ?? (subscription.plan !== null || subscription.end_date !== null))
  );

  const isExpired = Boolean(
    subscription?.is_expired ||
      (subscription && !subscription.is_active && hasSubscription && subscription.status === "expired")
  );

  const rawEndDate = subscription?.end_date || null;
  const rawStartDate = subscription?.start_date || null;

  // Timezone-safe remaining days calculation from actual subscription end date
  const calculatedDays = rawEndDate ? calculateRemainingDays(rawEndDate) : (subscription?.days_left ?? 0);
  const remainingDays = Math.max(0, calculatedDays);

  const level = getExpirationLevel(
    remainingDays,
    isExpired,
    hasSubscription
  );

  const formattedPlan = formatPlanName(subscription?.plan);
  const formattedEndDate = formatSubscriptionDate(rawEndDate);
  const formattedStartDate = rawStartDate ? formatSubscriptionDate(rawStartDate) : null;

  // 3. No Active Subscription State
  if (level === "none") {
    return (
      <div className="card border radius-12 shadow-none mb-24 bg-white" data-testid="subscription-none">
        <div className="card-body p-20">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle bg-neutral-100 text-secondary d-flex align-items-center justify-content-center flex-shrink-0">
                <Icon icon="solar:shield-warning-bold-duotone" className="text-2xl" />
              </div>
              <div>
                <div className="d-flex align-items-center gap-2 mb-1 flex-wrap">
                  <h6 className="mb-0 fw-bold text-dark">No Active Subscription</h6>
                  <span className="badge bg-secondary-focus text-secondary-main text-xs px-2 py-1 radius-4">
                    Inactive
                  </span>
                </div>
                <p className="mb-0 text-secondary-light text-sm" style={{ maxWidth: "600px" }}>
                  There is currently no active subscription associated with your school. Please contact Khmer PenPal for assistance.
                </p>
              </div>
            </div>
            <div className="ms-auto ms-sm-0">
              <Link
                to={targetRoute}
                className="btn btn-sm btn-outline-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium"
              >
                <span>View Subscription</span>
                <Icon icon="solar:arrow-right-linear" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 4. Expired State (Zero negative days displayed!)
  if (level === "expired") {
    return (
      <div className="card border border-danger-subtle radius-12 shadow-none mb-24 bg-white" data-testid="subscription-expired">
        <div className="card-body p-20">
          {/* Header Row */}
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3 pb-3 border-bottom">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle bg-danger-50 text-danger d-flex align-items-center justify-content-center flex-shrink-0">
                <Icon icon="solar:close-circle-bold-duotone" className="text-2xl" />
              </div>
              <div>
                <span className="text-secondary-light text-xs fw-semibold text-uppercase tracking-wider d-block">
                  Your Subscription
                </span>
                <h6 className="mb-0 fw-bold text-dark">{formattedPlan}</h6>
              </div>
            </div>
            <div className="d-flex align-items-center gap-2 flex-wrap">
              <span className="badge bg-danger-focus text-danger-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                <Icon icon="solar:close-circle-bold" /> Expired
              </span>
              <Link
                to={targetRoute}
                className="btn btn-sm btn-outline-danger radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium"
              >
                <span>View Subscription</span>
                <Icon icon="solar:arrow-right-linear" />
              </Link>
            </div>
          </div>

          {/* Details & Alert Strip */}
          <div className="pt-3">
            <div className="d-flex flex-wrap align-items-center gap-3 text-secondary-light text-sm mb-3">
              {formattedStartDate && (
                <span>
                  Start Date: <strong className="text-dark fw-medium">{formattedStartDate}</strong>
                </span>
              )}
              <span>
                Expired: <strong className="text-dark fw-medium">{formattedEndDate}</strong>
              </span>
            </div>

            <div className="alert bg-danger-focus border border-danger-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-0 text-danger-main">
              <Icon icon="solar:danger-triangle-bold" className="text-xl flex-shrink-0 mt-1" />
              <div>
                <strong className="d-block mb-1 text-danger-main fw-semibold text-sm">Subscription Expired</strong>
                <span className="text-sm text-secondary-light">
                  Your subscription expired on {formattedEndDate}. Please contact Khmer PenPal for subscription assistance.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 5. Critical State (7 days or less remaining)
  if (level === "critical") {
    return (
      <div className="card border border-danger-subtle radius-12 shadow-none mb-24 bg-white" data-testid="subscription-critical">
        <div className="card-body p-20">
          {/* Header Row */}
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3 pb-3 border-bottom">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle bg-danger-50 text-danger d-flex align-items-center justify-content-center flex-shrink-0">
                <Icon icon="solar:alarm-play-bold-duotone" className="text-2xl" />
              </div>
              <div>
                <span className="text-secondary-light text-xs fw-semibold text-uppercase tracking-wider d-block">
                  Your Subscription
                </span>
                <h6 className="mb-0 fw-bold text-dark">{formattedPlan}</h6>
              </div>
            </div>
            <div className="d-flex align-items-center gap-2 flex-wrap">
              <span className="badge bg-danger-focus text-danger-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                <Icon icon="solar:alarm-play-bold" /> {remainingDays} {remainingDays === 1 ? "day" : "days"} remaining
              </span>
              <span className="badge bg-warning-focus text-warning-main px-12 py-4 radius-6 fw-semibold text-xs">
                Expiring Soon
              </span>
              <Link
                to={targetRoute}
                className="btn btn-sm btn-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium ms-1"
              >
                <span>View Subscription</span>
                <Icon icon="solar:arrow-right-linear" />
              </Link>
            </div>
          </div>

          {/* Details & Alert Strip */}
          <div className="pt-3">
            <div className="d-flex flex-wrap align-items-center gap-3 text-secondary-light text-sm mb-3">
              {formattedStartDate && (
                <span>
                  Start Date: <strong className="text-dark fw-medium">{formattedStartDate}</strong>
                </span>
              )}
              <span>
                Expires: <strong className="text-dark fw-medium">{formattedEndDate}</strong>
              </span>
              <span className="text-danger fw-semibold">
                ({remainingDays} {remainingDays === 1 ? "day" : "days"} remaining)
              </span>
            </div>

            <div className="alert bg-danger-focus border border-danger-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-0 text-danger-main">
              <Icon icon="solar:danger-triangle-bold" className="text-xl flex-shrink-0 mt-1" />
              <div>
                <strong className="d-block mb-1 text-danger-main fw-semibold text-sm">⚠ Subscription Expiring Soon</strong>
                <span className="text-sm text-secondary-light">
                  Your subscription expires in {remainingDays} {remainingDays === 1 ? "day" : "days"}. Please contact Khmer PenPal to renew your subscription.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 6. Warning State (30 days or less remaining)
  if (level === "warning") {
    return (
      <div className="card border border-warning-subtle radius-12 shadow-none mb-24 bg-white" data-testid="subscription-warning">
        <div className="card-body p-20">
          {/* Header Row */}
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3 pb-3 border-bottom">
            <div className="d-flex align-items-center gap-3">
              <div className="w-40-px h-40-px rounded-circle bg-warning-50 text-warning-main d-flex align-items-center justify-content-center flex-shrink-0">
                <Icon icon="solar:bell-bing-bold-duotone" className="text-2xl" />
              </div>
              <div>
                <span className="text-secondary-light text-xs fw-semibold text-uppercase tracking-wider d-block">
                  Your Subscription
                </span>
                <h6 className="mb-0 fw-bold text-dark">{formattedPlan}</h6>
              </div>
            </div>
            <div className="d-flex align-items-center gap-2 flex-wrap">
              <span className="badge bg-warning-focus text-warning-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                <Icon icon="solar:clock-circle-outline" /> {remainingDays} days remaining
              </span>
              <span className="badge bg-success-focus text-success-main px-12 py-4 radius-6 fw-semibold text-xs">
                Active
              </span>
              <Link
                to={targetRoute}
                className="btn btn-sm btn-outline-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium ms-1"
              >
                <span>View Subscription</span>
                <Icon icon="solar:arrow-right-linear" />
              </Link>
            </div>
          </div>

          {/* Details & Alert Strip */}
          <div className="pt-3">
            <div className="d-flex flex-wrap align-items-center gap-3 text-secondary-light text-sm mb-3">
              {formattedStartDate && (
                <span>
                  Start Date: <strong className="text-dark fw-medium">{formattedStartDate}</strong>
                </span>
              )}
              <span>
                Expires: <strong className="text-dark fw-medium">{formattedEndDate}</strong>
              </span>
              <span className="text-warning-main fw-semibold">
                ({remainingDays} days remaining)
              </span>
            </div>

            <div className="alert bg-warning-focus border border-warning-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-0 text-warning-main">
              <Icon icon="solar:bell-bing-bold" className="text-xl flex-shrink-0 mt-1" />
              <div>
                <strong className="d-block mb-1 text-warning-main fw-semibold text-sm">⚠ Subscription Expiring Soon</strong>
                <span className="text-sm text-secondary-light">
                  Your subscription expires in {remainingDays} days. Please contact Khmer PenPal if you would like to renew your subscription.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 7. Normal State (More than 30 days remaining - clean, calm, no yellow banner)
  return (
    <div className="card border radius-12 shadow-none mb-24 bg-white" data-testid="subscription-normal">
      <div className="card-body p-20">
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
          <div className="d-flex align-items-center gap-3">
            <div className="w-40-px h-40-px rounded-circle bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center flex-shrink-0">
              <Icon icon="solar:shield-check-bold-duotone" className="text-2xl" />
            </div>
            <div>
              <span className="text-secondary-light text-xs fw-semibold text-uppercase tracking-wider d-block mb-1">
                Your Subscription
              </span>
              <div className="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <h6 className="mb-0 fw-bold text-dark">{formattedPlan}</h6>
                <span className="badge bg-success-focus text-success-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                  <Icon icon="solar:verified-check-bold" /> Active
                </span>
              </div>
              <div className="d-flex flex-wrap align-items-center gap-3 text-secondary-light text-sm">
                {formattedStartDate && (
                  <span>
                    Start Date: <strong className="text-dark fw-medium">{formattedStartDate}</strong>
                  </span>
                )}
                <span>
                  Expires: <strong className="text-dark fw-medium">{formattedEndDate}</strong>
                </span>
                <span className="badge bg-neutral-100 text-secondary-light fw-medium radius-4 px-2 py-1 text-xs">
                  {remainingDays} days remaining
                </span>
              </div>
            </div>
          </div>
          <div>
            <Link
              to={targetRoute}
              className="btn btn-sm btn-outline-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1 fw-medium"
            >
              <span>View Subscription</span>
              <Icon icon="solar:arrow-right-linear" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
