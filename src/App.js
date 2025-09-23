// src/App.jsx
import React from "react";
import { Routes, Route, Outlet, Navigate, useParams } from "react-router-dom";
import RouteScrollToTop from "./helper/RouteScrollToTop";
import Gate from "./components/router/Gate";

// ---------- Public Pages ----------
import Frontend from "./frontend";
import ImageToWord from "./frontend/page/imageToWord";
import ProductDetail from "./frontend/page/ProductDetail";
import Product from "./frontend/page/Product";
import Cart from "./frontend/page/Cart";
import Favorite from "./frontend/page/FavoritePage";
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

// ---------- School Pages ----------
import SchoolLayout from "./pages/school/masterLayout/SchoolLayout";
import ManageTeacher from "./pages/school/page/ManageTeacher";
import SchoolDashboard from "./pages/school/page/SchoolDashboard";
// later: import ManageStudents, StudentPerformance, etc.

// ---------- Utils ----------
const LegacyProductRedirect = () => {
  const { slug } = useParams();
  return <Navigate to={`/product/${slug}`} replace />;
};

export default function App() {
  return (
    <>
      <RouteScrollToTop />
      <Routes>
        {/* ---------- Public Routes ---------- */}
        <Route path="/frontend" element={<Frontend />} />
        <Route path="/image-world" element={<ImageToWord />} />

        {/* Product routes */}
        <Route path="/product/:slug" element={<ProductDetail />} />
        <Route path="/product-detail/:slug" element={<LegacyProductRedirect />} />
        <Route path="/category/:slug" element={<Product />} />

        {/* Misc public */}
        <Route path="/cart" element={<Cart />} />
        <Route path="/favorite" element={<Favorite />} />
        <Route path="/sign-in" element={<SignInPage />} />
        <Route path="/sign-up" element={<SignUpPage />} />
        <Route path="/oauth-success" element={<OAuthSuccess />} />
        <Route path="/access-denied" element={<AccessDeniedPage />} />

        {/* ---------- Admin Routes (Protected) ---------- */}
        <Route
          element={
            <Gate
              roles={["admin", "super-admin"]}
              anyPerm={[
                "users.manage",
                "roles.manage",
                "permissions.manage",
              ]}
            >
              <Outlet />
            </Gate>
          }
        >
          <Route path="/admin" element={<HomePageOne />} />
          <Route path="/admin/users" element={<AdminUsersPage />} />
          <Route path="/admin/roles" element={<AdminRolesPage />} />
          <Route path="/admin/permissions" element={<AdminPermissionsPage />} />
          <Route path="/admin/schools" element={<ManageClientsPage />} />
        </Route>

        {/* ---------- School Routes (Protected) ---------- */}
        <Route
          element={
            <Gate
              roles={["school-admin", "teacher", "parent"]}
              anyPerm={[
                "teachers.view",
                "students.view",
                "school.dashboard.view",
              ]}
            >
                <Outlet />
             
            </Gate>
          }
        >
          <Route path="/school" element={<Navigate to="/school/dashboard" replace />} />
          <Route path="/school/dashboard" element={<SchoolDashboard />} />
          <Route path="/school/teachers" element={<ManageTeacher />} />
          {/* Add more later: */}
          {/* <Route path="/school/students" element={<ManageStudents />} /> */}
          {/* <Route path="/school/performance" element={<StudentPerformance />} /> */}
        </Route>

        {/* ---------- Fallback ---------- */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  );
}
