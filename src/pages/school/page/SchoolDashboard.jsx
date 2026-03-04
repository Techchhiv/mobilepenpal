import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import SchoolLayout from "../masterLayout/SchoolLayout";
import SchoolDashboardHeader from "../../../components/school/SchoolDashboardHeader";
import API from "../../../helper/api";

function SchoolDashboard() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchDashboard = async () => {
            try {
                const res = await API.get("/school/dashboard");
                if (res.data?.success) {
                    setData(res.data.data);
                }
            } catch (err) {
                console.error("Error fetching school dashboard:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchDashboard();
    }, []);

    const sub = data?.subscription;

    return (
        <>
            <SchoolLayout>
                {/* Header with greeting, date, and clock */}
                <SchoolDashboardHeader />

                {loading ? (
                    <div className="d-flex justify-content-center align-items-center" style={{ minHeight: "200px" }}>
                        <div className="spinner-border text-primary" role="status">
                            <span className="visually-hidden">Loading...</span>
                        </div>
                    </div>
                ) : (
                    <div className="row row-cols-xxxl-4 row-cols-lg-2 row-cols-sm-2 row-cols-1 gy-4">
                        {/* Total Students */}
                        <div className="col">
                            <div className="card shadow-none border bg-gradient-start-1 h-100">
                                <div className="card-body p-20">
                                    <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                                        <div>
                                            <p className="fw-medium text-primary-light mb-1">Total Students</p>
                                            <h6 className="mb-0">{data?.total_students ?? 0}</h6>
                                        </div>
                                        <div className="w-50-px h-50-px bg-cyan rounded-circle d-flex justify-content-center align-items-center">
                                            <Icon icon="gridicons:multiple-users" className="text-white text-2xl mb-0" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Total Teachers */}
                        <div className="col">
                            <div className="card shadow-none border bg-gradient-start-2 h-100">
                                <div className="card-body p-20">
                                    <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                                        <div>
                                            <p className="fw-medium text-primary-light mb-1">Total Teachers</p>
                                            <h6 className="mb-0">{data?.total_teachers ?? 0}</h6>
                                        </div>
                                        <div className="w-50-px h-50-px bg-purple rounded-circle d-flex justify-content-center align-items-center">
                                            <Icon icon="mdi:teach" className="text-white text-2xl mb-0" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Student Progress (Exercise Attempts) */}
                        <div className="col">
                            <div className="card shadow-none border bg-gradient-start-3 h-100">
                                <div className="card-body p-20">
                                    <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                                        <div>
                                            <p className="fw-medium text-primary-light mb-1">Total Exercise Attempts</p>
                                            <h6 className="mb-0">{data?.total_exercise_attempts ?? 0}</h6>
                                        </div>
                                        <div className="w-50-px h-50-px bg-info rounded-circle d-flex justify-content-center align-items-center">
                                            <Icon icon="fluent:target-arrow-24-filled" className="text-white text-2xl mb-0" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Subscription Status */}
                        <div className="col">
                            <div className="card shadow-none border bg-gradient-start-4 h-100">
                                <div className="card-body p-20">
                                    <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                                        <div>
                                            <p className="fw-medium text-primary-light mb-1">Subscription</p>
                                            {sub?.is_active ? (
                                                <>
                                                    <h6 className="mb-0 text-capitalize">{sub.plan}</h6>
                                                    <p className="fw-medium text-sm text-primary-light mt-4 mb-0">
                                                        Expires: {new Date(sub.end_date).toLocaleDateString()} ({sub.days_left} days left)
                                                    </p>
                                                </>
                                            ) : (
                                                <h6 className="mb-0 text-danger-main">Inactive</h6>
                                            )}
                                        </div>
                                        <div className={`w-50-px h-50-px ${sub?.is_active ? "bg-success-main" : "bg-red"} rounded-circle d-flex justify-content-center align-items-center`}>
                                            <Icon icon="fa-solid:award" className="text-white text-2xl mb-0" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </SchoolLayout>
        </>
    );
}

export default SchoolDashboard;