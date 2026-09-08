import React from 'react';
import SchoolReportRow from './SchoolReportRow';
import AdminPagination from '../admin/common/AdminPagination';

export default function SchoolReportTable({
  schools = [],
  page,
  totalPages,
  totalItems = 0,
  onPageChange,
  loading,
}) {
  return (
    <div className="school-report-table overflow-hidden">
      <div className="card-header border-bottom bg-base py-16 px-24 d-flex align-items-center justify-content-between">
        <h6 className="fw-semibold mb-0">School List</h6>
        {!loading && (
          <span className="badge text-sm fw-semibold bg-primary-focus text-primary-600 px-12 py-6 radius-4">
            {totalItems} {totalItems === 1 ? 'school' : 'schools'}
          </span>
        )}
      </div>

      <div className="card-body p-0">
        <div className="table-responsive scroll-sm school-report-table-responsive">
          <table className="table sm-table mb-0 school-report-data-table">
            <thead className="school-list-head">
              <tr>
                <th scope="col">School Name</th>
                <th scope="col">School Key</th>
                <th scope="col">Admin Email</th>
                <th scope="col">Students</th>
                <th scope="col">Teachers</th>
                <th scope="col">Plan</th>
                <th scope="col">Subscription</th>
                <th scope="col">Updated</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={8} className="text-center py-5">
                    <div
                      className="spinner-border text-primary"
                      role="status"
                      aria-label="Loading"
                    >
                      <span className="visually-hidden">Loading...</span>
                    </div>
                  </td>
                </tr>
              ) : schools.length === 0 ? (
                <tr>
                  <td colSpan={8} className="text-center text-secondary-light py-40">
                    <div className="d-flex flex-column align-items-center gap-2">
                      No schools found.
                    </div>
                  </td>
                </tr>
              ) : (
                schools.map((school) => (
                  <SchoolReportRow
                    key={school.schoolId}
                    school={school}
                  />
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {!loading && totalItems > 0 && (
        <div className="card-footer border-top bg-base py-14 px-24 d-flex align-items-center justify-content-between flex-wrap gap-12">
          <div className="text-secondary-light text-xs font-semibold">
            Showing {(page - 1) * 10 + 1}–{Math.min(page * 10, totalItems)} of {totalItems} entries
          </div>
          {totalPages > 1 && (
            <div className="ms-auto">
              <AdminPagination
                page={page}
                totalPages={totalPages}
                onPageChange={onPageChange}
              />
            </div>
          )}
        </div>
      )}
    </div>
  );
}
