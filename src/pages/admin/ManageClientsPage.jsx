// src/pages/admin/ManageClientsPage.jsx
import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../../masterLayout/MasterLayout";
import API from "../../helper/api";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminErrorState from "../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../components/admin/common/ConfirmModal";
import AdminPagination from "../../components/admin/common/AdminPagination";

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

  // editing & confirmation modal
  const [editing, setEditing] = useState(null);
  const [search, setSearch] = useState("");
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  const load = async () => {
    setLoading(true);
    setErr("");
    try {
      const res = await API.get("admin/schools");
      setSchools(Array.isArray(res.data) ? res.data : res.data.data || []);
    } catch (e) {
      setErr(e?.response?.data?.message || "Failed to load school clients from server.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 3500);
  };

  const generateKey = async () => {
    try {
      const res = await API.get("admin/schools/generate-key");
      setSchoolKey(res.data.key);
    } catch (e) {
      flash("Failed to generate school key", true);
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
      flash("School client registered successfully");
    } catch (e) {
      flash(e?.response?.data?.message || "Failed to register school client", true);
    }
  };

  const saveEdit = async (e) => {
    e.preventDefault();
    if (!editing) return;
    try {
      await API.put(`admin/schools/${editing.id}`, editing);
      setEditing(null);
      await load();
      flash("School details updated successfully");
    } catch (e) {
      flash(e?.response?.data?.message || "Failed to update school details", true);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await API.delete(`admin/schools/${deleteTarget.id}`);
      setSchools((prev) => prev.filter((s) => s.id !== deleteTarget.id));
      flash("School client deleted successfully");
      setDeleteTarget(null);
    } catch (e) {
      flash(e?.response?.data?.message || "Failed to delete school client", true);
    } finally {
      setDeleting(false);
    }
  };

  const [page, setPage] = useState(1);
  const perPage = 10;

  const filteredSchools = useMemo(() => {
    const t = search.trim().toLowerCase();
    if (!t) return schools;
    return schools.filter(
      (s) =>
        (s.name || "").toLowerCase().includes(t) ||
        (s.school_key || "").toLowerCase().includes(t) ||
        (s.admin_email || "").toLowerCase().includes(t)
    );
  }, [schools, search]);

  const totalPages = Math.ceil(filteredSchools.length / perPage) || 1;

  const paginatedSchools = useMemo(() => {
    const start = (page - 1) * perPage;
    return filteredSchools.slice(start, start + perPage);
  }, [filteredSchools, page, perPage]);

  // Reset to page 1 on search
  useEffect(() => {
    setPage(1);
  }, [search]);

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Manage Clients"
          subtitle="Register, update, and manage institutional client accounts"
        />

        {err && !schools.length && !loading ? (
          <AdminErrorState
            title="Failed to Load Clients"
            message={err}
            onRetry={load}
          />
        ) : (
          <div className="row g-20">
            {/* Create School Form Card */}
            <div className="col-12 col-xl-4">
              <div className="card border radius-12 shadow-none h-100">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold mb-0 text-dark">Create New School</h6>
                </div>
                <div className="card-body p-24">
                  <form onSubmit={createSchool} className="d-flex flex-column gap-16">
                    <div>
                      <label className="form-label text-sm fw-medium text-dark">School Name</label>
                      <input
                        className="form-control radius-8"
                        placeholder="e.g. Angkor High School"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        required
                      />
                    </div>

                    <div>
                      <label className="form-label text-sm fw-medium text-dark">Admin Email</label>
                      <input
                        type="email"
                        className="form-control radius-8"
                        placeholder="admin@school.edu.kh"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        required
                      />
                    </div>

                    <div>
                      <label className="form-label text-sm fw-medium text-dark">Admin Password</label>
                      <input
                        type="password"
                        className="form-control radius-8"
                        placeholder="At least 8 characters"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        minLength={8}
                      />
                    </div>

                    <div>
                      <label className="form-label text-sm fw-medium text-dark">School Key</label>
                      <div className="d-flex align-items-center gap-8">
                        <input
                          className="form-control radius-8 font-monospace"
                          placeholder="e.g. PENPAL001"
                          value={schoolKey}
                          onChange={(e) => setSchoolKey(e.target.value)}
                          required
                        />
                        <button
                          type="button"
                          className="btn btn-outline-secondary radius-8 text-nowrap"
                          onClick={generateKey}
                        >
                          Generate
                        </button>
                      </div>
                    </div>

                    <button type="submit" className="btn btn-primary radius-8 d-inline-flex align-items-center justify-content-center gap-8 mt-8">
                      <Icon icon="lucide:plus" className="text-lg" />
                      <span>Create School</span>
                    </button>

                    {msg && <div className="alert alert-success py-8 px-12 radius-8 text-xs mb-0">{msg}</div>}
                    {err && <div className="alert alert-danger py-8 px-12 radius-8 text-xs mb-0">{err}</div>}
                  </form>
                </div>
              </div>
            </div>

            {/* Schools List Card */}
            <div className="col-12 col-xl-8">
              <div className="card border radius-12 shadow-none h-100">
                <div className="card-header border-bottom py-16 px-24 bg-base d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <h6 className="fw-bold mb-0 text-dark">Registered Schools</h6>
                  <div className="d-flex align-items-center gap-12">
                    <input
                      className="form-control form-control-sm radius-8 min-w-200-px"
                      placeholder="Search schools..."
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                    />
                    <span className="badge bg-neutral-200 text-secondary-light radius-6 text-xs px-10 py-6">
                      {filteredSchools.length} / {schools.length}
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
                  ) : (
                    <div className="table-responsive">
                      <table className="table bordered-table mb-0 align-middle">
                        <thead>
                          <tr>
                            <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16" style={{ width: 60 }}>ID</th>
                            <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">School Name</th>
                            <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">School Key</th>
                            <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Admin Email</th>
                            <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-end" style={{ width: 100 }}>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {paginatedSchools.map((s) => (
                            <tr key={s.id} className="hover-bg-neutral-50 transition-1">
                              <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{s.id}</td>
                              <td className="py-12 px-16 text-sm fw-bold text-dark">{s.name}</td>
                              <td className="py-12 px-16">
                                <span className="fw-bold font-monospace text-primary-600 bg-primary-light px-10 py-4 radius-6 text-xs">
                                  {s.school_key || '-'}
                                </span>
                              </td>
                              <td className="py-12 px-16 text-sm text-secondary-light">{s.admin_email || '-'}</td>
                              <td className="py-12 px-16 text-end">
                                <div className="d-inline-flex align-items-center gap-6">
                                  <button
                                    type="button"
                                    className="w-32-px h-32-px radius-6 bg-primary-light text-primary-600 border-0 d-inline-flex align-items-center justify-content-center"
                                    title="Edit"
                                    onClick={() => setEditing(s)}
                                  >
                                    <Icon icon="lucide:edit" />
                                  </button>
                                  <button
                                    type="button"
                                    className="w-32-px h-32-px radius-6 bg-danger-focus text-danger-main border-0 d-inline-flex align-items-center justify-content-center"
                                    title="Delete"
                                    onClick={() => setDeleteTarget(s)}
                                  >
                                    <Icon icon="mingcute:delete-2-line" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          ))}
                          {!filteredSchools.length && (
                            <tr>
                              <td colSpan={5} className="text-center text-secondary-light py-32">
                                No schools match your search query.
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}

                  {/* Inline Edit Card */}
                  {editing && (
                    <div className="m-20 border radius-12 p-20 bg-base">
                      <div className="d-flex align-items-center justify-content-between mb-16 pb-8 border-bottom">
                        <h6 className="fw-bold text-dark mb-0">Edit School: {editing.name}</h6>
                        <button
                          className="btn-close"
                          type="button"
                          onClick={() => setEditing(null)}
                        />
                      </div>

                      <form onSubmit={saveEdit} className="d-flex flex-column gap-12">
                        <div>
                          <label className="form-label text-xs fw-medium text-secondary-light">School Name</label>
                          <input
                            className="form-control radius-8"
                            value={editing.name || ""}
                            onChange={(e) => setEditing((o) => ({ ...o, name: e.target.value }))}
                            required
                          />
                        </div>
                        <div>
                          <label className="form-label text-xs fw-medium text-secondary-light">Admin Email</label>
                          <input
                            className="form-control radius-8"
                            value={editing.admin_email || ""}
                            onChange={(e) => setEditing((o) => ({ ...o, admin_email: e.target.value }))}
                            required
                          />
                        </div>
                        <div>
                          <label className="form-label text-xs fw-medium text-secondary-light">School Key</label>
                          <input
                            className="form-control radius-8 font-monospace"
                            value={editing.school_key || ""}
                            onChange={(e) => setEditing((o) => ({ ...o, school_key: e.target.value }))}
                            required
                          />
                        </div>
                        <div className="d-flex gap-8 mt-8">
                          <button className="btn btn-primary btn-sm radius-8" type="submit">
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

                {/* ── Card Footer Pagination ── */}
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {filteredSchools.length > 0 ? (page - 1) * perPage + 1 : 0}–
                    {Math.min(page * perPage, filteredSchools.length)} of {filteredSchools.length} entries
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
            </div>
          </div>
        )}

        {/* Destructive Action Modal */}
        <ConfirmModal
          open={Boolean(deleteTarget)}
          title="Delete School Account"
          message={`Are you sure you want to delete "${deleteTarget?.name}"? This action cannot be undone.`}
          confirmLabel="Delete School"
          variant="danger"
          loading={deleting}
          onConfirm={handleConfirmDelete}
          onCancel={() => setDeleteTarget(null)}
        />
      </div>
    </MasterLayout>
  );
}
