import React, { useEffect, useRef, useState } from 'react';
import { Icon } from '@iconify/react';

const SCHOOL_STATUS_OPTIONS = [
  { value: '', label: 'All Schools' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

const SUBSCRIPTION_STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'scheduled', label: 'Scheduled' },
  { value: 'expired', label: 'Expired' },
  { value: 'inactive', label: 'Inactive' },
  { value: 'none', label: 'No Subscription' },
];

const PLAN_OPTIONS = [
  { value: '', label: 'All Plans' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'yearly', label: 'Yearly' },
];

export default function ReportFilters({ filters = {}, onChange }) {
  const [searchValue, setSearchValue] = useState(filters.search ?? '');
  const searchTimer = useRef(null);

  useEffect(() => {
    setSearchValue(filters.search ?? '');
  }, [filters.search]);

  const handleSearchChange = (e) => {
    const value = e.target.value;
    setSearchValue(value);
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      onChange({ search: value });
    }, 300);
  };

  return (
    <div className="filter-container">
      <div className="card-header">
        <Icon icon="ic:baseline-filter-list" className="text-xl text-primary-600" />
        <h6 className="fw-semibold mb-0">Filter Schools</h6>
      </div>

      <div className="card-body p-24">
        <div className="row g-3">
          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Search</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="ic:baseline-search" />
              </span>
              <input
                type="text"
                className="form-control border-start-0 ps-0"
                placeholder="Name, school key, admin email..."
                value={searchValue}
                onChange={handleSearchChange}
                aria-label="Search schools"
              />
            </div>
          </div>

          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">School Status</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:school-outline" />
              </span>
              <select
                className="form-select border-start-0 report-filter-select"
                value={filters.schoolStatus ?? ''}
                onChange={(e) => onChange({ schoolStatus: e.target.value })}
                aria-label="Filter by school status"
              >
                {SCHOOL_STATUS_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Subscription Status</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:check-circle-outline" />
              </span>
              <select
                className="form-select border-start-0 report-filter-select"
                value={filters.subscriptionStatus ?? ''}
                onChange={(e) => onChange({ subscriptionStatus: e.target.value })}
                aria-label="Filter by subscription status"
              >
                {SUBSCRIPTION_STATUS_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Plan</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:package-variant-closed" />
              </span>
              <select
                className="form-select border-start-0 report-filter-select"
                value={filters.plan ?? ''}
                onChange={(e) => onChange({ plan: e.target.value })}
                aria-label="Filter by plan"
              >
                {PLAN_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
