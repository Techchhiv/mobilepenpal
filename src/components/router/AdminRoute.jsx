// src/router/AdminRoute.jsx
// import { Navigate, useLocation } from "react-router-dom";
// import { useAuth } from "../context/AuthContext";
// import LoadingSpinner from "../components/LoadingSpinner";

// export default function AdminRoute({ children }) {
//   const { user, loading, isSuperAdmin } = useAuth();
//   const location = useLocation();

//   if (loading) return <LoadingSpinner />;

//   // allow super-admin OR anyone with 'admin' role
//   const hasAdminRole =
//     isSuperAdmin || (user?.roles || []).some(r => ["admin","super-admin"].includes(r.name));

//   if (!hasAdminRole) return <Navigate to="/" replace state={{ from: location }} />;

//   return children;
// }
 