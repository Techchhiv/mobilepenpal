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
    return dt.toLocaleDateString();
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
            setError(err?.response?.data?.message || "Failed to load progress.");
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
        if (s === "enrolled") return <span className="badge bg-success">Enrolled</span>;
        if (s === "completed") return <span className="badge bg-info">Completed</span>;
        if (s === "removed") return <span className="badge bg-danger">Removed</span>;
        return <span className="badge bg-secondary">—</span>;
    };

    const summaryCards = useMemo(() => {
        if (!summary) return [];
        const accPct = Math.round(clamp((summary.accuracy || 0) * 100, 0, 100));
        return [
            {
                label: "Time Spent",
                value: formatDuration(summary.time_spent_seconds ?? summary.total_time_spent_seconds ?? 0),
                icon: "mdi:timer-outline",
            },
            {
                label: "Accuracy",
                value: `${accPct}%`,
                icon: "mdi:target",
            },
            {
                label: "Exercises",
                value: summary.exercises_attempted ?? summary.total_exercises_attempted ?? 0,
                icon: "mdi:clipboard-check-outline",
            },
            {
                label: "Correct",
                value: summary.correct_attempts ?? summary.total_correct_attempts ?? 0,
                icon: "mdi:check-circle-outline",
            },
            {
                label: "Stars",
                value: summary.stars_earned ?? summary.total_stars_earned ?? 0,
                icon: "mdi:star-outline",
            },
            {
                label: "Stages Completed",
                value: summary.stages_completed ?? summary.total_stages_completed ?? 0,
                icon: "mdi:flag-checkered",
            },
            ...(mode === "week"
                ? [
                    {
                        label: "Practice Days",
                        value: summary.practice_days ?? 0,
                        icon: "mdi:calendar-check-outline",
                    },
                ]
                : []),
        ];
    }, [summary, mode]);

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
            <div className="col-12">
                <div className="card">
                    {/* Header */}
                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <div>
                            <h5 className="card-title mb-0">Student Progress</h5>
                            <small className="text-muted">
                                Classroom #{classroomId} • Student #{studentId}
                            </small>
                        </div>

                        <div className="d-flex gap-2 flex-wrap">
                            <button
                                type="button"
                                className="btn btn-outline-secondary d-flex align-items-center"
                                onClick={() => navigate(-1)}
                            >
                                <Icon icon="mdi:arrow-left" className="me-6" />
                                Back
                            </button>

                            <Link
                                to={`/school/classrooms/${classroomId}`}
                                className="btn btn-outline-primary d-flex align-items-center"
                            >
                                <Icon icon="mdi:google-classroom" className="me-6" />
                                Classroom
                            </Link>

                            <Link
                                to={`/school/students/${studentId}`}
                                className="btn btn-outline-info d-flex align-items-center"
                            >
                                <Icon icon="mdi:account-school" className="me-6" />
                                Student Profile
                            </Link>
                        </div>
                    </div>

                    <div className="card-body">
                        {error && <div className="alert alert-danger">{error}</div>}

                        {loading ? (
                            <div className="text-center py-40">
                                <div className="spinner-border" role="status" />
                                <div className="mt-12 text-muted">Loading progress...</div>
                            </div>
                        ) : (
                            <>
                                {/* Student + classroom context */}
                                <div className="row g-3 mb-3">
                                    <div className="col-12 col-lg-4">
                                        <div className="card border h-100">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:account" />
                                                <h6 className="mb-0">Student</h6>
                                            </div>
                                            <div className="card-body">
                                                <div className="d-flex align-items-center gap-3">
                                                    <div
                                                        className="border radius-12 overflow-hidden bg-neutral-50"
                                                        style={{ width: 72, height: 72 }}
                                                    >
                                                        {avatar ? (
                                                            <img
                                                                className="w-100 h-100 object-fit-cover"
                                                                src={avatar}
                                                                alt={studentName}
                                                            />
                                                        ) : (
                                                            <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                                                <Icon icon="mdi:account" width={36} />
                                                            </div>
                                                        )}
                                                    </div>

                                                    <div className="flex-grow-1">
                                                        <div className="fw-semibold">{studentName}</div>
                                                        <div className="text-muted small">
                                                            Nickname: {student?.nickname || "—"}
                                                        </div>
                                                        <div className="mt-6">{statusBadge(enrollment?.status)}</div>
                                                    </div>
                                                </div>

                                                <div className="mt-12 text-muted small">
                                                    Enrolled: {formatDate(enrollment?.enrolled_at || enrollment?.created_at)}
                                                    <br />
                                                    Left: {enrollment?.left_at ? formatDate(enrollment.left_at) : "—"}
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="col-12 col-lg-8">
                                        <div className="card border h-100">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:google-classroom" />
                                                <h6 className="mb-0">Classroom</h6>
                                            </div>
                                            <div className="card-body">
                                                <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                                                    <div>
                                                        <div className="fw-semibold">{classroom?.name || "—"}</div>
                                                        <div className="text-muted small">
                                                            Date Range: {formatDate(classroom?.start_date)} -{" "}
                                                            {formatDate(classroom?.end_date)}
                                                        </div>
                                                    </div>

                                                    <span
                                                        className={`badge ${classroom?.is_active ? "bg-success" : "bg-warning text-dark"
                                                            }`}
                                                    >
                                                        {classroom?.is_active ? "Active" : "Archived"}
                                                    </span>
                                                </div>

                                                {/* Filters */}
                                                <form className="mt-14" onSubmit={onApply}>
                                                    {/* FILTER ROW */}
                                                    <div className="row g-2">
                                                        {/* View */}
                                                        <div className="col-12 col-md-3">
                                                            <label className="form-label">View</label>
                                                            <select
                                                                className="form-select"
                                                                value={mode}
                                                                onChange={(e) => setMode(e.target.value)}
                                                            >
                                                                <option value="day">Day</option>
                                                                <option value="week">Week</option>
                                                                <option value="month">Month</option>
                                                            </select>
                                                        </div>

                                                        {/* DAILY */}
                                                        {mode === "day" && (
                                                            <div className="col-12 col-md-4">
                                                                <label className="form-label">Day</label>
                                                                <input
                                                                    type="date"
                                                                    className="form-control"
                                                                    value={day}
                                                                    onChange={(e) => setDay(e.target.value)}
                                                                />
                                                            </div>
                                                        )}

                                                        {/* WEEKLY */}
                                                        {mode === "week" && (
                                                            <>
                                                                <div className="col-6 col-md-3">
                                                                    <label className="form-label">Month</label>
                                                                    <select
                                                                        className="form-select"
                                                                        value={selectedMonth}
                                                                        onChange={(e) => setSelectedMonth(parseInt(e.target.value, 10))}
                                                                    >
                                                                        {monthOptions.map((m) => (
                                                                            <option key={m} value={m}>
                                                                                {monthName(m)}
                                                                            </option>
                                                                        ))}
                                                                    </select>
                                                                </div>

                                                                <div className="col-6 col-md-2">
                                                                    <label className="form-label">Year</label>
                                                                    <select
                                                                        className="form-select"
                                                                        value={selectedYear}
                                                                        onChange={(e) => setSelectedYear(parseInt(e.target.value, 10))}
                                                                    >
                                                                        {yearOptions.map((y) => (
                                                                            <option key={y} value={y}>
                                                                                {y}
                                                                            </option>
                                                                        ))}
                                                                    </select>
                                                                </div>

                                                                <div className="col-12 col-md-4">
                                                                    <label className="form-label">Week</label>
                                                                    <select
                                                                        className="form-select"
                                                                        value={selectedWeekIndex}
                                                                        onChange={(e) => setSelectedWeekIndex(parseInt(e.target.value, 10))}
                                                                    >
                                                                        {weeksInSelectedMonth.map((w, idx) => (
                                                                            <option key={`${w.from}-${w.to}`} value={idx}>
                                                                                {w.label}
                                                                            </option>
                                                                        ))}
                                                                    </select>
                                                                </div>
                                                            </>
                                                        )}

                                                        {/* MONTHLY */}
                                                        {mode === "month" && (
                                                            <>
                                                                <div className="col-6 col-md-3">
                                                                    <label className="form-label">Month</label>
                                                                    <select
                                                                        className="form-select"
                                                                        value={selectedMonth}
                                                                        onChange={(e) => setSelectedMonth(parseInt(e.target.value, 10))}
                                                                    >
                                                                        {monthOptions.map((m) => (
                                                                            <option key={m} value={m}>
                                                                                {monthName(m)}
                                                                            </option>
                                                                        ))}
                                                                    </select>
                                                                </div>

                                                                <div className="col-6 col-md-2">
                                                                    <label className="form-label">Year</label>
                                                                    <select
                                                                        className="form-select"
                                                                        value={selectedYear}
                                                                        onChange={(e) => setSelectedYear(parseInt(e.target.value, 10))}
                                                                    >
                                                                        {yearOptions.map((y) => (
                                                                            <option key={y} value={y}>
                                                                                {y}
                                                                            </option>
                                                                        ))}
                                                                    </select>
                                                                </div>
                                                            </>
                                                        )}
                                                    </div>

                                                    {/* APPLY ROW (ALWAYS SAME POSITION) */}
                                                    <div className="row mt-3">
                                                        <div className="col-12 col-md-3">
                                                            <button
                                                                type="submit"
                                                                className="btn btn-primary w-100 d-flex align-items-center justify-content-center"
                                                                disabled={loading}
                                                            >
                                                                <Icon icon="mdi:filter" className="me-6" />
                                                                Apply
                                                            </button>
                                                        </div>
                                                    </div>

                                                    {/* RANGE INFO */}
                                                    {summary?.range && (
                                                        <div className="text-muted small mt-10">
                                                            {mode === "day" && (
                                                                <>
                                                                    Date: <b>{summary.range.used_date || "—"}</b>
                                                                </>
                                                            )}

                                                            {mode !== "day" && (
                                                                <>
                                                                    Range: <b>{summary.range.used_from || "—"}</b> →{" "}
                                                                    <b>{summary.range.used_to || "—"}</b>
                                                                </>
                                                            )}
                                                        </div>
                                                    )}
                                                </form>


                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {/* Summary cards */}
                                <div className="row g-3 mb-3">
                                    {summaryCards.map((c) => (
                                        <div className="col-12 col-sm-6 col-lg-3" key={c.label}>
                                            <div className="card border h-100">
                                                <div className="card-body">
                                                    <div className="d-flex align-items-center justify-content-between">
                                                        <div>
                                                            <div className="text-muted small">{c.label}</div>
                                                            <div className="fw-semibold">{c.value}</div>
                                                        </div>
                                                        <Icon icon={c.icon} width={28} className="text-muted" />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>

                                {/* Daily insights (best/needs attention) */}
                                {mode === "day" && (bestChar || weakChar) && (
                                    <div className="row g-3 mb-3">
                                        <div className="col-12 col-lg-6">
                                            <div className="card border h-100">
                                                <div className="card-header d-flex align-items-center gap-2">
                                                    <Icon icon="mdi:star" />
                                                    <h6 className="mb-0">Best Character</h6>
                                                </div>
                                                <div className="card-body">
                                                    {bestChar ? (
                                                        <div className="d-flex justify-content-between align-items-center">
                                                            <div className="fw-semibold">{bestChar.character}</div>
                                                            <span className="badge bg-success">
                                                                {Math.round((bestChar.accuracy || 0) * 100)}%
                                                            </span>
                                                        </div>
                                                    ) : (
                                                        <div className="text-muted">—</div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        <div className="col-12 col-lg-6">
                                            <div className="card border h-100">
                                                <div className="card-header d-flex align-items-center gap-2">
                                                    <Icon icon="mdi:alert-circle-outline" />
                                                    <h6 className="mb-0">Needs Attention</h6>
                                                </div>
                                                <div className="card-body">
                                                    {weakChar ? (
                                                        <div className="d-flex justify-content-between align-items-center">
                                                            <div className="fw-semibold">{weakChar.character}</div>
                                                            <span className="badge bg-warning text-dark">
                                                                {Math.round((weakChar.accuracy || 0) * 100)}%
                                                            </span>
                                                        </div>
                                                    ) : (
                                                        <div className="text-muted">—</div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                {/* Weekly highlight lists */}
                                {mode === "week" && (topMastered.length > 0 || toReview.length > 0) && (
                                    <div className="row g-3 mb-3">
                                        <div className="col-12 col-lg-6">
                                            <div className="card border h-100">
                                                <div className="card-header d-flex align-items-center gap-2">
                                                    <Icon icon="mdi:thumb-up-outline" />
                                                    <h6 className="mb-0">Top Mastered</h6>
                                                </div>
                                                <div className="card-body">
                                                    {topMastered.length === 0 ? (
                                                        <div className="text-muted">—</div>
                                                    ) : (
                                                        <div className="d-flex flex-wrap gap-2">
                                                            {topMastered.map((c, idx) => (
                                                                <span className="badge bg-success" key={`${c.character}-${idx}`}>
                                                                    {c.character} • {Math.round((c.accuracy || 0) * 100)}%
                                                                </span>
                                                            ))}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        <div className="col-12 col-lg-6">
                                            <div className="card border h-100">
                                                <div className="card-header d-flex align-items-center gap-2">
                                                    <Icon icon="mdi:repeat" />
                                                    <h6 className="mb-0">Characters to Review</h6>
                                                </div>
                                                <div className="card-body">
                                                    {toReview.length === 0 ? (
                                                        <div className="text-muted">—</div>
                                                    ) : (
                                                        <div className="d-flex flex-wrap gap-2">
                                                            {toReview.map((c, idx) => (
                                                                <span className="badge bg-warning text-dark" key={`${c.character}-${idx}`}>
                                                                    {c.character} • {Math.round((c.accuracy || 0) * 100)}%
                                                                </span>
                                                            ))}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                {/* Characters table */}
                                <div className="card border">
                                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                                        <h6 className="mb-0">Character Breakdown</h6>

                                        <div className="d-flex align-items-center gap-2 flex-wrap">
                                            <div className="d-flex align-items-center gap-2">
                                                <span className="text-muted small">Min Accuracy</span>
                                                <select
                                                    className="form-select form-select-sm"
                                                    style={{ width: 140 }}
                                                    value={minAccuracy}
                                                    onChange={(e) => setMinAccuracy(parseInt(e.target.value, 10))}
                                                >
                                                    <option value={0}>All</option>
                                                    <option value={50}>≥ 50%</option>
                                                    <option value={60}>≥ 60%</option>
                                                    <option value={70}>≥ 70%</option>
                                                    <option value={80}>≥ 80%</option>
                                                    <option value={90}>≥ 90%</option>
                                                </select>
                                            </div>

                                            <span className="text-muted small">{charactersList.length} characters</span>
                                        </div>
                                    </div>


                                    <div className="card-body">
                                        {charactersList.length === 0 ? (
                                            <div className="text-center text-muted py-20">No character data found for this period.</div>
                                        ) : (
                                            <div className="table-responsive">
                                                <table className="table bordered-table mb-0">
                                                    <thead>
                                                        <tr>
                                                            <th>#</th>
                                                            <th>Character</th>
                                                            <th>Attempts</th>
                                                            <th>Correct</th>
                                                            <th
                                                                role="button"
                                                                onClick={() =>
                                                                    setAccuracySort((prev) =>
                                                                        prev === "none" ? "desc" : prev === "desc" ? "asc" : "none"
                                                                    )
                                                                }
                                                                style={{ cursor: "pointer", userSelect: "none", whiteSpace: "nowrap" }}
                                                                title="Sort by accuracy"
                                                            >
                                                                <span className="d-inline-flex align-items-center gap-2">
                                                                    Accuracy

                                                                    <span className="d-inline-flex flex-column" style={{ lineHeight: 1 }}>
                                                                        <Icon
                                                                            icon="mdi:chevron-up"
                                                                            style={{
                                                                                opacity: accuracySort === "asc" ? 1 : 0.25,
                                                                                transform: "translateY(2px)",
                                                                            }}
                                                                        />
                                                                        <Icon
                                                                            icon="mdi:chevron-down"
                                                                            style={{
                                                                                opacity: accuracySort === "desc" ? 1 : 0.25,
                                                                                transform: "translateY(-2px)",
                                                                            }}
                                                                        />
                                                                    </span>
                                                                </span>
                                                            </th>

                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {charactersList.map((c, idx) => {
                                                            const attempts = Number(c.attempts || 0);
                                                            const correct = Number(c.correct_attempts || 0);
                                                            const accuracy = attempts > 0 ? Math.round((correct / attempts) * 100) : 0;

                                                            return (
                                                                <tr key={`${c.character}-${idx}`}>
                                                                    <td>{idx + 1}</td>
                                                                    <td className="fw-semibold">{c.character || "—"}</td>
                                                                    <td>{attempts}</td>
                                                                    <td>{correct}</td>
                                                                    <td>
                                                                        <span
                                                                            className={`badge ${accuracy >= 80
                                                                                ? "bg-success"
                                                                                : accuracy >= 50
                                                                                    ? "bg-info"
                                                                                    : "bg-warning text-dark"
                                                                                }`}
                                                                        >
                                                                            {accuracy}%
                                                                        </span>
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
                </div>
            </div>
        </SchoolLayout>
    );
}
