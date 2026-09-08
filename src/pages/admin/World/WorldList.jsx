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

const normalizeWorld = (w) => ({
  ...w,
  is_active: w?.is_active === true || String(w?.is_active ?? "0") === "1",
  is_premium: w?.is_premium === true || String(w?.is_premium ?? "0") === "1",
  is_unlocked_by_default:
    w?.is_unlocked_by_default === true ||
    String(w?.is_unlocked_by_default ?? "0") === "1",
  levels_count: w?.levels_count ?? "—",
  active_levels_count: w?.active_levels_count ?? "—",
  stages_count: w?.stages_count ?? "—",
  active_stages_count: w?.active_stages_count ?? "—",
});

const WorldList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [worlds, setWorlds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Filters & Pagination
  const [searchVal, setSearchVal] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;

  // Toggle Confirm Modal
  const [toggleTarget, setToggleTarget] = useState(null);
  const [toggling, setToggling] = useState(false);

  const canAnyAction = hasAnyPermission([
    "worlds.view",
    "worlds.update",
    "worlds.enable_disable",
  ]);

  const fetchWorlds = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await API.get("/admin/worlds");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.worlds) ? payload.worlds : [];
      setWorlds(rows.map(normalizeWorld));
    } catch (err) {
      console.error("Fetch worlds failed:", err);
      setError(err?.response?.data?.message || "Failed to load worlds list.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorlds();
  }, []);

  const filteredWorlds = useMemo(() => {
    return worlds.filter((w) => {
      const matchesSearch =
        searchVal.trim() === "" ||
        (w.name || "").toLowerCase().includes(searchVal.toLowerCase()) ||
        (w.description || "").toLowerCase().includes(searchVal.toLowerCase());

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && w.is_active) ||
        (statusFilter === "inactive" && !w.is_active);

      return matchesSearch && matchesStatus;
    });
  }, [worlds, searchVal, statusFilter]);

  const totalPages = Math.ceil(filteredWorlds.length / pageSize) || 1;
  const paginatedWorlds = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredWorlds.slice(start, start + pageSize);
  }, [filteredWorlds, currentPage, pageSize]);

  const handleToggleConfirm = async () => {
    if (!toggleTarget) return;
    setToggling(true);
    try {
      await API.put(`/admin/worlds/${toggleTarget.id}/toggle`);
      setWorlds((prev) =>
        prev.map((w) =>
          w.id === toggleTarget.id ? { ...w, is_active: !w.is_active } : w
        )
      );
      setToggleTarget(null);
    } catch (err) {
      console.error("Toggle world failed:", err);
    } finally {
      setToggling(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="World Management"
          subtitle="Manage game worlds, learning stages, and content availability"
          primaryAction={
            hasPermission("worlds.create")
              ? {
                  label: "Create World",
                  to: "/admin/worlds/create",
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
                  placeholder="Search worlds by name or description..."
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
              Total: <strong>{filteredWorlds.length}</strong> worlds
            </div>
          </div>
        </div>

        {/* Error State */}
        {error ? (
          <AdminErrorState message={error} onRetry={fetchWorlds} />
        ) : (
          /* Table Container Card */
          <div className="card border radius-12 shadow-none">
            <div className="card-body p-0">
              <div className="table-responsive">
                <table className="table bordered-table mb-0 align-middle">
                  <thead>
                    <tr>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">#</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Order</th>
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
                          {canAnyAction && <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>}
                        </tr>
                      ))
                    ) : paginatedWorlds.length === 0 ? (
                      <tr>
                        <td colSpan={canAnyAction ? 8 : 7} className="text-center text-secondary-light py-40">
                          <Icon icon="mdi:earth-off" width="48" className="mb-12 opacity-50" />
                          <h6>No worlds found</h6>
                          <p className="text-xs text-secondary-light mb-0">Try adjusting your search query or filter options.</p>
                        </td>
                      </tr>
                    ) : (
                      paginatedWorlds.map((w, idx) => {
                        const rowNum = (currentPage - 1) * pageSize + idx + 1;
                        return (
                          <tr key={w.id} className={`hover-bg-neutral-50 transition-1 ${!w.is_active ? "opacity-75" : ""}`}>
                            <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{rowNum}</td>
                            <td className="py-12 px-16 text-sm text-secondary-light">{w.order_index ?? "—"}</td>
                            <td className="py-12 px-16 text-sm fw-bold text-dark">
                              <Trunc value={w.name} maxWidth={260} />
                            </td>

                            <td className="py-12 px-16 text-sm text-secondary-light">
                              <Trunc value={w.description || "—"} maxWidth={320} />
                            </td>

                            <td className="py-12 px-16 text-center">
                              <div className="text-xs text-secondary-light">
                                Levels: <strong className="text-dark">{w.active_levels_count}/{w.levels_count}</strong>
                                <br />
                                Stages: <strong className="text-dark">{w.active_stages_count}/{w.stages_count}</strong>
                              </div>
                            </td>

                            <td className="py-12 px-16 text-center text-sm text-secondary-light">
                              {w.is_unlocked_by_default ? (
                                <span className="badge bg-success-subtle text-success border border-success-subtle radius-4 text-xs">Unlocked</span>
                              ) : (
                                <span className="badge bg-secondary-subtle text-secondary border border-secondary-subtle radius-4 text-xs">Locked</span>
                              )}
                            </td>

                            <td className="py-12 px-16 text-center align-middle">
                              <span
                                className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                  w.is_active ? "status-badge-active" : "status-badge-inactive"
                                }`}
                              >
                                <Icon icon={w.is_active ? "mdi:check-circle" : "mdi:close-circle"} />
                                <span>{w.is_active ? "Active" : "Disabled"}</span>
                              </span>
                            </td>

                            {canAnyAction && (
                              <td className="py-12 px-16 text-center align-middle">
                                <div className="d-inline-flex align-items-center gap-6">
                                  {hasPermission("worlds.view") && (
                                    <Link
                                      to={`/admin/worlds/${w.id}`}
                                      className="w-32-px h-32-px radius-8 bg-primary-50 text-primary-600 d-inline-flex align-items-center justify-content-center"
                                      title="View World"
                                    >
                                      <Icon icon="iconamoon:eye-light" />
                                    </Link>
                                  )}

                                  {hasPermission("worlds.update") && (
                                    <Link
                                      to={`/admin/worlds/${w.id}/edit`}
                                      className="w-32-px h-32-px radius-8 bg-success-50 text-success-600 d-inline-flex align-items-center justify-content-center"
                                      title="Edit World"
                                    >
                                      <Icon icon="lucide:edit" />
                                    </Link>
                                  )}

                                  {hasPermission("worlds.enable_disable") && (
                                    <button
                                      type="button"
                                      onClick={() => setToggleTarget(w)}
                                      className={`w-32-px h-32-px radius-8 border-0 d-inline-flex align-items-center justify-content-center ${
                                        w.is_active ? "bg-warning-50 text-warning-600" : "bg-info-50 text-info-600"
                                      }`}
                                      title={w.is_active ? "Disable World" : "Enable World"}
                                    >
                                      <Icon icon={w.is_active ? "mdi:toggle-switch-off-outline" : "mdi:toggle-switch-outline"} />
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

              {/* Standard Pagination Footer */}
              {!loading && filteredWorlds.length > 0 && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {(currentPage - 1) * pageSize + 1}–
                    {Math.min(currentPage * pageSize, filteredWorlds.length)} of {filteredWorlds.length} entries
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

      {/* Confirmation Modal for Toggle Action */}
      <ConfirmModal
        open={Boolean(toggleTarget)}
        title={toggleTarget?.is_active ? "Disable Game World?" : "Enable Game World?"}
        message={`Are you sure you want to ${toggleTarget?.is_active ? "disable" : "enable"} the world "${toggleTarget?.name}"? Students will ${toggleTarget?.is_active ? "no longer be able to access" : "now be able to access"} stages in this world.`}
        confirmLabel={toggleTarget?.is_active ? "Disable World" : "Enable World"}
        cancelLabel="Cancel"
        variant={toggleTarget?.is_active ? "warning" : "primary"}
        loading={toggling}
        onConfirm={handleToggleConfirm}
        onCancel={() => setToggleTarget(null)}
      />
    </MasterLayout>
  );
};

export default WorldList;
