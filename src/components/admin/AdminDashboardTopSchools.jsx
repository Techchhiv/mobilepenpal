import React from "react";
import { Link } from "react-router-dom";

const AdminDashboardTopSchools = ({ schools }) => {
    return (
        <div className="col-12 mt-4">
            <div className="card h-100">
                <div className="card-header border-bottom bg-base py-16 px-24">
                    <h6 className="text-lg fw-semibold mb-0">Top Schools (By Students)</h6>
                </div>
                <div className="card-body p-24">
                    <div className="table-responsive">
                        <table className="table bordered-table mb-0">
                            <thead>
                                <tr>
                                    <th scope="col">School Name</th>
                                    <th scope="col">School Key</th>
                                    <th scope="col">Admin Email</th>
                                    <th scope="col">Status</th>
                                    <th scope="col">Students</th>
                                    <th scope="col">Teachers</th>
                                </tr>
                            </thead>
                            <tbody>
                                {schools && schools.length > 0 ? (
                                    schools.map((school, index) => (
                                        <tr key={index}>
                                            <td>
                                                <div className="d-flex align-items-center">
                                                    <h6 className="text-md mb-0 fw-medium flex-grow-1">
                                                        {school.name}
                                                    </h6>
                                                </div>
                                            </td>
                                            <td>{school.school_key}</td>
                                            <td>{school.admin_email}</td>
                                            <td>
                                                {school.is_active ? (
                                                    <span className="bg-success-focus text-success-main px-24 py-4 rounded-pill fw-medium text-sm">
                                                        Active
                                                    </span>
                                                ) : (
                                                    <span className="bg-danger-focus text-danger-main px-24 py-4 rounded-pill fw-medium text-sm">
                                                        Inactive
                                                    </span>
                                                )}
                                            </td>
                                            <td>{school.students_count}</td>
                                            <td>{school.teachers_count}</td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td colSpan="6" className="text-center py-3">
                                            No schools found.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminDashboardTopSchools;
