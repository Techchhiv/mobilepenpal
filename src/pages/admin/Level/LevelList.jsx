import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";

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

const normalizeLevel = (lv) => ({
  ...lv,
  is_active: lv?.is_active === true || String(lv?.is_active ?? "0") === "1",
  is_unlocked_by_default:
    lv?.is_unlocked_by_default === true ||
    String(lv?.is_unlocked_by_default ?? "0") === "1",
  stages_count: lv?.stages_count ?? "—",
  active_stages_count: lv?.active_stages_count ?? "—",
  world_name: lv?.world?.name ?? "—",
});

const LevelList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [levels, setLevels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Search & Pagination
  const [searchVal, setSearchVal] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Toggle Confirm Modal
  const [toggleTarget, setToggleTarget] = useState(null);
  const [toggling, setToggling] = useState(false);

  const canAnyAction = hasAnyPermission([
    "levels.view",
    "levels.update",
    "levels.enable_disable",
  ]);

  const fetchLevels = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await API.get("/admin/levels?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.levels) ? payload.levels : [];
      setLevels(rows.map(normalizeLevel));
    } catch (err) {
      console.error("Fetch levels failed:", err);
      setError(err?.response?.data?.message || "Failed to load levels list.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLevels();
  }, []);

  const filteredLevels = useMemo(() => {
    return levels.filter((lv) => {
      const matchesSearch =
        searchVal.trim() === "" ||
        (lv.name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (lv.world_name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (lv.description || "").toLowerCase().includes(searchVal.toLowerCase());

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && lv.is_active) ||
        (statusFilter === "inactive" && !lv.is_active);

      return matchesSearch && matchesStatus;
    });
  }, [levels, searchVal, statusFilter]);

  const totalPages = Math.ceil(filteredLevels.length / pageSize) || 1;
  const paginatedLevels = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredLevels.slice(start, start + pageSize);
  }, [filteredLevels, currentPage, pageSize]);

  const handleToggleConfirm = async () => {
    if (!toggleTarget) return;
    setToggling(true);
    try {
      await API.put(`/admin/levels/${toggleTarget.id}/toggle`);
      setLevels((prev) =>
        prev.map((l) =>
          l.id === toggleTarget.id ? { ...l, is_active: !l.is_active } : l
        )
      );
      setToggleTarget(null);
    } catch (err) {
      console.error("Toggle level failed:", err);
    } finally {
      setToggling(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Level Management"
          subtitle="Manage game level progression and stage contents"
          primaryAction={
            hasPermission("levels.create")
              ? {
                  label: "Create Level",
                  to: "/admin/levels/create",
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
                  placeholder="Search level, world name, or description..."
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
              Total: <strong>{filteredLevels.length}</strong> levels
            </div>
          </div>
        </div>

        {error ? (
          <AdminErrorState message={error} onRetry={fetchLevels} />
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
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Name</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Description</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Content</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Default Unlock</th>
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
                          {canAnyAction && <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>}
                        </tr>
                      ))
                    ) : paginatedLevels.length === 0 ? (
                      <tr>
                        <td colSpan={canAnyAction ? 9 : 8} className="text-center text-secondary-light py-40">
                          <Icon icon="mdi:layers-off" width="48" className="mb-12 opacity-50" />
                          <h6>No levels found</h6>
                          <p className="text-xs text-secondary-light mb-0">Try adjusting your search query or filter options.</p>
                        </td>
                      </tr>
                    ) : (
                      paginatedLevels.map((lv, idx) => {
                        const rowNum = (currentPage - 1) * pageSize + idx + 1;
                        return (
                          <tr key={lv.id} className={`hover-bg-neutral-50 transition-1 ${!lv.is_active ? "opacity-75" : ""}`}>
                            <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{rowNum}</td>
                            <td className="py-12 px-16 text-sm text-secondary-light">{lv.order_index ?? "—"}</td>
                            <td className="py-12 px-16 text-sm fw-bold text-dark">
                              <Trunc value={lv.world_name} maxWidth={200} />
                            </td>
                            <td className="py-12 px-16 text-sm fw-semibold text-dark">
                              <Trunc value={lv.name} maxWidth={240} />
                            </td>
                            <td className="py-12 px-16 text-sm text-secondary-light">
                              <Trunc value={lv.description || "—"} maxWidth={300} />
                            </td>

                            <td className="py-12 px-16 text-center text-xs text-secondary-light">
                              Stages: <strong className="text-dark">{lv.active_stages_count}/{lv.stages_count}</strong>
                            </td>

                            <td className="py-12 px-16 text-center text-sm text-secondary-light">
                              {lv.is_unlocked_by_default ? (
                                <span className="badge bg-success-subtle text-success border border-success-subtle radius-4 text-xs">Unlocked</span>
                              ) : (
                                <span className="badge bg-secondary-subtle text-secondary border border-secondary-subtle radius-4 text-xs">Locked</span>
                              )}
                            </td>

                            <td className="py-12 px-16 text-center align-middle">
                              <span
                                className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                  lv.is_active ? "status-badge-active" : "status-badge-inactive"
                                }`}
                              >
                                <Icon icon={lv.is_active ? "mdi:check-circle" : "mdi:close-circle"} />
                                <span>{lv.is_active ? "Active" : "Disabled"}</span>
                              </span>
                            </td>

                            {canAnyAction && (
                              <td className="py-12 px-16 text-center align-middle">
                                <div className="d-inline-flex align-items-center gap-6">
                                  {hasPermission("levels.view") && (
                                    <Link
                                      to={`/admin/levels/${lv.id}`}
                                      className="w-32-px h-32-px radius-8 bg-primary-50 text-primary-600 d-inline-flex align-items-center justify-content-center"
                                      title="View Level"
                                    >
                                      <Icon icon="iconamoon:eye-light" />
                                    </Link>
                                  )}

                                  {hasPermission("levels.update") && (
                                    <Link
                                      to={`/admin/levels/${lv.id}/edit`}
                                      className="w-32-px h-32-px radius-8 bg-success-50 text-success-600 d-inline-flex align-items-center justify-content-center"
                                      title="Edit Level"
                                    >
                                      <Icon icon="lucide:edit" />
                                    </Link>
                                  )}

                                  {hasPermission("levels.enable_disable") && (
                                    <button
                                      type="button"
                                      onClick={() => setToggleTarget(lv)}
                                      className={`w-32-px h-32-px radius-8 border-0 d-inline-flex align-items-center justify-content-center ${
                                        lv.is_active ? "bg-warning-50 text-warning-600" : "bg-info-50 text-info-600"
                                      }`}
                                      title={lv.is_active ? "Disable Level" : "Enable Level"}
                                    >
                                      <Icon icon={lv.is_active ? "mdi:toggle-switch-off-outline" : "mdi:toggle-switch-outline"} />
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

              {!loading && filteredLevels.length > 0 && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {(currentPage - 1) * pageSize + 1}–
                    {Math.min(currentPage * pageSize, filteredLevels.length)} of {filteredLevels.length} entries
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
        title={toggleTarget?.is_active ? "Disable Level?" : "Enable Level?"}
        message={`Are you sure you want to ${toggleTarget?.is_active ? "disable" : "enable"} the level "${toggleTarget?.name}"?`}
        confirmLabel={toggleTarget?.is_active ? "Disable Level" : "Enable Level"}
        cancelLabel="Cancel"
        variant={toggleTarget?.is_active ? "warning" : "primary"}
        loading={toggling}
        onConfirm={handleToggleConfirm}
        onCancel={() => setToggleTarget(null)}
      />
    </MasterLayout>
  );
};

export default LevelList;
