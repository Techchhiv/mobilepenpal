// src/App.jsx
import React from "react";
import { Routes, Route, Outlet, Navigate, useParams } from "react-router-dom";
import RouteScrollToTop from "./helper/RouteScrollToTop";
import Gate from "./components/router/Gate";

// Public
import Frontend from "./frontend";
import ImageToWord from "./frontend/page/imageToWord";
import ProductDetail from "./frontend/page/ProductDetail"; // detail page (by slug)
import Product from "./frontend/page/Product";              // category listing
import Cart from "./frontend/page/Cart";
import Favorite from "./frontend/page/FavoritePage";
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";
import OAuthSuccess from "./helper/OAuthSuccess";
import AccessDeniedPage from "./pages/AccessDeniedPage";

// Admin
import HomePageOne from "./pages/HomePageOne";
import TableDataPage from "./pages/TableDataPage";
import Category from "./pages/Category";
import EditProduct from "./pages/EditProdcut";
import AdminUsersPage from "./pages/admin/AdminUsersPage";
import AdminRolesPage from "./pages/admin/AdminRolesPage";
import AdminPermissionsPage from "./pages/admin/AdminPermissionsPage";
import AddBlogPage from "./pages/AddBlogPage";

// legacy redirect: /product-detail/:slug  -> /product/:slug
const LegacyProductRedirect = () => {
  const { slug } = useParams();
  return <Navigate to={`/product/${slug}`} replace />;
};

export default function App() {
  return (
    <>
      <RouteScrollToTop />
      <Routes>
        {/* Public storefront landing */}
        <Route path="/Frontend" element={<Frontend />} />
        <Route path="/image_world" element={<ImageToWord />} />

        {/* ✅ Product detail by slug */}
        <Route path="/product/:slug" element={<ProductDetail />} />
        <Route path="/product-detail/:slug" element={<LegacyProductRedirect />} />

        {/* ✅ Category listing by slug */}
        <Route path="/category/:slug" element={<Product />} />

        {/* Misc public */}
        <Route path="/cart" element={<Cart />} />
        <Route path="/favorite" element={<Favorite />} />
        <Route path="/sign-in" element={<SignInPage />} />
        <Route path="/sign-up" element={<SignUpPage />} />
        <Route path="/oauth-success" element={<OAuthSuccess />} />
        <Route path="/access-denied" element={<AccessDeniedPage />} />

        {/* Admin (gated) */}
        <Route
          element={
            <Gate
              roles={["admin", "super-admin"]}
              anyPerm={[
                "users.manage",
                "roles.manage",
                "permissions.manage",
                "products.manage",
                "categories.manage",
              ]}
            >
              <Outlet />
            </Gate>
          }
        >
          <Route path="/" element={<HomePageOne />} />
          <Route path="/table-data" element={<TableDataPage />} />
          <Route path="/add-blog" element={<AddBlogPage />} />
          <Route path="/category" element={<Category />} />
          <Route path="/edit-product/:id" element={<EditProduct />} />
          <Route path="/admin/users" element={<AdminUsersPage />} />
          <Route path="/admin/roles" element={<AdminRolesPage />} />
          <Route path="/admin/permissions" element={<AdminPermissionsPage />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Frontend />} />
      </Routes>
    </>
  );
}
