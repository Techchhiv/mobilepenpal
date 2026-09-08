import React, { useEffect, useState, useCallback } from "react";
import { Icon } from "@iconify/react";
import SchoolLayout from "../masterLayout/SchoolLayout";
import Breadcrumb from "../../../components/Breadcrumb";
import API from "../../../helper/api";
import {
  calculateRemainingDays,
  getExpirationLevel,
  formatSubscriptionDate,
  formatPlanName,
} from "../../../utils/subscriptionUtils";

export default function SchoolSubscriptionBillingPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [downloadingId, setDownloadingId] = useState(null);
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [flashMessage, setFlashMessage] = useState({ text: "", isError: false });

  const flash = (text, isError = false) => {
    setFlashMessage({ text, isError });
    setTimeout(() => setFlashMessage({ text: "", isError: false }), 4000);
  };

  const fetchSubscriptionData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await API.get("/school/subscription");
      if (res.data?.success) {
        setData(res.data.data);
      } else {
        setError(res.data?.message || "Unable to load subscription information.");
      }
    } catch (err) {
      console.error("Error fetching school subscription:", err);
      setError(
        err?.response?.data?.message ||
          "Unable to load subscription information. Please try again later."
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSubscriptionData();
  }, [fetchSubscriptionData]);

  const handleDownloadPdf = async (invoiceId, invoiceNumber) => {
    setDownloadingId(invoiceId);
    try {
      const res = await API.get(`/school/invoices/${invoiceId}/pdf`, {
        responseType: "blob",
      });
      const url = URL.createObjectURL(new Blob([res.data], { type: "application/pdf" }));
      const a = document.createElement("a");
      a.href = url;
      a.download = `${invoiceNumber || "invoice"}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
      flash(`Invoice ${invoiceNumber} downloaded successfully.`);
    } catch (err) {
      console.error("Error downloading invoice PDF:", err);
      flash("Failed to download invoice PDF. Please try again.", true);
    } finally {
      setDownloadingId(null);
    }
  };

  const currentSub = data?.current_subscription;
  const history = data?.subscriptions || [];
  const invoices = data?.invoices || [];
  const contact = data?.support_contact || {
    email: "info@khmerpenpal.com",
    phone: "+855 935 248 60",
  };

  const hasSubscription = Boolean(currentSub?.has_subscription);
  const isExpired = Boolean(currentSub?.is_expired);
  const rawEndDate = currentSub?.end_date || null;
  const rawStartDate = currentSub?.start_date || null;

  const remainingDays = rawEndDate
    ? calculateRemainingDays(rawEndDate)
    : (currentSub?.days_left ?? 0);

  const level = getExpirationLevel(remainingDays, isExpired, hasSubscription);

  return (
    <SchoolLayout>
      <Breadcrumb title="Subscription & Billing" />

      {/* Flash Alert */}
      {flashMessage.text && (
        <div
          className={`alert ${
            flashMessage.isError ? "alert-danger" : "alert-success"
          } alert-dismissible fade show radius-8 mb-24`}
          role="alert"
        >
          <div className="d-flex align-items-center gap-2">
            <Icon
              icon={
                flashMessage.isError
                  ? "solar:danger-triangle-bold"
                  : "solar:check-circle-bold"
              }
              className="text-lg flex-shrink-0"
            />
            <span>{flashMessage.text}</span>
          </div>
          <button
            type="button"
            className="btn-close"
            onClick={() => setFlashMessage({ text: "", isError: false })}
          ></button>
        </div>
      )}

      {loading ? (
        <div
          className="d-flex justify-content-center align-items-center bg-white radius-12 p-5 border shadow-none mb-24"
          style={{ minHeight: "350px" }}
        >
          <div className="text-center">
            <div className="spinner-border text-primary mb-3" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
            <p className="text-muted text-sm mb-0">Loading subscription and billing records...</p>
          </div>
        </div>
      ) : error ? (
        <div className="card border radius-12 shadow-none bg-white mb-24">
          <div className="card-body p-4 text-center">
            <div className="w-48-px h-48-px rounded-circle bg-danger-50 text-danger d-flex align-items-center justify-content-center mx-auto mb-3">
              <Icon icon="solar:danger-triangle-bold" className="text-2xl" />
            </div>
            <h5 className="mb-2 fw-bold text-danger">Failed to Load Subscription Details</h5>
            <p className="text-muted text-sm mb-3">{error}</p>
            <button
              onClick={fetchSubscriptionData}
              className="btn btn-sm btn-primary radius-8 px-3 py-2 d-inline-flex align-items-center gap-2"
            >
              <Icon icon="solar:restart-bold" />
              <span>Retry</span>
            </button>
          </div>
        </div>
      ) : (
        <>
          {/* 1. CURRENT SUBSCRIPTION CARD */}
          <div className="card border radius-12 shadow-none bg-white mb-24">
            <div className="card-header bg-white border-bottom py-16 px-24 d-flex align-items-center justify-content-between flex-wrap gap-2">
              <div className="d-flex align-items-center gap-3">
                <div className="w-40-px h-40-px bg-primary-50 text-primary-600 rounded-circle d-flex align-items-center justify-content-center">
                  <Icon icon="solar:card-2-bold-duotone" className="text-xl" />
                </div>
                <div>
                  <h6 className="mb-0 fw-bold text-dark">Current Subscription</h6>
                  <span className="text-secondary-light text-xs">Active plan overview & renewal status</span>
                </div>
              </div>

              <div>
                {level === "none" && (
                  <span className="badge bg-secondary-focus text-secondary-main px-12 py-4 radius-6 fw-semibold text-xs">
                    No Active Subscription
                  </span>
                )}
                {level === "expired" && (
                  <span className="badge bg-danger-focus text-danger-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                    <Icon icon="solar:close-circle-bold" /> Expired
                  </span>
                )}
                {level === "critical" && (
                  <span className="badge bg-danger-focus text-danger-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                    <Icon icon="solar:alarm-play-bold" /> Critical ({remainingDays} {remainingDays === 1 ? "day" : "days"} left)
                  </span>
                )}
                {level === "warning" && (
                  <span className="badge bg-warning-focus text-warning-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                    <Icon icon="solar:clock-circle-outline" /> Expiring Soon ({remainingDays} days left)
                  </span>
                )}
                {level === "normal" && (
                  <span className="badge bg-success-focus text-success-main px-12 py-4 radius-6 fw-semibold text-xs d-inline-flex align-items-center gap-1">
                    <Icon icon="solar:verified-check-bold" /> Active
                  </span>
                )}
              </div>
            </div>

            <div className="card-body p-20 p-md-24">
              {/* Expiration Reminder Alert */}
              {level === "critical" && (
                <div className="alert bg-danger-focus border border-danger-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-20 text-danger-main">
                  <Icon icon="solar:danger-triangle-bold" className="text-xl flex-shrink-0 mt-1" />
                  <div>
                    <strong className="d-block mb-1 text-danger-main fw-semibold text-sm">
                      ⚠ Subscription Expiring Soon
                    </strong>
                    <span className="text-sm text-secondary-light">
                      Your subscription expires in {remainingDays} {remainingDays === 1 ? "day" : "days"}. Please contact Khmer PenPal to renew your subscription.
                    </span>
                  </div>
                </div>
              )}

              {level === "warning" && (
                <div className="alert bg-warning-focus border border-warning-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-20 text-warning-main">
                  <Icon icon="solar:bell-bing-bold" className="text-xl flex-shrink-0 mt-1" />
                  <div>
                    <strong className="d-block mb-1 text-warning-main fw-semibold text-sm">
                      ⚠ Subscription Expiring Soon
                    </strong>
                    <span className="text-sm text-secondary-light">
                      Your subscription expires in {remainingDays} days. Please contact Khmer PenPal if you would like to renew your subscription.
                    </span>
                  </div>
                </div>
              )}

              {level === "expired" && (
                <div className="alert bg-danger-focus border border-danger-border radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-20 text-danger-main">
                  <Icon icon="solar:danger-triangle-bold" className="text-xl flex-shrink-0 mt-1" />
                  <div>
                    <strong className="d-block mb-1 text-danger-main fw-semibold text-sm">
                      Subscription Expired
                    </strong>
                    <span className="text-sm text-secondary-light">
                      Your subscription expired on {formatSubscriptionDate(rawEndDate)}. Please contact Khmer PenPal for subscription assistance.
                    </span>
                  </div>
                </div>
              )}

              {level === "none" && (
                <div className="alert bg-neutral-100 border border-neutral-200 radius-8 p-12 px-16 d-flex align-items-start gap-2 mb-20 text-secondary">
                  <Icon icon="solar:info-circle-bold" className="text-xl flex-shrink-0 mt-1" />
                  <div>
                    <strong className="d-block mb-1 text-dark fw-semibold text-sm">
                      No Active Subscription
                    </strong>
                    <span className="text-sm text-secondary-light">
                      There is currently no active subscription associated with your school. Please contact Khmer PenPal for assistance.
                    </span>
                  </div>
                </div>
              )}

              {/* Subscription Metric Cards */}
              <div className="row g-3 mb-24">
                <div className="col-12 col-sm-6 col-lg-3">
                  <div className="p-20 bg-neutral-50 border border-neutral-200 radius-12 h-100">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <span className="text-secondary-light text-xs text-uppercase fw-semibold tracking-wider">
                        Current Plan
                      </span>
                      <div className="w-36-px h-36-px bg-primary-50 text-primary-600 rounded-circle d-flex align-items-center justify-content-center">
                        <Icon icon="solar:crown-line-bold-duotone" className="text-lg" />
                      </div>
                    </div>
                    <h5 className="mb-1 fw-bold text-dark">
                      {hasSubscription ? formatPlanName(currentSub.plan) : "None"}
                    </h5>
                    <span className="text-muted text-xs">
                      {hasSubscription ? (isExpired ? "Expired Plan" : "Active Subscription") : "No active tier"}
                    </span>
                  </div>
                </div>

                <div className="col-12 col-sm-6 col-lg-3">
                  <div className="p-20 bg-neutral-50 border border-neutral-200 radius-12 h-100">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <span className="text-secondary-light text-xs text-uppercase fw-semibold tracking-wider">
                        Start Date
                      </span>
                      <div className="w-36-px h-36-px bg-purple-50 text-purple rounded-circle d-flex align-items-center justify-content-center">
                        <Icon icon="solar:calendar-date-bold-duotone" className="text-lg" />
                      </div>
                    </div>
                    <h6 className="mb-1 fw-bold text-dark">
                      {formatSubscriptionDate(rawStartDate)}
                    </h6>
                    <span className="text-muted text-xs">Initial activation date</span>
                  </div>
                </div>

                <div className="col-12 col-sm-6 col-lg-3">
                  <div className="p-20 bg-neutral-50 border border-neutral-200 radius-12 h-100">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <span className="text-secondary-light text-xs text-uppercase fw-semibold tracking-wider">
                        Expiration Date
                      </span>
                      <div className="w-36-px h-36-px bg-info-50 text-info rounded-circle d-flex align-items-center justify-content-center">
                        <Icon icon="solar:calendar-mark-bold-duotone" className="text-lg" />
                      </div>
                    </div>
                    <h6 className="mb-1 fw-bold text-dark">
                      {formatSubscriptionDate(rawEndDate)}
                    </h6>
                    <span className="text-muted text-xs">Renewal / Expiration target</span>
                  </div>
                </div>

                <div className="col-12 col-sm-6 col-lg-3">
                  <div className="p-20 bg-neutral-50 border border-neutral-200 radius-12 h-100">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <span className="text-secondary-light text-xs text-uppercase fw-semibold tracking-wider">
                        Remaining Days
                      </span>
                      <div className={`w-36-px h-36-px ${
                        level === "critical"
                          ? "bg-danger-50 text-danger"
                          : level === "warning"
                          ? "bg-warning-50 text-warning-main"
                          : level === "expired"
                          ? "bg-neutral-100 text-secondary"
                          : "bg-success-50 text-success"
                      } rounded-circle d-flex align-items-center justify-content-center`}>
                        <Icon icon="solar:hourglass-bold-duotone" className="text-lg" />
                      </div>
                    </div>
                    <h5
                      className={`mb-1 fw-bold ${
                        level === "critical"
                          ? "text-danger"
                          : level === "warning"
                          ? "text-warning-main"
                          : level === "expired"
                          ? "text-muted"
                          : "text-success"
                      }`}
                    >
                      {level === "expired"
                        ? "Expired"
                        : level === "none"
                        ? "—"
                        : `${remainingDays} days`}
                    </h5>
                    <span className="text-muted text-xs">
                      {level === "expired"
                        ? "Subscription has expired"
                        : level === "none"
                        ? "No active period"
                        : remainingDays <= 7
                        ? "Critical renewal window"
                        : remainingDays <= 30
                        ? "Approaching expiration"
                        : "Coverage in good standing"}
                    </span>
                  </div>
                </div>
              </div>

              {/* Renewal Guidance & Support Contact Card */}
              <div className="p-20 rounded bg-gradient-start-1 border d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div className="d-flex align-items-center gap-3">
                  <div className="w-44-px h-44-px rounded-circle bg-white text-primary-600 d-flex align-items-center justify-content-center shadow-none border flex-shrink-0">
                    <Icon icon="solar:headphones-round-bold-duotone" className="text-2xl" />
                  </div>
                  <div>
                    <h6 className="mb-1 fw-bold text-dark">
                      Need to renew or update your school subscription?
                    </h6>
                    <p className="mb-0 text-secondary-light text-sm">
                      Please reach out to Khmer PenPal customer support for renewal assistance, custom invoicing, or payment questions.
                    </p>
                  </div>
                </div>

                <div className="d-flex flex-wrap align-items-center gap-2">
                  <a
                    href={`mailto:${contact.email}`}
                    className="btn btn-sm btn-white text-primary-600 border bg-white radius-8 px-16 py-8 d-inline-flex align-items-center gap-2 fw-medium shadow-none"
                  >
                    <Icon icon="solar:letter-bold-duotone" className="text-lg" />
                    <span>{contact.email}</span>
                  </a>
                  <a
                    href={`tel:${contact.phone}`}
                    className="btn btn-sm btn-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-2 fw-medium"
                  >
                    <Icon icon="solar:phone-calling-bold-duotone" className="text-lg" />
                    <span>{contact.phone}</span>
                  </a>
                </div>
              </div>
            </div>
          </div>

          {/* 2. SUBSCRIPTION HISTORY SECTION */}
          <div className="card border radius-12 shadow-none bg-white mb-24">
            <div className="card-header bg-white border-bottom py-16 px-24 d-flex align-items-center justify-content-between">
              <div className="d-flex align-items-center gap-2">
                <Icon icon="solar:history-bold-duotone" className="text-primary-600 text-xl" />
                <h6 className="mb-0 fw-bold text-dark">Subscription History</h6>
              </div>
              <span className="badge bg-neutral-100 text-secondary-light radius-4 px-2 py-1 text-xs fw-medium">
                {history.length} {history.length === 1 ? "Record" : "Records"}
              </span>
            </div>

            <div className="card-body p-0">
              {history.length === 0 ? (
                <div className="p-4 text-center text-muted">
                  <Icon icon="solar:document-text-linear" className="text-4xl text-neutral-300 mb-2 d-block mx-auto" />
                  <p className="mb-0 text-sm">No subscription history recorded yet.</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <table className="table bordered-table align-middle mb-0">
                    <thead className="table-light text-uppercase text-xs text-secondary-light">
                      <tr>
                        <th className="py-3 px-4">Plan</th>
                        <th className="py-3 px-4">Billing Period</th>
                        <th className="py-3 px-4">Amount</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4">Recorded On</th>
                      </tr>
                    </thead>
                    <tbody>
                      {history.map((sub) => (
                        <tr key={sub.id}>
                          <td className="py-3 px-4 fw-semibold text-dark">
                            {formatPlanName(sub.plan)}
                          </td>
                          <td className="py-3 px-4 text-sm text-secondary-light">
                            {formatSubscriptionDate(sub.start_date)} – {formatSubscriptionDate(sub.end_date)}
                          </td>
                          <td className="py-3 px-4 fw-semibold text-dark text-sm">
                            {sub.amount ? `$${Number(sub.amount).toFixed(2)}` : "—"}
                          </td>
                          <td className="py-3 px-4">
                            {sub.status === "active" ? (
                              <span className="badge bg-success-focus text-success-main text-xs px-2 py-1 radius-4">
                                Active
                              </span>
                            ) : sub.status === "expired" ? (
                              <span className="badge bg-danger-focus text-danger-main text-xs px-2 py-1 radius-4">
                                Expired
                              </span>
                            ) : (
                              <span className="badge bg-secondary-focus text-secondary-main text-xs px-2 py-1 radius-4">
                                Inactive
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-4 text-sm text-secondary-light">
                            {sub.created_at ? formatSubscriptionDate(sub.created_at) : "—"}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>

          {/* 3. RELATED INVOICES SECTION */}
          <div className="card border radius-12 shadow-none bg-white mb-24">
            <div className="card-header bg-white border-bottom py-16 px-24 d-flex align-items-center justify-content-between">
              <div className="d-flex align-items-center gap-2">
                <Icon icon="solar:bill-list-bold-duotone" className="text-primary-600 text-xl" />
                <h6 className="mb-0 fw-bold text-dark">Related Invoices</h6>
              </div>
              <span className="badge bg-neutral-100 text-secondary-light radius-4 px-2 py-1 text-xs fw-medium">
                {invoices.length} {invoices.length === 1 ? "Invoice" : "Invoices"}
              </span>
            </div>

            <div className="card-body p-0">
              {invoices.length === 0 ? (
                <div className="p-4 text-center text-muted">
                  <Icon icon="solar:receipt-linear" className="text-4xl text-neutral-300 mb-2 d-block mx-auto" />
                  <p className="mb-0 text-sm">No invoices recorded yet.</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <table className="table bordered-table align-middle mb-0">
                    <thead className="table-light text-uppercase text-xs text-secondary-light">
                      <tr>
                        <th className="py-3 px-4">Invoice #</th>
                        <th className="py-3 px-4">Plan / Description</th>
                        <th className="py-3 px-4">Billing Period</th>
                        <th className="py-3 px-4">Total Amount</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4">Issue Date</th>
                        <th className="py-3 px-4 text-end">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {invoices.map((inv) => (
                        <tr key={inv.id}>
                          <td className="py-3 px-4 fw-semibold text-dark font-monospace text-sm">
                            {inv.invoice_number}
                          </td>
                          <td className="py-3 px-4 text-sm">
                            <span className="fw-medium text-dark d-block">
                              {inv.plan ? formatPlanName(inv.plan) : "School Subscription"}
                            </span>
                            {inv.description && (
                              <small className="text-secondary-light text-xs d-block text-truncate" style={{ maxWidth: "240px" }}>
                                {inv.description}
                              </small>
                            )}
                          </td>
                          <td className="py-3 px-4 text-sm text-secondary-light">
                            {inv.billing_period_start && inv.billing_period_end ? (
                              <span>
                                {formatSubscriptionDate(inv.billing_period_start)} –{" "}
                                {formatSubscriptionDate(inv.billing_period_end)}
                              </span>
                            ) : (
                              "—"
                            )}
                          </td>
                          <td className="py-3 px-4 fw-bold text-dark text-sm">
                            ${Number(inv.total).toFixed(2)}{" "}
                            <span className="text-xs text-secondary-light fw-normal">{inv.currency || "USD"}</span>
                          </td>
                          <td className="py-3 px-4">
                            {inv.status === "paid" ? (
                              <span className="badge bg-success-focus text-success-main text-xs px-2 py-1 radius-4 d-inline-flex align-items-center gap-1">
                                <Icon icon="solar:check-circle-bold" /> Paid
                              </span>
                            ) : inv.status === "void" ? (
                              <span className="badge bg-danger-focus text-danger-main text-xs px-2 py-1 radius-4 d-inline-flex align-items-center gap-1">
                                <Icon icon="solar:close-circle-bold" /> Void
                              </span>
                            ) : (
                              <span className="badge bg-warning-focus text-warning-main text-xs px-2 py-1 radius-4">
                                {inv.status || "Issued"}
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-4 text-sm text-secondary-light">
                            {inv.issued_at ? formatSubscriptionDate(inv.issued_at) : "—"}
                          </td>
                          <td className="py-3 px-4 text-end">
                            <div className="d-flex align-items-center justify-content-end gap-1">
                              <button
                                type="button"
                                className="btn btn-sm btn-outline-secondary radius-8 px-2 py-1 d-inline-flex align-items-center gap-1 text-xs"
                                title="View Details"
                                onClick={() => setSelectedInvoice(inv)}
                              >
                                <Icon icon="solar:eye-linear" />
                                <span>Details</span>
                              </button>
                              <button
                                type="button"
                                className="btn btn-sm btn-outline-primary radius-8 px-2 py-1 d-inline-flex align-items-center gap-1 text-xs"
                                title="Download PDF"
                                disabled={downloadingId === inv.id}
                                onClick={() => handleDownloadPdf(inv.id, inv.invoice_number)}
                              >
                                {downloadingId === inv.id ? (
                                  <span
                                    className="spinner-border spinner-border-sm"
                                    role="status"
                                    aria-hidden="true"
                                  ></span>
                                ) : (
                                  <Icon icon="solar:download-minimalistic-bold" />
                                )}
                                <span>PDF</span>
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </>
      )}

      {/* 4. INVOICE DETAIL MODAL */}
      {selectedInvoice && (
        <div
          className="modal fade show d-block"
          tabIndex="-1"
          style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
          role="dialog"
          aria-modal="true"
        >
          <div className="modal-dialog modal-dialog-centered modal-lg">
            <div className="modal-content border-0 radius-12 shadow-lg">
              <div className="modal-header border-bottom py-16 px-24">
                <div className="d-flex align-items-center gap-2">
                  <div className="w-32-px h-32-px bg-primary-50 text-primary-600 rounded-circle d-flex align-items-center justify-content-center">
                    <Icon icon="solar:document-text-bold-duotone" className="text-lg" />
                  </div>
                  <div>
                    <h6 className="modal-title fw-bold text-dark mb-0">
                      Invoice Details – {selectedInvoice.invoice_number}
                    </h6>
                    <small className="text-secondary-light text-xs">
                      Issued {selectedInvoice.issued_at ? formatSubscriptionDate(selectedInvoice.issued_at) : "—"}
                    </small>
                  </div>
                </div>
                <button
                  type="button"
                  className="btn-close"
                  onClick={() => setSelectedInvoice(null)}
                  aria-label="Close"
                ></button>
              </div>

              <div className="modal-body p-24">
                <div className="row g-3 mb-24">
                  <div className="col-sm-6">
                    <div className="p-16 bg-neutral-50 radius-8 border">
                      <span className="text-secondary-light text-xs text-uppercase d-block mb-1 fw-semibold">Plan</span>
                      <strong className="text-dark">
                        {selectedInvoice.plan ? formatPlanName(selectedInvoice.plan) : "School Subscription"}
                      </strong>
                    </div>
                  </div>
                  <div className="col-sm-6">
                    <div className="p-16 bg-neutral-50 radius-8 border">
                      <span className="text-secondary-light text-xs text-uppercase d-block mb-1 fw-semibold">Status</span>
                      {selectedInvoice.status === "paid" ? (
                        <span className="badge bg-success-focus text-success-main text-xs px-2 py-1 radius-4">
                          Paid
                        </span>
                      ) : selectedInvoice.status === "void" ? (
                        <span className="badge bg-danger-focus text-danger-main text-xs px-2 py-1 radius-4">
                          Void
                        </span>
                      ) : (
                        <span className="badge bg-warning-focus text-warning-main text-xs px-2 py-1 radius-4">
                          {selectedInvoice.status || "Issued"}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="col-sm-6">
                    <div className="p-16 bg-neutral-50 radius-8 border">
                      <span className="text-secondary-light text-xs text-uppercase d-block mb-1 fw-semibold">Billing Period</span>
                      <span className="text-sm text-dark">
                        {selectedInvoice.billing_period_start && selectedInvoice.billing_period_end
                          ? `${formatSubscriptionDate(selectedInvoice.billing_period_start)} – ${formatSubscriptionDate(selectedInvoice.billing_period_end)}`
                          : "—"}
                      </span>
                    </div>
                  </div>
                  <div className="col-sm-6">
                    <div className="p-16 bg-neutral-50 radius-8 border">
                      <span className="text-secondary-light text-xs text-uppercase d-block mb-1 fw-semibold">Payment Method</span>
                      <span className="text-sm text-dark text-capitalize">
                        {selectedInvoice.payment?.method || "Direct Invoice"}
                        {selectedInvoice.payment?.reference && ` (${selectedInvoice.payment.reference})`}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Amount Breakdown */}
                <div className="border radius-8 p-16 bg-neutral-50 mb-3">
                  <div className="d-flex justify-content-between text-sm py-1">
                    <span className="text-secondary-light">Subtotal:</span>
                    <span className="fw-medium text-dark">${Number(selectedInvoice.subtotal || 0).toFixed(2)}</span>
                  </div>
                  {Number(selectedInvoice.discount || 0) > 0 && (
                    <div className="d-flex justify-content-between text-sm py-1 text-danger">
                      <span>Discount:</span>
                      <span>-${Number(selectedInvoice.discount).toFixed(2)}</span>
                    </div>
                  )}
                  {Number(selectedInvoice.tax || 0) > 0 && (
                    <div className="d-flex justify-content-between text-sm py-1 text-secondary-light">
                      <span>Tax:</span>
                      <span>${Number(selectedInvoice.tax).toFixed(2)}</span>
                    </div>
                  )}
                  <div className="d-flex justify-content-between text-base py-2 border-top mt-2 fw-bold text-dark">
                    <span>Total:</span>
                    <span>
                      ${Number(selectedInvoice.total).toFixed(2)} {selectedInvoice.currency || "USD"}
                    </span>
                  </div>
                </div>
              </div>

              <div className="modal-footer border-top py-16 px-24 d-flex justify-content-between">
                <button
                  type="button"
                  className="btn btn-sm btn-outline-secondary radius-8 px-16 py-8"
                  onClick={() => setSelectedInvoice(null)}
                >
                  Close
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-primary radius-8 px-16 py-8 d-inline-flex align-items-center gap-1"
                  disabled={downloadingId === selectedInvoice.id}
                  onClick={() => handleDownloadPdf(selectedInvoice.id, selectedInvoice.invoice_number)}
                >
                  {downloadingId === selectedInvoice.id ? (
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                  ) : (
                    <Icon icon="solar:download-minimalistic-bold" />
                  )}
                  <span>Download PDF</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </SchoolLayout>
  );
}
