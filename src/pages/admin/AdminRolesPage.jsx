// src/pages/admin/AdminRolesPage.jsx
import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../components/admin/common/ConfirmModal";

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
    <div className="border radius-12 p-16 bg-neutral-50">
      <div className="d-flex flex-wrap gap-8 align-items-center justify-content-between mb-12">
        <div className="position-relative flex-grow-1 min-w-160-px" style={{ maxWidth: "260px" }}>
          <input
            type="text"
            className="form-control form-control-sm radius-8"
            placeholder="Search permissions…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            style={{ paddingRight: "36px" }}
          />
          <Icon
            icon="ion:search-outline"
            className="position-absolute end-0 top-50 translate-middle-y text-secondary-light text-base pointer-events-none"
            style={{ marginRight: "12px" }}
          />
        </div>
        <div className="d-flex align-items-center gap-6">
          <button
            type="button"
            className="btn btn-sm btn-outline-primary radius-6 px-10 py-4 fw-medium text-xs"
            onClick={selectAll}
          >
            Select All
          </button>
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary radius-6 px-10 py-4 fw-medium text-xs"
            onClick={selectNone}
          >
            Clear
          </button>
        </div>
      </div>

      <div className="row g-2" style={{ maxHeight: 240, overflowY: "auto" }}>
        {filtered.map((p) => {
          const isChecked = value.includes(p.name);
          return (
            <div className="col-12 col-sm-6" key={p.id || p.name}>
              <label className="form-check d-flex align-items-center gap-2 cursor-pointer mb-0 py-4">
                <input
                  type="checkbox"
                  className="form-check-input mt-0 radius-4"
                  checked={isChecked}
                  onChange={() => toggle(p.name)}
                />
                <span className="form-check-label text-xs">
                  {p.name}
                </span>
              </label>
            </div>
          );
        })}
        {!filtered.length && (
          <div className="col-12 text-center text-muted text-xs py-12">
            No permissions matching search criteria.
          </div>
        )}
      </div>
    </div>
  );
}

export default function AdminRolesPage() {
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
        API.get("admin/roles"),
        API.get("admin/permissions"),
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
      await API.post("admin/roles", { name, permissions: perms });
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
      await API.put(`admin/roles/${editing.id}`, {
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

  const [deleteModal, setDeleteModal] = useState(null); // role to delete
  const [deleteLoading, setDeleteLoading] = useState(false);

  const handleDeleteRole = (role) => {
    setDeleteModal(role);
  };

  const confirmDeleteRole = async () => {
    if (!deleteModal) return;
    try {
      setDeleteLoading(true);
      await API.delete(`admin/roles/${deleteModal.id}`);
      setRoles((prev) => prev.filter((r) => r.id !== deleteModal.id));
      flash("Role deleted");
      setDeleteModal(null);
    } catch (e) {
      flash(e?.response?.data?.message || "Delete failed", true);
    } finally {
      setDeleteLoading(false);
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

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Roles & Access Control"
          subtitle="Define custom security roles, assign permission groups, and manage administrative privileges"
        />

        {msg && <div className="alert alert-success py-12 px-16 radius-8 text-sm mb-16">{msg}</div>}

        {err && !roles.length && !loading ? (
          <AdminErrorState
            title="Failed to Load Roles"
            message={err}
            onRetry={load}
          />
        ) : (
          <div className="row g-4">
            {/* Create Role */}
            <div className="col-12 col-xl-5">
              <div className="card border radius-12 shadow-none h-100">
                <div className="card-header border-bottom py-16 px-24 bg-base d-flex align-items-center justify-content-between">
                  <h6 className="fw-bold mb-0 text-dark">Add New Role</h6>
                  <span className="badge bg-primary-light text-primary-600 px-10 py-4 radius-6 text-xs fw-semibold">
                    {allPerms.length} Available Perms
                  </span>
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

                <div className="card-body p-0">
                  <div className="table-responsive">
                    <table className="table bordered-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th style={{ width: 70 }} className="px-16">ID</th>
                          <th className="px-16">Name</th>
                          <th style={{ width: 130 }} className="px-16"># Perms</th>
                          <th className="px-16">Permissions</th>
                          <th style={{ width: 120 }} className="pe-16 text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredRoles.map((r) => {
                          const permNames = (r.permissions || []).map((p) => p.name);
                          const permPreview =
                            permNames.length > 0 ? permNames.join(", ") : "—";

                          return (
                            <tr key={r.id}>
                              <td className="px-16 font-monospace text-secondary-light">{r.id}</td>
                              <td className="fw-semibold px-16 text-dark">{r.name}</td>
                              <td className="px-16">
                                <span className="badge bg-primary-light text-primary-600">
                                  {permNames.length}
                                </span>
                              </td>
                              <td className="text-truncate px-16 text-sm text-secondary-light" style={{ maxWidth: 360 }}>
                                {permPreview}
                              </td>
                              <td className="pe-16 text-end">
                                <div className="d-inline-flex align-items-center justify-content-end gap-2">
                                  <button
                                    type="button"
                                    className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                    title="Edit"
                                    onClick={() => startEdit(r)}
                                  >
                                    <Icon icon="lucide:edit" />
                                  </button>
                                  <button
                                    type="button"
                                    className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                    title="Delete"
                                    onClick={() => handleDeleteRole(r)}
                                  >
                                    <Icon icon="mingcute:delete-2-line" />
                                  </button>
                                </div>
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
                </div>

                {/* ── Card Footer ── */}
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {filteredRoles.length > 0 ? 1 : 0}–{filteredRoles.length} of {filteredRoles.length} entries
                  </div>
                </div>

                {/* Inline Edit Panel */}
                {editing && (
                  <div className="m-20 border radius-12 p-20 bg-base">
                    <div className="d-flex align-items-center justify-content-between mb-16 pb-8 border-bottom">
                      <h6 className="fw-bold text-dark mb-0">Edit Role: {editing.name}</h6>
                      <button
                        className="btn-close"
                        type="button"
                        onClick={() => setEditing(null)}
                      />
                    </div>

                    <form onSubmit={saveEdit} className="d-flex flex-column gap-12">
                      <div>
                        <label className="form-label text-xs fw-medium text-secondary-light">Role name</label>
                        <input
                          className="form-control radius-8"
                          value={editing.name}
                          onChange={(e) =>
                            setEditing((old) => ({ ...old, name: e.target.value }))
                          }
                          required
                        />
                      </div>

                      <div>
                        <label className="form-label text-xs fw-medium text-secondary-light">Permissions</label>
                        <PermissionPicker
                          allPerms={allPerms}
                          value={editing.permissions}
                          onChange={(v) => setEditing((old) => ({ ...old, permissions: v }))}
                        />
                      </div>

                      <div className="d-flex gap-8 mt-8">
                        <button className="btn btn-primary btn-sm radius-8" type="submit">
                          <Icon icon="solar:check-circle-linear" className="me-1" />
                          Save Changes
                        </button>
                        <button
                          className="btn btn-outline-secondary btn-sm radius-8"
                          type="button"
                          onClick={() => setEditing(null)}
                        >
                          Cancel
                        </button>
                      </div>
                    </form>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
        <ConfirmModal
          open={!!deleteModal}
          title="Delete Security Role"
          message={deleteModal ? `Are you sure you want to delete role "${deleteModal.name}"? Users assigned to this role will lose its permissions.` : ""}
          confirmLabel="Delete Role"
          variant="danger"
          loading={deleteLoading}
          onConfirm={confirmDeleteRole}
          onCancel={() => setDeleteModal(null)}
        />
      </div>
    </MasterLayout>
  );
}
