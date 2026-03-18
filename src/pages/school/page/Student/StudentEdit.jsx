import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { useParams, Link, useNavigate } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";
import { useAuth } from "../../../../context/AuthContext";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function StudentEdit() {
  const { hasPermission } = useAuth();
  const { id } = useParams();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [nickname, setNickname] = useState("");
  const [age, setAge] = useState("");
  const [gender, setGender] = useState("male");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [phone, setPhone] = useState("");

  const [parentFirstName, setParentFirstName] = useState("");
  const [parentLastName, setParentLastName] = useState("");
  const [address, setAddress] = useState("");
  const [enrollmentYear, setEnrollmentYear] = useState("");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [uploadedImage, setUploadedImage] = useState(null);
  const [existingAvatar, setExistingAvatar] = useState(null);

  const [isAvatarModalOpen, setIsAvatarModalOpen] = useState(false);

  const openAvatarModal = () => {
    if (!previewSrc) return;
    setIsAvatarModalOpen(true);
  };

  const closeAvatarModal = () => setIsAvatarModalOpen(false);

  const [error, setError] = useState("");

  const avatarUrl = (path) => {
    if (!path) return null;
    if (String(path).startsWith("http")) return path;
    return `${API_BASE_URL}/${String(path).replace(/^\/+/, "")}`;
  };

  const previewSrc = useMemo(() => {
    if (uploadedImage?.src) return uploadedImage.src;
    if (existingAvatar) return avatarUrl(existingAvatar);
    return null;
  }, [uploadedImage, existingAvatar]);

  const displayName = useMemo(() => {
    const name = [firstName, lastName].filter(Boolean).join(" ").trim();
    return name || "Student";
  }, [firstName, lastName]);

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result;
      setUploadedImage({ src: base64, file: null });
    };
    reader.readAsDataURL(file);

    e.target.value = "";
  };


  const removeNewImage = () => {
    if (uploadedImage) URL.revokeObjectURL(uploadedImage.src);
    setUploadedImage(null);
  };

  const fetchStudent = async () => {
    setLoading(true);
    setError("");

    try {
      const res = await API.get(`/school/students/${id}`);
      const s = res?.data?.student || res?.data;

      setFirstName(s?.first_name ?? "");
      setLastName(s?.last_name ?? "");
      setNickname(s?.nickname ?? "");
      setAge(s?.age ?? "");
      setGender(s?.gender ?? "male");

      const dob = s?.date_of_birth ? String(s.date_of_birth).slice(0, 10) : "";
      setDateOfBirth(dob);

      setPhone(s?.phone ?? "");
      setParentFirstName(s?.parent_first_name ?? "");
      setParentLastName(s?.parent_last_name ?? "");
      setAddress(s?.address ?? "");

      const ey = s?.enrollment_year ? String(s.enrollment_year) : "";
      setEnrollmentYear(/^\d{4}/.test(ey) ? ey.slice(0, 4) : ey.slice(0, 10));

      setExistingAvatar(s?.avatar ?? null);
    } catch (err) {
      setError(err?.response?.data?.message || "Failed to load student.");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStudent();
    return () => {
      if (uploadedImage) URL.revokeObjectURL(uploadedImage.src);
    };
  }, [id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!hasPermission("children.update")) {
      setError("You don't have permission to update students.");
      return;
    }

    if (password || confirmPassword) {
      if (password !== confirmPassword) {
        setError("Passwords do not match.");
        return;
      }
      if (password.length > 0 && password.length < 6) {
        setError("Password must be at least 6 characters.");
        return;
      }
    }

    try {
      const formData = new FormData();

      formData.append("first_name", firstName);
      formData.append("last_name", lastName);

      formData.append("nickname", nickname || "");
      formData.append("age", age === "" ? "" : String(age));
      formData.append("gender", gender || "");
      formData.append("date_of_birth", dateOfBirth || "");
      formData.append("parent_first_name", parentFirstName || "");
      formData.append("parent_last_name", parentLastName || "");
      formData.append("address", address || "");
      formData.append("enrollment_year", enrollmentYear || "");

      if (password) formData.append("password", password);
      if (uploadedImage?.src) formData.append("avatar", uploadedImage.src);

      formData.append("_method", "PUT");

      await API.post(`/school/students/${id}`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      navigate("/school/students", {
        state: { flash: "Student updated successfully!" },
        replace: true,
      });
    } catch (err) {
      setError(
        err?.response?.data?.errors?.first_name?.[0] ||
        err?.response?.data?.errors?.last_name?.[0] ||
        err?.response?.data?.message ||
        "Failed to update student."
      );
      console.error(err);
    }
  };

  return (
    <SchoolLayout>
      <div className="col-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h4 className="card-title mb-0">Edit Student</h4>
            </div>

            <div className="d-flex gap-2">
              <Link to="/school/students" className="d-flex align-items-center btn btn-secondary">
                <Icon icon="mdi:arrow-left" className="me-6" />
                Back
              </Link>
            </div>
          </div>

          <div className="card-body">
            {error && <div className="alert alert-danger">{error}</div>}

            {loading ? (
              <div className="text-center py-40">
                <div className="spinner-border" role="status" />
                <div className="mt-12 text-muted">Loading student...</div>
              </div>
            ) : (
              <form onSubmit={handleSubmit}>

                <div className="row g-3">
                  <div className="col-12 col-lg-4">
                    <div className="card border">
                      <div className="card-header d-flex align-items-center gap-2">
                        <Icon icon="solar:camera-outline" />
                        <h6 className="mb-0">Avatar</h6>
                      </div>

                      <div className="card-body">
                        <div className="d-flex align-items-center gap-3">
                          <div
                            className="border radius-12 overflow-hidden bg-neutral-50 position-relative"
                            style={{ width: 120, height: 120 }}
                          >
                            {previewSrc ? (
                              <button
                                type="button"
                                onClick={openAvatarModal}
                                className="p-0 border-0 bg-transparent w-100 h-100"
                                title="Click to view"
                                style={{ cursor: "zoom-in" }}
                              >
                                <img
                                  className="w-100 h-100 object-fit-cover"
                                  src={previewSrc}
                                  alt="Avatar"
                                />
                                <span
                                  className="position-absolute bottom-0 end-0 m-2 bg-dark text-white rounded-circle d-flex align-items-center justify-content-center"
                                  style={{ width: 28, height: 28, opacity: 0.85 }}
                                >
                                  <Icon icon="mdi:magnify-plus-outline" width={18} />
                                </span>
                              </button>
                            ) : (
                              <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                <Icon icon="mdi:account" width={44} />
                              </div>
                            )}
                          </div>

                          <div className="flex-grow-1">
                            <div className="fw-semibold">{displayName}</div>
                            <div className="text-muted small">Student ID: {id}</div>

                            <div className="mt-10 d-flex gap-2 flex-wrap">
                              <label className="btn btn-outline-primary btn-sm mb-0">
                                <Icon icon="solar:camera-outline" className="me-6" />
                                Upload
                                <input
                                  type="file"
                                  hidden
                                  accept="image/*"
                                  onChange={handleFileChange}
                                />
                              </label>

                              {uploadedImage && (
                                <button
                                  type="button"
                                  className="btn btn-outline-danger btn-sm"
                                  onClick={removeNewImage}
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
                        <h6 className="mb-0">Student Information</h6>
                      </div>
                      <div className="card-body">
                        <div className="row gy-3">
                          <div className="col-md-6">
                            <label className="form-label">
                              First Name <Required />
                            </label>
                            <input
                              className="form-control"
                              value={firstName}
                              onChange={(e) => setFirstName(e.target.value)}
                              required
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">
                              Last Name <Required />
                            </label>
                            <input
                              className="form-control"
                              value={lastName}
                              onChange={(e) => setLastName(e.target.value)}
                              required
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Nickname</label>
                            <input
                              className="form-control"
                              value={nickname}
                              onChange={(e) => setNickname(e.target.value)}
                              placeholder="Optional"
                            />
                          </div>

                          <div className="col-md-3">
                            <label className="form-label">Age</label>
                            <input
                              type="number"
                              className="form-control"
                              value={age}
                              onChange={(e) => setAge(e.target.value)}
                              min={1}
                              placeholder="Optional"
                            />
                          </div>

                          <div className="col-md-3">
                            <label className="form-label">Gender</label>
                            <select
                              className="form-control"
                              value={gender}
                              onChange={(e) => setGender(e.target.value)}
                            >
                              <option value="male">Male</option>
                              <option value="female">Female</option>
                              <option value="other">Other</option>
                            </select>
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Date of Birth</label>
                            <input
                              type="date"
                              className="form-control"
                              value={dateOfBirth}
                              onChange={(e) => setDateOfBirth(e.target.value)}
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">
                              Phone{" "}
                              <span className="text-muted small">
                                (read-only)
                              </span>
                            </label>
                            <input
                              className="form-control"
                              value={phone}
                              onChange={(e) => setPhone(e.target.value)}
                              disabled
                              title="Phone editing is disabled (not in UpdateUserRequest)."
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    
                    <div className="card border mb-3">
                      <div className="card-header d-flex align-items-center gap-2">
                        <Icon icon="mdi:account-group" />
                        <h6 className="mb-0">Parent & Extra</h6>
                      </div>
                      <div className="card-body">
                        <div className="row gy-3">
                          <div className="col-md-6">
                            <label className="form-label">Parent First Name</label>
                            <input
                              className="form-control"
                              value={parentFirstName}
                              onChange={(e) => setParentFirstName(e.target.value)}
                              placeholder="Optional"
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Parent Last Name</label>
                            <input
                              className="form-control"
                              value={parentLastName}
                              onChange={(e) => setParentLastName(e.target.value)}
                              placeholder="Optional"
                            />
                          </div>

                          <div className="col-12">
                            <label className="form-label">Address</label>
                            <input
                              className="form-control"
                              value={address}
                              onChange={(e) => setAddress(e.target.value)}
                              placeholder="Village / Commune / District / Province"
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Enrollment Year</label>
                            <input
                              className="form-control"
                              value={enrollmentYear}
                              onChange={(e) => setEnrollmentYear(e.target.value)}
                              placeholder="e.g. 2024"
                              maxLength={10}
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
                            <label className="form-label">New Password</label>
                            <input
                              type="password"
                              className="form-control"
                              placeholder="Leave empty to keep current"
                              value={password}
                              onChange={(e) => setPassword(e.target.value)}
                            />
                            <div className="form-text">
                              Leave blank if you don’t want to change it.
                            </div>
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Confirm New Password</label>
                            <input
                              type="password"
                              className="form-control"
                              placeholder="Re-type new password"
                              value={confirmPassword}
                              onChange={(e) => setConfirmPassword(e.target.value)}
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="d-flex justify-content-end gap-3 flex-wrap">
                      <button className="d-flex align-items-center btn btn-primary" type="submit">
                        <Icon icon="mdi:content-save" className="me-6" />
                        Save Changes
                      </button>

                      <button
                        type="button"
                        className="btn btn-outline-secondary"
                        onClick={() => navigate("/school/students")}
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>

      {isAvatarModalOpen && previewSrc && (
        <>
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
            onClick={closeAvatarModal}
            role="dialog"
            aria-modal="true"
          >
            <img
              src={previewSrc}
              alt="Avatar Large"
              style={{
                maxWidth: "95vw",
                maxHeight: "90vh",
                borderRadius: 12,
                cursor: "default",
              }}
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        </>
      )}
    </SchoolLayout>
  );
}
