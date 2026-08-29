import React, { useState } from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import { useAuth } from "../../context/AuthContext";
import "../../assets/css/adminExpenses.css";

const AdminFinancialSummary = ({ financial, onExpenseUpdated }) => {
    const { isSuperAdmin, hasAnyPermission } = useAuth();
    const canViewFinancial = isSuperAdmin || hasAnyPermission(["menu.payments", "billing.view", "payments.manage", "reports.view", "menu.reports"]);

    const [selectedPeriod, setSelectedPeriod] = useState("all_time");
    const [customFinancial, setCustomFinancial] = useState(null);
    const [loadingPeriod, setLoadingPeriod] = useState(false);

    const [showRecordModal, setShowRecordModal] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [toastMessage, setToastMessage] = useState(null);

    // Form state for new expense
    const [formData, setFormData] = useState({
        title: "",
        amount: "",
        category: "server",
        spent_at: new Date().toISOString().split("T")[0],
        notes: "",
    });

    if (!canViewFinancial) {
        return null;
    }

    const currentData = customFinancial || financial;
    const totalRevenue = parseFloat(currentData?.total_revenue ?? 0);
    const totalExpenses = parseFloat(currentData?.total_expenses ?? 0);
    const netProfit = parseFloat(currentData?.net_profit ?? (totalRevenue - totalExpenses));
    const isProfitPositive = netProfit >= 0;
    const periodLabel = currentData?.period_label || (
        selectedPeriod === "this_month" ? "This Month" :
        selectedPeriod === "this_year" ? "This Year" :
        selectedPeriod === "today" ? "Today" :
        selectedPeriod === "last_30_days" ? "Last 30 Days" : "All Time"
    );

    const formatCurrency = (val) => {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
        }).format(val);
    };

    const handlePeriodChange = async (newPeriod) => {
        setSelectedPeriod(newPeriod);
        try {
            setLoadingPeriod(true);
            const res = await API.get(`/admin/dashboard?financial_period=${newPeriod}`);
            if (res.data?.data?.financial_summary) {
                setCustomFinancial(res.data.data.financial_summary);
            }
        } catch (e) {
            console.error("Error changing financial period:", e);
        } finally {
            setLoadingPeriod(false);
        }
    };

    const handleOpenRecordModal = () => {
        setFormData({
            title: "",
            amount: "",
            category: "server",
            spent_at: new Date().toISOString().split("T")[0],
            notes: "",
        });
        setShowRecordModal(true);
    };

    const handleFormSubmit = async (e) => {
        e.preventDefault();
        if (!formData.title || !formData.amount || parseFloat(formData.amount) <= 0) {
            alert("Please provide a valid title and positive amount.");
            return;
        }

        try {
            setSubmitting(true);
            await API.post("/admin/expenses", {
                title: formData.title,
                amount: parseFloat(formData.amount),
                category: formData.category,
                spent_at: formData.spent_at,
                notes: formData.notes,
            });

            setShowRecordModal(false);
            setToastMessage("Expense recorded successfully!");
            setTimeout(() => setToastMessage(null), 4000);

            // Trigger dashboard refresh
            if (onExpenseUpdated) {
                onExpenseUpdated();
            }

            // Reload period data
            if (selectedPeriod !== "all_time") {
                handlePeriodChange(selectedPeriod);
            }
        } catch (error) {
            console.error("Error recording expense:", error);
            alert(error.response?.data?.message || "Failed to record expense.");
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="card border shadow-sm radius-12 mb-24 overflow-hidden financial-summary-card">
            {/* Clean, Unified Card Header matching Dashboard sections */}
            <div className="card-header py-16 px-24 border-bottom d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div className="d-flex align-items-center gap-3">
                    <div className="w-40-px h-40-px bg-primary-50 text-primary-600 rounded-circle d-flex justify-content-center align-items-center flex-shrink-0">
                        <Icon icon="ph:chart-pie-slice-bold" className="text-xl" />
                    </div>
                    <div>
                        <h6 className="mb-0 fw-bold text-primary-light">Financial Overview</h6>
                        <span className="text-xs text-secondary-light">
                            High-level audit of school payments, server costs, and net platform profit
                        </span>
                    </div>
                </div>

                <div className="d-flex align-items-center gap-2 flex-wrap">
                    {/* Clean Select Filter */}
                    <select
                        className="form-select form-select-sm w-auto ps-14 pe-32 py-6 rounded-pill period-select-custom shadow-none"
                        value={selectedPeriod}
                        onChange={(e) => handlePeriodChange(e.target.value)}
                        disabled={loadingPeriod}
                    >
                        <option value="today">Today</option>
                        <option value="last_30_days">Last 30 Days</option>
                        <option value="this_month">This Month</option>
                        <option value="this_year">This Year</option>
                        <option value="all_time">All Time</option>
                    </select>

                    <Link
                        to="/admin/expenses"
                        className="btn btn-sm btn-outline-primary text-xs font-semibold rounded-pill px-16 py-6 d-inline-flex align-items-center gap-1"
                    >
                        <Icon icon="ph:receipt-bold" className="text-sm" />
                        <span>Manage Expenses</span>
                    </Link>

                    <button
                        type="button"
                        onClick={handleOpenRecordModal}
                        className="btn btn-sm btn-primary-600 text-xs font-semibold rounded-pill px-16 py-6 d-inline-flex align-items-center gap-1 shadow-sm"
                    >
                        <Icon icon="ph:plus-circle-bold" className="text-sm" />
                        <span>Record Expense</span>
                    </button>
                </div>
            </div>

            {/* Card Body with 3 Summary Cards */}
            <div className="card-body p-20">
                {toastMessage && (
                    <div className="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2 py-10 px-16 mb-16 radius-8 shadow-sm" role="alert">
                        <Icon icon="ph:check-circle-bold" className="text-xl text-success-main" />
                        <div className="text-sm fw-medium">{toastMessage}</div>
                        <button type="button" className="btn-close ms-auto" onClick={() => setToastMessage(null)}></button>
                    </div>
                )}

                <div className="row g-3">
                    {/* 1. Total Revenue Card */}
                    <div className="col-12 col-md-4">
                        <div className="card shadow-none border bg-gradient-start-1 h-100" style={{ borderRadius: "10px" }}>
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Total Revenue
                                        </p>
                                        <h4 className="fw-bold mb-0 text-primary">
                                            {loadingPeriod ? (
                                                <span className="spinner-border spinner-border-sm text-primary" role="status" />
                                            ) : (
                                                formatCurrency(totalRevenue)
                                            )}
                                        </h4>
                                    </div>
                                    <div className="w-50-px h-50-px bg-cyan rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm">
                                        <Icon icon="ph:credit-card-fill" className="text-white text-2xl mb-0" />
                                    </div>
                                </div>
                                <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                                    <span className="text-xs text-secondary-light">
                                        School Subscriptions
                                    </span>
                                    <span className="text-xs fw-semibold text-primary">
                                        {periodLabel}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* 2. Total Expenses Card */}
                    <div className="col-12 col-md-4">
                        <div className="card shadow-none border bg-gradient-start-2 h-100" style={{ borderRadius: "10px" }}>
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Total Expenses
                                        </p>
                                        <h4 className="fw-bold mb-0 text-warning-main">
                                            {loadingPeriod ? (
                                                <span className="spinner-border spinner-border-sm text-warning" role="status" />
                                            ) : (
                                                formatCurrency(totalExpenses)
                                            )}
                                        </h4>
                                    </div>
                                    <div className="w-50-px h-50-px bg-warning rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm">
                                        <Icon icon="ph:coins-fill" className="text-white text-2xl mb-0" />
                                    </div>
                                </div>
                                <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                                    <span className="text-xs text-secondary-light">
                                        Operating & Server Costs
                                    </span>
                                    <span className="text-xs fw-semibold text-warning-main">
                                        {periodLabel}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* 3. Net Profit Card */}
                    <div className="col-12 col-md-4">
                        <div className="card shadow-none border bg-gradient-start-4 h-100" style={{ borderRadius: "10px" }}>
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Net Profit
                                        </p>
                                        <h4 className={`fw-bold mb-0 ${isProfitPositive ? "text-success-main" : "text-danger-main"}`}>
                                            {loadingPeriod ? (
                                                <span className="spinner-border spinner-border-sm text-success" role="status" />
                                            ) : (
                                                formatCurrency(netProfit)
                                            )}
                                        </h4>
                                    </div>
                                    <div className={`w-50-px h-50-px ${isProfitPositive ? "bg-success" : "bg-danger"} rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm`}>
                                        <Icon icon={isProfitPositive ? "ph:trend-up-fill" : "ph:trend-down-fill"} className="text-white text-2xl mb-0" />
                                    </div>
                                </div>
                                <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                                    <span className="text-xs text-secondary-light">
                                        Revenue − Expenses
                                    </span>
                                    <span className={`text-xs fw-semibold ${isProfitPositive ? "text-success-main" : "text-danger-main"}`}>
                                        {isProfitPositive ? "Profitable" : "Deficit"}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Record Expense Modal */}
            {showRecordModal && (
                <div
                    className="modal fade show d-block expense-modal"
                    tabIndex="-1"
                    style={{ backgroundColor: "rgba(0,0,0,0.6)", zIndex: 1050 }}
                >
                    <div className="modal-dialog modal-dialog-centered" style={{ maxWidth: "580px" }}>
                        <div className="modal-content radius-16 border-0 shadow-lg">
                            <div className="modal-header py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                                <div className="d-flex align-items-center gap-3">
                                    <div className="w-36-px h-36-px rounded-circle bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center">
                                        <Icon icon="ph:receipt-bold" className="text-lg" />
                                    </div>
                                    <div>
                                        <h6 className="modal-title fw-bold mb-0 text-md text-primary-light">Record Operating Expense</h6>
                                        <span className="text-xs text-secondary-light">
                                            Record a manual operational cost in the backend
                                        </span>
                                    </div>
                                </div>
                                <button
                                    type="button"
                                    className="btn-close shadow-none"
                                    onClick={() => setShowRecordModal(false)}
                                    disabled={submitting}
                                ></button>
                            </div>

                            <form onSubmit={handleFormSubmit}>
                                <div className="modal-body p-24">
                                    <div className="mb-20">
                                        <label className="form-label fw-semibold text-primary-light text-sm mb-8">
                                            Expense Title <span className="text-danger-main">*</span>
                                        </label>
                                        <input
                                            type="text"
                                            className="form-control radius-8 h-44-px text-sm"
                                            placeholder="e.g. AWS Cloud Hosting, Google Workspace, Office Supplies"
                                            value={formData.title}
                                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                            required
                                        />
                                    </div>

                                    <div className="row g-3 mb-20">
                                        <div className="col-12 col-sm-6">
                                            <label className="form-label fw-semibold text-primary-light text-sm mb-8">
                                                Amount ($ USD) <span className="text-danger-main">*</span>
                                            </label>
                                            <div className="input-group">
                                                <span className="input-group-text text-secondary-light fw-bold px-12 border-end-0 radius-start-8">
                                                    $
                                                </span>
                                                <input
                                                    type="number"
                                                    step="0.01"
                                                    min="0.01"
                                                    className="form-control border-start-0 radius-end-8 h-44-px text-sm fw-semibold"
                                                    placeholder="0.00"
                                                    value={formData.amount}
                                                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                                                    required
                                                />
                                            </div>
                                        </div>

                                        <div className="col-12 col-sm-6">
                                            <label className="form-label fw-semibold text-primary-light text-sm mb-8">
                                                Category <span className="text-danger-main">*</span>
                                            </label>
                                            <select
                                                className="form-select radius-8 h-44-px text-sm fw-medium"
                                                value={formData.category}
                                                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                            >
                                                <option value="server">Server & Infrastructure</option>
                                                <option value="software">Software / SaaS</option>
                                                <option value="marketing">Marketing & Ads</option>
                                                <option value="salary">Salaries & Contractors</option>
                                                <option value="utilities">Utilities & Office</option>
                                                <option value="other">Other Expense</option>
                                            </select>
                                        </div>
                                    </div>

                                    <div className="mb-20">
                                        <label className="form-label fw-semibold text-primary-light text-sm mb-8">
                                            Date Spent
                                        </label>
                                        <input
                                            type="date"
                                            className="form-control radius-8 h-44-px text-sm"
                                            value={formData.spent_at}
                                            onChange={(e) => setFormData({ ...formData, spent_at: e.target.value })}
                                        />
                                    </div>

                                    <div className="mb-0">
                                        <label className="form-label fw-semibold text-primary-light text-sm mb-8">
                                            Notes / Reference <span className="text-secondary-light fw-normal">(Optional)</span>
                                        </label>
                                        <textarea
                                            rows="3"
                                            className="form-control radius-8 text-sm"
                                            placeholder="Invoice reference, vendor details, or payment notes..."
                                            value={formData.notes}
                                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                                        ></textarea>
                                    </div>
                                </div>

                                <div className="modal-footer py-16 px-24 border-top radius-bottom-16 d-flex align-items-center justify-content-end gap-2">
                                    <button
                                        type="button"
                                        className="btn btn-outline-secondary radius-8 px-20 py-10 text-xs fw-semibold"
                                        onClick={() => setShowRecordModal(false)}
                                        disabled={submitting}
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        className="btn btn-primary-600 radius-8 px-24 py-10 text-xs fw-semibold d-inline-flex align-items-center gap-2 shadow-sm"
                                        disabled={submitting}
                                    >
                                        {submitting ? (
                                            <>
                                                <span className="spinner-border spinner-border-sm" role="status" />
                                                <span>Saving…</span>
                                            </>
                                        ) : (
                                            <>
                                                <Icon icon="lucide:check" className="text-sm" />
                                                <span>Save Expense</span>
                                            </>
                                        )}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AdminFinancialSummary;
