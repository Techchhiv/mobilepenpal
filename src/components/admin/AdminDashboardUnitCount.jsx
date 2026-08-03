import React from "react";
import { Icon } from "@iconify/react";

const AdminDashboardUnitCount = ({ summary }) => {
    if (!summary) return null;

    return (
        <div className="row row-cols-xxxl-4 row-cols-lg-4 row-cols-sm-2 row-cols-1 gy-4">
            <div className="col">
                <div className="card shadow-none border bg-gradient-start-1 h-100">
                    <div className="card-body p-20">
                        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                            <div>
                                <p className="fw-medium text-primary-light mb-1">Total Schools</p>
                                <h6 className="mb-0">{summary.total_schools || 0}</h6>
                            </div>
                            <div className="w-50-px h-50-px bg-cyan rounded-circle d-flex justify-content-center align-items-center">
                                <Icon icon="ph:buildings-fill" className="text-white text-2xl mb-0" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="col">
                <div className="card shadow-none border bg-gradient-start-2 h-100">
                    <div className="card-body p-20">
                        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                            <div>
                                <p className="fw-medium text-primary-light mb-1">Active Schools</p>
                                <h6 className="mb-0">{summary.active_schools ?? summary.total_active_schools ?? 0}</h6>
                            </div>
                            <div className="w-50-px h-50-px bg-purple rounded-circle d-flex justify-content-center align-items-center">
                                <Icon icon="ph:check-circle-fill" className="text-white text-2xl mb-0" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="col">
                <div className="card shadow-none border bg-gradient-start-3 h-100">
                    <div className="card-body p-20">
                        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                            <div>
                                <p className="fw-medium text-primary-light mb-1">Total Students</p>
                                <h6 className="mb-0">{summary.total_students || 0}</h6>
                            </div>
                            <div className="w-50-px h-50-px bg-info rounded-circle d-flex justify-content-center align-items-center">
                                <Icon icon="ph:users-three-fill" className="text-white text-2xl mb-0" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="col">
                <div className="card shadow-none border bg-gradient-start-4 h-100">
                    <div className="card-body p-20">
                        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                            <div>
                                <p className="fw-medium text-primary-light mb-1">Total Teachers</p>
                                <h6 className="mb-0">{summary.total_teachers || 0}</h6>
                            </div>
                            <div className="w-50-px h-50-px bg-success-main rounded-circle d-flex justify-content-center align-items-center">
                                <Icon icon="ph:chalkboard-teacher-fill" className="text-white text-2xl mb-0" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminDashboardUnitCount;
