import React, { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import invoiceService from "../../../services/invoiceService";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../../components/admin/common/AdminErrorState";
import AdminPagination from "../../../components/admin/common/AdminPagination";

const STATUS_BADGE = {
  paid: "status-badge status-badge-active",
  issued: "status-badge status-badge-scheduled",
  void: "status-badge status-badge-expired",
};

const PLAN_BADGE = {
  monthly: "plan-badge plan-badge-monthly",
  yearly: "plan-badge plan-badge-yearly",
};

export default function AdminInvoiceListPage() {
  const navigate = useNavigate();

  const [invoices, setInvoices] = useState([]);
  const [meta, setMeta] = useState(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");

  // Filters
  const [filters, setFilters] = useState({
    invoice_number: "",
    customer_name: "",
    customer_type: "",
    status: "",
    plan: "",
    date_from: "",
    date_to: "",
    per_page: 20,
    page: 1,
  });

  const [voidModal, setVoidModal] = useState(null); // { id, invoice_number }
  const [voidReason, setVoidReason] = useState("");
  const [voidLoading, setVoidLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setErr("");
    try {
      const params = Object.fromEntries(
        Object.entries(filters).filter(([, v]) => v !== "" && v !== null)
      );
      const res = await invoiceService.list(params);
      const d = res.data;
      setInvoices(d.data || []);
      setMeta(d.meta || null);
    } catch (e) {
      setErr(e?.response?.data?.message || "Failed to load invoices from server.");
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    load();
  }, [load]);

  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 4000);
  };

  const handleFilter = (key, value) => {
    setFilters((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleDownloadPdf = async (invoiceId, invoiceNumber) => {
    try {
      const res = await invoiceService.downloadPdf(invoiceId);
      const url = URL.createObjectURL(new Blob([res.data], { type: "application/pdf" }));
      const a = document.createElement("a");
      a.href = url;
      a.download = `${invoiceNumber}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      flash("Failed to download PDF document", true);
    }
  };

  const handleVoid = async (e) => {
    e.preventDefault();
    if (!voidModal || !voidReason.trim()) return;
    setVoidLoading(true);
    try {
      await invoiceService.void(voidModal.id, voidReason);
      flash(`Invoice ${voidModal.invoice_number} voided successfully.`);
      setVoidModal(null);
      setVoidReason("");
      await load();
    } catch (e) {
      flash(e?.response?.data?.message || "Failed to void invoice", true);
    } finally {
      setVoidLoading(false);
    }
  };

  const formatDate = (iso) => (iso ? new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) : "—");
  const formatAmount = (amt, curr = "USD") => `$${Number(amt || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  return (
    <MasterLayout>
      <div className="py-12">
        {/* ── Header ── */}
        <AdminPageHeader
          title="Invoices"
          subtitle="Financial billing records and subscription invoicing across all clients"
        />

        {/* ── Alerts ── */}
        {msg && <div className="alert alert-success py-12 px-16 radius-8 text-sm mb-16">{msg}</div>}

        {err && !invoices.length && !loading ? (
          <AdminErrorState
            title="Failed to Load Invoices"
            message={err}
            onRetry={load}
          />
        ) : (
          <>
            {/* ── Filters ── */}
            <div className="card border radius-12 shadow-none mb-20">
              <div className="card-body p-20">
                <div className="row g-12 align-items-end">
                  <div className="col-12 col-sm-6 col-md-3">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">Invoice #</label>
                    <input
                      className="form-control form-control-sm radius-8 "
                      placeholder="e.g. INV-2026-0001"
                      value={filters.invoice_number}
                      onChange={(e) => handleFilter("invoice_number", e.target.value)}
                    />
                  </div>
                  <div className="col-12 col-sm-6 col-md-3">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">Customer Name</label>
                    <input
                      className="form-control form-control-sm radius-8"
                      placeholder="Search customer..."
                      value={filters.customer_name}
                      onChange={(e) => handleFilter("customer_name", e.target.value)}
                    />
                  </div>
                  <div className="col-6 col-sm-4 col-md-2">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">Type</label>
                    <select
                      className="form-select form-select-sm radius-8"
                      value={filters.customer_type}
                      onChange={(e) => handleFilter("customer_type", e.target.value)}
                    >
                      <option value="">All Types</option>
                      <option value="school">School</option>
                      <option value="student">Student</option>
                    </select>
                  </div>
                  <div className="col-6 col-sm-4 col-md-2">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">Status</label>
                    <select
                      className="form-select form-select-sm radius-8"
                      value={filters.status}
                      onChange={(e) => handleFilter("status", e.target.value)}
                    >
                      <option value="">All Statuses</option>
                      <option value="paid">Paid</option>
                      <option value="issued">Issued / Pending</option>
                      <option value="void">Void</option>
                    </select>
                  </div>
                  <div className="col-6 col-sm-4 col-md-2">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">Plan</label>
                    <select
                      className="form-select form-select-sm radius-8"
                      value={filters.plan}
                      onChange={(e) => handleFilter("plan", e.target.value)}
                    >
                      <option value="">All Plans</option>
                      <option value="monthly">Monthly</option>
                      <option value="yearly">Yearly</option>
                    </select>
                  </div>
                  <div className="col-12 col-sm-6 col-md-3">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">From Date</label>
                    <input
                      type="date"
                      className="form-control form-control-sm radius-8"
                      value={filters.date_from}
                      onChange={(e) => handleFilter("date_from", e.target.value)}
                    />
                  </div>
                  <div className="col-12 col-sm-6 col-md-3">
                    <label className="form-label text-xs fw-medium text-secondary-light mb-4">To Date</label>
                    <input
                      type="date"
                      className="form-control form-control-sm radius-8"
                      value={filters.date_to}
                      onChange={(e) => handleFilter("date_to", e.target.value)}
                    />
                  </div>
                  <div className="col-auto">
                    <button
                      type="button"
                      className="btn btn-sm btn-outline-secondary radius-8 d-inline-flex align-items-center gap-6"
                      onClick={() =>
                        setFilters({
                          invoice_number: "", customer_name: "", customer_type: "",
                          status: "", plan: "", date_from: "", date_to: "",
                          per_page: 20, page: 1,
                        })
                      }
                    >
                      <Icon icon="mdi:refresh" className="text-base" />
                      <span>Clear</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* ── Table Card ── */}
            <div className="card border radius-12 shadow-none overflow-hidden">
              <div className="card-body p-0">
                {loading ? (
                  <div className="placeholder-glow d-flex flex-column gap-12 p-24">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <span key={i} className="placeholder col-12 radius-8" style={{ height: "48px" }}></span>
                    ))}
                  </div>
                ) : invoices.length === 0 ? (
                  <AdminEmptyState
                    icon="mdi:file-document-outline"
                    title="No invoices found"
                    message="No invoice billing records match the selected filters."
                  />
                ) : (
                  <div className="table-responsive">
                    <table className="table bordered-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Invoice #</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Customer</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Type</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Plan</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Billing Period</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Amount</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Method</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Issued</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Status</th>
                          <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {invoices.map((inv) => (
                          <tr key={inv.id}>
                            <td className="px-16">
                              <span className="fw-semibold" style={{ fontSize: 13, fontFamily: "monospace" }}>
                                {inv.invoice_number}
                              </span>
                            </td>
                            <td className="fw-semibold px-16" style={{ maxWidth: 160, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                              {inv.customer_name}
                            </td>
                            <td className="px-16">
                              <span className="badge bg-neutral-200 text-neutral-600 text-capitalize px-12 py-4 radius-4 fw-medium text-xs">
                                {inv.customer_type}
                              </span>
                            </td>
                            <td className="px-16">
                              <span className={`badge text-capitalize ${PLAN_BADGE[inv.plan] || "bg-neutral-100"}`}>
                                {inv.plan}
                              </span>
                            </td>
                            <td className="px-16" style={{ fontSize: 12 }}>
                              {formatDate(inv.billing_period_start)} –<br />
                              {formatDate(inv.billing_period_end)}
                            </td>
                            <td className="fw-bold text-primary-600 px-16">
                              {formatAmount(inv.total, inv.currency)}
                            </td>
                            <td className="px-16" style={{ fontSize: 12 }}>
                              {inv.payment?.payment_method ? inv.payment.payment_method.replace(/_/g, " ").toUpperCase() : "—"}
                            </td>
                            <td className="px-16" style={{ fontSize: 12 }}>
                              {formatDate(inv.issued_at)}
                            </td>
                            <td className="px-16">
                              <span className={`badge text-capitalize ${STATUS_BADGE[inv.status] || ""}`}>
                                {inv.status}
                              </span>
                            </td>
                            <td className="pe-16 text-end">
                              <div className="d-flex align-items-center justify-content-end gap-2">
                                <button
                                  type="button"
                                  className="btn btn-sm btn-outline-primary p-0 rounded-circle d-inline-flex align-items-center justify-content-center"
                                  style={{ width: 32, height: 32 }}
                                  title="View Invoice"
                                  onClick={() => navigate(`/admin/invoices/${inv.id}`)}
                                >
                                  <Icon icon="iconamoon:eye-light" style={{ fontSize: 16 }} />
                                </button>
                                <button
                                  type="button"
                                  className="btn btn-sm btn-outline-success p-0 rounded-circle d-inline-flex align-items-center justify-content-center"
                                  style={{ width: 32, height: 32 }}
                                  title="Download PDF"
                                  onClick={() => handleDownloadPdf(inv.id, inv.invoice_number)}
                                >
                                  <Icon icon="lucide:download" style={{ fontSize: 15 }} />
                                </button>
                                {inv.status !== "void" && (
                                  <button
                                    type="button"
                                    className="btn btn-sm btn-outline-danger p-0 rounded-circle d-inline-flex align-items-center justify-content-center text-danger"
                                    style={{ width: 32, height: 32 }}
                                    title="Void Invoice"
                                    onClick={() => setVoidModal({ id: inv.id, invoice_number: inv.invoice_number })}
                                  >
                                    <Icon icon="mingcute:delete-2-line" style={{ fontSize: 16, color: "#dc3545" }} />
                                  </button>
                                )}
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>

              {/* ── Card Footer Pagination ── */}
              {meta && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {meta.from ?? 0}–{meta.to ?? 0} of {meta.total ?? 0} entries
                  </div>
                  {meta.last_page > 1 && (
                    <div className="ms-auto">
                      <AdminPagination
                        page={meta.current_page}
                        totalPages={meta.last_page}
                        onPageChange={(p) => setFilters((f) => ({ ...f, page: p }))}
                      />
                    </div>
                  )}
                </div>
              )}
            </div>
          </>
        )}

        {/* ── Void Invoice Modal ── */}
        {voidModal && (
          <>
            <div className="modal-backdrop fade show"></div>
            <div
              className="modal fade show d-block"
              tabIndex={-1}
              role="dialog"
              aria-modal="true"
              onClick={() => { setVoidModal(null); setVoidReason(""); }}
            >
              <div className="modal-dialog modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
                <div className="modal-content">
                  <div className="modal-header">
                    <h6 className="modal-title d-flex align-items-center gap-2 text-danger mb-0">
                      <Icon icon="mdi:cancel" />
                      Void Invoice
                    </h6>
                    <button type="button" className="btn-close" onClick={() => { setVoidModal(null); setVoidReason(""); }} />
                  </div>
                  <form onSubmit={handleVoid}>
                    <div className="modal-body">
                      <div className="alert alert-warning py-2 mb-3">
                        <Icon icon="mdi:alert" className="me-1" />
                        Voiding <strong>{voidModal.invoice_number}</strong> is irreversible. The record will remain but marked as void.
                      </div>
                      <label className="form-label">Reason for voiding <span className="text-danger">*</span></label>
                      <textarea
                        className="form-control"
                        rows={3}
                        required
                        minLength={5}
                        placeholder="Explain why this invoice is being voided…"
                        value={voidReason}
                        onChange={(e) => setVoidReason(e.target.value)}
                      />
                    </div>
                    <div className="modal-footer">
                      <button type="button" className="btn btn-light" onClick={() => { setVoidModal(null); setVoidReason(""); }}>
                        Cancel
                      </button>
                      <button type="submit" className="btn btn-danger d-inline-flex align-items-center gap-1" disabled={voidLoading}>
                        {voidLoading ? (
                          <><span className="spinner-border spinner-border-sm me-1" />Voiding…</>
                        ) : (
                          <><Icon icon="mdi:cancel" />Void Invoice</>
                        )}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </MasterLayout>
  );
}
