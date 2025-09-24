import React, { useEffect, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../helper/api";
import MasterLayout from "../../masterLayout/MasterLayout";

export default function ManagePaymentsPage() {
  const [schools, setSchools] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSchools();
  }, []);

  const loadSchools = async () => {
    try {
      const { data } = await API.get("/admin/schools");
      setSchools(data.data ?? []); // Laravel paginate returns { data: [...] }
    } catch (error) {
      console.error("Failed to load schools:", error);
    } finally {
      setLoading(false);
    }
  };

  // Initialize DataTable after schools load
  useEffect(() => {
    if (schools.length > 0) {
      const table = $("#schoolsTable").DataTable({ destroy: true, pageLength: 10 });
      return () => table.destroy(true);
    }
  }, [schools]);

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5 className="mb-0 fw-semibold">🏫 Payments – Schools</h5>
        </div>

        <div className="card-body">
          {loading ? (
            <p>Loading schools...</p>
          ) : schools.length === 0 ? (
            <p className="text-muted">No schools found.</p>
          ) : (
            <table
              className="table bordered-table mb-0"
              id="schoolsTable"
              data-page-length={10}
            >
              <thead>
                <tr>
                  <th>S.L</th>
                  <th>School</th>
                  <th>Admin Email</th>
                  <th>Status</th>
                  <th className="text-end">Action</th>
                </tr>
              </thead>
              <tbody>
                {schools.map((s, index) => (
                  <tr key={s.id}>
                    <td>
                      <div className="form-check style-check d-flex align-items-center">
                        <input className="form-check-input" type="checkbox" />
                        <label className="form-check-label">{index + 1}</label>
                      </div>
                    </td>

                    <td className="fw-medium">{s.name}</td>
                    <td>{s.admin_email}</td>
                    <td>
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          s.is_active
                            ? "bg-success-focus text-success-main"
                            : "bg-danger-focus text-danger-main"
                        }`}
                      >
                        {s.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>

                    <td className="text-end">
                      <Link
                        to={`/admin/schools/${s.id}/payments`}
                        className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                        title="Manage Subscription"
                      >
                        <Icon icon="mdi:credit-card-outline" />
                      </Link>
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
