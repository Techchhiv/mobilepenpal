import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

export default function Gate({ anyPerm = [], allPerm = [], children }) {
  const { loading, isAuthenticated, user, isSuperAdmin, hasPermission, hasAnyPermission } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;

  if (!isAuthenticated) {
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }
console.log("User roles:", user?.roles);
console.log("User permissions:", user?.permissions);

  // If no permissions specified, allow any authenticated user
  if (anyPerm.length === 0 && allPerm.length === 0) {
    return children || <Outlet />;
  }

  const anyOK = isSuperAdmin || anyPerm.length === 0 || hasAnyPermission(anyPerm);
  const allOK = isSuperAdmin || allPerm.length === 0 || allPerm.every(hasPermission);

  if (!(anyOK && allOK)) {
    if (user?.roles?.some(r => r.name.toLowerCase() === "school-admin")) {
      return <Navigate to="/school" replace />;
    }
    return <Navigate to="/admin" replace />;
  }

  return children || <Outlet />;
}
