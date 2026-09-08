import React, { useEffect, useState, useCallback } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../../masterLayout/MasterLayout";
import API from "../../helper/api";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";
import ConfirmModal from "../../components/admin/common/ConfirmModal";
import AdminPagination from "../../components/admin/common/AdminPagination";
import "../../assets/css/adminExpenses.css";

const getPresetDates = (periodKey) => {
    const now = new Date();
    const pad = (n) => String(n).padStart(2, "0");
    const toDateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

    switch (periodKey) {
        case "today": {
            const str = toDateStr(now);
            return { from: str, to: str };
        }
        case "this_month": {
            const first = new Date(now.getFullYear(), now.getMonth(), 1);
            const last = new Date(now.getFullYear(), now.getMonth() + 1, 0);
            return { from: toDateStr(first), to: toDateStr(last) };
        }
        case "this_year": {
            const first = new Date(now.getFullYear(), 0, 1);
            const last = new Date(now.getFullYear(), 11, 31);
            return { from: toDateStr(first), to: toDateStr(last) };
        }
        case "last_30_days": {
            const past = new Date();
            past.setDate(past.getDate() - 30);
            return { from: toDateStr(past), to: toDateStr(now) };
        }
        case "all_time":
        default:
            return { from: "", to: "" };
    }
};

export default function AdminExpensesPage() {
    const [expenses, setExpenses] = useState([]);
    const [summary, setSummary] = useState(null);
    const [loading, setLoading] = useState(true);
    const [financialPeriod, setFinancialPeriod] = useState("all_time");

    const [pagination, setPagination] = useState({
        currentPage: 1,
        lastPage: 1,
        total: 0,
        perPage: 15,
    });

    // Filter states
    const [search, setSearch] = useState("");
    const [category, setCategory] = useState("");
    const [fromDate, setFromDate] = useState("");
    const [toDate, setToDate] = useState("");

    // Modal state
    const [modalOpen, setModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [saving, setSaving] = useState(false);
    const [toastMessage, setToastMessage] = useState(null);

    const [formData, setFormData] = useState({
        title: "",
        amount: "",
        category: "server",
        spent_at: new Date().toISOString().split("T")[0],
        notes: "",
    });

    const loadData = useCallback(async (
        page = 1,
        currentPeriod = financialPeriod,
        currentCat = category,
        currentSearch = search,
        currentFrom = fromDate,
        currentTo = toDate
    ) => {
        try {
            setLoading(true);

            // Params for Expenses Table API
            const expParams = new URLSearchParams();
            expParams.append("page", page);
            if (currentSearch && currentSearch.trim()) expParams.append("search", currentSearch.trim());
            if (currentCat) expParams.append("category", currentCat);
            if (currentFrom) expParams.append("from_date", currentFrom);
            if (currentTo) expParams.append("to_date", currentTo);
            if (currentPeriod && currentPeriod !== "custom" && !currentFrom && !currentTo) {
                expParams.append("period", currentPeriod);
            }

            // Params for Financial Summary Calculation API
            const reportParams = new URLSearchParams();
            if (currentPeriod && currentPeriod !== "custom") {
                reportParams.append("financial_period", currentPeriod);
            }
            if (currentFrom) reportParams.append("financial_from", currentFrom);
            if (currentTo) reportParams.append("financial_to", currentTo);

            const [expensesRes, reportRes] = await Promise.all([
                API.get(`/admin/expenses?${expParams.toString()}`),
                API.get(`/admin/reports/schools?${reportParams.toString()}`),
            ]);

            if (expensesRes.data?.data) {
                const d = expensesRes.data.data;
                setExpenses(d.expenses || []);
                if (d.pagination) {
                    setPagination({
                        currentPage: d.pagination.current_page || 1,
                        lastPage: d.pagination.last_page || 1,
                        total: d.pagination.total || 0,
                        perPage: d.pagination.per_page || 15,
                    });
                }
            }

            if (reportRes.data?.data) {
                setSummary(reportRes.data.data.financial_summary || reportRes.data.data.summary?.financial || null);
            }
        } catch (error) {
            console.error("Failed to load expenses & financial summary:", error);
        } finally {
            setLoading(false);
        }
    }, [financialPeriod, category, search, fromDate, toDate]);

    // Initial load
    useEffect(() => {
        loadData(1, "all_time", "", "", "", "");
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    // When Period preset is changed (Today, This Month, etc.) -> sync from_date and to_date
    const handlePeriodPresetChange = (newPeriod) => {
        setFinancialPeriod(newPeriod);
        const { from, to } = getPresetDates(newPeriod);
        setFromDate(from);
        setToDate(to);
        loadData(1, newPeriod, category, search, from, to);
    };

    // When user manually picks From Date
    const handleFromDateChange = (val) => {
        setFromDate(val);
        setFinancialPeriod("custom");
        loadData(1, "custom", category, search, val, toDate);
    };

    // When user manually picks To Date
    const handleToDateChange = (val) => {
        setToDate(val);
        setFinancialPeriod("custom");
        loadData(1, "custom", category, search, fromDate, val);
    };

    // When user changes category
    const handleCategoryChange = (newCat) => {
        setCategory(newCat);
        loadData(1, financialPeriod, newCat, search, fromDate, toDate);
    };

    // When user searches
    const handleSearchChange = (val) => {
        setSearch(val);
        loadData(1, financialPeriod, category, val, fromDate, toDate);
    };

    // Reset all filters in sync
    const handleResetFilters = () => {
        setSearch("");
        setCategory("");
        setFromDate("");
        setToDate("");
        setFinancialPeriod("all_time");
        loadData(1, "all_time", "", "", "", "");
    };

    const formatCurrency = (val) => {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
        }).format(val || 0);
    };

    const handleOpenCreateModal = () => {
        setEditingItem(null);
        setFormData({
            title: "",
            amount: "",
            category: "server",
            spent_at: new Date().toISOString().split("T")[0],
            notes: "",
        });
        setModalOpen(true);
    };

    const handleOpenEditModal = (item) => {
        setEditingItem(item);
        setFormData({
            title: item.title || "",
            amount: item.amount || "",
            category: item.category || "other",
            spent_at: item.spent_at ? item.spent_at.split("T")[0] : new Date().toISOString().split("T")[0],
            notes: item.notes || "",
        });
        setModalOpen(true);
    };

    const handleFormSubmit = async (e) => {
        e.preventDefault();
        if (!formData.title || !formData.amount || parseFloat(formData.amount) <= 0) {
            alert("Please enter a valid title and positive amount.");
            return;
        }

        try {
            setSaving(true);
            const payload = {
                title: formData.title,
                amount: parseFloat(formData.amount),
                category: formData.category,
                spent_at: formData.spent_at,
                notes: formData.notes,
            };

            if (editingItem) {
                await API.put(`/admin/expenses/${editingItem.id}`, payload);
                setToastMessage("Expense record updated successfully!");
            } else {
                await API.post("/admin/expenses", payload);
                setToastMessage("New expense recorded successfully!");
            }

            setModalOpen(false);
            setTimeout(() => setToastMessage(null), 4000);
            loadData(pagination.currentPage, financialPeriod, category, search, fromDate, toDate);
        } catch (error) {
            console.error("Error saving expense:", error);
            alert(error.response?.data?.message || "Failed to save expense.");
        } finally {
            setSaving(false);
        }
    };

    const [deleteModal, setDeleteModal] = useState(null); // expense item to delete
    const [deleteLoading, setDeleteLoading] = useState(false);

    const handleDeleteExpense = async (item) => {
        setDeleteModal(item);
    };

    const confirmDeleteExpense = async () => {
        if (!deleteModal) return;
        try {
            setDeleteLoading(true);
            await API.delete(`/admin/expenses/${deleteModal.id}`);
            setToastMessage("Expense deleted successfully!");
            setTimeout(() => setToastMessage(null), 4000);
            setDeleteModal(null);
            loadData(pagination.currentPage, financialPeriod, category, search, fromDate, toDate);
        } catch (error) {
            console.error("Error deleting expense:", error);
            alert("Failed to delete expense.");
        } finally {
            setDeleteLoading(false);
        }
    };

    // Export CSV Feature (exports exact active filters)
    const handleExportCSV = async () => {
        try {
            const expParams = new URLSearchParams();
            expParams.append("per_page", "1000");
            if (search && search.trim()) expParams.append("search", search.trim());
            if (category) expParams.append("category", category);
            if (fromDate) expParams.append("from_date", fromDate);
            if (toDate) expParams.append("to_date", toDate);
            if (financialPeriod && financialPeriod !== "custom" && !fromDate && !toDate) {
                expParams.append("period", financialPeriod);
            }

            const res = await API.get(`/admin/expenses?${expParams.toString()}`);
            const exportList = res.data?.data?.expenses || expenses;

            if (exportList.length === 0) {
                alert("No expense records found matching current selection.");
                return;
            }

            const headers = ["ID", "Title", "Category", "Amount ($)", "Date Spent", "Notes", "Recorded By", "Created At"];
            const rows = exportList.map((exp, idx) => [
                idx + 1,
                `"${(exp.title || "").replace(/"/g, '""')}"`,
                exp.category || "other",
                parseFloat(exp.amount || 0).toFixed(2),
                exp.spent_at ? exp.spent_at.split("T")[0] : (exp.created_at?.split("T")[0] || ""),
                `"${(exp.notes || "").replace(/"/g, '""')}"`,
                `"${exp.recorder?.name || "Admin"}"`,
                exp.created_at || "",
            ]);

            const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
            const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
            const url = URL.createObjectURL(blob);
            const link = document.createElement("a");
            link.setAttribute("href", url);
            const filterTag = category ? `_${category}` : `_${financialPeriod}`;
            link.setAttribute("download", `expenses_report${filterTag}_${new Date().toISOString().split("T")[0]}.csv`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (e) {
            console.error("Export error:", e);
            alert("Failed to export expenses.");
        }
    };

    const categoryTabs = [
        { key: "", label: "All Expenses", icon: "ph:squares-four-bold" },
        { key: "server", label: "Server & Infra", icon: "ph:hard-drives-bold" },
        { key: "software", label: "Software / SaaS", icon: "ph:cloud-bold" },
        { key: "marketing", label: "Marketing", icon: "ph:megaphone-simple-bold" },
        { key: "salary", label: "Salaries", icon: "ph:users-three-bold" },
        { key: "utilities", label: "Utilities", icon: "ph:buildings-bold" },
        { key: "other", label: "Other", icon: "ph:dots-three-circle-bold" },
    ];

    const getCategoryBadge = (cat) => {
        switch (cat) {
            case "server":
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-primary-focus text-primary-600 d-inline-flex align-items-center gap-1"><Icon icon="ph:hard-drives-bold" /> Server</span>;
            case "software":
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-info-focus text-info-main d-inline-flex align-items-center gap-1"><Icon icon="ph:cloud-bold" /> Software</span>;
            case "marketing":
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-warning-focus text-warning-main d-inline-flex align-items-center gap-1"><Icon icon="ph:megaphone-simple-bold" /> Marketing</span>;
            case "salary":
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-success-focus text-success-main d-inline-flex align-items-center gap-1"><Icon icon="ph:users-three-bold" /> Salary</span>;
            case "utilities":
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-purple-100 text-purple-600 d-inline-flex align-items-center gap-1"><Icon icon="ph:buildings-bold" /> Utilities</span>;
            default:
                return <span className="px-12 py-4 rounded-pill fw-semibold text-xs bg-neutral-200 text-neutral-800 d-inline-flex align-items-center gap-1"><Icon icon="ph:dots-three-circle-bold" /> Other</span>;
        }
    };

    const totalRevenue = parseFloat(summary?.total_revenue ?? 0);
    const totalExpenses = parseFloat(summary?.total_expenses ?? 0);
    const netProfit = parseFloat(summary?.net_profit ?? (totalRevenue - totalExpenses));
    const isProfitPositive = netProfit >= 0;
    const periodLabel = summary?.period_label || (
        financialPeriod === "this_month" ? "This Month" :
        financialPeriod === "this_year" ? "This Year" :
        financialPeriod === "today" ? "Today" :
        financialPeriod === "last_30_days" ? "Last 30 Days" :
        financialPeriod === "custom" ? "Custom Range" : "All Time"
    );

    return (
        <MasterLayout>
            <div className="expenses-page py-12">
                <AdminPageHeader
                    title="Operating Expenses"
                    subtitle="Track company expenditure, revenue reports, net profit analysis, and operational costs"
                    actionLabel="Record Expense"
                    actionIcon="ph:plus-circle-bold"
                    onAction={handleOpenCreateModal}
                />

                {/* 3 Metric Cards row matching project grid */}
                <div className="row row-cols-xxxl-3 row-cols-lg-3 row-cols-md-2 row-cols-1 gy-4 mb-24">
                    {/* 1. Total Revenue Card */}
                    <div className="col">
                        <div className="card shadow-none border bg-gradient-start-1 h-100 radius-12">
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Total Revenue
                                        </p>
                                        <h4 className="fw-bold mb-0 text-primary">
                                            {loading ? (
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
                    <div className="col">
                        <div className="card shadow-none border bg-gradient-start-2 h-100 radius-12">
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Total Expenses
                                        </p>
                                        <h4 className="fw-bold mb-0 text-warning-main">
                                            {loading ? (
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
                    <div className="col">
                        <div className="card shadow-none border bg-gradient-start-4 h-100 radius-12">
                            <div className="card-body p-20">
                                <div className="d-flex align-items-center justify-content-between mb-12">
                                    <div>
                                
                                    <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                                            Net Profit
                                        </p>
                                        <h4 className={`fw-bold mb-0 ${isProfitPositive ? "text-success-main" : "text-danger-main"}`}>
                                            {loading ? (
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

                {toastMessage && (
                    <div className="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2 py-12 px-16 mb-24 radius-8 shadow-sm" role="alert">
                        <Icon icon="ph:check-circle-bold" className="text-xl text-success-main" />
                        <div className="text-sm fw-medium">{toastMessage}</div>
                        <button type="button" className="btn-close ms-auto" onClick={() => setToastMessage(null)}></button>
                    </div>
                )}

                {/* Main Table Card */}
                <div className="card basic-data-table border radius-12 overflow-hidden shadow-sm">
                    {/* Card Header with Title & Action Controls */}
                    <div className="card-header border-bottom py-16 px-24 d-flex flex-wrap align-items-center justify-content-between gap-3">
                        <div className="d-flex align-items-center gap-2">
                            <h5 className="mb-0 fw-semibold text-primary-light">Operating Expenses</h5>
                            <span className="badge bg-neutral-200 text-neutral-800 text-xs px-8 py-3 rounded-pill fw-semibold">
                                {pagination.total} records
                            </span>
                        </div>

                        <div className="d-flex align-items-center gap-2 flex-wrap">
                            {/* Period Switcher Dropdown */}
                            <select
                                className="form-select form-select-sm w-auto ps-14 pe-32 py-6 rounded-pill period-select-custom shadow-none"
                                value={financialPeriod}
                                onChange={(e) => handlePeriodPresetChange(e.target.value)}
                            >
                                <option value="today">Today</option>
                                <option value="last_30_days">Last 30 Days</option>
                                <option value="this_month">This Month</option>
                                <option value="this_year">This Year</option>
                                <option value="all_time">All Time</option>
                                {financialPeriod === "custom" && <option value="custom">Custom Range</option>}
                            </select>

                            {/* Export CSV */}
                            <button
                                type="button"
                                onClick={handleExportCSV}
                                disabled={expenses.length === 0}
                                className="btn btn-sm btn-outline-secondary text-xs font-semibold rounded-pill px-16 py-6 d-inline-flex align-items-center gap-1"
                                style={{ height: "36px" }}
                                title="Export to CSV"
                            >
                                <Icon icon="ph:download-simple-bold" className="text-sm" />
                                <span>Export CSV</span>
                            </button>

                            {/* Record Expense Button */}
                            <button
                                type="button"
                                onClick={handleOpenCreateModal}
                                className="btn btn-sm btn-primary-600 text-xs font-semibold rounded-pill px-16 py-6 d-inline-flex align-items-center gap-1 shadow-sm"
                                style={{ height: "36px" }}
                            >
                                <Icon icon="ph:plus-circle-bold" className="text-sm" />
                                <span>Record Expense</span>
                            </button>
                        </div>
                    </div>

                    {/* Filter Toolbar & Quick Category Tabs */}
                    <div className="card-body border-bottom p-20">
                        {/* Quick Category Filter Tabs */}
                        <div className="d-flex align-items-center gap-2 flex-wrap mb-16">
                            {categoryTabs.map((tab) => {
                                const isActive = category === tab.key;
                                return (
                                    <button
                                        key={tab.key}
                                        type="button"
                                        onClick={() => handleCategoryChange(tab.key)}
                                        className={`btn btn-sm px-16 py-6 rounded-pill category-tab-btn d-inline-flex align-items-center gap-1 ${
                                            isActive
                                                ? "btn-primary shadow-sm"
                                                : "tab-inactive btn-outline-secondary border-neutral-200"
                                        }`}
                                    >
                                        <Icon icon={tab.icon} className="text-sm" />
                                        <span>{tab.label}</span>
                                    </button>
                                );
                            })}
                        </div>

                        {/* Search & Date Range Filters */}
                        <div className="row g-3 align-items-center">
                            <div className="col-12 col-md-4">
                                <div className="input-group input-group-sm">
                                    <span className="input-group-text border-end-0 px-10">
                                        <Icon icon="ph:magnifying-glass-bold" className="text-secondary text-sm" />
                                    </span>
                                    <input
                                        type="text"
                                        className="form-control border-start-0 text-xs"
                                        placeholder="Search title, vendor or notes…"
                                        value={search}
                                        onChange={(e) => handleSearchChange(e.target.value)}
                                        style={{ height: "36px" }}
                                    />
                                    {search && (
                                        <button
                                            type="button"
                                            className="btn btn-light border border-start-0 px-10"
                                            onClick={() => handleSearchChange("")}
                                        >
                                            <Icon icon="ph:x-bold" className="text-xs text-secondary" />
                                        </button>
                                    )}
                                </div>
                            </div>

                            <div className="col-6 col-md-3">
                                <select
                                    className="form-select form-select-sm text-xs"
                                    value={category}
                                    onChange={(e) => handleCategoryChange(e.target.value)}
                                    style={{ height: "36px" }}
                                >
                                    <option value="">All Categories</option>
                                    <option value="server">Server & Infrastructure</option>
                                    <option value="software">Software / SaaS</option>
                                    <option value="marketing">Marketing & Ads</option>
                                    <option value="salary">Salaries & Contractors</option>
                                    <option value="utilities">Utilities & Office</option>
                                    <option value="other">Other</option>
                                </select>
                            </div>

                            <div className="col-6 col-md-2">
                                <input
                                    type="date"
                                    className="form-control form-control-sm text-xs"
                                    value={fromDate}
                                    onChange={(e) => handleFromDateChange(e.target.value)}
                                    placeholder="From Date"
                                    style={{ height: "36px" }}
                                    title="Filter From Date"
                                />
                            </div>

                            <div className="col-6 col-md-2">
                                <input
                                    type="date"
                                    className="form-control form-control-sm text-xs"
                                    value={toDate}
                                    onChange={(e) => handleToDateChange(e.target.value)}
                                    placeholder="To Date"
                                    style={{ height: "36px" }}
                                    title="Filter To Date"
                                />
                            </div>

                            <div className="col-6 col-md-1">
                                <button
                                    type="button"
                                    onClick={handleResetFilters}
                                    className="btn btn-outline-secondary btn-sm w-100 py-6 text-xs"
                                    style={{ height: "36px" }}
                                    title="Reset all filters"
                                >
                                    Reset
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Table Body */}
                    <div className="card-body p-0">
                        {loading ? (
                            <div className="text-center py-5">
                                <div className="spinner-border text-primary" role="status" />
                                <p className="mt-2 text-muted text-sm">Loading expenses…</p>
                            </div>
                        ) : expenses.length === 0 ? (
                            <AdminEmptyState
                                icon="ph:receipt-bold"
                                title="No expense records found"
                                message="No operating expense records match the selected filters. Click 'Record Expense' to add a new record."
                            />
                        ) : (
                            <div className="table-responsive">
                                <table className="table bordered-table mb-0 align-middle">
                                    <thead>
                                        <tr className="bg-neutral-50">
                                            <th scope="col" style={{ width: 60 }} className="ps-24 py-14">
                                                S.L
                                            </th>
                                            <th scope="col" className="py-14">Title / Description</th>
                                            <th scope="col" className="py-14">Category</th>
                                            <th scope="col" className="py-14">Date Spent</th>
                                            <th scope="col" className="py-14">Amount</th>
                                            <th scope="col" className="py-14">Recorded By</th>
                                            <th scope="col" className="pe-24 text-end py-14" style={{ width: 120 }}>
                                                Action
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {expenses.map((item, index) => (
                                            <tr key={item.id}>
                                                <td className="ps-24 text-secondary-light fw-medium">
                                                    {(pagination.currentPage - 1) * pagination.perPage + index + 1}
                                                </td>
                                                <td>
                                                    <div className="fw-bold text-primary-light text-sm">{item.title}</div>
                                                    {item.notes && (
                                                        <div className="text-xs text-secondary-light mt-1">{item.notes}</div>
                                                    )}
                                                </td>
                                                <td>
                                                    {getCategoryBadge(item.category)}
                                                </td>
                                                <td className="text-sm text-secondary fw-medium">
                                                    {item.spent_at ? item.spent_at.split("T")[0] : (item.created_at?.split("T")[0] || "—")}
                                                </td>
                                                <td>
                                                    <span className="fw-bold text-primary-light text-md">
                                                        {formatCurrency(parseFloat(item.amount || 0))}
                                                    </span>
                                                </td>
                                                <td>
                                                    <div className="d-flex align-items-center gap-2">
                                                        <div className="w-28-px h-28-px rounded-circle bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center fw-bold text-xs">
                                                            {(item.recorder?.name || "A").charAt(0).toUpperCase()}
                                                        </div>
                                                        <div>
                                                            <div className="text-xs fw-semibold text-primary-light">{item.recorder?.name || "Admin"}</div>
                                                            <div className="text-xs text-secondary-light" style={{ fontSize: "11px" }}>
                                                                {item.recorder?.email || ""}
                                                            </div>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="pe-24 text-end">
                                                    <button
                                                        type="button"
                                                        onClick={() => handleOpenEditModal(item)}
                                                        className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                        title="Edit"
                                                    >
                                                        <Icon icon="lucide:edit" />
                                                    </button>
                                                    <button
                                                        type="button"
                                                        onClick={() => handleDeleteExpense(item)}
                                                        className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                        title="Delete"
                                                    >
                                                        <Icon icon="mingcute:delete-2-line" />
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>

                    {/* Card Footer Pagination */}
                    <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                        <div className="text-secondary-light text-xs font-semibold">
                            Showing {pagination.total > 0 ? (pagination.currentPage - 1) * pagination.perPage + 1 : 0}–
                            {Math.min(pagination.currentPage * pagination.perPage, pagination.total)} of {pagination.total} entries
                        </div>
                        {pagination.lastPage > 1 && (
                            <div className="ms-auto">
                                <AdminPagination
                                    page={pagination.currentPage}
                                    totalPages={pagination.lastPage}
                                    onPageChange={(p) => loadData(p, financialPeriod, category, search, fromDate, toDate)}
                                />
                            </div>
                        )}
                    </div>
                </div>

                {/* Create / Edit Modal */}
                {modalOpen && (
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
                                            <Icon icon={editingItem ? "lucide:edit" : "ph:receipt-bold"} className="text-lg" />
                                        </div>
                                        <div>
                                            <h6 className="modal-title fw-bold mb-0 text-md text-primary-light">
                                                {editingItem ? "Edit Operating Expense" : "Record New Expense"}
                                            </h6>
                                            <span className="text-xs text-secondary-light">
                                                {editingItem ? "Update existing expense information" : "Record an operational cost in the backend"}
                                            </span>
                                        </div>
                                    </div>
                                    <button
                                        type="button"
                                        className="btn-close shadow-none"
                                        onClick={() => setModalOpen(false)}
                                        disabled={saving}
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
                                                placeholder="e.g. AWS Cloud Hosting, Google Workspace, Office Rent"
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
                                            onClick={() => setModalOpen(false)}
                                            disabled={saving}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            className="btn btn-primary-600 radius-8 px-24 py-10 text-xs fw-semibold d-inline-flex align-items-center gap-2 shadow-sm"
                                            disabled={saving}
                                        >
                                            {saving ? (
                                                <>
                                                    <span className="spinner-border spinner-border-sm" role="status" />
                                                    <span>Saving…</span>
                                                </>
                                            ) : (
                                                <>
                                                    <Icon icon="lucide:check" className="text-sm" />
                                                    <span>{editingItem ? "Update Expense" : "Save Expense"}</span>
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                )}

                <ConfirmModal
                    open={!!deleteModal}
                    title="Delete Expense Record"
                    message={deleteModal ? `Are you sure you want to delete "${deleteModal.title}" ($${Number(deleteModal.amount).toFixed(2)})? This action cannot be undone.` : ""}
                    confirmLabel="Delete Expense"
                    variant="danger"
                    loading={deleteLoading}
                    onConfirm={confirmDeleteExpense}
                    onCancel={() => setDeleteModal(null)}
                />
            </div>
        </MasterLayout>
    );
}
