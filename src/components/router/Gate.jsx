import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

/**
 * Gate — route permission guard.
 *
 * Props:
 *   anyPerm       {string[]}  — user must have at least one of these permissions
 *   allPerm       {string[]}  — user must have ALL of these permissions
 *   superAdminOnly {boolean}  — only Super Admin may access; all others get redirected
 *   children                  — used when Gate wraps a single element (not an Outlet pattern)
 */
export default function Gate({ anyPerm = [], allPerm = [], superAdminOnly = false, children }) {
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

  // Super Admin bypasses all checks
  if (isSuperAdmin) return children || <Outlet />;

  // Super Admin only routes — block everyone else
  if (superAdminOnly) {
    return <Navigate to="/access-denied" replace />;
  }

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
