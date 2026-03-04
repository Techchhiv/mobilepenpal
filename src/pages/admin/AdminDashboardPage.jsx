import React from "react";
import MasterLayout from "../../masterLayout/MasterLayout";
import Breadcrumb from "../../components/Breadcrumb";
import AdminDashBoardLayer from "../../components/admin/AdminDashboardLayer";

const AdminDashboardPage = () => {
    return (
        <>
            <MasterLayout>
                {/* <Breadcrumb title="Dashboard" /> */}
                <AdminDashBoardLayer />
            </MasterLayout>
        </>
    );
};

export default AdminDashboardPage;
