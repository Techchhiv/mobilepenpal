import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link, useSearchParams } from "react-router-dom";

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
  const dtRef = useRef(null);

  const [searchParams] = useSearchParams();
  const worldId = searchParams.get("world_id");
  const levelId = searchParams.get("level_id");

  const canAnyAction = hasAnyPermission([
    "stages.view",
    "stages.update",
    "stages.enable_disable",
  ]);

  const fetchStages = async () => {
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
    }
  };

  useEffect(() => {
    fetchStages();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [worldId, levelId]);

  useEffect(() => {
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (stages.length > 0) {
      const t = setTimeout(() => {
        dtRef.current = $("#stageTable").DataTable({
          destroy: true,
          pageLength: 10,
          scrollX: true,
          scrollCollapse: true,
          autoWidth: true,
          order: [[1, "asc"]],
          columnDefs: [
            { targets: 0, width: "60px" },  // #
            { targets: 1, width: "80px" },  // order
            { targets: 2, width: "160px" }, // world
            { targets: 3, width: "180px" }, // level
            { targets: 4, width: "220px" }, // name
            { targets: 5, width: "260px" }, // desc
            { targets: 6, width: "170px" }, // content
            { targets: 7, width: "110px" }, // max stars
            { targets: 8, width: "140px" }, // status
            ...(canAnyAction ? [{ targets: 9, width: "180px" }] : []),
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
  }, [stages, canAnyAction]);

  const toggleStage = async (id) => {
    try {
      await API.put(`/admin/stages/${id}/toggle`);
      await fetchStages();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <div>
            <h5 className="mb-0">Stages</h5>
            {(worldId || levelId) && (
              <div className="text-muted small">
                Filter:
                {worldId ? ` world_id=${worldId}` : ""}
                {levelId ? ` level_id=${levelId}` : ""}
              </div>
            )}
          </div>

          {hasPermission("stages.create") && (
            <Link to="/admin/stages/create">
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
            id="stageTable"
            data-page-length={10}
          >
            <thead>
              <tr>
                <th>#</th>
                <th>Order</th>
                <th>World</th>
                <th>Level</th>
                <th>Name</th>
                <th>Description</th>
                <th className="text-center align-middle">Content</th>
                <th className="text-center align-middle">Max Stars</th>
                <th className="text-center align-middle">Status</th>
                {canAnyAction && (
                  <th className="text-center align-middle">Action</th>
                )}
              </tr>
            </thead>

            <tbody>
              {stages.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 10 : 9} className="text-center">
                    No stages found
                  </td>
                </tr>
              ) : (
                stages.map((s, idx) => (
                  <tr key={s.id} className={!s.is_active ? "table-light" : ""}>
                    <td>{idx + 1}</td>
                    <td>{s.order_index ?? "—"}</td>

                    <td>
                      <Trunc value={s.world_name} maxWidth={220} />
                    </td>

                    <td>
                      <Trunc value={s.level_name} maxWidth={240} />
                    </td>

                    <td>
                      <Trunc value={s.name} maxWidth={280} />
                    </td>

                    <td>
                      <Trunc value={s.description || "—"} maxWidth={320} />
                    </td>

                    <td>
                      <div className="small text-center">
                        Exercises: {s.active_exercises_count}/{s.exercises_count}
                      </div>
                    </td>

                    <td className="text-center">{s.max_stars ?? "—"}</td>

                    <td className="text-center align-middle">
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          s.is_active
                            ? "bg-success-focus text-success-main"
                            : "bg-warning-focus text-warning-main"
                        }`}
                      >
                        {s.is_active ? "Active" : "Disabled"}
                      </span>
                    </td>

                    {canAnyAction && (
                      <td className="text-center align-middle">
                        {hasPermission("stages.view") && (
                          <Link
                            to={`/admin/stages/${s.id}`}
                            className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="View"
                          >
                            <Icon icon="iconamoon:eye-light" />
                          </Link>
                        )}

                        {hasPermission("stages.update") && (
                          <Link
                            to={`/admin/stages/${s.id}/edit`}
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="Edit"
                          >
                            <Icon icon="lucide:edit" />
                          </Link>
                        )}

                        {hasPermission("stages.enable_disable") && (
                          <button
                            type="button"
                            onClick={() => toggleStage(s.id)}
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

          {/* Optional helper link when filtered */}
          {(worldId || levelId) && (
            <div className="mt-12">
              <Link to="/admin/stages" className="text-decoration-underline small">
                Clear filters
              </Link>
            </div>
          )}
        </div>
      </div>
    </MasterLayout>
  );
};

export default StageList;
