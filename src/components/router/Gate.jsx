import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

export default function Gate({ roles = [], anyPerm = [], allPerm = [] }) {
  const { loading, isAuthenticated, user, isSuperAdmin, hasRole, hasPermission, hasAnyPermission } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;

  if (!isAuthenticated) {
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  const roleOK = isSuperAdmin || roles.length === 0 || roles.some(hasRole);
  const anyOK = isSuperAdmin || anyPerm.length === 0 || hasAnyPermission(anyPerm);
  const allOK = isSuperAdmin || allPerm.length === 0 || allPerm.every(hasPermission);

  if (!(roleOK && anyOK && allOK)) {
    // Redirect to correct sign-in page
    if (roles.includes("school-admin")) return <Navigate to="/sign-in-school" replace state={{ from: location }} />;
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
