import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

function prettyDate(d) {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
}

const WorldView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission } = useAuth();

    const [world, setWorld] = useState(null);
    const [loading, setLoading] = useState(true);

    const [message, setMessage] = useState("");
    const [error, setError] = useState("");

    const canView = hasPermission("worlds.view");
    const canEdit = hasPermission("worlds.update");
    const canToggle = hasPermission("worlds.enable_disable");

    const canCreateLevel = hasPermission("levels.create") || hasPermission("worlds.update");

    const [insertLevelOpen, setInsertLevelOpen] = useState(false);
    const [insertLevelLoading, setInsertLevelLoading] = useState(false);
    const [insertLevelError, setInsertLevelError] = useState("");

    const [newLevelName, setNewLevelName] = useState("");
    const [newLevelDescription, setNewLevelDescription] = useState("");
    const [newLevelNameEn, setNewLevelNameEn] = useState("");
    const [newLevelDescriptionEn, setNewLevelDescriptionEn] = useState("");

    const [newLevelActive, setNewLevelActive] = useState(true);
    const [newLevelUnlockedByDefault, setNewLevelUnlockedByDefault] = useState(false);

    const fetchWorld = async () => {
        setLoading(true);
        setError("");
        setMessage("");

        try {
            const res = await API.get(`/admin/worlds/${id}`);
            const payload = res.data?.data ?? res.data; // ✅ handle wrapper
            setWorld(payload?.world ?? null);
        } catch (err) {
            console.error("Fetch world failed:", err);
            setError(err?.response?.data?.message || "Failed to load world.");
        } finally {
            setLoading(false);
        }
    };


    const openInsertLevel = () => {
        setInsertLevelError("");
        setNewLevelName("");
        setNewLevelNameEn("");
        setNewLevelDescription("");
        setNewLevelDescriptionEn("");
        setNewLevelActive(true);
        setNewLevelUnlockedByDefault(false);
        setInsertLevelOpen(true);
    };


    const closeInsertLevel = () => {
        setInsertLevelOpen(false);
        setInsertLevelError("");
    };

    const submitInsertLevel = async () => {
        setInsertLevelLoading(true);
        setInsertLevelError("");
        setError("");
        setMessage("");

        try {
            const payload = {
                name: newLevelName.trim(),
                name_en: newLevelNameEn.trim() || null,
                description: newLevelDescription.trim() || null,
                description_en: newLevelDescriptionEn.trim() || null,
                is_active: newLevelActive ? 1 : 0,
                is_unlocked_by_default: newLevelUnlockedByDefault ? 1 : 0,
            };

            if (!payload.name) {
                setInsertLevelError("Level name (KH) is required.");
                return;
            }

            await API.post(`/admin/worlds/${id}/levels`, payload);

            setMessage("Level created.");
            closeInsertLevel();
            await fetchWorld();
        } catch (err) {
            console.error("Create level failed:", err);
            setInsertLevelError(err?.response?.data?.message || "Failed to create level.");
        } finally {
            setInsertLevelLoading(false);
        }
    };


    useEffect(() => {
        if (!canView) return;
        fetchWorld();
    }, [id, canView]);

    const normalized = useMemo(() => {
        if (!world) return null;

        const is_active =
            world?.is_active === true || String(world?.is_active ?? "0") === "1";

        const is_unlocked_by_default =
            world?.is_unlocked_by_default === true ||
            String(world?.is_unlocked_by_default ?? "0") === "1";

        const levels = Array.isArray(world?.levels) ? world.levels : [];

        const levels_count = levels.length;
        const active_levels_count = levels.filter(
            (l) => l?.is_active === true || String(l?.is_active ?? "0") === "1"
        ).length;

        const stages_count = levels.reduce(
            (sum, l) => sum + (Number(l?.stages_count) || 0),
            0
        );

        const active_stages_count = levels.reduce(
            (sum, l) => sum + (Number(l?.active_stages_count) || 0),
            0
        );

        return {
            ...world,
            is_active,
            is_unlocked_by_default,
            levels,
            levels_count,
            active_levels_count,
            stages_count,
            active_stages_count,
        };
    }, [world]);


    const toggleWorld = async () => {
        if (!normalized) return;

        setError("");
        setMessage("");
        try {
            await API.put(`/admin/worlds/${id}/toggle`);
            setMessage("World status updated");
            await fetchWorld();
        } catch (err) {
            console.error("Toggle failed:", err);
            setError(err?.response?.data?.message || "Toggle failed");
        }
    };

    if (!canView) {
        return (
            <MasterLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to view world details.
                </div>
            </MasterLayout>
        );
    }

    return (
        <MasterLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">World Details</h5>
                        <small className="text-muted">ID: {id}</small>
                    </div>

                    <div className="d-flex gap-2 flex-wrap">
                        <Link
                            to="/admin/worlds"
                            className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
                        >
                            <Icon icon="mdi:arrow-left" className="me-6" />
                            Back
                        </Link>

                        {canEdit && (
                            <Link
                                to={`/admin/worlds/${id}/edit`}
                                className="d-flex align-items-center btn btn-success radius-3 px-20 py-11"
                            >
                                <Icon icon="lucide:edit" className="me-6" />
                                Edit
                            </Link>
                        )}

                        {canToggle && normalized && (
                            <button
                                type="button"
                                onClick={toggleWorld}
                                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${normalized.is_active ? "btn-warning" : "btn-primary"
                                    }`}
                                title="Toggle Active"
                            >
                                <Icon icon="mdi:toggle-switch" className="me-6" />
                                {normalized.is_active ? "Disable" : "Enable"}
                            </button>
                        )}
                    </div>
                </div>

                <div className="card-body">
                    {message && <div className="alert alert-success">{message}</div>}
                    {error && <div className="alert alert-danger">{error}</div>}

                    {loading ? (
                        <div className="text-center py-40">
                            <div className="spinner-border" role="status" />
                            <div className="mt-12 text-muted">Loading world...</div>
                        </div>
                    ) : !normalized ? (
                        <div className="text-center py-40 text-muted">World not found.</div>
                    ) : (
                        <div className="row g-3">
                            {/* Left */}
                            <div className="col-12 col-md-4 col-lg-3">
                                <div className="card border">
                                    <div className="card-body text-center">
                                        <div
                                            className="d-inline-flex align-items-center justify-content-center"
                                            style={{
                                                width: 120,
                                                height: 120,
                                                borderRadius: 16,
                                                background: "#e5e7eb",
                                                border: "1px solid rgba(0,0,0,0.08)",
                                            }}
                                            title={normalized.theme_color || "—"}
                                        >
                                            <Icon icon="mdi:map" width={54} />
                                        </div>

                                        <h6 className="mt-16 mb-3">{normalized.name || "—"}</h6>
                                        {/* <h6 className="mt-16 mb-3">{normalized.name_en || "—"}</h6> */}

                                        <div className="d-flex justify-content-center gap-8 flex-wrap mt-3">
                                            <span className="badge bg-info text-dark">
                                                Audience: {normalized.audience ?? "—"}
                                            </span>

                                            <span
                                                className={`badge ${normalized.is_active ? "bg-success" : "bg-secondary"
                                                    }`}
                                            >
                                                {normalized.is_active ? "Active" : "Disabled"}
                                            </span>

                                            <span
                                                className={`badge ${normalized.is_unlocked_by_default
                                                    ? "bg-primary"
                                                    : "bg-light text-dark"
                                                    }`}
                                            >
                                                {normalized.is_unlocked_by_default
                                                    ? "Default Unlock"
                                                    : "Not Default"}
                                            </span>
                                        </div>

                                        <div className="mt-10 text-muted">
                                            Order Index:{" "}
                                            <span className="text-dark">
                                                {normalized.order_index ?? "—"}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="card border mt-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">Content Summary</h6>
                                    </div>
                                    <div className="card-body">
                                        <MiniRow
                                            label="Levels"
                                            value={`${normalized.active_levels_count}/${normalized.levels_count}`}
                                        />
                                        <MiniRow
                                            label="Stages"
                                            value={`${normalized.active_stages_count}/${normalized.stages_count}`}
                                        />
                                    </div>
                                </div>
                            </div>

                            {/* Right */}
                            <div className="col-12 col-md-8 col-lg-9">
                                <div className="card border mb-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">World Information</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem label="Name" value={normalized.name} />
                                            <InfoItem label="Name English" value={normalized.name_en} />
                                            <InfoItem
                                                label="Default Unlocked"
                                                value={normalized.is_unlocked_by_default ? "Yes" : "No"}
                                                colClass="col-12"
                                            />
                                            <InfoItem
                                                label="Description"
                                                value={normalized.description}
                                                colClass="col-12"
                                            />
                                            <InfoItem
                                                label="Description English"
                                                value={normalized.description_en}
                                                colClass="col-12"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="card border">
                                    <div className="card-header">
                                        <h6 className="mb-0">System</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem
                                                label="Created At"
                                                value={prettyDate(normalized.created_at)}
                                            />
                                            <InfoItem
                                                label="Updated At"
                                                value={prettyDate(normalized.updated_at)}
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="card border mt-3">
                                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                                        <h6 className="mb-0">Levels</h6>

                                        {canCreateLevel && (
                                            <button
                                                type="button"
                                                className="btn btn-primary d-flex align-items-center"
                                                onClick={openInsertLevel}
                                            >
                                                <Icon icon="mdi:plus" className="me-6" />
                                                Insert Level
                                            </button>
                                        )}
                                    </div>

                                    <div className="card-body">
                                        {normalized.levels.length === 0 ? (
                                            <div className="text-muted">No levels.</div>
                                        ) : (
                                            <div className="table-responsive">
                                                <table className="table bordered-table mb-0">
                                                    <thead>
                                                        <tr>
                                                            <th>Order</th>
                                                            <th>Name</th>
                                                            <th>Status</th>
                                                            <th>Stages</th>
                                                            <th style={{ width: 120 }} className="text-center">Action</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {normalized.levels
                                                            .slice()
                                                            .sort((a, b) => (a.order_index ?? 0) - (b.order_index ?? 0))
                                                            .map((l) => {
                                                                const active =
                                                                    l?.is_active === true || String(l?.is_active ?? "0") === "1";
                                                                return (
                                                                    <tr key={l.id} className={!active ? "table-light" : ""}>
                                                                        <td>{l.order_index ?? "—"}</td>
                                                                        <td>
                                                                            <div className="fw-medium">{l.name ?? "—"}</div>
                                                                            {l.name_en ? <div className="text-muted small">{l.name_en}</div> : null}
                                                                        </td>
                                                                        <td>
                                                                            <span
                                                                                className={`badge ${active ? "bg-success" : "bg-secondary"
                                                                                    }`}
                                                                            >
                                                                                {active ? "Active" : "Disabled"}
                                                                            </span>
                                                                        </td>
                                                                        <td>
                                                                            {l.active_stages_count}/{l.stages_count}
                                                                        </td>
                                                                        <td className="text-center align-middle">
                                                                            <Link
                                                                                to={`/admin/levels/${l.id}`}
                                                                                state={{ from: `/admin/worlds/${id}` }}
                                                                                title="View Level"
                                                                                className="bg-primary-focus text-primary-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                                                style={{ textDecoration: "none" }}
                                                                            >
                                                                                <Icon icon="mdi:eye-outline" />
                                                                            </Link>
                                                                        </td>

                                                                    </tr>
                                                                );
                                                            })}
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                {insertLevelOpen && (
                    <div
                        className="position-fixed top-0 start-0 w-100 h-100"
                        style={{
                            background: "rgba(0,0,0,0.55)",
                            zIndex: 1055,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            padding: 16,
                        }}
                        onClick={closeInsertLevel}
                        role="dialog"
                        aria-modal="true"
                    >
                        <div
                            className="card"
                            style={{ width: "min(760px, 96vw)", maxHeight: "90vh", overflow: "hidden" }}
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="card-header d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 className="mb-0">Insert Level</h6>
                                    <small className="text-muted">Create a new level for this world</small>
                                </div>

                                <button className="btn btn-light d-flex" type="button" onClick={closeInsertLevel} title="Close">
                                    <Icon icon="radix-icons:cross-2" />
                                </button>
                            </div>

                            <div className="card-body" style={{ overflow: "auto" }}>
                                {insertLevelError && <div className="alert alert-danger">{insertLevelError}</div>}

                                <div className="row g-3">
                                    <div className="col-12">
                                        <label className="form-label">Level Name (KH) *</label>
                                        <input
                                            className="form-control"
                                            value={newLevelName}
                                            onChange={(e) => setNewLevelName(e.target.value)}
                                            placeholder="e.g. ក - ង"
                                        />
                                    </div>

                                    <div className="col-12">
                                        <label className="form-label">Level Name (EN)</label>
                                        <input
                                            className="form-control"
                                            value={newLevelNameEn}
                                            onChange={(e) => setNewLevelNameEn(e.target.value)}
                                            placeholder="e.g. Ka - Ngo"
                                        />
                                    </div>

                                    <div className="col-12">
                                        <label className="form-label">Description (KH)</label>
                                        <textarea
                                            className="form-control"
                                            rows={3}
                                            value={newLevelDescription}
                                            onChange={(e) => setNewLevelDescription(e.target.value)}
                                            placeholder="Optional"
                                        />
                                    </div>

                                    <div className="col-12">
                                        <label className="form-label">Description (EN)</label>
                                        <textarea
                                            className="form-control"
                                            rows={3}
                                            value={newLevelDescriptionEn}
                                            onChange={(e) => setNewLevelDescriptionEn(e.target.value)}
                                            placeholder="Optional"
                                        />
                                    </div>


                                    <div className="col-12 col-md-6">
                                        <div className="form-check d-flex align-items-center gap-2">
                                            <input
                                                className="form-check-input m-0"
                                                type="checkbox"
                                                id="newLevelActive"
                                                checked={!!newLevelActive}
                                                onChange={(e) => setNewLevelActive(e.target.checked)}
                                                style={{ marginTop: 0 }}
                                            />
                                            <label className="form-check-label mb-0" htmlFor="newLevelActive">
                                                Active
                                            </label>
                                        </div>

                                        <small className="text-muted d-block">
                                            If unchecked, this level will be hidden from students.
                                        </small>
                                    </div>

                                    <div className="col-12 col-md-6">
                                        <div className="form-check d-flex align-items-center gap-2">
                                            <input
                                                className="form-check-input m-0"
                                                type="checkbox"
                                                id="newLevelUnlockedByDefault"
                                                checked={!!newLevelUnlockedByDefault}
                                                onChange={(e) => setNewLevelUnlockedByDefault(e.target.checked)}
                                                style={{ marginTop: 0 }}
                                            />
                                            <label className="form-check-label mb-0" htmlFor="newLevelUnlockedByDefault">
                                                Unlocked by default
                                            </label>
                                        </div>

                                        <small className="text-muted d-block">
                                            Students start with this level unlocked.
                                        </small>
                                    </div>

                                </div>
                            </div>

                            <div className="card-footer d-flex justify-content-end gap-2">
                                <button type="button" className="btn btn-secondary" onClick={closeInsertLevel} disabled={insertLevelLoading}>
                                    Cancel
                                </button>

                                <button
                                    type="button"
                                    className="btn btn-primary"
                                    onClick={submitInsertLevel}
                                    disabled={insertLevelLoading}
                                >
                                    {insertLevelLoading ? "Saving..." : "Create"}
                                </button>
                            </div>
                        </div>
                    </div>
                )}

            </div>
        </MasterLayout>
    );
};

const InfoItem = ({ label, value, colClass = "col-12 col-md-6 col-lg-4" }) => {
    const v = value === null || value === undefined || value === "" ? "—" : value;
    return (
        <div className={colClass}>
            <div className="p-12 border radius-8 h-100">
                <div className="text-muted small">{label}</div>
                <div className="fw-medium" style={{ wordBreak: "break-word" }}>
                    {v}
                </div>
            </div>
        </div>
    );
};

const MiniRow = ({ label, value }) => {
    const v = value === null || value === undefined || value === "" ? "—" : value;
    return (
        <div className="d-flex justify-content-between gap-2 py-6 border-bottom">
            <div className="text-muted small">{label}</div>
            <div className="fw-medium">{v}</div>
        </div>
    );
};

export default WorldView;
