import React, { useEffect, useState, useCallback, useMemo } from "react";
import {
  Award,
  ShieldCheck,
  ShieldAlert,
  Calendar,
  Clock,
  FileText,
  CreditCard,
  CreditCard as CreditCardOff,
  History,
  RefreshCw,
  Eye,
  Download,
  CheckCircle2,
  AlertCircle,
  Info,
  Mail,
  Phone,
  MapPin,
} from "lucide-react";
import SchoolLayout from "../masterLayout/SchoolLayout";
import schoolBillingService from "../../../services/schoolBillingService";

/**
 * Format date string into "01 Jan 2026"
 */
function formatDate(dateStr) {
  if (!dateStr) return "—";
  const d = new Date(dateStr);
  if (Number.isNaN(d.getTime())) return String(dateStr);
  return d.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/**
 * Format date & time into "01 Jan 2026, 14:30"
 */
function formatDateTime(dateStr) {
  if (!dateStr) return "—";
  const d = new Date(dateStr);
  if (Number.isNaN(d.getTime())) return String(dateStr);
  return d.toLocaleString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Format currency amount
 */
function formatCurrency(amount, currency = "USD") {
  const num = Number(amount) || 0;
  return `$${num.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/**
 * Cohesive badge styles matching Khmer PenPal Dashboard
 */
const STATUS_BADGES = {
  active: "bg-success-subtle text-success border border-success-subtle",
  paid: "bg-success-subtle text-success border border-success-subtle",
  expired: "bg-warning-subtle text-warning border border-warning-subtle",
  upcoming: "bg-primary-subtle text-primary border border-primary-subtle",
  issued: "bg-info-subtle text-info border border-info-subtle",
  void: "bg-danger-subtle text-danger border border-danger-subtle",
  inactive: "bg-secondary-subtle text-secondary border border-secondary-subtle",
};

export default function SchoolSubscriptionBillingPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [billingData, setBillingData] = useState(null);

  // Invoice modal state
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [invoiceModalLoading, setInvoiceModalLoading] = useState(false);
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);

  // Download state tracking
  const [downloadingId, setDownloadingId] = useState(null);
  const [flashMsg, setFlashMsg] = useState({ text: "", type: "info" });

  const notify = (text, type = "info") => {
    setFlashMsg({ text, type });
    setTimeout(() => setFlashMsg({ text: "", type: "info" }), 4000);
  };

  const fetchBillingData = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await schoolBillingService.getBillingSummary();
      if (res.data?.data) {
        setBillingData(res.data.data);
      } else {
        setBillingData(res.data || null);
      }
    } catch (err) {
      console.error("Failed to load subscription & billing:", err);
      const msg =
        err?.response?.data?.message ||
        "Unable to load subscription information. Please try again.";
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBillingData();
  }, [fetchBillingData]);

  // Open invoice view modal
  const handleViewInvoice = async (invoiceId) => {
    if (!invoiceId) return;
    setInvoiceModalLoading(true);
    setShowInvoiceModal(true);
    try {
      const res = await schoolBillingService.getInvoiceDetails(invoiceId);
      const inv = res.data?.data?.invoice || res.data?.invoice || res.data;
      setSelectedInvoice(inv);
    } catch (err) {
      console.error("Failed to load invoice details:", err);
      notify(
        err?.response?.data?.message || "Failed to load invoice details.",
        "danger"
      );
      setShowInvoiceModal(false);
    } finally {
      setInvoiceModalLoading(false);
    }
  };

  // Trigger PDF download
  const handleDownloadInvoice = async (invoiceId, invoiceNumber) => {
    if (!invoiceId) return;
    setDownloadingId(invoiceId);
    try {
      const res = await schoolBillingService.downloadInvoicePdf(invoiceId);
      const blob = new Blob([res.data], { type: "application/pdf" });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${invoiceNumber || `invoice-${invoiceId}`}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
      notify(`Invoice ${invoiceNumber || ""} downloaded successfully.`, "success");
    } catch (err) {
      console.error("Failed to download invoice PDF:", err);
      notify(
        err?.response?.data?.message || "Failed to download invoice PDF.",
        "danger"
      );
    } finally {
      setDownloadingId(null);
    }
  };

  const currentSub = billingData?.current_subscription;
  const historyList = billingData?.history || [];
  const school = billingData?.school;
  const isActive = currentSub?.status === "active" || Boolean(currentSub?.is_active);

  // Compute contract duration & elapsed progress
  const progressMetrics = useMemo(() => {
    if (!currentSub?.start_date || !currentSub?.end_date) return null;
    const s = new Date(currentSub.start_date).getTime();
    const e = new Date(currentSub.end_date).getTime();
    const now = new Date().getTime();
    if (Number.isNaN(s) || Number.isNaN(e) || e <= s) return null;

    const totalDays = Math.max(1, Math.round((e - s) / (1000 * 60 * 60 * 24)));
    const elapsedDays = Math.max(0, Math.round((now - s) / (1000 * 60 * 60 * 24)));
    const percentUsed = Math.min(100, Math.max(0, Math.round((elapsedDays / totalDays) * 100)));
    const percentRemaining = Math.max(0, 100 - percentUsed);

    return { totalDays, elapsedDays, percentUsed, percentRemaining };
  }, [currentSub?.start_date, currentSub?.end_date]);

  return (
    <SchoolLayout>
      {/* ══════════════════════════════════════════════════════════════════
          1. CLEAN PAGE HEADER (Matches Khmer PenPal Dashboard Style)
      ══════════════════════════════════════════════════════════════════ */}
      <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-24">
        <div>
          <div className="d-flex align-items-center gap-2 mb-1">
            <h5 className="fw-bold text-dark mb-0">Subscription & Billing</h5>
            <span className="badge bg-primary-subtle text-primary text-xs px-2.5 py-1 rounded-pill fw-medium border border-primary-subtle">
              Read-Only View
            </span>
          </div>
          <p className="text-muted text-sm mb-0">
            Overview of your school's current license plan, subscription duration, and official invoices.
          </p>
        </div>
      </div>

      {/* ── Flash Notification Banner ── */}
      {flashMsg.text && (
        <div
          className={`alert alert-${flashMsg.type} d-flex align-items-center justify-content-between py-2 px-3 radius-8 mb-24 shadow-sm border-0`}
          role="alert"
        >
          <div className="d-flex align-items-center gap-2">
            {flashMsg.type === "success" ? (
              <CheckCircle2 size={18} className="text-success-main flex-shrink-0" />
            ) : flashMsg.type === "danger" ? (
              <AlertCircle size={18} className="text-danger-main flex-shrink-0" />
            ) : (
              <Info size={18} className="text-info-main flex-shrink-0" />
            )}
            <span className="text-sm fw-medium">{flashMsg.text}</span>
          </div>
          <button
            type="button"
            className="btn-close"
            onClick={() => setFlashMsg({ text: "", type: "info" })}
            aria-label="Close"
          />
        </div>
      )}

      {/* ── Loading State ── */}
      {loading && (
        <div className="card border-0 shadow-sm radius-12 p-5 text-center my-24 bg-white">
          <div
            className="spinner-border text-primary mx-auto mb-3"
            style={{ width: "2.5rem", height: "2.5rem" }}
            role="status"
          >
            <span className="visually-hidden">Loading subscription...</span>
          </div>
          <h6 className="fw-bold text-dark mb-1">
            Loading Subscription & Billing...
          </h6>
          <p className="text-muted text-sm mb-0">
            Fetching active school license details and official invoices.
          </p>
        </div>
      )}

      {/* ── Error State ── */}
      {!loading && error && (
        <div className="card border-0 shadow-sm radius-12 p-4 text-center my-24 bg-white">
          <div
            className="w-48-px h-48-px bg-danger-50 text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center mx-auto mb-3"
          >
            <AlertCircle size={26} />
          </div>
          <h6 className="fw-bold text-danger-main mb-1">
            Unable to load subscription information
          </h6>
          <p className="text-muted text-sm mb-3 mx-auto" style={{ maxWidth: 480 }}>
            {error}
          </p>
          <div>
            <button
              type="button"
              className="btn btn-sm btn-primary radius-8 px-4 py-2 d-inline-flex align-items-center gap-1.5 text-white"
              onClick={fetchBillingData}
            >
              <RefreshCw size={15} />
              <span>Retry</span>
            </button>
          </div>
        </div>
      )}

      {/* ── Main Content (Loaded) ── */}
      {!loading && !error && (
        <>
          {/* ══════════════════════════════════════════════════════════════════
              2. TOP 4 STAT CARDS (Vibrant, Clear, High-Contrast Icons)
          ══════════════════════════════════════════════════════════════════ */}
          <div className="row row-cols-xxl-4 row-cols-lg-2 row-cols-sm-2 row-cols-1 g-3 mb-24">
            {/* Card 1: Plan Tier */}
            <div className="col">
              <div className="card shadow-none border bg-white h-100 radius-12">
                <div className="card-body p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <span className="text-muted text-sm fw-medium">Plan Tier</span>
                    <div className="w-36-px h-36-px bg-primary-50 rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">
                      <Award size={19} strokeWidth={2.2} className="text-primary-600" />
                    </div>
                  </div>
                  <h5 className="mb-1 fw-bold text-dark">
                    {currentSub ? currentSub.plan_name : "No Active Plan"}
                  </h5>
                  <span className="text-muted text-xs">
                    {currentSub
                      ? `${formatCurrency(currentSub.amount, currentSub.currency)} / ${
                          currentSub.plan === "yearly" ? "year" : "month"
                        }`
                      : "Contact Khmer PenPal"}
                  </span>
                </div>
              </div>
            </div>

            {/* Card 2: Status */}
            <div className="col">
              <div className="card shadow-none border bg-white h-100 radius-12">
                <div className="card-body p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <span className="text-muted text-sm fw-medium">Status</span>
                    <div
                      className={`w-36-px h-36-px ${
                        isActive ? "bg-success-50" : "bg-danger-50"
                      } rounded-circle d-flex align-items-center justify-content-center flex-shrink-0`}
                    >
                      {isActive ? (
                        <ShieldCheck size={19} strokeWidth={2.2} className="text-success-main" />
                      ) : (
                        <ShieldAlert size={19} strokeWidth={2.2} className="text-danger-main" />
                      )}
                    </div>
                  </div>
                  <h5 className="mb-1 fw-bold text-dark">
                    {currentSub?.status_label || (isActive ? "Active" : "Inactive")}
                  </h5>
                  <span
                    className={`badge ${
                      isActive ? "bg-success-subtle text-success" : "bg-danger-subtle text-danger"
                    } text-xs`}
                  >
                    {isActive ? "Active License" : "Expired / Suspended"}
                  </span>
                </div>
              </div>
            </div>

            {/* Card 3: Validity */}
            <div className="col">
              <div className="card shadow-none border bg-white h-100 radius-12">
                <div className="card-body p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <span className="text-muted text-sm fw-medium">Validity</span>
                    <div className="w-36-px h-36-px bg-warning-50 rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">
                      <Calendar size={18} strokeWidth={2.2} className="text-warning-main" />
                    </div>
                  </div>
                  <h5 className="mb-1 fw-bold text-dark">
                    {currentSub?.days_left !== undefined
                      ? `${currentSub.days_left} Days Left`
                      : "—"}
                  </h5>
                  <span className="text-muted text-xs">
                    {currentSub?.end_date
                      ? `Valid until ${formatDate(currentSub.end_date)}`
                      : "No expiry set"}
                  </span>
                </div>
              </div>
            </div>

            {/* Card 4: Invoices */}
            <div className="col">
              <div className="card shadow-none border bg-white h-100 radius-12">
                <div className="card-body p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <span className="text-muted text-sm fw-medium">Invoices</span>
                    <div className="w-36-px h-36-px bg-info-50 rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">
                      <FileText size={18} strokeWidth={2.2} className="text-info-main" />
                    </div>
                  </div>
                  <h5 className="mb-1 fw-bold text-dark">
                    {historyList.length} Record{historyList.length !== 1 ? "s" : ""}
                  </h5>
                  <span className="text-muted text-xs">
                    {historyList.length > 0 ? "Official tax invoices on file" : "No billing history"}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* ══════════════════════════════════════════════════════════════════
              3. CURRENT SUBSCRIPTION HERO CARD (10/10 Masterpiece)
          ══════════════════════════════════════════════════════════════════ */}
          <div className="card border-0 shadow-sm radius-12 mb-24 bg-white overflow-hidden">
            {/* Card Header with Glowing Status Dot */}
            <div className="card-header bg-white border-bottom py-3 px-3 px-md-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
              <div className="d-flex align-items-center gap-2">
                <div className="w-36-px h-36-px bg-primary-50 text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center flex-shrink-0">
                  <CreditCard size={18} className="text-primary-600" />
                </div>
                <div>
                  <h6 className="mb-0 fw-bold text-dark">Current School Subscription</h6>
                  <small className="text-muted">Active subscription plan and invoice details</small>
                </div>
              </div>

              {currentSub && (
                <span className="badge bg-success-subtle text-success text-xs px-3 py-1.5 rounded-pill fw-semibold d-inline-flex align-items-center gap-2 border border-success-subtle">
                  <span
                    className="rounded-circle bg-success d-inline-block"
                    style={{
                      width: 7,
                      height: 7,
                      boxShadow: "0 0 0 2px rgba(34, 197, 94, 0.25)",
                    }}
                  />
                  <span>{currentSub.status_label || "Active License"}</span>
                </span>
              )}
            </div>

            {/* Card Body */}
            <div className="card-body p-3 p-md-4">
              {currentSub ? (
                <div className="row g-4 align-items-center">
                  {/* Left: Plan, School & Amount */}
                  <div className="col-12 col-lg-5">
                    <div className="d-flex flex-column gap-2">
                      <div className="d-flex align-items-center gap-2">
                        <span className="badge bg-light text-dark font-mono text-xs border">
                          {currentSub.plan?.toUpperCase()} PLAN
                        </span>
                        {school?.name && (
                          <span className="text-muted text-xs fw-medium text-truncate">
                            • {school.name}
                          </span>
                        )}
                      </div>

                      <h3 className="fw-bold text-dark mb-0">
                        {currentSub.plan_name}
                      </h3>

                      <div className="d-flex align-items-baseline gap-2 mt-1">
                        <span className="display-6 fw-bold text-primary">
                          {formatCurrency(currentSub.amount, currentSub.currency)}
                        </span>
                        <span className="text-muted text-sm">
                          / {currentSub.plan === "yearly" ? "year" : "month"} ({currentSub.currency})
                        </span>
                      </div>

                      {/* 🌟 10/10 Enterprise Progress Bar: Contract Lifecycle */}
                      {progressMetrics && (
                        <div className="mt-2 pt-1">
                          <div className="d-flex justify-content-between align-items-center mb-1 text-xs">
                            <span className="text-muted fw-medium d-inline-flex align-items-center gap-1">
                              <Clock size={12} className="text-primary-600" />
                              <span>Cycle Lifecycle</span>
                            </span>
                            <span className="fw-semibold text-dark">
                              {currentSub.days_left > 0
                                ? `${currentSub.days_left} Days Remaining`
                                : "Expires Today"}
                            </span>
                          </div>
                          <div
                            className="progress bg-light"
                            style={{ height: 6, borderRadius: 999 }}
                            role="progressbar"
                            aria-valuenow={progressMetrics.percentUsed}
                            aria-valuemin="0"
                            aria-valuemax="100"
                          >
                            <div
                              className="progress-bar bg-primary rounded-pill"
                              style={{
                                width: `${progressMetrics.percentUsed}%`,
                                transition: "width 0.6s ease",
                              }}
                            />
                          </div>
                          <div className="d-flex justify-content-between text-muted text-xs mt-1">
                            <span>Started {formatDate(currentSub.start_date)}</span>
                            <span>Renews {formatDate(currentSub.end_date)}</span>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Middle: Start & End Dates (Crisp Spec Tiles) */}
                  <div className="col-12 col-md-6 col-lg-4">
                    <div className="d-flex flex-column gap-3 justify-content-center h-100">
                      <div className="p-3 bg-light border radius-8">
                        <div className="d-flex align-items-center justify-content-between mb-1">
                          <div className="d-flex align-items-center gap-2">
                            <div className="w-24-px h-24-px bg-primary-50 rounded-circle d-inline-flex align-items-center justify-content-center flex-shrink-0">
                              <Calendar size={13} className="text-primary-600" />
                            </div>
                            <span className="text-muted text-xs text-uppercase fw-semibold">
                              Start Date
                            </span>
                          </div>
                          <span className="badge bg-white text-muted border text-xs py-0.5 px-2">
                            Cycle Start
                          </span>
                        </div>
                        <span className="fw-bold text-dark text-sm ps-4 d-block">
                          {formatDate(currentSub.start_date)}
                        </span>
                      </div>

                      <div className="p-3 bg-light border radius-8">
                        <div className="d-flex align-items-center justify-content-between mb-1">
                          <div className="d-flex align-items-center gap-2">
                            <div className="w-24-px h-24-px bg-warning-50 rounded-circle d-inline-flex align-items-center justify-content-center flex-shrink-0">
                              <Clock size={13} className="text-warning-main" />
                            </div>
                            <span className="text-muted text-xs text-uppercase fw-semibold">
                              End Date
                            </span>
                          </div>
                          <span className="badge bg-white text-muted border text-xs py-0.5 px-2">
                            Expiration Due
                          </span>
                        </div>
                        <span className="fw-bold text-dark text-sm ps-4 d-block">
                          {formatDate(currentSub.end_date)}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Right: Official Invoice Action Tile */}
                  <div className="col-12 col-md-6 col-lg-3">
                    <div className="p-3 bg-light border radius-12 d-flex flex-column justify-content-between h-100 gap-3">
                      <div className="d-flex align-items-center justify-content-between flex-wrap gap-1">
                        <span className="text-muted text-xs text-uppercase fw-semibold">
                          Latest Invoice
                        </span>
                        {currentSub.invoice?.invoice_number && (
                          <span className="badge bg-white text-dark border font-mono text-xs px-2 py-1">
                            {currentSub.invoice.invoice_number}
                          </span>
                        )}
                      </div>

                      {currentSub.invoice ? (
                        <div className="d-flex flex-column gap-2">
                          <button
                            type="button"
                            className="btn btn-sm btn-outline-primary radius-8 py-2 w-100 d-flex align-items-center justify-content-center gap-2 fw-semibold shadow-none"
                            onClick={() => handleViewInvoice(currentSub.invoice.id)}
                          >
                            <Eye size={15} />
                            <span>View Invoice</span>
                          </button>
                          <button
                            type="button"
                            className="btn btn-sm btn-primary radius-8 py-2 w-100 d-flex align-items-center justify-content-center gap-2 fw-semibold text-white shadow-sm"
                            onClick={() =>
                              handleDownloadInvoice(
                                currentSub.invoice.id,
                                currentSub.invoice.invoice_number
                              )
                            }
                            disabled={downloadingId === currentSub.invoice.id}
                          >
                            {downloadingId === currentSub.invoice.id ? (
                              <>
                                <span className="spinner-border spinner-border-sm" role="status" />
                                <span>Downloading…</span>
                              </>
                            ) : (
                              <>
                                <Download size={15} className="text-white" />
                                <span>Download PDF</span>
                              </>
                            )}
                          </button>
                        </div>
                      ) : (
                        <div className="text-center py-3 text-muted text-xs fst-italic">
                          Invoice pending generation
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ) : (
                /* Empty state */
                <div className="py-4 text-center">
                  <div className="w-48-px h-48-px bg-light text-muted rounded-circle d-inline-flex align-items-center justify-content-center mx-auto mb-3">
                    <CreditCardOff size={26} />
                  </div>
                  <h6 className="fw-bold text-dark mb-1">
                    No active subscription found
                  </h6>
                  <p className="text-muted text-sm mb-0 mx-auto" style={{ maxWidth: 460 }}>
                    There is currently no active subscription associated with your school. Please contact Khmer PenPal administration to activate your license.
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* ══════════════════════════════════════════════════════════════════
              4. SUBSCRIPTION & INVOICE HISTORY TABLE (Clean Enterprise Ledger)
          ══════════════════════════════════════════════════════════════════ */}
          <div className="card border-0 shadow-sm radius-12 mb-24 bg-white overflow-hidden">
            {/* Card Header with Icon Container */}
            <div className="card-header bg-white border-bottom py-3 px-3 px-md-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
              <div className="d-flex align-items-center gap-2">
                <div className="w-36-px h-36-px bg-info-50 text-info-main rounded-circle d-inline-flex align-items-center justify-content-center flex-shrink-0">
                  <History size={18} className="text-info-main" />
                </div>
                <div>
                  <h6 className="mb-0 fw-bold text-dark">Subscription & Invoice History</h6>
                  <small className="text-muted">
                    Complete audit record of past and current subscription billings
                  </small>
                </div>
              </div>
              {historyList.length > 0 && (
                <span className="badge bg-light text-muted border text-xs font-mono">
                  {historyList.length} Record{historyList.length !== 1 ? "s" : ""}
                </span>
              )}
            </div>

            {/* Table Body */}
            <div className="card-body p-0">
              {historyList.length > 0 ? (
                <div className="table-responsive">
                  <table className="table table-hover align-middle mb-0">
                    <thead className="table-light text-xs text-uppercase text-muted">
                      <tr>
                        <th className="ps-3 py-3">Plan Details</th>
                        <th className="py-3">Billing Period</th>
                        <th className="py-3">Amount</th>
                        <th className="py-3">Status</th>
                        <th className="pe-3 py-3 text-end">Invoice Action</th>
                      </tr>
                    </thead>
                    <tbody className="text-sm">
                      {historyList.map((item) => {
                        const hasInv = item.has_invoice && item.invoice;
                        return (
                          <tr key={item.id}>
                            {/* Plan Column */}
                            <td className="ps-3 py-3">
                              <span className="fw-semibold text-dark d-block">
                                {item.plan_name}
                              </span>
                              <small className="text-muted text-xs text-capitalize">
                                {item.plan} Billing Cycle
                              </small>
                            </td>

                            {/* Period Column */}
                            <td className="py-3">
                              <span className="text-dark fw-medium d-block">
                                {formatDate(item.start_date)} &mdash; {formatDate(item.end_date)}
                              </span>
                              <small className="text-muted text-xs">
                                {item.plan === "yearly" ? "1-Year License" : "Monthly License"}
                              </small>
                            </td>

                            {/* Amount Column */}
                            <td className="py-3">
                              <span className="fw-bold text-dark">
                                {formatCurrency(item.amount, item.currency)}
                              </span>{" "}
                              <small className="text-muted text-xs">{item.currency}</small>
                            </td>

                            {/* Status Column */}
                            <td className="py-3">
                              <span
                                className={`badge ${
                                  STATUS_BADGES[item.status] || STATUS_BADGES.inactive
                                } text-xs px-2.5 py-1 rounded-pill`}
                              >
                                {item.status_label || item.status}
                              </span>
                            </td>

                            {/* Actions Column */}
                            <td className="pe-3 py-3 text-end">
                              {hasInv ? (
                                <div className="d-inline-flex align-items-center gap-2">
                                  <button
                                    type="button"
                                    className="btn btn-sm btn-outline-primary radius-8 px-3 py-1.5 d-inline-flex align-items-center gap-1.5 shadow-none"
                                    onClick={() => handleViewInvoice(item.invoice.id)}
                                    title="View Invoice Details"
                                  >
                                    <Eye size={14} />
                                    <span>View</span>
                                  </button>
                                  <button
                                    type="button"
                                    className="btn btn-sm btn-primary radius-8 px-3 py-1.5 d-inline-flex align-items-center gap-1.5 text-white shadow-sm"
                                    onClick={() =>
                                      handleDownloadInvoice(
                                        item.invoice.id,
                                        item.invoice.invoice_number
                                      )
                                    }
                                    disabled={downloadingId === item.invoice.id}
                                    title="Download Invoice PDF"
                                  >
                                    {downloadingId === item.invoice.id ? (
                                      <>
                                        <span className="spinner-border spinner-border-sm" role="status" />
                                        <span>Downloading…</span>
                                      </>
                                    ) : (
                                      <>
                                        <Download size={14} className="text-white" />
                                        <span>Download</span>
                                      </>
                                    )}
                                  </button>
                                </div>
                              ) : (
                                <span className="text-muted text-xs fst-italic">—</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              ) : (
                /* Empty state */
                <div className="py-5 text-center">
                  <div className="w-48-px h-48-px bg-light text-muted rounded-circle d-inline-flex align-items-center justify-content-center mx-auto mb-3">
                    <FileText size={24} />
                  </div>
                  <h6 className="fw-bold text-dark mb-1">
                    No previous subscription history found
                  </h6>
                  <p className="text-muted text-sm mb-0">
                    When subscription records are created or renewed, they will be archived here.
                  </p>
                </div>
              )}
            </div>
          </div>


        </>
      )}

      {/* ══════════════════════════════════════════════════════════════════
          6. INVOICE DETAIL MODAL (Clean Standard Modal)
      ══════════════════════════════════════════════════════════════════ */}
      {showInvoiceModal && (
        <div
          className="modal fade show d-block"
          style={{ backgroundColor: "rgba(15, 23, 42, 0.55)", zIndex: 1055 }}
          tabIndex="-1"
          role="dialog"
          aria-modal="true"
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setShowInvoiceModal(false);
              setSelectedInvoice(null);
            }
          }}
        >
          <div className="modal-dialog modal-dialog-centered modal-lg" style={{ maxWidth: "780px" }} role="document">
            <div className="modal-content radius-16 border-0 shadow-lg bg-base">
              {/* Modal Header */}
              <div className="modal-header py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                <div className="d-flex align-items-center gap-2 flex-wrap">
                  <h6 className="modal-title fw-bold text-dark mb-0">
                    Official Invoice: {selectedInvoice?.invoice_number || ""}
                  </h6>
                  {selectedInvoice?.status && (
                    <span
                      className={`badge ${
                        STATUS_BADGES[selectedInvoice.status] || STATUS_BADGES.inactive
                      } text-xs px-2.5 py-1 rounded-pill text-capitalize fw-semibold ms-1`}
                    >
                      {selectedInvoice.status}
                    </span>
                  )}
                </div>
                <button
                  type="button"
                  className="btn-close shadow-none"
                  aria-label="Close"
                  onClick={() => {
                    setShowInvoiceModal(false);
                    setSelectedInvoice(null);
                  }}
                />
              </div>

              {/* Modal Body */}
              <div className="modal-body p-24">
                {invoiceModalLoading ? (
                  <div className="text-center py-5">
                    <div className="spinner-border text-primary mb-2" role="status" />
                    <p className="text-muted text-sm mb-0">Loading invoice details…</p>
                  </div>
                ) : selectedInvoice ? (
                  <div className="d-flex flex-column gap-3">
                    {/* Customer & Invoice Meta Cards */}
                    <div className="row g-3">
                      {/* Billed To Card */}
                      <div className="col-12 col-md-6">
                        <div className="p-3 bg-light bg-opacity-50 border radius-10 h-100 d-flex flex-column">
                          <span className="text-muted text-xs text-uppercase fw-semibold d-block mb-2">
                            Billed To (School)
                          </span>
                          <h6 className="fw-bold text-dark mb-2">
                            {selectedInvoice.customer_name || school?.name || "School Administration"}
                          </h6>
                          <div className="text-xs text-muted d-flex flex-column gap-1.5 mt-auto">
                            {selectedInvoice.customer_email && (
                              <div className="d-flex align-items-center gap-2">
                                <Mail size={13} className="text-primary-600 flex-shrink-0" />
                                <span className="text-break text-dark">{selectedInvoice.customer_email}</span>
                              </div>
                            )}
                            {selectedInvoice.customer_phone && (
                              <div className="d-flex align-items-center gap-2">
                                <Phone size={13} className="text-primary-600 flex-shrink-0" />
                                <span className="text-dark">{selectedInvoice.customer_phone}</span>
                              </div>
                            )}
                            {selectedInvoice.customer_address && (
                              <div className="d-flex align-items-start gap-2">
                                <MapPin size={13} className="text-primary-600 mt-0.5 flex-shrink-0" />
                                <span className="text-dark">{selectedInvoice.customer_address}</span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Invoice Summary Card */}
                      <div className="col-12 col-md-6">
                        <div className="p-3 bg-light bg-opacity-50 border radius-10 h-100 d-flex flex-column justify-content-between">
                          <span className="text-muted text-xs text-uppercase fw-semibold d-block mb-2">
                            Invoice Summary
                          </span>
                          <div className="d-flex flex-column gap-2 text-xs">
                            <div className="d-flex justify-content-between align-items-center">
                              <span className="text-muted">Invoice Number:</span>
                              <span className="fw-bold text-dark font-mono">
                                {selectedInvoice.invoice_number}
                              </span>
                            </div>
                            <div className="d-flex justify-content-between align-items-center">
                              <span className="text-muted">Issue Date:</span>
                              <span className="fw-semibold text-dark">
                                {formatDate(selectedInvoice.issued_at)}
                              </span>
                            </div>
                            <div className="d-flex justify-content-between align-items-center">
                              <span className="text-muted">Billing Period:</span>
                              <span className="fw-semibold text-dark">
                                {formatDate(selectedInvoice.billing_period_start)} &mdash;{" "}
                                {formatDate(selectedInvoice.billing_period_end)}
                              </span>
                            </div>
                            <div className="d-flex justify-content-between align-items-center">
                              <span className="text-muted">Payment Status:</span>
                              <span
                                className={`badge ${
                                  STATUS_BADGES[selectedInvoice.status] || STATUS_BADGES.inactive
                                } text-xs px-2.5 py-0.5 rounded-pill text-capitalize fw-semibold`}
                              >
                                {selectedInvoice.status}
                              </span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Itemized Table */}
                    <div className="border radius-10 overflow-hidden">
                      <table className="table mb-0 align-middle">
                        <thead className="table-light text-xs text-uppercase text-muted">
                          <tr>
                            <th className="py-2.5 px-3">Description / Plan</th>
                            <th className="py-2.5 text-center">Period</th>
                            <th className="py-2.5 text-end px-3">Total</th>
                          </tr>
                        </thead>
                        <tbody className="text-sm">
                          <tr>
                            <td className="py-3 px-3">
                              <span className="fw-semibold text-dark d-block text-capitalize">
                                {selectedInvoice.plan} Subscription
                              </span>
                              <small className="text-muted text-xs">
                                {selectedInvoice.description ||
                                  `Institutional School License for ${
                                    selectedInvoice.customer_name || school?.name || "School"
                                  }`}
                              </small>
                            </td>
                            <td className="py-3 text-center text-xs text-muted">
                              {formatDate(selectedInvoice.billing_period_start)} &mdash;{" "}
                              {formatDate(selectedInvoice.billing_period_end)}
                            </td>
                            <td className="py-3 text-end px-3 fw-bold text-dark font-mono">
                              {formatCurrency(selectedInvoice.subtotal, selectedInvoice.currency)}
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>

                    {/* Payment Info & Grand Total Breakdown */}
                    <div className="row g-3">
                      {/* Left: Payment Info */}
                      <div className="col-12 col-md-6">
                        <div className="p-3 bg-light bg-opacity-50 border radius-10 h-100">
                          <span className="text-muted text-xs text-uppercase fw-semibold d-block mb-2">
                            Payment Details
                          </span>
                          {selectedInvoice.payment ? (
                            <div className="d-flex flex-column gap-2 text-xs">
                              <div className="d-flex justify-content-between align-items-center">
                                <span className="text-muted">Payment Method:</span>
                                <span className="fw-semibold text-dark text-capitalize">
                                  {selectedInvoice.payment.payment_method?.replace(/_/g, " ") ||
                                    "Bank Transfer"}
                                </span>
                              </div>
                              {selectedInvoice.payment.payment_reference && (
                                <div className="d-flex justify-content-between align-items-center">
                                  <span className="text-muted">Transaction Ref:</span>
                                  <span className="fw-semibold text-dark font-mono text-break">
                                    {selectedInvoice.payment.payment_reference}
                                  </span>
                                </div>
                              )}
                              <div className="d-flex justify-content-between align-items-center">
                                <span className="text-muted">Amount Settled:</span>
                                <span className="fw-bold text-success-main font-mono">
                                  {formatCurrency(
                                    selectedInvoice.payment.amount,
                                    selectedInvoice.payment.currency
                                  )}
                                </span>
                              </div>
                              {selectedInvoice.payment.paid_at && (
                                <div className="d-flex justify-content-between align-items-center">
                                  <span className="text-muted">Settlement Date:</span>
                                  <span className="text-dark">
                                    {formatDateTime(selectedInvoice.payment.paid_at)}
                                  </span>
                                </div>
                              )}
                            </div>
                          ) : (
                            <div className="py-3 text-center text-muted text-xs fst-italic">
                              Payment settled under official institutional agreement.
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Right: Total Calculation Box */}
                      <div className="col-12 col-md-6">
                        <div className="p-3 bg-light bg-opacity-50 border radius-10 h-100 d-flex flex-column justify-content-between">
                          <div className="d-flex flex-column gap-2 text-xs">
                            <div className="d-flex justify-content-between text-muted">
                              <span>Subtotal:</span>
                              <span className="font-mono">{formatCurrency(selectedInvoice.subtotal, selectedInvoice.currency)}</span>
                            </div>
                            {Number(selectedInvoice.discount) > 0 && (
                              <div className="d-flex justify-content-between text-success-main">
                                <span>Discount:</span>
                                <span className="font-mono">-{formatCurrency(selectedInvoice.discount, selectedInvoice.currency)}</span>
                              </div>
                            )}
                            {Number(selectedInvoice.tax) > 0 && (
                              <div className="d-flex justify-content-between text-muted">
                                <span>Tax:</span>
                                <span className="font-mono">{formatCurrency(selectedInvoice.tax, selectedInvoice.currency)}</span>
                              </div>
                            )}
                          </div>

                          <div className="mt-2 pt-2 border-top">
                            <div className="d-flex justify-content-between align-items-baseline">
                              <span className="fw-bold text-dark text-sm">Total Paid:</span>
                              <div className="text-end">
                                <span className="fw-bold text-primary fs-5 font-mono">
                                  {formatCurrency(selectedInvoice.total, selectedInvoice.currency)}
                                </span>{" "}
                                <span className="text-muted text-xs fw-semibold">{selectedInvoice.currency}</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ) : null}
              </div>

              {/* Modal Footer */}
              <div className="modal-footer py-16 px-24 border-top d-flex align-items-center justify-content-end gap-2">
                <button
                  type="button"
                  className="btn border border-neutral-300 text-neutral-600 bg-hover-neutral-200 text-sm px-20 py-10 radius-8 fw-medium m-0"
                  onClick={() => {
                    setShowInvoiceModal(false);
                    setSelectedInvoice(null);
                  }}
                >
                  Close
                </button>

                {selectedInvoice && (
                  <button
                    type="button"
                    className="btn btn-primary-600 text-white text-sm px-20 py-10 radius-8 d-inline-flex align-items-center gap-2 fw-medium shadow-sm m-0"
                    onClick={() =>
                      handleDownloadInvoice(
                        selectedInvoice.id,
                        selectedInvoice.invoice_number
                      )
                    }
                    disabled={downloadingId === selectedInvoice.id}
                  >
                    {downloadingId === selectedInvoice.id ? (
                      <>
                        <span className="spinner-border spinner-border-sm" role="status" />
                        <span>Generating PDF…</span>
                      </>
                    ) : (
                      <>
                        <Download size={16} className="text-white" />
                        <span>Download PDF Invoice</span>
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </SchoolLayout>
  );
}
