import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../components/admin/common/AdminErrorState";

export default function ManagePaymentsPage() {
  const [schools, setSchools] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    loadSchools();
  }, []);

  const loadSchools = async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await API.get("/admin/schools");
      setSchools(data.data ?? (Array.isArray(data) ? data : []));
    } catch (err) {
      console.error("Failed to load schools:", err);
      setError(err?.response?.data?.message || "Failed to load school accounts from server.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Manage Payments"
          subtitle="Select a school client to review payment history and active billing subscriptions"
        />

        {error ? (
          <AdminErrorState
            title="Failed to Load Payment Accounts"
            message={error}
            onRetry={loadSchools}
          />
        ) : (
          <div className="card border radius-12 shadow-none">
            <div className="card-header border-bottom py-16 px-24 bg-base d-flex align-items-center justify-content-between">
              <h6 className="fw-bold mb-0 text-dark">School Accounts</h6>
              <span className="badge bg-neutral-200 text-secondary-light radius-6 text-xs px-10 py-6">
                Total: {schools.length}
              </span>
            </div>

            <div className="card-body p-0">
              {loading ? (
                <div className="placeholder-glow d-flex flex-column gap-12 p-24">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <span key={i} className="placeholder col-12 radius-8" style={{ height: "48px" }}></span>
                  ))}
                </div>
              ) : schools.length === 0 ? (
                <AdminEmptyState
                  icon="mdi:credit-card-off-outline"
                  title="No school accounts found"
                  message="There are currently no school clients registered in the system."
                />
              ) : (
                <div className="table-responsive">
                  <table className="table bordered-table mb-0 align-middle">
                    <thead>
                      <tr>
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16" style={{ width: 60 }}>#</th>
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">School Name</th>
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Admin Email</th>
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Account Status</th>
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-end" style={{ width: 120 }}>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {schools.map((s, index) => {
                        const isActive = Boolean(s.is_active ?? true);
                        return (
                          <tr key={s.id} className="hover-bg-neutral-50 transition-1">
                            <td className="py-12 px-16 text-sm font-monospace text-secondary-light">{index + 1}</td>
                            <td className="py-12 px-16 text-sm fw-bold text-dark">{s.name}</td>
                            <td className="py-12 px-16 text-sm text-secondary-light">{s.admin_email || '-'}</td>
                            <td className="py-12 px-16">
                              <span
                                className={`status-badge d-inline-flex align-items-center gap-6 px-10 py-4 radius-6 text-xs fw-semibold ${
                                  isActive ? 'status-active' : 'status-inactive'
                                }`}
                              >
                                <Icon icon={isActive ? 'mdi:check-circle' : 'mdi:close-circle'} />
                                <span>{isActive ? 'Active' : 'Inactive'}</span>
                              </span>
                            </td>
                            <td className="py-12 px-16 text-end">
                              <Link
                                to={`/admin/schools/${s.id}/payments`}
                                className="btn btn-outline-primary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                                title="Manage Subscription & Payments"
                              >
                                <Icon icon="mdi:credit-card-outline" className="text-base" />
                                <span>Payments</span>
                              </Link>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Card Footer */}
            <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between">
              <div className="text-secondary-light text-xs font-semibold">
                Showing {schools.length > 0 ? 1 : 0}–{schools.length} of {schools.length} entries
              </div>
            </div>
          </div>
        )}
      </div>
    </MasterLayout>
  );
}
