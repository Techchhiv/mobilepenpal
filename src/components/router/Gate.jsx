import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

export default function Gate({ roles = [], anyPerm = [], allPerm = [] }) {
  const { loading, isAuthenticated, user, isSuperAdmin } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;
  if (!isAuthenticated) return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;

  const userRoles = (user?.roles || []).map(r => r.name);
  const userPerms = user?.permissions || [];

  const roleOK = isSuperAdmin || roles.length === 0 || roles.some(role => userRoles.includes(role));
  const anyOK = isSuperAdmin || anyPerm.length === 0 || anyPerm.some(perm => userPerms.includes(perm));
  const allOK = isSuperAdmin || allPerm.length === 0 || allPerm.every(perm => userPerms.includes(perm));

  if (!(roleOK && anyOK && allOK)) {
    if (roles.includes("school-admin")) return <Navigate to="/sign-in-school" replace state={{ from: location }} />;
    return <Navigate to="/sign-in-admin" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
