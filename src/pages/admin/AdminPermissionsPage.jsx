// src/pages/admin/AdminPermissionsPage.jsx
import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";

// Reusable modal
function PermissionModal({ open, onClose, onSubmit, initial, saving }) {
  const isEdit = Boolean(initial?.id);
  const [name, setName] = useState(initial?.name || "");

  useEffect(() => {
    setName(initial?.name || "");
  }, [initial, open]);

  if (!open) return null;

  return (
    <div className="modal-backdrop show" style={{ display: "block" }}>
      <div className="modal d-block" tabIndex={-1} role="dialog" onClick={onClose}>
        <div
          className="modal-dialog modal-dialog-centered"
          role="document"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="modal-content">
            <div className="modal-header">
              <h6 className="modal-title">{isEdit ? "Edit Permission" : "Add Permission"}</h6>
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
                <small className="text-muted d-block mt-1">
                  Use a consistent naming pattern like <code>resource.action</code>.
                </small>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-light" onClick={onClose}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? "Saving…" : isEdit ? "Save Changes" : "Create Permission"}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
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

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return perms;
    return perms.filter((p) => p.name.toLowerCase().includes(s));
  }, [q, perms]);

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

  const deletePerm = async (p) => {
    if (!window.confirm(`Delete permission "${p.name}"?`)) return;
    try {
      await API.delete(`admin/permissions/${p.id}`);
      setPerms((prev) => prev.filter((x) => x.id !== p.id));
      showFlash("Permission deleted");
    } catch (e) {
      showErr(e?.response?.data?.message || "Delete failed");
    }
  };

  if (loading) return <div>Loading permissions…</div>;

  return (
    <MasterLayout>
      <div className="card p-3">
        <div className="d-flex flex-wrap gap-2 align-items-center justify-content-between mb-3">
          <div className="d-flex align-items-center gap-2">
            <h5 className="mb-0">Permissions</h5>
            <span className="badge bg-neutral-200 text-dark">{perms.length}</span>
          </div>

          <div className="d-flex gap-2">
            <div className="input-group">
              <span className="input-group-text">
                <Icon icon="ion:search-outline" />
              </span>
              <input
                className="form-control"
                placeholder="Search permissions…"
                value={q}
                onChange={(e) => setQ(e.target.value)}
              />
            </div>

            <button className="btn btn-primary" onClick={openCreate}>
              <Icon icon="lucide:plus" className="me-1" />
              Add
            </button>
          </div>
        </div>

        {(flash || err) && (
          <div className="mb-3">
            {flash && <div className="alert alert-success py-2 mb-2">{flash}</div>}
            {err && <div className="alert alert-danger py-2">{err}</div>}
          </div>
        )}

        <div className="table-responsive">
          <table className="table align-middle">
            <thead>
              <tr>
                <th style={{ width: 90 }}>ID</th>
                <th>Name</th>
                <th style={{ width: 140 }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => (
                <tr key={p.id}>
                  <td>{p.id}</td>
                  <td>
                    <span className="badge bg-primary-light text-primary-600 rounded-pill px-3 py-2">
                      {p.name}
                    </span>
                  </td>
                  <td>
                    <div className="d-flex align-items-center gap-2">
                      <button
                        type="button"
                        className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                        title="Edit"
                        onClick={() => openEdit(p)}
                      >
                        <Icon icon="lucide:edit" />
                      </button>
                      <button
                        type="button"
                        className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                        title="Delete"
                        onClick={() => deletePerm(p)}
                      >
                        <Icon icon="mingcute:delete-2-line" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}

              {!filtered.length && (
                <tr>
                  <td colSpan={3} className="text-center text-muted py-4">
                    No permissions found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Create / Edit modal */}
      <PermissionModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
        initial={editing}
        saving={saving}
      />
    </MasterLayout>
  );
}
