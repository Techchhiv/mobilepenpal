import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../../helper/api";
import SchoolLayout from "../masterLayout/SchoolLayout";
const normalizeList = (payload, key = "data") =>
  Array.isArray(payload) ? payload : Array.isArray(payload?.[key]) ? payload[key] : [];

function PermissionPicker({ allPerms = [], value = [], onChange }) {
  const [q, setQ] = useState("");

  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    return term
      ? allPerms.filter((p) => p.name.toLowerCase().includes(term))
      : allPerms;
  }, [q, allPerms]);

  const toggle = (name) =>
    value.includes(name)
      ? onChange(value.filter((v) => v !== name))
      : onChange([...value, name]);

  const selectAll = () => onChange(filtered.map((p) => p.name));
  const selectNone = () => onChange([]);

  return (
    <div className="border rounded-3 p-2">
      <div className="d-flex gap-2 align-items-center mb-2">
        <div className="position-relative flex-grow-1">
          <input
            className="form-control"
            placeholder="Search permissions…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <Icon icon="ion:search-outline" className="position-absolute end-2 top-50 translate-middle-y" />
        </div>
        <button type="button" className="btn btn-light" onClick={selectAll}>
          Select all
        </button>
        <button type="button" className="btn btn-light" onClick={selectNone}>
          None
        </button>
      </div>

      <div className="row g-2" style={{ maxHeight: 260, overflow: "auto" }}>
        {filtered.map((p) => (
          <div className="col-12 col-sm-6" key={p.id || p.name}>
            <label className="form-check d-flex align-items-center gap-2">
              <input
                type="checkbox"
                className="form-check-input"
                checked={value.includes(p.name)}
                onChange={() => toggle(p.name)}
              />
              <span className="form-check-label">{p.name}</span>
            </label>
          </div>
        ))}
        {!filtered.length && <div className="text-muted small px-2">No permissions</div>}
      </div>
    </div>
  );
}

export default function SchoolRolesPage() {
  const [roles, setRoles] = useState([]);
  const [allPerms, setAllPerms] = useState([]);

  // create form
  const [name, setName] = useState("");
  const [perms, setPerms] = useState([]);

  // edit state
  const [editing, setEditing] = useState(null); // { id, name, permissions:[] }

  // ui
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [roleSearch, setRoleSearch] = useState("");

  const load = async () => {
    setLoading(true);
    setErr("");
    try {
      const [rRes, pRes] = await Promise.all([
        API.get("school/roles"),
        API.get("school/permissions"),
      ]);

      const rList = normalizeList(rRes.data); // accepts [] or {data:[]}
      const pList = normalizeList(pRes.data); // accepts [] or {data:[]}

      // Ensure each role has permissions array (Spatie often returns permissions on eager load)
      setRoles(
        rList.map((r) => ({
          id: r.id,
          name: r.name,
          permissions: normalizeList(r.permissions, undefined).length
            ? r.permissions
            : (r.permissions || []),
        }))
      );
      setAllPerms(pList.map((p) => ({ id: p.id, name: p.name })));
    } catch (e) {
      setErr(e?.response?.data?.message || e.message || "Failed to load roles/permissions");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  // feedback helper
  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 2500);
  };

  const createRole = async (e) => {
    e.preventDefault();
    try {
      await API.post("school/roles", { name, permissions: perms });
      setName("");
      setPerms([]);
      await load();
      flash("Role created");
    } catch (e) {
      flash(e?.response?.data?.message || "Create failed", true);
    }
  };

  const startEdit = (role) => {
    setEditing({
      id: role.id,
      name: role.name,
      permissions: (role.permissions || []).map((p) => p.name),
    });
  };

  const saveEdit = async (e) => {
    e.preventDefault();
    if (!editing) return;
    try {
      await API.put(`school/roles/${editing.id}`, {
        name: editing.name,
        permissions: editing.permissions,
      });
      setEditing(null);
      await load();
      flash("Role updated");
    } catch (e) {
      flash(e?.response?.data?.message || "Update failed", true);
    }
  };

  const deleteRole = async (role) => {
    if (!window.confirm(`Delete role "${role.name}"?`)) return;
    try {
      await API.delete(`school/roles/${role.id}`);
      setRoles((prev) => prev.filter((r) => r.id !== role.id));
      flash("Role deleted");
    } catch (e) {
      flash(e?.response?.data?.message || "Delete failed", true);
    }
  };

  const filteredRoles = useMemo(() => {
    const t = roleSearch.trim().toLowerCase();
    if (!t) return roles;
    return roles.filter(
      (r) =>
        r.name.toLowerCase().includes(t) ||
        (r.permissions || []).some((p) => p.name.toLowerCase().includes(t))
    );
  }, [roles, roleSearch]);

  if (loading) return <div>Loading roles…</div>;
  if (err && !roles.length) return <div className="text-danger">Error: {err}</div>;

  return (
   <SchoolLayout>
           <div className="row g-4">
      {/* Create Role */}
      <div className="col-12 col-xl-5">
        <div className="card h-100">
          <div className="card-header d-flex align-items-center justify-content-between">
            <h6 className="mb-0">Add New Role</h6>
            <span className="badge bg-primary-600 text-white">{allPerms.length} perms</span>
          </div>
          <div className="card-body">
            <form onSubmit={createRole} className="d-flex flex-column gap-3">
              <div>
                <label className="form-label">Role name</label>
                <input
                  className="form-control"
                  placeholder="e.g. editor"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="form-label">Permissions</label>
                <PermissionPicker
                  allPerms={allPerms}
                  value={perms}
                  onChange={setPerms}
                />
              </div>

              <div className="d-flex gap-2">
                <button className="btn btn-primary">
                  <Icon icon="lucide:plus" className="me-1" />
                  Create Role
                </button>
                {msg && <span className="text-success fw-semibold">{msg}</span>}
                {err && <span className="text-danger">{err}</span>}
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Roles Table */}
      <div className="col-12 col-xl-7">
        <div className="card h-100">
          <div className="card-header d-flex align-items-center justify-content-between">
            <h6 className="mb-0">Roles</h6>
            <div className="d-flex align-items-center gap-2">
              <input
                className="form-control"
                placeholder="Search roles or permissions…"
                value={roleSearch}
                onChange={(e) => setRoleSearch(e.target.value)}
              />
              <span className="badge bg-neutral-200 text-neutral-800">
                {filteredRoles.length} / {roles.length}
              </span>
            </div>
          </div>

          <div className="card-body">
            <div className="table-responsive">
              <table className="table bordered-table mb-0">
                <thead>
                  <tr>
                    <th style={{ width: 70 }}>ID</th>
                    <th>Name</th>
                    <th style={{ width: 130 }}># Perms</th>
                    <th>Permissions</th>
                    <th style={{ width: 120 }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRoles.map((r) => {
                    const permNames = (r.permissions || []).map((p) => p.name);
                    const permPreview =
                      permNames.length > 0 ? permNames.join(", ") : "—";

                    return (
                      <tr key={r.id}>
                        <td>{r.id}</td>
                        <td className="fw-semibold">{r.name}</td>
                        <td>
                          <span className="badge bg-primary-light text-primary-600">
                            {permNames.length}
                          </span>
                        </td>
                        <td className="text-truncate" style={{ maxWidth: 360 }}>
                          {permPreview}
                        </td>
                        <td>
                          <button
                            type="button"
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title="Edit"
                            onClick={() => startEdit(r)}
                          >
                            <Icon icon="lucide:edit" />
                          </button>
                          <button
                            type="button"
                            className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title="Delete"
                            onClick={() => deleteRole(r)}
                          >
                            <Icon icon="mingcute:delete-2-line" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                  {!filteredRoles.length && (
                    <tr>
                      <td colSpan={5} className="text-center text-muted py-4">
                        No roles found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Inline Edit Panel */}
            {editing && (
              <div className="mt-4 border rounded-3 p-3">
                <div className="d-flex align-items-center justify-content-between mb-2">
                  <h6 className="mb-0">Edit Role: {editing.name}</h6>
                  <button
                    className="btn btn-light"
                    type="button"
                    onClick={() => setEditing(null)}
                  >
                    <Icon icon="radix-icons:cross-2" />
                  </button>
                </div>

                <form onSubmit={saveEdit} className="d-flex flex-column gap-3">
                  <div>
                    <label className="form-label">Role name</label>
                    <input
                      className="form-control"
                      value={editing.name}
                      onChange={(e) =>
                        setEditing((old) => ({ ...old, name: e.target.value }))
                      }
                      required
                    />
                  </div>

                  <div>
                    <label className="form-label">Permissions</label>
                    <PermissionPicker
                      allPerms={allPerms}
                      value={editing.permissions}
                      onChange={(v) => setEditing((old) => ({ ...old, permissions: v }))}
                    />
                  </div>

                  <div className="d-flex gap-2">
                    <button className="btn btn-primary" type="submit">
                      <Icon icon="solar:check-circle-linear" className="me-1" />
                      Save Changes
                    </button>
                    <button
                      className="btn btn-light"
                      type="button"
                      onClick={() => setEditing(null)}
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            )}

            {msg && <div className="text-success fw-semibold mt-3">{msg}</div>}
            {err && <div className="text-danger mt-2">{err}</div>}
          </div>
        </div>
      </div>
    </div>
   </SchoolLayout>
  );
}
