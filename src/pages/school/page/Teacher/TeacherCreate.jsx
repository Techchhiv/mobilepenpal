import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function TeacherCreate() {
  const { hasPermission } = useAuth();
  const navigate = useNavigate();

  const [submitting, setSubmitting] = useState(false);

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [subject, setSubject] = useState("");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");


  const [uploadedImage, setUploadedImage] = useState(null);
  const [error, setError] = useState("");


  const [previewSrc, setPreviewSrc] = useState(null);
  const closePreview = () => setPreviewSrc(null);

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && closePreview();
    if (previewSrc) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [previewSrc]);


  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      setUploadedImage({ src: reader.result });
    };
    reader.readAsDataURL(file);

    e.target.value = "";
  };

  const removeImage = () => setUploadedImage(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
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


      if (uploadedImage?.src) formData.append("photo", uploadedImage.src);

      const res = await API.post("/school/teachers", formData);

      navigate("/school/teachers", {
        state: {
          flash: `Teacher created successfully! ID: ${res?.data?.teacher?.teacher_id ?? "—"
            }`,
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
        "Failed to create teacher."
      );
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <SchoolLayout>
      <div className="col-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h5 className="card-title mb-0">Add New Teacher</h5>
              <small className="text-muted">Create teacher account & profile</small>
            </div>

            <div className="d-flex gap-2">
              <Link to="/school/teachers" className="d-flex align-items-center btn btn-secondary">
                <Icon icon="mdi:arrow-left" className="me-6" />
                Back
              </Link>
            </div>
          </div>

          <div className="card-body">
            {error && <div className="alert alert-danger">{error}</div>}

            <form onSubmit={handleSubmit}>
              <div className="row g-3">

                <div className="col-12 col-lg-4">
                  <div className="card border">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="solar:camera-outline" />
                      <h6 className="mb-0">Photo</h6>
                    </div>

                    <div className="card-body">
                      <div className="d-flex align-items-center gap-3">
                        <div
                          className="border radius-12 overflow-hidden bg-neutral-50"
                          style={{ width: 120, height: 120 }}
                        >
                          {uploadedImage?.src ? (
                            <button
                              type="button"
                              className="p-0 border-0 bg-transparent w-100 h-100"
                              onClick={() => setPreviewSrc(uploadedImage.src)}
                              style={{ cursor: "zoom-in" }}
                              title="Click to view"
                              disabled={submitting}
                            >
                              <img
                                className="w-100 h-100 object-fit-cover"
                                src={uploadedImage.src}
                                alt="Preview"
                              />
                            </button>
                          ) : (
                            <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                              <Icon icon="mdi:account" width={44} />
                            </div>
                          )}
                        </div>

                        <div className="flex-grow-1">
                          <div className="fw-semibold">Teacher Profile</div>

                          <div className="mt-10 d-flex gap-2 flex-wrap">
                            <label
                              className={`btn btn-outline-primary btn-sm mb-0 ${submitting ? "disabled" : ""
                                }`}
                              style={submitting ? { pointerEvents: "none", opacity: 0.6 } : {}}
                            >
                              <Icon icon="solar:camera-outline" className="me-6" />
                              Upload
                              <input
                                type="file"
                                hidden
                                accept="image/*"
                                onChange={handleFileChange}
                                disabled={submitting}
                              />
                            </label>

                            {uploadedImage && (
                              <button
                                type="button"
                                className="btn btn-outline-danger btn-sm"
                                onClick={removeImage}
                                disabled={submitting}
                              >
                                <Icon icon="radix-icons:cross-2" className="me-6" />
                                Remove
                              </button>
                            )}
                          </div>

                          <div className="text-muted small mt-8">
                            Recommended: square image (jpg/png).
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>


                <div className="col-12 col-lg-8">
                  <div className="card border mb-3">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:account" />
                      <h6 className="mb-0">Teacher Information</h6>
                    </div>
                    <div className="card-body">
                      <div className="row gy-3">
                        <div className="col-md-6">
                          <label className="form-label">
                            Full Name <Required />
                          </label>
                          <input
                            className="form-control"
                            placeholder="Enter full name"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            required
                            disabled={submitting}
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">
                            Email <Required />
                          </label>
                          <input
                            type="email"
                            className="form-control"
                            placeholder="Enter email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            disabled={submitting}
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">Phone</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="+855 000 000"
                            value={phone}
                            onChange={(e) => setPhone(e.target.value)}
                            disabled={submitting}
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">Subject</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Khmer Writing"
                            value={subject}
                            onChange={(e) => setSubject(e.target.value)}
                            disabled={submitting}
                          />
                        </div>
                      </div>
                    </div>
                  </div>


                  <div className="card border mb-3">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:lock" />
                      <h6 className="mb-0">Security</h6>
                    </div>
                    <div className="card-body">
                      <div className="row gy-3">
                        <div className="col-md-6">
                          <label className="form-label">
                            Password <Required />
                          </label>
                          <input
                            type="password"
                            className="form-control"
                            placeholder="Enter password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            disabled={submitting}
                          />
                          <div className="form-text">Use at least 6 characters.</div>
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">
                            Confirm Password <Required />
                          </label>
                          <input
                            type="password"
                            className="form-control"
                            placeholder="Confirm password"
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            required
                            disabled={submitting}
                          />
                        </div>
                      </div>
                    </div>
                  </div>


                  <div className="d-flex justify-content-end gap-3 flex-wrap">
                    <button className="d-flex align-items-center btn btn-primary" type="submit" disabled={submitting}>
                      <Icon icon="mdi:account-plus" className="me-6" />
                      {submitting ? "Creating..." : "Create Teacher"}
                    </button>

                    <button
                      type="button"
                      className="btn btn-outline-secondary"
                      onClick={() => navigate("/school/teachers")}
                      disabled={submitting}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>


      {previewSrc && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100"
          style={{
            background: "rgba(0,0,0,0.75)",
            zIndex: 1055,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 16,
          }}
          onClick={closePreview}
          role="dialog"
          aria-modal="true"
        >
          <img
            src={previewSrc}
            alt="Photo Preview"
            style={{
              maxWidth: "95vw",
              maxHeight: "90vh",
              borderRadius: 12,
              cursor: "default",
            }}
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </SchoolLayout>
  );
}
