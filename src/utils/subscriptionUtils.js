/**
 * Utilities for School Subscription Date & Expiration Calculations
 */

/**
 * Calculates remaining days between today and subscription end date.
 * Timezone-safe: calculates day difference in UTC midnights to prevent off-by-one errors.
 * Never returns negative numbers (returns 0 if expired or today).
 *
 * @param {string|Date|null} endDate - ISO string (e.g. "2026-12-31") or Date object
 * @param {string|Date|null} [currentDate] - Optional reference date for testing
 * @returns {number} Non-negative integer representing remaining days
 */
export function calculateRemainingDays(endDate, currentDate = null) {
  if (!endDate) return 0;

  try {
    let endYear, endMonth, endDay;

    if (typeof endDate === "string") {
      const cleanDate = endDate.split("T")[0];
      const parts = cleanDate.split("-").map(Number);
      if (parts.length < 3 || parts.some(isNaN)) return 0;
      [endYear, endMonth, endDay] = parts;
    } else if (endDate instanceof Date && !isNaN(endDate.getTime())) {
      endYear = endDate.getFullYear();
      endMonth = endDate.getMonth() + 1;
      endDay = endDate.getDate();
    } else {
      return 0;
    }

    const endUtc = Date.UTC(endYear, endMonth - 1, endDay);

    let nowYear, nowMonth, nowDay;
    if (currentDate) {
      if (typeof currentDate === "string") {
        const cleanDate = currentDate.split("T")[0];
        const parts = cleanDate.split("-").map(Number);
        [nowYear, nowMonth, nowDay] = parts;
      } else if (currentDate instanceof Date) {
        nowYear = currentDate.getFullYear();
        nowMonth = currentDate.getMonth() + 1;
        nowDay = currentDate.getDate();
      }
    } else {
      const now = new Date();
      nowYear = now.getFullYear();
      nowMonth = now.getMonth() + 1;
      nowDay = now.getDate();
    }

    const nowUtc = Date.UTC(nowYear, nowMonth - 1, nowDay);
    const diffMs = endUtc - nowUtc;
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    return Math.max(0, diffDays);
  } catch (err) {
    console.error("Error calculating remaining subscription days:", err);
    return 0;
  }
}

/**
 * Categorizes the subscription into reminder levels:
 * - 'none': School does not have any active or previous subscription
 * - 'expired': Subscription is expired (end_date in past or manually deactivated)
 * - 'critical': 7 days or less remaining
 * - 'warning': 8 to 30 days remaining
 * - 'normal': More than 30 days remaining
 *
 * @param {number} daysLeft - Remaining days (>= 0)
 * @param {boolean} isExpired - Explicit expiration flag from backend or date check
 * @param {boolean} hasSubscription - Whether a subscription record exists
 * @returns {'none'|'expired'|'critical'|'warning'|'normal'}
 */
export function getExpirationLevel(daysLeft, isExpired = false, hasSubscription = true) {
  if (!hasSubscription) return "none";
  if (isExpired) return "expired";
  if (daysLeft <= 0) return "expired";
  if (daysLeft <= 7) return "critical";
  if (daysLeft <= 30) return "warning";
  return "normal";
}

/**
 * Formats date into "DD MMMM YYYY" format (e.g. "31 December 2026")
 *
 * @param {string|Date|null} dateStr
 * @returns {string}
 */
export function formatSubscriptionDate(dateStr) {
  if (!dateStr) return "—";
  try {
    let year, month, day;
    if (typeof dateStr === "string") {
      const clean = dateStr.split("T")[0];
      const parts = clean.split("-").map(Number);
      if (parts.length < 3 || parts.some(isNaN)) return dateStr;
      [year, month, day] = parts;
    } else if (dateStr instanceof Date && !isNaN(dateStr.getTime())) {
      year = dateStr.getFullYear();
      month = dateStr.getMonth() + 1;
      day = dateStr.getDate();
    } else {
      return String(dateStr);
    }

    const date = new Date(Date.UTC(year, month - 1, day));
    return new Intl.DateTimeFormat("en-GB", {
      day: "2-digit",
      month: "long",
      year: "numeric",
      timeZone: "UTC",
    }).format(date);
  } catch (e) {
    return String(dateStr);
  }
}

/**
 * Formats plan string into human-friendly plan title
 *
 * @param {string|null} plan
 * @returns {string}
 */
export function formatPlanName(plan) {
  if (!plan) return "School Subscription";
  const trimmed = plan.trim();
  const lower = trimmed.toLowerCase();
  if (lower === "yearly") return "Yearly Plan";
  if (lower === "monthly") return "Monthly Plan";

  // Capitalize every word
  const capitalized = trimmed.replace(/\b\w/g, (c) => c.toUpperCase());
  if (capitalized.toLowerCase().endsWith("plan")) {
    return capitalized;
  }
  return capitalized + " Plan";
}
