import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const Trunc = ({ value, maxWidth = 240 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const normalizeWorldRow = (w) => {
  const ownedBySchool = w?.owned_by_school === true || w?.owned_by_school === 1;
  const isActive = normalizeBool(w?.is_active);

  const isAdmin = !ownedBySchool && (w?.school_id == null);

  const isHiddenForSchool =
    isAdmin ? (w?.is_hidden_for_school === true || String(w?.is_hidden_for_school ?? "0") === "1") : false;

  // Ordering:
  // - global_worlds use order_index
  // - school_stack: use stack_order_index (falls back to order_index if missing)
  const sortIndex =
    (ownedBySchool || w?.audience === "assigned")
      ? (w?.stack_order_index ?? w?.order_index ?? null)
      : (w?.order_index ?? null);

  // Source label
  const sourceLabel = ownedBySchool ? "School" : `Admin (${w?.audience ?? "public"})`;

  // Status label/class
  let statusLabel = "—";
  let statusClass = "bg-secondary-focus text-secondary-main";
  let isDim = false;

  if (ownedBySchool) {
    statusLabel = isActive ? "Active" : "Disabled";
    statusClass = isActive
      ? "bg-success-focus text-success-main"
      : "bg-warning-focus text-warning-main";
    isDim = !isActive;
  } else {
    statusLabel = isHiddenForSchool ? "Hidden" : "Visible";
    statusClass = isHiddenForSchool
      ? "bg-warning-focus text-warning-main"
      : "bg-success-focus text-success-main";
    isDim = isHiddenForSchool;
  }

  return {
    ...w,
    owned_by_school: ownedBySchool,
    is_active: isActive,
    is_admin_world: isAdmin,
    is_hidden_for_school: isHiddenForSchool,
    sort_index: sortIndex,
    source_label: sourceLabel,
    status_label: statusLabel,
    status_class: statusClass,
    is_dim: isDim,

    active_levels_count: w?.active_levels_count ?? "—",
    active_stages_count: w?.active_stages_count ?? "—",
  };
};

const SchoolWorldList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const dtRef = useRef(null);

  const canAnyAction = hasAnyPermission([
    "worlds.view",
    "worlds.update",
    "worlds.enable_disable",
  ]);

  const fetchWorlds = async () => {
    try {
      const res = await API.get("/school/worlds");
      const data = res.data?.data ?? {};
      const globalWorlds = Array.isArray(data?.global_worlds) ? data.global_worlds : [];
      const schoolStack = Array.isArray(data?.school_stack) ? data.school_stack : [];

      // merge + normalize
      const merged = [...globalWorlds, ...schoolStack].map(normalizeWorldRow);

      // Sort so globals first (order_index), then stack (stack_order_index)
      // If you want a single combined order, remove group sorting and just sort by sort_index.
      merged.sort((a, b) => {
        const ga = a.owned_by_school || a.audience === "assigned" ? 1 : 0;
        const gb = b.owned_by_school || b.audience === "assigned" ? 1 : 0;
        if (ga !== gb) return ga - gb;

        const ai = Number(a.sort_index ?? 999999);
        const bi = Number(b.sort_index ?? 999999);
        if (ai !== bi) return ai - bi;

        return (a.id ?? 0) - (b.id ?? 0);
      });

      setRows(merged);
    } catch (err) {
      console.error("Fetch school worlds failed:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorlds();
  }, []);

  useEffect(() => {
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (rows.length > 0) {
      const t = setTimeout(() => {
        dtRef.current = $("#schoolWorldTable").DataTable({
          destroy: true,
          pageLength: 10,
          scrollX: true,
          scrollCollapse: true,
          autoWidth: true,
          order: [[1, "asc"]],
          columnDefs: [
            { targets: 0, width: "60px" },
            { targets: 1, width: "80px" },  // Order
            { targets: 2, width: "150px" }, // Source
            { targets: 3, width: "220px" }, // Name
            { targets: 4, width: "300px" }, // Desc
            { targets: 5, width: "170px" }, // Content
            { targets: 6, width: "140px" }, // Default Unlock
            { targets: 7, width: "140px" }, // Status
          ],
        });
      }, 0);

      return () => clearTimeout(t);
    }

    return () => {
      if (dtRef.current) {
        dtRef.current.destroy();
        dtRef.current = null;
      }
    };
  }, [rows, canAnyAction]);

  const toggleWorld = async (id) => {
    try {
      await API.put(`/school/worlds/${id}/toggle`);
      await fetchWorlds();
    } catch (err) {
      console.error("Toggle world failed:", err);
    }
  };

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Worlds</h5>

          {hasPermission("worlds.create") && (
            <Link to="/school/worlds/create">
              <button
                type="button"
                className="d-flex align-items-center btn btn-primary-600 radius-3 px-20 py-11"
              >
                <Icon icon="mdi:plus" className="me-8" />
                Create
              </button>
            </Link>
          )}
        </div>

        <div className="card-body">
          <table className="table bordered-table mb-0" id="schoolWorldTable" data-page-length={10}>
            <thead>
              <tr>
                <th>#</th>
                <th>Order</th>
                <th>Source</th>
                <th>Name</th>
                <th>Description</th>
                <th className="text-center align-middle">Content</th>
                <th className="text-center align-middle">Default Unlock</th>
                <th className="text-center align-middle">Status</th>
                {canAnyAction && <th className="text-center align-middle">Action</th>}
              </tr>
            </thead>

            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center py-4">
                    <div className="spinner-border spinner-border-sm" role="status" />
                    <div className="mt-2 text-muted">Loading worlds…</div>
                  </td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center">
                    No worlds found
                  </td>
                </tr>
              ) : (
                rows.map((w, idx) => (
                  <tr key={`${w.id}-${w.owned_by_school ? "school" : "admin"}`} className={w.is_dim ? "table-light" : ""}>
                    <td>{idx + 1}</td>

                    <td>{w.sort_index ?? "—"}</td>

                    <td>
                      <span className="text-sm fw-medium">{w.source_label}</span>
                    </td>

                    <td>
                      <Trunc value={w.name} maxWidth={260} />
                    </td>

                    <td>
                      <Trunc value={w.description || "—"} maxWidth={340} />
                    </td>

                    <td>
                      <div className="small text-center">
                        Levels: {w.active_levels_count}
                        <br />
                        Stages: {w.active_stages_count}
                      </div>
                    </td>

                    <td className="text-center">
                      {normalizeBool(w.is_unlocked_by_default) ? "Yes" : "No"}
                    </td>

                    <td className="text-center align-middle">
                      <span className={`px-24 py-4 rounded-pill fw-medium text-sm ${w.status_class}`}>
                        {w.status_label}
                      </span>
                    </td>

                    {canAnyAction && (
                      <td className="text-center align-middle">
                        {hasPermission("worlds.view") && (
                          <Link
                            to={`/school/worlds/${w.id}`}
                            className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="View"
                          >
                            <Icon icon="iconamoon:eye-light" />
                          </Link>
                        )}

                        {/* only school-owned worlds can be edited by school */}
                        {w.owned_by_school && hasPermission("worlds.update") && (
                          <Link
                            to={`/school/worlds/${w.id}/edit`}
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="Edit"
                          >
                            <Icon icon="lucide:edit" />
                          </Link>
                        )}

                        {hasPermission("worlds.enable_disable") && (
                          <button
                            type="button"
                            onClick={() => toggleWorld(w.id)}
                            className="w-32-px h-32-px me-8 bg-warning-focus text-warning-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title={w.owned_by_school ? "Toggle Active" : "Hide/Show for School"}
                          >
                            <Icon icon="mdi:toggle-switch" />
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </SchoolLayout>
  );
};

export default SchoolWorldList;