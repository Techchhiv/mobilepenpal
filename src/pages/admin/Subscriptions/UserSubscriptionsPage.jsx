// src/pages/admin/Subscriptions/UserSubscriptionsPage.jsx
import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";

const SETTINGS_DEFAULTS = {
    price: 5.0,
    discount: 50,
    billing_cycle: "month",
    contact_phone: "+855 935 248 60",
    contact_email: "nginkimlong@gmail.com",
};

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

    // --- Settings modal state ---
    const [showSettings, setShowSettings] = useState(false);
    const [settingsLoading, setSettingsLoading] = useState(false);
    const [settingsSaving, setSettingsSaving] = useState(false);
    const [settings, setSettings] = useState({ ...SETTINGS_DEFAULTS });

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
        loadSettings();
    }, []);

    const getDefaultAmount = (currentPlan, currentSettings) => {
        const price = parseFloat(currentSettings.price) || 0;
        const discount = parseFloat(currentSettings.discount) || 0;
        const discountedPrice = price * (1 - discount / 100);

        if (currentSettings.billing_cycle === "year") {
            if (currentPlan === "yearly") {
                return discountedPrice.toFixed(2);
            } else {
                return (discountedPrice / 12).toFixed(2);
            }
        } else {
            if (currentPlan === "monthly") {
                return discountedPrice.toFixed(2);
            } else {
                return (discountedPrice * 12).toFixed(2);
            }
        }
    };

    const openModal = (type, student) => {
        const defaultPlan = settings.billing_cycle === "year" ? "yearly" : "monthly";
        setPlan(defaultPlan);
        setAmount(getDefaultAmount(defaultPlan, settings));
        setModal({
            type,
            studentId: student.id,
            studentName: fullName(student),
        });
    };

    const flash = (text, isError = false) => {
        (isError ? setErr : setMsg)(text);
        setTimeout(() => (isError ? setErr("") : setMsg("")), 3000);
    };

    // --- Settings helpers ---
    const loadSettings = async () => {
        setSettingsLoading(true);
        try {
            const res = await API.get("admin/system-settings/subscription");
            const s = res.data?.data?.settings || {};
            setSettings({ ...SETTINGS_DEFAULTS, ...s });
        } catch {
            setSettings({ ...SETTINGS_DEFAULTS });
        } finally {
            setSettingsLoading(false);
        }
    };

    const saveSettings = async (e) => {
        e.preventDefault();
        setSettingsSaving(true);
        try {
            await API.post("admin/system-settings/subscription", { value: settings });
            flash("Subscription settings saved successfully");
            setShowSettings(false);
        } catch (e) {
            flash(e?.response?.data?.message || "Failed to save settings", true);
        } finally {
            setSettingsSaving(false);
        }
    };

    const openSettings = () => {
        setShowSettings(true);
        loadSettings();
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
                                <button
                                    type="button"
                                    className="btn btn-outline-primary btn-sm d-inline-flex align-items-center gap-1"
                                    onClick={openSettings}
                                >
                                    <Icon icon="mdi:cog" />
                                    Configure Pricing
                                </button>
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
                                                                onClick={() => openModal("activate", s)}
                                                            >
                                                                <Icon icon="mdi:power" />
                                                                Activate
                                                            </button>
                                                        ) : (
                                                            <button
                                                                type="button"
                                                                className="btn btn-sm btn-primary-600 d-inline-flex align-items-center gap-1"
                                                                disabled={actionLoading === s.id}
                                                                onClick={() => openModal("renew", s)}
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
                                            onChange={(e) => {
                                                const newPlan = e.target.value;
                                                setPlan(newPlan);
                                                setAmount(getDefaultAmount(newPlan, settings));
                                            }}
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

            {/* Configure Pricing Settings Modal */}
            {showSettings && (
                <div
                    className="modal d-block"
                    tabIndex={-1}
                    style={{ background: "rgba(0,0,0,0.5)" }}
                    onClick={(e) => {
                        if (e.target === e.currentTarget) setShowSettings(false);
                    }}
                >
                    <div className="modal-dialog modal-dialog-centered">
                        <div className="modal-content">
                            <div className="modal-header">
                                <h5 className="modal-title d-flex align-items-center gap-2">
                                    <Icon icon="mdi:cog" />
                                    Subscription Settings
                                </h5>
                                <button
                                    type="button"
                                    className="btn-close"
                                    onClick={() => setShowSettings(false)}
                                />
                            </div>
                            {settingsLoading ? (
                                <div className="modal-body text-center py-5">
                                    <div className="spinner-border text-primary" role="status" />
                                    <p className="mt-2 text-muted">Loading settings…</p>
                                </div>
                            ) : (
                                <form onSubmit={saveSettings}>
                                    <div className="modal-body row g-3">
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Price ($)</label>
                                            <input
                                                type="number"
                                                min="0"
                                                step="0.01"
                                                className="form-control"
                                                value={settings.price}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        price: parseFloat(e.target.value) || 0,
                                                    }))
                                                }
                                                required
                                            />
                                            <div className="form-text">Original price before discount</div>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Discount (%)</label>
                                            <input
                                                type="number"
                                                min="0"
                                                max="100"
                                                step="1"
                                                className="form-control"
                                                value={settings.discount}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        discount: parseInt(e.target.value) || 0,
                                                    }))
                                                }
                                                required
                                            />
                                            <div className="form-text">Set 0 for no discount</div>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Billing Cycle</label>
                                            <select
                                                className="form-select"
                                                value={settings.billing_cycle}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        billing_cycle: e.target.value,
                                                    }))
                                                }
                                            >
                                                <option value="month">Monthly</option>
                                                <option value="year">Yearly</option>
                                            </select>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Contact Phone</label>
                                            <input
                                                type="text"
                                                className="form-control"
                                                value={settings.contact_phone}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        contact_phone: e.target.value,
                                                    }))
                                                }
                                                required
                                            />
                                        </div>
                                        <div className="col-12">
                                            <label className="form-label">Contact Email</label>
                                            <input
                                                type="email"
                                                className="form-control"
                                                value={settings.contact_email}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        contact_email: e.target.value,
                                                    }))
                                                }
                                                required
                                            />
                                        </div>

                                        {/* Live Preview */}
                                        <div className="col-12">
                                            <div className="alert alert-light border mb-0">
                                                <small className="fw-semibold text-muted d-block mb-1">Preview</small>
                                                <div className="d-flex align-items-end gap-2">
                                                    {settings.discount > 0 && (
                                                        <span>
                                                            <span className="badge bg-danger-focus text-danger-main me-1">
                                                                {settings.discount}% OFF
                                                            </span>
                                                            <span className="text-muted text-decoration-line-through">
                                                                ${Number(settings.price).toFixed(2)}
                                                            </span>
                                                        </span>
                                                    )}
                                                    <span className="fw-bold text-primary fs-5">
                                                        $
                                                        {(
                                                            settings.price *
                                                            (1 - settings.discount / 100)
                                                        ).toFixed(2)}{" "}
                                                        / {settings.billing_cycle === "year" ? "year" : "month"}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="modal-footer">
                                        <button
                                            type="button"
                                            className="btn btn-light"
                                            onClick={() => setShowSettings(false)}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            className="btn btn-primary d-inline-flex align-items-center justify-content-center"
                                            disabled={settingsSaving}
                                        >
                                            {settingsSaving ? (
                                                <>
                                                    <span className="spinner-border spinner-border-sm me-1" />
                                                    Saving…
                                                </>
                                            ) : (
                                                <>
                                                    <Icon icon="mdi:content-save" className="me-1" />
                                                    Save Settings
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </form>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </MasterLayout>
    );
}
