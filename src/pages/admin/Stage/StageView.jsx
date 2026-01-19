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

const StageView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const { hasPermission } = useAuth();

    const canView = hasPermission("stages.view") || hasPermission("stages.update");
    const canEdit = hasPermission("stages.update");
    const canToggle = hasPermission("stages.enable_disable");

    // stage-exercises permissions (adjust names if yours differ)
    const canAttachExercise = hasPermission("stage_exercises.create") || hasPermission("stages.update");
    const canViewExercises = hasPermission("exercises.view") || hasPermission("stages.view");

    const from = location.state?.from || "/admin/stages";

    const [loading, setLoading] = useState(true);
    const [stage, setStage] = useState(null);

    const [message, setMessage] = useState("");
    const [error, setError] = useState("");

    // ✅ stage exercises separate fetch
    const [loadingSE, setLoadingSE] = useState(false);
    const [stageExercises, setStageExercises] = useState([]);

    const [attachOpen, setAttachOpen] = useState(false);
    const [attachLoading, setAttachLoading] = useState(false);
    const [attachError, setAttachError] = useState("");
    const [attachRepeat, setAttachRepeat] = useState(3);

    const [exerciseQuery, setExerciseQuery] = useState("");
    const [characterType, setCharacterType] = useState("");
    const [exerciseRows, setExerciseRows] = useState([]);

    const fetchStage = async () => {
        setLoading(true);
        setError("");
        setMessage("");
        try {
            const res = await API.get(`/admin/stages/${id}`);
            const payload = res.data?.data ?? res.data;
            const s = payload?.stage ?? payload ?? null;
            setStage(s);
        } catch (err) {
            console.error("Fetch stage failed:", err);
            setError(err?.response?.data?.message || "Failed to load stage.");
        } finally {
            setLoading(false);
        }
    };

    const fetchStageExercises = async () => {
        setLoadingSE(true);
        try {
            const res = await API.get(`/admin/stages/${id}/exercises`, {
                params: { include_inactive: true },
            });
            const payload = res.data?.data ?? res.data;

            const rows = Array.isArray(payload?.stage_exercises) ? payload.stage_exercises : [];
            setStageExercises(rows);
        } catch (err) {
            console.error("Fetch stage exercises failed:", err);
            // keep stage view usable even if this fails
        } finally {
            setLoadingSE(false);
        }
    };

    useEffect(() => {
        if (!canView) return;
        fetchStage();
        fetchStageExercises();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id, canView]);

    const active = useMemo(() => normalizeBool(stage?.is_active), [stage]);

    const prettyDateTime = (d) => {
        if (!d) return "—";
        const dt = new Date(d);
        if (Number.isNaN(dt.getTime())) return String(d);
        return dt.toLocaleString();
    };

    const toggleStage = async () => {
        if (!canToggle) return;
        setError("");
        setMessage("");
        try {
            await API.put(`/admin/stages/${id}/toggle`);
            setMessage("Stage status updated.");
            await fetchStage();
        } catch (err) {
            console.error("Toggle failed:", err);
            setError(err?.response?.data?.message || "Toggle failed.");
        }
    };



    const goBack = () => {
        if (window.history.length > 1) navigate(-1);
        else navigate(from);
    };

    const openAttach = async () => {
        setAttachError("");
        setAttachRepeat(3);
        setAttachOpen(true);
        await searchExercises({ q: "", character_type: "" });
    };


    const closeAttach = () => {
        setAttachOpen(false);
        setAttachError("");
    };

    const searchExercises = async ({ q, character_type }) => {
        setAttachLoading(true);
        setAttachError("");
        try {
            const res = await API.get("/admin/exercises", {
                params: {
                    per_page: 50,
                    q: q || undefined,
                    character_type: character_type || undefined,
                },
            });

            const payload = res.data?.data ?? res.data;

            const list =
                payload?.exercises?.data && Array.isArray(payload.exercises.data)
                    ? payload.exercises.data
                    : Array.isArray(payload?.exercises)
                        ? payload.exercises
                        : [];

            setExerciseRows(list);
        } catch (err) {
            console.error("Fetch exercises failed:", err);
            setAttachError(err?.response?.data?.message || "Failed to load exercises.");
        } finally {
            setAttachLoading(false);
        }
    };

    const attachExercise = async (exerciseId) => {
        if (!canAttachExercise) return;

        setAttachLoading(true);
        setAttachError("");
        try {
            await API.post(`/admin/stages/${id}/exercises`, {
                exercise_id: exerciseId,
                repeat_count: Math.max(1, Number(attachRepeat || 3)),
                is_active: true,
            });

            setMessage("Exercise attached to stage.");
            closeAttach();

            await fetchStage();
            await fetchStageExercises();
        } catch (err) {
            console.error("Attach failed:", err);
            setAttachError(err?.response?.data?.message || "Failed to attach exercise.");
        } finally {
            setAttachLoading(false);
        }
    };

    const removeStageExercise = async (stageExerciseId) => {
        if (!canAttachExercise) return;

        const ok = window.confirm("Remove this exercise from the stage?");
        if (!ok) return;

        setError("");
        setMessage("");

        try {
            await API.put(`/admin/stage-exercises/${stageExerciseId}`, {
                is_active: false,
            });

            setMessage("Exercise removed from stage.");
            await fetchStage();
            await fetchStageExercises();
        } catch (err) {
            console.error("Remove failed:", err);
            setError(err?.response?.data?.message || "Failed to remove exercise.");
        }
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

    const worldName = stage?.level?.world?.name ?? "—";
    const levelName = stage?.level?.name ?? "—";

    const totalExercises = stage?.exercises_count ?? 0;
    const activeExercises = stage?.active_exercises_count ?? 0;

    return (
        <MasterLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">Stage Details</h5>
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

                        {canEdit && (
                            <Link
                                to={`/admin/stages/${id}/edit`}
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
                                onClick={toggleStage}
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
                            <div className="mt-12 text-muted">Loading stage...</div>
                        </div>
                    ) : !stage ? (
                        <div className="text-center py-40 text-muted">Stage not found.</div>
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
                                            title={stage?.name || "—"}
                                        >
                                            <Icon icon="mdi:layers" width={54} />
                                        </div>

                                        <h6 className="mt-3 mb-2">
                                            <Trunc value={stage?.name ?? "—"} maxWidth={220} />
                                        </h6>

                                        <div className="text-muted small mb-1">
                                            World: <span className="fw-medium">{worldName}</span>
                                        </div>
                                        <div className="text-muted small mb-2">
                                            Level: <span className="fw-medium">{levelName}</span>
                                        </div>

                                        <div className="d-flex justify-content-center gap-8 flex-wrap">
                                            <span className={`badge ${active ? "bg-success" : "bg-secondary"}`}>
                                                {active ? "Active" : "Disabled"}
                                            </span>

                                            <span className="badge bg-light text-dark">
                                                Max Stars: {stage?.max_stars ?? "—"}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="card border mt-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">System</h6>
                                    </div>
                                    <div className="card-body">
                                        <MiniRow label="Order Index" value={stage?.order_index ?? "—"} />
                                        <MiniRow label="Exercises" value={`${activeExercises}/${totalExercises}`} />
                                        <MiniRow label="Created At" value={prettyDateTime(stage?.created_at)} />
                                        <MiniRow label="Updated At" value={prettyDateTime(stage?.updated_at)} />
                                    </div>
                                </div>
                            </div>

                            {/* Right */}
                            <div className="col-12 col-md-8 col-lg-9">
                                <div className="card border mb-0">
                                    <div className="card-header">
                                        <h6 className="mb-0">Stage Information</h6>
                                    </div>

                                    <div className="card-body">
                                        <div className="row g-3">
                                            <Info label="Name" value={stage?.name} />
                                            <Info label="World" value={worldName} />
                                            <Info label="Level" value={levelName} />
                                            <Info label="Max Stars" value={stage?.max_stars ?? "—"} />
                                            <Info
                                                label="Instruction"
                                                value={stage?.instruction || "—"}
                                                colClass="col-12"
                                            />
                                            <Info
                                                label="Description"
                                                value={stage?.description || "—"}
                                                colClass="col-12"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="card border mt-3">
                                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                                        <div>
                                            <h6 className="mb-0">Exercises</h6>
                                            <small className="text-muted">
                                                {stage?.active_exercises_count ?? 0}/{stage?.exercises_count ?? 0} active
                                            </small>
                                        </div>

                                        {canAttachExercise && (
                                            <button
                                                type="button"
                                                className="btn btn-primary d-flex align-items-center"
                                                onClick={openAttach}
                                            >
                                                <Icon icon="mdi:plus" className="me-6" />
                                                Insert Exercise
                                            </button>
                                        )}
                                    </div>

                                    <div className="card-body">
                                        {loadingSE ? (
                                            <div className="text-center py-24 text-muted">
                                                <div className="spinner-border" role="status" />
                                                <div className="mt-10">Loading exercises...</div>
                                            </div>
                                        ) : stageExercises.length > 0 ? (
                                            <div className="table-responsive">
                                                <table className="table bordered-table mb-0">
                                                    <thead>
                                                        <tr>
                                                            <th style={{ width: 70 }}>#</th>
                                                            <th style={{ width: 90 }}>Order</th>
                                                            <th style={{ width: 120 }}>Exercise ID</th>
                                                            <th style={{ width: 200 }}>Character</th>
                                                            <th>Prompt</th>
                                                            <th style={{ width: 120 }} className="text-center">
                                                                Repeat
                                                            </th>
                                                            <th style={{ width: 140 }} className="text-center">
                                                                Status
                                                            </th>
                                                            {canAttachExercise && (
                                                                <th style={{ width: 90 }} className="text-center">
                                                                    Action
                                                                </th>
                                                            )}

                                                        </tr>
                                                    </thead>

                                                    <tbody>
                                                        {stageExercises
                                                            .slice()
                                                            .sort((a, b) => (a?.order_index ?? 0) - (b?.order_index ?? 0))
                                                            .map((se, idx) => {
                                                                const seActive =
                                                                    se?.is_active === true || String(se?.is_active ?? "0") === "1";
                                                                const ex = se?.exercise ?? {};

                                                                return (
                                                                    <tr key={se.id} className={!seActive ? "table-light" : ""}>
                                                                        <td>{idx + 1}</td>
                                                                        <td>{se?.order_index ?? "—"}</td>
                                                                        <td>{se?.exercise_id ?? ex?.id ?? "—"}</td>

                                                                        <td>
                                                                            <div className="fw-semibold">{ex?.character ?? "—"}</div>
                                                                            <div className="text-muted small">
                                                                                {ex?.character_type ?? "—"}
                                                                            </div>
                                                                        </td>

                                                                        <td>
                                                                            <Trunc value={ex?.prompt ?? "—"} maxWidth={420} />
                                                                            {ex?.instruction ? (
                                                                                <div className="text-muted small mt-1">
                                                                                    <Trunc value={ex.instruction} maxWidth={520} />
                                                                                </div>
                                                                            ) : null}
                                                                        </td>

                                                                        <td className="text-center">{se?.repeat_count ?? "—"}</td>

                                                                        <td className="text-center align-middle">
                                                                            <span
                                                                                className={`px-24 py-4 rounded-pill fw-medium text-sm ${seActive
                                                                                    ? "bg-success-focus text-success-main"
                                                                                    : "bg-warning-focus text-warning-main"
                                                                                    }`}
                                                                            >
                                                                                {seActive ? "Active" : "Disabled"}
                                                                            </span>
                                                                        </td>

                                                                        {canAttachExercise && (
                                                                            <td className="text-center align-middle">
                                                                                <button
                                                                                    type="button"
                                                                                    onClick={() => removeStageExercise(se.id)}
                                                                                    className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                                                    title="Remove"
                                                                                    disabled={attachLoading}
                                                                                >
                                                                                    <Icon icon="mdi:trash-can-outline" />
                                                                                </button>
                                                                            </td>
                                                                        )}

                                                                    </tr>
                                                                );
                                                            })}
                                                    </tbody>
                                                </table>
                                            </div>
                                        ) : (
                                            <div className="text-center text-muted py-24">
                                                No exercises attached to this stage.
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* ✅ Attach Exercise Modal */}
            {attachOpen && (
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
                    onClick={closeAttach}
                    role="dialog"
                    aria-modal="true"
                >
                    <div
                        className="card"
                        style={{ width: "min(980px, 96vw)", maxHeight: "90vh", overflow: "hidden" }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <h6 className="mb-0">Insert Exercise</h6>
                                <small className="text-muted">Select an exercise from the global bank</small>
                            </div>

                            <button className="btn btn-light" type="button" onClick={closeAttach} title="Close">
                                <Icon icon="radix-icons:cross-2" />
                            </button>
                        </div>

                        <div className="card-body" style={{ overflow: "auto" }}>
                            {attachError && <div className="alert alert-danger">{attachError}</div>}
                            <div className="row g-2 align-items-end mb-3">
                                <div className="col-12 col-md-4">
                                    <label className="form-label">Repeat Count</label>
                                    <input
                                        type="number"
                                        min={1}
                                        className="form-control"
                                        value={attachRepeat}
                                        onChange={(e) => setAttachRepeat(e.target.value)}
                                    />
                                    <small className="text-muted">Used when inserting exercises.</small>
                                </div>
                            </div>


                            <div className="row g-2 align-items-end">
                                <div className="col-12 col-md-6">
                                    <label className="form-label">Search</label>
                                    <input
                                        className="form-control"
                                        placeholder="Search prompt / question / instruction / character..."
                                        value={exerciseQuery}
                                        onChange={(e) => setExerciseQuery(e.target.value)}
                                    />
                                </div>

                                <div className="col-12 col-md-4">
                                    <label className="form-label">Character Type</label>
                                    <select
                                        className="form-control"
                                        value={characterType}
                                        onChange={(e) => setCharacterType(e.target.value)}
                                    >
                                        <option value="">All</option>
                                        <option value="digits">digits</option>
                                        <option value="consonants">consonants</option>
                                        <option value="independent_vowels">independent_vowels</option>
                                        <option value="dependent_vowels">dependent_vowels</option>
                                    </select>
                                </div>

                                <div className="col-12 col-md-2">
                                    <button
                                        type="button"
                                        className="btn btn-primary w-100"
                                        onClick={() => searchExercises({ q: exerciseQuery, character_type: characterType })}
                                        disabled={attachLoading}
                                    >
                                        {attachLoading ? "..." : "Search"}
                                    </button>
                                </div>
                            </div>

                            <div className="mt-3">
                                {attachLoading ? (
                                    <div className="text-center py-24 text-muted">
                                        <div className="spinner-border" role="status" />
                                        <div className="mt-10">Loading exercises...</div>
                                    </div>
                                ) : exerciseRows.length === 0 ? (
                                    <div className="text-center text-muted py-24">No exercises found.</div>
                                ) : (
                                    <div className="table-responsive">
                                        <table className="table bordered-table mb-0">
                                            <thead>
                                                <tr>
                                                    <th style={{ width: 110 }}>ID</th>
                                                    <th style={{ width: 180 }}>Character</th>
                                                    <th>Prompt / Question</th>
                                                    <th style={{ width: 140 }} className="text-center">
                                                        Action
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {exerciseRows.map((ex) => (
                                                    <tr key={ex.id}>
                                                        <td>{ex.id}</td>
                                                        <td>
                                                            <div className="fw-semibold">{ex.character ?? "—"}</div>
                                                            <div className="text-muted small">{ex.character_type ?? "—"}</div>
                                                        </td>
                                                        <td>
                                                            <div className="fw-medium">
                                                                <Trunc value={ex.prompt ?? ex.question ?? "—"} maxWidth={520} />
                                                            </div>
                                                            {ex.instruction ? (
                                                                <div className="text-muted small mt-1">
                                                                    <Trunc value={ex.instruction} maxWidth={640} />
                                                                </div>
                                                            ) : null}
                                                        </td>
                                                        <td className="text-center">
                                                            <button
                                                                type="button"
                                                                onClick={() => attachExercise(ex.id)}
                                                                disabled={attachLoading}
                                                                className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                                title="Insert into this stage"
                                                            >
                                                                <Icon icon="mdi:plus" />
                                                            </button>
                                                        </td>

                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="card-footer d-flex justify-content-end">
                            <button type="button" className="btn btn-secondary" onClick={closeAttach}>
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}
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

export default StageView;
