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
import '../../assets/css/adminReport.css';

export default function AdminSchoolReportsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedSchoolId, setSelectedSchoolId] = useState(null);
  const currentPage = Number(searchParams.get('page') ?? '1');

  const filters = {
    search: searchParams.get('search') ?? '',
    schoolStatus: searchParams.get('schoolStatus') ?? '',
    subscriptionStatus: searchParams.get('subscriptionStatus') ?? '',
    plan: searchParams.get('plan') ?? '',
    page: Number.isFinite(currentPage) && currentPage > 0 ? currentPage : 1,
  };

  const {
    pagedList,
    filteredList,
    selectedSchool,
    summaryStats,
    totalPages,
    totalItems,
    loading,
    selectedSchoolLoading,
    error,
  } = useSchoolReports(filters, selectedSchoolId);

  const handleFilterChange = (partial) => {
    const next = { ...filters, ...partial, page: 1 };
    syncFiltersToURL(next, setSearchParams);
  };

  const handlePageChange = (page) => {
    syncFiltersToURL({ ...filters, page }, setSearchParams);
  };

  const handleSelectSchool = (id) => {
    setSelectedSchoolId(id);
  };

  const handleCloseSidebar = () => {
    setSelectedSchoolId(null);
  };

  const isSidebarOpen = Boolean(selectedSchoolId);

  return (
    <MasterLayout>
      <div className="school-report-page">
        <div className="d-flex justify-content-between align-items-center mb-3">
          <h5 className="fw-semibold mb-0">School Reports</h5>
          <ExportCSVButton
            schools={filteredList}
            disabled={loading || filteredList.length === 0}
          />
        </div>

        <ReportSummaryCards summary={summaryStats} />
        <ReportFilters filters={filters} onChange={handleFilterChange} />

        {error && (
          <div className="alert alert-danger mt-3 mb-0" role="alert">
            {error}
          </div>
        )}

        <div className="d-flex gap-3 mt-3">
          <div style={{ flex: isSidebarOpen ? '0 0 60%' : '1', minWidth: 0 }}>
            <SchoolReportTable
              schools={pagedList}
              selectedId={selectedSchoolId}
              onSelect={handleSelectSchool}
              page={filters.page}
              totalPages={totalPages}
              totalItems={totalItems}
              onPageChange={handlePageChange}
              loading={loading}
            />
          </div>

          {isSidebarOpen && (
            <div style={{ flex: '0 0 38%', minWidth: 0 }}>
              <SchoolDetailSidebar
                school={selectedSchool}
                loading={selectedSchoolLoading}
                onClose={handleCloseSidebar}
              />
            </div>
          )}
        </div>
      </div>
    </MasterLayout>
  );
}
