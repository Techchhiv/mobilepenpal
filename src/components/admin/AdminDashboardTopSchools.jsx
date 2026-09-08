import React from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";

const AdminDashboardTopSchools = ({ schools = [] }) => {
    return (
        <div className="card border shadow-sm h-100" style={{ borderRadius: "12px" }}>
            <div className="card-header bg-base py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                <div>
                    <h6 className="mb-0 fw-bold text-dark">Top Partner Schools Overview</h6>
                    <span className="text-xs text-secondary-light">Ranked by total enrolled student capacity</span>
                </div>
                <Link to="/admin/schools" className="btn btn-sm btn-outline-primary text-xs font-semibold rounded-pill px-12">
                    View All Schools
                </Link>
            </div>
            <div className="card-body p-0">
                <div className="table-responsive">
                    <table className="table bordered-table mb-0 align-middle">
                        <thead>
                            <tr>
                                <th scope="col" className="py-12 px-24">School Name</th>
                                <th scope="col" className="py-12 px-24">Admin Email</th>
                                <th scope="col" className="py-12 px-24 text-center">Status</th>
                                <th scope="col" className="py-12 px-24 text-center">Classrooms</th>
                                <th scope="col" className="py-12 px-24 text-center">Teachers</th>
                                <th scope="col" className="py-12 px-24 text-center">Students</th>
                                <th scope="col" className="py-12 px-24 text-end">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {schools && schools.length > 0 ? (
                                schools.map((school) => (
                                    <tr key={school.id}>
                                        <td className="py-16 px-24">
                                            <div className="d-flex align-items-center gap-3">
                                                <div className="w-36-px h-36-px rounded-circle bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center font-bold">
                                                    <Icon icon="ph:buildings-bold" className="text-lg" />
                                                </div>
                                                <div>
                                                    <h6 className="text-sm mb-0 fw-bold text-primary-light">
                                                        {school.name}
                                                    </h6>
                                                    <span className="text-xs text-secondary-light">
                                                        ID #{school.id}
                                                    </span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="py-16 px-24 text-sm text-secondary-light fw-medium">
                                            {school.admin_email || "—"}
                                        </td>
                                        <td className="py-16 px-24 text-center">
                                            {school.is_active ? (
                                                <span className="badge bg-success-50 text-success-600 px-10 py-4 rounded-pill text-xs fw-semibold">
                                                    Active
                                                </span>
                                            ) : (
                                                <span className="badge bg-danger-50 text-danger-600 px-10 py-4 rounded-pill text-xs fw-semibold">
                                                    Inactive
                                                </span>
                                            )}
                                        </td>
                                        <td className="py-16 px-24 text-center text-sm fw-bold">
                                            {school.classrooms_count || 0}
                                        </td>
                                        <td className="py-16 px-24 text-center text-sm fw-bold">
                                            {school.teachers_count || 0}
                                        </td>
                                        <td className="py-16 px-24 text-center text-sm fw-bold text-primary-600">
                                            {school.students_count || 0}
                                        </td>
                                        <td className="py-16 px-24 text-end">
                                            <Link
                                                to={`/admin/schools`}
                                                className="btn btn-sm btn-outline-neutral-400 text-xs px-12 py-6 rounded-2"
                                            >
                                                Manage
                                            </Link>
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="7" className="text-center py-4 text-secondary-light">
                                        No partner schools registered yet.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default AdminDashboardTopSchools;
