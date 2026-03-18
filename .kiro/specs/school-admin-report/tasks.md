# Implementation Plan: School Admin Report

## Overview

Build a frontend-only admin reporting dashboard at `/admin/reports`. The work proceeds in layers: data → utilities → hook → components → page wiring → routing. Each step is immediately usable by the next.

## Tasks

- [x] 1. Create mock data file
  - Create `src/data/mockSchoolReports.js` exporting an array of at least 20 school objects
  - Each object must include all fields described in the design: basic info, location, contact, students, teachers, infrastructure (optional fields), subscription, and system usage
  - Cover a variety of `subscriptionPlan`, `subscriptionStatus`, `schoolType`, and `country` values so filters can be meaningfully tested
  - _Requirements: 8.2_

- [x] 2. Implement utility functions in `src/utils/schoolReportUtils.js`
  - [x] 2.1 Implement `filterSchools(schools, filters)`
    - Apply search (case-insensitive match on `schoolName`, `city`, `country`, `schoolCode`), location (match on `city`, `country`, `provinceOrState`), `subscriptionStatus` exact match, `subscriptionPlan` exact match
    - Empty filter fields must be treated as "match all"; do not mutate the input array
    - _Requirements: 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 9.1, 9.2, 9.3_

  - [ ]* 2.2 Write unit tests for `filterSchools`
    - Test each filter in isolation and all filters combined
    - Test empty filters return full array; test case-insensitivity; test no mutation
    - _Requirements: 3.4–3.9, 9.1–9.3_

  - [x] 2.3 Implement `parsePaginatedPage(list, page, pageSize)`
    - Return the correct slice; return empty array when page exceeds total pages; do not mutate input
    - _Requirements: 5.4, 5.5_

  - [ ]* 2.4 Write unit tests for `parsePaginatedPage`
    - Test first page, last page, out-of-range page, and single-item list
    - _Requirements: 5.4, 5.5_

  - [x] 2.5 Implement `exportToCSV(schools, filename)`
    - Build header row + one data row per school using the 20 columns listed in the design
    - Escape values that contain commas or quotes; trigger browser download via Blob + anchor click; do not mutate input array
    - _Requirements: 7.2, 7.3, 7.4, 7.5_

  - [ ]* 2.6 Write unit tests for `exportToCSV`
    - Test that output has exactly `schools.length + 1` lines; test header columns; test no mutation
    - _Requirements: 7.3, 7.4, 7.5_

  - [x] 2.7 Implement `syncFiltersToURL(filters, setSearchParams)`
    - Set only non-empty / non-default params; omit `page` when it equals 1
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 2.8 Write unit tests for `syncFiltersToURL`
    - Test that empty fields are omitted; test page=1 is omitted; test all fields set when non-empty
    - _Requirements: 4.1–4.3_

- [x] 3. Implement `useSchoolReports` hook in `src/hook/useSchoolReports.js`
  - Load schools via an internal `fetchSchools` async function that returns `mockSchoolReports` (API-swap seam)
  - Derive `filteredList` by calling `filterSchools`; derive `pagedList` by calling `parsePaginatedPage`
  - Compute `summaryStats` (totalSchools, activeSchools, totalStudents, totalTeachers) from the full unfiltered array
  - Compute `totalPages = Math.ceil(filteredList.length / PAGE_SIZE)` where `PAGE_SIZE = 10`
  - Manage `selectedSchool` — always null or an element of the full schools array
  - Expose `{ filteredList, pagedList, selectedSchool, summaryStats, totalPages, loading, selectSchool }`
  - _Requirements: 5.4, 5.5, 6.7, 8.1, 8.3, 9.4, 9.5_

- [x] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Build `ReportSummaryCards` component (`src/components/schoolReport/ReportSummaryCards.jsx`)
  - Accept `summary` prop `{ totalSchools, activeSchools, totalStudents, totalTeachers }`
  - Render four stat cards using the Bootstrap gradient card style from `SchoolDashboard` (`bg-gradient-start-1` through `bg-gradient-start-4`, `@iconify/react` icons)
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 6. Build `ReportFilters` component (`src/components/schoolReport/ReportFilters.jsx`)
  - Accept `filters` and `onChange` props
  - Render: search text input, location text input, subscriptionStatus `<select>`, subscriptionPlan `<select>`
  - Debounce search and location inputs by 300 ms before calling `onChange`; dropdowns call `onChange` immediately
  - _Requirements: 3.1, 3.2, 3.3, 3.10_

- [x] 7. Build `SchoolReportRow` component (`src/components/schoolReport/SchoolReportRow.jsx`)
  - Accept `school`, `isSelected`, `onSelect` props
  - Render one `<tr>` with columns: School Name, Location (city + country), Total Students, Total Teachers, Subscription Plan, Subscription Status, Created Date, Last Activity
  - Apply a highlight class when `isSelected` is true; call `onSelect` on row click
  - _Requirements: 5.1, 6.1_

- [x] 8. Build `SchoolReportTable` component (`src/components/schoolReport/SchoolReportTable.jsx`)
  - Accept `schools`, `selectedId`, `onSelect`, `page`, `totalPages`, `onPageChange`, `loading` props
  - Render table header + one `SchoolReportRow` per school; show a loading spinner (Bootstrap or `LoadingSpinner`) while `loading` is true
  - Render pagination controls (prev / numbered pages / next) that call `onPageChange`; do not use DataTables
  - _Requirements: 5.1, 5.2, 5.3, 5.6_

- [x] 9. Build `SchoolDetailSidebar` component (`src/components/schoolReport/SchoolDetailSidebar.jsx`)
  - Accept `school` (or null) and `onClose` props; render nothing when `school` is null
  - Display seven sections: School Overview, Location, Contact Information, Student Statistics, Teacher Statistics, Subscription Details, System Usage Metrics
  - Include a close button that calls `onClose`
  - _Requirements: 6.2, 6.3, 6.4, 6.6_

- [x] 10. Build `ExportCSVButton` component (`src/components/schoolReport/ExportCSVButton.jsx`)
  - Accept `schools` and `disabled` props
  - Show the count of records to be exported in the button label
  - Call `exportToCSV(schools, 'school-report')` on click; disable the button when `disabled` is true
  - _Requirements: 7.1, 7.2, 7.6_

- [x] 11. Build `AdminSchoolReportsPage` (`src/pages/admin/AdminSchoolReportsPage.jsx`)
  - Read filter values from URL query params via `useSearchParams` on mount
  - Manage `selectedSchoolId` in local state
  - Call `useSchoolReports(filters, selectedSchoolId)` to get derived data
  - On any filter change call `syncFiltersToURL` and reset page to 1
  - Compose: page header + `ExportCSVButton`, `ReportSummaryCards`, `ReportFilters`, side-by-side `SchoolReportTable` (full width or ~60%) and `SchoolDetailSidebar` (~38%) inside `MasterLayout`
  - _Requirements: 1.1, 1.3, 3.10, 4.1, 4.4, 5.5, 6.1, 6.4, 6.5, 6.6_

- [x] 12. Wire route in `src/App.js`
  - Import `AdminSchoolReportsPage`
  - Add a `<Route element={<Gate anyPerm={["menu.reports"]} />}>` block containing `<Route path="/admin/reports" element={<AdminSchoolReportsPage />} />`
  - _Requirements: 1.1, 1.2_

- [x] 13. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- `PAGE_SIZE` is defined as a constant (10) inside `useSchoolReports.js`
- No new npm packages are needed — all dependencies are already in `package.json`
- The `types/` folder is intentionally omitted; this is a plain JS project
- When the real API is ready, only the `fetchSchools` function inside `useSchoolReports.js` needs to change
