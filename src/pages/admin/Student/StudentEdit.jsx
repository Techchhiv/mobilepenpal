import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { useParams, Link, useNavigate } from "react-router-dom";
import MasterLayout from "../../../masterLayout/MasterLayout";
import API from "../../../helper/api";
import API_BASE_URL from "../../../helper/Base_urls";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function AdminStudentEdit() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [nickname, setNickname] = useState("");
  const [age, setAge] = useState("");
  const [gender, setGender] = useState("male");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");

  const [parentFirstName, setParentFirstName] = useState("");
  const [parentLastName, setParentLastName] = useState("");
  const [address, setAddress] = useState("");
  const [enrollmentYear, setEnrollmentYear] = useState("");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [uploadedImage, setUploadedImage] = useState(null);
  const [existingAvatar, setExistingAvatar] = useState(null);

  // School selection
  const [schools, setSchools] = useState([]);
  const [schoolId, setSchoolId] = useState("");

  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const [isAvatarModalOpen, setIsAvatarModalOpen] = useState(false);

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

  // Load schools for dropdown
  useEffect(() => {
    API.get("/schools/list")
      .then((res) => {
        const list = res.data?.data || res.data || [];
        setSchools(Array.isArray(list) ? list : []);
      })
      .catch(() => {});
  }, []);

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith("image/")) {
      setError("Please select a valid image file");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError("Image size should be less than 5MB");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      setUploadedImage({ src: reader.result });
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const removeNewImage = () => {
    setUploadedImage(null);
  };

  const fetchStudent = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await API.get(`/admin/students/${id}`);
      const s = res?.data?.data?.student || res?.data?.student || res?.data;

      setFirstName(s?.first_name ?? "");
      setLastName(s?.last_name ?? "");
      setNickname(s?.nickname ?? "");
      setAge(s?.age ?? "");
      setGender(s?.gender ?? "male");

      const dob = s?.date_of_birth ? String(s.date_of_birth).slice(0, 10) : "";
      setDateOfBirth(dob);

      setEmail(s?.email ?? "");
      setPhone(s?.phone ?? "");
      setParentFirstName(s?.parent_first_name ?? "");
      setParentLastName(s?.parent_last_name ?? "");
      setAddress(s?.address ?? "");
      setEnrollmentYear(s?.enrollment_year ?? "");
      setExistingAvatar(s?.avatar ?? null);
      setSchoolId(s?.school_id ?? "");
    } catch (err) {
      console.error("Fetch student error:", err);
      setError(err?.response?.data?.message || "Failed to load student.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStudent();
  }, [id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!firstName.trim() || !lastName.trim()) {
      setError("First name and last name are required");
      return;
    }
    if (!email.trim()) {
      setError("Email address is required");
      return;
    }
    if (!/\S+@\S+\.\S+/.test(email.trim())) {
      setError("Please enter a valid email address");
      return;
    }
    if (password && password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }
    if (password && password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        nickname: nickname.trim(),
        age,
        date_of_birth: dateOfBirth,
        gender,
        phone: phone.trim(),
        email: email.trim(),
        parent_first_name: parentFirstName.trim(),
        parent_last_name: parentLastName.trim(),
        address: address.trim(),
        enrollment_year: enrollmentYear,
        school_id: schoolId || null,
      };

      if (password) payload.password = password;
      if (uploadedImage?.src) payload.avatar = uploadedImage.src;

      await API.put(`/admin/students/${id}`, payload);

      navigate("/admin/students", {
        state: { success: `Student "${firstName} ${lastName}" updated successfully!` },
      });
    } catch (err) {
      console.error("Update student error:", err);
      const errors = err?.response?.data?.errors;
      setError(
        errors?.email?.[0] ||
        errors?.phone?.[0] ||
        errors?.first_name?.[0] ||
        errors?.last_name?.[0] ||
        errors?.password?.[0] ||
        err?.response?.data?.message ||
        "Failed to update student."
      );
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <MasterLayout>
        <div className="card">
          <div className="card-body text-center py-5">
            <div className="spinner-border" role="status" />
            <p className="mt-3 text-muted">Loading student…</p>
          </div>
        </div>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center">
            <h3 className="card-title mb-0">Edit Student — {displayName}</h3>
            <Link to="/admin/students" className="d-flex align-items-center btn btn-secondary">
              <Icon icon="mdi:arrow-left" className="me-3" />
              Back to Students
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
              {/* Avatar */}
              <div className="col-md-4">
                <div className="card h-100">
                  <div className="card-header bg-light">
                    <h6 className="mb-0">Profile Picture</h6>
                  </div>
                  <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                    <div className="mb-3">
                      {previewSrc ? (
                        <div className="position-relative mx-auto" style={{ width: '150px', height: '150px' }}>
                          {uploadedImage && (
                            <button
                              type="button"
                              onClick={removeNewImage}
                              className="position-absolute top-0 end-0 z-1 text-danger btn btn-sm btn-light"
                              style={{ margin: '5px' }}
                            >
                              <Icon icon="radix-icons:cross-2" />
                            </button>
                          )}
                          <img
                            className="w-100 h-100 object-fit-cover rounded-circle border"
                            src={previewSrc}
                            alt="Preview"
                            onClick={() => setIsAvatarModalOpen(true)}
                            style={{ cursor: "zoom-in" }}
                          />
                        </div>
                      ) : (
                        <div
                          className="mx-auto rounded-circle border d-flex align-items-center justify-content-center bg-light overflow-hidden"
                          style={{ width: '150px', height: '150px' }}
                        >
                          <Icon icon="mdi:account-circle" className="text-secondary" width="100%" height="100%" />
                        </div>
                      )}
                    </div>
                    <label className="d-flex align-items-center justify-content-center btn btn-outline-primary w-100">
                      <Icon icon="solar:camera-outline" className="me-3" />
                      {existingAvatar || uploadedImage ? "Change Photo" : "Upload Photo"}
                      <input type="file" hidden onChange={handleFileChange} accept="image/*" />
                    </label>
                    <small className="text-muted d-block">JPG or PNG, max 5MB</small>
                  </div>
                </div>
              </div>

              {/* Student Info */}
              <div className="col-md-8">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:account-school" className="me-3" />
                      Student Information
                    </h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <div className="col-md-6">
                        <label className="form-label">First Name <Required /></label>
                        <input className="form-control" value={firstName} onChange={(e) => setFirstName(e.target.value)} required />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Last Name <Required /></label>
                        <input className="form-control" value={lastName} onChange={(e) => setLastName(e.target.value)} required />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Nickname</label>
                        <input className="form-control" value={nickname} onChange={(e) => setNickname(e.target.value)} />
                      </div>
                      <div className="col-md-3">
                        <label className="form-label">Age</label>
                        <input type="number" className="form-control" value={age} onChange={(e) => setAge(e.target.value)} min="1" max="25" />
                      </div>
                      <div className="col-md-3">
                        <label className="form-label">Gender</label>
                        <select className="form-control" value={gender} onChange={(e) => setGender(e.target.value)}>
                          <option value="male">Male</option>
                          <option value="female">Female</option>
                        </select>
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Date of Birth</label>
                        <input type="date" className="form-control" value={dateOfBirth} onChange={(e) => setDateOfBirth(e.target.value)} max={new Date().toISOString().split('T')[0]} />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Email <Required /></label>
                        <input type="email" className="form-control" value={email} onChange={(e) => setEmail(e.target.value)} required />
                        <small className="text-muted">Used for login and must be unique</small>
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Enrollment Year</label>
                        <input type="number" className="form-control" value={enrollmentYear} onChange={(e) => setEnrollmentYear(e.target.value)} min="2000" max="2100" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* School Assignment */}
              <div className="col-12">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:school" className="me-3" />
                      School Assignment
                    </h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <div className="col-md-6">
                        <label className="form-label">Assign to School</label>
                        <select className="form-select" value={schoolId} onChange={(e) => setSchoolId(e.target.value)}>
                          <option value="">No School (Public Account)</option>
                          {schools.map((s) => (
                            <option key={s.id} value={s.id}>{s.name}</option>
                          ))}
                        </select>
                        <small className="text-muted">Change or remove school affiliation</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Parent Info */}
              <div className="col-12">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:account-group" className="me-3" />
                      Parent Information
                    </h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <div className="col-md-4">
                        <label className="form-label">Parent First Name</label>
                        <input className="form-control" value={parentFirstName} onChange={(e) => setParentFirstName(e.target.value)} />
                      </div>
                      <div className="col-md-4">
                        <label className="form-label">Parent Last Name</label>
                        <input className="form-control" value={parentLastName} onChange={(e) => setParentLastName(e.target.value)} />
                      </div>
                      <div className="col-md-4">
                        <label className="form-label">Phone Number</label>
                        <input type="tel" className="form-control" value={phone} onChange={(e) => setPhone(e.target.value)} />
                        <small className="text-muted">Optional contact number</small>
                      </div>
                      <div className="col-12">
                        <label className="form-label">Address</label>
                        <textarea className="form-control" rows="2" value={address} onChange={(e) => setAddress(e.target.value)} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Password */}
              <div className="col-12">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:lock" className="me-3" />
                      Change Password
                    </h6>
                  </div>
                  <div className="card-body">
                    <p className="text-muted mb-3">Leave blank to keep the current password.</p>
                    <div className="row g-3">
                      <div className="col-md-6">
                        <label className="form-label">New Password</label>
                        <input type="password" className="form-control" placeholder="Min 6 characters" value={password} onChange={(e) => setPassword(e.target.value)} />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label">Confirm New Password</label>
                        <input type="password" className="form-control" placeholder="Re-enter new password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="col-12">
                <div className="d-flex justify-content-end align-items-end gap-2">
                  <button className="d-flex align-items-center btn btn-primary" type="submit" disabled={submitting}>
                    <Icon icon="mdi:content-save" className="me-3" />
                    {submitting ? "Saving..." : "Save Changes"}
                  </button>
                  <Link to="/admin/students" className="d-flex align-items-center btn btn-secondary">
                    Cancel
                  </Link>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Avatar modal */}
      {isAvatarModalOpen && previewSrc && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100"
          style={{ background: "rgba(0,0,0,0.75)", zIndex: 1055, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}
          onClick={() => setIsAvatarModalOpen(false)}
          role="dialog"
          aria-modal="true"
        >
          <img
            src={previewSrc}
            alt="Avatar Preview"
            style={{ maxWidth: "95vw", maxHeight: "90vh", borderRadius: 12 }}
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </MasterLayout>
  );
}
