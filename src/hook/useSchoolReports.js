import { useState, useEffect, useMemo } from 'react';
import { mockSchoolReports } from '../data/mockSchoolReports';
import { filterSchools, parsePaginatedPage } from '../utils/schoolReportUtils';

const PAGE_SIZE = 10;

/**
 * Internal data-fetch seam.
 * Swap this function for an API call when the backend is ready —
 * no other code needs to change (Req 8.1, 8.3).
 *
 * @returns {Promise<Array>} Resolves to the full array of SchoolReport objects
 */
async function fetchSchools() {
  return mockSchoolReports;
  // Future API swap:
  // const { data } = await API.get('/admin/school-reports');
  // return data;
}

/**
 * useSchoolReports
 *
 * Manages school data loading, filtering, pagination, selection, and summary stats.
 *
 * @param {Object} filters - SchoolReportFilters
 * @param {string|null} selectedSchoolId - ID of the currently selected school
 * @returns {{ filteredList, pagedList, selectedSchool, summaryStats, totalPages, loading, selectSchool }}
 */
export function useSchoolReports(filters, selectedSchoolId) {
  const [schools, setSchools] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState(selectedSchoolId ?? null);

  // Keep internal selectedId in sync when the caller changes selectedSchoolId
  useEffect(() => {
    setSelectedId(selectedSchoolId ?? null);
  }, [selectedSchoolId]);

  // Load schools once on mount (Req 8.1)
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchSchools().then((data) => {
      if (!cancelled) {
        setSchools(data);
        setLoading(false);
      }
    });
    return () => { cancelled = true; };
  }, []);

  // Derive filteredList — subset of full schools array (Req 9.4)
  const filteredList = useMemo(
    () => filterSchools(schools, filters),
    [schools, filters]
  );

  // Compute totalPages (Req 5.4, 5.5)
  const totalPages = useMemo(
    () => Math.ceil(filteredList.length / PAGE_SIZE),
    [filteredList]
  );

  // Derive pagedList — at most PAGE_SIZE items (Req 5.4, 5.5)
  const pagedList = useMemo(
    () => parsePaginatedPage(filteredList, filters.page ?? 1, PAGE_SIZE),
    [filteredList, filters.page]
  );

  // selectedSchool is always null or an element of the full unfiltered array (Req 6.7)
  const selectedSchool = useMemo(
    () => (selectedId ? (schools.find((s) => s.schoolId === selectedId) ?? null) : null),
    [schools, selectedId]
  );

  // summaryStats computed over the full unfiltered array (Req 9.5)
  const summaryStats = useMemo(() => ({
    totalSchools: schools.length,
    activeSchools: schools.filter((s) => s.status === 'active').length,
    totalStudents: schools.reduce((sum, s) => sum + (s.totalStudents ?? 0), 0),
    totalTeachers: schools.reduce((sum, s) => sum + (s.totalTeachers ?? 0), 0),
  }), [schools]);

  /** Select or deselect a school by ID */
  const selectSchool = (id) => setSelectedId(id ?? null);

  return {
    filteredList,
    pagedList,
    selectedSchool,
    summaryStats,
    totalPages,
    loading,
    selectSchool,
  };
}

export default useSchoolReports;
