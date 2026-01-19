import React, { useEffect, useMemo, useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const WorldEdit = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission } = useAuth();

    const canEdit = hasPermission("worlds.update");
    const canToggle = hasPermission("worlds.enable_disable");
    const canView = hasPermission("worlds.view") || canEdit;

    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    const [message, setMessage] = useState("");
    const [error, setError] = useState("");

    const [world, setWorld] = useState(null);

    const [form, setForm] = useState({
        name: "",
        description: "",
        theme_color: "",
        is_unlocked_by_default: false,
    });

    const active = useMemo(() => {
        const v = world?.is_active;
        return v === true || String(v ?? "0") === "1";
    }, [world]);

    const fetchWorld = async () => {
        setLoading(true);
        setError("");
        setMessage("");
        try {
            const res = await API.get(`/admin/worlds/${id}`);
            const payload = res.data?.data ?? res.data;
            const w = payload?.world ?? null;

            setWorld(w);

            setForm({
                name: w?.name ?? "",
                description: w?.description ?? "",
                theme_color: w?.theme_color ?? "",
                is_unlocked_by_default:
                    w?.is_unlocked_by_default === true ||
                    String(w?.is_unlocked_by_default ?? "0") === "1",
            });
        } catch (err) {
            console.error("Fetch world failed:", err);
            setError(err?.response?.data?.message || "Failed to load world.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (!canView) return;
        fetchWorld();
    }, [id, canView]);

    const onChange = (key) => (e) => {
        const val =
            e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
        setForm((p) => ({ ...p, [key]: val }));
    };

    const validateHexColor = (v) => {
        if (!v) return true;
        const s = String(v).trim();
        return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(s);
    };

    const save = async (e) => {
        e.preventDefault();
        if (!canEdit) return;

        setSaving(true);
        setError("");
        setMessage("");

        if (!form.name?.trim()) {
            setSaving(false);
            setError("Name is required.");
            return;
        }

        if (form.theme_color && !validateHexColor(form.theme_color)) {
            setSaving(false);
            setError("Theme color must be a valid hex like #4CAF50.");
            return;
        }

        try {
            await API.put(`/admin/worlds/${id}`, {
                name: form.name.trim(),
                description: form.description?.trim() || null,
                theme_color: form.theme_color?.trim() || null,
                is_unlocked_by_default: !!form.is_unlocked_by_default,
            });

            if (window.history.length > 1) {
                navigate(-1);
            } else {
                navigate(`/admin/worlds/${id}`);
            }
            return;
        } catch (err) {
            console.error("Update failed:", err);
            setError(err?.response?.data?.message || "Update failed");
        } finally {
            setSaving(false);
        }
    };

    const toggleWorld = async () => {
        if (!canToggle) return;
        setError("");
        setMessage("");
        try {
            await API.put(`/admin/worlds/${id}/toggle`);
            setMessage("World status updated.");
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
                    You don’t have permission to view this page.
                </div>
            </MasterLayout>
        );
    }

    if (!canEdit) {
        return (
            <MasterLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to edit worlds.
                </div>
            </MasterLayout>
        );
    }

    function prettyDateTime(d) {
        if (!d) return "—";
        const dt = new Date(d);
        if (Number.isNaN(dt.getTime())) return String(d);

        return dt.toLocaleString();
    }


    return (
        <MasterLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">Edit World</h5>
                        <small className="text-muted">ID: {id}</small>
                    </div>

                    <div className="d-flex gap-2 flex-wrap">
                        <Link
                            onClick={() => (window.history.length > 1 ? navigate(-1) : navigate("/admin/worlds"))}
                            className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
                        >
                            <Icon icon="mdi:arrow-left" className="me-6" />
                            Back
                        </Link>

                        {canToggle && (
                            <button
                                type="button"
                                onClick={toggleWorld}
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
                            <div className="mt-12 text-muted">Loading world...</div>
                        </div>
                    ) : !world ? (
                        <div className="text-center py-40 text-muted">World not found.</div>
                    ) : (
                        <form id="worldEditForm" onSubmit={save}>
                            <div className="row g-3">
                                {/* Left preview */}
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
                                                title={form.theme_color || "—"}
                                            >
                                                <Icon icon="mdi:map" width={54} />
                                            </div>

                                            <h6 className="mt-3 mb-3">
                                                {form.name?.trim() || "—"}
                                            </h6>

                                            <div className="d-flex justify-content-center gap-8 flex-wrap">
                                                <span
                                                    className={`badge ${active ? "bg-success" : "bg-secondary"
                                                        }`}
                                                >
                                                    {active ? "Active" : "Disabled"}
                                                </span>

                                                <span
                                                    className={`badge ${form.is_unlocked_by_default
                                                        ? "bg-primary"
                                                        : "bg-light text-dark"
                                                        }`}
                                                >
                                                    {form.is_unlocked_by_default
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
                                            <MiniRow label="Created At" value={prettyDateTime(world?.created_at)} />
                                            <MiniRow label="Updated At" value={prettyDateTime(world?.updated_at)} />
                                        </div>
                                    </div>
                                </div>

                                {/* Right form */}
                                <div className="col-12 col-md-8 col-lg-9">
                                    <div className="card border mb-0">
                                        <div className="card-header">
                                            <h6 className="mb-0">World Information</h6>
                                        </div>

                                        <div className="card-body">
                                            <div className="row g-3">
                                                <Field label="Name *" colClass="col-12 col-lg-6">
                                                    <input
                                                        className="form-control"
                                                        value={form.name}
                                                        onChange={onChange("name")}
                                                        required
                                                        maxLength={255}
                                                    />
                                                </Field>

                                                <Field label="Theme Color" colClass="col-12 col-lg-6">
                                                    <input
                                                        className="form-control"
                                                        placeholder="#4CAF50"
                                                        value={form.theme_color}
                                                        onChange={onChange("theme_color")}
                                                    />
                                                    <div className="small text-muted mt-6">
                                                        Use hex color like <code>#4CAF50</code>
                                                    </div>
                                                </Field>

                                                <Field label="Description" colClass="col-12">
                                                    <textarea
                                                        className="form-control"
                                                        rows={4}
                                                        value={form.description}
                                                        onChange={onChange("description")}
                                                    />
                                                </Field>

                                                <div className="col-12">
                                                    <div className="form-check">
                                                        <input
                                                            className="form-check-input"
                                                            type="checkbox"
                                                            id="unlockedByDefault"
                                                            checked={!!form.is_unlocked_by_default}
                                                            onChange={onChange("is_unlocked_by_default")}
                                                        />
                                                        <label
                                                            className="form-check-label"
                                                            htmlFor="unlockedByDefault"
                                                        >
                                                            Unlocked by default
                                                        </label>
                                                    </div>
                                                    <div className="small text-muted mt-6">
                                                        Students will start with this world unlocked (in
                                                        addition to the first active world).
                                                    </div>
                                                </div>
                                            </div>
                                        </div>


                                    </div>
                                </div>
                                <div className="d-flex justify-content-end gap-2">
                                    <button
                                        type="button"
                                        className="btn btn-secondary"
                                        onClick={() => navigate("/admin/worlds")}
                                        disabled={saving}
                                    >
                                        Cancel
                                    </button>

                                    <button
                                        type="submit"
                                        className="btn btn-primary"
                                        disabled={saving}
                                    >
                                        {saving ? "Saving..." : "Save"}
                                    </button>
                                </div>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </MasterLayout>
    );
};

const Field = ({ label, children, colClass = "col-12 col-md-6" }) => (
    <div className={colClass}>
        <div className="p-12 border radius-8 h-100">
            <div className="text-muted small mb-6">{label}</div>
            {children}
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

export default WorldEdit;
