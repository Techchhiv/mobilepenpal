import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation } from "react-router-dom";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import API_BASE_URL from "../../../../helper/Base_urls";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

const photoUrl = (photo) => {
  if (!photo) return null;
  if (String(photo).startsWith("http")) return photo;
  return `${API_BASE_URL}/${String(photo).replace(/^\/+/, "")}`;
};

const TeacherList = () => {
  const { hasPermission, isSchoolAdmin } = useAuth();
  const location = useLocation();

  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState(location.state?.flash || "");

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [previewSrc, setPreviewSrc] = useState(null);

  const canCreate = isSchoolAdmin || hasPermission("teachers.create");
  const canView = isSchoolAdmin || hasPermission("teachers.view");
  const canUpdate = isSchoolAdmin || hasPermission("teachers.update");
  const canDelete = isSchoolAdmin || hasPermission("teachers.delete");

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && setPreviewSrc(null);
    if (previewSrc) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [previewSrc]);

  const isOnline = (t) => {
    const flag = t?.is_online === true || String(t?.is_online) === "1";
    const last = t?.last_seen_at ? new Date(t.last_seen_at) : null;
    const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
    return flag || fresh;
  };

  const normalizeTeacher = (t) => ({
    ...t,
    active: t?.is_active === true || String(t?.is_active ?? t?.status ?? "0") === "1",
    online: isOnline(t),
  });

  const fetchTeachers = async () => {
    try {
      const res = await API.get("/school/teachers");
      const rows = Array.isArray(res.data) ? res.data : res.data?.data || [];
      setTeachers(rows.map(normalizeTeacher));
    } catch (err) {
      console.error("Fetch teachers failed:", err);
      setError(err?.response?.data?.message || "Failed to load teachers list.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTeachers();
  }, []);

  const deleteTeacher = async (id, name) => {
    if (!window.confirm(`Are you sure you want to delete teacher "${name}"?`)) return;

    setError("");
    setMessage("");
    try {
      await API.delete(`/school/teachers/${id}`);
      setMessage(`Teacher "${name}" deleted successfully.`);
      setTeachers((prev) => prev.filter((t) => t.id !== id));
    } catch (err) {
      console.error("Delete failed:", err);
      setError(err?.response?.data?.message || "Failed to delete teacher.");
    }
  };

  const filteredTeachers = useMemo(() => {
    let result = teachers;

    if (statusFilter === "active") {
      result = result.filter((t) => t.active);
    } else if (statusFilter === "inactive") {
      result = result.filter((t) => !t.active);
    }

    const q = search.trim().toLowerCase();
    if (q) {
      result = result.filter(
        (t) =>
          (t.name || "").toLowerCase().includes(q) ||
          (t.email || "").toLowerCase().includes(q) ||
          (t.phone || "").toLowerCase().includes(q) ||
          (t.subject || "").toLowerCase().includes(q) ||
          (t.teacher_id || "").toLowerCase().includes(q)
      );
    }

    return result;
  }, [teachers, search, statusFilter]);

  return (
    <SchoolLayout>
      <div className="d-flex flex-column gap-4">
        {/* Header Card */}
        <div className="card border-0 shadow-sm radius-12 p-3 bg-white">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
            <div className="d-flex align-items-center gap-3">
              <div className="w-44-px h-44-px bg-purple-50 text-purple rounded-circle d-flex align-items-center justify-content-center">
                <Icon icon="mdi:teach" className="text-xl" />
              </div>
              <div>
                <h5 className="mb-0 fw-bold text-dark">Teacher Directory</h5>
                <small className="text-muted">Manage teaching staff and course instructors</small>
              </div>
            </div>

            {canCreate && (
              <Link to="/school/teachers/create" className="btn btn-primary d-flex align-items-center gap-1 radius-8 shadow-sm">
                <Icon icon="mdi:plus" /> Add New Teacher
              </Link>
            )}
          </div>
        </div>

        {message && (
          <div className="alert alert-success alert-dismissible fade show radius-12 mb-0" role="alert">
            <Icon icon="mdi:check-circle-outline" className="me-2 text-lg" />
            {message}
            <button type="button" className="btn-close" onClick={() => setMessage("")} />
          </div>
        )}

        {error && (
          <div className="alert alert-danger alert-dismissible fade show radius-12 mb-0" role="alert">
            <Icon icon="mdi:alert-circle-outline" className="me-2 text-lg" />
            {error}
            <button type="button" className="btn-close" onClick={() => setError("")} />
          </div>
        )}

        {/* Table Card */}
        <div className="card border-0 shadow-sm radius-12 bg-white">
          {/* Controls Header */}
          <div className="card-header bg-white border-bottom py-3">
            <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
              {/* Search */}
              <div className="position-relative" style={{ minWidth: "260px" }}>
                <Icon icon="mdi:magnify" className="position-absolute top-50 start-0 translate-middle-y ms-3 text-muted text-lg" />
                <input
                  type="text"
                  className="form-control form-control-sm ps-5 radius-8"
                  placeholder="Search teacher by name, email, subject..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>

              {/* Status Filter & Count Badge */}
              <div className="d-flex align-items-center gap-3">
                <div className="d-flex align-items-center gap-2">
                  <span className="text-muted text-xs">Status:</span>
                  <select
                    className="form-select form-select-sm radius-8"
                    style={{ width: "130px" }}
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                  >
                    <option value="all">All Teachers</option>
                    <option value="active">Active Only</option>
                    <option value="inactive">Inactive Only</option>
                  </select>
                </div>

                <span className="badge bg-light text-dark border text-xs">
                  {filteredTeachers.length} {filteredTeachers.length === 1 ? "Teacher" : "Teachers"}
                </span>
              </div>
            </div>
          </div>

          {/* Table Body */}
          <div className="card-body p-0">
            {loading ? (
              <div className="d-flex justify-content-center align-items-center py-5" style={{ minHeight: "240px" }}>
                <div className="spinner-border text-primary" role="status">
                  <span className="visually-hidden">Loading teachers...</span>
                </div>
              </div>
            ) : filteredTeachers.length === 0 ? (
              <div className="d-flex flex-column align-items-center justify-content-center py-5 text-muted small text-center">
                <Icon icon="mdi:account-off-outline" className="text-3xl text-muted mb-2" />
                <span className="fw-medium text-dark">No teachers found</span>
                <span className="text-xs text-muted mt-1">Try adjusting your search query or status filter</span>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="table align-middle mb-0">
                  <thead className="table-light text-xs text-uppercase text-muted">
                    <tr>
                      <th className="ps-3" style={{ width: "50px" }}>#</th>
                      <th>Teacher Name & Email</th>
                      <th>Teacher ID</th>
                      <th>Subject / Department</th>
                      <th>Phone Number</th>
                      <th>Status</th>
                      <th className="pe-3 text-end">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="text-sm">
                    {filteredTeachers.map((t, idx) => {
                      const pUrl = photoUrl(t.photo);
                      return (
                        <tr key={t.id}>
                          <td className="ps-3 text-muted text-xs">{idx + 1}</td>
                          <td>
                            <div className="d-flex align-items-center gap-3">
                              <div
                                className="position-relative w-40-px h-40-px rounded-circle overflow-hidden bg-light border flex-shrink-0 cursor-pointer"
                                onClick={() => pUrl && setPreviewSrc(pUrl)}
                                title={pUrl ? "Click to view photo" : "No photo"}
                              >
                                {pUrl ? (
                                  <img src={pUrl} alt={t.name} className="w-100 h-100 object-fit-cover" />
                                ) : (
                                  <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                    <Icon icon="mdi:account" className="text-xl" />
                                  </div>
                                )}
                                {/* Online status indicator dot */}
                                <span
                                  className={`position-absolute bottom-0 end-0 p-1 rounded-circle border border-white ${t.online ? "bg-success" : "bg-secondary"}`}
                                  style={{ width: "10px", height: "10px" }}
                                  title={t.online ? "Online now" : "Offline"}
                                />
                              </div>
                              <div>
                                <div className="fw-semibold text-dark">{t.name}</div>
                                <div className="text-muted text-xs">{t.email || "—"}</div>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="badge bg-light text-dark font-mono text-xs border">
                              {t.teacher_id || `#${t.id}`}
                            </span>
                          </td>
                          <td>
                            {t.subject ? (
                              <span className="badge bg-purple-subtle text-purple border border-purple-subtle">
                                {t.subject}
                              </span>
                            ) : (
                              <span className="text-muted">—</span>
                            )}
                          </td>
                          <td>{t.phone || <span className="text-muted">—</span>}</td>
                          <td>
                            <span className={`badge ${t.active ? "bg-success-subtle text-success" : "bg-secondary-subtle text-secondary"}`}>
                              {t.active ? "Active" : "Inactive"}
                            </span>
                          </td>
                          <td className="pe-3 text-end">
                            <div className="d-inline-flex gap-1">
                              {canView && (
                                <Link
                                  to={`/school/teachers/${t.id}`}
                                  className="btn btn-sm btn-outline-primary p-1 text-xs"
                                  title="View Teacher Profile"
                                >
                                  <Icon icon="mdi:eye" className="text-base" />
                                </Link>
                              )}
                              {canUpdate && (
                                <Link
                                  to={`/school/teachers/${t.id}/edit`}
                                  className="btn btn-sm btn-outline-info p-1 text-xs"
                                  title="Edit Teacher"
                                >
                                  <Icon icon="mdi:pencil" className="text-base" />
                                </Link>
                              )}
                              {canDelete && (
                                <button
                                  type="button"
                                  className="btn btn-sm btn-outline-danger p-1 text-xs"
                                  title="Delete Teacher"
                                  onClick={() => deleteTeacher(t.id, t.name)}
                                >
                                  <Icon icon="mdi:trash-can-outline" className="text-base" />
                                </button>
                              )}
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
        </div>

        {/* Lightbox Photo Preview Modal */}
        {previewSrc && (
          <div
            className="modal fade show d-block bg-dark bg-opacity-75"
            tabIndex="-1"
            onClick={() => setPreviewSrc(null)}
          >
            <div className="modal-dialog modal-dialog-centered" onClick={(e) => e.stopPropagation()}>
              <div className="modal-content border-0 radius-12 overflow-hidden bg-transparent text-center">
                <div className="p-2 position-relative">
                  <button
                    type="button"
                    className="btn-close btn-close-white position-absolute top-0 end-0 m-3 z-1"
                    onClick={() => setPreviewSrc(null)}
                  />
                  <img src={previewSrc} alt="Preview" className="img-fluid radius-12 shadow-lg" style={{ maxHeight: "80vh" }} />
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </SchoolLayout>
  );
};

export default TeacherList;
