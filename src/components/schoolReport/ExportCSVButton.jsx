import React from 'react';
import { Icon } from '@iconify/react';
import { exportToCSV } from '../../utils/schoolReportUtils';

/**
 * ExportCSVButton
 * Triggers a CSV download of the provided schools array.
 *
 * @param {Array}   schools  - Array of SchoolReport objects to export
 * @param {boolean} disabled - When true the button is disabled (e.g. while loading)
 */
export default function ExportCSVButton({ schools = [], disabled = false }) {
  const count = schools.length;

  const handleClick = () => {
    exportToCSV(schools, 'school-report');
  };

  return (
    <button
      type="button"
      className="btn btn-primary d-flex align-items-center gap-2"
      onClick={handleClick}
      disabled={disabled}
    >
      <Icon icon="mdi:download" className="text-xl" />
      Export CSV ({count} {count === 1 ? 'record' : 'records'})
    </button>
  );
}
