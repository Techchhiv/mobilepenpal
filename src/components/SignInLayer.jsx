import { Icon } from "@iconify/react";
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../helper/api";
import { useAuth } from "../context/AuthContext";
import penLogo from "../assets/images/pen_logo.png";

const AdminSignInLayer = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const navigate = useNavigate();
  const { isAuthenticated, login, user } = useAuth();

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated) {
      if (
        user?.school_id ||
        user?.roles?.some(
          (r) =>
            r.name.toLowerCase().includes("manager") ||
            r.name.toLowerCase().includes("school")
        )
      ) {
        navigate("/school", { replace: true });
      } else {
        navigate("/admin", { replace: true });
      }
    }
  }, [isAuthenticated, user, navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    if (submitting) return;
    setError("");
    setSubmitting(true);

    try {
      const payload = { email: email.trim(), password };
      const { data } = await API.post("/login", payload);

      setAuthToken(data.token);
      login(data.user, data.token);

      const hasSchoolId = Boolean(data.user?.school_id);
      const roles = (data.user?.roles || []).map((r) => r.name.toLowerCase());

      if (
        hasSchoolId ||
        roles.includes("school-admin") ||
        roles.includes("teacher") ||
        roles.some((r) => r.includes("manager"))
      ) {
        navigate("/school", { replace: true });
      } else {
        navigate("/admin", { replace: true });
      }
    } catch (err) {
      const status = err?.response?.status;
      let msg =
        err?.response?.data?.message ||
        err?.message ||
        "Login failed. Please try again.";
      if (status === 422) msg = "Invalid credentials.";
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

          <h4 className="fw-bold mb-4 text-dark fs-4 text-center">Sign In to your Admin Account</h4>
          <p className="mb-16 text-secondary-light text-sm text-center">
            Welcome back! Please enter your details.
          </p>

          <form onSubmit={handleLogin}>
            {/* Email Field */}
            <div className="mb-14">
              <label className="form-label text-sm fw-semibold text-dark mb-4">
                Email Address
              </label>
              <div className="auth-input-field">
                <Icon icon="mage:email" className="input-icon" />
                <input
                  type="email"
                  className="form-control auth-input-control w-100"
                  placeholder="Enter your admin email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            {/* Password Field with Show/Hide Toggle */}
            <div className="mb-16">
              <label className="form-label text-sm fw-semibold text-dark mb-4">
                Password
              </label>
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
                  <Icon
                    icon={showPassword ? "solar:eye-outline" : "solar:eye-closed-outline"}
                  />
                </button>
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
              School Login?{" "}
              <Link to="/sign-in-school" className="text-primary-600 fw-semibold">
                Click here
              </Link>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AdminSignInLayer;
