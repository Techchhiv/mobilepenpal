import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";

export default function SchoolPayments() {
  const { schoolId } = useParams();
  const [school, setSchool] = useState(null);
  const [subs, setSubs] = useState([]);
  const [plan, setPlan] = useState("monthly");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (schoolId) {
      loadSchool();
      loadSubs();
    }
  }, [schoolId]);

  const loadSchool = async () => {
    try {
      const { data } = await API.get(`/admin/schools/${schoolId}`);
      setSchool(data); // assuming your API returns the school object directly
    } catch (err) {
      console.error("Failed to load school info", err);
    }
  };

  const loadSubs = async () => {
    try {
      const { data } = await API.get(`/admin/schools/${schoolId}/subscriptions`);
      setSubs(data ?? []);
    } catch (err) {
      console.error("Failed to load subscriptions", err);
    }
  };

  const createSub = async () => {
    setLoading(true);
    try {
      await API.post(`/admin/schools/${schoolId}/subscriptions`, {
        plan,
        amount: plan === "monthly" ? 50 : 500,
      });
      await loadSubs();
    } catch (err) {
      console.error("Failed to create subscription", err);
    } finally {
      setLoading(false);
    }
  };

  // Initialize DataTable
  useEffect(() => {
    if (subs.length > 0) {
      const table = $("#subsTable").DataTable({ destroy: true, pageLength: 10 });
      return () => table.destroy(true);
    }
  }, [subs]);

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5 className="mb-0 fw-semibold">
            📑 School Subscriptions – {school ? school.name : `School #${schoolId}`}
          </h5>

          <div className="d-flex align-items-center gap-2">
            <select
              className="form-select"
              value={plan}
              onChange={(e) => setPlan(e.target.value)}
            >
              <option value="monthly">Monthly - $50</option>
              <option value="yearly">Yearly - $500</option>
            </select>
            <button
              onClick={createSub}
              disabled={loading}
              className="btn btn-primary-600 px-20 py-11"
            >
              {loading ? "Processing..." : "Subscribe"}
            </button>
          </div>
        </div>

        <div className="card-body">
          {subs.length === 0 ? (
            <p className="text-muted">No subscriptions yet.</p>
          ) : (
            <table
              className="table bordered-table mb-0"
              id="subsTable"
              data-page-length={10}
            >
              <thead>
                <tr>
                  <th>S.L</th>
                  <th>Plan</th>
                  <th>Amount</th>
                  <th>Start</th>
                  <th>End</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {subs.map((s, index) => (
                  <tr key={s.id}>
                    <td>
                      <div className="form-check style-check d-flex align-items-center">
                        <input className="form-check-input" type="checkbox" />
                        <label className="form-check-label">{index + 1}</label>
                      </div>
                    </td>
                    <td className="fw-medium">{s.plan}</td>
                    <td>${s.amount}</td>
                    <td>{s.start_date}</td>
                    <td>{s.end_date}</td>
                    <td>
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          s.active
                            ? "bg-success-focus text-success-main"
                            : "bg-danger-focus text-danger-main"
                        }`}
                      >
                        {s.active ? "Active" : "Expired"}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </MasterLayout>
  );
}
