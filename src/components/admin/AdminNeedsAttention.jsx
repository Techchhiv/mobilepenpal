import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import { useAuth } from "../../context/AuthContext";

const AdminNeedsAttention = () => {
  const { hasPermission, isSuperAdmin } = useAuth();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Permission checks
  const canViewBilling =
    isSuperAdmin || hasPermission("billing.view") || hasPermission("menu.payments");
  const canViewSubscriptions = canViewBilling;
  const canViewInvoices = canViewBilling;
  const canViewPayments = canViewBilling;

  useEffect(() => {
    const fetchNeedsAttention = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await API.get("/admin/dashboard/needs-attention");
        if (res.data && res.data.data) {
          setData(res.data.data);
        }
      } catch (err) {
        console.error("Error fetching needs attention data:", err);
        setError("Unable to load items requiring attention.");
      } finally {
        setLoading(false);
      }
    };

    fetchNeedsAttention();
  }, []);

  if (!canViewBilling) {
    return null;
  }

  const expiringCount = data?.expiring_subscriptions ?? 0;
  const unpaidCount = data?.unpaid_invoices ?? 0;
  const failedCount = data?.failed_payments ?? 0;

  const totalIssuesCount =
    (canViewSubscriptions ? expiringCount : 0) +
    (canViewInvoices ? unpaidCount : 0) +
    (canViewPayments ? failedCount : 0);

  return (
    <div className="card border radius-12 shadow-none mb-24">
      {/* Header matching template design */}
      <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
        <div className="d-flex align-items-center gap-10">
          <div className="w-36-px h-36-px rounded-circle bg-warning text-white d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm">
            <Icon icon="ph:bell-simple-fill" className="text-xl" />
          </div>
          <div>
            <h6 className="fw-bold mb-0 text-dark">Needs Attention</h6>
            <span className="text-xs text-secondary-light">
              Actionable billing and subscription items requiring review
            </span>
          </div>
        </div>
        {!loading && !error && totalIssuesCount > 0 && (
          <span className="badge bg-warning-50 text-warning-main border border-warning-200 px-10 py-6 radius-8 text-xs fw-semibold">
            {totalIssuesCount} Action{totalIssuesCount > 1 ? "s" : ""} Required
          </span>
        )}
      </div>

      {/* Card Body */}
      <div className="card-body p-20">
        {loading ? (
          <div className="placeholder-glow">
            <div className="row g-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="col-12 col-md-4">
                  <span
                    className="placeholder col-12 radius-10"
                    style={{ height: "90px", display: "block" }}
                  ></span>
                </div>
              ))}
            </div>
          </div>
        ) : error ? (
          <div className="alert alert-warning text-sm mb-0 radius-8 d-flex align-items-center gap-8 py-12 px-16">
            <Icon icon="ph:warning-circle-fill" className="text-lg flex-shrink-0" />
            <div>{error}</div>
          </div>
        ) : totalIssuesCount === 0 ? (
          <div className="py-24 px-16 text-center radius-12 bg-neutral-50 border border-neutral-100">
            <Icon
              icon="ph:check-circle-fill"
              className="text-success-main text-4xl mb-8"
            />
            <h6 className="fw-bold text-dark text-base mb-4">Everything looks good!</h6>
            <p className="text-xs text-secondary-light mb-0">
              There are currently no billing or subscription issues requiring attention.
            </p>
          </div>
        ) : (
          <div className="row g-3">
            {/* 1. Subscriptions Expiring Soon */}
            {canViewSubscriptions && expiringCount > 0 && (
              <div className="col-12 col-md-4">
                <Link
                  to="/admin/subscriptions/schools"
                  className="card shadow-none border bg-gradient-start-2 h-100 text-decoration-none transition-all hover-shadow-sm"
                  style={{ borderRadius: "10px" }}
                >
                  <div className="card-body p-20">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <div>
                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                          Subscriptions Expiring
                        </p>
                        <h4 className="fw-bold mb-0 text-warning-main">
                          {expiringCount}
                        </h4>
                      </div>
                      <div className="w-50-px h-50-px bg-warning rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm">
                        <Icon icon="ph:warning-fill" className="text-white text-2xl mb-0" />
                      </div>
                    </div>
                    <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                      <span className="text-xs text-secondary-light">
                        Expiring within 30 days
                      </span>
                      <span className="text-xs fw-semibold text-warning-main">
                        Review →
                      </span>
                    </div>
                  </div>
                </Link>
              </div>
            )}

            {/* 2. Unpaid Invoices */}
            {canViewInvoices && unpaidCount > 0 && (
              <div className="col-12 col-md-4">
                <Link
                  to="/admin/invoices"
                  className="card shadow-none border bg-gradient-start-1 h-100 text-decoration-none transition-all hover-shadow-sm"
                  style={{ borderRadius: "10px" }}
                >
                  <div className="card-body p-20">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <div>
                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                          Unpaid Invoices
                        </p>
                        <h4 className="fw-bold mb-0 text-danger-main">
                          {unpaidCount}
                        </h4>
                      </div>
                      <div className="w-50-px h-50-px bg-danger-main rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm">
                        <Icon icon="ph:receipt-fill" className="text-white text-2xl mb-0" />
                      </div>
                    </div>
                    <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                      <span className="text-xs text-secondary-light">
                        Pending or overdue
                      </span>
                      <span className="text-xs fw-semibold text-danger-main">
                        Review →
                      </span>
                    </div>
                  </div>
                </Link>
              </div>
            )}

            {/* 3. Failed Payments */}
            {canViewPayments && failedCount > 0 && (
              <div className="col-12 col-md-4">
                <Link
                  to="/admin/subscriptions/schools"
                  className="card shadow-none border bg-gradient-start-3 h-100 text-decoration-none transition-all hover-shadow-sm"
                  style={{ borderRadius: "10px" }}
                >
                  <div className="card-body p-20">
                    <div className="d-flex align-items-center justify-content-between mb-12">
                      <div>
                        <p className="fw-medium text-primary-light mb-1 text-xs text-uppercase tracking-wider">
                          Failed Payments
                        </p>
                        <h4 className="fw-bold mb-0 text-danger-main">
                          {failedCount}
                        </h4>
                      </div>
                      <div className="w-50-px h-50-px bg-danger-main rounded-circle d-flex justify-content-center align-items-center flex-shrink-0 shadow-sm">
                        <Icon icon="ph:x-circle-fill" className="text-white text-2xl mb-0" />
                      </div>
                    </div>
                    <div className="d-flex align-items-center justify-content-between pt-10 border-top border-neutral-200">
                      <span className="text-xs text-secondary-light">
                        Require investigation
                      </span>
                      <span className="text-xs fw-semibold text-danger-main">
                        Investigate →
                      </span>
                    </div>
                  </div>
                </Link>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminNeedsAttention;
