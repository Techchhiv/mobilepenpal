import React from "react";
import "../../../assets/css/auditLog.css";

/**
 * Shared Admin Pagination Component
 * Follows the exact AuditLogPage pagination model & UI.
 *
 * Props:
 * - page: number (current page, 1-indexed)
 * - totalPages: number (total number of pages)
 * - onPageChange: (newPage: number) => void
 * - totalItems: number (optional, total record count)
 * - from: number (optional, record start index)
 * - to: number (optional, record end index)
 */
export default function AdminPagination({
  page = 1,
  totalPages = 1,
  onPageChange,
  totalItems = null,
  from = null,
  to = null,
}) {
  if (totalPages <= 1 && totalItems === null) return null;

  const handlePrev = () => {
    if (page > 1 && onPageChange) {
      onPageChange(page - 1);
    }
  };

  const handleNext = () => {
    if (page < totalPages && onPageChange) {
      onPageChange(page + 1);
    }
  };

  const handleSelectPage = (pg) => {
    if (pg !== page && onPageChange) {
      onPageChange(pg);
    }
  };

  // Generate up to 7 page numbers centered around current page
  const maxVisiblePages = 7;
  let startPage = Math.max(1, page - Math.floor(maxVisiblePages / 2));
  let endPage = startPage + maxVisiblePages - 1;

  if (endPage > totalPages) {
    endPage = totalPages;
    startPage = Math.max(1, endPage - maxVisiblePages + 1);
  }

  const pages = [];
  for (let i = startPage; i <= endPage; i++) {
    pages.push(i);
  }

  return (
    <div className="d-flex flex-column align-items-center gap-12 mt-20">
      {from !== null && to !== null && totalItems !== null && (
        <div className="audit-counter text-center mb-0">
          Showing {from}–{to} of {totalItems} records
        </div>
      )}

      {totalPages > 1 && (
        <div className="audit-pagination-container">
          <button
            type="button"
            onClick={handlePrev}
            disabled={page === 1}
            className="audit-btn audit-btn-secondary"
          >
            ← Prev
          </button>

          {pages.map((pg) => (
            <button
              key={pg}
              type="button"
              onClick={() => handleSelectPage(pg)}
              className={`audit-btn ${pg === page ? "audit-btn-primary" : "audit-btn-secondary"}`}
              style={{ minWidth: 36, padding: "0 10px" }}
            >
              {pg}
            </button>
          ))}

          <button
            type="button"
            onClick={handleNext}
            disabled={page === totalPages}
            className="audit-btn audit-btn-secondary"
          >
            Next →
          </button>
        </div>
      )}
    </div>
  );
}
