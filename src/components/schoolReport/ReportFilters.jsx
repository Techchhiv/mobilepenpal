import React, { useRef, useState, useEffect } from 'react';
import { Icon } from '@iconify/react';

const SUBSCRIPTION_STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'expired', label: 'Expired' },
  { value: 'trial', label: 'Trial' },
  { value: 'cancelled', label: 'Cancelled' },
];

const SUBSCRIPTION_PLAN_OPTIONS = [
  { value: '', label: 'All Plans' },
  { value: 'basic', label: 'Basic' },
  { value: 'pro', label: 'Pro' },
  { value: 'enterprise', label: 'Enterprise' },
];

/**
 * ReportFilters renders search/filter controls for the school report page.
 *
 * Props:
 *   filters  — { search, location, subscriptionStatus, subscriptionPlan, page }
 *   onChange — (partial) => void  called with partial filter updates
 *
 * Search and location inputs are debounced 300 ms before calling onChange.
 * Dropdowns call onChange immediately.
 */
export default function ReportFilters({ filters = {}, onChange }) {
  // Local state mirrors the text inputs so the UI stays responsive while debouncing
  const [searchValue, setSearchValue] = useState(filters.search ?? '');
  const [locationValue, setLocationValue] = useState(filters.location ?? '');

  const searchTimer = useRef(null);
  const locationTimer = useRef(null);

  // Keep local state in sync when the parent resets filters externally
  useEffect(() => {
    setSearchValue(filters.search ?? '');
  }, [filters.search]);

  useEffect(() => {
    setLocationValue(filters.location ?? '');
  }, [filters.location]);

  const handleSearchChange = (e) => {
    const value = e.target.value;
    setSearchValue(value);
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      onChange({ search: value });
    }, 300);
  };

  const handleLocationChange = (e) => {
    const value = e.target.value;
    setLocationValue(value);
    clearTimeout(locationTimer.current);
    locationTimer.current = setTimeout(() => {
      onChange({ location: value });
    }, 300);
  };

  const handleStatusChange = (e) => {
    onChange({ subscriptionStatus: e.target.value });
 };

  const handlePlanChange = (e) => {
    onChange({ subscriptionPlan: e.target.value });
  };

  return (
    <div className="filter-container">
      <div className="card-header">
        <Icon icon="ic:baseline-filter-list" className="text-xl text-primary-600" />
        <h6 className="fw-semibold mb-0">Filter Schools</h6>
      </div>

      <div className="card-body p-24">
        <div className="row g-3">

          {/* Search */}
          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Search</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="ic:baseline-search" />
              </span>
              <input
                type="text"
                className="form-control border-start-0 ps-0 "
                placeholder="Name, city, country…"
                value={searchValue}
                onChange={handleSearchChange}
                aria-label="Search schools"
              />
            </div>
          </div>

          {/* Location */}
          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Location</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:map-marker-outline" />
              </span>
              <input
                type="text"
                className="form-control border-start-0 ps-0"
                placeholder="City or region…"
                value={locationValue}
                onChange={handleLocationChange}
                aria-label="Filter by location"
              />
            </div>
          </div>

          {/* Status */}
          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Subscription Status</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:check-circle-outline" />
              </span>
              <select
                className="form-select border-start-0 report-filter-select"
                value={filters.subscriptionStatus ?? ''}
                onChange={handleStatusChange}
                aria-label="Filter by subscription status"
              >
                {SUBSCRIPTION_STATUS_OPTIONS.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Plan */}
          <div className="col-12 col-sm-6 col-xl-3">
            <label className="form-label text-secondary-light fw-semibold text-sm mb-8">Subscription Plan</label>
            <div className="input-group">
              <span className="input-group-text bg-base border-end-0 text-secondary-light">
                <Icon icon="mdi:package-variant-closed" />
              </span>
              <select
                className="form-select border-start-0 report-filter-select"
                value={filters.subscriptionPlan ?? ''}
                onChange={handlePlanChange}
                aria-label="Filter by subscription plan"
              >
             
                {SUBSCRIPTION_PLAN_OPTIONS.map(({ value, label }) => (
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
