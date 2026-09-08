import React from "react";
import { Icon } from "@iconify/react";

const AdminDashboardActivityStream = ({ activities = [] }) => {
    return (
        <div className="card border shadow-sm h-100" style={{ borderRadius: "12px" }}>
            <div className="card-header bg-base py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                <div>
                    <h6 className="mb-0 fw-bold text-dark">Recent Platform Activity</h6>
                    <span className="text-xs text-secondary-light">Live stream of student attempts across partner schools</span>
                </div>
                <Icon icon="solar:history-bold-duotone" className="text-primary-600 text-xl" />
            </div>
            <div className="card-body p-20">
                {activities.length > 0 ? (
                    <div className="d-flex flex-column gap-3">
                        {activities.map((act) => (
                            <div key={act.id} className="d-flex align-items-center justify-content-between p-12 rounded-3 border bg-base border-neutral-200">
                                <div className="d-flex align-items-center gap-3">
                                    <div className={`w-32-px h-32-px rounded-circle d-flex align-items-center justify-content-center ${act.is_correct ? "bg-success-100 text-success-600" : "bg-danger-100 text-danger-600"}`}>
                                        <Icon icon={act.is_correct ? "solar:check-circle-bold" : "solar:close-circle-bold"} className="text-lg" />
                                    </div>
                                    <div>
                                        <h6 className="text-sm fw-bold text-primary-light mb-0">
                                            {act.student_name}
                                        </h6>
                                        <span className="text-xs text-secondary-light">
                                            Practiced <strong className="text-primary-600">{act.exercise_title}</strong>
                                        </span>
                                    </div>
                                </div>
                                <span className="text-xs text-secondary-light fw-medium">
                                    {act.time_ago}
                                </span>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="d-flex flex-column align-items-center justify-content-center py-5">
                        <Icon icon="solar:inbox-line-broken" className="text-secondary-light text-4xl mb-2" />
                        <p className="text-secondary-light text-sm mb-0">No recent activities recorded.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AdminDashboardActivityStream;
