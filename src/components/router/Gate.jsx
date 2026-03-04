import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

export default function Gate({ anyPerm = [], allPerm = [], children }) {
  const { loading, isAuthenticated, user, isSuperAdmin, isSchoolAdmin, isSchoolUser, hasPermission, hasAnyPermission } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;

  if (!isAuthenticated) {
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  const isAdminRoute = location.pathname.startsWith("/admin");
  const isSchoolRoute = location.pathname.startsWith("/school");

  if (isAdminRoute && isSchoolUser) {
    return <Navigate to="/school" replace />;
  }

  if (isSchoolRoute && !isSchoolUser) {
    return <Navigate to="/admin" replace />;
  }

  if (isSuperAdmin) return children || <Outlet />;

  // Check permissions
  const anyOK = anyPerm.length === 0 || hasAnyPermission(anyPerm);
  const allOK = allPerm.length === 0 || allPerm.every(hasPermission);

  if (anyOK && allOK) return children || <Outlet />;

  if (isSchoolAdmin) return <Navigate to="/school" replace />;

  // Fallback for other roles (e.g., teacher, parent) → school dashboard
  if (user?.roles?.some(r => ["teacher", "parent"].includes(r.name.toLowerCase()))) {
    return <Navigate to="/school" replace />;
  }

  return <Navigate to="/sign-in-admin" replace />;
}
