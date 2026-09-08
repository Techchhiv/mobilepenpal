// src/pages/admin/AdminPermissionsPage.jsx
import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../components/admin/common/AdminErrorState";
import AdminPagination from "../../components/admin/common/AdminPagination";
import ConfirmModal from "../../components/admin/common/ConfirmModal";

// Reusable modal
function PermissionModal({ open, onClose, onSubmit, initial, saving }) {
  const isEdit = Boolean(initial?.id);
  const [name, setName] = useState(initial?.name || "");

  useEffect(() => {
    setName(initial?.name || "");
  }, [initial, open]);

  if (!open) return null;

  return (
    <>
      {/* Backdrop */}
      <div className="modal-backdrop fade show"></div>

      {/* Modal */}
      <div
        className="modal fade show d-block"
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        onClick={onClose}
      >
        <div
          className="modal-dialog modal-dialog-centered"
          role="document"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="modal-content">
            <div className="modal-header">
              <h6 className="modal-title">
                {isEdit ? "Edit Permission" : "Add Permission"}
              </h6>
              <button type="button" className="btn-close" onClick={onClose} />
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault();
                onSubmit({ id: initial?.id, name: name.trim() });
              }}
            >
              <div className="modal-body">
                <label className="form-label">Permission Name</label>
                <input
                  className="form-control"
                  placeholder="e.g., products.manage"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  minLength={2}
                />
                <small className="text-xs text-secondary-light d-block mt-6">
                  Use a consistent naming pattern like{" "}
                  <code>resource.action</code>.
                </small>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-light"
                  onClick={onClose}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={saving}
                >
                  {saving
                    ? "Saving…"
                    : isEdit
                    ? "Save Changes"
                    : "Create Permission"}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
}


export default function AdminPermissionsPage() {
  const [perms, setPerms] = useState([]);      // [{id, name}]
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState("");
  const [flash, setFlash] = useState("");

  // modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null); // null | {id, name}

  // search
  const [q, setQ] = useState("");

  const [page, setPage] = useState(1);
  const perPage = 10;

  const filtered = useMemo(() => {
    const t = q.trim().toLowerCase();
    if (!t) return perms;
    return perms.filter((p) => p.name.toLowerCase().includes(t));
  }, [perms, q]);

  const totalPages = Math.ceil(filtered.length / perPage) || 1;

  const paginated = useMemo(() => {
    const start = (page - 1) * perPage;
    return filtered.slice(start, start + perPage);
  }, [filtered, page, perPage]);

  useEffect(() => {
    setPage(1);
  }, [q]);

  const showFlash = (txt) => {
    setFlash(txt);
    setTimeout(() => setFlash(""), 2500);
  };

  const showErr = (txt) => {
    setErr(txt);
    setTimeout(() => setErr(""), 3500);
  };

  const load = async () => {
    setLoading(true);
    setErr("");
    try {
      const { data } = await API.get("admin/permissions");
      // Accept array or paginator {data:[]}
      const list = Array.isArray(data) ? data : Array.isArray(data?.data) ? data.data : [];
      setPerms(list.map((p) => ({ id: p.id, name: p.name })));
    } catch (e) {
      showErr(e?.response?.data?.message || e.message || "Failed to load permissions.");
      setPerms([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => { setEditing(null); setModalOpen(true); };
  const openEdit = (p) => { setEditing(p); setModalOpen(true); };

  const handleSubmit = async ({ id, name }) => {
    setSaving(true);
    try {
      if (id) {
        await API.put(`admin/permissions/${id}`, { name });
        showFlash("Permission updated");
      } else {
        await API.post("admin/permissions", { name });
        showFlash("Permission created");
      }
      setModalOpen(false);
      await load();
    } catch (e) {
      showErr(e?.response?.data?.message || "Save failed");
    } finally {
      setSaving(false);
    }
  };

  const [deleteModal, setDeleteModal] = useState(null); // permission to delete
  const [deleteLoading, setDeleteLoading] = useState(false);

  const handleDeleteClick = (p) => {
    setDeleteModal(p);
  };

  const confirmDeletePerm = async () => {
    if (!deleteModal) return;
    try {
      setDeleteLoading(true);
      await API.delete(`admin/permissions/${deleteModal.id}`);
      setPerms((prev) => prev.filter((x) => x.id !== deleteModal.id));
      showFlash("Permission deleted");
      setDeleteModal(null);
    } catch (e) {
      showErr(e?.response?.data?.message || "Delete failed");
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Permissions Management"
          subtitle="System access control permissions and security scope definitions"
          actionLabel="Add Permission"
          actionIcon="lucide:plus"
          onAction={openCreate}
        />

        {flash && <div className="alert alert-success py-12 px-16 radius-8 text-sm mb-16">{flash}</div>}

        {err && !perms.length && !loading ? (
          <AdminErrorState
            title="Failed to Load Permissions"
            message={err}
            onRetry={load}
          />
        ) : (
          <div className="card border radius-12 shadow-none">
            <div className="card-header border-bottom py-16 px-24 bg-base d-flex align-items-center justify-content-between flex-wrap gap-12">
              <h6 className="fw-bold mb-0 text-dark">System Permissions</h6>
              <div className="d-flex align-items-center gap-12">
                <input
                  className="form-control form-control-sm radius-8 min-w-200-px"
                  placeholder="Search permissions..."
                  value={q}
                  onChange={(e) => setQ(e.target.value)}
                />
                <span className="badge bg-neutral-200 text-secondary-light px-10 py-6 radius-6 text-xs">
                  {filtered.length} / {perms.length}
                </span>
              </div>
            </div>

            <div className="card-body p-0">
              {loading ? (
                <div className="placeholder-glow d-flex flex-column gap-12 p-24">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <span key={i} className="placeholder col-12 radius-8" style={{ height: "48px" }}></span>
                  ))}
                </div>
              ) : filtered.length === 0 ? (
                <AdminEmptyState
                  icon="mdi:key-outline"
                  title="No permissions found"
                  message="No permission scope matches the current search query."
                />
              ) : (
                <div className="table-responsive">
                  <table className="table bordered-table mb-0 align-middle">
                    <thead>
                      <tr>
                        <th style={{ width: 80 }} className="px-16">ID</th>
                        <th className="px-16">Permission Key</th>
                        <th style={{ width: 120 }} className="text-end pe-16">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {paginated.map((p) => (
                        <tr key={p.id}>
                          <td className="px-16 font-monospace text-secondary-light">{p.id}</td>
                          <td className="px-16">
                            <span className="badge bg-primary-light text-primary-600 px-12 py-6 radius-6 text-xs fw-semibold font-monospace">
                              {p.name}
                            </span>
                          </td>
                          <td className="text-end pe-16">
                            <div className="d-inline-flex align-items-center gap-2">
                              <button
                                type="button"
                                className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                title="Edit Permission"
                                onClick={() => openEdit(p)}
                              >
                                <Icon icon="lucide:edit" />
                              </button>
                              <button
                                type="button"
                                className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                title="Delete Permission"
                                onClick={() => handleDeleteClick(p)}
                              >
                                <Icon icon="mingcute:delete-2-line" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* ── Card Footer Pagination ── */}
            <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
              <div className="text-secondary-light text-xs font-semibold">
                Showing {filtered.length > 0 ? (page - 1) * perPage + 1 : 0}–
                {Math.min(page * perPage, filtered.length)} of {filtered.length} entries
              </div>
              {totalPages > 1 && (
                <div className="ms-auto">
                  <AdminPagination
                    page={page}
                    totalPages={totalPages}
                    onPageChange={setPage}
                  />
                </div>
              )}
            </div>
          </div>
        )}

        <PermissionModal
          open={modalOpen}
          onClose={() => setModalOpen(false)}
          onSubmit={handleSubmit}
          initial={editing}
          saving={saving}
        />

        <ConfirmModal
          open={!!deleteModal}
          title="Delete Permission Scope"
          message={deleteModal ? `Are you sure you want to delete permission "${deleteModal.name}"? Roles assigned to this permission will lose this capability.` : ""}
          confirmLabel="Delete Permission"
          variant="danger"
          loading={deleteLoading}
          onConfirm={confirmDeletePerm}
          onCancel={() => setDeleteModal(null)}
        />
      </div>
    </MasterLayout>
  );
}
