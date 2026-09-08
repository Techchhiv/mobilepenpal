import React from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import LoadingSpinner from "../components/LoadingSpinner";

export default function ProfileRedirect() {
  const { loading, isSchoolUser } = useAuth();

  if (loading) return <LoadingSpinner />;

  return isSchoolUser ? (
    <Navigate to="/school/profile" replace />
  ) : (
    <Navigate to="/admin/profile" replace />
  );
}
