# Requirements Document

## Introduction

The School Admin Report feature provides a frontend-only admin reporting dashboard within the School Management SaaS platform. It allows administrators to view, search, filter, and export detailed information about all managed schools. The page is built with static mock data and structured so a real API call can replace the mock with minimal changes.

## Glossary

- **AdminSchoolReportsPage**: The top-level page component rendered at `/admin/reports`
- **ReportFilters**: The UI component that renders search and filter controls
- **ReportSummaryCards**: The UI component that displays four aggregate stat cards
- **SchoolReportTable**: The UI component that renders the paginated table of schools
- **SchoolReportRow**: A single row in the school report table
- **SchoolDetailSidebar**: The right-side panel that shows full details for a selected school
- **ExportCSVButton**: The button component that triggers a CSV file download
- **useSchoolReports**: The React hook that manages filter, pagination, and selection logic
- **filterSchools**: The utility function that applies all active filters to the school list
- **exportToCSV**: The utility function that serializes school data and triggers a browser download
- **syncFiltersToURL**: The utility function that writes current filter state to URL query params
- **SchoolReport**: The data object representing a single school and all its associated metrics
- **SchoolReportFilters**: The object holding the current values of all active filters
- **SchoolReportSummary**: The object holding aggregate counts across the unfiltered school list
- **PAGE_SIZE**: The fixed number of schools displayed per table page
- **filteredList**: The array of schools after all active filters have been applied, before pagination
- **pagedList**: The slice of `filteredList` corresponding to the current page

---

## Requirements

### Requirement 1: Page Access and Routing

**User Story:** As an administrator, I want to access the school reports page through a protected route, so that only authorized users can view school data.

#### Acceptance Criteria

1. WHEN a user navigates to `/admin/reports`, THE AdminSchoolReportsPage SHALL render inside the existing `MasterLayout` admin shell.
2. WHEN a user without the `menu.reports` permission navigates to `/admin/reports`, THE Gate component SHALL prevent access to the AdminSchoolReportsPage.
3. THE AdminSchoolReportsPage SHALL read initial filter values from URL query parameters (`search`, `location`, `subscriptionStatus`, `subscriptionPlan`, `page`) on mount.

---

### Requirement 2: Summary Statistics Display

**User Story:** As an administrator, I want to see aggregate statistics at the top of the page, so that I can quickly understand the overall state of all managed schools.

#### Acceptance Criteria

1. THE ReportSummaryCards SHALL display four stat cards: total schools, active schools, total students, and total teachers.
2. THE ReportSummaryCards SHALL derive all displayed counts from the full unfiltered `schools` array, not from `filteredList`.
3. WHEN the school data is loaded, THE ReportSummaryCards SHALL reflect the current counts without requiring a page reload.

---

### Requirement 3: Search and Filtering

**User Story:** As an administrator, I want to search and filter the school list by name, location, subscription status, and plan, so that I can quickly find specific schools.

#### Acceptance Criteria

1. THE ReportFilters SHALL render a text input for free-text search, a text input for location, a dropdown for subscription status, and a dropdown for subscription plan.
2. WHEN a user types in the search input, THE ReportFilters SHALL debounce the input by 300 ms before calling `onChange`.
3. WHEN a user types in the location input, THE ReportFilters SHALL debounce the input by 300 ms before calling `onChange`.
4. WHEN the search filter is non-empty, THE filterSchools function SHALL return only schools whose `schoolName`, `city`, `country`, or `schoolCode` contains the search term (case-insensitive).
5. WHEN the location filter is non-empty, THE filterSchools function SHALL return only schools whose `city`, `country`, or `provinceOrState` contains the location term (case-insensitive).
6. WHEN the subscriptionStatus filter is non-empty, THE filterSchools function SHALL return only schools whose `subscriptionStatus` exactly matches the selected value.
7. WHEN the subscriptionPlan filter is non-empty, THE filterSchools function SHALL return only schools whose `subscriptionPlan` exactly matches the selected value.
8. WHEN multiple filters are active simultaneously, THE filterSchools function SHALL return only schools that satisfy all active filter criteria.
9. WHEN all filter fields are empty, THE filterSchools function SHALL return the full unmodified `schools` array.
10. WHEN any filter value changes, THE AdminSchoolReportsPage SHALL reset the page number to 1.

---

### Requirement 4: URL State Synchronization

**User Story:** As an administrator, I want filter state to be reflected in the URL, so that I can share or bookmark a filtered view.

#### Acceptance Criteria

1. WHEN any filter value changes, THE syncFiltersToURL function SHALL update the URL query string to reflect the current filter state.
2. WHEN a filter field is empty or at its default value, THE syncFiltersToURL function SHALL omit that parameter from the URL query string.
3. WHEN the current page is 1, THE syncFiltersToURL function SHALL omit the `page` parameter from the URL query string.
4. WHEN a user loads the page with query parameters present in the URL, THE AdminSchoolReportsPage SHALL initialize filters from those query parameters.

---

### Requirement 5: Paginated School Table

**User Story:** As an administrator, I want to browse schools in a paginated table, so that I can navigate large lists without performance issues.

#### Acceptance Criteria

1. THE SchoolReportTable SHALL display columns for School Name, Location, Total Students, Total Teachers, Subscription Plan, Subscription Status, Created Date, and Last Activity.
2. THE SchoolReportTable SHALL render one SchoolReportRow per school in `pagedList`.
3. THE SchoolReportTable SHALL render pagination controls that allow navigating between pages.
4. WHEN the current page exceeds the total number of pages, THE useSchoolReports hook SHALL return an empty `pagedList`.
5. THE pagedList SHALL contain no more than PAGE_SIZE schools for any valid page and filter combination.
6. THE SchoolReportTable SHALL display a loading indicator WHILE the `loading` state is true.

---

### Requirement 6: School Selection and Detail Sidebar

**User Story:** As an administrator, I want to click a school row to view its full details in a sidebar, so that I can inspect all school information without leaving the page.

#### Acceptance Criteria

1. WHEN a user clicks a SchoolReportRow, THE AdminSchoolReportsPage SHALL set `selectedSchoolId` to that school's `schoolId`.
2. WHEN `selectedSchoolId` is set, THE SchoolDetailSidebar SHALL be rendered with the corresponding SchoolReport.
3. THE SchoolDetailSidebar SHALL display seven sections: School Overview, Location, Contact Information, Student Statistics, Teacher Statistics, Subscription Details, and System Usage Metrics.
4. WHEN a user clicks the close control on the SchoolDetailSidebar, THE AdminSchoolReportsPage SHALL set `selectedSchoolId` to null and hide the sidebar.
5. WHEN the SchoolDetailSidebar is visible, THE SchoolReportTable SHALL reduce its width to approximately 60% of the content area.
6. WHEN `selectedSchoolId` is null, THE SchoolDetailSidebar SHALL NOT be rendered.
7. THE selectedSchool value returned by useSchoolReports SHALL always be either null or an element of the full unfiltered `schools` array.

---

### Requirement 7: CSV Export

**User Story:** As an administrator, I want to export the currently filtered school list to a CSV file, so that I can analyze or share the data outside the application.

#### Acceptance Criteria

1. THE ExportCSVButton SHALL display the count of records that will be exported.
2. WHEN a user clicks the ExportCSVButton, THE exportToCSV function SHALL trigger a browser file download of a `.csv` file named `school-report.csv`.
3. THE exportToCSV function SHALL produce a CSV with a header row followed by exactly one data row per school in the input array.
4. THE CSV header row SHALL include: School Name, School Code, Type, Status, Country, City, Province, Total Students, Active Students, Total Teachers, Teacher-Student Ratio, Subscription Plan, Subscription Status, Billing Cycle, Payment Status, Subscription Start, Subscription End, Created At, Last Login, Active Users.
5. THE exportToCSV function SHALL NOT mutate the input `schools` array.
6. WHEN the `loading` state is true, THE ExportCSVButton SHALL be disabled.

---

### Requirement 8: Mock Data and API Integration Seam

**User Story:** As a developer, I want the data layer to be isolated behind a single async function, so that switching from mock data to a real API requires changing only one function.

#### Acceptance Criteria

1. THE useSchoolReports hook SHALL load school data by calling an internal `fetchSchools` async function.
2. THE mockSchoolReports data file SHALL contain at least 20 school objects conforming to the SchoolReport interface.
3. WHEN the `fetchSchools` function is replaced with an API call, THE useSchoolReports hook and all other components SHALL require no other changes.

---

### Requirement 9: Filter Pipeline Correctness

**User Story:** As a developer, I want the filter pipeline to be correct and non-destructive, so that the original data is never modified and results are always consistent.

#### Acceptance Criteria

1. THE filterSchools function SHALL return an array that is a subset of the input `schools` array.
2. THE filterSchools function SHALL NOT mutate the input `schools` array.
3. THE filterSchools function SHALL preserve the relative order of schools from the input array.
4. THE filteredList returned by useSchoolReports SHALL always be a subset of the full unfiltered `schools` array.
5. THE summaryStats.totalSchools value SHALL equal the length of the full unfiltered `schools` array regardless of active filters.
