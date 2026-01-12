import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

function calcAgeFromDob(dob) {
    if (!dob) return null;
    const d = new Date(dob);
    if (Number.isNaN(d.getTime())) return null;

    const now = new Date();
    let age = now.getFullYear() - d.getFullYear();
    const m = now.getMonth() - d.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < d.getDate())) age--;
    return age >= 0 ? age : null;
}

function prettyDate(d) {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
}

const formatEnrollmentYear = (v) => {
    if (!v) return "—";

    const s = String(v).trim();
    if (/^\d{4}$/.test(s)) return s;

    const d = new Date(s);
    if (!Number.isNaN(d.getTime())) {
        const y = d.getFullYear();
        if (y === 1970) return "—";
        return String(y);
    }
    return "—";
};

const StudentView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission } = useAuth();

    const [student, setStudent] = useState(null);
    const [loading, setLoading] = useState(true);

    const [message, setMessage] = useState("");
    const [error, setError] = useState("");

    const fullName = (s) =>
        [s?.first_name, s?.last_name].filter(Boolean).join(" ").trim() || "—";

    const isOnline = (s) => {
        const flag = s?.is_online === true || String(s?.is_online) === "1";
        const last = s?.last_seen_at ? new Date(s.last_seen_at) : null;
        const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
        return flag || fresh;
    };

    const fetchStudent = async () => {
        setLoading(true);
        setError("");
        setMessage("");
        try {
            const res = await API.get(`/school/students/${id}`);
            setStudent(res.data?.student ?? null);
        } catch (err) {
            console.error("Fetch student failed:", err);
            setError(err?.response?.data?.message || "Failed to load student.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStudent();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id]);

    const normalized = useMemo(() => {
        if (!student) return null;

        const active =
            student?.is_active === true ||
            String(student?.is_active ?? student?.status ?? "0") === "1";

        const computedAge =
            student?.age ?? calcAgeFromDob(student?.date_of_birth) ?? "—";

        const parentName =
            [student?.parent_first_name, student?.parent_last_name]
                .filter(Boolean)
                .join(" ")
                .trim() || "—";

        return {
            ...student,
            name: fullName(student),
            active,
            online: isOnline(student),
            computedAge,
            parentName,
        };
    }, [student]);

    const avatarUrl = useMemo(() => {
        if (!normalized?.avatar) return null;
        return String(normalized.avatar).startsWith("http")
            ? normalized.avatar
            : `${API_BASE_URL}/${String(normalized.avatar).replace(/^\/+/, "")}`;
    }, [normalized]);

    const deleteStudent = async () => {
        if (!window.confirm("Delete this student?")) return;

        setError("");
        setMessage("");
        try {
            await API.delete(`/school/students/${id}`);
            setMessage("Student deleted successfully");
            navigate("/school/students");
        } catch (err) {
            console.error("Delete failed:", err);
            setError(err?.response?.data?.message || "Delete failed");
        }
    };

    const canView = hasPermission("children.view");
    const canEdit = hasPermission("children.update");
    const canDelete = hasPermission("children.delete");

    if (!canView) {
        return (
            <SchoolLayout>
                <div className="alert alert-danger mb-0">
                    You don’t have permission to view student details.
                </div>
            </SchoolLayout>
        );
    }

    return (
        <SchoolLayout>
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 className="mb-0">Student Details</h5>
                        <small className="text-muted">ID: {id}</small>
                    </div>

                    <div className="d-flex gap-2 flex-wrap">
                        <Link
                            to="/school/students"
                            className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
                        >
                            <Icon icon="mdi:arrow-left" className="me-6" />
                            Back
                        </Link>

                        {canEdit && (
                            <Link
                                to={`/school/students/${id}/edit`}
                                className="d-flex align-items-center btn btn-success radius-3 px-20 py-11"
                            >
                                <Icon icon="lucide:edit" className="me-6" />
                                Edit
                            </Link>
                        )}

                        {canDelete && (
                            <button
                                type="button"
                                onClick={deleteStudent}
                                className="btn btn-danger radius-3 px-20 py-11"
                            >
                                <Icon icon="mingcute:delete-2-line" className="me-6" />
                                Delete
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
                            <div className="mt-12 text-muted">Loading student...</div>
                        </div>
                    ) : !normalized ? (
                        <div className="text-center py-40 text-muted">Student not found.</div>
                    ) : (
                        <div className="row g-3">
                            {/* Left */}
                            <div className="col-12 col-md-4 col-lg-3">
                                <div className="card border">
                                    <div className="card-body text-center">
                                        {avatarUrl ? (
                                            <img
                                                src={avatarUrl}
                                                alt={normalized.name}
                                                style={{
                                                    width: 120,
                                                    height: 120,
                                                    objectFit: "cover",
                                                    borderRadius: "50%",
                                                }}
                                            />
                                        ) : (
                                            <div
                                                className="d-inline-flex align-items-center justify-content-center bg-light"
                                                style={{
                                                    width: 120,
                                                    height: 120,
                                                    borderRadius: "50%",
                                                }}
                                            >
                                                <Icon icon="mdi:account" width={48} />
                                            </div>
                                        )}

                                        <h6 className="mt-16 mb-4">{normalized.name}</h6>

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
                                            Nickname:{" "}
                                            <span className="text-dark">{normalized.nickname || "—"}</span>
                                        </div>
                                    </div>
                                </div>

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

                            {/* Right */}
                            <div className="col-12 col-md-8 col-lg-9">
                                {/* Student Information */}
                                <div className="card border mb-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">Student Information</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem label="First Name" value={normalized.first_name} />
                                            <InfoItem label="Last Name" value={normalized.last_name} />
                                            <InfoItem label="Gender" value={normalized.gender} />
                                            <InfoItem
                                                label="Date of Birth"
                                                value={prettyDate(normalized.date_of_birth)}
                                            />
                                            <InfoItem label="Age" value={normalized.computedAge} />
                                            <InfoItem
                                                label="Enrollment Year"
                                                value={formatEnrollmentYear(normalized.enrollment_year)}
                                            />

                                            <InfoItem
                                                label="Address"
                                                value={normalized.address}
                                                colClass="col-12"
                                            />
                                        </div>
                                    </div>
                                </div>

                                {/* ✅ Combined Contact + Parent */}
                                <div className="card border mb-3">
                                    <div className="card-header">
                                        <h6 className="mb-0">Contact & Parent</h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <InfoItem label="Phone" value={normalized.phone} />
                                            <InfoItem label="Email" value={normalized.email} />
                                            <InfoItem label="Parent Name" value={normalized.parentName}
                                                colClass="col-12" />
                                        </div>
                                    </div>
                                </div>

                                {/* System */}
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
        </SchoolLayout>
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

export default StudentView;
