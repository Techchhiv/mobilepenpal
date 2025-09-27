import React from "react";
import { Routes, Route, Outlet, Navigate, useParams } from "react-router-dom";
import RouteScrollToTop from "./helper/RouteScrollToTop";
import Gate from "./components/router/Gate";

// ---------- Public Pages ----------
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";
import OAuthSuccess from "./helper/OAuthSuccess";
import AccessDeniedPage from "./pages/AccessDeniedPage";

// ---------- Admin Pages ----------
import HomePageOne from "./pages/HomePageOne";
import AdminUsersPage from "./pages/admin/AdminUsersPage";
import AdminRolesPage from "./pages/admin/AdminRolesPage";
import AdminPermissionsPage from "./pages/admin/AdminPermissionsPage";
import ManageClientsPage from "./pages/admin/ManageClientsPage";
import ManagePaymentsPage from "./pages/admin/ManagePaymentsPage";
import SchoolPayments from "./pages/admin/SchoolPayments";

// ---------- School Pages ----------
import SchoolSignInLayer from "./pages/school/page/SchoolSignin";
import SchoolDashboard from "./pages/school/page/SchoolDashboard";
import ManageTeacher from "./pages/school/page/ManageTeacher";


export default function App() {
  return (
    <>
      <RouteScrollToTop />
      <Routes>
        {/* ---------- Public Routes ---------- */}
        <Route path="/sign-in-admin" element={<SignInPage />} />
        <Route path="/sign-in-school" element={<SchoolSignInLayer />} />
        <Route path="/sign-up" element={<SignUpPage />} />
        <Route path="/oauth-success" element={<OAuthSuccess />} />
        <Route path="/access-denied" element={<AccessDeniedPage />} />

        {/* ---------- Admin Routes ---------- */}
        <Route
          element={
            <Gate roles={["admin", "super-admin"]} anyPerm={["console.view"]} />
          }
        >
          <Route path="/admin" element={<HomePageOne />} />
        </Route>

        {/* ---------- Manage Clients ---------- */}
        <Route
          element={
            <Gate
              roles={["client-manager"]}
              anyPerm={["manage_clients.manage"]}
            />
          }
        >
          <Route path="/admin/schools" element={<ManageClientsPage />} />
        </Route>

        {/* ---------- Payments ---------- */}
        <Route
          element={
            <Gate
              roles={["Payment Admin"]}
              anyPerm={["payments.manage"]}
            />
          }
        >
          <Route path="/admin/payments" element={<ManagePaymentsPage />} />
          <Route path="/admin/schools/:schoolId/payments" element={<SchoolPayments />} />
        </Route>

        {/* ---------- Users / Roles / Permissions ---------- */}
        <Route
          element={
            <Gate
              roles={["admin", "super-admin"]}
              anyPerm={["users.manage", "roles.manage", "permissions.manage"]}
            />
          }
        >
          <Route path="/admin/users" element={<AdminUsersPage />} />
          <Route path="/admin/roles" element={<AdminRolesPage />} />
          <Route path="/admin/permissions" element={<AdminPermissionsPage />} />
        </Route>

        {/* ---------- School Routes ---------- */}
        <Route
          element={
            <Gate
              roles={["school-admin", "teacher", "parent"]}
              anyPerm={["school.dashboard.view"]}
            />
          }
        >
          <Route path="/school" element={<SchoolDashboard />} />
          <Route path="/school/teachers" element={<ManageTeacher />} />
        </Route>

        {/* ---------- Fallback ---------- */}
        <Route path="*" element={<Navigate to="/#" replace />} />
      </Routes>
    </>
  );
}
