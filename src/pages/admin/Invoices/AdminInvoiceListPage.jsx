import React, { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import invoiceService from "../../../services/invoiceService";

const STATUS_BADGE = {
  paid:   "bg-success-focus text-success-main px-12 py-4 radius-4 fw-medium text-xs",
  issued: "bg-warning-focus text-warning-main px-12 py-4 radius-4 fw-medium text-xs",
  void:   "bg-danger-focus text-danger-main px-12 py-4 radius-4 fw-medium text-xs",
};

const PLAN_BADGE = {
  monthly: "bg-primary-light text-primary-600 px-12 py-4 radius-4 fw-medium text-xs",
  yearly:  "bg-info-focus text-info-main px-12 py-4 radius-4 fw-medium text-xs",
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
    customer_name:  "",
    customer_type:  "",
    status:         "",
    plan:           "",
    date_from:      "",
    date_to:        "",
    per_page:       20,
    page:           1,
  });

  const [voidModal, setVoidModal] = useState(null); // { id, invoice_number }
  const [voidReason, setVoidReason] = useState("");
  const [voidLoading, setVoidLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      // Strip empty values
      const params = Object.fromEntries(
        Object.entries(filters).filter(([, v]) => v !== "" && v !== null)
      );
      const res = await invoiceService.list(params);
      const d = res.data;
      setInvoices(d.data || []);
      setMeta(d.meta || null);
    } catch (e) {
      setErr(e?.response?.data?.message || "Failed to load invoices");
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
      flash("Failed to download PDF", true);
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

  const formatDate = (iso) => (iso ? new Date(iso).toLocaleDateString() : "—");
  const formatAmount = (amt, curr = "USD") =>
    `${curr} ${Number(amt || 0).toFixed(2)}`;

  return (
    <MasterLayout>
      <div className="row gy-4">
        <div className="col-12">
          {/* ── Header ── */}
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
            <div>
              <h5 className="mb-1 d-flex align-items-center gap-2">
                <Icon icon="mdi:file-document-outline" className="text-primary-600 fs-4" />
                Invoices
              </h5>
              <p className="text-muted mb-0 text-sm">
                Financial billing records for all subscriptions
              </p>
            </div>
          </div>

          {/* ── Alerts ── */}
          {msg && <div className="alert alert-success py-2 mb-3">{msg}</div>}
          {err && <div className="alert alert-danger py-2 mb-3">{err}</div>}

          {/* ── Filters ── */}
          <div className="card mb-3">
            <div className="card-body p-3">
              <div className="row g-2 align-items-end">
                <div className="col-12 col-sm-6 col-md-3">
                  <label className="form-label text-xs fw-medium mb-1">Invoice #</label>
                  <input
                    className="form-control form-control-sm"
                    placeholder="INV-2026-…"
                    value={filters.invoice_number}
                    onChange={(e) => handleFilter("invoice_number", e.target.value)}
                  />
                </div>
                <div className="col-12 col-sm-6 col-md-3">
                  <label className="form-label text-xs fw-medium mb-1">Customer Name</label>
                  <input
                    className="form-control form-control-sm"
                    placeholder="Name…"
                    value={filters.customer_name}
                    onChange={(e) => handleFilter("customer_name", e.target.value)}
                  />
                </div>
                <div className="col-6 col-sm-4 col-md-2">
                  <label className="form-label text-xs fw-medium mb-1">Type</label>
                  <select
                    className="form-select form-select-sm"
                    value={filters.customer_type}
                    onChange={(e) => handleFilter("customer_type", e.target.value)}
                  >
                    <option value="">All</option>
                    <option value="school">School</option>
                    <option value="student">Student</option>
                  </select>
                </div>
                <div className="col-6 col-sm-4 col-md-2">
                  <label className="form-label text-xs fw-medium mb-1">Status</label>
                  <select
                    className="form-select form-select-sm"
                    value={filters.status}
                    onChange={(e) => handleFilter("status", e.target.value)}
                  >
                    <option value="">All</option>
                    <option value="paid">Paid</option>
                    <option value="issued">Issued</option>
                    <option value="void">Void</option>
                  </select>
                </div>
                <div className="col-6 col-sm-4 col-md-2">
                  <label className="form-label text-xs fw-medium mb-1">Plan</label>
                  <select
                    className="form-select form-select-sm"
                    value={filters.plan}
                    onChange={(e) => handleFilter("plan", e.target.value)}
                  >
                    <option value="">All</option>
                    <option value="monthly">Monthly</option>
                    <option value="yearly">Yearly</option>
                  </select>
                </div>
                <div className="col-12 col-sm-6 col-md-3">
                  <label className="form-label text-xs fw-medium mb-1">From Date</label>
                  <input
                    type="date"
                    className="form-control form-control-sm"
                    value={filters.date_from}
                    onChange={(e) => handleFilter("date_from", e.target.value)}
                  />
                </div>
                <div className="col-12 col-sm-6 col-md-3">
                  <label className="form-label text-xs fw-medium mb-1">To Date</label>
                  <input
                    type="date"
                    className="form-control form-control-sm"
                    value={filters.date_to}
                    onChange={(e) => handleFilter("date_to", e.target.value)}
                  />
                </div>
                <div className="col-auto">
                  <button
                    type="button"
                    className="btn btn-sm btn-outline-secondary d-inline-flex align-items-center justify-content-center gap-1 px-3"
                    style={{ height: 32 }}
                    onClick={() =>
                      setFilters({
                        invoice_number: "", customer_name: "", customer_type: "",
                        status: "", plan: "", date_from: "", date_to: "",
                        per_page: 20, page: 1,
                      })
                    }
                  >
                    <Icon icon="mdi:refresh" className="fs-6" />
                    <span>Clear</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* ── Table ── */}
          <div className="card">
            <div className="card-body p-0">
              {loading ? (
                <div className="text-center py-5">
                  <div className="spinner-border text-primary" role="status" />
                  <p className="mt-2 text-muted">Loading invoices…</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <table className="table bordered-table mb-0">
                    <thead>
                      <tr>
                        <th>Invoice</th>
                        <th>Customer</th>
                        <th>Type</th>
                        <th>Plan</th>
                        <th>Billing Period</th>
                        <th>Amount</th>
                        <th>Method</th>
                        <th>Issued</th>
                        <th>Status</th>
                        <th style={{ width: 130 }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {invoices.map((inv) => (
                        <tr key={inv.id}>
                          <td>
                            <span className="fw-semibold" style={{ fontSize: 13, fontFamily: "monospace" }}>
                              {inv.invoice_number}
                            </span>
                          </td>
                          <td className="fw-semibold" style={{ maxWidth: 160, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                            {inv.customer_name}
                          </td>
                          <td>
                            <span className="badge bg-neutral-200 text-neutral-600 text-capitalize px-12 py-4 radius-4 fw-medium text-xs">
                              {inv.customer_type}
                            </span>
                          </td>
                          <td>
                            <span className={`badge text-capitalize ${PLAN_BADGE[inv.plan] || "bg-neutral-100"}`}>
                              {inv.plan}
                            </span>
                          </td>
                          <td style={{ fontSize: 12 }}>
                            {formatDate(inv.billing_period_start)} –<br />
                            {formatDate(inv.billing_period_end)}
                          </td>
                          <td className="fw-semibold" style={{ color: "#e94560", fontSize: 13 }}>
                            {formatAmount(inv.total, inv.currency)}
                          </td>
                          <td style={{ fontSize: 12 }}>
                            {inv.payment?.payment_method ? inv.payment.payment_method.replace(/_/g, " ").toUpperCase() : "—"}
                          </td>
                          <td style={{ fontSize: 12 }}>
                            {formatDate(inv.issued_at)}
                          </td>
                          <td>
                            <span className={`badge text-capitalize ${STATUS_BADGE[inv.status] || ""}`}>
                              {inv.status}
                            </span>
                          </td>
                          <td>
                            <div className="d-flex align-items-center gap-2">
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
                      {!invoices.length && (
                        <tr>
                          <td colSpan={10} className="text-center text-muted py-5">
                            <Icon icon="mdi:file-document-off-outline" style={{ fontSize: 32 }} />
                            <p className="mt-2 mb-0">No invoices found.</p>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}

              {/* ── Pagination ── */}
              {meta && meta.last_page > 1 && (
                <div className="d-flex justify-content-between align-items-center px-4 py-3 border-top flex-wrap gap-2">
                  <span className="text-muted text-sm">
                    Showing {meta.from}–{meta.to} of {meta.total} invoices
                  </span>
                  <div className="d-flex align-items-center gap-2">
                    <button
                      className="w-32-px h-32-px bg-neutral-100 text-neutral-600 rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                      disabled={meta.current_page === 1}
                      onClick={() => setFilters((f) => ({ ...f, page: f.page - 1 }))}
                    >
                      <Icon icon="mdi:chevron-left" />
                    </button>
                    <span className="text-sm px-2 fw-medium">
                      {meta.current_page} / {meta.last_page}
                    </span>
                    <button
                      className="w-32-px h-32-px bg-neutral-100 text-neutral-600 rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                      disabled={meta.current_page === meta.last_page}
                      onClick={() => setFilters((f) => ({ ...f, page: f.page + 1 }))}
                    >
                      <Icon icon="mdi:chevron-right" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

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
    </MasterLayout>
  );
}
