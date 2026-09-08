import React, { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";

export default function SchoolPayments() {
  const { schoolId } = useParams();
  const [school, setSchool] = useState(null);
  const [subs, setSubs] = useState([]);
  const [plan, setPlan] = useState("monthly");
  const [submitting, setSubmitting] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!schoolId) return;

    const fetchSchoolInfo = async () => {
      try {
        const { data } = await API.get(`/admin/schools/${schoolId}`);
        setSchool(data);
      } catch (err) {
        console.error("Failed to load school info", err);
      }
    };

    const fetchSubHistory = async () => {
      setLoading(true);
      try {
        const { data } = await API.get(`/admin/schools/${schoolId}/subscriptions`);
        setSubs(Array.isArray(data) ? data : data?.data || []);
      } catch (err) {
        console.error("Failed to load subscriptions", err);
      } finally {
        setLoading(false);
      }
    };

    fetchSchoolInfo();
    fetchSubHistory();
  }, [schoolId]);

  const loadSubs = async () => {
    setLoading(true);
    try {
      const { data } = await API.get(`/admin/schools/${schoolId}/subscriptions`);
      setSubs(Array.isArray(data) ? data : data?.data || []);
    } catch (err) {
      console.error("Failed to load subscriptions", err);
    } finally {
      setLoading(false);
    }
  };

  const createSub = async () => {
    setSubmitting(true);
    try {
      await API.post(`/admin/schools/${schoolId}/subscriptions`, {
        plan,
        amount: plan === "monthly" ? 50 : 500,
      });
      await loadSubs();
    } catch (err) {
      console.error("Failed to create subscription", err);
    } finally {
      setSubmitting(false);
    }
  };

  const formatCurrency = (amt) => {
    const num = Number(amt) || 0;
    return `$${num.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return "—";
    try {
      const date = new Date(dateStr);
      if (isNaN(date.getTime())) return dateStr;
      return date.toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "2-digit",
      });
    } catch {
      return dateStr;
    }
  };

  const pageTitle = school ? `Subscriptions – ${school.name}` : `School Subscriptions #${schoolId}`;

  return (
    <MasterLayout>
      <div className="py-12">
        <div className="mb-16">
          <Link to="/admin/payments" className="btn btn-outline-primary btn-sm radius-8 d-inline-flex align-items-center gap-6">
            <Icon icon="mdi:arrow-left" />
            <span>Back to School Payments</span>
          </Link>
        </div>

        <AdminPageHeader
          title={pageTitle}
          subtitle="Manage active subscription plan and review past subscription billing history"
        />

        <div className="card border radius-12 shadow-none">
          <div className="card-header border-bottom py-16 px-24 bg-base d-flex align-items-center justify-content-between flex-wrap gap-12">
            <h6 className="fw-bold mb-0 text-dark">Subscription Records</h6>

            <div className="d-flex align-items-center gap-12">
              <select
                className="form-select form-select-sm radius-8 min-w-160-px"
                value={plan}
                onChange={(e) => setPlan(e.target.value)}
              >
                <option value="monthly">Monthly - $50.00</option>
                <option value="yearly">Yearly - $500.00</option>
              </select>
              <button
                onClick={createSub}
                disabled={submitting}
                className="btn btn-primary btn-sm radius-8 d-inline-flex align-items-center gap-6"
              >
                {submitting && <Icon icon="mdi:loading" className="spin" />}
                <span>Subscribe Plan</span>
              </button>
            </div>
          </div>

          <div className="card-body p-24">
            {loading ? (
              <div className="placeholder-glow d-flex flex-column gap-12">
                {[1, 2, 3].map((i) => (
                  <span key={i} className="placeholder col-12 radius-8" style={{ height: "48px" }}></span>
                ))}
              </div>
            ) : subs.length === 0 ? (
              <AdminEmptyState
                icon="mdi:credit-card-off-outline"
                title="No subscription history found"
                message="This school currently does not have any active or past subscription plans."
              />
            ) : (
              <div className="table-responsive">
                <table className="table bordered-table mb-0">
                  <thead>
                    <tr>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16" style={{ width: 60 }}>#</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Plan Name</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Amount</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Start Date</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">End Date</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-end">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {subs.map((s, index) => {
                      const isActive = Boolean(s.active ?? true);
                      return (
                        <tr key={s.id || index} className="hover-bg-neutral-50 transition-1">
                          <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{index + 1}</td>
                          <td className="py-12 px-16 text-sm fw-bold text-dark text-capitalize">{s.plan} Plan</td>
                          <td className="py-12 px-16 text-sm fw-bold text-primary-600">{formatCurrency(s.amount)}</td>
                          <td className="py-12 px-16 text-sm text-secondary-light">{formatDate(s.start_date || s.created_at)}</td>
                          <td className="py-12 px-16 text-sm text-secondary-light">{formatDate(s.end_date)}</td>
                          <td className="py-12 px-16 text-end">
                            <span
                              className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                isActive ? 'status-active' : 'status-expired'
                              }`}
                            >
                              <Icon icon={isActive ? 'mdi:check-circle' : 'mdi:clock-alert-outline'} />
                              <span>{isActive ? 'Active' : 'Expired'}</span>
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    </MasterLayout>
  );
}
