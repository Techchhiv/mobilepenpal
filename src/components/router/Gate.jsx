// src/components/router/Gate.js
import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";
import { hasRole, hasAnyPermission, hasAllPermissions, isSuperAdmin } from "../../utils/permissions";

export default function Gate({ roles = [], anyPerm = [], allPerm = [] }) {
  const { loading, isAuthenticated, user } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;

  // If user is not authenticated, redirect to sign-in page
  if (!isAuthenticated) {
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  const userRoles = (user?.roles || []).map((r) => r.name);
  const userPerms = user?.permissions || [];

  // Use helper functions for role and permission checks
  const roleOK = isSuperAdmin(userRoles) || roles.length === 0 || roles.some((role) => hasRole(userRoles, role));
  const anyOK = isSuperAdmin(userRoles) || anyPerm.length === 0 || hasAnyPermission(userPerms, anyPerm);
  const allOK = isSuperAdmin(userRoles) || allPerm.length === 0 || hasAllPermissions(userPerms, allPerm);

  if (!(roleOK && anyOK && allOK)) {
    // Redirect to sign-in page based on role
    if (roles.includes("school-admin")) {
      return <Navigate to="/sign-in-school" replace state={{ from: location }} />;
    }
    // Fallback to sign-in-admin if not school-admin
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
