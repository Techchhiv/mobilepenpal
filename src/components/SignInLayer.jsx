import { Icon } from "@iconify/react";
import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../helper/api";
import { useAuth } from "../context/AuthContext";
import penLogo from "../assets/images/pen_logo.png";
import coverPen from "../assets/images/coverPen.png";

const SignInLayer = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [schoolKey, setSchoolKey] = useState(""); // ✅ NEW
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const navigate = useNavigate();
  const { isAuthenticated, login } = useAuth();

  useEffect(() => {
    if (isAuthenticated) navigate("/admin");
  }, [isAuthenticated, navigate]);

const handleLogin = async (e) => {
  e.preventDefault();
  setError("");
  setSubmitting(true);

  try {
    const payload = { email: email.trim(), password };
    if (schoolKey.trim()) payload.school_key = schoolKey.trim();

    const { data } = await API.post("/login", payload);
    setAuthToken(data.token);

    // Save user to context
    if (login.length >= 2) {
      login(data.user, data.token, data.abilities);
    } else {
      login(data.user);
    }

    // ✅ Role-based redirect
    const roles = (data.user.roles || []).map((r) => r.name);

    if (roles.includes("super-admin") || roles.includes("team-admin")) {
      navigate("/admin/dashboard");
    } else if (
      roles.includes("school-admin") ||
      roles.includes("teacher") ||
      roles.includes("parent")
    ) {
      navigate("/school");
    } else {
      navigate("/admin"); // fallback
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
    <section className="auth bg-base d-flex flex-wrap">
      <div className="auth-left d-lg-block d-none">
        <div className="d-flex align-items-center flex-column h-100 justify-content-center">
          <img src={coverPen} alt="auth" />
        </div>
      </div>

      <div className="auth-right py-32 px-24 d-flex flex-column justify-content-center">
        <div className="max-w-464-px mx-auto w-100">
          <div>
            <Link to="/" className="mb-40 max-w-290-px d-block">
              <img src={penLogo} alt="logo" />
            </Link>
            <h4 className="mb-12">Sign In to your Account</h4>
            <p className="mb-32 text-secondary-light text-lg">
              Welcome back! Please enter your details.
            </p>
          </div>

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
                  id="your-password"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                />
              </div>
            </div>

            {/* ✅ NEW School Key input */}
            <div className="icon-field mb-20">
              <span className="icon top-50 translate-middle-y">
                <Icon icon="mdi:school-outline" />
              </span>
              <input
                type="text"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder="School Key (required for School Admins)"
                value={schoolKey}
                onChange={(e) => setSchoolKey(e.target.value)}
                required={false}
              />
            </div>

            <div className="d-flex justify-content-between gap-2">
              <div className="form-check style-check d-flex align-items-center">
                <input
                  className="form-check-input border border-neutral-300"
                  type="checkbox"
                  id="remember"
                />
                <label className="form-check-label" htmlFor="remember">
                  Remember me
                </label>
              </div>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="btn btn-primary text-sm btn-sm px-12 py-16 w-100 radius-12 mt-32"
            >
              {submitting ? "Signing in..." : "Sign In"}
            </button>

            {error && (
              <p className="mt-12" style={{ color: "red" }}>
                {error}
              </p>
            )}
          </form>
        </div>
      </div>
    </section>
  );
};

export default SignInLayer;
