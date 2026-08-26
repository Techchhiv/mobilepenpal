import SchoolReportRow from './SchoolReportRow';

export default function SchoolReportTable({
  schools = [],
  page,
  totalPages,
  totalItems = 0,
  onPageChange,
  loading,
}) {
  const pageNumbers = buildPageNumbers(page, totalPages);

  return (
    <div className="school-report-table overflow-hidden ">
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

      {!loading && totalPages > 1 && (
        <div className="card-footer border-top bg-base py-16 px-24">
          <nav aria-label="School report pagination">
            <ul className="pagination pagination-sm justify-content-center mb-0">
              <li className={`page-item${page <= 1 ? ' disabled' : ''}`}>
                <button
                  className="page-link"
                  onClick={() => onPageChange(page - 1)}
                  disabled={page <= 1}
                  aria-label="Previous page"
                >
                  &laquo;
                </button>
              </li>

              {pageNumbers.map((num, idx) =>
                num === '...' ? (
                  <li key={`ellipsis-${idx}`} className="page-item disabled">
                    <span className="page-link">...</span>
                  </li>
                ) : (
                  <li
                    key={num}
                    className={`page-item${num === page ? ' active' : ''}`}
                  >
                    <button
                      className="page-link"
                      onClick={() => num !== page && onPageChange(num)}
                      aria-current={num === page ? 'page' : undefined}
                    >
                      {num}
                    </button>
                  </li>
                )
              )}

              <li className={`page-item${page >= totalPages ? ' disabled' : ''}`}>
                <button
                  className="page-link"
                  onClick={() => onPageChange(page + 1)}
                  disabled={page >= totalPages}
                  aria-label="Next page"
                >
                  &raquo;
                </button>
              </li>
            </ul>
          </nav>
        </div>
      )}
    </div>
  );
}

function buildPageNumbers(current, total) {
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
