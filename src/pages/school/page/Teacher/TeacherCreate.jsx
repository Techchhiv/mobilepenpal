import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function TeacherCreate() {
  const navigate = useNavigate();

  const [submitting, setSubmitting] = useState(false);

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [subject, setSubject] = useState("");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const [uploadedImage, setUploadedImage] = useState(null);
  const [error, setError] = useState("");

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      setUploadedImage({ src: reader.result, file });
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const removeImage = () => setUploadedImage(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (password !== confirmPassword) {
      setError("Passwords do not match. Please verify password entries.");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    setSubmitting(true);
    try {
      const formData = new FormData();
      formData.append("name", name);
      formData.append("email", email);
      formData.append("phone", phone || "");
      formData.append("subject", subject || "");
      formData.append("password", password);

      if (uploadedImage?.src) {
        formData.append("photo", uploadedImage.src);
      }

      const res = await API.post("/school/teachers", formData);

      navigate("/school/teachers", {
        state: {
          flash: `Teacher "${name}" created successfully! (ID: ${res?.data?.teacher?.teacher_id ?? "—"})`,
        },
        replace: true,
      });
    } catch (err) {
      setError(
        err?.response?.data?.errors?.name?.[0] ||
        err?.response?.data?.errors?.email?.[0] ||
        err?.response?.data?.errors?.password?.[0] ||
        err?.response?.data?.errors?.photo?.[0] ||
        err?.response?.data?.message ||
        "Failed to create teacher account."
      );
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <SchoolLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center">
            <h3 className="card-title mb-0">Add New Teacher</h3>
            <Link to="/school/teachers" className="d-flex align-items-center btn btn-secondary">
              <Icon icon="mdi:arrow-left" className="me-3" />
              Back to Teachers
            </Link>
          </div>

          <div className="card-body">
            {error && (
              <div className="alert alert-danger">
                <Icon icon="mdi:alert-circle" className="me-2" />
                {error}
              </div>
            )}

            <form className="row gy-4" onSubmit={handleSubmit}>
              {/* Left Column: Avatar */}
              <div className="col-md-4">
                <div className="card h-100">
                  <div className="card-header bg-light">
                    <h6 className="mb-0">Teacher Photo</h6>
                  </div>
                  <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                    <div className="mb-3">
                      {uploadedImage?.src ? (
                        <div className="position-relative mx-auto" style={{ width: "150px", height: "150px" }}>
                          <button
                            type="button"
                            onClick={removeImage}
                            className="position-absolute top-0 end-0 z-1 text-danger btn btn-sm btn-light"
                            style={{ margin: "5px" }}
                          >
                            <Icon icon="radix-icons:cross-2" />
                          </button>
                          <img
                            className="w-100 h-100 object-fit-cover rounded-circle border"
                            src={uploadedImage.src}
                            alt="Preview"
                          />
                        </div>
                      ) : (
                        <div
                          className="mx-auto rounded-circle border d-flex align-items-center justify-content-center bg-light overflow-hidden"
                          style={{ width: "150px", height: "150px" }}
                        >
                          <Icon icon="mdi:account-circle" className="text-secondary" width="100%" height="100%" />
                        </div>
                      )}
                    </div>

                    <label className="d-flex align-items-center justify-content-center btn btn-outline-primary w-100">
                      <Icon icon="solar:camera-outline" className="me-3" />
                      Choose Photo
                      <input type="file" hidden accept="image/*" onChange={handleFileChange} />
                    </label>
                    <small className="text-muted d-block">JPG, PNG or GIF up to 5MB</small>

                    <div className="mt-3 p-3 bg-light rounded text-start">
                      <div className="d-flex align-items-center gap-2 text-primary fw-bold mb-1">
                        <Icon icon="mdi:information-outline" /> Login Access
                      </div>
                      <small className="text-muted d-block">
                        Teachers sign in to the portal using their registered email and account password.
                      </small>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column: Personal Details & Password */}
              <div className="col-md-8">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:account" className="me-3" />
                      Personal Details
                    </h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <div className="col-md-6">
                        <label className="form-label">
                          Full Name <Required />
                        </label>
                        <input
                          type="text"
                          className="form-control"
                          placeholder="e.g. John Doe"
                          value={name}
                          onChange={(e) => setName(e.target.value)}
                          required
                        />
                      </div>

                      <div className="col-md-6">
                        <label className="form-label">
                          Email Address <Required />
                        </label>
                        <input
                          type="email"
                          className="form-control"
                          placeholder="e.g. teacher@school.edu"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          required
                        />
                      </div>

                      <div className="col-md-6">
                        <label className="form-label">Phone Number</label>
                        <input
                          type="text"
                          className="form-control"
                          placeholder="e.g. +855 12 345 678"
                          value={phone}
                          onChange={(e) => setPhone(e.target.value)}
                        />
                      </div>

                      <div className="col-md-6">
                        <label className="form-label">Subject / Department</label>
                        <input
                          type="text"
                          className="form-control"
                          placeholder="e.g. Khmer Literature, Mathematics"
                          value={subject}
                          onChange={(e) => setSubject(e.target.value)}
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:lock" className="me-3" />
                      Account Password
                    </h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <div className="col-md-6">
                        <label className="form-label">
                          Password <Required />
                        </label>
                        <div className="position-relative">
                          <input
                            type={showPassword ? "text" : "password"}
                            className="form-control pe-5"
                            placeholder="At least 6 characters"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                          />
                          <button
                            type="button"
                            className="btn btn-link position-absolute top-50 end-0 translate-middle-y text-muted pe-3 text-decoration-none"
                            onClick={() => setShowPassword(!showPassword)}
                          >
                            <Icon icon={showPassword ? "mdi:eye-off" : "mdi:eye"} />
                          </button>
                        </div>
                      </div>

                      <div className="col-md-6">
                        <label className="form-label">
                          Confirm Password <Required />
                        </label>
                        <input
                          type={showPassword ? "text" : "password"}
                          className="form-control"
                          placeholder="Re-enter password"
                          value={confirmPassword}
                          onChange={(e) => setConfirmPassword(e.target.value)}
                          required
                        />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Form Actions */}
                <div className="d-flex justify-content-end gap-2">
                  <button type="submit" className="d-flex align-items-center btn btn-primary" disabled={submitting}>
                    {submitting ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2" role="status" /> Creating...
                      </>
                    ) : (
                      <>
                        <Icon icon="mdi:plus" className="me-2" /> Save Teacher
                      </>
                    )}
                  </button>
                  <Link to="/school/teachers" className="d-flex align-items-center btn btn-secondary">
                    Cancel
                  </Link>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
}
