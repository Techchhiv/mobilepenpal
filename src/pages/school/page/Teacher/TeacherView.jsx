import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

function prettyDate(d) {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
}

const TeacherView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission } = useAuth();

    const [teacher, setTeacher] = useState(null);
    const [loading, setLoading] = useState(true);

    const [error, setError] = useState("");
    const [message, setMessage] = useState("");

    const [previewSrc, setPreviewSrc] = useState(null);
    const closePreview = () => setPreviewSrc(null);

    useEffect(() => {
        const onKeyDown = (e) => e.key === "Escape" && closePreview();
        if (previewSrc) window.addEventListener("keydown", onKeyDown);
        return () => window.removeEventListener("keydown", onKeyDown);
    }, [previewSrc]);

    const isOnline = (t) => {
        const flag = t?.is_online === true || String(t?.is_online) === "1";
        const last = t?.last_seen_at ? new Date(t.last_seen_at) : null;
        const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
        return flag || fresh;
    };

    const photoUrl = (photo) => {
        if (!photo) return null;
        if (String(photo).startsWith("http")) return photo;
        return `${API_BASE_URL}/${String(photo).replace(/^\/+/, "")}`;
    };

    const fetchTeacher = async () => {
        setLoading(true);
        setError("");
        setMessage("");
        try {
            const res = await API.get(`/school/teachers/${id}`);
            setTeacher(res.data?.teacher ?? res.data ?? null);
        } catch (err) {
            console.error("Fetch teacher failed:", err);
            setError(err?.response?.data?.message || "Failed to load teacher.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTeacher();
    }, [id]);

    const normalized = useMemo(() => {
        if (!teacher) return null;

        const active =
            teacher?.is_active === true ||
            String(teacher?.is_active ?? teacher?.status ?? "0") === "1";

        return {
            ...teacher,
            active,
            online: isOnline(teacher),
        };
    }, [teacher]);

    const avatar = useMemo(() => photoUrl(normalized?.photo), [normalized]);

    const canView = hasPermission("teachers.view");

    const deleteTeacher = async () => {
        if (!window.confirm("Delete this teacher?")) return;

        setError("");
        setMessage("");
        try {
            await API.delete(`/school/teachers/${id}`);
            setMessage("Teacher deleted successfully");
            navigate("/school/teachers");
        } catch (err) {
            console.error("Delete failed:", err);
            setError(err?.response?.data?.message || "Delete failed");
        }
    };

    if (!canView) {
        return (
            <SchoolLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to view teacher details.
                </div>
            </SchoolLayout>
        );
    }

    return (
        <SchoolLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">Teacher Details</h5>
                        <small className="text-muted">ID: {id}</small>
                    </div>

                    <div className="d-flex gap-2 flex-wrap">
                        <Link
                            to="/school/teachers"
                            className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
                        >
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
                            <div className="mt-12 text-muted">Loading teacher...</div>
                        </div>
                    ) : !normalized ? (
                        <div className="text-center py-40 text-muted">Teacher not found.</div>
                    ) : (
                        <div className="row g-3">
                            {/* Left: Photo + status */}
                            <div className="col-12 col-md-4 col-lg-3">
                                <div className="card border">
                                    <div className="card-body text-center">
                                        {avatar ? (
                                            <button
                                                type="button"
                                                className="p-0 border-0 bg-transparent"
                                                onClick={() => setPreviewSrc(avatar)}
                                                style={{ cursor: "zoom-in" }}
                                                title="Click to view"
                                            >
                                                <img
                                                    src={avatar}
                                                    alt={normalized.name}
                                                    style={{
                                                        width: 120,
                                                        height: 120,
                                                        objectFit: "cover",
                                                        borderRadius: "50%",
                                                    }}
                                                />
                                            </button>
                                        ) : (
                                            <div
                                                className="d-inline-flex align-items-center justify-content-center bg-light text-muted"
                                                style={{
                                                    width: 120,
                                                    height: 120,
                                                    borderRadius: "50%",
                                                }}
                                                title="No photo"
                                            >
                                                <Icon icon="mdi:account" width={48} />
                                            </div>
                                        )}

                                        <h6 className="mt-16 mb-4">{normalized.name || "—"}</h6>

                                        <div className="d-flex justify-content-center gap-8 flex-wrap">
                                            <span
                                                className={`badge ${normalized.active ? "bg-success" : "bg-secondary"
                                                    }`}
                                            >
                                                {normalized.active ? "Active" : "Inactive"}
                                            </span>

                                            <span
                                                className={`badge ${normalized.online ? "bg-primary" : "bg-light text-dark"
                                                    }`}
                                                title={
                                                    normalized.last_seen_at
                                                        ? `Last seen: ${normalized.last_seen_at}`
                                                        : ""
                                                }
                                            >
                                                {normalized.online ? "Online" : "Offline"}
                                            </span>
                                        </div>

                                        <div className="mt-10 text-muted">
                                            Teacher ID:{" "}
                                            <span className="text-dark">
                                                {normalized.teacher_id || "—"}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                {/* School-like info */}
                                <div className="card border mt-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">School</h6>
                                    </div>
                                    <div className="card-body">
                                        <MiniRow label="School ID" value={normalized.school_id ?? "—"} />
                                        <MiniRow label="School Key" value={normalized.school_key ?? "—"} />
                                    </div>
                                </div>
                            </div>

                            {/* Right: Details */}
                            <div className="col-12 col-md-8 col-lg-9">
                                <div className="card border mb-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">Teacher Information</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem label="Name" value={normalized.name} />
                                            <InfoItem label="Email" value={normalized.email} />
                                            <InfoItem label="Phone" value={normalized.phone} />
                                            <InfoItem label="Subject" value={normalized.subject} />
                                        </div>
                                    </div>
                                </div>

                                <div className="card border">
                                    <div className="card-header">
                                        <h6 className="mb-0">System</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem label="Created At" value={prettyDate(normalized.created_at)} />
                                            <InfoItem label="Updated At" value={prettyDate(normalized.updated_at)} />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {previewSrc && (
                <div
                    className="position-fixed top-0 start-0 w-100 h-100"
                    style={{
                        background: "rgba(0,0,0,0.75)",
                        zIndex: 1055,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        padding: 16,
                    }}
                    onClick={closePreview}
                    role="dialog"
                    aria-modal="true"
                >
                    <img
                        src={previewSrc}
                        alt="Photo Preview"
                        style={{
                            maxWidth: "95vw",
                            maxHeight: "90vh",
                            borderRadius: 12,
                            cursor: "default",
                        }}
                        onClick={(e) => e.stopPropagation()}
                    />
                </div>
            )}
        </SchoolLayout>
    );
};

const InfoItem = ({ label, value }) => {
    const v = value === null || value === undefined || value === "" ? "—" : value;
    return (
        <div className="col-12 col-md-6 col-lg-4">
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

export default TeacherView;
