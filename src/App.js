import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
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
import SchoolUsersPage from "./pages/school/page/SchoolUsersPage";
import SchoolRolesPage from "./pages/school/page/SchoolRolesPage";
import SchoolPermissionsPage from "./pages/school/page/SchoolPermissionsPage";
import TeacherList from "./pages/school/page/Teacher/TeacherList";
import TeacherCreate from "./pages/school/page/Teacher/TeacherCreate";
import ClassRoomsList from "./pages/school/page/ClassRooms/ClassRoomsList";

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

        {/* ---------- Admin Dashboard (all logged-in users) ---------- */}
        <Route path="/admin" element={<Gate><HomePageOne /></Gate>} />

        {/* ---------- Users / Roles / Permissions (Super Admin / Admin only) ---------- */}
        <Route
          element={
            <Gate anyPerm={["users.manage", "roles.manage", "permissions.manage"]} />}>
          <Route path="/admin/users" element={<AdminUscersPage />} />
          <Route path="/admin/roles" element={<AdminRolesPage />} />
          <Route path="/admin/permissions" element={<AdminPermissionsPage />} />
        </Route>


        {/* ---------- Manage Clients (Client Manager only) ---------- */}
        <Route
          element={<Gate anyPerm={["menu.manage_clients"]} />}
        >
          <Route path="/admin/schools" element={<ManageClientsPage />} />
        </Route>

        {/* ---------- Payments (Payment Manager only) ---------- */}
        <Route
          element={<Gate anyPerm={["menu.payments"]} />}
        >
          <Route path="/admin/payments" element={<ManagePaymentsPage />} />
          <Route path="/admin/schools/:schoolId/payments" element={<SchoolPayments />} />
        </Route>



        <Route path="/school" element={<Gate><SchoolDashboard /></Gate>} />

        {/* ---------- School Routes ---------- */}
        <Route element={<Gate anyPerm={["users.manage", "roles.manage", "permissions.manage"]} />}>
          <Route path="/school/users" element={<SchoolUsersPage />} />
          <Route path="/school/roles" element={<SchoolRolesPage />} />
          <Route path="/school/permissions" element={<SchoolPermissionsPage />} />
        </Route>

        <Route element={<Gate anyPerm={["teachers.view"]} />}>
          <Route path="/school/teachers_list" element={<TeacherList />} />
          <Route path="/school/teachers_create" element={<TeacherCreate />} />
        </Route>
        <Route element={<Gate anyPerm={["classrooms.view"]} />}>
          <Route path="/school/classroomslist" element={<ClassRoomsList />} />
        </Route>


        {/* ---------- Fallback ---------- */}
        <Route path="*" element={<Navigate to="/access-denied" replace />} />
      </Routes>
    </>
  );
}
