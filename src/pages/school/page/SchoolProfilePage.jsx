import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import API from "../../../helper/api";
import SchoolLayout from "../masterLayout/SchoolLayout";

// ─── helpers ────────────────────────────────────────────────────────────────

function prettyDate(d) {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function capitalize(str) {
  if (!str) return "";
  return str.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

// ─── component ──────────────────────────────────────────────────────────────

const SchoolProfilePage = () => {
  const [profile, setProfile] = useState(null);
  const [school, setSchool] = useState(null);
  const [loading, setLoading] = useState(true);

  // Edit form state
  const [form, setForm] = useState({ name: "", email: "", phone: "" });
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");
  const [formSuccess, setFormSuccess] = useState("");

  // Password form state
  const [pwForm, setPwForm] = useState({ current_password: "", password: "", password_confirmation: "" });
  const [pwSaving, setPwSaving] = useState(false);
  const [pwError, setPwError] = useState("");
  const [pwSuccess, setPwSuccess] = useState("");
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  // Key copy
  const [keyCopied, setKeyCopied] = useState(false);

  const fetchProfile = async () => {
    try {
      setLoading(true);
      const res = await API.get("/school/profile");
      const u = res.data?.user;
      const s = res.data?.school ?? null;
      setProfile(u);
      setSchool(s);
      setForm({
        name: u?.name || "",
        email: u?.email || "",
        phone: u?.phone || "",
      });
    } catch (err) {
      console.error("Failed to load profile:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  // Auto-dismiss alerts
  useEffect(() => {
    if (!formSuccess) return;
    const t = setTimeout(() => setFormSuccess(""), 3000);
    return () => clearTimeout(t);
  }, [formSuccess]);

  useEffect(() => {
    if (!pwSuccess) return;
    const t = setTimeout(() => setPwSuccess(""), 3000);
    return () => clearTimeout(t);
  }, [pwSuccess]);

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    setFormError("");
  };

  const handleProfileSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setFormError("");
    setFormSuccess("");
    try {
      await API.put("/school/profile", form);
      setFormSuccess("Profile updated successfully.");
      fetchProfile();
    } catch (err) {
      const errors = err?.response?.data?.errors;
      const msg = errors
        ? Object.values(errors).flat().join(" ")
        : err?.response?.data?.message || "Failed to save profile.";
      setFormError(msg);
    } finally {
      setSaving(false);
    }
  };

  const handlePwChange = (e) => {
    const { name, value } = e.target;
    setPwForm((prev) => ({ ...prev, [name]: value }));
    setPwError("");
  };

  const handlePasswordSave = async (e) => {
    e.preventDefault();
    if (pwForm.password !== pwForm.password_confirmation) {
      setPwError("New password and confirmation do not match.");
      return;
    }
    setPwSaving(true);
    setPwError("");
    setPwSuccess("");
    try {
      await API.put("/school/profile", {
        name: form.name,
        email: form.email,
        phone: form.phone,
        current_password: pwForm.current_password,
        password: pwForm.password,
        password_confirmation: pwForm.password_confirmation,
      });
      setPwSuccess("Password updated successfully.");
      setPwForm({ current_password: "", password: "", password_confirmation: "" });
    } catch (err) {
      const errors = err?.response?.data?.errors;
      const msg = errors
        ? Object.values(errors).flat().join(" ")
        : err?.response?.data?.message || "Failed to update password.";
      setPwError(msg);
    } finally {
      setPwSaving(false);
    }
  };

  const copyKey = async () => {
    if (!school?.school_key) return;
    try {
      await navigator.clipboard.writeText(school.school_key);
    } catch {
      const ta = document.createElement("textarea");
      ta.value = school.school_key;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
    }
    setKeyCopied(true);
    setTimeout(() => setKeyCopied(false), 1500);
  };

  const initials = (name) =>
    (name || "?")
      .split(" ")
      .slice(0, 2)
      .map((n) => n[0]?.toUpperCase() || "")
      .join("");

  // ─── render ───────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <SchoolLayout>
        <div className="d-flex align-items-center justify-content-center" style={{ minHeight: 300 }}>
          <div className="spinner-border text-primary me-3" role="status" />
          <span className="text-muted">Loading profile…</span>
        </div>
      </SchoolLayout>
    );
  }

  const roles = Array.isArray(profile?.roles) ? profile.roles : [];

  return (
    <SchoolLayout>
      <div className="row g-4">

        {/* ── LEFT: Profile Card ─────────────────────────────────────── */}
        <div className="col-12 col-lg-4">

          {/* User Identity Card */}
          <div className="card border mb-4">
            <div
              className="card-img-top"
              style={{
                background: "linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)",
                height: 80,
              }}
            />
            <div className="card-body text-center" style={{ marginTop: -40 }}>
              <div
                className="d-inline-flex align-items-center justify-content-center rounded-circle text-white fw-bold mx-auto mb-3 border border-white border-3"
                style={{
                  width: 80,
                  height: 80,
                  fontSize: 28,
                  background: "linear-gradient(135deg, #4f46e5, #7c3aed)",
                  boxShadow: "0 4px 12px rgba(79,70,229,.35)",
                }}
              >
                {initials(profile?.name)}
              </div>
              <h5 className="mb-1 fw-bold">{profile?.name || "—"}</h5>
              <p className="text-muted small mb-2">{profile?.email}</p>
              <div className="d-flex flex-wrap justify-content-center gap-1 mb-3">
                {roles.length > 0 ? (
                  roles.map((r, i) => (
                    <span key={i} className="badge bg-primary-light text-primary-600 px-2 py-1 rounded-pill text-xs fw-semibold">
                      {capitalize(r)}
                    </span>
                  ))
                ) : (
                  <span className="badge bg-secondary text-white rounded-pill text-xs">User</span>
                )}
              </div>

              <div className="border-top pt-3 text-start">
                <ul className="list-unstyled mb-0 small">
                  <li className="d-flex align-items-center gap-2 mb-2 text-muted">
                    <Icon icon="mdi:email-outline" className="text-primary" />
                    <span className="text-truncate">{profile?.email || "—"}</span>
                  </li>
                  {profile?.phone && (
                    <li className="d-flex align-items-center gap-2 mb-2 text-muted">
                      <Icon icon="mdi:phone-outline" className="text-primary" />
                      <span>{profile.phone}</span>
                    </li>
                  )}
                  <li className="d-flex align-items-center gap-2 text-muted">
                    <Icon icon="mdi:calendar-outline" className="text-primary" />
                    <span>Joined {prettyDate(profile?.created_at)}</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* School Info Card */}
          {school && (
            <div className="card border">
              <div className="card-header bg-light">
                <h6 className="mb-0 fw-semibold d-flex align-items-center gap-2">
                  <Icon icon="mdi:school-outline" className="text-primary" />
                  School Information
                </h6>
              </div>
              <div className="card-body">
                <div className="d-flex align-items-center gap-2 mb-3">
                  <div
                    className="d-inline-flex align-items-center justify-content-center rounded-circle bg-primary-light text-primary-600 flex-shrink-0"
                    style={{ width: 40, height: 40 }}
                  >
                    <Icon icon="mdi:school" width={20} />
                  </div>
                  <div>
                    <div className="fw-semibold">{school.name}</div>
                    <span className={`badge ${school.is_active ? "bg-success-focus text-success-main" : "bg-warning-focus text-warning-main"} text-xs rounded-pill`}>
                      {school.is_active ? "Active" : "Inactive"}
                    </span>
                  </div>
                </div>

                {/* School Key */}
                <div className="mb-3">
                  <div className="text-muted small mb-1">School Join Key</div>
                  <div className="d-flex align-items-center gap-2">
                    <code
                      className="bg-light border rounded px-2 py-1 text-xs flex-grow-1 text-truncate"
                      style={{ fontFamily: "monospace" }}
                    >
                      {school.school_key}
                    </code>
                    <button
                      type="button"
                      className={`btn btn-sm d-flex align-items-center gap-1 ${keyCopied ? "btn-success" : "btn-outline-secondary"}`}
                      onClick={copyKey}
                      title="Copy join key"
                    >
                      <Icon icon={keyCopied ? "mdi:check" : "mdi:content-copy"} />
                      {keyCopied ? "Copied" : "Copy"}
                    </button>
                  </div>
                </div>

                {/* Stats */}
                <div className="row g-2 mt-1">
                  <div className="col-4 text-center">
                    <div
                      className="p-2 rounded-3 bg-primary-light"
                    >
                      <div className="fw-bold text-primary-600 fs-5">{school.teachers_count ?? 0}</div>
                      <div className="text-muted text-xs">Teachers</div>
                    </div>
                  </div>
                  <div className="col-4 text-center">
                    <div className="p-2 rounded-3 bg-success-focus">
                      <div className="fw-bold text-success-main fs-5">{school.students_count ?? 0}</div>
                      <div className="text-muted text-xs">Students</div>
                    </div>
                  </div>
                  <div className="col-4 text-center">
                    <div className="p-2 rounded-3 bg-info-focus">
                      <div className="fw-bold text-info-main fs-5">{school.classrooms_count ?? 0}</div>
                      <div className="text-muted text-xs">Classes</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ── RIGHT: Edit Forms ──────────────────────────────────────── */}
        <div className="col-12 col-lg-8">

          {/* Personal Info Edit */}
          <div className="card border mb-4">
            <div className="card-header bg-light d-flex align-items-center gap-2">
              <Icon icon="mdi:account-edit-outline" className="text-primary" />
              <h6 className="mb-0 fw-semibold">Personal Information</h6>
            </div>
            <div className="card-body">
              {formError && (
                <div className="alert alert-danger d-flex align-items-center gap-2 py-2">
                  <Icon icon="mdi:alert-circle-outline" />
                  {formError}
                </div>
              )}
              {formSuccess && (
                <div className="alert alert-success d-flex align-items-center gap-2 py-2">
                  <Icon icon="mdi:check-circle-outline" />
                  {formSuccess}
                </div>
              )}
              <form onSubmit={handleProfileSave}>
                <div className="row g-3">
                  <div className="col-12 col-md-6">
                    <label className="form-label fw-semibold">
                      Full Name <span className="text-danger">*</span>
                    </label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:account-outline" />
                      </span>
                      <input
                        type="text"
                        className="form-control"
                        name="name"
                        value={form.name}
                        onChange={handleFormChange}
                        placeholder="e.g. John Doe"
                        required
                      />
                    </div>
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label fw-semibold">
                      Email Address <span className="text-danger">*</span>
                    </label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:email-outline" />
                      </span>
                      <input
                        type="email"
                        className="form-control"
                        name="email"
                        value={form.email}
                        onChange={handleFormChange}
                        placeholder="e.g. admin@school.edu"
                        required
                      />
                    </div>
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label fw-semibold">Phone Number</label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:phone-outline" />
                      </span>
                      <input
                        type="text"
                        className="form-control"
                        name="phone"
                        value={form.phone}
                        onChange={handleFormChange}
                        placeholder="e.g. +855 12 345 678"
                      />
                    </div>
                  </div>
                </div>

                <div className="d-flex justify-content-end mt-4">
                  <button type="submit" className="btn btn-primary d-flex align-items-center gap-2" disabled={saving}>
                    {saving ? (
                      <><span className="spinner-border spinner-border-sm" /> Saving…</>
                    ) : (
                      <><Icon icon="mdi:content-save-outline" /> Save Changes</>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>

          {/* Security / Password */}
          <div className="card border mt-4">
            <div className="card-header bg-light d-flex align-items-center gap-2 py-3">
              <Icon icon="mdi:shield-lock-outline" className="text-primary" />
              <h6 className="mb-0 fw-semibold">Change Password</h6>
            </div>
            <div className="card-body pt-4">
              {pwError && (
                <div className="alert alert-danger d-flex align-items-center gap-2 py-2">
                  <Icon icon="mdi:alert-circle-outline" />
                  {pwError}
                </div>
              )}
              {pwSuccess && (
                <div className="alert alert-success d-flex align-items-center gap-2 py-2">
                  <Icon icon="mdi:check-circle-outline" />
                  {pwSuccess}
                </div>
              )}
              <form onSubmit={handlePasswordSave}>
                <div className="row g-3">
                  <div className="col-12">
                    <label className="form-label fw-semibold">Current Password</label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:lock-outline" />
                      </span>
                      <input
                        type={showCurrent ? "text" : "password"}
                        className="form-control"
                        name="current_password"
                        value={pwForm.current_password}
                        onChange={handlePwChange}
                        placeholder="Enter your current password"
                      />
                      <button
                        type="button"
                        className="input-group-text bg-light border-start-0"
                        onClick={() => setShowCurrent(!showCurrent)}
                      >
                        <Icon icon={showCurrent ? "mdi:eye-off-outline" : "mdi:eye-outline"} />
                      </button>
                    </div>
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label fw-semibold">New Password</label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:lock-reset" />
                      </span>
                      <input
                        type={showNew ? "text" : "password"}
                        className="form-control"
                        name="password"
                        value={pwForm.password}
                        onChange={handlePwChange}
                        placeholder="Min. 8 characters"
                      />
                      <button
                        type="button"
                        className="input-group-text bg-light border-start-0"
                        onClick={() => setShowNew(!showNew)}
                      >
                        <Icon icon={showNew ? "mdi:eye-off-outline" : "mdi:eye-outline"} />
                      </button>
                    </div>
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label fw-semibold">Confirm New Password</label>
                    <div className="input-group">
                      <span className="input-group-text bg-light">
                        <Icon icon="mdi:lock-check-outline" />
                      </span>
                      <input
                        type={showConfirm ? "text" : "password"}
                        className="form-control"
                        name="password_confirmation"
                        value={pwForm.password_confirmation}
                        onChange={handlePwChange}
                        placeholder="Re-enter new password"
                      />
                      <button
                        type="button"
                        className="input-group-text bg-light border-start-0"
                        onClick={() => setShowConfirm(!showConfirm)}
                      >
                        <Icon icon={showConfirm ? "mdi:eye-off-outline" : "mdi:eye-outline"} />
                      </button>
                    </div>
                  </div>
                </div>

                <div className="d-flex justify-content-end mt-24">
                  <button
                    type="submit"
                    className="btn btn-warning d-flex align-items-center gap-2"
                    disabled={pwSaving || !pwForm.current_password || !pwForm.password}
                  >
                    {pwSaving ? (
                      <><span className="spinner-border spinner-border-sm" /> Updating…</>
                    ) : (
                      <><Icon icon="mdi:shield-lock-outline" /> Update Password</>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>

        </div>
      </div>
    </SchoolLayout>
  );
};

export default SchoolProfilePage;
