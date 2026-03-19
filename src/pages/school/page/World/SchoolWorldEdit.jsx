import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const Required = () => <span className="text-danger ms-1">*</span>;
const boolish = (v) => v === true || String(v ?? "0") === "1";

const SchoolWorldEdit = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission } = useAuth();

    const canEdit = hasPermission("worlds.update");

    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    const [world, setWorld] = useState(null);

    const [form, setForm] = useState({
        name: "",
        description: "",
        is_active: true,
        is_unlocked_by_default: false,
    });

    const [error, setError] = useState("");
    const [message, setMessage] = useState("");

    const normalized = useMemo(() => {
        if (!world) return null;

        const owned_by_school = !!world?.owned_by_school || world?.school_id != null;

        return {
            ...world,
            owned_by_school,
            is_active: boolish(world?.is_active),
            is_unlocked_by_default: boolish(world?.is_unlocked_by_default),
        };
    }, [world]);

    const fetchWorld = async () => {
        setLoading(true);
        setError("");
        setMessage("");

        try {
            const res = await API.get(`/school/worlds/${id}`);
            const payload = res.data?.data ?? res.data;
            const w = payload?.world ?? null;

            setWorld(w);

            setForm({
                name: w?.name ?? "",
                description: w?.description ?? "",
                is_active: boolish(w?.is_active),
                is_unlocked_by_default: boolish(w?.is_unlocked_by_default),
            });
        } catch (err) {
            console.error("Fetch school world failed:", err);
            setError(err?.response?.data?.message || "Failed to load world.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchWorld();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id]);

    const onChange = (key) => (e) => {
        const val =
            e?.target?.type === "checkbox"
                ? e.target.checked
                : e?.target?.value ?? "";
        setForm((p) => ({ ...p, [key]: val }));
    };

    const submit = async (e) => {
        e.preventDefault();
        setError("");
        setMessage("");

        if (!canEdit) {
            setError("You don’t have permission to update worlds.");
            return;
        }

        if (!normalized?.owned_by_school) {
            setError("You can only edit worlds owned by your school.");
            return;
        }

        if (!form.name?.trim()) {
            setError("Name is required.");
            return;
        }

        setSubmitting(true);
        try {
            const payload = {
                name: form.name.trim(),
                description: form.description?.trim() || null,
                is_active: form.is_active ? 1 : 0,
                is_unlocked_by_default: form.is_unlocked_by_default ? 1 : 0,
            };

            await API.put(`/school/worlds/${id}`, payload);

            if (window.history.length > 1) {
                navigate(-1, { replace: true });
            } else {
                navigate("/school/worlds", { replace: true });
            }
        } catch (err) {
            console.error("Update world failed:", err);

            const errors = err?.response?.data?.errors || {};
            setError(
                errors?.name?.[0] ||
                errors?.description?.[0] ||
                errors?.is_active?.[0] ||
                errors?.is_unlocked_by_default?.[0] ||
                err?.response?.data?.message ||
                "Failed to update world."
            );
        } finally {
            setSubmitting(false);
        }
    };

    const previewActive = useMemo(() => !!form.is_active, [form.is_active]);

    if (!canEdit) {
        return (
            <SchoolLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to edit worlds.
                </div>
            </SchoolLayout>
        );
    }

    return (
        <SchoolLayout>
            <div className="col-12">
                <div className="card">
                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <div>
                            <h5 className="card-title mb-0">Edit World</h5>
                            <small className="text-muted">Update world information</small>
                        </div>

                        <div className="d-flex gap-2">
                            <Link onClick={() =>
                                window.history.length > 1
                                    ? navigate(-1)
                                    : navigate("/school/worlds")
                            }
                                className="btn btn-outline-secondary">
                                <Icon icon="mdi:arrow-left" className="me-6" />
                                Back
                            </Link>
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
                        ) : !normalized.owned_by_school ? (
                            <div className="alert alert-warning mb-0">
                                <Icon icon="mdi:information-outline" className="me-2" />
                                This is a global/admin world. Your school can hide/unhide it, but cannot edit it.
                            </div>
                        ) : (
                            <form onSubmit={submit}>
                                <div className="row g-3">
                                    {/* LEFT: Preview */}
                                    <div className="col-12 col-lg-4">
                                        <div className="card border h-100">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:eye-outline" />
                                                <h6 className="mb-0">Preview</h6>
                                            </div>

                                            <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                                                <div
                                                    className="mx-auto d-flex align-items-center justify-content-center border overflow-hidden"
                                                    style={{
                                                        width: 150,
                                                        height: 150,
                                                        borderRadius: 16,
                                                        background: "#f1f5f9",
                                                    }}
                                                >
                                                    <Icon icon="mdi:map" width={72} />
                                                </div>

                                                <h6 className="mt-2 mb-1">{form.name?.trim() || "—"}</h6>

                                                <div className="d-flex justify-content-center gap-8 flex-wrap">
                                                    <span className={`badge ${previewActive ? "bg-success" : "bg-secondary"}`}>
                                                        {previewActive ? "Active" : "Disabled"}
                                                    </span>

                                                    <span
                                                        className={`badge ${form.is_unlocked_by_default ? "bg-primary" : "bg-light text-dark"
                                                            }`}
                                                    >
                                                        {form.is_unlocked_by_default ? "Default Unlock" : "Not Default"}
                                                    </span>

                                                    <span className="badge bg-warning text-dark" title="Worlds created by your school are always premium">
                                                        <Icon icon="mdi:crown" className="me-1" />
                                                        Premium (Always Included)
                                                    </span>
                                                </div>

                                                <div className="mt-10 text-muted small">
                                                    World ID: <span className="text-dark">{id}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* RIGHT: Form */}
                                    <div className="col-12 col-lg-8">
                                        <div className="card border mb-3">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:earth" />
                                                <h6 className="mb-0">World Information</h6>
                                            </div>

                                            <div className="card-body">
                                                <div className="row gy-3">
                                                    <div className="col-12">
                                                        <label className="form-label">
                                                            Name <Required />
                                                        </label>
                                                        <input
                                                            className="form-control"
                                                            value={form.name}
                                                            onChange={onChange("name")}
                                                            required
                                                            maxLength={255}
                                                            placeholder="Enter world name"
                                                        />
                                                    </div>

                                                    <div className="col-12">
                                                        <label className="form-label">Description</label>
                                                        <textarea
                                                            className="form-control"
                                                            rows={3}
                                                            value={form.description}
                                                            onChange={onChange("description")}
                                                            placeholder="Optional description"
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <div className="form-check d-flex align-items-center gap-2">
                                                            <input
                                                                className="form-check-input m-0"
                                                                type="checkbox"
                                                                id="isActive"
                                                                checked={!!form.is_active}
                                                                onChange={onChange("is_active")}
                                                                style={{ marginTop: 0 }}
                                                            />
                                                            <label className="form-check-label mb-0" htmlFor="isActive">
                                                                Active
                                                            </label>
                                                        </div>
                                                        <small className="text-muted d-block">
                                                            If unchecked, this world won’t appear to students.
                                                        </small>
                                                    </div>

                                                    <div className="col-md-6">
                                                        <div className="form-check d-flex align-items-center gap-2">
                                                            <input
                                                                className="form-check-input m-0"
                                                                type="checkbox"
                                                                id="unlockedByDefault"
                                                                checked={!!form.is_unlocked_by_default}
                                                                onChange={onChange("is_unlocked_by_default")}
                                                                style={{ marginTop: 0 }}
                                                            />
                                                            <label className="form-check-label mb-0" htmlFor="unlockedByDefault">
                                                                Unlocked by default
                                                            </label>
                                                        </div>
                                                        <small className="text-muted d-block">
                                                            Students start with this world unlocked.
                                                        </small>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Actions */}
                                        <div className="d-flex gap-2 flex-wrap">
                                            <button className="btn btn-primary" type="submit" disabled={submitting}>
                                                <Icon icon="mdi:content-save" className="me-6" />
                                                {submitting ? "Saving..." : "Save Changes"}
                                            </button>

                                            <button
                                                type="button"
                                                className="btn btn-outline-secondary"
                                                onClick={() => navigate(`/school/worlds/${id}`)}
                                                disabled={submitting}
                                            >
                                                Cancel
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            </div>
        </SchoolLayout>
    );
};

export default SchoolWorldEdit;
