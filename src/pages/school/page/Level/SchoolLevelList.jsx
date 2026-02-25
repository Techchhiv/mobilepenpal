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

const boolish = (v) => v === true || String(v ?? "0") === "1";

const normalizeLevel = (lv) => ({
    ...lv,
    is_active: boolish(lv?.is_active),
    is_unlocked_by_default: boolish(lv?.is_unlocked_by_default),
    stages_count: lv?.stages_count ?? "—",
    active_stages_count: lv?.active_stages_count ?? "—",
    world_name: lv?.world?.name ?? "—",
    owned_by_school: !!lv?.owned_by_school || lv?.world?.school_id != null || lv?.school_id != null,
});

const SchoolLevelList = () => {
    const { hasPermission, hasAnyPermission } = useAuth();
    const [levels, setLevels] = useState([]);
    const [loading, setLoading] = useState(true);
    const dtRef = useRef(null);

    const canView = hasPermission("worlds.view");
    const canCreate = hasPermission("worlds.create");
    const canUpdate = hasPermission("worlds.update");
    const canToggle = hasPermission("worlds.enable_disable");

    const canAnyAction = hasAnyPermission([
        "worlds.view",
        "worlds.update",
        "worlds.enable_disable",
    ]);

    const fetchLevels = async () => {
        try {
            const res = await API.get("/school/levels?include_inactive=1");
            const payload = res.data?.data ?? res.data;
            const rows = Array.isArray(payload?.levels) ? payload.levels : [];
            setLevels(rows.map(normalizeLevel));
        } catch (err) {
            console.error("Fetch school levels failed:", err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (!canView) return;
        fetchLevels();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [canView]);

    useEffect(() => {
        if (dtRef.current) {
            dtRef.current.destroy();
            dtRef.current = null;
        }

        if (levels.length > 0) {
            const t = setTimeout(() => {
                dtRef.current = $("#schoolLevelTable").DataTable({
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
            await API.put(`/school/levels/${id}/toggle`);
            await fetchLevels();
        } catch (err) {
            console.error(err);
        }
    };

    if (!canView) {
        return (
            <SchoolLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to view levels.
                </div>
            </SchoolLayout>
        );
    }

    return (
        <SchoolLayout>
            <div className="card basic-data-table">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <h5>Levels</h5>

                    {canCreate && (
                        <Link to="/school/levels/create">
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
                        id="schoolLevelTable"
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
                            {loading ? (
                                <tr>
                                    <td colSpan={canAnyAction ? 9 : 8} className="text-center py-4">
                                        <div className="spinner-border spinner-border-sm" role="status" />
                                        <div className="mt-2 text-muted">Loading levels…</div>
                                    </td>
                                </tr>
                            ) : levels.length === 0 ? (
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
                                                className={`px-24 py-4 rounded-pill fw-medium text-sm ${lv.is_active
                                                    ? "bg-success-focus text-success-main"
                                                    : "bg-warning-focus text-warning-main"
                                                    }`}
                                            >
                                                {lv.is_active ? "Active" : "Disabled"}
                                            </span>
                                        </td>

                                        {canAnyAction && (
                                            <td className="text-center align-middle">
                                                {/* View is OK for both school-owned and global levels */}
                                                {hasPermission("levels.view") && (
                                                    <Link
                                                        to={`/school/levels/${lv.id}`}
                                                        className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                                                        title="View"
                                                    >
                                                        <Icon icon="iconamoon:eye-light" />
                                                    </Link>
                                                )}

                                                {/* Only allow edit/toggle if school-owned */}
                                                {canUpdate && lv.owned_by_school && (
                                                    <Link
                                                        to={`/school/levels/${lv.id}/edit`}
                                                        className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                                                        title="Edit"
                                                    >
                                                        <Icon icon="lucide:edit" />
                                                    </Link>
                                                )}

                                                {canToggle && lv.owned_by_school && (
                                                    <button
                                                        type="button"
                                                        onClick={() => toggleLevel(lv.id)}
                                                        className="w-32-px h-32-px me-8 bg-warning-focus text-warning-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                        title="Toggle"
                                                    >
                                                        <Icon icon="mdi:toggle-switch" />
                                                    </button>
                                                )}

                                                {/* Optional hint if not owned */}
                                                {!lv.owned_by_school && (canUpdate || canToggle) && (
                                                    <span className="text-muted small" title="Global level (read-only)">
                                                        —
                                                    </span>
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

export default SchoolLevelList;
