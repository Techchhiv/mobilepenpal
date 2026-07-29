import React, { useEffect, useState, useCallback } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";
import API_BASE_URL from "../../../helper/Base_urls";

const Trunc = ({ value, maxWidth = 200 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

export default function AdminStudentList() {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  // Filters
  const [search, setSearch] = useState("");
  const [schoolAffiliation, setSchoolAffiliation] = useState("all");
  const [activeFilter, setActiveFilter] = useState("all");
  const [schools, setSchools] = useState([]);
  const [selectedSchoolId, setSelectedSchoolId] = useState("");

  // Pagination
  const [page, setPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);
  const [total, setTotal] = useState(0);
  const perPage = 15;

  // Image preview
  const [previewSrc, setPreviewSrc] = useState(null);

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && setPreviewSrc(null);
    if (previewSrc) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [previewSrc]);

  // Load schools for the filter dropdown
  useEffect(() => {
    API.get("/schools/list")
      .then((res) => {
        const list = res.data?.data || res.data || [];
        setSchools(Array.isArray(list) ? list : []);
      })
      .catch(() => {});
  }, []);

  const flash = (text, isError = false) => {
    (isError ? setError : setMessage)(text);
    setTimeout(() => (isError ? setError("") : setMessage("")), 3000);
  };

  const fullName = (s) =>
    [s?.first_name, s?.last_name].filter(Boolean).join(" ").trim() || "—";

  const avatarUrl = (avatar) => {
    if (!avatar) return null;
    return String(avatar).startsWith("http")
      ? avatar
      : `${API_BASE_URL}/${String(avatar).replace(/^\/+/, "")}`;
  };

  const fetchStudents = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = { page, per_page: perPage };
      if (search.trim()) params.search = search.trim();
      if (schoolAffiliation !== "all") params.school_affiliation = schoolAffiliation;
      if (activeFilter !== "all") params.is_active = activeFilter === "active";
      if (selectedSchoolId) params.school_id = selectedSchoolId;

      const res = await API.get("/admin/students", { params });
      const data = res.data?.data?.students || res.data?.students || {};
      const rows = Array.isArray(data?.data) ? data.data : Array.isArray(data) ? data : [];
      setStudents(rows);
      setLastPage(data?.last_page || 1);
      setTotal(data?.total || rows.length);
    } catch (err) {
      setError(err?.response?.data?.message || "Failed to load students");
    } finally {
      setLoading(false);
    }
  }, [page, search, schoolAffiliation, activeFilter, selectedSchoolId]);

  useEffect(() => {
    fetchStudents();
  }, [fetchStudents]);

  // Reset to page 1 when filters change
  useEffect(() => {
    setPage(1);
  }, [search, schoolAffiliation, activeFilter, selectedSchoolId]);

  const toggleStudent = async (id) => {
    try {
      const res = await API.put(`/admin/students/${id}/toggle`);
      const updated = res.data?.data?.student;
      if (updated) {
        setStudents((prev) =>
          prev.map((s) => (s.id === id ? { ...s, is_active: updated.is_active } : s))
        );
      } else {
        fetchStudents();
      }
      flash("Student status updated");
    } catch (err) {
      flash(err?.response?.data?.message || "Toggle failed", true);
    }
  };

  const deleteStudent = async (id) => {
    if (!window.confirm("Are you sure you want to delete this student?")) return;
    try {
      await API.delete(`/admin/students/${id}`);
      setStudents((prev) => prev.filter((s) => s.id !== id));
      flash("Student deleted successfully");
    } catch (err) {
      flash(err?.response?.data?.message || "Delete failed", true);
    }
  };

  const isActive = (s) =>
    s?.is_active === true || String(s?.is_active ?? "0") === "1";

  const parentName = (s) =>
    [s?.parent_first_name, s?.parent_last_name].filter(Boolean).join(" ").trim() || "—";

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex flex-wrap justify-content-between align-items-center gap-3">
          <h5 className="mb-0">Manage Students</h5>
          <Link to="/admin/students/create">
            <button type="button" className="btn btn-primary-600 radius-3 px-20 py-11">
              <Icon icon="ic:baseline-plus" className="me-1" width={18} />
              Add Student
            </button>
          </Link>
        </div>

        {/* Filters */}
        <div className="card-body pb-0">
          <div className="row g-3 mb-3">
            <div className="col-md-3">
              <input
                type="text"
                className="form-control"
                placeholder="Search name, phone, email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div className="col-md-2">
              <select
                className="form-control"
                value={schoolAffiliation}
                onChange={(e) => {
                  setSchoolAffiliation(e.target.value);
                  if (e.target.value === "public") setSelectedSchoolId("");
                }}
              >
                <option value="all">All Students</option>
                <option value="school">School-Affiliated</option>
                <option value="public">Public (No School)</option>
              </select>
            </div>
            <div className="col-md-2">
              <select
                className="form-control"
                value={activeFilter}
                onChange={(e) => setActiveFilter(e.target.value)}
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
            {schoolAffiliation !== "public" && (
              <div className="col-md-3">
                <select
                  className="form-control"
                  value={selectedSchoolId}
                  onChange={(e) => setSelectedSchoolId(e.target.value)}
                >
                  <option value="">All Schools</option>
                  {schools.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.name}
                    </option>
                  ))}
                </select>
              </div>
            )}
            <div className="col-md-2 d-flex align-items-center text-muted">
              <small>{total} student{total !== 1 ? "s" : ""} found</small>
            </div>
          </div>
        </div>

        {message && <div className="alert alert-success mx-3">{message}</div>}
        {error && <div className="alert alert-danger mx-3">{error}</div>}

        <div className="card-body pt-0">
          <div className="table-responsive">
            <table className="table bordered-table mb-0">
              <thead>
                <tr>
                  <th style={{ width: 50 }}>#</th>
                  <th style={{ width: 70 }}>Avatar</th>
                  <th>Name</th>
                  <th>Phone</th>
                  <th>School</th>
                  <th>Parent</th>
                  <th style={{ width: 100 }}>Status</th>
                  <th style={{ width: 150 }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={8} className="text-center py-4">
                      <div className="spinner-border spinner-border-sm" role="status" />
                      <div className="mt-2 text-muted">Loading students…</div>
                    </td>
                  </tr>
                ) : students.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="text-center py-4 text-muted">
                      No students found
                    </td>
                  </tr>
                ) : (
                  students.map((s, idx) => {
                    const url = avatarUrl(s.avatar);
                    return (
                      <tr key={s.id}>
                        <td>{(page - 1) * perPage + idx + 1}</td>
                        <td>
                          {url ? (
                            <button
                              type="button"
                              className="p-0 border-0 bg-transparent"
                              onClick={() => setPreviewSrc(url)}
                              style={{ cursor: "zoom-in" }}
                            >
                              <img
                                src={url}
                                alt={fullName(s)}
                                style={{
                                  width: 40,
                                  height: 40,
                                  objectFit: "cover",
                                  borderRadius: "50%",
                                }}
                              />
                            </button>
                          ) : (
                            <div
                              className="d-inline-flex align-items-center justify-content-center bg-light text-muted"
                              style={{ width: 40, height: 40, borderRadius: "50%" }}
                            >
                              <Icon icon="mdi:account" width={22} />
                            </div>
                          )}
                        </td>
                        <td><Trunc value={fullName(s)} maxWidth={220} /></td>
                        <td><Trunc value={s.phone || "—"} maxWidth={160} /></td>
                        <td>
                          {s.school_id ? (
                            <span className="badge bg-primary-100 text-primary-600">
                              {s.school_key || `School #${s.school_id}`}
                            </span>
                          ) : (
                            <span className="badge bg-warning-100 text-warning-600">Public</span>
                          )}
                        </td>
                        <td><Trunc value={parentName(s)} maxWidth={180} /></td>
                        <td>
                          <div className="form-switch switch-primary">
                            <input
                              className="form-check-input"
                              type="checkbox"
                              role="switch"
                              checked={isActive(s)}
                              onChange={() => toggleStudent(s.id)}
                              title={isActive(s) ? "Deactivate Account" : "Activate Account"}
                              style={{ cursor: "pointer" }}
                            />
                          </div>
                        </td>
                        <td>
                          <div className="d-flex align-items-center gap-2">
                            <Link
                              to={`/admin/students/${s.id}`}
                              className="w-32-px h-32-px bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="View"
                            >
                              <Icon icon="iconamoon:eye-light" />
                            </Link>
                            <Link
                              to={`/admin/students/${s.id}/edit`}
                              className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="Edit"
                            >
                              <Icon icon="lucide:edit" />
                            </Link>
                            <button
                              type="button"
                              onClick={() => deleteStudent(s.id)}
                              className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                              title="Delete"
                            >
                              <Icon icon="mingcute:delete-2-line" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {lastPage > 1 && (
            <nav className="d-flex justify-content-between align-items-center mt-3">
              <small className="text-muted">
                Page {page} of {lastPage}
              </small>
              <ul className="pagination mb-0">
                <li className={`page-item ${page <= 1 ? "disabled" : ""}`}>
                  <button className="page-link" onClick={() => setPage((p) => Math.max(1, p - 1))}>
                    Previous
                  </button>
                </li>
                {Array.from({ length: Math.min(lastPage, 5) }, (_, i) => {
                  let num;
                  if (lastPage <= 5) {
                    num = i + 1;
                  } else if (page <= 3) {
                    num = i + 1;
                  } else if (page >= lastPage - 2) {
                    num = lastPage - 4 + i;
                  } else {
                    num = page - 2 + i;
                  }
                  return (
                    <li key={num} className={`page-item ${page === num ? "active" : ""}`}>
                      <button className="page-link" onClick={() => setPage(num)}>
                        {num}
                      </button>
                    </li>
                  );
                })}
                <li className={`page-item ${page >= lastPage ? "disabled" : ""}`}>
                  <button className="page-link" onClick={() => setPage((p) => Math.min(lastPage, p + 1))}>
                    Next
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      </div>

      {/* Image preview overlay */}
      {previewSrc && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100"
          style={{
            background: "rgba(0,0,0,0.75)",
            zIndex: 1055,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 16,
          }}
          onClick={() => setPreviewSrc(null)}
          role="dialog"
          aria-modal="true"
        >
          <img
            src={previewSrc}
            alt="Avatar Preview"
            style={{
              maxWidth: "95vw",
              maxHeight: "90vh",
              borderRadius: 12,
              cursor: "default",
            }}
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </MasterLayout>
  );
}
