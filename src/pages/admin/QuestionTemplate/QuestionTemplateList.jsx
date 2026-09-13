import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import { toast } from "react-toastify";

import API from "../../../helper/api";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminErrorState from "../../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../../components/admin/common/ConfirmModal";
import AdminPagination from "../../../components/admin/common/AdminPagination";

const Trunc = ({ value, maxWidth = 300 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate text-secondary-light" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const QuestionTemplateList = () => {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Filters & Pagination
  const [searchVal, setSearchVal] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [difficultyFilter, setDifficultyFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Confirm Modal state
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [toggleTarget, setToggleTarget] = useState(null);
  const [toggling, setToggling] = useState(false);

  const fetchTemplates = async () => {
    try {
      setLoading(true);
      setError("");
      const res = await API.get("/admin/question-templates?per_page=100");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.question_templates?.data)
        ? payload.question_templates.data
        : Array.isArray(payload?.question_templates)
        ? payload.question_templates
        : [];
      setTemplates(rows);
    } catch (err) {
      console.error("Fetch templates failed:", err);
      setError(err?.response?.data?.message || "Failed to load question templates.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTemplates();
  }, []);

  const filteredTemplates = useMemo(() => {
    return templates.filter((t) => {
      const matchesSearch =
        searchVal.trim() === "" ||
        (t.question_en || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (t.question_kh || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (t.operation || "").toLowerCase().includes(searchVal.toLowerCase());

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && t.is_active) ||
        (statusFilter === "inactive" && !t.is_active);

      const matchesDifficulty =
        difficultyFilter === "all" || t.difficulty === difficultyFilter;

      return matchesSearch && matchesStatus && matchesDifficulty;
    });
  }, [templates, searchVal, statusFilter, difficultyFilter]);

  const totalPages = Math.ceil(filteredTemplates.length / pageSize) || 1;
  const paginatedTemplates = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredTemplates.slice(start, start + pageSize);
  }, [filteredTemplates, currentPage, pageSize]);

  const handleToggleConfirm = async () => {
    if (!toggleTarget) return;
    setToggling(true);
    try {
      const nextStatus = !toggleTarget.is_active;
      await API.put(`/admin/question-templates/${toggleTarget.id}`, {
        is_active: nextStatus,
      });
      setTemplates((prev) =>
        prev.map((item) =>
          item.id === toggleTarget.id ? { ...item, is_active: nextStatus } : item
        )
      );
      toast.success(`Template ${nextStatus ? "activated" : "disabled"} successfully`);
      setToggleTarget(null);
    } catch (err) {
      console.error(err);
      toast.error("Failed to update template status");
    } finally {
      setToggling(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await API.delete(`/admin/question-templates/${deleteTarget.id}`);
      setTemplates((prev) => prev.filter((item) => item.id !== deleteTarget.id));
      toast.success("Template deleted successfully");
      setDeleteTarget(null);
    } catch (err) {
      console.error(err);
      toast.error("Failed to delete template");
    } finally {
      setDeleting(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Question Templates"
          subtitle="Manage reusable math and language question templates"
          primaryAction={{
            label: "Create Template",
            to: "/admin/question-templates/create",
            icon: "mdi:plus",
          }}
        />

        {/* Filter and Search Bar */}
        <div className="card border radius-12 shadow-none mb-20">
          <div className="card-body p-16 d-flex flex-wrap align-items-center justify-content-between gap-16">
            <div className="d-flex flex-wrap align-items-center gap-12 flex-grow-1">
              <div className="input-group" style={{ maxWidth: "320px" }}>
                <span className="input-group-text bg-base text-secondary-light border-end-0 radius-8-left">
                  <Icon icon="mdi:magnify" width="18" />
                </span>
                <input
                  type="text"
                  className="form-control border-start-0 ps-0 radius-8-right"
                  placeholder="Search questions (EN/KH) or operation..."
                  value={searchVal}
                  onChange={(e) => {
                    setSearchVal(e.target.value);
                    setCurrentPage(1);
                  }}
                />
              </div>

              <select
                className="form-select w-auto radius-8"
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  setCurrentPage(1);
                }}
              >
                <option value="all">All Status</option>
                <option value="active">Active Only</option>
                <option value="inactive">Disabled Only</option>
              </select>

              <select
                className="form-select w-auto radius-8"
                value={difficultyFilter}
                onChange={(e) => {
                  setDifficultyFilter(e.target.value);
                  setCurrentPage(1);
                }}
              >
                <option value="all">All Difficulty</option>
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
              </select>

              {(searchVal || statusFilter !== "all" || difficultyFilter !== "all") && (
                <button
                  type="button"
                  className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                  onClick={() => {
                    setSearchVal("");
                    setStatusFilter("all");
                    setDifficultyFilter("all");
                    setCurrentPage(1);
                  }}
                >
                  <Icon icon="mdi:filter-off-outline" />
                  <span>Clear Filters</span>
                </button>
              )}
            </div>

            <div className="text-secondary-light text-sm">
              Total: <strong>{filteredTemplates.length}</strong> templates
            </div>
          </div>
        </div>

        {error ? (
          <AdminErrorState message={error} onRetry={fetchTemplates} />
        ) : (
          <div className="card border radius-12 shadow-none">
            <div className="card-body p-0">
              <div className="table-responsive">
                <table className="table bordered-table mb-0 align-middle">
                  <thead>
                    <tr>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">#</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Question (EN)</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Question (KH)</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Operation</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Difficulty</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Status</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Action</th>
                    </tr>
                  </thead>

                  <tbody>
                    {loading ? (
                      Array.from({ length: 5 }).map((_, idx) => (
                        <tr key={idx}>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                        </tr>
                      ))
                    ) : paginatedTemplates.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="text-center text-secondary-light py-40">
                          <Icon icon="mdi:help-box-outline" width="48" className="mb-12 opacity-50" />
                          <h6>No question templates found</h6>
                          <p className="text-xs text-secondary-light mb-0">Try adjusting your search query or filter options.</p>
                        </td>
                      </tr>
                    ) : (
                      paginatedTemplates.map((t, idx) => {
                        const rowNum = (currentPage - 1) * pageSize + idx + 1;
                        return (
                          <tr key={t.id} className={`hover-bg-neutral-50 transition-1 ${!t.is_active ? "opacity-75" : ""}`}>
                            <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{rowNum}</td>
                            <td className="py-12 px-16 text-sm fw-semibold text-dark">
                              <Trunc value={t.question_en} />
                            </td>
                            <td className="py-12 px-16 text-sm text-dark">
                              <Trunc value={t.question_kh} />
                            </td>
                            <td className="py-12 px-16 text-center text-capitalize">
                              <span className="badge bg-neutral-100 text-secondary-light border radius-4 text-xs">
                                {t.operation}
                              </span>
                            </td>
                            <td className="py-12 px-16 text-center text-capitalize">
                              <span
                                className={`badge radius-4 text-xs ${
                                  t.difficulty === "easy"
                                    ? "bg-success-subtle text-success border border-success-subtle"
                                    : t.difficulty === "medium"
                                    ? "bg-warning-subtle text-warning border border-warning-subtle"
                                    : "bg-danger-subtle text-danger border border-danger-subtle"
                                }`}
                              >
                                {t.difficulty}
                              </span>
                            </td>
                            <td className="py-12 px-16 text-center align-middle">
                              <span
                                className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                  t.is_active ? "status-badge-active" : "status-badge-inactive"
                                }`}
                              >
                                <Icon icon={t.is_active ? "mdi:check-circle" : "mdi:close-circle"} />
                                <span>{t.is_active ? "Active" : "Disabled"}</span>
                              </span>
                            </td>
                            <td className="py-12 px-16 text-center align-middle">
                              <div className="d-inline-flex align-items-center gap-6">
                                <Link
                                  to={`/admin/question-templates/${t.id}/edit`}
                                  className="w-32-px h-32-px radius-8 bg-success-50 text-success-600 d-inline-flex align-items-center justify-content-center"
                                  title="Edit Template"
                                >
                                  <Icon icon="lucide:edit" />
                                </Link>

                                <button
                                  type="button"
                                  onClick={() => setToggleTarget(t)}
                                  className={`w-32-px h-32-px radius-8 border-0 d-inline-flex align-items-center justify-content-center ${
                                    t.is_active ? "bg-warning-50 text-warning-600" : "bg-info-50 text-info-600"
                                  }`}
                                  title={t.is_active ? "Disable Template" : "Enable Template"}
                                >
                                  <Icon icon={t.is_active ? "mdi:toggle-switch-off-outline" : "mdi:toggle-switch-outline"} />
                                </button>

                                <button
                                  type="button"
                                  onClick={() => setDeleteTarget(t)}
                                  className="w-32-px h-32-px radius-8 bg-danger-50 text-danger-600 d-inline-flex align-items-center justify-content-center border-0"
                                  title="Delete Template"
                                >
                                  <Icon icon="lucide:trash" />
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

              {!loading && filteredTemplates.length > 0 && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {(currentPage - 1) * pageSize + 1}–
                    {Math.min(currentPage * pageSize, filteredTemplates.length)} of {filteredTemplates.length} entries
                  </div>
                  {totalPages > 1 && (
                    <div className="ms-auto">
                      <AdminPagination
                        page={currentPage}
                        totalPages={totalPages}
                        onPageChange={setCurrentPage}
                      />
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      <ConfirmModal
        open={Boolean(toggleTarget)}
        title={toggleTarget?.is_active ? "Disable Question Template?" : "Enable Question Template?"}
        message={`Are you sure you want to ${toggleTarget?.is_active ? "disable" : "enable"} this template?`}
        confirmLabel={toggleTarget?.is_active ? "Disable Template" : "Enable Template"}
        cancelLabel="Cancel"
        variant={toggleTarget?.is_active ? "warning" : "primary"}
        loading={toggling}
        onConfirm={handleToggleConfirm}
        onCancel={() => setToggleTarget(null)}
      />

      <ConfirmModal
        open={Boolean(deleteTarget)}
        title="Delete Question Template?"
        message={`Are you sure you want to permanently delete this template? This action cannot be undone.`}
        confirmLabel="Delete Template"
        cancelLabel="Cancel"
        variant="danger"
        loading={deleting}
        onConfirm={handleDeleteConfirm}
        onCancel={() => setDeleteTarget(null)}
      />
    </MasterLayout>
  );
};

export default QuestionTemplateList;
