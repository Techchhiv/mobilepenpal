/**
 * Tests for schoolReportUtils.js
 * Covers: filterSchools, parsePaginatedPage, exportToCSV, syncFiltersToURL
 */
import {
  filterSchools,
  parsePaginatedPage,
  exportToCSV,
  syncFiltersToURL,
} from './schoolReportUtils';

// ─── Shared fixtures ──────────────────────────────────────────────────────────

const makeSchool = (overrides = {}) => ({
  schoolId: 'SCH-001',
  schoolName: 'Test School',
  schoolCode: 'TS01',
  schoolEmail: 'admin@school.edu',
  status: 'active',
  country: 'Cambodia',
  provinceOrState: 'Phnom Penh',
  city: 'Phnom Penh',
  district: 'Chamkarmon',
  address: '1 Main St',
  postalCode: '12000',
  latitude: 11.5,
  longitude: 104.9,
  schoolEmail: 'test@school.edu',
  phoneNumber: '+855-23-000000',
  website: 'https://school.edu',
  principalName: 'Principal A',
  adminContactName: 'Admin A',
  adminContactEmail: 'admin@school.edu',
  totalStudents: 500,
  maleStudents: 250,
  femaleStudents: 250,
  gradeLevels: ['Grade 1'],
  activeStudents: 480,
  inactiveStudents: 20,
  totalTeachers: 30,
  activeTeachers: 25,
  fullTimeTeachers: 25,
  partTimeTeachers: 5,
  teacherStudentRatio: '1:17',
  subscriptionPlan: 'basic',
  subscriptionStatus: 'active',
  subscriptionStartDate: '2024-01-01',
  subscriptionEndDate: '2024-12-31',
  billingCycle: 'yearly',
  paymentStatus: 'paid',
  createdAt: '2023-01-01T00:00:00Z',
  lastLoginAt: '2025-01-01T00:00:00Z',
  lastUpdatedAt: '2025-01-01T00:00:00Z',
  numberOfActiveUsers: 10,
  numberOfAdminUsers: 2,
  ...overrides,
});

const schools = [
  makeSchool({ schoolId: 'SCH-001', schoolName: 'Alpha Academy', schoolCode: 'AA01', city: 'Phnom Penh', country: 'Cambodia', provinceOrState: 'Phnom Penh', subscriptionPlan: 'basic', subscriptionStatus: 'active' }),
  makeSchool({ schoolId: 'SCH-002', schoolName: 'Beta School', schoolCode: 'BS02', city: 'Siem Reap', country: 'Cambodia', provinceOrState: 'Siem Reap', subscriptionPlan: 'pro', subscriptionStatus: 'trial' }),
  makeSchool({ schoolId: 'SCH-003', schoolName: 'Gamma Institute', schoolCode: 'GI03', city: 'Bangkok', country: 'Thailand', provinceOrState: 'Bangkok', subscriptionPlan: 'enterprise', subscriptionStatus: 'expired' }),
  makeSchool({ schoolId: 'SCH-004', schoolName: 'Delta High', schoolCode: 'DH04', city: 'Hanoi', country: 'Vietnam', provinceOrState: 'Hanoi', subscriptionPlan: 'basic', subscriptionStatus: 'cancelled' }),
];

const emptyFilters = { search: '', location: '', subscriptionStatus: '', subscriptionPlan: '' };

// ─── filterSchools ────────────────────────────────────────────────────────────

describe('filterSchools', () => {
  test('returns full array when all filters are empty', () => {
    const result = filterSchools(schools, emptyFilters);
    expect(result).toHaveLength(schools.length);
  });

  test('does not mutate the input array', () => {
    const copy = [...schools];
    filterSchools(schools, { ...emptyFilters, search: 'alpha' });
    expect(schools).toEqual(copy);
  });

  test('search filter matches schoolName (case-insensitive)', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'alpha' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-001');
  });

  test('search filter matches city (case-insensitive)', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'BANGKOK' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-003');
  });

  test('search filter matches country (case-insensitive)', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'vietnam' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-004');
  });

  test('search filter matches schoolCode (case-insensitive)', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'gi03' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-003');
  });

  test('location filter matches city', () => {
    const result = filterSchools(schools, { ...emptyFilters, location: 'Siem Reap' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-002');
  });

  test('location filter matches country', () => {
    const result = filterSchools(schools, { ...emptyFilters, location: 'Thailand' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-003');
  });

  test('location filter matches provinceOrState', () => {
    const result = filterSchools(schools, { ...emptyFilters, location: 'Hanoi' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-004');
  });

  test('subscriptionStatus filter does exact match', () => {
    const result = filterSchools(schools, { ...emptyFilters, subscriptionStatus: 'trial' });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-002');
  });

  test('subscriptionPlan filter does exact match', () => {
    const result = filterSchools(schools, { ...emptyFilters, subscriptionPlan: 'basic' });
    expect(result).toHaveLength(2);
    expect(result.map((s) => s.schoolId)).toEqual(['SCH-001', 'SCH-004']);
  });

  test('multiple filters are ANDed together', () => {
    const result = filterSchools(schools, {
      search: 'Cambodia',
      location: '',
      subscriptionStatus: 'active',
      subscriptionPlan: 'basic',
    });
    expect(result).toHaveLength(1);
    expect(result[0].schoolId).toBe('SCH-001');
  });

  test('returns empty array when no schools match', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'zzznomatch' });
    expect(result).toHaveLength(0);
  });

  test('preserves relative order of matching schools', () => {
    const result = filterSchools(schools, { ...emptyFilters, subscriptionPlan: 'basic' });
    expect(result[0].schoolId).toBe('SCH-001');
    expect(result[1].schoolId).toBe('SCH-004');
  });

  test('returned array is a subset of the input array (same references)', () => {
    const result = filterSchools(schools, { ...emptyFilters, search: 'alpha' });
    expect(schools).toContain(result[0]);
  });
});

// ─── parsePaginatedPage ───────────────────────────────────────────────────────

describe('parsePaginatedPage', () => {
  const list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  test('returns first page correctly', () => {
    expect(parsePaginatedPage(list, 1, 5)).toEqual([1, 2, 3, 4, 5]);
  });

  test('returns last (partial) page correctly', () => {
    expect(parsePaginatedPage(list, 3, 5)).toEqual([11, 12]);
  });

  test('returns empty array when page exceeds total pages', () => {
    expect(parsePaginatedPage(list, 10, 5)).toEqual([]);
  });

  test('returns empty array for page < 1', () => {
    expect(parsePaginatedPage(list, 0, 5)).toEqual([]);
  });

  test('handles single-item list on page 1', () => {
    expect(parsePaginatedPage([42], 1, 10)).toEqual([42]);
  });

  test('handles empty list', () => {
    expect(parsePaginatedPage([], 1, 10)).toEqual([]);
  });

  test('does not mutate the input array', () => {
    const original = [1, 2, 3];
    parsePaginatedPage(original, 1, 2);
    expect(original).toEqual([1, 2, 3]);
  });

  test('result length does not exceed pageSize', () => {
    const result = parsePaginatedPage(list, 1, 5);
    expect(result.length).toBeLessThanOrEqual(5);
  });
});

// ─── exportToCSV ─────────────────────────────────────────────────────────────

describe('exportToCSV', () => {
  let createObjectURL;
  let revokeObjectURL;
  let appendChildSpy;
  let removeChildSpy;
  let clickSpy;

  beforeEach(() => {
    // Mock browser APIs not available in jsdom
    createObjectURL = jest.fn(() => 'blob:mock-url');
    revokeObjectURL = jest.fn();
    global.URL.createObjectURL = createObjectURL;
    global.URL.revokeObjectURL = revokeObjectURL;

    clickSpy = jest.fn();
    appendChildSpy = jest.spyOn(document.body, 'appendChild').mockImplementation(() => {});
    removeChildSpy = jest.spyOn(document.body, 'removeChild').mockImplementation(() => {});

    // Intercept createElement('a') to capture the link
    const origCreate = document.createElement.bind(document);
    jest.spyOn(document, 'createElement').mockImplementation((tag) => {
      const el = origCreate(tag);
      if (tag === 'a') el.click = clickSpy;
      return el;
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('triggers a download (click is called)', () => {
    exportToCSV([makeSchool()], 'test-report');
    expect(clickSpy).toHaveBeenCalledTimes(1);
  });

  test('produces header + one data row per school (correct line count)', () => {
    let capturedContent = '';
    global.Blob = class {
      constructor(parts) { capturedContent = parts[0]; }
    };

    exportToCSV([makeSchool(), makeSchool({ schoolId: 'SCH-002' })], 'report');
    const lines = capturedContent.split('\n');
    // 1 header + 2 data rows = 3 lines
    expect(lines).toHaveLength(3);
  });

  test('header row contains expected columns', () => {
    let capturedContent = '';
    global.Blob = class {
      constructor(parts) { capturedContent = parts[0]; }
    };

    exportToCSV([makeSchool()], 'report');
    const header = capturedContent.split('\n')[0];
    expect(header).toContain('School Name');
    expect(header).toContain('School Key');
    expect(header).toContain('Admin Email');
    expect(header).toContain('Plan');
    expect(header).toContain('Updated');
  });

  test('formats exported dates for spreadsheet display', () => {
    let capturedContent = '';
    global.Blob = class {
      constructor(parts) { capturedContent = parts[0]; }
    };

    exportToCSV([makeSchool()], 'report');
    expect(capturedContent).toContain('2024-01-01');
    expect(capturedContent).toContain('2024-12-31');
    expect(capturedContent).toContain('2023-01-01 00:00');
    expect(capturedContent).not.toContain('2023-01-01T00:00:00Z');
  });

  test('does not mutate the input array', () => {
    const input = [makeSchool()];
    const copy = [...input];
    exportToCSV(input, 'report');
    expect(input).toEqual(copy);
  });

  test('appends .csv extension when not already present', () => {
    // Restore the createElement mock from beforeEach, then re-spy cleanly
    jest.restoreAllMocks();
    let downloadAttr = '';
    const realCreate = HTMLDocument.prototype.createElement.bind(document);
    jest.spyOn(document, 'createElement').mockImplementation((tag) => {
      const el = realCreate(tag);
      if (tag === 'a') {
        el.click = jest.fn();
        Object.defineProperty(el, 'download', {
          set(v) { downloadAttr = v; },
          get() { return downloadAttr; },
          configurable: true,
        });
      }
      return el;
    });
    jest.spyOn(document.body, 'appendChild').mockImplementation(() => {});
    jest.spyOn(document.body, 'removeChild').mockImplementation(() => {});

    exportToCSV([makeSchool()], 'my-report');
    expect(downloadAttr).toBe('my-report.csv');
  });
});

// ─── syncFiltersToURL ─────────────────────────────────────────────────────────

describe('syncFiltersToURL', () => {
  let setSearchParams;
  let capturedParams;

  beforeEach(() => {
    setSearchParams = jest.fn((params) => { capturedParams = params; });
  });

  test('sets non-empty search param', () => {
    syncFiltersToURL({ search: 'alpha', schoolStatus: '', subscriptionStatus: '', plan: '', page: 1 }, setSearchParams);
    expect(capturedParams.get('search')).toBe('alpha');
  });

  test('omits empty search param', () => {
    syncFiltersToURL({ search: '', schoolStatus: '', subscriptionStatus: '', plan: '', page: 1 }, setSearchParams);
    expect(capturedParams.has('search')).toBe(false);
  });

  test('omits page param when page is 1', () => {
    syncFiltersToURL({ search: '', schoolStatus: '', subscriptionStatus: '', plan: '', page: 1 }, setSearchParams);
    expect(capturedParams.has('page')).toBe(false);
  });

  test('sets page param when page > 1', () => {
    syncFiltersToURL({ search: '', schoolStatus: '', subscriptionStatus: '', plan: '', page: 3 }, setSearchParams);
    expect(capturedParams.get('page')).toBe('3');
  });

  test('sets all non-empty fields', () => {
    syncFiltersToURL({
      search: 'test',
      schoolStatus: 'active',
      subscriptionStatus: 'active',
      plan: 'yearly',
      page: 2,
    }, setSearchParams);
    expect(capturedParams.get('search')).toBe('test');
    expect(capturedParams.get('schoolStatus')).toBe('active');
    expect(capturedParams.get('subscriptionStatus')).toBe('active');
    expect(capturedParams.get('plan')).toBe('yearly');
    expect(capturedParams.get('page')).toBe('2');
  });

  test('omits all params when all filters are empty/default', () => {
    syncFiltersToURL({ search: '', schoolStatus: '', subscriptionStatus: '', plan: '', page: 1 }, setSearchParams);
    expect([...capturedParams.keys()]).toHaveLength(0);
  });

  test('calls setSearchParams exactly once', () => {
    syncFiltersToURL(emptyFilters, setSearchParams);
    expect(setSearchParams).toHaveBeenCalledTimes(1);
  });
});
