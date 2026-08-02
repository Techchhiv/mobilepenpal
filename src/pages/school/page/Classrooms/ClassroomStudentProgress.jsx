import React, { useEffect, useMemo, useState, useRef } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";

import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";

const clamp = (n, min, max) => Math.max(min, Math.min(max, n));

const formatDate = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
};

const toYMD = (d) => {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
};

const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

const startOfWeekMonday = (date) => {
    const d = startOfDay(date);
    const day = d.getDay();
    const diff = (day === 0 ? -6 : 1) - day;
    d.setDate(d.getDate() + diff);
    return d;
};

const endOfWeekSunday = (monday) => {
    const d = startOfDay(monday);
    d.setDate(d.getDate() + 6);
    return d;
};

const monthName = (m) =>
    ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][m - 1];

const buildWeeksForMonth = (year, month) => {
    const firstDay = new Date(year, month - 1, 1);
    const lastDay = new Date(year, month, 0);

    const weeks = [];
    let cursor = startOfWeekMonday(firstDay);

    while (cursor <= lastDay) {
        const weekStart = startOfDay(cursor);
        const weekEnd = endOfWeekSunday(weekStart);

        weeks.push({
            label: `Week ${weeks.length + 1} (${weekStart.toLocaleDateString()} – ${weekEnd.toLocaleDateString()})`,
            from: toYMD(weekStart),
            to: toYMD(weekEnd),
        });

        cursor.setDate(cursor.getDate() + 7);
    }

    return weeks;
};

const formatDuration = (seconds) => {
    const s = Math.max(0, parseInt(seconds || 0, 10));
    const hh = String(Math.floor(s / 3600)).padStart(2, "0");
    const mm = String(Math.floor((s % 3600) / 60)).padStart(2, "0");
    const ss = String(s % 60).padStart(2, "0");
    return `${hh}:${mm}:${ss}`;
};

const avatarUrl = (path) => {
    if (!path) return null;
    if (String(path).startsWith("http")) return path;
    return `${API_BASE_URL}/${String(path).replace(/^\/+/, "")}`;
};

export default function ClassroomStudentProgress() {
    const { classroomId, studentId } = useParams();
    const navigate = useNavigate();

    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    const [classroom, setClassroom] = useState(null);
    const [student, setStudent] = useState(null);
    const [enrollment, setEnrollment] = useState(null);
    const [summary, setSummary] = useState(null);

    const [mode, setMode] = useState("day");
    const todayLocal = () => {
        const d = new Date();
        d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
        return d.toISOString().slice(0, 10);
    };

    const [day, setDay] = useState(todayLocal);
    const today = new Date();

    const [minAccuracy, setMinAccuracy] = useState(0);
    const [accuracySort, setAccuracySort] = useState("none");

    const [selectedYear, setSelectedYear] = useState(today.getFullYear());
    const [selectedMonth, setSelectedMonth] = useState(today.getMonth() + 1);
    const [selectedWeekIndex, setSelectedWeekIndex] = useState(0);

    const reqIdRef = useRef(0);

    const studentName = useMemo(() => {
        if (!student) return "Student";
        const full = [student.first_name, student.last_name].filter(Boolean).join(" ").trim();
        return full || student.name || "Student";
    }, [student]);

    const fetchProgress = async (opts = {}) => {
        const myReqId = ++reqIdRef.current;

        setLoading(true);
        setError("");

        const type = opts.type ?? mode;

        const params = new URLSearchParams();
        params.set("type", type);

        if (type === "day") {
            const dateToSend = opts.date ?? day;
            params.set("date", dateToSend);
        } else if (type === "month") {
            const m = String(opts.month ?? selectedMonth).padStart(2, "0");
            const y = opts.year ?? selectedYear;
            params.set("month", `${y}-${m}`);
        } else {
            const idx = opts.week ?? selectedWeekIndex;
            const wk = weeksInSelectedMonth[idx];
            if (wk) {
                params.set("from", wk.from);
                params.set("to", wk.to);
            }
        }

        try {
            const res = await API.get(
                `/school/classrooms/${classroomId}/students/${studentId}?${params.toString()}`
            );

            if (myReqId !== reqIdRef.current) return;

            setClassroom(res?.data?.classroom ?? null);
            setStudent(res?.data?.student ?? null);
            setEnrollment(res?.data?.enrollment ?? null);
            setSummary(res?.data?.summary ?? null);
        } catch (err) {
            if (myReqId !== reqIdRef.current) return;
            console.error("Fetch student progress failed:", err);
            setError(err?.response?.data?.message || "Failed to load student progress.");
        } finally {
            if (myReqId === reqIdRef.current) setLoading(false);
        }
    };

    const yearOptions = useMemo(() => {
        const y = new Date().getFullYear();
        return [y - 2, y - 1, y, y + 1, y + 2];
    }, []);

    const monthOptions = useMemo(() => {
        return Array.from({ length: 12 }, (_, i) => i + 1);
    }, []);

    const weeksInSelectedMonth = useMemo(() => {
        return buildWeeksForMonth(selectedYear, selectedMonth);
    }, [selectedYear, selectedMonth]);

    useEffect(() => {
        fetchProgress();
    }, [classroomId, studentId]);

    useEffect(() => {
        setSelectedWeekIndex(0);
    }, [selectedYear, selectedMonth]);

    const onApply = (e) => {
        e.preventDefault();
        const opts = { type: mode };
        if (mode === "day") {
            opts.date = day;
        } else if (mode === "week") {
            opts.week = selectedWeekIndex;
        } else {
            opts.year = selectedYear;
            opts.month = selectedMonth;
        }
        fetchProgress(opts);
    };

    const statusBadge = (status) => {
        const s = String(status || "").toLowerCase();
        if (s === "enrolled") return <span className="badge bg-success-subtle text-success">Enrolled</span>;
        if (s === "completed") return <span className="badge bg-info-subtle text-info">Completed</span>;
        if (s === "removed") return <span className="badge bg-danger-subtle text-danger">Removed</span>;
        return <span className="badge bg-secondary-subtle text-secondary">—</span>;
    };

    const summaryCards = useMemo(() => {
        if (!summary) return [];
        const accPct = Math.round(clamp((summary.accuracy || 0) * 100, 0, 100));
        return [
            {
                label: "Time Spent",
                value: formatDuration(summary.time_spent_seconds ?? summary.total_time_spent_seconds ?? 0),
                icon: "mdi:clock-outline",
                bgColor: "bg-primary",
                textColor: "text-white",
            },
            {
                label: "Accuracy",
                value: `${accPct}%`,
                icon: "mdi:target",
                bgColor: accPct >= 70 ? "bg-success" : "bg-warning",
                textColor: accPct >= 70 ? "text-white" : "text-dark",
            },
            {
                label: "Exercises Attempted",
                value: summary.exercises_attempted ?? summary.total_exercises_attempted ?? 0,
                icon: "mdi:clipboard-check-outline",
                bgColor: "bg-info",
                textColor: "text-white",
            },
            {
                label: "Correct Submissions",
                value: summary.correct_attempts ?? summary.total_correct_attempts ?? 0,
                icon: "mdi:check-circle-outline",
                bgColor: "bg-success",
                textColor: "text-white",
            },
            {
                label: "Stars Earned",
                value: summary.stars_earned ?? summary.total_stars_earned ?? 0,
                icon: "mdi:star-outline",
                bgColor: "bg-warning",
                textColor: "text-dark",
            },
            {
                label: "Stages Completed",
                value: summary.stages_completed ?? summary.total_stages_completed ?? 0,
                icon: "mdi:flag-checkered",
                bgColor: "bg-dark",
                textColor: "text-white",
            },
        ];
    }, [summary]);

    const charactersList = useMemo(() => {
        if (!summary) return [];

        const list =
            mode === "day"
                ? (summary.characters_practiced || []).map((c) => {
                    const attempts = Number(c.attempts || 0);
                    const correct = Number(c.correct_attempts || 0);
                    const accuracyPct =
                        typeof c.accuracy === "number"
                            ? Math.round(c.accuracy * 100)
                            : attempts > 0
                                ? Math.round((correct / attempts) * 100)
                                : 0;

                    return { ...c, accuracyPct };
                })
                : (summary.characters_summary || []).map((c) => {
                    const attempts = Number(c.attempts || 0);
                    const correct = Number(c.correct_attempts || 0);
                    const accuracyPct = attempts > 0 ? Math.round((correct / attempts) * 100) : 0;

                    return { ...c, accuracyPct };
                });

        const filtered = list.filter((c) => (Number(c.accuracyPct) || 0) >= minAccuracy);
        let result = filtered;

        if (accuracySort !== "none") {
            const dir = accuracySort === "asc" ? 1 : -1;
            result = [...filtered].sort((a, b) => {
                const aa = Number(a.accuracyPct) || 0;
                const bb = Number(b.accuracyPct) || 0;
                return (aa - bb) * dir;
            });
        }

        return result;
    }, [summary, mode, minAccuracy, accuracySort]);

    const topMastered = summary?.top_mastered_characters || [];
    const toReview = summary?.characters_to_review || [];
    const bestChar = summary?.best_character;
    const weakChar = summary?.needs_attention;
    const avatar = avatarUrl(student?.avatar);

    return (
        <SchoolLayout>
            <div className="d-flex flex-column gap-4">
                {/* Header Navigation Bar */}
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
                                <h5 className="mb-0 fw-bold text-dark">Student Progress Analysis</h5>
                                <small className="text-muted">
                                    Classroom: <strong>{classroom?.name || `#${classroomId}`}</strong> &bull; Student: <strong>{studentName}</strong>
                                </small>
                            </div>
                        </div>

                        <div className="d-flex gap-2 flex-wrap">
                            <Link to={`/school/classrooms/${classroomId}`} className="btn btn-sm btn-outline-primary d-flex align-items-center gap-1 radius-8">
                                <Icon icon="mdi:google-classroom" /> Classroom Details
                            </Link>
                            <Link to={`/school/students/${studentId}`} className="btn btn-sm btn-outline-info d-flex align-items-center gap-1 radius-8">
                                <Icon icon="mdi:account-school" /> Student Profile
                            </Link>
                        </div>
                    </div>
                </div>

                {error && <div className="alert alert-danger radius-12 mb-0">{error}</div>}

                {loading ? (
                    <div className="d-flex justify-content-center align-items-center py-5" style={{ minHeight: "300px" }}>
                        <div className="spinner-border text-primary" role="status">
                            <span className="visually-hidden">Loading progress...</span>
                        </div>
                    </div>
                ) : (
                    <>
                        {/* Student Profile & Filter Row */}
                        <div className="row g-3">
                            {/* Student Profile Card */}
                            <div className="col-12 col-lg-5">
                                <div className="card border-0 shadow-sm radius-12 h-100 bg-white">
                                    <div className="card-body p-3 d-flex align-items-center">
                                        <div className="d-flex align-items-center gap-3">
                                            <div className="w-64-px h-64-px rounded-circle overflow-hidden bg-light border flex-shrink-0">
                                                {avatar ? (
                                                    <img className="w-100 h-100 object-fit-cover" src={avatar} alt={studentName} />
                                                ) : (
                                                    <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                                        <Icon icon="mdi:account" className="text-2xl" />
                                                    </div>
                                                )}
                                            </div>
                                            <div className="flex-grow-1">
                                                <div className="d-flex align-items-center justify-content-between">
                                                    <h6 className="mb-0 fw-bold text-dark">{studentName}</h6>
                                                    {statusBadge(enrollment?.status)}
                                                </div>
                                                <div className="text-muted text-xs mt-1">
                                                    Nickname: <strong>{student?.nickname || "—"}</strong>
                                                </div>
                                                <div className="text-muted text-xs mt-1">
                                                    Enrolled: <strong>{formatDate(enrollment?.enrolled_at || enrollment?.created_at)}</strong>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Date Filter Control Card */}
                            <div className="col-12 col-lg-7">
                                <div className="card border-0 shadow-sm radius-12 h-100 bg-white">
                                    <div className="card-body p-3">
                                        <form onSubmit={onApply}>
                                            <div className="d-flex align-items-center justify-content-between mb-2">
                                                <span className="fw-bold text-dark text-sm">Timeframe Filter:</span>
                                                <div className="btn-group btn-group-sm" role="group">
                                                    <button
                                                        type="button"
                                                        className={`btn ${mode === "day" ? "btn-primary" : "btn-outline-secondary"}`}
                                                        onClick={() => setMode("day")}
                                                    >
                                                        Day
                                                    </button>
                                                    <button
                                                        type="button"
                                                        className={`btn ${mode === "week" ? "btn-primary" : "btn-outline-secondary"}`}
                                                        onClick={() => setMode("week")}
                                                    >
                                                        Week
                                                    </button>
                                                    <button
                                                        type="button"
                                                        className={`btn ${mode === "month" ? "btn-primary" : "btn-outline-secondary"}`}
                                                        onClick={() => setMode("month")}
                                                    >
                                                        Month
                                                    </button>
                                                </div>
                                            </div>

                                            <div className="row g-2 align-items-end mt-1">
                                                {mode === "day" && (
                                                    <div className="col">
                                                        <label className="form-label text-xs mb-1">Select Date</label>
                                                        <input type="date" className="form-control form-control-sm" value={day} onChange={(e) => setDay(e.target.value)} />
                                                    </div>
                                                )}

                                                {mode === "week" && (
                                                    <>
                                                        <div className="col-4">
                                                            <label className="form-label text-xs mb-1">Month</label>
                                                            <select className="form-select form-select-sm" value={selectedMonth} onChange={(e) => setSelectedMonth(parseInt(e.target.value, 10))}>
                                                                {monthOptions.map((m) => (
                                                                    <option key={m} value={m}>{monthName(m)}</option>
                                                                ))}
                                                            </select>
                                                        </div>
                                                        <div className="col-3">
                                                            <label className="form-label text-xs mb-1">Year</label>
                                                            <select className="form-select form-select-sm" value={selectedYear} onChange={(e) => setSelectedYear(parseInt(e.target.value, 10))}>
                                                                {yearOptions.map((y) => (
                                                                    <option key={y} value={y}>{y}</option>
                                                                ))}
                                                            </select>
                                                        </div>
                                                        <div className="col-5">
                                                            <label className="form-label text-xs mb-1">Week Range</label>
                                                            <select className="form-select form-select-sm" value={selectedWeekIndex} onChange={(e) => setSelectedWeekIndex(parseInt(e.target.value, 10))}>
                                                                {weeksInSelectedMonth.map((w, idx) => (
                                                                    <option key={`${w.from}-${w.to}`} value={idx}>{w.label}</option>
                                                                ))}
                                                            </select>
                                                        </div>
                                                    </>
                                                )}

                                                {mode === "month" && (
                                                    <>
                                                        <div className="col-6">
                                                            <label className="form-label text-xs mb-1">Month</label>
                                                            <select className="form-select form-select-sm" value={selectedMonth} onChange={(e) => setSelectedMonth(parseInt(e.target.value, 10))}>
                                                                {monthOptions.map((m) => (
                                                                    <option key={m} value={m}>{monthName(m)}</option>
                                                                ))}
                                                            </select>
                                                        </div>
                                                        <div className="col-6">
                                                            <label className="form-label text-xs mb-1">Year</label>
                                                            <select className="form-select form-select-sm" value={selectedYear} onChange={(e) => setSelectedYear(parseInt(e.target.value, 10))}>
                                                                {yearOptions.map((y) => (
                                                                    <option key={y} value={y}>{y}</option>
                                                                ))}
                                                            </select>
                                                        </div>
                                                    </>
                                                )}

                                                <div className="col-auto">
                                                    <button type="submit" className="btn btn-sm btn-primary d-flex align-items-center gap-1" disabled={loading}>
                                                        <Icon icon="mdi:filter" /> Filter
                                                    </button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* KPI Metric Cards */}
                        <div className="row row-cols-xxl-6 row-cols-lg-3 row-cols-sm-2 row-cols-1 g-3">
                            {summaryCards.map((c) => (
                                <div className="col" key={c.label}>
                                    <div className="card shadow-none border bg-white h-100 radius-12">
                                        <div className="card-body p-3">
                                            <div className="d-flex align-items-center justify-content-between mb-2">
                                                <span className="text-muted text-xs fw-medium text-truncate">{c.label}</span>
                                                <div className={`w-36-px h-36-px ${c.bgColor} ${c.textColor} rounded-circle d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm`}>
                                                    <Icon icon={c.icon} className="text-lg" />
                                                </div>
                                            </div>
                                            <h5 className="mb-0 fw-bold">{c.value}</h5>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>

                        {/* Daily Learning Highlights */}
                        {mode === "day" && (bestChar || weakChar) && (
                            <div className="row g-3">
                                {bestChar && (
                                    <div className="col-12 col-md-6">
                                        <div className="card border-0 shadow-sm radius-12 bg-success-subtle p-3">
                                            <div className="d-flex align-items-center justify-content-between">
                                                <div className="d-flex align-items-center gap-3">
                                                    <div className="w-48-px h-48-px rounded bg-success text-white font-mono fw-bold fs-4 d-flex align-items-center justify-content-center shadow-sm">
                                                        {bestChar.character}
                                                    </div>
                                                    <div>
                                                        <span className="badge bg-success mb-1">Top Mastered</span>
                                                        <div className="fw-bold text-dark text-sm">Best Accuracy Character</div>
                                                    </div>
                                                </div>
                                                <h4 className="mb-0 fw-bold text-success">
                                                    {Math.round((bestChar.accuracy || 0) * 100)}%
                                                </h4>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                {weakChar && (
                                    <div className="col-12 col-md-6">
                                        <div className="card border-0 shadow-sm radius-12 bg-warning-subtle p-3">
                                            <div className="d-flex align-items-center justify-content-between">
                                                <div className="d-flex align-items-center gap-3">
                                                    <div className="w-48-px h-48-px rounded bg-warning text-dark font-mono fw-bold fs-4 d-flex align-items-center justify-content-center shadow-sm">
                                                        {weakChar.character}
                                                    </div>
                                                    <div>
                                                        <span className="badge bg-warning text-dark mb-1">Needs Attention</span>
                                                        <div className="fw-bold text-dark text-sm">Lowest Accuracy Character</div>
                                                    </div>
                                                </div>
                                                <h4 className="mb-0 fw-bold text-warning-emphasis">
                                                    {Math.round((weakChar.accuracy || 0) * 100)}%
                                                </h4>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Weekly Highlight Lists */}
                        {mode === "week" && (topMastered.length > 0 || toReview.length > 0) && (
                            <div className="row g-3">
                                <div className="col-12 col-lg-6">
                                    <div className="card border-0 shadow-sm radius-12 h-100">
                                        <div className="card-header bg-white border-bottom py-3 d-flex align-items-center gap-2">
                                            <Icon icon="mdi:thumb-up-outline" className="text-success text-xl" />
                                            <h6 className="mb-0 fw-bold">Top Mastered Characters</h6>
                                        </div>
                                        <div className="card-body">
                                            {topMastered.length === 0 ? (
                                                <div className="text-muted small">—</div>
                                            ) : (
                                                <div className="d-flex flex-wrap gap-2">
                                                    {topMastered.map((c, idx) => (
                                                        <span className="badge bg-success-subtle text-success border border-success-subtle p-2 text-sm" key={`${c.character}-${idx}`}>
                                                            <strong className="font-mono fs-6 me-1">{c.character}</strong> &bull; {Math.round((c.accuracy || 0) * 100)}%
                                                        </span>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                <div className="col-12 col-lg-6">
                                    <div className="card border-0 shadow-sm radius-12 h-100">
                                        <div className="card-header bg-white border-bottom py-3 d-flex align-items-center gap-2">
                                            <Icon icon="mdi:repeat" className="text-warning text-xl" />
                                            <h6 className="mb-0 fw-bold">Characters to Review</h6>
                                        </div>
                                        <div className="card-body">
                                            {toReview.length === 0 ? (
                                                <div className="text-muted small">—</div>
                                            ) : (
                                                <div className="d-flex flex-wrap gap-2">
                                                    {toReview.map((c, idx) => (
                                                        <span className="badge bg-warning-subtle text-warning border border-warning-subtle p-2 text-sm" key={`${c.character}-${idx}`}>
                                                            <strong className="font-mono fs-6 me-1">{c.character}</strong> &bull; {Math.round((c.accuracy || 0) * 100)}%
                                                        </span>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* Character Breakdown Table */}
                        <div className="card border-0 shadow-sm radius-12">
                            <div className="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between flex-wrap gap-2">
                                <div className="d-flex align-items-center gap-2">
                                    <Icon icon="mdi:alphabetical" className="text-primary text-xl" />
                                    <h6 className="mb-0 fw-bold">Character Practice Breakdown</h6>
                                </div>

                                <div className="d-flex align-items-center gap-3 flex-wrap">
                                    <div className="d-flex align-items-center gap-2">
                                        <span className="text-muted text-xs">Min Accuracy:</span>
                                        <select
                                            className="form-select form-select-sm"
                                            style={{ width: 120 }}
                                            value={minAccuracy}
                                            onChange={(e) => setMinAccuracy(parseInt(e.target.value, 10))}
                                        >
                                            <option value={0}>All</option>
                                            <option value={50}>&ge; 50%</option>
                                            <option value={60}>&ge; 60%</option>
                                            <option value={70}>&ge; 70%</option>
                                            <option value={80}>&ge; 80%</option>
                                            <option value={90}>&ge; 90%</option>
                                        </select>
                                    </div>
                                    <span className="badge bg-light text-dark border text-xs">{charactersList.length} characters</span>
                                </div>
                            </div>

                            <div className="card-body p-0">
                                {charactersList.length === 0 ? (
                                    <div className="d-flex flex-column align-items-center justify-content-center py-5 text-muted small text-center">
                                        <Icon icon="mdi:script-text-outline" className="text-2xl text-muted mb-1" />
                                        No character practice data recorded for this timeframe.
                                    </div>
                                ) : (
                                    <div className="table-responsive">
                                        <table className="table align-middle mb-0">
                                            <thead className="table-light text-xs text-uppercase text-muted">
                                                <tr>
                                                    <th className="ps-3" style={{ width: "60px" }}>#</th>
                                                    <th>Character</th>
                                                    <th>Attempts</th>
                                                    <th>Correct Submissions</th>
                                                    <th
                                                        role="button"
                                                        onClick={() =>
                                                            setAccuracySort((prev) =>
                                                                prev === "none" ? "desc" : prev === "desc" ? "asc" : "none"
                                                            )
                                                        }
                                                        style={{ cursor: "pointer", userSelect: "none" }}
                                                        title="Sort by accuracy"
                                                    >
                                                        <span className="d-inline-flex align-items-center gap-1">
                                                            Accuracy Rate
                                                            <Icon icon={accuracySort === "asc" ? "mdi:sort-ascending" : accuracySort === "desc" ? "mdi:sort-descending" : "mdi:sort"} />
                                                        </span>
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody className="text-sm">
                                                {charactersList.map((c, idx) => {
                                                    const attempts = Number(c.attempts || 0);
                                                    const correct = Number(c.correct_attempts || 0);
                                                    const accuracy = attempts > 0 ? Math.round((correct / attempts) * 100) : 0;

                                                    return (
                                                        <tr key={`${c.character}-${idx}`}>
                                                            <td className="ps-3 text-muted text-xs">{idx + 1}</td>
                                                            <td>
                                                                <div className="w-36-px h-36-px rounded bg-primary-subtle text-primary border border-primary-subtle font-mono fw-bold fs-5 d-flex align-items-center justify-content-center shadow-sm">
                                                                    {c.character || "—"}
                                                                </div>
                                                            </td>
                                                            <td className="fw-medium">{attempts}</td>
                                                            <td className="fw-medium text-success">{correct}</td>
                                                            <td style={{ width: "220px" }}>
                                                                <div className="d-flex align-items-center gap-2">
                                                                    <div className="progress flex-grow-1" style={{ height: "6px" }}>
                                                                        <div
                                                                            className={`progress-bar ${accuracy >= 70 ? "bg-success" : accuracy >= 50 ? "bg-info" : "bg-warning"}`}
                                                                            role="progressbar"
                                                                            style={{ width: `${accuracy}%` }}
                                                                        />
                                                                    </div>
                                                                    <span className={`fw-bold text-xs ${accuracy >= 70 ? "text-success" : "text-warning"}`}>
                                                                        {accuracy}%
                                                                    </span>
                                                                </div>
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
                    </>
                )}
            </div>
        </SchoolLayout>
    );
}
