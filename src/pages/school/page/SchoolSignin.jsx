import { Icon } from "@iconify/react";
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import penLogo from "../../../assets/images/pen_logo.png";

const SchoolSignInLayer = () => {
  const [loginType, setLoginType] = useState("school"); // "school" or "teacher"
  const [emailOrId, setEmailOrId] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [schoolKey, setSchoolKey] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const navigate = useNavigate();
  const { isAuthenticated, login, user } = useAuth();

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/school", { replace: true });
    }
  }, [isAuthenticated, user, navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    if (submitting) return;
    setError("");
    setSubmitting(true);

    try {
      let payload, endpoint;

      if (loginType === "teacher") {
        payload = {
          teacher_id: emailOrId.trim(),
          password,
          school_key: schoolKey.trim(),
        };
        endpoint = "/teacher/login";
      } else {
        payload = {
          email: emailOrId.trim(),
          password,
          school_key: schoolKey.trim(),
        };
        endpoint = "/login";
      }

      const { data } = await API.post(endpoint, payload);

      setAuthToken(data.token);
      login(data.user || data.teacher, data.token, data.abilities);

      const hasSchoolId = Boolean(data.user?.school_id || data.teacher?.school_id);
      const roles = (data.user?.roles || data.teacher?.roles || []).map(r => r.name.toLowerCase());

      if (hasSchoolId || roles.includes("school-admin") || roles.includes("teacher") || roles.some(r => r.includes("manager"))) {
        navigate("/school", { replace: true });
      } else {
        navigate("/admin", { replace: true });
      }
    } catch (err) {
      const status = err?.response?.status;
      let msg = err?.response?.data?.message || "Login failed. Please check your credentials.";
      if (status === 422) msg = "Invalid credentials or school key.";
      setError(msg);
      console.error("Login error:", err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section className="auth-page-section">
      {/* Centered Login Card */}
      <div className="auth-form-wrapper">
        <div className="auth-form-container">
          <div className="auth-logo-wrapper text-center">
            <Link to="/" className="d-inline-block">
              <img src={penLogo} alt="Khmer Penpal Logo" className="auth-logo-img" />
            </Link>
          </div>

          <h4 className="fw-bold mb-4 text-dark fs-4 text-center">Sign In to your School Account</h4>
          <p className="mb-16 text-secondary-light text-sm text-center">
            Welcome back! Please enter your details.
          </p>

          {/* Switch Login Type Selector */}
          <div className="account-selector-container mb-16">
            <button
              type="button"
              className={`account-selector-btn ${loginType === "school" ? "active" : ""}`}
              onClick={() => setLoginType("school")}
            >
              School Admin
            </button>
            <button
              type="button"
              className={`account-selector-btn ${loginType === "teacher" ? "active" : ""}`}
              onClick={() => setLoginType("teacher")}
            >
              Teacher
            </button>
          </div>

          <form onSubmit={handleLogin}>
            {/* Email / Teacher ID Field */}
            <div className="mb-14">
              <label className="form-label text-sm fw-semibold text-dark mb-4">
                {loginType === "teacher" ? "Teacher ID" : "Email Address"}
              </label>
              <div className="auth-input-field">
                <Icon
                  icon={loginType === "teacher" ? "solar:user-id-linear" : "mage:email"}
                  className="input-icon"
                />
                <input
                  type={loginType === "teacher" ? "text" : "email"}
                  className="form-control auth-input-control w-100"
                  placeholder={loginType === "teacher" ? "Enter Teacher ID" : "Enter your email"}
                  value={emailOrId}
                  onChange={(e) => setEmailOrId(e.target.value)}
                  autoComplete={loginType === "teacher" ? "username" : "email"}
                  required
                />
              </div>
            </div>

            {/* Password Field with Show/Hide Toggle */}
            <div className="mb-14">
              <label className="form-label text-sm fw-semibold text-dark mb-4">Password</label>
              <div className="auth-input-field">
                <Icon icon="solar:lock-password-outline" className="input-icon" />
                <input
                  type={showPassword ? "text" : "password"}
                  className="form-control auth-input-control w-100"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  className="password-toggle-btn"
                  onClick={() => setShowPassword((prev) => !prev)}
                  tabIndex={-1}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  <Icon icon={showPassword ? "solar:eye-outline" : "solar:eye-closed-outline"} />
                </button>
              </div>
            </div>

            {/* School Key Field */}
            <div className="mb-16">
              <label className="form-label text-sm fw-semibold text-dark mb-4">School Key</label>
              <div className="auth-input-field">
                <Icon icon="mdi:school-outline" className="input-icon" />
                <input
                  type="text"
                  className="form-control auth-input-control w-100"
                  placeholder="Enter School Key"
                  value={schoolKey}
                  onChange={(e) => setSchoolKey(e.target.value)}
                  required
                />
              </div>
            </div>

            {/* Error Message Banner */}
            {error && (
              <div className="alert alert-danger d-flex align-items-center gap-8 py-10 px-16 radius-8 text-sm mb-14">
                <Icon icon="mdi:alert-circle" className="text-lg flex-shrink-0" />
                <div>{error}</div>
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={submitting}
              className="auth-submit-btn w-100"
            >
              {submitting ? (
                <>
                  <Icon icon="svg-spinners:180-ring-with-bg" className="text-xl me-2" />
                  <span>Signing In...</span>
                </>
              ) : (
                "Sign In"
              )}
            </button>
          </form>

          <div className="mt-16 text-center">
            <p className="text-sm text-secondary-light mb-0">
              Admin Login?{" "}
              <Link to="/sign-in-admin" className="text-primary-600 fw-semibold">
                Click here
              </Link>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default SchoolSignInLayer;
