// src/pages/admin/Subscriptions/UserSubscriptionsPage.jsx
import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";

export default function UserSubscriptionsPage() {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [err, setErr] = useState("");
    const [msg, setMsg] = useState("");
    const [search, setSearch] = useState("");
    const [actionLoading, setActionLoading] = useState(null);

    const [modal, setModal] = useState(null);
    const [plan, setPlan] = useState("monthly");
    const [amount, setAmount] = useState("");

    const load = async () => {
        setLoading(true);
        try {
            const res = await API.get("admin/subscriptions/students");
            setStudents(res.data.data?.students || []);
        } catch (e) {
            setErr(e?.response?.data?.message || "Failed to load user subscriptions");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        load();
    }, []);

    const flash = (text, isError = false) => {
        (isError ? setErr : setMsg)(text);
        setTimeout(() => (isError ? setErr("") : setMsg("")), 3000);
    };

    const handleActivate = async (e) => {
        e.preventDefault();
        if (!modal) return;
        setActionLoading(modal.studentId);
        try {
            const endpoint =
                modal.type === "activate"
                    ? `admin/subscriptions/student/${modal.studentId}/activate`
                    : `admin/subscriptions/student/${modal.studentId}/renew`;
            await API.post(endpoint, { plan, amount: parseFloat(amount) });
            flash(
                modal.type === "activate"
                    ? "Subscription activated successfully"
                    : "Subscription renewed successfully"
            );
            setModal(null);
            setPlan("monthly");
            setAmount("");
            await load();
        } catch (e) {
            flash(e?.response?.data?.message || "Action failed", true);
        } finally {
            setActionLoading(null);
        }
    };

    const filteredStudents = useMemo(() => {
        const t = search.trim().toLowerCase();
        if (!t) return students;
        return students.filter(
            (s) =>
                (s.first_name || "").toLowerCase().includes(t) ||
                (s.last_name || "").toLowerCase().includes(t)
        );
    }, [students, search]);

    const fullName = (s) =>
        [s.first_name, s.last_name].filter(Boolean).join(" ") || "Unknown";

    return (
        <MasterLayout>
            <div className="row gy-4">

                {/* Table Card */}
                <div className="col-12">
                    <div className="card">
                        <div className="card-header d-flex align-items-center justify-content-between flex-wrap gap-2">
                            <h6 className="mb-0">All Public Users</h6>
                            <div className="d-flex align-items-center gap-2">
                                <input
                                    className="form-control"
                                    placeholder="Search users…"
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                    style={{ maxWidth: 260 }}
                                />
                                <span className="badge bg-neutral-200 text-neutral-800">
                                    {filteredStudents.length} / {students.length}
                                </span>
                            </div>
                        </div>

                        <div className="card-body">
                            {msg && <div className="alert alert-success py-2">{msg}</div>}
                            {err && <div className="alert alert-danger py-2">{err}</div>}

                            {loading ? (
                                <div className="text-center py-5">
                                    <div className="spinner-border text-primary" role="status" />
                                    <p className="mt-2 text-muted">Loading users…</p>
                                </div>
                            ) : (
                                <div className="table-responsive">
                                    <table className="table bordered-table mb-0">
                                        <thead>
                                            <tr>
                                                <th style={{ width: 60 }}>ID</th>
                                                <th>Full Name</th>
                                                <th>Status</th>
                                                <th>Current Plan</th>
                                                <th>End Date</th>
                                                <th style={{ width: 200 }}>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {filteredStudents.map((s) => (
                                                <tr key={s.id}>
                                                    <td>{s.id}</td>
                                                    <td className="fw-semibold">{fullName(s)}</td>
                                                    <td>
                                                        {s.has_active_subscription ? (
                                                            <span className="badge bg-success-focus text-success-main px-16 py-6 radius-4">
                                                                <Icon icon="mdi:check-circle" className="me-1" />
                                                                Active
                                                            </span>
                                                        ) : (
                                                            <span className="badge bg-danger-focus text-danger-main px-16 py-6 radius-4">
                                                                <Icon icon="mdi:close-circle" className="me-1" />
                                                                Inactive
                                                            </span>
                                                        )}
                                                    </td>
                                                    <td>
                                                        {s.current_plan ? (
                                                            <span className="badge bg-primary-light text-primary-600 text-capitalize">
                                                                {s.current_plan}
                                                            </span>
                                                        ) : (
                                                            <span className="text-muted">—</span>
                                                        )}
                                                    </td>
                                                    <td>
                                                        {s.subscription_end_date
                                                            ? new Date(s.subscription_end_date).toLocaleDateString()
                                                            : "—"}
                                                    </td>
                                                    <td>
                                                        {!s.has_active_subscription ? (
                                                            <button
                                                                type="button"
                                                                className="btn btn-sm btn-success-600 d-inline-flex align-items-center gap-1"
                                                                disabled={actionLoading === s.id}
                                                                onClick={() =>
                                                                    setModal({
                                                                        type: "activate",
                                                                        studentId: s.id,
                                                                        studentName: fullName(s),
                                                                    })
                                                                }
                                                            >
                                                                <Icon icon="mdi:power" />
                                                                Activate
                                                            </button>
                                                        ) : (
                                                            <button
                                                                type="button"
                                                                className="btn btn-sm btn-primary-600 d-inline-flex align-items-center gap-1"
                                                                disabled={actionLoading === s.id}
                                                                onClick={() =>
                                                                    setModal({
                                                                        type: "renew",
                                                                        studentId: s.id,
                                                                        studentName: fullName(s),
                                                                    })
                                                                }
                                                            >
                                                                <Icon icon="mdi:autorenew" />
                                                                Renew
                                                            </button>
                                                        )}
                                                    </td>
                                                </tr>
                                            ))}
                                            {!filteredStudents.length && (
                                                <tr>
                                                    <td colSpan={6} className="text-center text-muted py-4">
                                                        No public users found.
                                                    </td>
                                                </tr>
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Activate / Renew Modal */}
            {modal && (
                <div
                    className="modal d-block"
                    tabIndex={-1}
                    style={{ background: "rgba(0,0,0,0.5)" }}
                    onClick={(e) => {
                        if (e.target === e.currentTarget) setModal(null);
                    }}
                >
                    <div className="modal-dialog modal-dialog-centered">
                        <div className="modal-content">
                            <div className="modal-header">
                                <h5 className="modal-title text-capitalize">
                                    {modal.type} Subscription
                                </h5>
                                <button
                                    type="button"
                                    className="btn-close"
                                    onClick={() => setModal(null)}
                                />
                            </div>
                            <form onSubmit={handleActivate}>
                                <div className="modal-body row g-3">
                                    <div className="col-12 col-sm-6">
                                        <label className="form-label">Plan</label>
                                        <select
                                            className="form-select"
                                            value={plan}
                                            onChange={(e) => setPlan(e.target.value)}
                                        >
                                            <option value="monthly">Monthly</option>
                                            <option value="yearly">Yearly</option>
                                        </select>
                                    </div>
                                    <div className="col-12 col-sm-6">
                                        <label className="form-label">Amount ($)</label>
                                        <input
                                            type="number"
                                            min="0"
                                            step="0.01"
                                            className="form-control"
                                            value={amount}
                                            onChange={(e) => setAmount(e.target.value)}
                                            required
                                        />
                                    </div>
                                </div>
                                <div className="modal-footer">
                                    <button
                                        type="button"
                                        className="btn btn-light"
                                        onClick={() => setModal(null)}
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        className="btn btn-primary d-inline-flex align-items-center justify-content-center"
                                        disabled={actionLoading === modal.studentId}
                                    >
                                        {actionLoading === modal.studentId ? (
                                            <>
                                                <span className="spinner-border spinner-border-sm me-1" />
                                                Processing…
                                            </>
                                        ) : (
                                            <>
                                                <Icon
                                                    icon={
                                                        modal.type === "activate" ? "mdi:power" : "mdi:autorenew"
                                                    }
                                                    className="me-1"
                                                />
                                                {modal.type === "activate" ? "Activate" : "Renew"}
                                            </>
                                        )}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            )}
        </MasterLayout>
    );
}
