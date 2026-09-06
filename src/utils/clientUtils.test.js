import {
  formatClientDate,
  getClientStatusBadge,
  getSubscriptionStatusBadge,
  getPlanBadge,
  syncFiltersToURL,
} from './clientUtils';

describe('clientUtils', () => {
  describe('formatClientDate', () => {
    it('returns "-" for falsy dates', () => {
      expect(formatClientDate(null)).toBe('-');
      expect(formatClientDate('')).toBe('-');
      expect(formatClientDate(undefined)).toBe('-');
    });

    it('formats a valid date string correctly', () => {
      const formatted = formatClientDate('2026-12-31');
      expect(formatted).toMatch(/31/);
      expect(formatted).toMatch(/Dec/);
      expect(formatted).toMatch(/2026/);
    });

    it('returns "-" for invalid date string', () => {
      expect(formatClientDate('invalid-date')).toBe('-');
    });
  });

  describe('getClientStatusBadge', () => {
    it('returns active badge when status is active', () => {
      const badge = getClientStatusBadge('active', true);
      expect(badge.label).toBe('Active');
      expect(badge.text).toBe('text-success-main');
    });

    it('returns active badge when isActive is true even if status is missing', () => {
      const badge = getClientStatusBadge(null, true);
      expect(badge.label).toBe('Active');
    });

    it('returns inactive badge when inactive', () => {
      const badge = getClientStatusBadge('inactive', false);
      expect(badge.label).toBe('Inactive');
      expect(badge.bg).toBe('bg-neutral-200');
    });
  });

  describe('getSubscriptionStatusBadge', () => {
    it('handles active status', () => {
      const badge = getSubscriptionStatusBadge('active');
      expect(badge.label).toBe('Active');
      expect(badge.text).toBe('text-success-main');
    });

    it('handles expiring_soon and expiring', () => {
      expect(getSubscriptionStatusBadge('expiring_soon').label).toBe('Expiring Soon');
      expect(getSubscriptionStatusBadge('expiring').label).toBe('Expiring Soon');
    });

    it('handles expired', () => {
      const badge = getSubscriptionStatusBadge('expired');
      expect(badge.label).toBe('Expired');
      expect(badge.text).toBe('text-danger-main');
    });

    it('handles none / unknown', () => {
      expect(getSubscriptionStatusBadge('none').label).toBe('No Subscription');
      expect(getSubscriptionStatusBadge(null).label).toBe('No Subscription');
    });
  });

  describe('getPlanBadge', () => {
    it('formats monthly plan', () => {
      const badge = getPlanBadge('monthly');
      expect(badge.label).toBe('Monthly');
      expect(badge.bg).toBe('bg-primary-focus');
    });

    it('formats yearly plan', () => {
      const badge = getPlanBadge('yearly');
      expect(badge.label).toBe('Yearly');
      expect(badge.bg).toBe('bg-info-focus');
    });

    it('handles falsy plan', () => {
      const badge = getPlanBadge(null);
      expect(badge.label).toBe('-');
    });
  });

  describe('syncFiltersToURL', () => {
    it('sets non-empty filter parameters and page > 1', () => {
      const mockSetSearchParams = jest.fn();
      syncFiltersToURL(
        {
          search: 'Angkor',
          schoolStatus: 'active',
          subscriptionStatus: 'expiring_soon',
          plan: 'monthly',
          page: 2,
        },
        mockSetSearchParams
      );

      expect(mockSetSearchParams).toHaveBeenCalledWith(
        {
          search: 'Angkor',
          school_status: 'active',
          subscription_status: 'expiring_soon',
          plan: 'monthly',
          page: '2',
        },
        { replace: true }
      );
    });

    it('omits page when page is 1 or falsy', () => {
      const mockSetSearchParams = jest.fn();
      syncFiltersToURL(
        {
          search: '',
          schoolStatus: '',
          subscriptionStatus: '',
          plan: '',
          page: 1,
        },
        mockSetSearchParams
      );

      expect(mockSetSearchParams).toHaveBeenCalledWith({}, { replace: true });
    });
  });
});
