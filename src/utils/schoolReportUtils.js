/**
 * schoolReportUtils.js
 * Utility functions for the School Admin Report feature.
 */

// ─── filterSchools ────────────────────────────────────────────────────────────

/**
 * Filter an array of school objects based on the provided filter criteria.
 * Empty filter fields are treated as "match all".
 * Does NOT mutate the input array.
 *
 * @param {Array}  schools - Array of SchoolReport objects
 * @param {Object} filters - SchoolReportFilters object
 * @param {string} filters.search             - Case-insensitive match on schoolName, city, country, schoolCode
 * @param {string} filters.location           - Case-insensitive match on city, country, provinceOrState
 * @param {string} filters.subscriptionStatus - Exact match or empty string
 * @param {string} filters.subscriptionPlan   - Exact match or empty string
 * @returns {Array} Filtered subset of the input array (same order)
 */
export function filterSchools(schools, filters) {
  const { search = '', location = '', subscriptionStatus = '', subscriptionPlan = '' } = filters;

  const searchTerm   = search.trim().toLowerCase();
  const locationTerm = location.trim().toLowerCase();

  return schools.filter((school) => {
    // 1. Text search — schoolName, city, country, schoolCode
    if (searchTerm) {
      const matchesSearch =
        school.schoolName.toLowerCase().includes(searchTerm) ||
        school.city.toLowerCase().includes(searchTerm) ||
        school.country.toLowerCase().includes(searchTerm) ||
        school.schoolCode.toLowerCase().includes(searchTerm);
      if (!matchesSearch) return false;
    }

    // 2. Location filter — city, country, provinceOrState
    if (locationTerm) {
      const matchesLocation =
        school.city.toLowerCase().includes(locationTerm) ||
        school.country.toLowerCase().includes(locationTerm) ||
        school.provinceOrState.toLowerCase().includes(locationTerm);
      if (!matchesLocation) return false;
    }

    // 3. Subscription status — exact match
    if (subscriptionStatus && school.subscriptionStatus !== subscriptionStatus) {
      return false;
    }

    // 4. Subscription plan — exact match
    if (subscriptionPlan && school.subscriptionPlan !== subscriptionPlan) {
      return false;
    }

    return true;
  });
}

// ─── parsePaginatedPage ───────────────────────────────────────────────────────

/**
 * Return the slice of `list` corresponding to the given page.
 * Returns an empty array when `page` exceeds the total number of pages.
 * Does NOT mutate the input array.
 *
 * @param {Array}  list     - Full list to paginate
 * @param {number} page     - 1-based page number
 * @param {number} pageSize - Number of items per page
 * @returns {Array} Slice for the requested page
 */
export function parsePaginatedPage(list, page, pageSize) {
  const totalPages = Math.ceil(list.length / pageSize);
  if (page > totalPages || page < 1) return [];

  const start = (page - 1) * pageSize;
  return list.slice(start, start + pageSize);
}

// ─── exportToCSV ─────────────────────────────────────────────────────────────

/**
 * Escape a single CSV cell value.
 * Wraps in double-quotes if the value contains a comma, double-quote, or newline.
 * Doubles any existing double-quotes inside the value.
 *
 * @param {*} value - Raw cell value
 * @returns {string} Escaped CSV cell string
 */
function escapeCSVValue(value) {
  const str = value == null ? '' : String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

function pad2(value) {
  return String(value).padStart(2, '0');
}

function formatDateForExport(value, includeTime = false) {
  if (!value) return '';

  if (typeof value === 'string') {
    const normalized = value.trim().replace('T', ' ').replace(/Z$/, '');
    if (/^\d{4}-\d{2}-\d{2}/.test(normalized)) {
      return includeTime ? normalized.slice(0, 16) : normalized.slice(0, 10);
    }
    return normalized;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return String(value);
  }

  const yyyy = date.getFullYear();
  const mm = pad2(date.getMonth() + 1);
  const dd = pad2(date.getDate());

  if (!includeTime) {
    return `${yyyy}-${mm}-${dd}`;
  }

  const hh = pad2(date.getHours());
  const min = pad2(date.getMinutes());
  return `${yyyy}-${mm}-${dd} ${hh}:${min}`;
}

function asExcelText(value) {
  if (!value) return '';
  return `="${String(value).replace(/"/g, '""')}"`;
}

/**
 * Serialize an array of school objects to CSV and trigger a browser download.
 * Does NOT mutate the input array.
 *
 * @param {Array}  schools  - Array of SchoolReport objects to export
 * @param {string} filename - Base filename (without extension)
 */
export function exportToCSV(schools, filename) {
  const headers = [
    'School Name', 'School Key', 'Admin Email', 'School Status',
    'Students', 'Active Students',
    'Teachers', 'Active Teachers',
    'Plan', 'Subscription Status',
    'Sub Start', 'Sub End',
    'Created', 'Updated',
  ];

  const rows = schools.map((school) => [
    school.schoolName,
    school.schoolCode,
    school.schoolEmail,
    school.status,
    school.totalStudents,
    school.activeStudents,
    school.totalTeachers,
    school.activeTeachers,
    school.subscriptionPlan,
    school.subscriptionStatus,
    asExcelText(formatDateForExport(school.subscriptionStartDate)),
    asExcelText(formatDateForExport(school.subscriptionEndDate)),
    asExcelText(formatDateForExport(school.createdAt, true)),
    asExcelText(formatDateForExport(school.lastUpdatedAt, true)),
  ].map(escapeCSVValue).join(','));

  const csvContent = '\uFEFF' + [headers.map(escapeCSVValue).join(','), ...rows].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href     = url;
  link.download = filename.endsWith('.csv') ? filename : `${filename}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// ─── syncFiltersToURL ─────────────────────────────────────────────────────────

/**
 * Write the current filter state to the URL query string.
 * Empty / default values are omitted for clean URLs.
 * `page` is omitted when it equals 1.
 *
 * @param {Object}   filters          - SchoolReportFilters object
 * @param {Function} setSearchParams  - React Router's setSearchParams function
 */
export function syncFiltersToURL(filters, setSearchParams) {
  const params = new URLSearchParams();

  if (filters.search)             params.set('search',             filters.search);
  if (filters.schoolStatus)       params.set('schoolStatus',       filters.schoolStatus);
  if (filters.subscriptionStatus) params.set('subscriptionStatus', filters.subscriptionStatus);
  if (filters.plan)               params.set('plan',               filters.plan);
  if (filters.page && filters.page > 1) params.set('page',         String(filters.page));

  setSearchParams(params);
}
