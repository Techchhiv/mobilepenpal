// src/pages/admin/AdminUsersPage.jsx
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";
import { useAuth } from "../../context/AuthContext";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../components/admin/common/ConfirmModal";
import AdminPagination from "../../components/admin/common/AdminPagination";

// Accept [] or {data:[]}
const normalizeList = (payload) =>
  Array.isArray(payload) ? payload : Array.isArray(payload?.data) ? payload.data : [];

const ONLINE_GRACE_MS = 2 * 60 * 1000;
const isTruthy = (v) => v === true || String(v) === "1";
const computeOnline = (u) => {
  const flag = isTruthy(u?.is_online);
  const last = u?.last_seen_at ? new Date(u.last_seen_at) : null;
  const fresh = last ? (Date.now() - last.getTime()) <= ONLINE_GRACE_MS : false;
  return flag || fresh;
};

function UserFormModal({
  open,
  onClose,
  onSubmit,
  allRoles,
  initial, // {id?, name, email, roles:[]}
  saving,
}) {
  const isEdit = Boolean(initial?.id);
  const [name, setName] = useState(initial?.name || "");
  const [email, setEmail] = useState(initial?.email || "");
  const [password, setPassword] = useState("");
  const [roles, setRoles] = useState(initial?.roles || []);

  useEffect(() => {
    setName(initial?.name || "");
    setEmail(initial?.email || "");
    setPassword("");
    setRoles(initial?.roles || []);
  }, [initial, open]);

  const toggleRole = (rName) =>
    setRoles((prev) =>
      prev.includes(rName) ? prev.filter((r) => r !== rName) : [...prev, rName]
    );

  if (!open) return null;

  return (
    <>
      <div className="modal-backdrop fade show"></div>
      <div className="modal fade show d-block" tabIndex={-1} role="dialog" aria-modal="true" onClick={onClose}>
        <div className="modal-dialog modal-lg modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
          <div className="modal-content">
            <div className="modal-header">
              <h6 className="modal-title">{isEdit ? "Edit User" : "Add User"}</h6>
              <button type="button" className="btn-close" onClick={onClose} />
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault();
                onSubmit({
                  id: initial?.id,
                  name,
                  email,
                  password: password || undefined, // omit if empty on edit
                  roles,
                });
              }}
            >
              <div className="modal-body">
                <div className="row g-3">
                  <div className="col-12 col-md-6">
                    <label className="form-label">Name</label>
                    <input className="form-control" value={name} onChange={(e) => setName(e.target.value)} required />
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label">Email</label>
                    <input type="email" className="form-control" value={email} onChange={(e) => setEmail(e.target.value)} required />
                  </div>

                  <div className="col-12">
                    <label className="form-label">{isEdit ? "Password (leave empty to keep)" : "Password"}</label>
                    <input
                      type="password"
                      className="form-control"
                      placeholder={isEdit ? "Optional" : "At least 8 characters"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      {...(isEdit ? {} : { required: true })}
                      minLength={8}
                    />
                  </div>

                  <div className="col-12">
                    <label className="form-label">Roles</label>
                    <div className="border rounded-3 p-2" style={{ maxHeight: 220, overflow: "auto" }}>
                      <div className="row g-2">
                        {allRoles.map((r) => (
                          <div key={r.id || r.name} className="col-12 col-sm-6">
                            <label className="form-check d-flex align-items-center gap-2">
                              <input
                                type="checkbox"
                                className="form-check-input"
                                checked={roles.includes(r.name)}
                                onChange={() => toggleRole(r.name)}
                              />
                              <span className="form-check-label">{r.name}</span>
                            </label>
                          </div>
                        ))}
                        {!allRoles.length && <div className="text-muted small px-2">No roles</div>}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? "Saving…" : isEdit ? "Save Changes" : "Create User"}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
}

const AdminUsersPage = () => {
  const { user: currentUser } = useAuth();
  const [rows, setRows] = useState([]);
  const [allRoles, setAllRoles] = useState([]);
  const [message, setMessage] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);

  // Search & Pagination States
  const [search, setSearch] = useState("");
  const [perPage, setPerPage] = useState(10);
  const [page, setPage] = useState(1);

  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState(null);

  const pollRef = useRef(null);

  const flash = (txt, isErr = false) => {
    (isErr ? setErr : setMessage)(txt);
    setTimeout(() => (isErr ? setErr("") : setMessage("")), 2500);
  };

  const fetchUsers = async () => {
    const { data } = await API.get("/admin/users");
    const list = normalizeList(data);

    return list
      .filter((u) => !currentUser || (u.id !== currentUser.id && u.email !== currentUser.email))
      .map((u) => ({
        id: u.id,
        name: u.name,
        email: u.email,
        roles: (u.roles || []).map((r) => r.name),
        created_at: u.created_at,

        // keep what the API sends
        is_online: u.is_online,
        last_seen_at: u.last_seen_at,

        // derived field
        online: computeOnline(u),
      }));
  };

  const fetchRoles = async () => {
    const { data } = await API.get("/admin/roles");
    const list = normalizeList(data);
    return list.map((r) => ({ id: r.id, name: r.name }));
  };

  const load = async () => {
    setLoading(true);
    setErr("");
    try {
      const [users, roles] = await Promise.all([fetchUsers(), fetchRoles()]);
      setRows(users);
      setAllRoles(roles);
    } catch (e) {
      console.error("Admin users load failed:", e?.response?.data || e);
      setRows([]);
      setErr(e?.response?.data?.message || e.message || "Failed to load users.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  // Poll every 20s for fresh online status cleanly without wiping DOM nodes
  useEffect(() => {
    pollRef.current = setInterval(async () => {
      try {
        const users = await fetchUsers();
        setRows(users);
      } catch (e) {
        // silent fail
      }
    }, 20000);
    return () => clearInterval(pollRef.current);
  }, []);

  // Filtered and Paginated rows
  const filteredRows = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        (u.roles || []).some((r) => r.toLowerCase().includes(q))
    );
  }, [rows, search]);

  const totalPages = Math.ceil(filteredRows.length / perPage) || 1;
  const paginatedRows = useMemo(() => {
    const start = (page - 1) * perPage;
    return filteredRows.slice(start, start + perPage);
  }, [filteredRows, page, perPage]);

  const openCreate = () => { setEditing(null); setModalOpen(true); };
  const openEdit = (u) => {
    setEditing({ id: u.id, name: u.name, email: u.email, roles: u.roles || [] });
    setModalOpen(true);
  };

  const handleSubmit = async (payload) => {
    setSaving(true);
    try {
      if (payload.id) {
        await API.put(`/admin/users/${payload.id}`, {
          name: payload.name,
          email: payload.email,
          ...(payload.password ? { password: payload.password } : {}),
          roles: payload.roles,
        });
        flash("User updated");
      } else {
        await API.post("/admin/users", {
          name: payload.name,
          email: payload.email,
          password: payload.password,
          roles: payload.roles,
        });
        flash("User created");
      }
      setModalOpen(false);
      await load();
    } catch (e) {
      flash(e?.response?.data?.message || "Save failed", true);
    } finally {
      setSaving(false);
    }
  };

  const [deleteModal, setDeleteModal] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const handleDeleteClick = (u) => {
    setDeleteModal(u);
  };

  const confirmDeleteUser = async () => {
    if (!deleteModal) return;
    try {
      setDeleteLoading(true);
      const res = await API.delete(`/admin/users/${deleteModal.id}`);
      if (res.status === 204 || res.status === 200) {
        setRows((prev) => prev.filter((u) => u.id !== deleteModal.id));
        flash("User deleted successfully.");
        setDeleteModal(null);
      }
    } catch (e) {
      console.error(e);
      flash(e?.response?.data?.message || "Failed to delete user.", true);
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="System Users"
          subtitle="Manage administrative user accounts, roles, access privileges, and online presence"
          actionLabel="Add User"
          actionIcon="lucide:plus"
          onAction={openCreate}
        />

        {message && <div className="alert alert-success py-12 px-16 radius-8 text-sm mb-16">{message}</div>}
        {err && !rows.length && !loading && (
          <AdminErrorState
            title="Failed to Load System Users"
            message={err}
            onRetry={load}
          />
        )}

        {/* Standalone Filter Card */}
        <div className="card border radius-12 shadow-none mb-20">
          <div className="card-body p-16 px-20">
            <div className="d-flex flex-wrap align-items-center justify-content-between gap-16">
              {/* Left side: Search input */}
              <div className="d-flex align-items-center gap-12 flex-grow-1" style={{ maxWidth: 360, minWidth: 220 }}>
                <div className="position-relative w-100">
                  <input
                    type="text"
                    className="form-control h-40-px ps-40 pe-36 radius-8 text-sm border-neutral-200 bg-base"
                    placeholder="Search name, email, role…"
                    value={search}
                    onChange={(e) => {
                      setSearch(e.target.value);
                      setPage(1);
                    }}
                  />
                  <Icon
                    icon="ion:search-outline"
                    className="position-absolute top-50 translate-middle-y text-secondary-light"
                    style={{ left: 14, fontSize: 20, pointerEvents: "none" }}
                  />
                  {search && (
                    <button
                      type="button"
                      className="btn p-0 border-0 position-absolute top-50 end-0 translate-middle-y me-12 text-secondary-light hover-text-danger d-flex align-items-center justify-content-center"
                      onClick={() => {
                        setSearch("");
                        setPage(1);
                      }}
                      title="Clear search"
                    >
                      <Icon icon="lucide:x" className="font-16" />
                    </button>
                  )}
                </div>
              </div>

              {/* Right side: Entries Select + Status Badges */}
              <div className="d-flex align-items-center gap-16 flex-wrap ms-auto">
                {/* Entries Per Page Select */}
                <div className="d-flex align-items-center gap-8">
                  <span className="text-xs text-secondary-light font-medium">Show:</span>
                  <select
                    className="form-select h-40-px radius-8 text-sm border-neutral-200 bg-base px-12"
                    style={{ width: "auto", cursor: "pointer" }}
                    value={perPage}
                    onChange={(e) => {
                      setPerPage(Number(e.target.value));
                      setPage(1);
                    }}
                  >
                    <option value={10}>10 entries</option>
                    <option value={25}>25 entries</option>
                    <option value={50}>50 entries</option>
                    <option value={100}>100 entries</option>
                  </select>
                </div>

                <div className="border-start border-neutral-200 h-24-px d-none d-sm-block"></div>

                {/* Status Indicator Badges (Original Design) */}
                <div className="d-flex align-items-center gap-16 text-muted">
                  <small className="d-inline-flex align-items-center gap-1 text-xs">
                    <span className="badge bg-success-focus text-success-main radius-4">●</span> Online
                  </small>
                  <small className="d-inline-flex align-items-center gap-1 text-xs">
                    <span className="badge bg-danger-focus text-danger-main radius-4">●</span> Offline
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Table Card */}
        <div className="card border radius-12 shadow-none overflow-hidden">
          <div className="card-body p-0">
            {loading ? (
              <div className="placeholder-glow d-flex flex-column gap-12 p-24">
                {[1, 2, 3, 4, 5].map((i) => (
                  <span key={i} className="placeholder col-12 radius-8" style={{ height: "48px" }}></span>
                ))}
              </div>
            ) : filteredRows.length === 0 ? (
              <AdminEmptyState
                icon="mdi:account-outline"
                title={search ? "No matching users found" : "No system users found"}
                message={search ? `No accounts match "${search}".` : "Click 'Add User' to create your first administrative user account."}
              />
            ) : (
              <div className="table-responsive">
                <table className="table bordered-table mb-0 align-middle">
                  <thead>
                    <tr>
                      <th scope="col" className="px-16" style={{ width: 80 }}>S.L</th>
                      <th scope="col" className="px-16">Name</th>
                      <th scope="col" className="px-16">Email</th>
                      <th scope="col" className="px-16">Online</th>
                      <th scope="col" className="px-16">Roles</th>
                      <th scope="col" className="px-16">Created</th>
                      <th scope="col" className="pe-16 text-end">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedRows.map((u, idx) => {
                      const globalIndex = (page - 1) * perPage + idx + 1;
                      return (
                        <tr key={u.id}>
                          <td className="px-16 font-monospace text-secondary-light">{globalIndex}</td>
                          <td className="fw-semibold px-16 text-dark">{u.name}</td>
                          <td className="px-16 text-secondary-light">{u.email}</td>
                          <td className="px-16">
                            {u.online ? (
                              <span className="badge bg-success-focus text-success-main px-10 py-4 radius-6 text-xs fw-semibold">
                                Online
                              </span>
                            ) : (
                              <span className="badge bg-neutral-200 text-secondary-light px-10 py-4 radius-6 text-xs fw-semibold">
                                Offline
                              </span>
                            )}
                          </td>
                          <td className="px-16">
                            {(u.roles || []).map((r) => (
                              <span key={r} className="badge bg-primary-light text-primary-600 me-1 px-8 py-4 radius-4 text-xs">
                                {r}
                              </span>
                            ))}
                          </td>
                          <td className="px-16 text-sm text-secondary-light">{u.created_at ? new Date(u.created_at).toLocaleDateString() : "-"}</td>
                          <td className="pe-16 text-end">
                            <div className="d-inline-flex align-items-center justify-content-end gap-2">
                              <button
                                onClick={() => openEdit(u)}
                                className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                title="Edit User"
                                type="button"
                              >
                                <Icon icon="lucide:edit" />
                              </button>
                              <button
                                onClick={() => handleDeleteClick(u)}
                                className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                title="Delete User"
                                type="button"
                              >
                                <Icon icon="mingcute:delete-2-line" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* ── Card Footer Pagination ── */}
          <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
            <div className="text-secondary-light text-xs font-semibold">
              Showing {filteredRows.length > 0 ? (page - 1) * perPage + 1 : 0}–
              {Math.min(page * perPage, filteredRows.length)} of {filteredRows.length} entries
            </div>
            {totalPages > 1 && (
              <div className="ms-auto">
                <AdminPagination
                  page={page}
                  totalPages={totalPages}
                  onPageChange={(p) => setPage(p)}
                />
              </div>
            )}
          </div>
        </div>

        <UserFormModal
          open={modalOpen}
          onClose={() => setModalOpen(false)}
          onSubmit={handleSubmit}
          allRoles={allRoles}
          initial={editing}
          saving={saving}
        />

        <ConfirmModal
          open={!!deleteModal}
          title="Delete System User"
          message={deleteModal ? `Are you sure you want to delete account "${deleteModal.name}" (${deleteModal.email})? This action cannot be undone.` : ""}
          confirmLabel="Delete User"
          variant="danger"
          loading={deleteLoading}
          onConfirm={confirmDeleteUser}
          onCancel={() => setDeleteModal(null)}
        />
      </div>
    </MasterLayout>
  );
};

export default AdminUsersPage;
