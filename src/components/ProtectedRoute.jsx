import React from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import LoadingSpinner from "./LoadingSpinner";

const ProtectRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth(); // Access isAuthenticated from context

  if(loading){
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/sign-in" replace />;
  }

  return children;
};

export default ProtectRoute;
