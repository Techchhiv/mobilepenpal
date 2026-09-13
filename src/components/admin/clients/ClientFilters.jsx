import React, { useEffect, useRef, useState } from 'react';
import { Icon } from '@iconify/react';

const SCHOOL_STATUS_OPTIONS = [
  { value: '', label: 'All School Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

const SUBSCRIPTION_STATUS_OPTIONS = [
  { value: '', label: 'All Subscription Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'expiring_soon', label: 'Expiring Soon' },
  { value: 'expired', label: 'Expired' },
  { value: 'none', label: 'No Subscription' },
];

const PLAN_OPTIONS = [
  { value: '', label: 'All Plans' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'yearly', label: 'Yearly' },
];

export default function ClientFilters({ filters = {}, onChange, onClear }) {
  const [searchTerm, setSearchTerm] = useState(filters.search ?? '');
  const debounceTimer = useRef(null);

  useEffect(() => {
    setSearchTerm(filters.search ?? '');
  }, [filters.search]);

  const handleSearchChange = (e) => {
    const val = e.target.value;
    setSearchTerm(val);
    clearTimeout(debounceTimer.current);
    debounceTimer.current = setTimeout(() => {
      onChange({ search: val });
    }, 300);
  };

  const isFiltered = Boolean(
    (filters.search && filters.search.trim()) ||
    filters.schoolStatus ||
    filters.subscriptionStatus ||
    filters.plan
  );

  return (
    <div className="card client-filter-card mb-24">
      <div className="card-header border-bottom bg-base py-16 px-20 d-flex align-items-center justify-content-between flex-wrap gap-12">
        <div className="d-flex align-items-center gap-8">
          <Icon
            icon="ic:baseline-filter-list"
            className="text-lg text-primary-600"
          />
          <h6 className="fw-semibold mb-0 text-sm">Filter & Search Clients</h6>
        </div>
        {isFiltered && (
          <button
            type="button"
            className="client-clear-filters-btn"
            onClick={onClear}
            title="Reset all filters"
          >
            <Icon icon="mdi:filter-remove-outline" />
            <span>Clear Filters</span>
          </button>
        )}
      </div>

      <div className="card-body p-20">
        <div className="row g-3">
          {/* Search */}
          <div className="col-12 col-md-6 col-lg-3">
            <label className="form-label text-secondary-light fw-semibold text-xs mb-6">
              Search
            </label>
            <div className="input-group">
              <span className="input-group-text bg-base text-secondary-light">
                <Icon icon="ic:baseline-search" />
              </span>
              <input
                type="text"
                className="form-control ps-0"
                placeholder="Name, school key, email..."
                value={searchTerm}
                onChange={handleSearchChange}
                aria-label="Search clients"
              />
              {searchTerm && (
                <button
                  type="button"
                  className="btn btn-link text-secondary-light p-1 pe-2"
                  onClick={() => {
                    setSearchTerm('');
                    onChange({ search: '' });
                  }}
                  title="Clear search"
                  aria-label="Clear search input"
                >
                  <Icon icon="mdi:close-circle" className="text-sm" />
                </button>
              )}
            </div>
          </div>

          {/* School Status */}
          <div className="col-12 col-sm-6 col-md-6 col-lg-3">
            <label className="form-label text-secondary-light fw-semibold text-xs mb-6">
              School Status
            </label>
            <div className="input-group">
              <span className="input-group-text bg-base text-secondary-light">
                <Icon icon="mdi:school-outline" />
              </span>
              <select
                className="form-select client-filter-select"
                value={filters.schoolStatus ?? ''}
                onChange={(e) => onChange({ schoolStatus: e.target.value })}
                aria-label="Filter by school status"
              >
                {SCHOOL_STATUS_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Subscription Status */}
          <div className="col-12 col-sm-6 col-md-6 col-lg-3">
            <label className="form-label text-secondary-light fw-semibold text-xs mb-6">
              Subscription Status
            </label>
            <div className="input-group">
              <span className="input-group-text bg-base text-secondary-light">
                <Icon icon="mdi:check-decagram-outline" />
              </span>
              <select
                className="form-select client-filter-select"
                value={filters.subscriptionStatus ?? ''}
                onChange={(e) =>
                  onChange({ subscriptionStatus: e.target.value })
                }
                aria-label="Filter by subscription status"
              >
                {SUBSCRIPTION_STATUS_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Plan */}
          <div className="col-12 col-sm-6 col-md-6 col-lg-3">
            <label className="form-label text-secondary-light fw-semibold text-xs mb-6">
              Subscription Plan
            </label>
            <div className="input-group">
              <span className="input-group-text bg-base text-secondary-light">
                <Icon icon="mdi:package-variant-closed" />
              </span>
              <select
                className="form-select client-filter-select"
                value={filters.plan ?? ''}
                onChange={(e) => onChange({ plan: e.target.value })}
                aria-label="Filter by plan"
              >
                {PLAN_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
