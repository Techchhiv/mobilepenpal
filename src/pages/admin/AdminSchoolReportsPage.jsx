import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import MasterLayout from '../../masterLayout/MasterLayout';
import { useSchoolReports } from '../../hook/useSchoolReports';
import ReportFilters from '../../components/schoolReport/ReportFilters';
import ReportSummaryCards from '../../components/schoolReport/ReportSummaryCards';
import SchoolReportTable from '../../components/schoolReport/SchoolReportTable';
import SchoolDetailSidebar from '../../components/schoolReport/SchoolDetailSidebar';
import ExportCSVButton from '../../components/schoolReport/ExportCSVButton';
import { syncFiltersToURL } from '../../utils/schoolReportUtils';
import "../../assets/css/adminReport.css";

export default function AdminSchoolReportsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedSchoolId, setSelectedSchoolId] = useState(null);

  // Derive filter state from URL query params on every render (Req 1.3, 4.4)
  const filters = {
    search:             searchParams.get('search') ?? '',
    location:           searchParams.get('location') ?? '',
    subscriptionStatus: searchParams.get('subscriptionStatus') ?? '',
    subscriptionPlan:   searchParams.get('subscriptionPlan') ?? '',
    page:               Number(searchParams.get('page') ?? '1'),
  };

  const {
    pagedList,
    filteredList,
    selectedSchool,
    summaryStats,
    totalPages,
    loading,
  } = useSchoolReports(filters, selectedSchoolId);

  // On any filter change: merge partial update, reset page to 1, sync to URL (Req 3.10, 4.1)
  const handleFilterChange = (partial) => {
    const next = { ...filters, ...partial, page: 1 };
    syncFiltersToURL(next, setSearchParams);
  };

  // Page change does NOT reset to 1 — it sets the requested page
  const handlePageChange = (page) => {
    syncFiltersToURL({ ...filters, page }, setSearchParams);
  };

  // Row click sets selectedSchoolId (Req 6.1)
  const handleSelectSchool = (id) => {
    setSelectedSchoolId(id);
  };

  // Sidebar close clears selection (Req 6.4, 6.6)
  const handleCloseSidebar = () => {
    setSelectedSchoolId(null);
  };

  return (
    <MasterLayout>
      <div className="school-report-page">
      {/* Page header + export button */}
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h5 className="fw-semibold mb-0">School Reports</h5>
        <ExportCSVButton schools={filteredList} disabled={loading} />
      </div>

      {/* Summary stat cards — always over full unfiltered data */}
      <ReportSummaryCards summary={summaryStats} />

      {/* Filter controls */}
      <ReportFilters filters={filters} onChange={handleFilterChange} />

      {/* Table + optional sidebar side-by-side (Req 6.5) */}
      <div className="d-flex gap-3 mt-3">
        {/* Table shrinks to ~60% when sidebar is open (Req 6.5) */}
        <div style={{ flex: selectedSchool ? '0 0 60%' : '1', minWidth: 0 }}>
          <SchoolReportTable
            schools={pagedList}
            selectedId={selectedSchoolId}
            onSelect={handleSelectSchool}
            page={filters.page}
            totalPages={totalPages}
            onPageChange={handlePageChange}
            loading={loading}
          />
        </div>

        {/* Sidebar only rendered when a school is selected (Req 6.2, 6.6) */}
        {selectedSchool && (
          <div style={{ flex: '0 0 38%', minWidth: 0 }}>
            <SchoolDetailSidebar
              school={selectedSchool}
              onClose={handleCloseSidebar}
            />
          </div>
        )}
      </div>
      </div>
    </MasterLayout>
  );
}
