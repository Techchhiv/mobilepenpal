import React from 'react';
import { Icon } from '@iconify/react';
import ClientRow from './ClientRow';

export default function ClientTable({
  schools = [],
  loading = false,
  error = '',
  isFiltered = false,
  pagination = {},
  onPageChange,
  onClearFilters,
  onRetry,
  onToggleStatus,
  onEditSchool,
  onDeleteSchool,
}) {
  const currentPage = pagination.current_page || 1;
  const lastPage = pagination.last_page || 1;
  const totalItems = pagination.total || 0;
  const from = pagination.from || (schools.length > 0 ? 1 : 0);
  const to = pagination.to || schools.length;

  const pageNumbers = buildPagination(currentPage, lastPage);

  return (
    <div className="card client-table-card">
      <div className="card-header border-bottom bg-base py-16 px-20 d-flex align-items-center justify-content-between flex-wrap gap-12">
        <div className="d-flex align-items-center gap-8">
          <Icon icon="mdi:domain" className="text-primary-600 text-lg" />
          <h6 className="fw-semibold mb-0 text-sm">Client List</h6>
        </div>
        {!loading && !error && (
          <span className="badge text-xs fw-semibold bg-primary-focus text-primary-600 px-12 py-6 radius-4">
            {totalItems} {totalItems === 1 ? 'client' : 'clients'}
          </span>
        )}
      </div>

      <div className="card-body p-0">
        <div className="table-responsive client-table-responsive">
          <table className="table client-table">
            <thead>
              <tr>
                <th scope="col" style={{ minWidth: 220 }}>School / Client</th>
                <th scope="col" style={{ minWidth: 130 }}>School Key</th>
                <th scope="col" style={{ minWidth: 160 }}>Admin Email</th>
                <th scope="col" style={{ minWidth: 110 }}>School Status</th>
                <th scope="col" style={{ minWidth: 110 }}>Subscription</th>
                <th scope="col" style={{ minWidth: 130 }}>Sub Status</th>
                <th scope="col" style={{ minWidth: 120 }}>End Date</th>
                <th scope="col" style={{ minWidth: 90 }}>Students</th>
                <th scope="col" style={{ minWidth: 90 }}>Teachers</th>
                <th scope="col" className="text-end" style={{ width: 80 }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {/* 1. Loading State */}
              {loading ? (
                Array.from({ length: 5 }).map((_, idx) => (
                  <tr key={`skeleton-${idx}`}>
                    <td>
                      <div className="d-flex align-items-center gap-12">
                        <div
                          className="placeholder rounded"
                          style={{ width: '40px', height: '40px' }}
                        />
                        <div className="flex-grow-1">
                          <span className="placeholder col-8 d-block mb-1" />
                          <span className="placeholder col-4 d-block" />
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="placeholder col-8 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-10 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-6 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-6 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-7 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-8 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-4 d-block" />
                    </td>
                    <td>
                      <span className="placeholder col-4 d-block" />
                    </td>
                    <td className="text-end">
                      <span
                        className="placeholder rounded"
                        style={{ width: '32px', height: '32px' }}
                      />
                    </td>
                  </tr>
                ))
              ) : error ? (
                /* 2. Error State */
                <tr>
                  <td colSpan={10} className="p-0">
                    <div className="client-error-state">
                      <Icon
                        icon="mdi:alert-circle-outline"
                        className="text-danger-main text-4xl mb-8 d-block mx-auto"
                      />
                      <span className="fw-semibold text-danger text-sm d-block mb-4">
                        Unable to load clients.
                      </span>
                      <span className="text-secondary-light text-xs d-block mb-14">
                        {error}
                      </span>
                      {onRetry && (
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-primary radius-8 px-14 py-6 text-xs fw-semibold d-inline-flex align-items-center gap-6"
                          onClick={onRetry}
                        >
                          <Icon icon="mdi:refresh" />
                          Try Again
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : schools.length === 0 ? (
                /* 3. Empty State */
                <tr>
                  <td colSpan={10} className="p-0">
                    <div className="client-empty-state">
                      <span className="fw-semibold text-secondary text-sm d-block mb-4">
                        {isFiltered
                          ? 'No clients match the selected filters.'
                          : 'No clients found.'}
                      </span>
                      <span className="text-secondary-light text-xs d-block mb-14">
                        {isFiltered
                          ? 'Try adjusting or clearing your search and filters to see more results.'
                          : 'Get started by creating your first school client.'}
                      </span>
                      {isFiltered && onClearFilters && (
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-primary radius-8 px-14 py-6 text-xs fw-semibold d-inline-flex align-items-center gap-6"
                          onClick={onClearFilters}
                        >
                          <Icon icon="mdi:filter-remove-outline" />
                          Clear Filters
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                /* 4. Data Rows */
                schools.map((school) => (
                  <ClientRow
                    key={school.id}
                    school={school}
                    onToggleStatus={onToggleStatus}
                    onEditSchool={onEditSchool}
                    onDeleteSchool={onDeleteSchool}
                  />
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination Footer */}
      {!loading && !error && totalItems > 0 && (
        <div className="card-footer border-top bg-base py-14 px-20 d-flex align-items-center justify-content-between flex-wrap gap-12">
          <div className="text-xs text-secondary-light">
            Showing <strong className="text-primary-light">{from}</strong> to{' '}
            <strong className="text-primary-light">{to}</strong> of{' '}
            <strong className="text-primary-light">{totalItems}</strong> clients
          </div>

          {lastPage > 1 && (
            <nav aria-label="Client pagination">
              <ul className="pagination pagination-sm mb-0">
                {/* Previous */}
                <li
                  className={`page-item ${
                    currentPage <= 1 ? 'disabled' : ''
                  }`}
                >
                  <button
                    className="page-link d-inline-flex align-items-center gap-4"
                    onClick={() => onPageChange(currentPage - 1)}
                    disabled={currentPage <= 1}
                    aria-label="Previous"
                  >
                    <Icon icon="mdi:chevron-left" />
                    <span>Previous</span>
                  </button>
                </li>

                {/* Page numbers */}
                {pageNumbers.map((num, idx) =>
                  num === '...' ? (
                    <li
                      key={`ellipsis-${idx}`}
                      className="page-item disabled"
                    >
                      <span className="page-link">...</span>
                    </li>
                  ) : (
                    <li
                      key={num}
                      className={`page-item ${
                        num === currentPage ? 'active' : ''
                      }`}
                    >
                      <button
                        className="page-link"
                        onClick={() =>
                          num !== currentPage && onPageChange(num)
                        }
                        aria-current={num === currentPage ? 'page' : undefined}
                      >
                        {num}
                      </button>
                    </li>
                  )
                )}

                {/* Next */}
                <li
                  className={`page-item ${
                    currentPage >= lastPage ? 'disabled' : ''
                  }`}
                >
                  <button
                    className="page-link d-inline-flex align-items-center gap-4"
                    onClick={() => onPageChange(currentPage + 1)}
                    disabled={currentPage >= lastPage}
                    aria-label="Next"
                  >
                    <span>Next</span>
                    <Icon icon="mdi:chevron-right" />
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      )}
    </div>
  );
}

function buildPagination(current, total) {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  const pages = new Set([1, total, current, current - 1, current + 1]);
  const sorted = [...pages]
    .filter((p) => p >= 1 && p <= total)
    .sort((a, b) => a - b);

  const result = [];
  for (let i = 0; i < sorted.length; i++) {
    if (i > 0 && sorted[i] - sorted[i - 1] > 1) {
      result.push('...');
    }
    result.push(sorted[i]);
  }
  return result;
}
