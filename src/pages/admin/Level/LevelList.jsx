import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Trunc = ({ value, maxWidth = 240 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
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
  const dtRef = useRef(null);

  const canAnyAction = hasAnyPermission([
    "levels.view",
    "levels.update",
    "levels.enable_disable",
  ]);

  const fetchLevels = async () => {
    try {
      // global endpoint
      const res = await API.get("/admin/levels?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.levels) ? payload.levels : [];
      setLevels(rows.map(normalizeLevel));
    } catch (err) {
      console.error("Fetch levels failed:", err);
    }
  };

  useEffect(() => {
    fetchLevels();
  }, []);

  useEffect(() => {
    // destroy previous datatable before re-init
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (levels.length > 0) {
      const t = setTimeout(() => {
        dtRef.current = $("#levelTable").DataTable({
          destroy: true,
          pageLength: 10,
          scrollX: true,
          scrollCollapse: true,
          autoWidth: true,
          order: [[1, "asc"]],
          columnDefs: [
            { targets: 0, width: "60px" },
            { targets: 1, width: "80px" },
            { targets: 2, width: "160px" },
            { targets: 3, width: "220px" }, 
            { targets: 4, width: "260px" },
            { targets: 5, width: "170px" },
            { targets: 6, width: "160px" },
            { targets: 7, width: "140px" },
            ...(canAnyAction ? [{ targets: 8, width: "160px" }] : []),
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
  }, [levels, canAnyAction]);

  const toggleLevel = async (id) => {
    try {
      await API.put(`/admin/levels/${id}/toggle`);
      await fetchLevels();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Levels</h5>

          {hasPermission("levels.create") && (
            <Link to="/admin/levels/create">
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
          <table
            className="table bordered-table mb-0"
            id="levelTable"
            data-page-length={10}
          >
            <thead>
              <tr>
                <th>#</th>
                <th>Order</th>
                <th>World</th>
                <th>Name</th>
                <th>Description</th>
                <th className="text-center align-middle">Content</th>
                <th className="text-center align-middle">Default Unlock</th>
                <th className="text-center align-middle">Status</th>
                {canAnyAction && (
                  <th className="text-center align-middle">Action</th>
                )}
              </tr>
            </thead>

            <tbody>
              {levels.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center">
                    No levels found
                  </td>
                </tr>
              ) : (
                levels.map((lv, idx) => (
                  <tr key={lv.id} className={!lv.is_active ? "table-light" : ""}>
                    <td>{idx + 1}</td>
                    <td>{lv.order_index ?? "—"}</td>

                    <td>
                      <Trunc value={lv.world_name} maxWidth={220} />
                    </td>

                    <td>
                      <Trunc value={lv.name} maxWidth={260} />
                    </td>

                    <td>
                      <Trunc value={lv.description || "—"} maxWidth={320} />
                    </td>

                    <td>
                      <div className="small text-center">
                        Stages: {lv.active_stages_count}/{lv.stages_count}
                      </div>
                    </td>

                    <td className="text-center">
                      {lv.is_unlocked_by_default ? "Yes" : "No"}
                    </td>

                    <td className="text-center align-middle">
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          lv.is_active
                            ? "bg-success-focus text-success-main"
                            : "bg-warning-focus text-warning-main"
                        }`}
                      >
                        {lv.is_active ? "Active" : "Disabled"}
                      </span>
                    </td>

                    {canAnyAction && (
                      <td className="text-center align-middle">
                        {hasPermission("levels.view") && (
                          <Link
                            to={`/admin/levels/${lv.id}`}
                            className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="View"
                          >
                            <Icon icon="iconamoon:eye-light" />
                          </Link>
                        )}

                        {hasPermission("levels.update") && (
                          <Link
                            to={`/admin/levels/${lv.id}/edit`}
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="Edit"
                          >
                            <Icon icon="lucide:edit" />
                          </Link>
                        )}

                        {hasPermission("levels.enable_disable") && (
                          <button
                            type="button"
                            onClick={() => toggleLevel(lv.id)}
                            className="w-32-px h-32-px me-8 bg-warning-focus text-warning-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                            title="Toggle"
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
    </MasterLayout>
  );
};

export default LevelList;
