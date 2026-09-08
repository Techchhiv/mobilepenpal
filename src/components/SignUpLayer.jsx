import { Icon } from "@iconify/react/dist/iconify.js";
import React from "react";
import { Link } from "react-router-dom";
import penLogo from "../assets/images/pen_logo.png";

const SignUpLayer = () => {
  return (
    <section className="auth-page-section">
      <div className="auth-form-wrapper">
        <div className="auth-form-container">
          <div className="auth-logo-wrapper text-center">
            <Link to="/" className="d-inline-block">
              <img src={penLogo} alt="Khmer Penpal Logo" className="auth-logo-img" />
            </Link>
          </div>

          <h4 className="fw-bold mb-4 text-dark fs-4 text-center">Sign Up to your Account</h4>
          <p className="mb-24 text-secondary-light text-sm text-center">
            Welcome! Please enter your details to create an account.
          </p>

          <form action="#">
            <div className="icon-field mb-16">
              <span className="icon top-50 translate-middle-y">
                <Icon icon="f7:person" />
              </span>
              <input
                type="text"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder="Username"
              />
            </div>
            <div className="icon-field mb-16">
              <span className="icon top-50 translate-middle-y">
                <Icon icon="mage:email" />
              </span>
              <input
                type="email"
                className="form-control h-56-px bg-neutral-50 radius-12"
                placeholder="Email"
              />
            </div>
            <div className="mb-20">
              <div className="position-relative">
                <div className="icon-field">
                  <span className="icon top-50 translate-middle-y">
                    <Icon icon="solar:lock-password-outline" />
                  </span>
                  <input
                    type="password"
                    className="form-control h-56-px bg-neutral-50 radius-12"
                    id="your-password"
                    placeholder="Password"
                  />
                </div>
                <span
                  className="toggle-password ri-eye-line cursor-pointer position-absolute end-0 top-50 translate-middle-y me-16 text-secondary-light"
                  data-toggle="#your-password"
                />
              </div>
              <span className="mt-12 text-sm text-secondary-light d-block">
                Your password must have at least 8 characters
              </span>
            </div>
            <div>
              <div className="d-flex justify-content-between gap-2">
                <div className="form-check style-check d-flex align-items-start">
                  <input
                    className="form-check-input border border-neutral-300 mt-4"
                    type="checkbox"
                    defaultValue=""
                    id="condition"
                  />
                  <label className="form-check-label text-sm ms-2" htmlFor="condition">
                    By creating an account means you agree to the{" "}
                    <Link to="#" className="text-primary-600 fw-semibold">
                      Terms &amp; Conditions
                    </Link>{" "}
                    and our{" "}
                    <Link to="#" className="text-primary-600 fw-semibold">
                      Privacy Policy
                    </Link>
                  </label>
                </div>
              </div>
            </div>
            <button
              type="submit"
              className="btn btn-primary text-sm btn-sm px-12 py-16 w-100 radius-12 mt-24"
            >
              Sign Up
            </button>
            <div className="mt-24 text-center text-sm">
              <p className="mb-0">
                Already have an account?{" "}
                <Link to="/sign-in-school" className="text-primary-600 fw-semibold">
                  Sign In
                </Link>
              </p>
            </div>
          </form>
        </div>
      </div>
    </section>
  );
};

export default SignUpLayer;
