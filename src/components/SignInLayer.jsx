import { Icon } from "@iconify/react";
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../helper/api";
import { useAuth } from "../context/AuthContext";
import penLogo from "../assets/images/pen_logo.png";
import coverPen from "../assets/images/coverPen.png";

const AdminSignInLayer = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const navigate = useNavigate();
  const { isAuthenticated, login, user } = useAuth();

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated) {
      if (user?.school_id || user?.roles?.some(r => r.name.toLowerCase().includes("manager") || r.name.toLowerCase().includes("school"))) {
        navigate("/school", { replace: true });
      } else {
        navigate("/admin", { replace: true });
      }
    }
  }, [isAuthenticated, user, navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);

    try {
      const payload = { email: email.trim(), password };
      const { data } = await API.post("/login", payload);

      // Set token for subsequent requests
      setAuthToken(data.token);

      // Save user + token in AuthContext
      login(data.user, data.token);

      // Determine redirect dynamically based on role/permissions
      const hasSchoolId = Boolean(data.user?.school_id);
      const roles = (data.user.roles || []).map(r => r.name.toLowerCase());

      if (hasSchoolId || roles.includes("school-admin") || roles.includes("teacher") || roles.some(r => r.includes("manager"))) {
        navigate("/school", { replace: true });
      } else {
        navigate("/admin", { replace: true });
      }

    } catch (err) {
      const status = err?.response?.status;
      let msg = err?.response?.data?.message || err?.message || "Login failed. Please try again.";
      if (status === 422) msg = "Invalid credentials.";
      setError(msg);
      console.error("Login error:", err);
    } finally {
      setSubmitting(false);
    }
  };
  return (
    <section className="auth bg-base d-flex flex-wrap">
      <div className="auth-left d-lg-block d-none">
        <div className="d-flex align-items-center flex-column h-100 justify-content-center">
          <img src={coverPen} alt="auth" />
        </div>
      </div>

      <div className="auth-right py-32 px-24 d-flex flex-column justify-content-center">
        <div className="max-w-464-px mx-auto w-100">
          <Link to="/" className="mb-40 max-w-290-px d-block">
            <img src={penLogo} alt="logo" />
          </Link>
          <h4 className="mb-12">Sign In to your Account</h4>
          <p className="mb-32 text-secondary-light text-lg">
            Welcome back! Please enter your details.
          </p>

          <form onSubmit={handleLogin}>
            <div className="icon-field mb-16">
              <span className="icon top-50 translate-middle-y">
                <Icon icon="mage:email" />
              </span>
              <input
                type="email"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="username"
                required
              />
            </div>

            <div className="position-relative mb-20">
              <div className="icon-field">
                <span className="icon top-50 translate-middle-y">
                  <Icon icon="solar:lock-password-outline" />
                </span>
                <input
                  type="password"
                  className="form-control h-56-px bg-neutral-50 radius-12"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="btn btn-primary text-sm btn-sm px-12 py-16 w-100 radius-12 mt-32"
            >
              {submitting ? "Signing in..." : "Sign In"}
            </button>

            {error && <p className="mt-12 text-danger">{error}</p>}
          </form>

          <div className="mt-4 text-center">
            <p>
              <span>School Login?</span>{" "}
              <Link to="/sign-in-school" className="text-primary">
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
