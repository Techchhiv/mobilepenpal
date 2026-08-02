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
    const dtRef = useRef(null);

    const canAnyAction = hasAnyPermission([
        "worlds.view",
        "worlds.update",
        "worlds.enable_disable",
    ]);

    const fetchWorlds = async () => {
        try {
            const res = await API.get("/admin/worlds");
            const payload = res.data?.data ?? res.data;
            const rows = Array.isArray(payload?.worlds) ? payload.worlds : [];
            setWorlds(rows.map(normalizeWorld));

        } catch (err) {
            console.error("Fetch worlds failed:", err);
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

        if (worlds.length > 0) {
            const t = setTimeout(() => {
                dtRef.current = $("#worldTable").DataTable({
                    destroy: true,
                    pageLength: 10,
                    scrollX: true,
                    scrollCollapse: true,
                    autoWidth: true,
                    order: [[1, "asc"]],
                    columnDefs: [
                        { targets: 0, width: "60px" },
                        { targets: 1, width: "60px" },
                        { targets: 2, width: "160px" },
                        { targets: 3, width: "200px" },
                        { targets: 4, width: "100px" }, // Premium
                        { targets: 5, width: "170px" }, // Content
                        // { targets: 6, width: "140px" }, // Default Unlock
                        // { targets: 7, width: "140px" }, // Status
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
    }, [worlds, canAnyAction]);


    const toggleWorld = async (id) => {
        try {
            await API.put(`/admin/worlds/${id}/toggle`);
            await fetchWorlds();
        } catch (err) {
            console.error(err);
        }
    };

    return (
        <MasterLayout>
            <div className="card basic-data-table">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <h5>Worlds</h5>

                    {hasPermission("worlds.create") && (
                        <Link to="/admin/worlds/create">
                            <button type="button" className="d-flex align-items-center btn btn-primary-600 radius-3 px-20 py-11">
                                <Icon icon="mdi:plus" className="me-8" />
                                Create
                            </button>
                        </Link>
                    )}
                </div>

                <div className="card-body">
                    <table className="table bordered-table mb-0" id="worldTable" data-page-length={10}>
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Order</th>
                                <th>Name</th>
                                <th>Description</th>
                                <th className="text-center align-middle">Content</th>
                                <th className="text-center align-middle">Default Unlock</th>
                                <th className="text-center align-middle">Status</th>
                                {canAnyAction && <th className="text-center align-middle">Action</th>}
                            </tr>
                        </thead>

                        <tbody>
                            {worlds.length === 0 ? (
                                <tr>
                                    <td colSpan={canAnyAction ? 9 : 8} className="text-center">
                                        No worlds found
                                    </td>
                                </tr>
                            ) : (
                                worlds.map((w, idx) => (
                                    <tr key={w.id} className={!w.is_active ? "table-light" : ""}>
                                        <td>{idx + 1}</td>
                                        <td>{w.order_index ?? "—"}</td>
                                        <td>
                                            <Trunc value={w.name} maxWidth={260} />
                                        </td>

                                        <td>
                                            <Trunc value={w.description || "—"} maxWidth={320} />
                                        </td>

                                        <td>
                                            <div className="small text-center">
                                                Levels: {w.active_levels_count}/{w.levels_count}
                                                <br />
                                                Stages: {w.active_stages_count}/{w.stages_count}
                                            </div>
                                        </td>

                                        <td className="text-center">{w.is_unlocked_by_default ? "Yes" : "No"}</td>

                                        <td className="text-center align-middle">
                                            <span
                                                className={`px-24 py-4 rounded-pill fw-medium text-sm ${w.is_active
                                                    ? "bg-success-focus text-success-main"
                                                    : "bg-warning-focus text-warning-main"
                                                    }`}
                                            >
                                                {w.is_active ? "Active" : "Disabled"}
                                            </span>
                                        </td>

                                        {canAnyAction && (
                                            <td className="text-center align-middle">
                                                {hasPermission("worlds.view") && (
                                                    <Link
                                                        to={`/admin/worlds/${w.id}`}
                                                        className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                                                        title="View"
                                                    >
                                                        <Icon icon="iconamoon:eye-light" />
                                                    </Link>
                                                )}

                                                {hasPermission("worlds.update") && (
                                                    <Link
                                                        to={`/admin/worlds/${w.id}/edit`}
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

export default WorldList;
