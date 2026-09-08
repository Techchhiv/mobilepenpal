import { useSearchParams } from 'react-router-dom';
import MasterLayout from '../../masterLayout/MasterLayout';
import { useSchoolReports } from '../../hook/useSchoolReports';
import ReportFilters from '../../components/schoolReport/ReportFilters';
import ReportSummaryCards from '../../components/schoolReport/ReportSummaryCards';
import SchoolReportTable from '../../components/schoolReport/SchoolReportTable';
import ExportCSVButton from '../../components/schoolReport/ExportCSVButton';
import AdminPageHeader from '../../components/admin/common/AdminPageHeader';
import AdminErrorState from '../../components/admin/common/AdminErrorState';
import { syncFiltersToURL } from '../../utils/schoolReportUtils';
import '../../assets/css/adminReport.css';

export default function AdminSchoolReportsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
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
    summaryStats,
    totalPages,
    totalItems,
    loading,
    error,
    refetch,
  } = useSchoolReports(filters);

  const handleFilterChange = (partial) => {
    const next = { ...filters, ...partial, page: 1 };
    syncFiltersToURL(next, setSearchParams);
  };

  const handlePageChange = (page) => {
    syncFiltersToURL({ ...filters, page }, setSearchParams);
  };

  return (
    <MasterLayout>
      <div className="school-report-page py-12">
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-16 mb-20">
          <AdminPageHeader
            title="School Reports"
            subtitle="Overview of registered institutions, enrollment capacity, and active subscription plans"
            className="mb-0"
          />
          <ExportCSVButton
            filters={filters}
            totalItems={totalItems}
            disabled={loading}
          />
        </div>

        <ReportSummaryCards summary={summaryStats} />
        <ReportFilters filters={filters} onChange={handleFilterChange} />

        {error && (
          <AdminErrorState
            title="Failed to Load School Reports"
            message={error}
            onRetry={refetch}
          />
        )}

        <div className="mt-20">
          <SchoolReportTable
            schools={pagedList}
            page={filters.page}
            totalPages={totalPages}
            totalItems={totalItems}
            onPageChange={handlePageChange}
            loading={loading}
          />
        </div>
      </div>
    </MasterLayout>
  );
}
