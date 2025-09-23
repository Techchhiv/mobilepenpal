// src/router/Gate.jsx
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import LoadingSpinner from "../LoadingSpinner";

export default function Gate({ children, roles = [], anyPerm = [], allPerm = [] }) {
  const { loading, isAuthenticated, user, isSuperAdmin } = useAuth();
  const location = useLocation();

  if (loading) return <LoadingSpinner />;
  if (!isAuthenticated) return <Navigate to="/sign-in" replace state={{ from: location }} />;

  const hasRole = (r) => (user?.roles || []).some(x => x.name === r);
  const can     = (p) => isSuperAdmin || (user?.permissions || []).includes(p);

  const roleOK   = roles.length === 0 || roles.some(hasRole) || isSuperAdmin;
  const anyOK    = anyPerm.length === 0 || anyPerm.some(can);
  const allOK    = allPerm.length === 0 || allPerm.every(can);

  if (!(roleOK && anyOK && allOK)) return <Navigate to="/" replace />;

  return children;
}

