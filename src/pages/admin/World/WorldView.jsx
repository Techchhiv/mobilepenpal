import React, { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";

function prettyDate(d) {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
}

const boolish = (v) => v === true || String(v ?? "0") === "1";

const WorldView = () => {
    const { id } = useParams();
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
            const payload = res.data?.data ?? res.data;
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

        const is_active = boolish(world?.is_active);
        const is_premium = boolish(world?.is_premium);
        const is_unlocked_by_default = boolish(world?.is_unlocked_by_default);

        const levels = Array.isArray(world?.levels) ? world.levels : [];

        const levels_count = levels.length;
        const active_levels_count = levels.filter((l) => boolish(l?.is_active)).length;

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
            is_premium,
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
            <div className="py-12">
                <AdminPageHeader
                    title={`World Details — ${normalized?.name || `#${id}`}`}
                    subtitle="Review world hierarchy, levels, and assigned scope"
                />

                <div className="card border radius-12 shadow-none">
                    <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
                        <div>
                            <h6 className="fw-bold mb-0 text-dark">World Details <span className="text-secondary-light text-xs font-normal">#{id}</span></h6>
                        </div>

                        <div className="d-flex gap-8 flex-wrap">
                            <Link
                                to="/admin/worlds"
                                className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                            >
                                <Icon icon="mdi:arrow-left" />
                                <span>Back</span>
                            </Link>

                            {canEdit && (
                                <Link
                                    to={`/admin/worlds/${id}/edit`}
                                    className="btn btn-success btn-sm radius-8 d-inline-flex align-items-center gap-6"
                                >
                                    <Icon icon="lucide:edit" />
                                    <span>Edit</span>
                                </Link>
                            )}

                            {canToggle && normalized && (
                                <button
                                    type="button"
                                    onClick={toggleWorld}
                                    className={`btn btn-sm radius-8 d-inline-flex align-items-center gap-6 ${normalized.is_active ? "btn-outline-warning" : "btn-primary"
                                        }`}
                                    title="Toggle Active"
                                >
                                    <Icon icon="mdi:toggle-switch" />
                                    <span>{normalized.is_active ? "Disable" : "Enable"}</span>
                                </button>
                            )}
                        </div>
                    </div>

                    <div className="card-body p-24">
                        {message && <div className="alert alert-success mb-20 radius-8">{message}</div>}
                        {error && <div className="alert alert-danger mb-20 radius-8">{error}</div>}

                        {loading ? (
                            <div className="py-24">
                              <div className="skeleton-loader py-20 w-100 mb-12 radius-8"></div>
                              <div className="skeleton-loader py-40 w-100 radius-8"></div>
                            </div>
                        ) : !normalized ? (
                            <div className="text-center py-40 text-secondary-light">World not found.</div>
                        ) : (
                            <div className="row g-3">
                                {/* Left */}
                                <div className="col-12 col-md-4 col-lg-3">
                                    <div className="card border radius-12 shadow-none">
                                        <div className="card-body text-center p-20">
                                            <div
                                                className="d-inline-flex align-items-center justify-content-center border radius-16 bg-neutral-100 text-secondary-light"
                                                style={{
                                                    width: 110,
                                                    height: 110,
                                                }}
                                                title={normalized.theme_color || "—"}
                                            >
                                                <Icon icon="mdi:map" width={48} />
                                            </div>

                                            <h6 className="mt-16 mb-1 fw-bold text-dark">{normalized.name || "—"}</h6>

                                            <div className="d-flex justify-content-center gap-8 flex-wrap mt-3">
                                                <span className="badge bg-info-50 text-info-600 px-10 py-4 radius-6 text-xs fw-semibold">
                                                    Audience: {normalized.audience ?? "—"}
                                                </span>

                                                <span
                                                    className={`status-badge px-10 py-4 radius-6 text-xs fw-semibold ${normalized.is_active ? "status-badge-active" : "status-badge-inactive"
                                                        }`}
                                                >
                                                    {normalized.is_active ? "Active" : "Disabled"}
                                                </span>

                                                <span
                                                    className={`badge px-10 py-4 radius-6 text-xs fw-semibold ${normalized.is_unlocked_by_default
                                                        ? "bg-primary-50 text-primary-600"
                                                        : "bg-neutral-100 text-secondary-light border border-neutral-200"
                                                        }`}
                                                >
                                                    {normalized.is_unlocked_by_default
                                                        ? "Default Unlock"
                                                        : "Not Default"}
                                                </span>
                                            </div>

                                            <div className="mt-12 text-secondary-light text-xs">
                                                Order Index:{" "}
                                                <span className="text-dark fw-semibold">
                                                    {normalized.order_index ?? "—"}
                                                </span>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="card border radius-12 shadow-none mt-3">
                                        <div className="card-header border-bottom py-12 px-16 bg-base">
                                            <h6 className="mb-0 fw-bold text-dark text-sm">Content Summary</h6>
                                        </div>
                                        <div className="card-body p-16">
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
                                    <div className="card border radius-12 shadow-none mb-3">
                                        <div className="card-header border-bottom py-12 px-16 bg-base">
                                            <h6 className="mb-0 fw-bold text-dark text-sm">World Information</h6>
                                        </div>
                                        <div className="card-body p-20">
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

                                    <div className="card border radius-12 shadow-none">
                                        <div className="card-header border-bottom py-12 px-16 bg-base">
                                            <h6 className="mb-0 fw-bold text-dark text-sm">System Info</h6>
                                        </div>
                                        <div className="card-body p-20">
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

                                    <div className="card border radius-12 shadow-none mt-3">
                                        <div className="card-header border-bottom py-12 px-16 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
                                            <h6 className="mb-0 fw-bold text-dark text-sm">Levels</h6>

                                            {canCreateLevel && (
                                                <button
                                                    type="button"
                                                    className="btn btn-primary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                                                    onClick={openInsertLevel}
                                                >
                                                    <Icon icon="mdi:plus" />
                                                    <span>Insert Level</span>
                                                </button>
                                            )}
                                        </div>

                                        <div className="card-body p-20">
                                            {normalized.levels.length === 0 ? (
                                                <div className="text-secondary-light text-sm">No levels found.</div>
                                            ) : (
                                                <div className="table-responsive">
                                                    <table className="table bordered-table mb-0 align-middle">
                                                        <thead>
                                                            <tr>
                                                                <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Order</th>
                                                                <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Name</th>
                                                                <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Status</th>
                                                                <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Stages</th>
                                                                <th scope="col" style={{ width: 120 }} className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Action</th>
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
                                                                        <tr key={l.id} className={`hover-bg-neutral-50 transition-1 ${!active ? "opacity-75" : ""}`}>
                                                                            <td className="py-12 px-16 text-sm text-secondary-light">{l.order_index ?? "—"}</td>
                                                                            <td className="py-12 px-16 text-sm">
                                                                                <div className="fw-semibold text-dark">{l.name ?? "—"}</div>
                                                                                {l.name_en ? <div className="text-secondary-light text-xs">{l.name_en}</div> : null}
                                                                            </td>
                                                                            <td className="py-12 px-16 align-middle">
                                                                                <span
                                                                                    className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${active ? "status-active" : "status-inactive"
                                                                                        }`}
                                                                                >
                                                                                    {active ? "Active" : "Disabled"}
                                                                                </span>
                                                                            </td>
                                                                            <td className="py-12 px-16 text-sm text-secondary-light">
                                                                                <strong className="text-dark">{l.active_stages_count}</strong>/{l.stages_count}
                                                                            </td>
                                                                            <td className="py-12 px-16 text-center align-middle">
                                                                                <Link
                                                                                    to={`/admin/levels/${l.id}`}
                                                                                    state={{ from: `/admin/worlds/${id}` }}
                                                                                    title="View Level"
                                                                                    className="w-32-px h-32-px radius-8 bg-primary-50 text-primary-600 d-inline-flex align-items-center justify-content-center"
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
                                className="card border radius-12 shadow-lg overflow-hidden bg-base"
                                style={{ width: "min(760px, 96vw)", maxHeight: "90vh" }}
                                onClick={(e) => e.stopPropagation()}
                            >
                                <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center">
                                    <div>
                                        <h6 className="fw-bold text-dark mb-0">Insert Level</h6>
                                        <small className="text-secondary-light text-xs">Create a new level for this world</small>
                                    </div>

                                    <button className="btn-close shadow-none" type="button" onClick={closeInsertLevel} title="Close" />
                                </div>

                                <div className="card-body p-24 bg-base" style={{ overflow: "auto" }}>
                                    {insertLevelError && <div className="alert alert-danger mb-16 radius-8">{insertLevelError}</div>}

                                    <div className="row g-3">
                                        <div className="col-12">
                                            <label className="form-label text-sm fw-semibold text-dark">Level Name (KH) *</label>
                                            <input
                                                className="form-control radius-8"
                                                value={newLevelName}
                                                onChange={(e) => setNewLevelName(e.target.value)}
                                                placeholder="e.g. ក - ង"
                                            />
                                        </div>

                                        <div className="col-12">
                                            <label className="form-label text-sm fw-semibold text-dark">Level Name (EN)</label>
                                            <input
                                                className="form-control radius-8"
                                                value={newLevelNameEn}
                                                onChange={(e) => setNewLevelNameEn(e.target.value)}
                                                placeholder="e.g. Ka - Ngo"
                                            />
                                        </div>

                                        <div className="col-12">
                                            <label className="form-label text-sm fw-semibold text-dark">Description (KH)</label>
                                            <textarea
                                                className="form-control radius-8"
                                                rows={3}
                                                value={newLevelDescription}
                                                onChange={(e) => setNewLevelDescription(e.target.value)}
                                                placeholder="Optional"
                                            />
                                        </div>

                                        <div className="col-12">
                                            <label className="form-label text-sm fw-semibold text-dark">Description (EN)</label>
                                            <textarea
                                                className="form-control radius-8"
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
                                                />
                                                <label className="form-check-label text-sm fw-semibold text-dark mb-0" htmlFor="newLevelActive">
                                                    Active
                                                </label>
                                            </div>

                                            <small className="text-secondary-light d-block mt-4 text-xs">
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
                                                />
                                                <label className="form-check-label text-sm fw-semibold text-dark mb-0" htmlFor="newLevelUnlockedByDefault">
                                                    Unlocked by default
                                                </label>
                                            </div>

                                            <small className="text-secondary-light d-block mt-4 text-xs">
                                                Students start with this level unlocked.
                                            </small>
                                        </div>

                                    </div>
                                </div>

                                <div className="card-footer border-top py-16 px-24 bg-base d-flex justify-content-end gap-12">
                                    <button type="button" className="btn btn-outline-secondary btn-sm radius-8" onClick={closeInsertLevel} disabled={insertLevelLoading}>
                                        Cancel
                                    </button>

                                    <button
                                        type="button"
                                        className="btn btn-primary btn-sm radius-8"
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
            </div>
        </MasterLayout>
    );
};

const InfoItem = ({ label, value, colClass = "col-12 col-md-6 col-lg-4" }) => {
    const v = value === null || value === undefined || value === "" ? "—" : value;
    return (
        <div className={colClass}>
            <div className="p-12 border radius-8 h-100 bg-base">
                <div className="text-secondary-light text-xs fw-semibold mb-6">{label}</div>
                <div className="fw-semibold text-dark text-sm" style={{ wordBreak: "break-word" }}>
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
            <div className="text-secondary-light text-xs">{label}</div>
            <div className="fw-semibold text-dark text-xs">{v}</div>
        </div>
    );
};

export default WorldView;
