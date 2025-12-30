import React, { createContext, useContext, useEffect, useMemo, useState, useCallback } from "react";
import API from "../helper/api";
import { useNavigate } from "react-router-dom";

const AuthContext = createContext();
export const useAuth = () => useContext(AuthContext);

function deriveAuth(userObj) {
  const roles = Array.isArray(userObj?.roles) ? userObj.roles : [];
  const roleNames = roles.map(r => r?.name?.toLowerCase()).filter(Boolean);

  const permNames = Array.isArray(userObj?.permissions)
    ? userObj.permissions.map(p => (typeof p === "string" ? p : p?.name)?.toLowerCase()).filter(Boolean)
    : [];

  const isSuperAdmin = roleNames.includes("super-admin");
  const isSchoolAdmin = roleNames.includes("school-admin");
  const isTeacher = roleNames.includes("teacher");


  const hasRole = role => roleNames.includes(role.toLowerCase());
  const hasPermission = perm => isSuperAdmin || permNames.includes(perm.toLowerCase());
  const hasAnyPermission = perms => isSuperAdmin || perms.some(p => permNames.includes(p.toLowerCase()));

  return { roleNames, permNames, isSuperAdmin, isSchoolAdmin,isTeacher, hasRole, hasPermission, hasAnyPermission };
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(() => localStorage.getItem("token"));
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  // Set token in axios headers
  useEffect(() => {
    if (token) {
      API.defaults.headers.common.Authorization = `Bearer ${token}`;
      localStorage.setItem("token", token);
    } else {
      delete API.defaults.headers.common.Authorization;
      localStorage.removeItem("token");
    }
  }, [token]);

  
  // Bootstrap user from token
  useEffect(() => {
    const bootstrap = async () => {
      if (!token) {
        setUser(null);
        setLoading(false);
        return;
      }
      try {
        const { data } = await API.get("/me");
        setUser(data);
      } catch {
        setUser(null);
        setToken(null);
      } finally {
        setLoading(false);
      }
    };
    bootstrap();
  }, [token]);

  const login = useCallback((userData, newToken) => {
    setUser(userData);
    if (newToken) setToken(newToken);
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    setToken(null);
    navigate("/sign-in-admin", { replace: true });
  }, [navigate]);

  const derived = useMemo(() => deriveAuth(user || {}), [user]);

  return (
    <AuthContext.Provider value={{
      user,
      token,
      loading,
      isAuthenticated: !!user,
      isSuperAdmin: derived.isSuperAdmin,
      isSchoolAdmin: derived.isSchoolAdmin,
      isTeacher: derived.isTeacher, 
      hasRole: derived.hasRole,
      hasPermission: derived.hasPermission,
      hasAnyPermission: derived.hasAnyPermission,
      login,
      logout,
      setUser,
    }}>
      {children}
    </AuthContext.Provider>
  );
};
