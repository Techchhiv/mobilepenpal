import {
  calculateRemainingDays,
  getExpirationLevel,
  formatSubscriptionDate,
  formatPlanName,
} from "./subscriptionUtils";

describe("subscriptionUtils", () => {
  describe("calculateRemainingDays", () => {
    it("returns 0 for null, undefined, or empty date", () => {
      expect(calculateRemainingDays(null)).toBe(0);
      expect(calculateRemainingDays(undefined)).toBe(0);
      expect(calculateRemainingDays("")).toBe(0);
      expect(calculateRemainingDays("invalid-date")).toBe(0);
    });

    it("calculates positive days correctly", () => {
      const today = "2026-09-08";
      expect(calculateRemainingDays("2026-09-09", today)).toBe(1);
      expect(calculateRemainingDays("2026-09-15", today)).toBe(7);
      expect(calculateRemainingDays("2026-10-08", today)).toBe(30);
      expect(calculateRemainingDays("2026-12-31", today)).toBe(114);
    });

    it("returns 0 for today (expires today)", () => {
      const today = "2026-09-08";
      expect(calculateRemainingDays("2026-09-08", today)).toBe(0);
    });

    it("never returns negative days for past dates", () => {
      const today = "2026-09-08";
      expect(calculateRemainingDays("2026-09-07", today)).toBe(0);
      expect(calculateRemainingDays("2026-01-01", today)).toBe(0);
      expect(calculateRemainingDays("2025-12-31", today)).toBe(0);
    });

    it("handles ISO strings with time components", () => {
      const today = "2026-09-08";
      expect(calculateRemainingDays("2026-09-18T00:00:00.000000Z", today)).toBe(10);
    });

    it("handles Date objects", () => {
      const today = new Date(2026, 8, 8); // Sept 8, 2026
      const future = new Date(2026, 8, 18); // Sept 18, 2026
      expect(calculateRemainingDays(future, today)).toBe(10);
    });
  });

  describe("getExpirationLevel", () => {
    it("returns 'none' when hasSubscription is false", () => {
      expect(getExpirationLevel(0, false, false)).toBe("none");
      expect(getExpirationLevel(50, false, false)).toBe("none");
    });

    it("returns 'expired' when isExpired is true", () => {
      expect(getExpirationLevel(10, true, true)).toBe("expired");
      expect(getExpirationLevel(0, true, true)).toBe("expired");
    });

    it("returns 'expired' when daysLeft is 0 or less", () => {
      expect(getExpirationLevel(0, false, true)).toBe("expired");
      expect(getExpirationLevel(-5, false, true)).toBe("expired");
    });

    it("returns 'critical' when daysLeft is 7 or less", () => {
      expect(getExpirationLevel(7, false, true)).toBe("critical");
      expect(getExpirationLevel(5, false, true)).toBe("critical");
      expect(getExpirationLevel(1, false, true)).toBe("critical");
    });

    it("returns 'warning' when daysLeft is between 8 and 30", () => {
      expect(getExpirationLevel(8, false, true)).toBe("warning");
      expect(getExpirationLevel(24, false, true)).toBe("warning");
      expect(getExpirationLevel(30, false, true)).toBe("warning");
    });

    it("returns 'normal' when daysLeft is greater than 30", () => {
      expect(getExpirationLevel(31, false, true)).toBe("normal");
      expect(getExpirationLevel(123, false, true)).toBe("normal");
    });
  });

  describe("formatSubscriptionDate", () => {
    it("formats ISO date string into DD MMMM YYYY", () => {
      expect(formatSubscriptionDate("2026-12-31")).toBe("31 December 2026");
      expect(formatSubscriptionDate("2026-01-01")).toBe("01 January 2026");
    });

    it("returns '—' for empty or null dates", () => {
      expect(formatSubscriptionDate(null)).toBe("—");
      expect(formatSubscriptionDate(undefined)).toBe("—");
      expect(formatSubscriptionDate("")).toBe("—");
    });
  });

  describe("formatPlanName", () => {
    it("formats standard plans", () => {
      expect(formatPlanName("yearly")).toBe("Yearly Plan");
      expect(formatPlanName("monthly")).toBe("Monthly Plan");
      expect(formatPlanName("Premium Plan")).toBe("Premium Plan");
      expect(formatPlanName("enterprise")).toBe("Enterprise Plan");
    });

    it("falls back to default if null", () => {
      expect(formatPlanName(null)).toBe("School Subscription");
    });
  });
});
