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
    return dt.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

const TeacherView = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const { hasPermission, isSchoolAdmin } = useAuth();

    const [teacher, setTeacher] = useState(null);
    const [classrooms, setClassrooms] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [message, setMessage] = useState("");

    const canUpdate = isSchoolAdmin || hasPermission("teachers.update");
    const canDelete = isSchoolAdmin || hasPermission("teachers.delete");

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
            const tData = res.data?.teacher ?? res.data ?? null;
            setTeacher(tData);

            // Fetch teacher classrooms if available
            if (res.data?.classrooms) {
                setClassrooms(res.data.classrooms);
            } else {
                const crRes = await API.get(`/school/classrooms?teacher_id=${id}`);
                const crList = Array.isArray(crRes.data) ? crRes.data : crRes.data?.data || [];
                setClassrooms(crList);
            }
        } catch (err) {
            console.error("Fetch teacher failed:", err);
            setError(err?.response?.data?.message || "Failed to load teacher profile.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTeacher();
    }, [id]);

    const normalized = useMemo(() => {
        if (!teacher) return null;
        const active = teacher?.is_active === true || String(teacher?.is_active ?? teacher?.status ?? "0") === "1";
        return {
            ...teacher,
            active,
            online: isOnline(teacher),
        };
    }, [teacher]);

    const avatar = useMemo(() => photoUrl(normalized?.photo), [normalized]);

    const deleteTeacher = async () => {
        if (!window.confirm(`Are you sure you want to delete teacher "${normalized?.name}"?`)) return;

        setError("");
        setMessage("");
        try {
            await API.delete(`/school/teachers/${id}`);
            navigate("/school/teachers", {
                state: { flash: `Teacher "${normalized?.name}" deleted successfully.` },
                replace: true,
            });
        } catch (err) {
            console.error("Delete failed:", err);
            setError(err?.response?.data?.message || "Failed to delete teacher.");
        }
    };

    return (
        <SchoolLayout>
            <div className="d-flex flex-column gap-4">
                {/* Header Card */}
                <div className="card border-0 shadow-sm radius-12 p-3 bg-white">
                    <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
                        <div className="d-flex align-items-center gap-3">
                            <button
                                type="button"
                                className="btn btn-sm btn-outline-secondary d-flex align-items-center gap-1 radius-8"
                                onClick={() => navigate(-1)}
                            >
                                <Icon icon="mdi:arrow-left" /> Back
                            </button>
                            <div>
                                <h5 className="mb-0 fw-bold text-dark">Teacher Profile</h5>
                                <small className="text-muted">Instructor overview and assigned classrooms</small>
                            </div>
                        </div>

                        <div className="d-flex gap-2">
                            {canUpdate && (
                                <Link to={`/school/teachers/${id}/edit`} className="btn btn-sm btn-outline-primary d-flex align-items-center gap-1 radius-8">
                                    <Icon icon="mdi:pencil" /> Edit Profile
                                </Link>
                            )}
                            {canDelete && (
                                <button type="button" className="btn btn-sm btn-outline-danger d-flex align-items-center gap-1 radius-8" onClick={deleteTeacher}>
                                    <Icon icon="mdi:trash-can-outline" /> Delete
                                </button>
                            )}
                        </div>
                    </div>
                </div>

                {message && (
                    <div className="alert alert-success alert-dismissible fade show radius-12 mb-0" role="alert">
                        <Icon icon="mdi:check-circle-outline" className="me-2 text-lg" />
                        {message}
                        <button type="button" className="btn-close" onClick={() => setMessage("")} />
                    </div>
                )}

                {error && (
                    <div className="alert alert-danger alert-dismissible fade show radius-12 mb-0" role="alert">
                        <Icon icon="mdi:alert-circle-outline" className="me-2 text-lg" />
                        {error}
                        <button type="button" className="btn-close" onClick={() => setError("")} />
                    </div>
                )}

                {loading ? (
                    <div className="d-flex justify-content-center align-items-center py-5" style={{ minHeight: "300px" }}>
                        <div className="spinner-border text-primary" role="status">
                            <span className="visually-hidden">Loading teacher profile...</span>
                        </div>
                    </div>
                ) : normalized ? (
                    <>
                        {/* Profile Info Card */}
                        <div className="card border-0 shadow-sm radius-12 bg-white p-4">
                            <div className="d-flex align-items-center flex-wrap gap-4">
                                <div className="position-relative w-96-px h-96-px rounded-circle overflow-hidden bg-light border flex-shrink-0 shadow-sm">
                                    {avatar ? (
                                        <img src={avatar} alt={normalized.name} className="w-100 h-100 object-fit-cover" />
                                    ) : (
                                        <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                            <Icon icon="mdi:account" className="text-4xl" />
                                        </div>
                                    )}
                                </div>

                                <div className="flex-grow-1">
                                    <div className="d-flex align-items-center gap-2 flex-wrap mb-1">
                                        <h4 className="mb-0 fw-bold text-dark">{normalized.name}</h4>
                                        <span className={`badge ${normalized.active ? "bg-success-subtle text-success" : "bg-secondary-subtle text-secondary"}`}>
                                            {normalized.active ? "Active Status" : "Inactive Status"}
                                        </span>
                                        <span className={`badge ${normalized.online ? "bg-success" : "bg-secondary text-white"}`}>
                                            {normalized.online ? "Online Now" : "Offline"}
                                        </span>
                                    </div>

                                    <div className="d-flex align-items-center gap-4 flex-wrap text-sm text-muted mt-2">
                                        <div>
                                            <Icon icon="mdi:card-account-details-outline" className="me-1 text-primary" />
                                            ID: <strong className="text-dark font-mono">{normalized.teacher_id || `#${normalized.id}`}</strong>
                                        </div>
                                        <div>
                                            <Icon icon="mdi:email-outline" className="me-1 text-primary" />
                                            Email: <strong className="text-dark">{normalized.email || "—"}</strong>
                                        </div>
                                        <div>
                                            <Icon icon="mdi:phone-outline" className="me-1 text-primary" />
                                            Phone: <strong className="text-dark">{normalized.phone || "—"}</strong>
                                        </div>
                                        <div>
                                            <Icon icon="mdi:book-open-page-variant-outline" className="me-1 text-primary" />
                                            Subject: {normalized.subject ? <span className="badge bg-purple-subtle text-purple border">{normalized.subject}</span> : <strong className="text-dark">—</strong>}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Assigned Classrooms Card */}
                        <div className="card border-0 shadow-sm radius-12 bg-white">
                            <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                                <div className="d-flex align-items-center gap-2">
                                    <Icon icon="mdi:google-classroom" className="text-purple text-xl" />
                                    <h6 className="mb-0 fw-bold">Assigned Classrooms ({classrooms.length})</h6>
                                </div>
                                <Link to="/school/classrooms/create" className="btn btn-sm btn-link text-decoration-none">
                                    + Add Classroom
                                </Link>
                            </div>
                            <div className="card-body p-0">
                                {classrooms.length === 0 ? (
                                    <div className="d-flex flex-column align-items-center justify-content-center py-5 text-muted small text-center">
                                        <Icon icon="mdi:google-classroom" className="text-3xl text-muted mb-2" />
                                        <span>No classrooms assigned to this teacher yet</span>
                                    </div>
                                ) : (
                                    <div className="table-responsive">
                                        <table className="table align-middle mb-0">
                                            <thead className="table-light text-xs text-uppercase text-muted">
                                                <tr>
                                                    <th className="ps-3">Classroom Name</th>
                                                    <th>Join Code</th>
                                                    <th>Enrolled Students</th>
                                                    <th>Schedule Range</th>
                                                    <th>Status</th>
                                                    <th className="pe-3 text-end">Action</th>
                                                </tr>
                                            </thead>
                                            <tbody className="text-sm">
                                                {classrooms.map((c) => (
                                                    <tr key={c.id}>
                                                        <td className="ps-3 fw-semibold text-dark">{c.name}</td>
                                                        <td>
                                                            <span className="badge bg-light text-dark font-mono text-xs border">
                                                                {c.join_code || "—"}
                                                            </span>
                                                        </td>
                                                        <td>
                                                            <span className="badge bg-primary-subtle text-primary">
                                                                {c.students_count ?? c.enrollments_count ?? 0} Students
                                                            </span>
                                                        </td>
                                                        <td className="text-muted text-xs">
                                                            {prettyDate(c.start_date)} &ndash; {prettyDate(c.end_date)}
                                                        </td>
                                                        <td>
                                                            <span className={`badge ${c.is_active ? "bg-success" : "bg-secondary"}`}>
                                                                {c.is_active ? "Active" : "Archived"}
                                                            </span>
                                                        </td>
                                                        <td className="pe-3 text-end">
                                                            <Link to={`/school/classrooms/${c.id}`} className="btn btn-sm btn-outline-primary py-1 px-2 text-xs">
                                                                Manage Classroom
                                                            </Link>
                                                        </td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        </div>
                    </>
                ) : null}
            </div>
        </SchoolLayout>
    );
};

export default TeacherView;
