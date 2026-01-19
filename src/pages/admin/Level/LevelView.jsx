import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Trunc = ({ value, maxWidth = 360 }) => {
    const v = value ?? "—";
    return (
        <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
            {v}
        </div>
    );
};

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const LevelView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const { hasPermission } = useAuth();

    const canView = hasPermission("levels.view") || hasPermission("levels.update");
    const canEdit = hasPermission("levels.update");
    const canToggle = hasPermission("levels.enable_disable");

    const from = location.state?.from || "/admin/levels";

    const [loading, setLoading] = useState(true);
    const [level, setLevel] = useState(null);

    const [message, setMessage] = useState("");
    const [error, setError] = useState("");

    const fetchLevel = async () => {
        setLoading(true);
        setError("");
        setMessage("");
        try {
            const res = await API.get(`/admin/levels/${id}`);
            const payload = res.data?.data ?? res.data;

            // backend might return { level: {...} } or { data: { level: {...} } }
            const lv = payload?.level ?? payload ?? null;
            setLevel(lv);
        } catch (err) {
            console.error("Fetch level failed:", err);
            setError(err?.response?.data?.message || "Failed to load level.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (!canView) return;
        fetchLevel();
    }, [id, canView]);

    const active = useMemo(() => normalizeBool(level?.is_active), [level]);

    const stages = Array.isArray(level?.stages) ? level.stages : [];

    const prettyDateTime = (d) => {
        if (!d) return "—";
        const dt = new Date(d);
        if (Number.isNaN(dt.getTime())) return String(d);
        return dt.toLocaleString();
    };

    const toggleLevel = async () => {
        if (!canToggle) return;
        setError("");
        setMessage("");
        try {
            await API.put(`/admin/levels/${id}/toggle`);
            setMessage("Level status updated.");
            await fetchLevel();
        } catch (err) {
            console.error("Toggle failed:", err);
            setError(err?.response?.data?.message || "Toggle failed.");
        }
    };

    const goBack = () => {
        // if you arrived here via navigation, go back; else go to default list
        if (window.history.length > 1) navigate(-1);
        else navigate(from);
    };

    if (!canView) {
        return (
            <MasterLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to view this page.
                </div>
            </MasterLayout>
        );
    }

    return (
        <MasterLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">Level Details</h5>
                        <small className="text-muted">ID: {id}</small>
                    </div>

                    <div className="d-flex gap-2 flex-wrap">
                        <button
                            type="button"
                            onClick={goBack}
                            className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
                        >
                            <Icon icon="mdi:arrow-left" className="me-6" />
                            Back
                        </button>

                        {/* stages list (filtered) - once you build StageList global */}
                        <Link
                            to={`/admin/stages?level_id=${id}`}
                            className="d-flex align-items-center btn btn-outline-dark radius-3 px-20 py-11"
                            title="View stages under this level"
                        >
                            <Icon icon="mdi:layers" className="me-6" />
                            Stages
                        </Link>

                        {canEdit && (
                            <Link
                                to={`/admin/levels/${id}/edit`}
                                state={{ from }}
                                className="d-flex align-items-center btn btn-primary radius-3 px-20 py-11"
                            >
                                <Icon icon="lucide:edit" className="me-6" />
                                Edit
                            </Link>
                        )}

                        {canToggle && (
                            <button
                                type="button"
                                onClick={toggleLevel}
                                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${active ? "btn-warning" : "btn-primary"
                                    }`}
                                title="Toggle Active"
                            >
                                <Icon icon="mdi:toggle-switch" className="me-6" />
                                {active ? "Disable" : "Enable"}
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
                            <div className="mt-12 text-muted">Loading level...</div>
                        </div>
                    ) : !level ? (
                        <div className="text-center py-40 text-muted">Level not found.</div>
                    ) : (
                        <div className="row g-3">
                            {/* Left: Preview + System */}
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
                                            title={level?.name || "—"}
                                        >
                                            <Icon icon="mdi:stairs" width={54} />
                                        </div>

                                        <h6 className="mt-3 mb-2">
                                            <Trunc value={level?.name ?? "—"} maxWidth={220} />
                                        </h6>

                                        <div className="text-muted small mb-2">
                                            World:{" "}
                                            <span className="fw-medium">
                                                {level?.world?.name ?? level?.world_name ?? "—"}
                                            </span>
                                        </div>

                                        <div className="d-flex justify-content-center gap-8 flex-wrap">
                                            <span
                                                className={`badge ${active ? "bg-success" : "bg-secondary"
                                                    }`}
                                            >
                                                {active ? "Active" : "Disabled"}
                                            </span>

                                            <span
                                                className={`badge ${normalizeBool(level?.is_unlocked_by_default)
                                                        ? "bg-primary"
                                                        : "bg-light text-dark"
                                                    }`}
                                            >
                                                {normalizeBool(level?.is_unlocked_by_default)
                                                    ? "Default Unlock"
                                                    : "Not Default"}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="card border mt-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">System</h6>
                                    </div>
                                    <div className="card-body">
                                        <MiniRow
                                            label="Order Index"
                                            value={level?.order_index ?? "—"}
                                        />
                                        <MiniRow
                                            label="Stages"
                                            value={
                                                level?.active_stages_count !== undefined &&
                                                    level?.stages_count !== undefined
                                                    ? `${level.active_stages_count}/${level.stages_count}`
                                                    : "—"
                                            }
                                        />
                                        <MiniRow
                                            label="Created At"
                                            value={prettyDateTime(level?.created_at)}
                                        />
                                        <MiniRow
                                            label="Updated At"
                                            value={prettyDateTime(level?.updated_at)}
                                        />
                                    </div>
                                </div>
                            </div>

                            {/* Right: Details */}
                            <div className="col-12 col-md-8 col-lg-9">
                                <div className="card border mb-0">
                                    <div className="card-header">
                                        <h6 className="mb-0">Level Information</h6>
                                    </div>

                                    <div className="card-body">
                                        <div className="row g-3">
                                            <Info label="Name" value={level?.name} />
                                            <Info label="World" value={level?.world?.name ?? "—"} />
                                            <Info
                                                label="Description"
                                                value={level?.description || "—"}
                                                colClass="col-12"
                                            />
                                            <Info
                                                label="Background Image"
                                                value={level?.background_image || "—"}
                                                colClass="col-12"
                                            />

                                            {level?.background_image ? (
                                                <div className="col-12">
                                                    <div className="border radius-8 p-12">
                                                        <div className="text-muted small mb-8">
                                                            Background Preview
                                                        </div>
                                                        <img
                                                            src={level.background_image}
                                                            alt="Background"
                                                            style={{
                                                                width: "100%",
                                                                maxHeight: 260,
                                                                objectFit: "cover",
                                                                borderRadius: 8,
                                                            }}
                                                            onError={(e) => {
                                                                // hide broken images
                                                                e.currentTarget.style.display = "none";
                                                            }}
                                                        />
                                                    </div>
                                                </div>
                                            ) : null}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Stages table */}
                            <div className="card border mt-3">
                                <div className="card-header d-flex justify-content-between align-items-center">
                                    <h6 className="mb-0">Stages</h6>
                                    <small className="text-muted">{stages.length} total</small>
                                </div>

                                <div className="card-body">
                                    {stages.length === 0 ? (
                                        <div className="text-center text-muted py-24">No stages found.</div>
                                    ) : (
                                        <div className="table-responsive">
                                            <table className="table bordered-table mb-0">
                                                <thead>
                                                    <tr>
                                                        <th style={{ width: 70 }}>#</th>
                                                        <th style={{ width: 90 }}>Order</th>
                                                        <th>Name</th>
                                                        <th>Description</th>
                                                        <th style={{ width: 140 }} className="text-center">
                                                            Status
                                                        </th>
                                                        <th style={{ width: 120 }} className="text-center">
                                                            Max Stars
                                                        </th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {stages
                                                        .slice()
                                                        .sort((a, b) => (a?.order_index ?? 0) - (b?.order_index ?? 0))
                                                        .map((s, idx) => {
                                                            const sActive =
                                                                s?.is_active === true || String(s?.is_active ?? "0") === "1";

                                                            return (
                                                                <tr key={s.id} className={!sActive ? "table-light" : ""}>
                                                                    <td>{idx + 1}</td>
                                                                    <td>{s?.order_index ?? "—"}</td>
                                                                    <td>
                                                                        <Trunc value={s?.name ?? "—"} maxWidth={340} />
                                                                    </td>
                                                                    <td>
                                                                        <Trunc value={s?.description ?? "—"} maxWidth={380} />
                                                                    </td>

                                                                    <td className="text-center align-middle">
                                                                        <span
                                                                            className={`px-24 py-4 rounded-pill fw-medium text-sm ${sActive
                                                                                    ? "bg-success-focus text-success-main"
                                                                                    : "bg-warning-focus text-warning-main"
                                                                                }`}
                                                                        >
                                                                            {sActive ? "Active" : "Disabled"}
                                                                        </span>
                                                                    </td>

                                                                    <td className="text-center">{s?.max_stars ?? "—"}</td>
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
                    )}
                </div>
            </div>
        </MasterLayout>
    );
};

const Info = ({ label, value, colClass = "col-12 col-md-6" }) => (
    <div className={colClass}>
        <div className="p-12 border radius-8 h-100">
            <div className="text-muted small mb-6">{label}</div>
            <div className="fw-medium">{value ?? "—"}</div>
        </div>
    </div>
);

const MiniRow = ({ label, value }) => {
    const v = value === null || value === undefined || value === "" ? "—" : value;
    return (
        <div className="d-flex justify-content-between gap-1 py-6 border-bottom">
            <div className="text-muted small">{label}</div>
            <div className="fw-medium">{v}</div>
        </div>
    );
};

export default LevelView;
