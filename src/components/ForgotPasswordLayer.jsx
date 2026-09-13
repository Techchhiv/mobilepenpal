import { Icon } from "@iconify/react/dist/iconify.js";
import React from "react";
import { Link } from "react-router-dom";
import penLogo from "../assets/images/pen_logo.png";

const ForgotPasswordLayer = () => {
  return (
    <>
      <section className="auth-page-section">
        <div className="auth-form-wrapper">
          <div className="auth-form-container">
            <div className="auth-logo-wrapper text-center">
              <Link to="/" className="d-inline-block">
                <img src={penLogo} alt="Khmer Penpal Logo" className="auth-logo-img" />
              </Link>
            </div>

            <h4 className="fw-bold mb-4 text-dark fs-4 text-center">Forgot Password</h4>
            <p className="mb-24 text-secondary-light text-sm text-center">
              Enter your registered email address and we will send you instructions to reset your password.
            </p>

            <form action="#">
              <div className="icon-field mb-16">
                <span className="icon top-50 translate-middle-y">
                  <Icon icon="mage:email" />
                </span>
                <input
                  type="email"
                  className="form-control h-56-px bg-neutral-50 radius-12"
                  placeholder="Enter Email"
                />
              </div>
              <button
                type="button"
                className="btn btn-primary text-sm btn-sm px-12 py-16 w-100 radius-12 mt-24"
                data-bs-toggle="modal"
                data-bs-target="#exampleModal"
              >
                Continue
              </button>
              <div className="text-center mt-20">
                <Link to="/sign-in-school" className="text-primary-600 fw-bold text-sm">
                  Back to Sign In
                </Link>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* Verification Modal */}
      <div
        className="modal fade"
        id="exampleModal"
        tabIndex={-1}
        aria-hidden="true"
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content radius-16 bg-base">
            <div className="modal-body p-40 text-center">
              <div className="mb-32">
                <Icon icon="solar:letter-bold-duotone" className="text-primary-600 text-6xl" />
              </div>
              <h6 className="mb-12">Verify your Email</h6>
              <p className="text-secondary-light text-sm mb-0">
                Thank you, check your email for instructions to reset your password.
              </p>
              <button
                type="button"
                className="btn btn-primary text-sm btn-sm px-12 py-16 w-100 radius-12 mt-32"
                data-bs-dismiss="modal"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ForgotPasswordLayer;