import React, { useEffect, useState, useCallback } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";
import API_BASE_URL from "../../../helper/Base_urls";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../../components/admin/common/AdminEmptyState";
import AdminPagination from "../../../components/admin/common/AdminPagination";
import ConfirmModal from "../../../components/admin/common/ConfirmModal";

const Trunc = ({ value, maxWidth = 200 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

export default function AdminStudentList() {
  const navigate = useNavigate();
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

  const [deleteModal, setDeleteModal] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const handleDeleteClick = (student) => {
    setDeleteModal(student);
  };

  const confirmDeleteStudent = async () => {
    if (!deleteModal) return;
    try {
      setDeleteLoading(true);
      await API.delete(`/admin/students/${deleteModal.id}`);
      setStudents((prev) => prev.filter((s) => s.id !== deleteModal.id));
      flash("Student deleted successfully");
      setDeleteModal(null);
    } catch (err) {
      flash(err?.response?.data?.message || "Delete failed", true);
    } finally {
      setDeleteLoading(false);
    }
  };

  const isActive = (s) =>
    s?.is_active === true || String(s?.is_active ?? "0") === "1";

  const parentName = (s) =>
    [s?.parent_first_name, s?.parent_last_name].filter(Boolean).join(" ").trim() || "—";

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Manage Students"
          subtitle="Manage student profiles, school affiliations, parent contacts, and account statuses"
          actionLabel="Add Student"
          actionIcon="lucide:plus"
          onAction={() => navigate("/admin/students/create")}
        />

        {message && <div className="alert alert-success py-12 px-16 radius-8 text-sm mb-16">{message}</div>}

        {/* Standalone Filter Card */}
        <div className="card border radius-12 shadow-none mb-20">
          <div className="card-body p-20">
            <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
              <div className="d-flex flex-wrap align-items-center gap-3 flex-grow-1">
                {/* Search input with magnify icon */}
                <div className="position-relative flex-grow-1" style={{ maxWidth: 320, minWidth: 200 }}>
                  <input
                    type="text"
                    className="form-control h-40-px ps-40 radius-8 text-sm"
                    placeholder="Search name, phone, email..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                  />
                  <Icon
                    icon="ion:search-outline"
                    className="position-absolute top-50 translate-middle-y text-secondary-light"
                    style={{ left: 14, fontSize: 20, pointerEvents: "none" }}
                  />
                </div>

                {/* School Affiliation Filter */}
                <select
                  className="form-select h-40-px radius-8 text-sm w-auto"
                  value={schoolAffiliation}
                  onChange={(e) => {
                    setSchoolAffiliation(e.target.value);
                    if (e.target.value === "public") setSelectedSchoolId("");
                  }}
                >
                  <option value="all">All Affiliations</option>
                  <option value="school">School-Affiliated</option>
                  <option value="public">Public (No School)</option>
                </select>

                {/* Active Status Filter */}
                <select
                  className="form-select h-40-px radius-8 text-sm w-auto"
                  value={activeFilter}
                  onChange={(e) => setActiveFilter(e.target.value)}
                >
                  <option value="all">All Status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>

                {/* Specific School Filter */}
                {schoolAffiliation !== "public" && (
                  <select
                    className="form-select h-40-px radius-8 text-sm w-auto"
                    style={{ maxWidth: 220 }}
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
                )}

                {/* Clear filters button */}
                {(search || schoolAffiliation !== "all" || activeFilter !== "all" || selectedSchoolId) && (
                  <button
                    type="button"
                    className="btn btn-neutral-100 text-secondary-light h-40-px px-16 radius-8 text-sm d-inline-flex align-items-center gap-2"
                    onClick={() => {
                      setSearch("");
                      setSchoolAffiliation("all");
                      setActiveFilter("all");
                      setSelectedSchoolId("");
                    }}
                  >
                    <Icon icon="lucide:x" />
                    Reset Filters
                  </button>
                )}
              </div>

              <div className="text-secondary-light text-sm font-medium">
                Total: <span className="text-primary-600 fw-bold">{total}</span> Students
              </div>
            </div>
          </div>
        </div>

        {/* Table Card */}
        <div className="card border radius-12 shadow-none overflow-hidden">
          <div className="card-body p-0">
            <div className="table-responsive">
              <table className="table bordered-table mb-0 align-middle">
                <thead>
                  <tr>
                    <th style={{ width: 50 }} className="px-16">#</th>
                    <th style={{ width: 70 }} className="px-16">Avatar</th>
                    <th className="px-16">Name</th>
                    <th className="px-16">Phone</th>
                    <th className="px-16">School</th>
                    <th className="px-16">Parent</th>
                    <th style={{ width: 100 }} className="px-16">Status</th>
                    <th style={{ width: 150 }} className="pe-16 text-end">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr>
                      <td colSpan={8} className="text-center py-4 text-secondary-light">
                        <div className="spinner-border spinner-border-sm text-primary me-2" role="status" />
                        Loading students…
                      </td>
                    </tr>
                  ) : students.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="text-center py-4 text-secondary-light">
                        <AdminEmptyState
                          title="No Students Found"
                          message="No student accounts match your filter criteria."
                        />
                      </td>
                    </tr>
                  ) : (
                    students.map((s, idx) => {
                      const url = avatarUrl(s.avatar);
                      return (
                        <tr key={s.id}>
                          <td className="px-16 font-monospace text-secondary-light">{(page - 1) * perPage + idx + 1}</td>
                          <td className="px-16">
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
                                className="d-inline-flex align-items-center justify-content-center bg-neutral-100 text-secondary-light border border-neutral-200"
                                style={{ width: 40, height: 40, borderRadius: "50%" }}
                              >
                                <Icon icon="mdi:account" width={22} />
                              </div>
                            )}
                          </td>
                          <td className="px-16"><Trunc value={fullName(s)} maxWidth={220} /></td>
                          <td className="px-16"><Trunc value={s.phone || "—"} maxWidth={160} /></td>
                          <td className="px-16">
                            {s.school_id ? (
                              <span className="badge bg-primary-100 text-primary-600">
                                {s.school_key || `School #${s.school_id}`}
                              </span>
                            ) : (
                              <span className="badge bg-warning-100 text-warning-600">Public</span>
                            )}
                          </td>
                          <td className="px-16"><Trunc value={parentName(s)} maxWidth={180} /></td>
                          <td className="px-16">
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
                          <td className="pe-16 text-end">
                            <div className="d-inline-flex align-items-center justify-end gap-2">
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
                                onClick={() => handleDeleteClick(s)}
                                className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                title="Delete Student"
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
          </div>

          {/* ── Card Footer Pagination Standard ── */}
          <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
            <div className="text-secondary-light text-xs font-semibold">
              Showing {total > 0 ? (page - 1) * perPage + 1 : 0}–
              {Math.min(page * perPage, total)} of {total} entries
            </div>
            {lastPage > 1 && (
              <div className="ms-auto">
                <AdminPagination
                  page={page}
                  totalPages={lastPage}
                  onPageChange={(p) => setPage(p)}
                />
              </div>
            )}
          </div>
        </div>

        <ConfirmModal
          open={!!deleteModal}
          title="Delete Student Account"
          message={deleteModal ? `Are you sure you want to delete student "${fullName(deleteModal)}"? This action cannot be undone.` : ""}
          confirmLabel="Delete Student"
          variant="danger"
          loading={deleteLoading}
          onConfirm={confirmDeleteStudent}
          onCancel={() => setDeleteModal(null)}
        />

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
      </div>
    </MasterLayout>
  );
}
