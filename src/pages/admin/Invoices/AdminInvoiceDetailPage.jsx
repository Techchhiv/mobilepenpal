import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";
import MasterLayout from "../../../masterLayout/MasterLayout";
import invoiceService from "../../../services/invoiceService";

const STATUS_BADGE = {
  paid: "bg-success-focus text-success-main px-12 py-4 radius-4 fw-medium text-xs",
  issued: "bg-warning-focus text-warning-main px-12 py-4 radius-4 fw-medium text-xs",
  void: "bg-danger-focus text-danger-main px-12 py-4 radius-4 fw-medium text-xs",
};

export default function AdminInvoiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [invoice, setInvoice] = useState(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");

  const [voidModal, setVoidModal] = useState(false);
  const [voidReason, setVoidReason] = useState("");
  const [voidDeactivateSubscription, setVoidDeactivateSubscription] = useState(true);
  const [voidLoading, setVoidLoading] = useState(false);
  const [pdfLoading, setPdfLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    invoiceService
      .get(id)
      .then((res) => setInvoice(res.data.data?.invoice || null))
      .catch((e) => setErr(e?.response?.data?.message || "Failed to load invoice"))
      .finally(() => setLoading(false));
  }, [id]);

  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 4000);
  };

  const handleDownloadPdf = async () => {
    setPdfLoading(true);
    try {
      const res = await invoiceService.downloadPdf(id);
      const url = URL.createObjectURL(new Blob([res.data], { type: "application/pdf" }));
      const a = document.createElement("a");
      a.href = url;
      a.download = `${invoice.invoice_number}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      flash("Failed to download PDF", true);
    } finally {
      setPdfLoading(false);
    }
  };

  const handleVoid = async (e) => {
    e.preventDefault();
    if (!voidReason.trim()) return;
    setVoidLoading(true);
    try {
      const res = await invoiceService.void(id, voidReason, voidDeactivateSubscription);
      setInvoice(res.data.data?.invoice || invoice);
      flash(`Invoice ${invoice.invoice_number} voided successfully.`);
      setVoidModal(false);
      setVoidReason("");
    } catch (e) {
      flash(e?.response?.data?.message || "Failed to void invoice", true);
    } finally {
      setVoidLoading(false);
    }
  };

  const fmt = (d) => (d ? new Date(d).toLocaleDateString() : "—");
  const fmtDT = (d) => (d ? new Date(d).toLocaleString() : "—");

  if (loading) {
    return (
      <MasterLayout>
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status" />
          <p className="mt-2 text-muted">Loading invoice…</p>
        </div>
      </MasterLayout>
    );
  }

  if (!invoice) {
    return (
      <MasterLayout>
        <div className="alert alert-danger">{err || "Invoice not found."}</div>
        <button className="btn btn-outline-secondary" onClick={() => navigate(-1)}>
          <Icon icon="mdi:arrow-left" className="me-1" />Back
        </button>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="row gy-4">
        {/* ── Header ── */}
        <div className="col-12">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div className="d-flex align-items-center gap-3">
              <button
                type="button"
                className="w-36-px h-36-px bg-neutral-100 text-neutral-600 rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                onClick={() => navigate(-1)}
                title="Go Back"
              >
                <Icon icon="mdi:arrow-left" className="text-lg" />
              </button>
              <div>
                <h5 className="mb-1 d-flex align-items-center gap-2">
                  <Icon icon="mdi:file-document-outline" className="text-primary-600 fs-4" />
                  {invoice.invoice_number}
                </h5>
                <span className={`badge ${STATUS_BADGE[invoice.status] || ""} text-capitalize`}>
                  {invoice.status}
                </span>
              </div>
            </div>
            <div className="d-flex align-items-center gap-2 flex-wrap">
              <button
                type="button"
                className="btn btn-sm btn-primary-600 px-16 py-8 radius-8 d-inline-flex align-items-center justify-content-center gap-2"
                onClick={handleDownloadPdf}
                disabled={pdfLoading}
              >
                {pdfLoading ? (
                  <><span className="spinner-border spinner-border-sm" /> Generating…</>
                ) : (
                  <><Icon icon="lucide:download" className="text-base" /> Download PDF</>
                )}
              </button>
              {invoice.status !== "void" && (
                <button
                  type="button"
                  className="btn btn-sm btn-danger-600 px-16 py-8 radius-8 d-inline-flex align-items-center justify-content-center gap-2 text-white"
                  onClick={() => setVoidModal(true)}
                >
                  <Icon icon="mdi:cancel" className="text-base text-white" />
                  <span>Void Invoice</span>
                </button>
              )}
            </div>
          </div>
        </div>

        {/* ── Alerts ── */}
        {msg && <div className="col-12"><div className="alert alert-success py-2">{msg}</div></div>}
        {err && <div className="col-12"><div className="alert alert-danger py-2">{err}</div></div>}

        {/* ── Void notice ── */}
        {invoice.status === "void" && (
          <div className="col-12">
            <div className="alert alert-danger">
              <Icon icon="mdi:alert-circle" className="me-2" />
              This invoice was voided on <strong>{fmtDT(invoice.voided_at)}</strong>.
              <br /><strong>Reason:</strong> {invoice.void_reason}
            </div>
          </div>
        )}

        {/* ── Customer & Invoice Info ── */}
        <div className="col-md-6">
          <div className="card h-100">
            <div className="card-header">
              <h6 className="mb-0">
                <Icon icon="mdi:account-outline" className="me-2" />
                Customer Information
              </h6>
            </div>
            <div className="card-body">
              {[
                ["Customer", invoice.customer_name],
                ["Type", <span className="text-capitalize">{invoice.customer_type}</span>],
                ["Email", invoice.customer_email || "—"],
                ["Phone", invoice.customer_phone || "—"],
                ["Address", invoice.customer_address || "—"],
              ].map(([label, val]) => (
                <div key={label} className="d-flex justify-content-between py-1 border-bottom">
                  <span className="text-muted" style={{ fontSize: 13 }}>{label}</span>
                  <span style={{ fontSize: 13 }}>{val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="col-md-6">
          <div className="card h-100">
            <div className="card-header">
              <h6 className="mb-0">
                <Icon icon="mdi:file-document-outline" className="me-2" />
                Invoice Details
              </h6>
            </div>
            <div className="card-body">
              {[
                ["Invoice No", <code>{invoice.invoice_number}</code>],
                ["Plan", <span className="text-capitalize">{invoice.plan}</span>],
                ["Billing Period", `${fmt(invoice.billing_period_start)} – ${fmt(invoice.billing_period_end)}`],
                ["Issued", fmtDT(invoice.issued_at)],
                ["Paid At", fmtDT(invoice.paid_at)],
                ["Created By", `User #${invoice.created_by || "—"}`],
              ].map(([label, val]) => (
                <div key={label} className="d-flex justify-content-between py-1 border-bottom">
                  <span className="text-muted" style={{ fontSize: 13 }}>{label}</span>
                  <span style={{ fontSize: 13 }}>{val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ── Financial Breakdown ── */}
        <div className="col-md-6">
          <div className="card h-100">
            <div className="card-header">
              <h6 className="mb-0">
                <Icon icon="mdi:currency-usd" className="me-2" />
                Amount Breakdown
              </h6>
            </div>
            <div className="card-body">
              {[
                ["Subtotal", `${invoice.currency} ${Number(invoice.subtotal).toFixed(2)}`],
                ["Discount", `- ${invoice.currency} ${Number(invoice.discount).toFixed(2)}`],
                ["Tax", `${invoice.currency} ${Number(invoice.tax).toFixed(2)}`],
              ].map(([label, val]) => (
                <div key={label} className="d-flex justify-content-between py-1 border-bottom">
                  <span className="text-muted" style={{ fontSize: 13 }}>{label}</span>
                  <span style={{ fontSize: 13 }}>{val}</span>
                </div>
              ))}
              <div className="d-flex justify-content-between py-2 mt-1">
                <strong>Total</strong>
                <strong style={{ fontSize: 16, color: "#e94560" }}>
                  {invoice.currency} {Number(invoice.total).toFixed(2)}
                </strong>
              </div>
            </div>
          </div>
        </div>

        {/* ── Payment Info ── */}
        {invoice.payment && (
          <div className="col-md-6">
            <div className="card h-100">
              <div className="card-header">
                <h6 className="mb-0">
                  <Icon icon="mdi:credit-card-outline" className="me-2" />
                  Payment Information
                </h6>
              </div>
              <div className="card-body">
                {[
                  ["Method", invoice.payment.payment_method ? invoice.payment.payment_method.replace(/_/g, " ").toUpperCase() : "—"],
                  ["Reference", invoice.payment.payment_reference || "—"],
                  ["Amount Paid", `${invoice.payment.currency} ${Number(invoice.payment.amount).toFixed(2)}`],
                  ["Paid At", fmtDT(invoice.payment.paid_at)],
                  ["Notes", invoice.payment.notes || "—"],
                ].map(([label, val]) => (
                  <div key={label} className="d-flex justify-content-between py-1 border-bottom">
                    <span className="text-muted" style={{ fontSize: 13 }}>{label}</span>
                    <span style={{ fontSize: 13 }}>{val}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* ── Void Modal ── */}
      {voidModal && (
        <>
          <div className="modal-backdrop fade show"></div>
          <div
            className="modal fade show d-block"
            tabIndex={-1}
            role="dialog"
            aria-modal="true"
            onClick={() => { setVoidModal(false); setVoidReason(""); }}
          >
            <div className="modal-dialog modal-dialog-centered" role="document" onClick={(e) => e.stopPropagation()}>
              <div className="modal-content">
                <div className="modal-header">
                  <h6 className="modal-title text-danger d-flex align-items-center gap-2 mb-0">
                    <Icon icon="mdi:cancel" /> Void Invoice
                  </h6>
                  <button type="button" className="btn-close" onClick={() => { setVoidModal(false); setVoidReason(""); }} />
                </div>
                <form onSubmit={handleVoid}>
                  <div className="modal-body">
                    <div className="alert alert-warning py-2 mb-3">
                      <Icon icon="mdi:alert" className="me-1" />
                      Voiding <strong>{invoice.invoice_number}</strong> is irreversible. The financial record will remain but marked as void.
                    </div>
                    <label className="form-label">Reason <span className="text-danger">*</span></label>
                    <textarea
                      className="form-control"
                      rows={3}
                      required
                      minLength={5}
                      placeholder="Why is this invoice being voided?"
                      value={voidReason}
                      onChange={(e) => setVoidReason(e.target.value)}
                    />

                    {invoice.subscription_id && (
                      <div className="form-check p-3 rounded bg-light border mt-3">
                        <input
                          className="form-check-input ms-0 me-2"
                          type="checkbox"
                          id="voidDeactivateSubCheck"
                          checked={voidDeactivateSubscription}
                          onChange={(e) => setVoidDeactivateSubscription(e.target.checked)}
                        />
                        <label className="form-check-label fw-semibold text-dark cursor-pointer" htmlFor="voidDeactivateSubCheck">
                          Also cancel linked active subscription
                        </label>
                        <div className="text-muted text-xs mt-1 ps-4">
                          Immediately terminates the active subscription associated with this invoice.
                        </div>
                      </div>
                    )}
                  </div>
                  <div className="modal-footer">
                    <button type="button" className="btn btn-light" onClick={() => { setVoidModal(false); setVoidReason(""); }}>Cancel</button>
                    <button type="submit" className="btn btn-danger d-inline-flex align-items-center gap-1" disabled={voidLoading}>
                      {voidLoading ? <><span className="spinner-border spinner-border-sm me-1" />Voiding…</> : <><Icon icon="mdi:cancel" />Void Invoice</>}
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
