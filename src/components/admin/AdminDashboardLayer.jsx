import React, { useEffect, useState } from "react";
import API from "../../helper/api";
import AdminDashboardHeader from "./AdminDashboardHeader";
import AdminDashboardUnitCount from "./AdminDashboardUnitCount";
import AdminDashboardQuickActions from "./AdminDashboardQuickActions";
import AdminDashboardPracticeChart from "./AdminDashboardPracticeChart";
import AdminDashboardActivityStream from "./AdminDashboardActivityStream";
import AdminDashboardTopSchools from "./AdminDashboardTopSchools";

const AdminDashboardLayer = () => {
    const [summary, setSummary] = useState(null);
    const [practiceTrend, setPracticeTrend] = useState([]);
    const [topSchools, setTopSchools] = useState([]);
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
        try {
            setLoading(true);
            const response = await API.get("/admin/reports/schools");
            if (response.data && response.data.data) {
                const d = response.data.data;
                setSummary(d.summary || null);
                setPracticeTrend(d.practice_trend || []);
                setTopSchools(d.top_schools || []);
                setActivities(d.recent_activities || []);
            }
        } catch (error) {
            console.error("Error fetching admin dashboard data:", error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '300px' }}>
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Loading...</span>
                </div>
            </div>
        );
    }

    return (
        <>
            <AdminDashboardHeader />

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
