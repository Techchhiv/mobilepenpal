import React, { useEffect, useState } from "react";
import API from "../../helper/api";
import AdminDashboardHeader from "./AdminDashboardHeader";
import AdminDashboardUnitCount from "./AdminDashboardUnitCount";
import AdminFinancialSummary from "./AdminFinancialSummary";
import AdminNeedsAttention from "./AdminNeedsAttention";
import AdminDashboardQuickActions from "./AdminDashboardQuickActions";
import AdminDashboardPracticeChart from "./AdminDashboardPracticeChart";
import AdminDashboardActivityStream from "./AdminDashboardActivityStream";
import AdminDashboardTopSchools from "./AdminDashboardTopSchools";
import AdminErrorState from "./common/AdminErrorState";

const AdminDashboardLayer = () => {
    const [summary, setSummary] = useState(null);
    const [financialSummary, setFinancialSummary] = useState(null);
    const [practiceTrend, setPracticeTrend] = useState([]);
    const [topSchools, setTopSchools] = useState([]);
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
        try {
            setLoading(true);
            setError(null);
            const response = await API.get("/admin/reports/schools");
            if (response.data && response.data.data) {
                const d = response.data.data;
                setSummary(d.summary || null);
                setFinancialSummary(d.financial_summary || d.summary?.financial || null);
                setPracticeTrend(d.practice_trend || []);
                setTopSchools(d.top_schools || []);
                setActivities(d.recent_activities || []);
            }
        } catch (err) {
            console.error("Error fetching admin dashboard data:", err);
            setError(err?.response?.data?.message || err.message || "Failed to load dashboard statistics.");
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="py-12">
                <AdminDashboardHeader />
                <div className="card border radius-12 p-24 mb-24 placeholder-glow">
                    <span className="placeholder col-4 mb-16" style={{ height: '24px', display: 'block' }}></span>
                    <div className="row g-20">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="col-md-4 col-12">
                                <span className="placeholder col-12 radius-8" style={{ height: '90px', display: 'block' }}></span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="py-12">
                <AdminDashboardHeader />
                <AdminErrorState
                    title="Failed to Load Dashboard Data"
                    message={error}
                    onRetry={fetchDashboardData}
                />
            </div>
        );
    }

    return (
        <>
            <AdminDashboardHeader />

            {/* Financial Summary: Total Revenue | Total Expenses | Net Profit */}
            <AdminFinancialSummary
                financial={financialSummary}
                onExpenseUpdated={fetchDashboardData}
            />

            {/* Needs Attention: Billing & Subscription Action Items */}
            <AdminNeedsAttention />

            <div className="mb-24">
                <AdminDashboardUnitCount summary={summary} />
            </div>

            <AdminDashboardQuickActions />

            <div className="row gy-4 mb-24">
                <div className="col-12 col-xl-8">
                    <AdminDashboardPracticeChart practiceTrend={practiceTrend} />
                </div>
                <div className="col-12 col-xl-4">
                    <AdminDashboardActivityStream activities={activities} />
                </div>
            </div>

            <section className="row gy-4">
                <div className="col-12">
                    <AdminDashboardTopSchools schools={topSchools} />
                </div>
            </section>
        </>
    );
};

export default AdminDashboardLayer;
