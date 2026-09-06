// src/pages/admin/ManageClientsPage.jsx
import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Icon } from '@iconify/react';
import MasterLayout from '../../masterLayout/MasterLayout';
import API from '../../helper/api';
import { useAuth } from '../../context/AuthContext';
import { syncFiltersToURL } from '../../utils/clientUtils';
import ClientSummaryCards from '../../components/admin/clients/ClientSummaryCards';
import ClientFilters from '../../components/admin/clients/ClientFilters';
import ClientTable from '../../components/admin/clients/ClientTable';
import CreateSchoolModal from '../../components/admin/clients/CreateSchoolModal';
import EditSchoolModal from '../../components/admin/clients/EditSchoolModal';
import StatusConfirmModal from '../../components/admin/clients/StatusConfirmModal';
import '../../assets/css/manageClients.css';

export default function ManageClientsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { isSuperAdmin, hasPermission } = useAuth();
  const canManageClients = isSuperAdmin || hasPermission('menu.manage_clients');

  // Read current filters from URL
  const search = searchParams.get('search') ?? '';
  const schoolStatus = searchParams.get('school_status') ?? '';
  const subscriptionStatus = searchParams.get('subscription_status') ?? '';
  const plan = searchParams.get('plan') ?? '';
  const pageParam = Number(searchParams.get('page') ?? '1');
  const currentPage = Number.isFinite(pageParam) && pageParam > 0 ? pageParam : 1;

  const filters = {
    search,
    schoolStatus,
    subscriptionStatus,
    plan,
    page: currentPage,
  };

  // State
  const [schools, setSchools] = useState([]);
  const [summary, setSummary] = useState({ total: 0, active: 0, inactive: 0 });
  const [pagination, setPagination] = useState({
    current_page: 1,
    last_page: 1,
    total: 0,
    per_page: 10,
    from: 0,
    to: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [flashMsg, setFlashMsg] = useState({ text: '', isError: false });

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editingSchool, setEditingSchool] = useState(null);
  const [statusModalSchool, setStatusModalSchool] = useState(null);
  const [statusSubmitting, setStatusSubmitting] = useState(false);

  const flash = (text, isError = false) => {
    setFlashMsg({ text, isError });
    setTimeout(() => {
      setFlashMsg({ text: '', isError: false });
    }, 3500);
  };

  // Fetch clients from backend
  const loadSchools = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await API.get('admin/schools', {
        params: {
          search: filters.search || undefined,
          school_status: filters.schoolStatus || undefined,
          subscription_status: filters.subscriptionStatus || undefined,
          plan: filters.plan || undefined,
          page: filters.page,
          per_page: 10,
        },
      });

      const payload = res.data ?? {};
      const rows = Array.isArray(payload.data) ? payload.data : [];
      setSchools(rows);

      if (payload.summary) {
        setSummary(payload.summary);
      } else {
        // Fallback summary if backend didn't return summary object
        setSummary({
          total: payload.total ?? rows.length,
          active: rows.filter((s) => s.is_active).length,
          inactive: rows.filter((s) => !s.is_active).length,
        });
      }

      setPagination({
        current_page: Number(payload.current_page || filters.page),
        last_page: Number(payload.last_page || 1),
        total: Number(payload.total || rows.length),
        per_page: Number(payload.per_page || 10),
        from: Number(payload.from || (rows.length > 0 ? 1 : 0)),
        to: Number(payload.to || rows.length),
      });
    } catch (e) {
      setError(
        e?.response?.data?.message || 'Unable to load clients. Please try again.'
      );
      setSchools([]);
    } finally {
      setLoading(false);
    }
  }, [
    filters.search,
    filters.schoolStatus,
    filters.subscriptionStatus,
    filters.plan,
    filters.page,
  ]);

  useEffect(() => {
    loadSchools();
  }, [loadSchools]);

  // Handlers for search & filters
  const handleFilterChange = (partial) => {
    const next = { ...filters, ...partial, page: 1 };
    syncFiltersToURL(next, setSearchParams);
  };

  const handleClearFilters = () => {
    const next = {
      search: '',
      schoolStatus: '',
      subscriptionStatus: '',
      plan: '',
      page: 1,
    };
    syncFiltersToURL(next, setSearchParams);
  };

  const handlePageChange = (newPage) => {
    syncFiltersToURL({ ...filters, page: newPage }, setSearchParams);
  };

  // Status toggle handler
  const handleToggleStatusConfirm = async (school, newStatus) => {
    setStatusSubmitting(true);
    try {
      await API.put(`admin/schools/${school.id}`, {
        is_active: newStatus,
      });
      flash(
        `School "${school.name}" has been ${newStatus ? 'activated' : 'deactivated'}.`
      );
      setStatusModalSchool(null);
      await loadSchools();
    } catch (err) {
      flash(
        err?.response?.data?.message || 'Failed to update school status.',
        true
      );
    } finally {
      setStatusSubmitting(false);
    }
  };

  // Delete handler
  const handleDeleteSchool = async (school) => {
    if (!window.confirm(`Are you sure you want to delete school "${school.name}"? This action cannot be undone.`)) {
      return;
    }
    try {
      await API.delete(`admin/schools/${school.id}`);
      flash(`School "${school.name}" deleted successfully.`);
      await loadSchools();
    } catch (err) {
      flash(err?.response?.data?.message || 'Failed to delete school.', true);
    }
  };

  const isFiltered = Boolean(
    (filters.search && filters.search.trim()) ||
    filters.schoolStatus ||
    filters.subscriptionStatus ||
    filters.plan
  );

  return (
    <MasterLayout>
      <div className="manage-clients-page">
        {/* Flash Notifications */}
        {flashMsg.text && (
          <div
            className={`alert ${
              flashMsg.isError ? 'alert-danger' : 'alert-success'
            } alert-dismissible fade show radius-8 mb-20 d-flex align-items-center justify-content-between`}
            role="alert"
          >
            <div className="d-flex align-items-center gap-8">
              <Icon
                icon={
                  flashMsg.isError
                    ? 'mdi:alert-circle-outline'
                    : 'mdi:check-circle-outline'
                }
                className="text-lg"
              />
              <span className="text-sm fw-medium">{flashMsg.text}</span>
            </div>
            <button
              type="button"
              className="btn-close"
              aria-label="Close"
              onClick={() => setFlashMsg({ text: '', isError: false })}
            />
          </div>
        )}

        {/* Page Header */}
        <div className="manage-clients-header d-flex align-items-center justify-content-between flex-wrap gap-16 mb-24">
          <div>
            <h5 className="fw-bold mb-4">Manage Clients</h5>
            <p className="text-secondary-light text-sm mb-0">
              Manage school clients, account status, and subscriptions.
            </p>
          </div>

          {canManageClients && (
            <button
              type="button"
              className="btn btn-primary radius-8 px-16 py-9 d-inline-flex align-items-center gap-8"
              onClick={() => setIsCreateOpen(true)}
            >
              <Icon icon="lucide:plus" className="text-md" />
              <span>Create School</span>
            </button>
          )}
        </div>

        {/* Client Summary Cards */}
        <ClientSummaryCards summary={summary} loading={loading} />

        {/* Filters */}
        <ClientFilters
          filters={filters}
          onChange={handleFilterChange}
          onClear={handleClearFilters}
        />

        {/* Client Table with Pagination, Loading, Empty, and Error states */}
        <ClientTable
          schools={schools}
          loading={loading}
          error={error}
          isFiltered={isFiltered}
          pagination={pagination}
          onPageChange={handlePageChange}
          onClearFilters={handleClearFilters}
          onRetry={loadSchools}
          onToggleStatus={(s) => setStatusModalSchool(s)}
          onEditSchool={(s) => setEditingSchool(s)}
          onDeleteSchool={handleDeleteSchool}
        />

        {/* Create School Modal */}
        <CreateSchoolModal
          isOpen={isCreateOpen}
          onClose={() => setIsCreateOpen(false)}
          onSuccess={(msg) => {
            flash(msg);
            loadSchools();
          }}
        />

        {/* Edit School Modal */}
        <EditSchoolModal
          isOpen={Boolean(editingSchool)}
          school={editingSchool}
          onClose={() => setEditingSchool(null)}
          onSuccess={(msg) => {
            flash(msg);
            loadSchools();
          }}
        />

        {/* Status Confirmation Modal */}
        <StatusConfirmModal
          isOpen={Boolean(statusModalSchool)}
          school={statusModalSchool}
          submitting={statusSubmitting}
          onConfirm={handleToggleStatusConfirm}
          onClose={() => setStatusModalSchool(null)}
        />
      </div>
    </MasterLayout>
  );
}
