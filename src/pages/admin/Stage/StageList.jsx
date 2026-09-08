import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import { Link, useSearchParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminErrorState from "../../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../../components/admin/common/ConfirmModal";
import AdminPagination from "../../../components/admin/common/AdminPagination";

const Trunc = ({ value, maxWidth = 240 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate text-secondary-light" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const normalizeStage = (s) => ({
  ...s,
  is_active: s?.is_active === true || String(s?.is_active ?? "0") === "1",
  world_name: s?.level?.world?.name ?? "—",
  world_id: s?.level?.world?.id ?? null,
  level_name: s?.level?.name ?? "—",
  level_id: s?.level?.id ?? s?.level_id ?? null,
  exercises_count: s?.exercises_count ?? "—",
  active_exercises_count: s?.active_exercises_count ?? "—",
});

const StageList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [stages, setStages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [searchParams] = useSearchParams();
  const worldId = searchParams.get("world_id");
  const levelId = searchParams.get("level_id");

  // Search & Pagination
  const [searchVal, setSearchVal] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Toggle Confirm Modal
  const [toggleTarget, setToggleTarget] = useState(null);
  const [toggling, setToggling] = useState(false);

  const canAnyAction = hasAnyPermission([
    "stages.view",
    "stages.update",
    "stages.enable_disable",
  ]);

  const fetchStages = async () => {
    setLoading(true);
    setError("");
    try {
      const qs = new URLSearchParams();
      qs.set("include_inactive", "1");
      if (worldId) qs.set("world_id", worldId);
      if (levelId) qs.set("level_id", levelId);

      const res = await API.get(`/admin/stages?${qs.toString()}`);
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.stages) ? payload.stages : [];
      setStages(rows.map(normalizeStage));
    } catch (err) {
      console.error("Fetch stages failed:", err);
      setError(err?.response?.data?.message || "Failed to load stages list.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStages();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [worldId, levelId]);

  const filteredStages = useMemo(() => {
    return stages.filter((s) => {
      const matchesSearch =
        searchVal.trim() === "" ||
        (s.name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (s.level_name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (s.world_name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (s.description || "").toLowerCase().includes(searchVal.toLowerCase());

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && s.is_active) ||
        (statusFilter === "inactive" && !s.is_active);

      return matchesSearch && matchesStatus;
    });
  }, [stages, searchVal, statusFilter]);

  const totalPages = Math.ceil(filteredStages.length / pageSize) || 1;
  const paginatedStages = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredStages.slice(start, start + pageSize);
  }, [filteredStages, currentPage, pageSize]);

  const handleToggleConfirm = async () => {
    if (!toggleTarget) return;
    setToggling(true);
    try {
      await API.put(`/admin/stages/${toggleTarget.id}/toggle`);
      setStages((prev) =>
        prev.map((s) =>
          s.id === toggleTarget.id ? { ...s, is_active: !s.is_active } : s
        )
      );
      setToggleTarget(null);
    } catch (err) {
      console.error("Toggle stage failed:", err);
    } finally {
      setToggling(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Stage Management"
          subtitle="Manage stage exercises, max stars, and learning progress items"
          primaryAction={
            hasPermission("stages.create")
              ? {
                  label: "Create Stage",
                  to: "/admin/stages/create",
                  icon: "mdi:plus",
                }
              : null
          }
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
                  placeholder="Search stage, level, world, or description..."
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

              {(searchVal || statusFilter !== "all") && (
                <button
                  type="button"
                  className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                  onClick={() => {
                    setSearchVal("");
                    setStatusFilter("all");
                    setCurrentPage(1);
                  }}
                >
                  <Icon icon="mdi:filter-off-outline" />
                  <span>Clear Filters</span>
                </button>
              )}
            </div>

            <div className="text-secondary-light text-sm">
              Total: <strong>{filteredStages.length}</strong> stages
            </div>
          </div>
        </div>

        {error ? (
          <AdminErrorState message={error} onRetry={fetchStages} />
        ) : (
          <div className="card border radius-12 shadow-none">
            <div className="card-body p-0">
              <div className="table-responsive">
                <table className="table bordered-table mb-0 align-middle">
                  <thead>
                    <tr>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">#</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Order</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">World</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Level</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Name</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Description</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Content</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Max Stars</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Status</th>
                      {canAnyAction && (
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Action</th>
                      )}
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
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          {canAnyAction && <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>}
                        </tr>
                      ))
                    ) : paginatedStages.length === 0 ? (
                      <tr>
                        <td colSpan={canAnyAction ? 10 : 9} className="text-center text-secondary-light py-40">
                          <Icon icon="mdi:flag-off-outline" width="48" className="mb-12 opacity-50" />
                          <h6>No stages found</h6>
                          <p className="text-xs text-secondary-light mb-0">Try adjusting your search query or filter options.</p>
                        </td>
                      </tr>
                    ) : (
                      paginatedStages.map((s, idx) => {
                        const rowNum = (currentPage - 1) * pageSize + idx + 1;
                        return (
                          <tr key={s.id} className={`hover-bg-neutral-50 transition-1 ${!s.is_active ? "opacity-75" : ""}`}>
                            <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{rowNum}</td>
                            <td className="py-12 px-16 text-sm text-secondary-light">{s.order_index ?? "—"}</td>
                            <td className="py-12 px-16 text-sm text-secondary-light">
                              <Trunc value={s.world_name} maxWidth={180} />
                            </td>
                            <td className="py-12 px-16 text-sm fw-bold text-dark">
                              <Trunc value={s.level_name} maxWidth={200} />
                            </td>
                            <td className="py-12 px-16 text-sm fw-semibold text-dark">
                              <Trunc value={s.name} maxWidth={220} />
                            </td>
                            <td className="py-12 px-16 text-sm text-secondary-light">
                              <Trunc value={s.description || "—"} maxWidth={260} />
                            </td>

                            <td className="py-12 px-16 text-center text-xs text-secondary-light">
                              Exercises: <strong className="text-dark">{s.active_exercises_count}/{s.exercises_count}</strong>
                            </td>

                            <td className="py-12 px-16 text-center text-sm fw-semibold text-dark me-4">
                              <Icon icon="mdi:star" className="text-warning-main me-4" />
                              {s.max_stars ?? "—"}
                            </td>

                            <td className="py-12 px-16 text-center align-middle">
                              <span
                                className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                  s.is_active ? "status-badge-active" : "status-badge-inactive"
                                }`}
                              >
                                <Icon icon={s.is_active ? "mdi:check-circle" : "mdi:close-circle"} />
                                <span>{s.is_active ? "Active" : "Disabled"}</span>
                              </span>
                            </td>

                            {canAnyAction && (
                              <td className="py-12 px-16 text-center align-middle">
                                <div className="d-inline-flex align-items-center gap-6">
                                  {hasPermission("stages.view") && (
                                    <Link
                                      to={`/admin/stages/${s.id}`}
                                      className="w-32-px h-32-px radius-8 bg-primary-50 text-primary-600 d-inline-flex align-items-center justify-content-center"
                                      title="View Stage"
                                    >
                                      <Icon icon="iconamoon:eye-light" />
                                    </Link>
                                  )}

                                  {hasPermission("stages.update") && (
                                    <Link
                                      to={`/admin/stages/${s.id}/edit`}
                                      className="w-32-px h-32-px radius-8 bg-success-50 text-success-600 d-inline-flex align-items-center justify-content-center"
                                      title="Edit Stage"
                                    >
                                      <Icon icon="lucide:edit" />
                                    </Link>
                                  )}

                                  {hasPermission("stages.enable_disable") && (
                                    <button
                                      type="button"
                                      onClick={() => setToggleTarget(s)}
                                      className={`w-32-px h-32-px radius-8 border-0 d-inline-flex align-items-center justify-content-center ${
                                        s.is_active ? "bg-warning-50 text-warning-600" : "bg-info-50 text-info-600"
                                      }`}
                                      title={s.is_active ? "Disable Stage" : "Enable Stage"}
                                    >
                                      <Icon icon={s.is_active ? "mdi:toggle-switch-off-outline" : "mdi:toggle-switch-outline"} />
                                    </button>
                                  )}
                                </div>
                              </td>
                            )}
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>

              {!loading && filteredStages.length > 0 && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {(currentPage - 1) * pageSize + 1}–
                    {Math.min(currentPage * pageSize, filteredStages.length)} of {filteredStages.length} entries
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
        title={toggleTarget?.is_active ? "Disable Stage?" : "Enable Stage?"}
        message={`Are you sure you want to ${toggleTarget?.is_active ? "disable" : "enable"} the stage "${toggleTarget?.name}"?`}
        confirmLabel={toggleTarget?.is_active ? "Disable Stage" : "Enable Stage"}
        cancelLabel="Cancel"
        variant={toggleTarget?.is_active ? "warning" : "primary"}
        loading={toggling}
        onConfirm={handleToggleConfirm}
        onCancel={() => setToggleTarget(null)}
      />
    </MasterLayout>
  );
};

export default StageList;
