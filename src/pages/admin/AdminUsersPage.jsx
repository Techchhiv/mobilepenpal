// src/pages/admin/AdminUsersPage.jsx
import React, { useEffect, useMemo, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";

// Small helper: accept [] or {data:[]}
const normalizeList = (payload) =>
  Array.isArray(payload) ? payload : Array.isArray(payload?.data) ? payload.data : [];

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
          className="modal-dialog modal-lg modal-dialog-centered"
          role="document"
          onClick={(e) => e.stopPropagation()}
        >
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
                  {/* Name */}
                  <div className="col-12 col-md-6">
                    <label className="form-label">Name</label>
                    <input
                      className="form-control"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      required
                    />
                  </div>

                  {/* Email */}
                  <div className="col-12 col-md-6">
                    <label className="form-label">Email</label>
                    <input
                      type="email"
                      className="form-control"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                    />
                  </div>

                  {/* Password */}
                  <div className="col-12">
                    <label className="form-label">
                      {isEdit ? "Password (leave empty to keep)" : "Password"}
                    </label>
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

                  {/* Roles */}
                  <div className="col-12">
                    <label className="form-label">Roles</label>
                    <div
                      className="border rounded-3 p-2"
                      style={{ maxHeight: 220, overflow: "auto" }}
                    >
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
                        {!allRoles.length && (
                          <div className="text-muted small px-2">No roles</div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
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
                    : "Create User"}
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
  const [rows, setRows] = useState([]);
  const [allRoles, setAllRoles] = useState([]);
  const [message, setMessage] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);

  // modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState(null); // null | {id,name,email,roles:[]}

  const flash = (txt, isErr = false) => {
    (isErr ? setErr : setMessage)(txt);
    setTimeout(() => (isErr ? setErr("") : setMessage("")), 2500);
  };

  const fetchUsers = async () => {
    const { data } = await API.get("/admin/users");
    const list = normalizeList(data);
    return list.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      roles: (u.roles || []).map((r) => r.name),
      created_at: u.created_at,
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

  // Init / re-init DataTable (only when rows change)
  useEffect(() => {
    if (!rows.length) return;
    const table = $("#usersTable").DataTable({
      destroy: true,
      pageLength: 10,
    });
    return () => table.destroy(true);
  }, [rows]);

  const openCreate = () => { setEditing(null); setModalOpen(true); };
  const openEdit = (u) => {
    setEditing({
      id: u.id,
      name: u.name,
      email: u.email,
      roles: u.roles || [],
    });
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

  const deleteUser = async (id) => {
    if (!window.confirm("Delete this user?")) return;
    try {
      const res = await API.delete(`/admin/users/${id}`);
      if (res.status === 204 || res.status === 200) {
        setRows((prev) => prev.filter((u) => u.id !== id));
        flash("User deleted successfully.");
      }
    } catch (e) {
      console.error(e);
      flash(e?.response?.data?.message || "Failed to delete user.", true);
    }
  };

  if (loading) return <div>Loading users…</div>;

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex align-items-center justify-content-between">
          <div className="d-flex align-items-center gap-2">
            <button
              type="button"
              className="btn btn-primary-600 radius-3 px-20 py-11"
              onClick={openCreate}
            >
              <Icon icon="lucide:plus" className="me-1" />
              Add User
            </button>
            {message && <span className="text-success fw-semibold">{message}</span>}
            {err && <span className="text-danger">{err}</span>}
          </div>

          {/* Quick legend */}
          <div className="d-none d-sm-flex align-items-center gap-3 text-muted">
            <small className="d-inline-flex align-items-center gap-1">
              <span className="badge bg-primary-light text-primary-600">A</span> Admin-ish
            </small>
            <small className="d-inline-flex align-items-center gap-1">
              <span className="badge bg-neutral-200">U</span> User
            </small>
          </div>
        </div>

        <div className="card-body">
          <div className="table-responsive">
            <table
              className="table bordered-table mb-0"
              id="usersTable"
              data-page-length={10}
            >
              <thead>
                <tr>
                  <th scope="col" style={{ width: 80 }}>
                    <div className="form-check style-check d-flex align-items-center">
                      <label className="form-check-label">S.L</label>
                    </div>
                  </th>
                  <th scope="col">Name</th>
                  <th scope="col">Email</th>
                  <th scope="col">Roles</th>
                  <th scope="col">Created</th>
                  <th scope="col" style={{ width: 140 }}>Action</th>
                </tr>
              </thead>

              <tbody>
                {rows.map((u, index) => (
                  <tr key={u.id}>
                    <td>
                      <div className="form-check style-check d-flex align-items-center">
                        <input className="form-check-input" type="checkbox" />
                        <label className="form-check-label">{index + 1}</label>
                      </div>
                    </td>

                    <td>
                      <div className="d-flex align-items-center">
                        <Link to={`/admin/users/${u.id}`} className="text-primary-600">
                          {u.name}
                        </Link>
                      </div>
                    </td>

                    <td>
                      <div className="d-flex align-items-center">
                        <h6 className="text-md mb-0 fw-medium flex-grow-1">{u.email}</h6>
                      </div>
                    </td>

                    <td className="text-truncate" style={{ maxWidth: 260 }}>
                      {(u.roles || []).join(", ") || "-"}
                    </td>

                    <td>{u.created_at ? new Date(u.created_at).toLocaleDateString() : "-"}</td>

                    <td>
                      <button
                        onClick={() => openEdit(u)}
                        className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                        title="Edit"
                        type="button"
                      >
                        <Icon icon="lucide:edit" />
                      </button>

                      <button
                        onClick={() => deleteUser(u.id)}
                        className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                        title="Delete"
                        type="button"
                      >
                        <Icon icon="mingcute:delete-2-line" />
                      </button>

                      <Link
                        to={`/admin/users/${u.id}`}
                        className="w-32-px h-32-px bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                        title="View"
                      >
                        <Icon icon="iconamoon:eye-light" />
                      </Link>
                    </td>
                  </tr>
                ))}
                {!rows.length && (
                  <tr>
                    <td colSpan={6} className="text-center text-muted py-4">
                      No users found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Create / Edit Modal */}
      <UserFormModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
        allRoles={allRoles}
        initial={editing}
        saving={saving}
      />
    </MasterLayout>
  );
};

export default AdminUsersPage;
