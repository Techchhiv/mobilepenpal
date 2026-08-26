import React, { useEffect, useState, useMemo, useCallback } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";
import invoiceService from "../../../services/invoiceService";

const uuid = () =>
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
  });

const PAYMENT_METHODS = [
  { value: "cash", label: "Cash" },
  { value: "bank_transfer", label: "Bank Transfer" },
  { value: "other", label: "Other" },
];

const defaultForm = (initialAmount = "", initialTaxRate = 0) => ({
  plan: "monthly",
  amount: initialAmount,
  tax_rate: initialTaxRate,
  payment_method: "cash",
  payment_reference: "",
  notes: "",
  idempotency_key: uuid(),
});

const SETTINGS_DEFAULTS = {
    price: 5.0,
    discount: 50,
    tax_rate: 0,
    billing_cycle: "month",
    contact_phone: "+855 935 248 60",
    contact_email: "info@khmerpenpal.com",
};

const FEATURE_LOCKS_DEFAULTS = {
    enabled: true,
    mini_game_free_daily_limit: 1,
    ai_writing_free_char_limit: 4,
};

export default function UserSubscriptionsPage() {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [err, setErr] = useState("");
    const [msg, setMsg] = useState("");
    const [search, setSearch] = useState("");
    const [actionLoading, setActionLoading] = useState(null);

    const [modal, setModal] = useState(null);
    const [form, setForm] = useState(defaultForm());
    const [prices, setPrices] = useState({ monthly: null, yearly: null });
    const [pricingDetails, setPricingDetails] = useState({ monthly: null, yearly: null });
    const [pricesLoading, setPricesLoading] = useState(false);
    const [invoiceResult, setInvoiceResult] = useState(null);
    const navigate = useNavigate();

    // --- Settings modal state ---
    const [showSettings, setShowSettings] = useState(false);
    const [settingsLoading, setSettingsLoading] = useState(false);
    const [settingsSaving, setSettingsSaving] = useState(false);
    const [settings, setSettings] = useState(SETTINGS_DEFAULTS);

    // --- Feature Locks modal state ---
    const [showFeatureLocks, setShowFeatureLocks] = useState(false);
    const [featureLocksLoading, setFeatureLocksLoading] = useState(false);
    const [featureLocksSaving, setFeatureLocksSaving] = useState(false);
    const [featureLocks, setFeatureLocks] = useState(FEATURE_LOCKS_DEFAULTS);

    // Deactivate modal state
    const [deactivateModal, setDeactivateModal] = useState(null); // { studentId, studentName, currentPlan, endDate }
    const [deactivateReason, setDeactivateReason] = useState("");
    const [voidInvoiceOnDeactivate, setVoidInvoiceOnDeactivate] = useState(false);
    const [deactivateLoading, setDeactivateLoading] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const res = await API.get("admin/subscriptions/students");
            const rawStudents = res.data?.data?.students || res.data?.students || (Array.isArray(res.data?.data) ? res.data.data : []);
            setStudents(Array.isArray(rawStudents) ? rawStudents : []);
        } catch (e) {
            flash(e?.response?.data?.message || "Failed to load students", true);
            setStudents([]);
        } finally {
            setLoading(false);
        }
    }, []);

    const location = useLocation();

    useEffect(() => {
        load();
        loadSettings();

        const query = new URLSearchParams(location.search);
        const modalType = query.get("modal") || query.get("open");
        if (modalType === "settings" || modalType === "global") {
            openSettings();
        } else if (modalType === "feature_locks" || modalType === "features") {
            openFeatureLocks();
        }
    }, [load, location.search]);

    const openModal = (type, student) => {
        setInvoiceResult(null);
        const initialPrice = prices.monthly != null ? Number(prices.monthly).toFixed(2) : "";
        const initialTax = pricingDetails.monthly?.tax_percent ?? 0;
        setForm(defaultForm(initialPrice, initialTax));
        setModal({ type, studentId: student.id, studentName: fullName(student) });
        // Fetch prices
        setPricesLoading(true);
        invoiceService.getPrices()
            .then((res) => {
                const d = res.data.data?.prices || res.data.prices || {};
                setPrices({ monthly: d.monthly, yearly: d.yearly });
                setPricingDetails(d.details || {});
                const planDetails = d.details?.[form.plan];
                setForm((f) => ({
                    ...f,
                    amount: f.amount !== "" ? f.amount : (d[f.plan] != null ? Number(d[f.plan]).toFixed(2) : ""),
                    tax_rate: f.tax_rate !== "" ? f.tax_rate : (planDetails?.tax_percent ?? 0),
                }));
            })
            .catch(() => {})
            .finally(() => setPricesLoading(false));
    };

    const handlePlanChange = (newPlan) => {
        const defaultForPlan = prices[newPlan] != null ? Number(prices[newPlan]).toFixed(2) : "";
        const defaultTax = pricingDetails[newPlan]?.tax_percent ?? 0;
        setForm((f) => ({
            ...f,
            plan: newPlan,
            amount: defaultForPlan,
            tax_rate: defaultTax,
        }));
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

    // --- Feature Locks helpers ---
    const loadFeatureLocks = async () => {
        setFeatureLocksLoading(true);
        try {
            const res = await API.get("admin/feature-locks");
            const s = res.data?.data?.settings || {};
            setFeatureLocks({ ...FEATURE_LOCKS_DEFAULTS, ...s });
        } catch {
            setFeatureLocks({ ...FEATURE_LOCKS_DEFAULTS });
        } finally {
            setFeatureLocksLoading(false);
        }
    };

    const saveFeatureLocks = async (e) => {
        e.preventDefault();
        setFeatureLocksSaving(true);
        try {
            await API.post("admin/feature-locks", { value: featureLocks });
            flash("Feature locks settings saved successfully");
            setShowFeatureLocks(false);
        } catch (e) {
            flash(e?.response?.data?.message || "Failed to save feature locks settings", true);
        } finally {
            setFeatureLocksSaving(false);
        }
    };

    const openFeatureLocks = () => {
        setShowFeatureLocks(true);
        loadFeatureLocks();
    };

    const openDeactivateModal = (student) => {
        setDeactivateModal({
            studentId: student.id,
            studentName: fullName(student),
            currentPlan: student.current_plan,
            endDate: student.subscription_end_date,
        });
        setDeactivateReason("");
        setVoidInvoiceOnDeactivate(false);
    };

    const closeDeactivateModal = () => {
        setDeactivateModal(null);
        setDeactivateReason("");
        setVoidInvoiceOnDeactivate(false);
    };

    const handleDeactivate = async (e) => {
        e.preventDefault();
        if (!deactivateModal) return;
        setDeactivateLoading(true);
        try {
            await API.post(`admin/subscriptions/student/${deactivateModal.studentId}/deactivate`, {
                reason: deactivateReason,
                void_invoice: voidInvoiceOnDeactivate,
            });
            flash(`Subscription for ${deactivateModal.studentName} has been deactivated.`);
            closeDeactivateModal();
            await load();
        } catch (e) {
            flash(e?.response?.data?.message || "Failed to deactivate subscription", true);
        } finally {
            setDeactivateLoading(false);
        }
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
            const res = await API.post(endpoint, {
                plan: form.plan,
                amount: form.amount !== "" ? parseFloat(form.amount) : undefined,
                override_price: form.amount !== "" ? parseFloat(form.amount) : undefined,
                tax_rate: form.tax_rate !== "" && form.tax_rate !== undefined ? parseFloat(form.tax_rate) : undefined,
                payment_method: form.payment_method,
                payment_reference: form.payment_reference || undefined,
                notes: form.notes || undefined,
                idempotency_key: form.idempotency_key,
            });
            const invoice = res.data.data?.invoice;
            setInvoiceResult(invoice || null);
            await load();
        } catch (e) {
            flash(e?.response?.data?.message || "Action failed", true);
        } finally {
            setActionLoading(null);
        }
    };

    const filteredStudents = useMemo(() => {
        const list = Array.isArray(students) ? students : [];
        const t = search.trim().toLowerCase();
        if (!t) return list;
        return list.filter(
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
                                    className="btn btn-outline-warning btn-sm d-inline-flex align-items-center gap-1"
                                    onClick={openFeatureLocks}
                                >
                                    <Icon icon="mdi:lock-cog" />
                                    Feature Locks
                                </button>
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
                                                        {s.has_active_subscription ? (
                                                            <div className="d-flex align-items-center gap-2">
                                                                <button
                                                                    type="button"
                                                                    className="btn btn-sm btn-primary-600 d-inline-flex align-items-center gap-1"
                                                                    disabled={actionLoading === s.id}
                                                                    onClick={() => openModal("renew", s)}
                                                                >
                                                                    <Icon icon="mdi:autorenew" />
                                                                    Renew
                                                                </button>
                                                                <button
                                                                    type="button"
                                                                    className="btn btn-sm btn-outline-danger d-inline-flex align-items-center gap-1"
                                                                    disabled={actionLoading === s.id}
                                                                    onClick={() => openDeactivateModal(s)}
                                                                    title="Deactivate / Terminate Subscription"
                                                                >
                                                                    <Icon icon="mdi:close-octagon-outline" />
                                                                    Deactivate
                                                                </button>
                                                            </div>
                                                        ) : (
                                                            <button
                                                                type="button"
                                                                className="btn btn-sm btn-success-600 d-inline-flex align-items-center gap-1"
                                                                disabled={actionLoading === s.id}
                                                                onClick={() => openModal("activate", s)}
                                                            >
                                                                <Icon icon="mdi:power" />
                                                                Activate
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
                <>
                    <div className="modal-backdrop fade show"></div>
                    <div
                        className="modal fade show d-block"
                        tabIndex={-1}
                        role="dialog"
                        aria-modal="true"
                        onClick={() => { setModal(null); setInvoiceResult(null); setForm(defaultForm()); }}
                    >
                        <div className="modal-dialog modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
                            <div className="modal-content">
                                <div className="modal-header">
                                    <h6 className="modal-title text-capitalize d-flex align-items-center gap-2 mb-0">
                                        <Icon icon={modal.type === "activate" ? "mdi:power" : "mdi:autorenew"} />
                                        {modal.type} Subscription
                                    </h6>
                                    <button
                                        type="button"
                                        className="btn-close"
                                        onClick={() => { setModal(null); setInvoiceResult(null); setForm(defaultForm()); }}
                                    />
                                </div>
                            {invoiceResult ? (
                                <div className="modal-body">
                                    <div className="text-center py-3">
                                        <div style={{ width:64, height:64, borderRadius:"50%", background:"linear-gradient(135deg,#48bb78,#38a169)", display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 16px" }}>
                                            <Icon icon="mdi:check-bold" style={{ fontSize:32, color:"#fff" }} />
                                        </div>
                                        <h6 className="text-success mb-1">Subscription {modal.type === "activate" ? "activated" : "renewed"} successfully!</h6>
                                        <p className="text-muted mb-3" style={{ fontSize:13 }}>Invoice <strong>{invoiceResult.invoice_number}</strong> has been created.</p>
                                        <div className="p-3 mb-3 rounded" style={{ background:"#f7fafc", border:"1px solid #e2e8f0" }}>
                                            <div className="d-flex justify-content-between mb-1"><span className="text-muted" style={{fontSize:12}}>Invoice No</span><strong style={{fontSize:12}}>{invoiceResult.invoice_number}</strong></div>
                                            <div className="d-flex justify-content-between mb-1"><span className="text-muted" style={{fontSize:12}}>Plan</span><span className="text-capitalize" style={{fontSize:12}}>{invoiceResult.plan}</span></div>
                                            <div className="d-flex justify-content-between mb-1"><span className="text-muted" style={{fontSize:12}}>Total</span><strong style={{fontSize:12,color:"#e94560"}}>{invoiceResult.currency} {Number(invoiceResult.total).toFixed(2)}</strong></div>
                                            <div className="d-flex justify-content-between"><span className="text-muted" style={{fontSize:12}}>Status</span><span className="badge bg-success-focus text-success-main" style={{fontSize:11}}>{invoiceResult.status?.toUpperCase()}</span></div>
                                        </div>
                                        <div className="d-flex gap-2 justify-content-center flex-wrap">
                                            <button className="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1" onClick={() => navigate(`/admin/invoices/${invoiceResult.id}`)}>
                                                <Icon icon="mdi:eye" /> View Invoice
                                            </button>
                                            <button className="btn btn-sm btn-primary d-inline-flex align-items-center gap-1" onClick={async () => { try { const r = await invoiceService.downloadPdf(invoiceResult.id); const url=URL.createObjectURL(new Blob([r.data],{type:"application/pdf"})); const a=document.createElement("a"); a.href=url; a.download=`${invoiceResult.invoice_number}.pdf`; a.click(); URL.revokeObjectURL(url); } catch { flash("Failed to download PDF", true); }}}>
                                                <Icon icon="mdi:download" /> Download PDF
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ) : (
                                <form onSubmit={handleActivate}>
                                    <div className="modal-body row g-3">
                                        <div className="col-12">
                                            <div className="p-2 rounded" style={{ background:"#f7fafc", border:"1px solid #e2e8f0" }}>
                                                <small className="text-muted d-block mb-1">Student</small>
                                                <strong>{modal.studentName}</strong>
                                            </div>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Plan</label>
                                            <select className="form-select" value={form.plan} onChange={(e) => handlePlanChange(e.target.value)}>
                                                <option value="monthly">Monthly</option>
                                                <option value="yearly">Yearly</option>
                                            </select>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <div className="d-flex justify-content-between align-items-center mb-1">
                                                <label className="form-label mb-0">Amount ($) <span className="text-danger">*</span></label>
                                                {prices[form.plan] != null && (
                                                    <button
                                                        type="button"
                                                        className="btn btn-link p-0 text-decoration-none"
                                                        style={{ fontSize: 11 }}
                                                        onClick={() => setForm((f) => ({ ...f, amount: Number(prices[f.plan]).toFixed(2) }))}
                                                        title="Reset to system default"
                                                    >
                                                        Default: ${Number(prices[form.plan]).toFixed(2)}
                                                    </button>
                                                )}
                                            </div>
                                            <div className="input-group">
                                                <span className="input-group-text">USD</span>
                                                <input
                                                    type="number"
                                                    step="0.01"
                                                    min="0"
                                                    required
                                                    className="form-control"
                                                    placeholder={pricesLoading ? "Loading…" : "0.00"}
                                                    value={form.amount}
                                                    onChange={(e) => setForm((f) => ({ ...f, amount: e.target.value }))}
                                                />
                                            </div>
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <div className="d-flex justify-content-between align-items-center mb-1">
                                                <label className="form-label mb-0">Tax Rate (%)</label>
                                                {pricingDetails[form.plan]?.tax_percent != null && (
                                                    <button
                                                        type="button"
                                                        className="btn btn-link p-0 text-decoration-none"
                                                        style={{ fontSize: 11 }}
                                                        onClick={() => setForm((f) => ({ ...f, tax_rate: pricingDetails[f.plan]?.tax_percent ?? 0 }))}
                                                        title="Reset to system default"
                                                    >
                                                        Default: {pricingDetails[form.plan]?.tax_percent}%
                                                    </button>
                                                )}
                                            </div>
                                            <input
                                                type="number"
                                                min="0"
                                                max="100"
                                                step="0.1"
                                                className="form-control"
                                                placeholder="0"
                                                value={form.tax_rate}
                                                onChange={(e) => setForm((f) => ({ ...f, tax_rate: e.target.value }))}
                                            />
                                        </div>
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label">Payment Method <span className="text-danger">*</span></label>
                                            <select className="form-select" required value={form.payment_method} onChange={(e) => setForm((f) => ({ ...f, payment_method: e.target.value }))}>
                                                {PAYMENT_METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}
                                            </select>
                                        </div>
                                        <div className="col-12">
                                            <label className="form-label">Payment Reference</label>
                                            <input type="text" className="form-control" placeholder="Transaction ID (optional)" value={form.payment_reference} onChange={(e) => setForm((f) => ({ ...f, payment_reference: e.target.value }))} />
                                        </div>
                                        <div className="col-12">
                                            <label className="form-label">Notes</label>
                                            <textarea className="form-control" rows={2} placeholder="Optional notes" value={form.notes} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} />
                                        </div>

                                        {/* Estimated Financial Breakdown Card */}
                                        {(() => {
                                            const currentDetail = pricingDetails[form.plan];
                                            const enteredAmount = parseFloat(form.amount) || 0;
                                            const taxRate = form.tax_rate !== "" && form.tax_rate !== undefined ? (parseFloat(form.tax_rate) || 0) : (currentDetail?.tax_percent || 0);
                                            
                                            let subtotal, discount, tax, total;
                                            if (currentDetail && Math.abs(enteredAmount - currentDetail.final_price) < 0.01) {
                                                subtotal = currentDetail.subtotal;
                                                discount = currentDetail.discount_amount;
                                                tax = currentDetail.tax_amount;
                                                total = currentDetail.final_price;
                                            } else if (currentDetail && currentDetail.subtotal > 0 && enteredAmount < currentDetail.subtotal) {
                                                subtotal = currentDetail.subtotal;
                                                discount = Math.max(0, subtotal - enteredAmount);
                                                tax = taxRate > 0 ? (enteredAmount * (taxRate / 100)) : 0;
                                                total = enteredAmount + tax;
                                            } else {
                                                subtotal = enteredAmount;
                                                discount = 0;
                                                tax = taxRate > 0 ? (subtotal * (taxRate / 100)) : 0;
                                                total = subtotal + tax;
                                            }

                                            return (
                                                <div className="col-12">
                                                    <div className="p-3 rounded border bg-light">
                                                        <small className="fw-semibold text-muted d-block mb-2">Estimated Invoice Breakdown</small>
                                                        <div className="d-flex justify-content-between py-1 text-sm border-bottom">
                                                            <span className="text-muted">Subtotal</span>
                                                            <span>${subtotal.toFixed(2)}</span>
                                                        </div>
                                                        {discount > 0 && (
                                                            <div className="d-flex justify-content-between py-1 text-sm border-bottom text-success">
                                                                <span>Discount</span>
                                                                <span>-${discount.toFixed(2)}</span>
                                                            </div>
                                                        )}
                                                        {taxRate > 0 && (
                                                            <div className="d-flex justify-content-between py-1 text-sm border-bottom">
                                                                <span className="text-muted">Tax ({taxRate}%)</span>
                                                                <span>+${tax.toFixed(2)}</span>
                                                            </div>
                                                        )}
                                                        <div className="d-flex justify-content-between pt-2 fw-bold text-dark">
                                                            <span>Total Amount</span>
                                                            <span className="text-primary">${total.toFixed(2)}</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            );
                                        })()}
                                    </div>
                                    <div className="modal-footer">
                                        <button type="button" className="btn btn-light" onClick={() => { setModal(null); setInvoiceResult(null); setForm(defaultForm()); }}>Cancel</button>
                                        <button type="submit" className="btn btn-primary d-inline-flex align-items-center justify-content-center gap-1" disabled={actionLoading === modal.studentId || pricesLoading}>
                                            {actionLoading === modal.studentId ? (<><span className="spinner-border spinner-border-sm me-1" />Processing…</>) : (<><Icon icon={modal.type === "activate" ? "mdi:power" : "mdi:autorenew"} />Confirm & {modal.type === "activate" ? "Activate" : "Renew"}</>)}
                                        </button>
                                    </div>
                                </form>
                            )}
                            {invoiceResult && (
                                <div className="modal-footer">
                                    <button type="button" className="btn btn-light" onClick={() => { setModal(null); setInvoiceResult(null); setForm(defaultForm()); }}>Close</button>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
                </>
            )}

            {/* Configure Pricing Settings Modal */}
            {showSettings && (
                <>
                    <div className="modal-backdrop fade show"></div>
                    <div
                        className="modal fade show d-block"
                        tabIndex={-1}
                        role="dialog"
                        aria-modal="true"
                        onClick={() => setShowSettings(false)}
                    >
                        <div className="modal-dialog modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
                            <div className="modal-content">
                                <div className="modal-header">
                                    <h6 className="modal-title d-flex align-items-center gap-2 mb-0">
                                        <Icon icon="mdi:cog" />
                                        Subscription Settings
                                    </h6>
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
                                            <label className="form-label">Tax Rate (%)</label>
                                            <input
                                                type="number"
                                                min="0"
                                                max="100"
                                                step="0.1"
                                                className="form-control"
                                                value={settings.tax_rate ?? 0}
                                                onChange={(e) =>
                                                    setSettings((s) => ({
                                                        ...s,
                                                        tax_rate: parseFloat(e.target.value) || 0,
                                                    }))
                                                }
                                            />
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
                                        <div className="col-12 col-sm-6">
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
                                                {(() => {
                                                    const base = Number(settings.price) || 0;
                                                    const discPct = Number(settings.discount) || 0;
                                                    const discAmt = discPct > 0 ? (base * (discPct / 100)) : 0;
                                                    const net = Math.max(0, base - discAmt);
                                                    const taxPct = Number(settings.tax_rate) || 0;
                                                    const taxAmt = taxPct > 0 ? (net * (taxPct / 100)) : 0;
                                                    const finalP = net + taxAmt;
                                                    return (
                                                        <div className="d-flex flex-column gap-1 text-sm">
                                                            <div className="d-flex justify-content-between">
                                                                <span className="text-muted">Base Price:</span>
                                                                <span>${base.toFixed(2)}</span>
                                                            </div>
                                                            {discPct > 0 && (
                                                                <div className="d-flex justify-content-between text-success">
                                                                    <span>Discount ({discPct}%):</span>
                                                                    <span>-${discAmt.toFixed(2)}</span>
                                                                </div>
                                                            )}
                                                            {taxPct > 0 && (
                                                                <div className="d-flex justify-content-between text-muted">
                                                                    <span>Tax / VAT ({taxPct}%):</span>
                                                                    <span>+${taxAmt.toFixed(2)}</span>
                                                                </div>
                                                            )}
                                                            <div className="d-flex justify-content-between fw-bold text-primary border-top pt-2 mt-1 fs-6">
                                                                <span>Total Payable:</span>
                                                                <span>${finalP.toFixed(2)} / {settings.billing_cycle === "year" ? "year" : "month"}</span>
                                                            </div>
                                                        </div>
                                                    );
                                                })()}
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
                </>
            )}
            {/* Feature Locks Modal */}
            {showFeatureLocks && (
                <>
                    <div className="modal-backdrop fade show"></div>
                    <div
                        className="modal fade show d-block"
                        tabIndex={-1}
                        role="dialog"
                        aria-modal="true"
                        onClick={() => setShowFeatureLocks(false)}
                    >
                        <div className="modal-dialog modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
                            <div className="modal-content">
                                <div className="modal-header">
                                    <h6 className="modal-title d-flex align-items-center gap-2 mb-0">
                                        <Icon icon="mdi:lock-cog" className="text-warning fs-4" />
                                        Feature Locks Settings
                                    </h6>
                                    <button
                                        type="button"
                                        className="btn-close"
                                        onClick={() => setShowFeatureLocks(false)}
                                    />
                                </div>
                            {featureLocksLoading ? (
                                <div className="text-center py-5">
                                    <div className="spinner-border text-primary" role="status" />
                                    <p className="mt-2 text-muted">Loading settings…</p>
                                </div>
                            ) : (
                                <form onSubmit={saveFeatureLocks}>
                                    <div className="modal-body row g-3">
                                        <div className="col-12">
                                            <div className="p-3 d-flex align-items-center justify-content-between alert alert-warning border rounded-3 mb-0 shadow-sm">
                                                <div className="pe-3">
                                                    <label className="form-check-label fw-bold d-block mb-1 cursor-pointer text-dark" htmlFor="locksEnabledSwitch">
                                                        Enable Free Tier Feature Restrictions
                                                    </label>
                                                    <div className="form-text mt-0 text-muted" style={{ fontSize: "0.85rem" }}>
                                                        When enabled, unsubscribed users are restricted based on limits below.
                                                    </div>
                                                </div>
                                                <div className="form-switch switch-primary d-flex align-items-center m-0 p-0 flex-shrink-0">
                                                    <input
                                                        className="form-check-input m-0 cursor-pointer"
                                                        type="checkbox"
                                                        role="switch"
                                                        id="locksEnabledSwitch"
                                                        checked={featureLocks.enabled}
                                                        onChange={(e) =>
                                                            setFeatureLocks((s) => ({
                                                                ...s,
                                                                enabled: e.target.checked,
                                                            }))
                                                        }
                                                    />
                                                </div>
                                            </div>
                                        </div>

                                        <div className="col-12 col-sm-6">
                                            <label className="form-label fw-semibold">Mini-Game Daily Play Limit</label>
                                            <input
                                                type="number"
                                                min="0"
                                                step="1"
                                                className="form-control"
                                                value={featureLocks.mini_game_free_daily_limit}
                                                onChange={(e) =>
                                                    setFeatureLocks((s) => ({
                                                        ...s,
                                                        mini_game_free_daily_limit: parseInt(e.target.value) || 0,
                                                    }))
                                                }
                                                required
                                            />
                                            <div className="form-text">Max free plays allowed per mini-game daily</div>
                                        </div>

                                        <div className="col-12 col-sm-6">
                                            <label className="form-label fw-semibold">AI Writing Character Limit</label>
                                            <input
                                                type="number"
                                                min="1"
                                                step="1"
                                                className="form-control"
                                                value={featureLocks.ai_writing_free_char_limit}
                                                onChange={(e) =>
                                                    setFeatureLocks((s) => ({
                                                        ...s,
                                                        ai_writing_free_char_limit: parseInt(e.target.value) || 1,
                                                    }))
                                                }
                                                required
                                            />
                                            <div className="form-text">Free consonants allowed (e.g. 4 = ក, ខ, គ, ឃ)</div>
                                        </div>
                                    </div>
                                    <div className="modal-footer">
                                        <button
                                            type="button"
                                            className="btn btn-light"
                                            onClick={() => setShowFeatureLocks(false)}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            className="btn btn-primary d-inline-flex align-items-center justify-content-center"
                                            disabled={featureLocksSaving}
                                        >
                                            {featureLocksSaving ? (
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
                </>
            )}

            {/* ── Deactivate Subscription Confirmation Modal ── */}
            {deactivateModal && (
                <>
                    <div className="modal-backdrop fade show"></div>
                    <div
                        className="modal fade show d-block"
                        tabIndex={-1}
                        role="dialog"
                        aria-modal="true"
                        onClick={closeDeactivateModal}
                    >
                        <div
                            className="modal-dialog modal-dialog-centered"
                            role="document"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="modal-content border-0 shadow">
                                <div className="modal-header bg-danger text-white">
                                    <h6 className="modal-title d-flex align-items-center gap-2 mb-0 text-white">
                                        <Icon icon="mdi:alert-circle" width={22} />
                                        Deactivate User Subscription
                                    </h6>
                                    <button
                                        type="button"
                                        className="btn-close btn-close-white"
                                        onClick={closeDeactivateModal}
                                    />
                                </div>
                                <form onSubmit={handleDeactivate}>
                                    <div className="modal-body p-4">
                                        <div className="alert alert-danger-100 border border-danger-200 text-danger-800 rounded p-3 mb-3">
                                            <strong>Warning:</strong> You are about to terminate the active subscription for <strong>{deactivateModal.studentName}</strong>. Premium features will be revoked immediately.
                                        </div>

                                        <div className="mb-3">
                                            <label className="form-label fw-semibold">
                                                Reason for Cancellation <span className="text-danger">*</span>
                                            </label>
                                            <textarea
                                                className="form-control"
                                                rows={3}
                                                required
                                                placeholder="e.g. User requested refund, disputed charge, or account cancellation..."
                                                value={deactivateReason}
                                                onChange={(e) => setDeactivateReason(e.target.value)}
                                            />
                                        </div>

                                        <div className="form-check p-3 rounded bg-light border">
                                            <input
                                                className="form-check-input ms-0 me-2"
                                                type="checkbox"
                                                id="voidInvoiceCheckUser"
                                                checked={voidInvoiceOnDeactivate}
                                                onChange={(e) => setVoidInvoiceOnDeactivate(e.target.checked)}
                                            />
                                            <label className="form-check-label fw-semibold text-dark cursor-pointer" htmlFor="voidInvoiceCheckUser">
                                                Also void linked active invoice
                                            </label>
                                            <div className="text-muted text-xs mt-1 ps-4">
                                                Check this if a refund or payment cancellation was processed. The invoice status will be updated to VOID.
                                            </div>
                                        </div>
                                    </div>
                                    <div className="modal-footer bg-light">
                                        <button
                                            type="button"
                                            className="btn btn-light"
                                            onClick={closeDeactivateModal}
                                            disabled={deactivateLoading}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            className="btn btn-danger d-inline-flex align-items-center gap-1"
                                            disabled={deactivateLoading || !deactivateReason.trim()}
                                        >
                                            {deactivateLoading ? (
                                                <>
                                                    <span className="spinner-border spinner-border-sm me-1" />
                                                    Processing…
                                                </>
                                            ) : (
                                                <>
                                                    <Icon icon="mdi:close-octagon" />
                                                    Confirm Deactivation
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </>
            )}
        </MasterLayout>
    );
}
