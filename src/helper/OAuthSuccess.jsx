import React, { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const OAuthSuccess = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { loginWithToken } = useAuth();
  const [status, setStatus] =  useState("Signing you in with Google...");

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const token = params.get("token");
    const redirectPath = params.get("redirect") || "/";
    const userDataString = params.get("user");

    let userData = null;
    try {
      userData = JSON.parse(userDataString);
    } catch (error) {
      console.error("Invalid user data in query string:", error);
    }

    if (token && userData) {
      loginWithToken(token, userData);
      navigate(redirectPath);
    } else {
      setStatus("Authentication failed. Redirecting to sign in...");
      setTimeout(() => navigate("/sign-in"), 2000);
    }
  }, [location.search, loginWithToken, navigate]);

  return (
    <div className="d-flex justify-content-center align-items-center vh-100">
      <div>
        <h5>{status}</h5>
      </div>
    </div>
  );
};

export default OAuthSuccess;
