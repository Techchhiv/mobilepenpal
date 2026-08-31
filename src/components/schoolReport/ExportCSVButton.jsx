import React, { useState } from 'react';
import { Icon } from '@iconify/react';
import API from '../../helper/api';

/**
 * ExportCSVButton
 * Sends the current active filters to the backend /admin/reports/schools/export endpoint
 * and downloads the full filtered CSV (not limited to the current page).
 *
 * @param {Object}  filters    - Current report filters (search, schoolStatus, subscriptionStatus, plan, sort_by, sort_direction)
 * @param {number}  totalItems - Total matching record count (used for label display)
 * @param {boolean} disabled   - Disable when no data or initial load in progress
 */
export default function ExportCSVButton({ filters = {}, totalItems = 0, disabled = false }) {
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState('');

  const handleClick = async () => {
    if (exporting) return;
    setExporting(true);
    setExportError('');

    try {
      // Build query params — omit page/per_page (export returns all matching records)
      const params = {};
      if (filters.search)             params.search              = filters.search;
      if (filters.schoolStatus)       params.school_status       = filters.schoolStatus;
      if (filters.subscriptionStatus) params.subscription_status = filters.subscriptionStatus;
      if (filters.plan)               params.plan                = filters.plan;
      if (filters.sortBy)             params.sort_by             = filters.sortBy;
      if (filters.sortDirection)      params.sort_direction      = filters.sortDirection;

      const response = await API.get('/admin/reports/schools/export', {
        params,
        responseType: 'blob',
      });

      // Build a download link and trigger it
      const url  = URL.createObjectURL(new Blob([response.data], { type: 'text/csv;charset=utf-8;' }));
      const link = document.createElement('a');
      const today = new Date().toISOString().slice(0, 10);
      link.href     = url;
      link.download = `school-report-${today}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('CSV export failed:', err);
      setExportError('Export failed. Please try again.');
    } finally {
      setExporting(false);
    }
  };

  const label = exporting
    ? 'Exporting…'
    : `Export CSV (${totalItems.toLocaleString()} ${totalItems === 1 ? 'record' : 'records'})`;

  return (
    <div className="d-flex flex-column align-items-end gap-1">
      <button
        type="button"
        id="export-csv-btn"
        className="btn btn-primary d-flex align-items-center gap-2"
        onClick={handleClick}
        disabled={disabled || exporting || totalItems === 0}
        aria-busy={exporting}
      >
        <Icon
          icon={exporting ? 'mdi:loading' : 'mdi:download'}
          className={`text-xl${exporting ? ' spin' : ''}`}
          style={exporting ? { animation: 'spin 1s linear infinite' } : undefined}
        />
        {label}
      </button>
      {exportError && (
        <span className="text-danger text-xs">{exportError}</span>
      )}
    </div>
  );
}
