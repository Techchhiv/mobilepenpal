import React, { useEffect, useState } from "react";
import API from "../../helper/api";
import AdminDashboardHeader from "./AdminDashboardHeader";
import AdminDashboardUnitCount from "./AdminDashboardUnitCount";
import AdminDashboardTopSchools from "./AdminDashboardTopSchools";

const AdminDashboardLayer = () => {
    const [summary, setSummary] = useState(null);
    const [topSchools, setTopSchools] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
        try {
            setLoading(true);
            const response = await API.get("/admin/reports/schools");
            if (response.data && response.data.data) {
                setSummary(response.data.data.summary);
                setTopSchools(response.data.data.top_schools || []);
            }
        } catch (error) {
            console.error("Error fetching dashboard data:", error);
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
            <AdminDashboardUnitCount summary={summary} />

            <section className="row gy-4 mt-3">
                <AdminDashboardTopSchools schools={topSchools} />
            </section>
        </>
    );
};

export default AdminDashboardLayer;
