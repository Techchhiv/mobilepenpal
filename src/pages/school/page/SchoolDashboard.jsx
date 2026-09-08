import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import Chart from "react-apexcharts";

import SchoolLayout from "../masterLayout/SchoolLayout";
import SchoolDashboardHeader from "../../../components/school/SchoolDashboardHeader";
import SchoolSubscriptionReminder from "../../../components/school/SchoolSubscriptionReminder";
import { calculateRemainingDays, formatPlanName, getExpirationLevel } from "../../../utils/subscriptionUtils";
import API from "../../../helper/api";
import API_BASE_URL from "../../../helper/Base_urls";
import { useAuth } from "../../../context/AuthContext";

const avatarUrl = (path) => {
    if (!path) return null;
    if (String(path).startsWith("http")) return path;
    return `${API_BASE_URL}/${String(path).replace(/^\/+/, "")}`;
};

function SchoolDashboard() {
    const { hasPermission, isSchoolAdmin } = useAuth();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [dashboardError, setDashboardError] = useState(null);
    const [copiedCode, setCopiedCode] = useState("");

    // Granular permission checks
    const canManageClassrooms = isSchoolAdmin || hasPermission("classrooms.view") || hasPermission("classroom.view");
    const canCreateClassrooms = isSchoolAdmin || hasPermission("classrooms.create");
    const canManageTeachers = isSchoolAdmin || hasPermission("teachers.view");
    const canCreateTeachers = isSchoolAdmin || hasPermission("teachers.create");
    const canManageStudents = isSchoolAdmin || hasPermission("children.view") || hasPermission("student.view");
    const canCreateStudents = isSchoolAdmin || hasPermission("children.create") || hasPermission("student.create");
    const canManageWorlds = isSchoolAdmin || hasPermission("worlds.view") || hasPermission("world.view");

    useEffect(() => {
        const fetchDashboard = async () => {
            try {
                const res = await API.get("/school/dashboard");
                if (res.data?.success) {
                    setData(res.data.data);
                } else {
                    setDashboardError(res.data?.message || "Failed to load dashboard data");
                }
            } catch (err) {
                console.error("Error fetching school dashboard:", err);
                setDashboardError(
                    err?.response?.data?.message || "Unable to load subscription information. Please try again later."
                );
            } finally {
                setLoading(false);
            }
        };
        fetchDashboard();
    }, []);

    const copyJoinCode = (code) => {
        if (!code) return;
        navigator.clipboard.writeText(code);
        setCopiedCode(code);
        setTimeout(() => setCopiedCode(""), 2000);
    };

    const isTeacher = Boolean(data?.is_teacher_view);
    const sub = data?.subscription;
    const subHas = Boolean(sub?.has_subscription ?? (sub?.plan || sub?.end_date));
    const subDays = sub?.end_date ? calculateRemainingDays(sub.end_date) : (sub?.days_left ?? 0);
    const subLevel = getExpirationLevel(subDays, sub?.is_expired, subHas);

    // Trend chart config
    const trendCategories = (data?.daily_trend || []).map((t) => t.label);
    const trendAttemptsData = (data?.daily_trend || []).map((t) => t.attempts);
    const trendCorrectData = (data?.daily_trend || []).map((t) => t.correct);

    const chartOptions = {
        chart: {
            type: "area",
            height: 280,
            toolbar: { show: false },
            fontFamily: "Inter, sans-serif",
        },
        dataLabels: { enabled: false },
        stroke: { curve: "smooth", width: 2 },
        colors: ["#487fff", "#45b369"],
        xaxis: {
            categories: trendCategories,
            labels: { style: { colors: "#64748b", fontSize: "12px" } },
        },
        yaxis: {
            labels: { style: { colors: "#64748b", fontSize: "12px" } },
        },
        fill: {
            type: "gradient",
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.35,
                opacityTo: 0.05,
                stops: [0, 90, 100],
            },
        },
        tooltip: {
            theme: "light",
            y: {
                formatter: (val) => `${val} attempts`,
            },
        },
        grid: { borderColor: "#f1f5f9" },
    };

    const chartSeries = [
        { name: "Total Attempts", data: trendAttemptsData },
        { name: "Correct Submissions", data: trendCorrectData },
    ];

    const showQuickActions = canCreateClassrooms || canManageClassrooms || canCreateTeachers || canCreateStudents || canManageStudents || canManageWorlds;

    return (
        <SchoolLayout>
            {/* Main Greeting Header */}
            <SchoolDashboardHeader />

            {loading ? (
                isSchoolAdmin ? (
                    <div className="d-flex flex-column gap-4">
                        <SchoolSubscriptionReminder loading={true} />
                        <div className="d-flex justify-content-center align-items-center" style={{ minHeight: "240px" }}>
                            <div className="spinner-border text-primary" role="status">
                                <span className="visually-hidden">Loading dashboard...</span>
                            </div>
                        </div>
                    </div>
                ) : (
                    <div className="d-flex justify-content-center align-items-center" style={{ minHeight: "300px" }}>
                        <div className="spinner-border text-primary" role="status">
                            <span className="visually-hidden">Loading dashboard...</span>
                        </div>
                    </div>
                )
            ) : isTeacher ? (
                /* ==========================================================
                   👨‍🏫 TEACHER DASHBOARD VIEW
                   ========================================================== */
                <div className="d-flex flex-column gap-4">
                    {/* Teacher Quick Action Bar */}
                    {showQuickActions && (
                        <div className="card border-0 shadow-sm p-3 bg-white radius-12">
                            <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
                                <div className="d-flex align-items-center gap-2">
                                    <Icon icon="mdi:lightning-bolt" className="text-warning text-xl" />
                                    <span className="fw-bold text-dark">Quick Actions:</span>
                                </div>
                                <div className="d-flex gap-2 flex-wrap">
                                    {canCreateClassrooms && (
                                        <Link to="/school/classrooms/create" className="btn btn-sm btn-primary d-flex align-items-center gap-1">
                                            <Icon icon="mdi:plus" /> New Classroom
                                        </Link>
                                    )}
                                    {canManageClassrooms && (
                                        <Link to="/school/classrooms" className="btn btn-sm btn-outline-primary d-flex align-items-center gap-1">
                                            <Icon icon="mdi:google-classroom" /> My Classrooms
                                        </Link>
                                    )}
                                    {canManageStudents && (
                                        <Link to="/school/students" className="btn btn-sm btn-outline-success d-flex align-items-center gap-1">
                                            <Icon icon="mdi:account-school" /> View Students
                                        </Link>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Classroom Join Codes Quick Display Banner */}
                    {canManageClassrooms && (
                        <div className="card border-0 shadow-sm p-3 bg-white radius-12">
                            <div className="d-flex align-items-center justify-content-between mb-3">
                                <div className="d-flex align-items-center gap-2">
                                    <Icon icon="mdi:key-wireless" className="text-warning text-xl" />
                                    <h6 className="mb-0 fw-bold">Classroom Join Codes for In-Class Display</h6>
                                </div>
                                <small className="text-muted">Students enter these codes on mobile to join</small>
                            </div>
                            <div className="row g-2">
                                {(data?.classroom_comparison || []).length > 0 ? (
                                    data.classroom_comparison.map((c) => (
                                        <div key={c.id} className="col-12 col-md-4 col-lg-3">
                                            <div className="border radius-8 p-2 bg-light d-flex align-items-center justify-content-between">
                                                <div className="text-truncate me-2">
                                                    <div className="fw-semibold text-dark text-xs text-truncate">{c.name}</div>
                                                    <div className="fw-mono text-primary font-bold text-base tracking-wider">
                                                        {c.join_code || "—"}
                                                    </div>
                                                </div>
                                                <button
                                                    type="button"
                                                    className="btn btn-sm btn-outline-primary p-1"
                                                    title="Copy Join Code"
                                                    onClick={() => copyJoinCode(c.join_code)}
                                                >
                                                    <Icon icon={copiedCode === c.join_code ? "mdi:check" : "mdi:content-copy"} />
                                                </button>
                                            </div>
                                        </div>
                                    ))
                                ) : (
                                    <div className="col-12 text-muted text-sm py-2">
                                        No active classrooms found. {canCreateClassrooms && <Link to="/school/classrooms/create">Create a classroom to generate a join code</Link>}.
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {/* Teacher KPI Stat Cards */}
                    <div className="row row-cols-xxl-4 row-cols-lg-2 row-cols-sm-2 row-cols-1 g-3">
                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">My Students</span>
                                        <div className="w-36-px h-36-px bg-primary-50 text-primary rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="gridicons:multiple-users" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.total_students ?? 0}</h5>
                                    <span className="badge bg-success-subtle text-success text-xs">
                                        {data?.active_students_7d ?? 0} active this week
                                    </span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">My Classrooms</span>
                                        <div className="w-36-px h-36-px bg-purple-50 text-purple rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="mdi:google-classroom" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.active_classrooms ?? 0} / {data?.total_classrooms ?? 0}</h5>
                                    <span className="text-muted text-xs">Active Classes</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Practice Attempts</span>
                                        <div className="w-36-px h-36-px bg-info-50 text-info rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="fluent:target-arrow-24-filled" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.total_exercise_attempts ?? 0}</h5>
                                    <span className="text-muted text-xs">Submissions Received</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Class Avg. Accuracy</span>
                                        <div className="w-36-px h-36-px bg-success-50 text-success rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="mdi:chart-line" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.average_accuracy ?? 0}%</h5>
                                    <span className="text-muted text-xs">Overall Accuracy</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Middle Section: Struggling Students Alert & Trend Chart */}
                    <div className="row g-3">
                        {/* Students Needing Support Alert Box */}
                        <div className="col-12 col-lg-5">
                            <div className="card border-0 shadow-sm radius-12 h-100">
                                <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                                    <div className="d-flex align-items-center gap-2">
                                        <Icon icon="mdi:alert-decagram" className="text-danger text-xl" />
                                        <h6 className="mb-0 fw-bold">Students Needing Support</h6>
                                    </div>
                                    <span className="badge bg-danger-subtle text-danger">Action Needed</span>
                                </div>
                                <div className="card-body p-0 d-flex flex-column justify-content-center">
                                    <div className="list-group list-group-flush w-100">
                                        {(data?.students_needing_attention || []).length > 0 ? (
                                            data.students_needing_attention.map((st) => (
                                                <div key={st.student_id} className="list-group-item px-3 py-2 border-bottom">
                                                    <div className="d-flex justify-content-between align-items-center">
                                                        <div className="d-flex align-items-center gap-2">
                                                            <div className="w-32-px h-32-px rounded-circle overflow-hidden bg-light border">
                                                                {avatarUrl(st.avatar) ? (
                                                                    <img src={avatarUrl(st.avatar)} alt={st.student_name} className="w-100 h-100 object-fit-cover" />
                                                                ) : (
                                                                    <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                                                        <Icon icon="mdi:account" />
                                                                    </div>
                                                                )}
                                                            </div>
                                                            <div>
                                                                <div className="fw-semibold text-dark text-xs">{st.student_name}</div>
                                                                <div className="text-muted text-xs">{st.classroom_name}</div>
                                                            </div>
                                                        </div>
                                                        <div className="text-end">
                                                            <span className="badge bg-warning-subtle text-warning text-xs mb-1 d-block">
                                                                {st.status}: {st.accuracy}%
                                                            </span>
                                                            {st.classroom_id && canManageClassrooms && (
                                                                <Link
                                                                    to={`/school/classrooms/${st.classroom_id}/students/${st.student_id}/progress`}
                                                                    className="btn btn-xs btn-outline-primary py-0 px-2 text-xs"
                                                                >
                                                                    View Progress
                                                                </Link>
                                                            )}
                                                        </div>
                                                    </div>
                                                </div>
                                            ))
                                        ) : (
                                            <div className="d-flex flex-column align-items-center justify-content-center py-5 px-3 text-muted text-sm text-center">
                                                <div className="w-48-px h-48-px rounded-circle bg-success-50 text-success d-flex align-items-center justify-content-center mb-2">
                                                    <Icon icon="mdi:check-circle-outline" className="text-2xl" />
                                                </div>
                                                <span className="fw-semibold text-dark">All students are performing well!</span>
                                                <span className="text-xs text-muted mt-1">No students require immediate intervention</span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* 14-Day Practice Trend Chart */}
                        <div className="col-12 col-lg-7">
                            <div className="card border-0 shadow-sm radius-12 h-100">
                                <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                                    <div className="d-flex align-items-center gap-2">
                                        <Icon icon="mdi:chart-areaspline" className="text-primary text-xl" />
                                        <h6 className="mb-0 fw-bold">Class Practice Activity Trend</h6>
                                    </div>
                                    <small className="text-muted">Daily submissions</small>
                                </div>
                                <div className="card-body">
                                    <Chart options={chartOptions} series={chartSeries} type="area" height={260} />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Classroom Performance Comparison Table */}
                    <div className="card border-0 shadow-sm radius-12">
                        <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                            <div className="d-flex align-items-center gap-2">
                                <Icon icon="mdi:google-classroom" className="text-purple text-xl" />
                                <h6 className="mb-0 fw-bold">My Classroom Performance Overview</h6>
                            </div>
                            {canManageClassrooms && (
                                <Link to="/school/classrooms" className="btn btn-sm btn-link text-decoration-none">
                                    Manage Classrooms &rarr;
                                </Link>
                            )}
                        </div>
                        <div className="card-body p-0">
                            <div className="table-responsive">
                                <table className="table align-middle mb-0">
                                    <thead className="table-light text-xs text-uppercase text-muted">
                                        <tr>
                                            <th className="ps-3">Classroom Name</th>
                                            <th>Join Code</th>
                                            <th>Enrolled Students</th>
                                            <th>Total Attempts</th>
                                            <th>Avg. Accuracy</th>
                                            {canManageClassrooms && <th className="pe-3 text-end">Action</th>}
                                        </tr>
                                    </thead>
                                    <tbody className="text-sm">
                                        {(data?.classroom_comparison || []).length > 0 ? (
                                            data.classroom_comparison.map((c) => (
                                                <tr key={c.id}>
                                                    <td className="ps-3 fw-semibold text-dark">{c.name}</td>
                                                    <td>
                                                        <span className="badge bg-light text-dark font-mono text-xs border">
                                                            {c.join_code || "—"}
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <span className="badge bg-primary-subtle text-primary">
                                                            {c.students_count} Students
                                                        </span>
                                                    </td>
                                                    <td>{c.total_attempts}</td>
                                                    <td>
                                                        <span className={`fw-bold ${c.accuracy >= 70 ? "text-success" : "text-warning"}`}>
                                                            {c.accuracy}%
                                                        </span>
                                                    </td>
                                                    {canManageClassrooms && (
                                                        <td className="pe-3 text-end">
                                                            <Link to={`/school/classrooms/${c.id}`} className="btn btn-sm btn-outline-primary py-1 px-2">
                                                                Classroom Details
                                                            </Link>
                                                        </td>
                                                    )}
                                                </tr>
                                            ))
                                        ) : (
                                            <tr>
                                                <td colSpan={canManageClassrooms ? 6 : 5} className="text-center py-4 text-muted">
                                                    No classrooms assigned yet. {canCreateClassrooms && <Link to="/school/classrooms/create">Create a classroom now</Link>}.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            ) : (
                /* ==========================================================
                   🏢 SCHOOL ADMIN DASHBOARD VIEW
                   ========================================================== */
                <div className="d-flex flex-column gap-4">
                    {/* Subscription Expiry Reminder Section */}
                    <SchoolSubscriptionReminder
                        subscription={sub}
                        loading={loading}
                        error={dashboardError}
                        targetRoute="/school/subscription"
                    />

                    {/* Quick Action Bar */}
                    {showQuickActions && (
                        <div className="card border-0 shadow-sm p-3 bg-white radius-12">
                            <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
                                <div className="d-flex align-items-center gap-2">
                                    <Icon icon="mdi:lightning-bolt" className="text-warning text-xl" />
                                    <span className="fw-bold text-dark">Quick Actions:</span>
                                </div>
                                <div className="d-flex gap-2 flex-wrap">
                                    {canCreateClassrooms && (
                                        <Link to="/school/classrooms/create" className="btn btn-sm btn-primary d-flex align-items-center gap-1">
                                            <Icon icon="mdi:plus" /> New Classroom
                                        </Link>
                                    )}
                                    {canCreateTeachers && (
                                        <Link to="/school/teachers/create" className="btn btn-sm btn-outline-primary d-flex align-items-center gap-1">
                                            <Icon icon="mdi:teach" /> Add Teacher
                                        </Link>
                                    )}
                                    {canCreateStudents && (
                                        <Link to="/school/students/create" className="btn btn-sm btn-outline-success d-flex align-items-center gap-1">
                                            <Icon icon="mdi:account-plus" /> Add Student
                                        </Link>
                                    )}
                                    {canManageWorlds && (
                                        <Link to="/school/worlds" className="btn btn-sm btn-outline-info d-flex align-items-center gap-1">
                                            <Icon icon="mdi:earth" /> Custom Worlds
                                        </Link>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Stat Cards Grid */}
                    <div className="row row-cols-xxl-6 row-cols-lg-3 row-cols-sm-2 row-cols-1 g-3">
                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Students</span>
                                        <div className="w-36-px h-36-px bg-primary-50 text-primary rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="gridicons:multiple-users" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.total_students ?? 0}</h5>
                                    <span className="badge bg-success-subtle text-success text-xs">
                                        {data?.active_students_7d ?? 0} active in 7 days
                                    </span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Teachers</span>
                                        <div className="w-36-px h-36-px bg-purple-50 text-purple rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="mdi:teach" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.total_teachers ?? 0}</h5>
                                    <span className="text-muted text-xs">Registered Staff</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Classrooms</span>
                                        <div className="w-36-px h-36-px bg-warning-50 text-warning rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="mdi:google-classroom" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.active_classrooms ?? 0} / {data?.total_classrooms ?? 0}</h5>
                                    <span className="text-muted text-xs">Active Classrooms</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Practice Attempts</span>
                                        <div className="w-36-px h-36-px bg-info-50 text-info rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="fluent:target-arrow-24-filled" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.total_exercise_attempts ?? 0}</h5>
                                    <span className="text-muted text-xs">Total Submissions</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <div className="card shadow-none border bg-white h-100 radius-12">
                                <div className="card-body p-3">
                                    <div className="d-flex align-items-center justify-content-between mb-2">
                                        <span className="text-muted text-sm fw-medium">Avg. Accuracy</span>
                                        <div className="w-36-px h-36-px bg-success-50 text-success rounded-circle d-flex align-items-center justify-content-center">
                                            <Icon icon="mdi:chart-line" className="text-lg" />
                                        </div>
                                    </div>
                                    <h5 className="mb-1 fw-bold">{data?.average_accuracy ?? 0}%</h5>
                                    <span className="text-muted text-xs">School Overall Accuracy</span>
                                </div>
                            </div>
                        </div>

                        <div className="col">
                            <Link to="/school/subscription" className="text-decoration-none d-block h-100">
                                <div className="card shadow-none border bg-white h-100 radius-12 hover-card">
                                    <div className="card-body p-3">
                                        <div className="d-flex align-items-center justify-content-between mb-2">
                                            <span className="text-muted text-sm fw-medium">Subscription</span>
                                            <div className={`w-36-px h-36-px ${
                                                subLevel === "normal"
                                                    ? "bg-success-50 text-success"
                                                    : subLevel === "warning" || subLevel === "critical"
                                                    ? "bg-warning-50 text-warning-main"
                                                    : "bg-danger-50 text-danger"
                                            } rounded-circle d-flex align-items-center justify-content-center`}>
                                                <Icon icon="fa-solid:award" className="text-lg" />
                                            </div>
                                        </div>
                                        {subLevel === "normal" ? (
                                            <>
                                                <h6 className="mb-0 text-capitalize text-truncate text-dark">{formatPlanName(sub?.plan)}</h6>
                                                <span className="badge bg-success-focus text-success-main text-xs mt-1">
                                                    {subDays} Days Remaining
                                                </span>
                                            </>
                                        ) : subLevel === "warning" || subLevel === "critical" ? (
                                            <>
                                                <h6 className="mb-0 text-capitalize text-truncate text-dark">{formatPlanName(sub?.plan)}</h6>
                                                <span className={`badge ${subLevel === "critical" ? "bg-danger-focus text-danger-main" : "bg-warning-focus text-warning-main"} text-xs mt-1`}>
                                                    {subDays} Days Left
                                                </span>
                                            </>
                                        ) : subLevel === "expired" ? (
                                            <>
                                                <h6 className="mb-0 text-danger text-capitalize text-truncate">{sub?.plan ? formatPlanName(sub.plan) : "Expired"}</h6>
                                                <span className="badge bg-danger-focus text-danger-main text-xs mt-1">
                                                    Expired
                                                </span>
                                            </>
                                        ) : (
                                            <>
                                                <h6 className="mb-0 text-muted">No Plan</h6>
                                                <span className="badge bg-secondary-focus text-secondary-main text-xs mt-1">
                                                    Inactive
                                                </span>
                                            </>
                                        )}
                                    </div>
                                </div>
                            </Link>
                        </div>
                    </div>

                    {/* Chart & Live Activity Section */}
                    <div className="row g-3">
                        <div className="col-12 col-lg-8">
                            <div className="card border-0 shadow-sm radius-12 h-100">
                                <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                                    <div className="d-flex align-items-center gap-2">
                                        <Icon icon="mdi:chart-areaspline" className="text-primary text-xl" />
                                        <h6 className="mb-0 fw-bold">14-Day Practice Activity Trend</h6>
                                    </div>
                                    <small className="text-muted">Daily exercise attempts</small>
                                </div>
                                <div className="card-body">
                                    <Chart options={chartOptions} series={chartSeries} type="area" height={280} />
                                </div>
                            </div>
                        </div>

                        <div className="col-12 col-lg-4">
                            <div className="card border-0 shadow-sm radius-12 h-100">
                                <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                                    <div className="d-flex align-items-center gap-2">
                                        <Icon icon="mdi:history" className="text-info text-xl" />
                                        <h6 className="mb-0 fw-bold">Recent Student Activity</h6>
                                    </div>
                                    <span className="badge bg-info-subtle text-info">Live Log</span>
                                </div>
                                <div className="card-body p-0">
                                    <div className="list-group list-group-flush">
                                        {(data?.recent_activity || []).length > 0 ? (
                                            data.recent_activity.map((item) => (
                                                <div key={item.id} className="list-group-item px-3 py-2 border-bottom">
                                                    <div className="d-flex justify-content-between align-items-center">
                                                        <span className="fw-semibold text-dark text-sm">{item.student_name}</span>
                                                        <span className={`badge ${item.is_correct ? "bg-success" : "bg-warning text-dark"} text-xs`}>
                                                            {item.is_correct ? "Correct" : "Needs Review"}
                                                        </span>
                                                    </div>
                                                    <div className="d-flex justify-content-between align-items-center text-xs text-muted mt-1">
                                                        <span className="text-truncate" style={{ maxWidth: "160px" }}>{item.exercise_title}</span>
                                                        <span>{item.created_at}</span>
                                                    </div>
                                                </div>
                                            ))
                                        ) : (
                                            <div className="text-center py-4 text-muted small">No recent activity recorded yet</div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Classrooms Breakdown Table */}
                    <div className="card border-0 shadow-sm radius-12">
                        <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
                            <div className="d-flex align-items-center gap-2">
                                <Icon icon="mdi:google-classroom" className="text-warning text-xl" />
                                <h6 className="mb-0 fw-bold">Top Active Classrooms</h6>
                            </div>
                            {canManageClassrooms && (
                                <Link to="/school/classrooms" className="btn btn-sm btn-link text-decoration-none">
                                    View All Classrooms &rarr;
                                </Link>
                            )}
                        </div>
                        <div className="card-body p-0">
                            <div className="table-responsive">
                                <table className="table align-middle mb-0">
                                    <thead className="table-light text-xs text-uppercase text-muted">
                                        <tr>
                                            <th className="ps-3">Classroom Name</th>
                                            <th>Assigned Teacher</th>
                                            <th>Enrolled Students</th>
                                            <th>Status</th>
                                            {canManageClassrooms && <th className="pe-3 text-end">Action</th>}
                                        </tr>
                                    </thead>
                                    <tbody className="text-sm">
                                        {(data?.top_classrooms || []).length > 0 ? (
                                            data.top_classrooms.map((c) => (
                                                <tr key={c.id}>
                                                    <td className="ps-3 fw-semibold text-dark">{c.name}</td>
                                                    <td>{c.teacher_name}</td>
                                                    <td>
                                                        <span className="badge bg-primary-subtle text-primary">
                                                            {c.students_count} Students
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <span className={`badge ${c.is_active ? "bg-success" : "bg-secondary"}`}>
                                                            {c.is_active ? "Active" : "Archived"}
                                                        </span>
                                                    </td>
                                                    {canManageClassrooms && (
                                                        <td className="pe-3 text-end">
                                                            <Link to={`/school/classrooms/${c.id}`} className="btn btn-sm btn-outline-primary py-1 px-2">
                                                                Manage
                                                            </Link>
                                                        </td>
                                                    )}
                                                </tr>
                                            ))
                                        ) : (
                                            <tr>
                                                <td colSpan={canManageClassrooms ? 5 : 4} className="text-center py-4 text-muted">
                                                    No classrooms found in school yet. {canCreateClassrooms && <Link to="/school/classrooms/create">Create one now</Link>}.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </SchoolLayout>
    );
}

export default SchoolDashboard;