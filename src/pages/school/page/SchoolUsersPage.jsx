import React, { useEffect, useMemo, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../../helper/api";
import SchoolLayout from "../masterLayout/SchoolLayout";

// Helper to normalize response
const normalizeList = (payload) =>
  Array.isArray(payload) ? payload : Array.isArray(payload?.data) ? payload.data : [];

function UserFormModal({ open, onClose, onSubmit, allRoles, initial, saving }) {
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

 const tenantRoleNames = useMemo(
    () => allRoles.map(r => r.name).filter(n => n !== "school-admin"),
    [allRoles]
  );

  const toggleRole = (rName) => {
    setRoles(prev => {
      const has = prev.includes(rName);

      // special behavior for school-admin
      if (rName === "school-admin") {
        if (has) {
          // uncheck only school-admin; keep whatever else is currently checked
          return prev.filter(n => n !== "school-admin");
        } else {
          // checking school-admin => select every tenant role too
          const merged = Array.from(new Set(["school-admin", ...tenantRoleNames, ...prev]));
          return merged;
        }
      }

      // normal toggle
      return has ? prev.filter(n => n !== rName) : [...prev, rName];
    });
  };

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
                  password: password || undefined,
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
                              
                              <input type="checkbox" className="form-check-input" checked={roles.includes(r.name)} onChange={() => toggleRole(r.name)} />
                              <span className="form-check-label">{r.name}</span>
                            </label>
                          </div>
                        ))}
                        {!allRoles.length && <div className="text-muted small px-2">No roles available for this school</div>}
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

const SchoolUsersPage = () => {
  const [rows, setRows] = useState([]);
  const [allRoles, setAllRoles] = useState([]);
  const [message, setMessage] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState(null);

  const flash = (txt, isErr = false) => {
    (isErr ? setErr : setMessage)(txt);
    setTimeout(() => (isErr ? setErr("") : setMessage("")), 2500);
  };

  // Fetch only users/roles for this school
  const fetchUsers = async () => {
    const { data } = await API.get("/school/users");
    return normalizeList(data).map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      roles: (u.roles || []).map((r) => r.name),
      created_at: u.created_at,
    }));
  };

 const fetchRoles = async () => {
  const { data } = await API.get("/school/roles");
  const list = normalizeList(data).map(r => ({ id: r.id, name: r.name }));

  // make sure global school-admin appears in the picker
  if (!list.find(r => r.name === "school-admin")) {
    list.unshift({ id: "global-school-admin", name: "school-admin" });
  }
  return list;
};

  const load = async () => {
    setLoading(true);
    setErr("");
    try {
      const [users, roles] = await Promise.all([fetchUsers(), fetchRoles()]);
      setRows(users);
      setAllRoles(roles);
    } catch (e) {
      console.error("Load failed:", e?.response?.data || e);
      flash(e?.response?.data?.message || "Failed to load users/roles", true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  // DataTable init
  useEffect(() => {
    if (!rows.length) return;
    const table = $("#usersTable").DataTable({ destroy: true, pageLength: 10 });
    return () => table.destroy(true);
  }, [rows]);

  const openCreate = () => { setEditing(null); setModalOpen(true); };
  const openEdit = (u) => {
  const tenantRoleNames = allRoles.map(r => r.name).filter(n => n !== "school-admin");
  const hasSchoolAdmin = (u.roles || []).includes("school-admin");

  setEditing({
    id: u.id,
    name: u.name,
    email: u.email,
    roles: hasSchoolAdmin ? ["school-admin", ...tenantRoleNames] : (u.roles || []),
  });
  setModalOpen(true);
};


  const handleSubmit = async (payload) => {
    setSaving(true);
    try {
      if (payload.id) {
        await API.put(`/school/users/${payload.id}`, {
          name: payload.name,
          email: payload.email,
          ...(payload.password ? { password: payload.password } : {}),
          roles: payload.roles,
        });
        flash("User updated");
      } else {
        await API.post("/school/users", {
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
      const res = await API.delete(`/school/users/${id}`);
      if (res.status === 204 || res.status === 200) {
        setRows((prev) => prev.filter((u) => u.id !== id));
        flash("User deleted successfully");
      }
    } catch (e) {
      console.error(e);
      flash(e?.response?.data?.message || "Failed to delete user", true);
    }
  };

  if (loading) return <div>Loading users…</div>;

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex align-items-center justify-content-between">
          <button className="btn btn-primary" onClick={openCreate}>
            <Icon icon="lucide:plus" /> Add User
          </button>
          {message && <span className="text-success">{message}</span>}
          {err && <span className="text-danger">{err}</span>}
        </div>

        <div className="card-body">
          <div className="table-responsive">
            <table className="table" id="usersTable">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Roles</th>
                  <th>Created</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((u, i) => (
                  <tr key={u.id}>
                    <td>{i + 1}</td>
                    <td><Link to={`/school/users/${u.id}`}>{u.name}</Link></td>
                    <td>{u.email}</td>
                    <td>{(u.roles || []).join(", ")}</td>
                    <td>{u.created_at ? new Date(u.created_at).toLocaleDateString() : "-"}</td>
                    <td>
                      <button onClick={() => openEdit(u)} className="btn btn-sm btn-success">Edit</button>
                      <button onClick={() => deleteUser(u.id)} className="btn btn-sm btn-danger">Delete</button>
                    </td>
                  </tr>
                ))}
                {!rows.length && <tr><td colSpan={6} className="text-center">No users found.</td></tr>}
              </tbody>
            </table>
          </div>
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
    </SchoolLayout>
  );
};

export default SchoolUsersPage;
