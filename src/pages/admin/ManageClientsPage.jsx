// src/pages/admin/ManageClientsPage.jsx
import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../../masterLayout/MasterLayout";
import API from "../../helper/api";

export default function ManageClientsPage() {
  const [schools, setSchools] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");

  // create form
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [schoolKey, setSchoolKey] = useState("");

  // editing
  const [editing, setEditing] = useState(null);
  const [search, setSearch] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const res = await API.get("admin/schools"); // backend: GET /admin/schools
      setSchools(Array.isArray(res.data) ? res.data : res.data.data || []);
    } catch (e) {
      setErr(e?.response?.data?.message || "Failed to load schools");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 2500);
  };

  // generate school key via backend
  const generateKey = async () => {
    try {
      const res = await API.get("admin/schools/generate-key");
      setSchoolKey(res.data.key);
    } catch (e) {
      flash("Failed to generate key", true);
    }
  };

  const createSchool = async (e) => {
    e.preventDefault();
    try {
      await API.post("admin/schools", { name, email, password, school_key: schoolKey });
      setName("");
      setEmail("");
      setPassword("");
      setSchoolKey("");
      await load();
      flash("School created");
    } catch (e) {
      flash(e?.response?.data?.message || "Create failed", true);
    }
  };

  const saveEdit = async (e) => {
    e.preventDefault();
    if (!editing) return;
    try {
      await API.put(`admin/schools/${editing.id}`, editing);
      setEditing(null);
      await load();
      flash("School updated");
    } catch (e) {
      flash(e?.response?.data?.message || "Update failed", true);
    }
  };

  const deleteSchool = async (id) => {
    if (!window.confirm("Delete this school?")) return;
    try {
      await API.delete(`admin/schools/${id}`);
      setSchools((prev) => prev.filter((s) => s.id !== id));
      flash("School deleted");
    } catch (e) {
      flash(e?.response?.data?.message || "Delete failed", true);
    }
  };

  const filteredSchools = useMemo(() => {
    const t = search.trim().toLowerCase();
    if (!t) return schools;
    return schools.filter(
      (s) =>
        s.name.toLowerCase().includes(t) ||
        (s.school_key || "").toLowerCase().includes(t) ||
        (s.admin_email || "").toLowerCase().includes(t)
    );
  }, [schools, search]);

  if (loading) return <div>Loading schools…</div>;

  return (
    <MasterLayout>
      <div className="row g-4">
        {/* Create School */}
        <div className="col-12 col-xl-4">
          <div className="card h-100">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h6 className="mb-0">Create New School</h6>
            </div>
            <div className="card-body">
              <form onSubmit={createSchool} className="d-flex flex-column gap-3">
                <div>
                  <label className="form-label">School Name</label>
                  <input
                    className="form-control"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                  />
                </div>

                <div>
                  <label className="form-label">Admin Email</label>
                  <input
                    type="email"
                    className="form-control"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>

                <div>
                  <label className="form-label">Admin Password</label>
                  <input
                    type="password"
                    className="form-control"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>

                <div className="d-flex align-items-center gap-2">
                  <div className="flex-grow-1">
                    <label className="form-label">School Key</label>
                    <input
                      className="form-control"
                      value={schoolKey}
                      onChange={(e) => setSchoolKey(e.target.value)}
                      required
                    />
                  </div>
                  <button type="button" className="btn btn-light mt-4" onClick={generateKey}>
                    Generate
                  </button>
                </div>

                <button className="btn btn-primary">
                  <Icon icon="lucide:plus" className="me-1" />
                  Create School
                </button>
                {msg && <span className="text-success">{msg}</span>}
                {err && <span className="text-danger">{err}</span>}
              </form>
            </div>
          </div>
        </div>

        {/* Schools Table */}
        <div className="col-12 col-xl-8">
          <div className="card h-100">
            <div className="card-header d-flex align-items-center justify-content-between">
              <h6 className="mb-0">Schools</h6>
              <div className="d-flex align-items-center gap-2">
                <input
                  className="form-control"
                  placeholder="Search schools…"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
                <span className="badge bg-neutral-200 text-neutral-800">
                  {filteredSchools.length} / {schools.length}
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
                      <th>School Key</th>
                      <th>Admin Email</th>
                      <th style={{ width: 120 }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredSchools.map((s) => (
                      <tr key={s.id}>
                        <td>{s.id}</td>
                        <td className="fw-semibold">{s.name}</td>
                        <td>
                          <span className="badge bg-primary-light text-primary-600">
                            {s.school_key}
                          </span>
                        </td>
                        <td>{s.admin_email}</td>
                        <td>
                          <button
                            type="button"
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title="Edit"
                            onClick={() => setEditing(s)}
                          >
                            <Icon icon="lucide:edit" />
                          </button>
                          <button
                            type="button"
                            className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title="Delete"
                            onClick={() => deleteSchool(s.id)}
                          >
                            <Icon icon="mingcute:delete-2-line" />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {!filteredSchools.length && (
                      <tr>
                        <td colSpan={5} className="text-center text-muted py-4">
                          No schools found.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Inline Edit */}
              {editing && (
                <div className="mt-4 border rounded-3 p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <h6 className="mb-0">Edit School: {editing.name}</h6>
                    <button
                      className="btn btn-light"
                      type="button"
                      onClick={() => setEditing(null)}
                    >
                      <Icon icon="radix-icons:cross-2" />
                    </button>
                  </div>

                  <form onSubmit={saveEdit} className="d-flex flex-column gap-3">
                    <input
                      className="form-control"
                      value={editing.name}
                      onChange={(e) => setEditing((o) => ({ ...o, name: e.target.value }))}
                    />
                    <input
                      className="form-control"
                      value={editing.admin_email}
                      onChange={(e) =>
                        setEditing((o) => ({ ...o, admin_email: e.target.value }))
                      }
                    />
                    <input
                      className="form-control"
                      value={editing.school_key}
                      onChange={(e) =>
                        setEditing((o) => ({ ...o, school_key: e.target.value }))
                      }
                    />
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
    </MasterLayout>
  );
}
