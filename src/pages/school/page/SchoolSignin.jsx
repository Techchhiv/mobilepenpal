import { Icon } from "@iconify/react";
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import penLogo from "../../../assets/images/pen_logo.png";
import coverPen from "../../../assets/images/coverPen.png";

const SchoolSignInLayer = () => {
  const [loginType, setLoginType] = useState("school"); // "school" or "teacher"
  const [emailOrId, setEmailOrId] = useState("");
  const [password, setPassword] = useState("");
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

      const roles = (data.user?.roles || data.teacher?.roles || []).map(r => r.name.toLowerCase());

      if (roles.includes("school-admin") || roles.includes("teacher") || roles.includes("parent")) {
        navigate("/school", { replace: true });
      } else if (roles.includes("super-admin") || roles.includes("team-admin")) {
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
    <section className="auth bg-base d-flex flex-wrap">
      {/* Left Cover */}
      <div className="auth-left d-lg-block d-none">
        <div className="d-flex align-items-center flex-column h-100 justify-content-center">
          <img src={coverPen} alt="auth" />
        </div>
      </div>

      {/* Login Form */}
      <div className="auth-right py-32 px-24 d-flex flex-column justify-content-center">
        <div className="max-w-464-px mx-auto w-100">
          <Link to="/" className="mb-40 max-w-290-px d-block">
            <img src={penLogo} alt="logo" />
          </Link>
          <h4 className="mb-12">Sign In to your School Account</h4>
          <p className="mb-32 text-secondary-light text-lg">Welcome back! Please enter your details.</p>

          {/* Switch Login Type */}
          <div className="mb-16 d-flex gap-2">
            <button type="button" className={`btn ${loginType === "school" ? "btn-primary" : "btn-light"}`} onClick={() => setLoginType("school")}>School Admin</button>
            <button type="button" className={`btn ${loginType === "teacher" ? "btn-primary" : "btn-light"}`} onClick={() => setLoginType("teacher")}>Teacher</button>
          </div>

          <form onSubmit={handleLogin}>
            <div className="icon-field mb-16">
              <span className="icon top-50 translate-middle-y"><Icon icon="mage:email" /></span>
              <input
                type="text"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder={loginType === "teacher" ? "Teacher ID" : "Email"}
                value={emailOrId}
                onChange={e => setEmailOrId(e.target.value)}
                required
              />
            </div>

            <div className="position-relative mb-20">
              <div className="icon-field">
                <span className="icon top-50 translate-middle-y"><Icon icon="solar:lock-password-outline" /></span>
                <input
                  type="password"
                  className="form-control h-56-px bg-neutral-50 radius-12"
                  placeholder="Password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="icon-field mb-20">
              <span className="icon top-50 translate-middle-y"><Icon icon="mdi:school-outline" /></span>
              <input
                type="text"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder="School Key"
                value={schoolKey}
                onChange={e => setSchoolKey(e.target.value)}
                required
              />
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
              <span>Admin Login?</span>{" "}
              <Link to="/sign-in-admin" className="text-primary">Click here</Link>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default SchoolSignInLayer;
