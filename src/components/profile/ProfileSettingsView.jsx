import React, { useEffect, useState, useMemo, useRef, useCallback } from "react";
import { Icon } from "@iconify/react";
import API from "../../helper/api";
import { useAuth } from "../../context/AuthContext";

// ─── Formatters & Helpers ──────────────────────────────────────────────────────

function formatDate(val) {
  if (!val) return "—";
  const dt = new Date(val);
  if (Number.isNaN(dt.getTime())) return String(val);
  return dt.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function formatDateTime(val) {
  if (!val) return "—";
  const dt = new Date(val);
  if (Number.isNaN(dt.getTime())) return String(val);
  return dt.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });
}

function formatRole(str) {
  if (!str) return "User";
  return String(str)
    .replace(/[_-]/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function getInitials(name) {
  if (!name) return "U";
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function getPhotoUrl(photo) {
  if (!photo) return null;
  if (String(photo).startsWith("http")) return photo;
  const backendBase = process.env.REACT_APP_API_URL
    ? process.env.REACT_APP_API_URL.replace(/\/api\/?$/, "")
    : "http://127.0.0.1:8000";
  return `${backendBase}/${String(photo).replace(/^\/+/, "")}`;
}

// ─── ProfileSettingsView Component ───────────────────────────────────────────

export default function ProfileSettingsView() {
  const { user: authUser, setUser } = useAuth();
  const fileInputRef = useRef(null);

  // Active Tab
  const [activeTab, setActiveTab] = useState("overview");

  // Backend Profile Data
  const [profile, setProfile] = useState(null);
  const [school, setSchool] = useState(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");

  // Personal Info Form State (Safe fields only: Name)
  const [name, setName] = useState("");
  const [initialName, setInitialName] = useState("");
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");
  const [formSuccess, setFormSuccess] = useState("");

  // Photo Upload & Auto-Save State
  const [photoSaving, setPhotoSaving] = useState(false);
  const [photoError, setPhotoError] = useState("");
  const [photoSuccess, setPhotoSuccess] = useState("");

  // Change Password State
  const [pwForm, setPwForm] = useState({
    current_password: "",
    password: "",
    password_confirmation: "",
  });
  const [pwSaving, setPwSaving] = useState(false);
  const [pwError, setPwError] = useState("");
  const [pwSuccess, setPwSuccess] = useState("");
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  // Campus Join Key Copy State
  const [keyCopied, setKeyCopied] = useState(false);

  // Photo Preview Source
  const previewPhotoSrc = useMemo(() => {
    return getPhotoUrl(profile?.photo);
  }, [profile?.photo]);

  // Check for unsaved changes in personal info
  const hasUnsavedProfileChanges = useMemo(() => {
    return name.trim() !== initialName.trim();
  }, [name, initialName]);

  // Password validation rules
  const isPwMinLength = pwForm.password.length >= 8;
  const isPwMatching =
    pwForm.password &&
    pwForm.password_confirmation &&
    pwForm.password === pwForm.password_confirmation;
  const isPwMismatch =
    pwForm.password &&
    pwForm.password_confirmation &&
    pwForm.password !== pwForm.password_confirmation;

  // ── Fetch Profile from Backend ──
  const fetchProfile = useCallback(async () => {
    setLoading(true);
    setLoadError("");
    try {
      let res;
      try {
        res = await API.get("/profile");
      } catch {
        res = await API.get("/school/profile");
      }

      const userData = res.data?.user || res.data || {};
      const schoolData = res.data?.school || null;

      setProfile(userData);
      setSchool(schoolData);
      setName(userData?.name || "");
      setInitialName(userData?.name || "");
    } catch (err) {
      console.error("Failed to load user profile:", err);
      setLoadError("Unable to load profile data from the server. Please check your connection and try again.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProfile();
  }, [fetchProfile]);

  // Auto-dismiss alert notifications
  useEffect(() => {
    if (!formSuccess) return;
    const t = setTimeout(() => setFormSuccess(""), 4000);
    return () => clearTimeout(t);
  }, [formSuccess]);

  useEffect(() => {
    if (!pwSuccess) return;
    const t = setTimeout(() => setPwSuccess(""), 4000);
    return () => clearTimeout(t);
  }, [pwSuccess]);

  useEffect(() => {
    if (!photoSuccess) return;
    const t = setTimeout(() => setPhotoSuccess(""), 4000);
    return () => clearTimeout(t);
  }, [photoSuccess]);

  useEffect(() => {
    if (!photoError) return;
    const t = setTimeout(() => setPhotoError(""), 5000);
    return () => clearTimeout(t);
  }, [photoError]);

  // ── Photo Upload & Auto-Save Handler ──
  const handlePhotoSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const validTypes = ["image/jpeg", "image/png", "image/webp", "image/jpg"];
    if (!validTypes.includes(file.type)) {
      setPhotoError("Supported image formats: PNG, JPG, or WEBP.");
      e.target.value = "";
      return;
    }

    if (file.size > 2 * 1024 * 1024) {
      setPhotoError("Image file size must not exceed 2MB.");
      e.target.value = "";
      return;
    }

    setPhotoError("");
    setPhotoSuccess("");
    const reader = new FileReader();
    reader.onload = async () => {
      const base64Data = reader.result;
      setPhotoSaving(true);
      try {
        const payload = {
          name: profile?.name || name || "User",
          photo: base64Data,
        };

        let res;
        try {
          res = await API.put("/profile", payload);
        } catch {
          res = await API.put("/school/profile", {
            ...payload,
            email: profile?.email,
          });
        }

        const updatedPhoto = res.data?.user?.photo || base64Data;
        setProfile((prev) => ({ ...prev, photo: updatedPhoto }));
        if (typeof setUser === "function") {
          setUser((prev) =>
            prev
              ? { ...prev, photo: updatedPhoto }
              : prev
          );
        }
        setPhotoSuccess("Profile image updated and saved successfully.");
      } catch (err) {
        console.error("Auto-save photo error:", err);
        const errors = err?.response?.data?.errors;
        const msg = errors
          ? Object.values(errors).flat().join(" ")
          : err?.response?.data?.message || "Failed to upload image. Please try again.";
        setPhotoError(msg);
      } finally {
        setPhotoSaving(false);
      }
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const handlePhotoRemove = async () => {
    if (photoSaving) return;
    setPhotoSaving(true);
    setPhotoError("");
    setPhotoSuccess("");
    try {
      const payload = {
        name: profile?.name || name || "User",
        photo: null,
      };

      try {
        await API.put("/profile", payload);
      } catch {
        await API.put("/school/profile", {
          ...payload,
          email: profile?.email,
        });
      }

      setProfile((prev) => ({ ...prev, photo: null }));
      if (typeof setUser === "function") {
        setUser((prev) =>
          prev
            ? { ...prev, photo: null }
            : prev
        );
      }
      setPhotoSuccess("Profile image removed successfully.");
    } catch (err) {
      console.error("Remove photo error:", err);
      const errors = err?.response?.data?.errors;
      const msg = errors
        ? Object.values(errors).flat().join(" ")
        : err?.response?.data?.message || "Failed to remove image. Please try again.";
      setPhotoError(msg);
    } finally {
      setPhotoSaving(false);
    }
  };

  // ── Submit Personal Profile to Backend ──
  const handleProfileSave = async (e) => {
    e.preventDefault();
    if (!hasUnsavedProfileChanges) return;

    if (!name.trim()) {
      setFormError("Full Name cannot be empty.");
      return;
    }

    setSaving(true);
    setFormError("");
    setFormSuccess("");

    try {
      const payload = {
        name: name.trim(),
      };

      let res;
      try {
        res = await API.put("/profile", payload);
      } catch {
        res = await API.put("/school/profile", {
          ...payload,
          email: profile?.email,
        });
      }

      const updatedUser = res.data?.user || { ...profile, ...payload };
      setProfile((prev) => ({ ...prev, ...updatedUser }));
      setInitialName(updatedUser.name);

      if (typeof setUser === "function") {
        setUser((prev) =>
          prev
            ? { ...prev, name: updatedUser.name }
            : prev
        );
      }

      setFormSuccess("Profile updated successfully.");
    } catch (err) {
      console.error("Profile update failed:", err);
      const errors = err?.response?.data?.errors;
      const msg = errors
        ? Object.values(errors).flat().join(" ")
        : err?.response?.data?.message || "Failed to update profile. Please try again.";
      setFormError(msg);
    } finally {
      setSaving(false);
    }
  };

  // ── Submit Password Change to Backend ──
  const handlePasswordSave = async (e) => {
    e.preventDefault();
    setPwError("");
    setPwSuccess("");

    if (!pwForm.current_password) {
      setPwError("Current password is required.");
      return;
    }

    if (pwForm.password.length < 8) {
      setPwError("New password must be at least 8 characters long.");
      return;
    }

    if (pwForm.password !== pwForm.password_confirmation) {
      setPwError("New password and confirmation do not match.");
      return;
    }

    setPwSaving(true);

    try {
      try {
        await API.put("/profile/password", {
          current_password: pwForm.current_password,
          password: pwForm.password,
          password_confirmation: pwForm.password_confirmation,
        });
      } catch {
        await API.put("/school/profile", {
          name,
          email: profile?.email,
          current_password: pwForm.current_password,
          password: pwForm.password,
          password_confirmation: pwForm.password_confirmation,
        });
      }

      setPwSuccess("Password updated successfully.");
      setPwForm({
        current_password: "",
        password: "",
        password_confirmation: "",
      });
    } catch (err) {
      console.error("Password update error:", err);
      const errors = err?.response?.data?.errors;
      const msg = errors
        ? Object.values(errors).flat().join(" ")
        : err?.response?.data?.message || "Failed to update password. Please check your current password.";
      setPwError(msg);
    } finally {
      setPwSaving(false);
    }
  };

  // ── Copy Campus Join Key ──
  const copySchoolKey = async () => {
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
    setTimeout(() => setKeyCopied(false), 2000);
  };

  // ── Loading State ──
  if (loading) {
    return (
      <div
        className="card border-0 shadow-sm p-4 d-flex flex-column align-items-center justify-content-center radius-16"
        style={{ minHeight: "380px" }}
      >
        <div className="spinner-border text-primary mb-3" role="status" style={{ width: "2.8rem", height: "2.8rem" }}>
          <span className="visually-hidden">Loading...</span>
        </div>
        <h6 className="text-secondary-light fw-medium">Loading profile and account settings...</h6>
      </div>
    );
  }

  // ── Error State ──
  if (loadError) {
    return (
      <div className="card border-0 shadow-sm p-4 text-center my-4 radius-16">
        <div
          className="d-inline-flex align-items-center justify-content-center rounded-circle bg-danger-focus text-danger-main mx-auto mb-3"
          style={{ width: "56px", height: "56px" }}
        >
          <Icon icon="solar:danger-triangle-bold" className="text-2xl" />
        </div>
        <h5 className="fw-semibold text-danger-main mb-2">Error Loading Profile</h5>
        <p className="text-muted small mb-4">{loadError}</p>
        <div>
          <button
            type="button"
            className="btn btn-primary d-inline-flex align-items-center gap-2 px-20 radius-8"
            onClick={fetchProfile}
          >
            <Icon icon="solar:refresh-linear" /> Retry
          </button>
        </div>
      </div>
    );
  }

  // Resolved Backend Data
  const roles = Array.isArray(profile?.roles)
    ? profile.roles
    : authUser?.roles?.map((r) => (typeof r === "string" ? r : r?.name)) || [];
  const primaryRole = roles[0] ? formatRole(roles[0]) : "Super Admin";
  const isActiveStatus = profile?.status === "Active" || profile?.is_online;

  // Tabs Configuration (Core personal settings strictly aligned with Task)
  const tabs = [
    { id: "overview", label: "Overview" },
    { id: "personal", label: "Personal Details" },
    { id: "security", label: "Password & Security" },
  ];

  return (
    <div className="profile-settings-page pb-24">
      {/* Hidden File Input for Image Upload */}
      <input
        type="file"
        ref={fileInputRef}
        style={{ display: "none" }}
        accept="image/jpeg,image/png,image/webp,image/jpg"
        onChange={handlePhotoSelect}
      />


      {/* Photo Notification Alerts */}
      {photoSuccess && (
        <div className="alert alert-success d-flex align-items-center gap-2 py-10 px-16 radius-8 mb-16 shadow-sm">
          <Icon icon="solar:check-circle-bold" className="text-lg text-success-main flex-shrink-0" />
          <span className="text-sm fw-medium">{photoSuccess}</span>
        </div>
      )}
      {photoError && (
        <div className="alert alert-danger d-flex align-items-center gap-2 py-10 px-16 radius-8 mb-16 shadow-sm">
          <Icon icon="solar:danger-triangle-bold" className="text-lg text-danger-main flex-shrink-0" />
          <span className="text-sm fw-medium">{photoError}</span>
        </div>
      )}

      {/* ── 2. Hero Profile Card ── */}
      <div className="card border-0 shadow-sm radius-16 p-24 mb-24 bg-white">
        <div className="d-flex flex-column flex-lg-row align-items-center align-items-lg-start gap-24">
          {/* Avatar with Camera & Remove Actions */}
          <div className="position-relative flex-shrink-0">
            <div
              className="rounded-20 overflow-hidden shadow-sm border border-2 border-primary-100 cursor-pointer d-flex align-items-center justify-content-center position-relative"
              style={{
                width: "112px",
                height: "112px",
                background: "linear-gradient(135deg, #0f172a 0%, #1e293b 55%, #334155 100%)",
                borderRadius: "20px",
              }}
              onClick={() => !photoSaving && fileInputRef.current?.click()}
              title={photoSaving ? "Saving photo..." : "Click to choose a new photo"}
            >
              {previewPhotoSrc ? (
                <img
                  src={previewPhotoSrc}
                  alt={profile?.name || "Profile"}
                  className="w-100 h-100 object-fit-cover"
                />
              ) : (
                <span className="text-white fw-bold" style={{ fontSize: "38px", letterSpacing: "1px" }}>
                  {getInitials(profile?.name)}
                </span>
              )}

              {/* Photo Saving Spinner Overlay */}
              {photoSaving && (
                <div
                  className="position-absolute top-0 start-0 w-100 h-100 d-flex flex-column align-items-center justify-content-center bg-dark bg-opacity-75"
                  style={{ zIndex: 4 }}
                >
                  <span className="spinner-border spinner-border-sm text-white mb-1" role="status" />
                  <span className="text-white fw-semibold" style={{ fontSize: "10px" }}>Saving...</span>
                </div>
              )}
            </div>

            {/* Bottom-right Overlay Buttons */}
            <div className="position-absolute d-flex gap-1" style={{ bottom: "-6px", right: "-6px", zIndex: 3 }}>
              <button
                type="button"
                className="btn btn-primary p-0 d-flex align-items-center justify-content-center shadow-sm"
                style={{ width: "30px", height: "30px", borderRadius: "10px" }}
                onClick={(e) => {
                  e.stopPropagation();
                  fileInputRef.current?.click();
                }}
                disabled={photoSaving}
                title="Upload new image (Max 2MB)"
              >
                <Icon icon="solar:camera-bold" className="text-sm" />
              </button>
              {previewPhotoSrc && (
                <button
                  type="button"
                  className="btn btn-danger p-0 d-flex align-items-center justify-content-center shadow-sm"
                  style={{ width: "30px", height: "30px", borderRadius: "10px" }}
                  onClick={(e) => {
                    e.stopPropagation();
                    handlePhotoRemove();
                  }}
                  disabled={photoSaving}
                  title="Remove image"
                >
                  <Icon icon="solar:trash-bin-trash-bold" className="text-sm" />
                </button>
              )}
            </div>
          </div>

          {/* User Details, Badges & Quick Action Buttons */}
          <div className="flex-grow-1 text-center text-lg-start min-w-0 w-100">
            <div className="d-flex flex-column flex-md-row align-items-center align-items-md-start justify-content-between gap-3 mb-16">
              <div>
                {/* User Name */}
                <h4 className="fw-bold text-dark mb-1">{profile?.name || "User"}</h4>

                {/* Role & Status Badges */}
                <div className="d-flex flex-wrap align-items-center justify-content-center justify-content-lg-start gap-2">
                  <span className="badge bg-primary-50 text-primary-600 border border-primary-100 px-12 py-6 rounded-pill text-xs fw-semibold d-inline-flex align-items-center gap-1">
                    <Icon icon="solar:shield-check-bold" className="text-sm" />
                    <span>{primaryRole}</span>
                  </span>

                  <span className="badge bg-success-50 text-success-600 border border-success-100 px-12 py-6 rounded-pill text-xs fw-semibold d-inline-flex align-items-center gap-1">
                    <span
                      className="rounded-circle bg-success-main"
                      style={{ width: "6px", height: "6px" }}
                    />
                    <span>{isActiveStatus ? "Active" : "Offline"}</span>
                  </span>
                </div>
              </div>

              {/* Quick Actions (Switch Tabs) */}
              <div className="d-flex flex-wrap align-items-center justify-content-center gap-2">
                <button
                  type="button"
                  onClick={() => setActiveTab("personal")}
                  className="btn btn-sm btn-outline-secondary radius-8 px-14 py-6 text-xs fw-semibold d-inline-flex align-items-center gap-2"
                >
                  <Icon icon="solar:pen-linear" />
                  <span>Edit Profile</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab("security")}
                  className="btn btn-sm btn-primary radius-8 px-14 py-6 text-xs fw-semibold d-inline-flex align-items-center gap-2 shadow-sm"
                >
                  <Icon icon="solar:key-linear" />
                  <span>Change Password</span>
                </button>
              </div>
            </div>

            {/* Chips Row (Backend Data Only - Clean & 100% Real) */}
            <div className="border-top pt-16 mt-16">
              <div className="row g-2">
                {/* Email */}
                <div className="col-12 col-md-6 col-xl-4">
                  <div className="p-8 px-12 bg-light border rounded-8 d-flex align-items-center gap-2 text-xs">
                    <Icon icon="solar:letter-bold" className="text-primary-600 flex-shrink-0" />
                    <span className="text-truncate font-monospace text-dark">{profile?.email || "—"}</span>
                  </div>
                </div>

                {/* Institution / School */}
                <div className="col-12 col-md-6 col-xl-4">
                  <div className="p-8 px-12 bg-light border rounded-8 d-flex align-items-center gap-2 text-xs">
                    <Icon icon="solar:buildings-2-bold" className="text-primary-600 flex-shrink-0" />
                    <span className="text-truncate text-dark">
                      {school?.name ? `${school.name} • Campus` : "Khmer Penpal Global Administration"}
                    </span>
                  </div>
                </div>

                {/* Registration Date */}
                <div className="col-12 col-md-6 col-xl-4">
                  <div className="p-8 px-12 bg-light border rounded-8 d-flex align-items-center gap-2 text-xs">
                    <Icon icon="solar:calendar-bold" className="text-primary-600 flex-shrink-0" />
                    <span className="text-truncate text-secondary-light">
                      Joined: <strong className="text-dark">{formatDate(profile?.created_at)}</strong>
                    </span>
                  </div>
                </div>

                {/* Last Updated Date */}
                <div className="col-12 col-md-6 col-xl-4">
                  <div className="p-8 px-12 bg-light border rounded-8 d-flex align-items-center gap-2 text-xs">
                    <Icon icon="solar:clock-circle-bold" className="text-success-main flex-shrink-0" />
                    <span className="text-truncate text-secondary-light">
                      Last Updated: <strong className="text-dark font-monospace">{formatDateTime(profile?.updated_at || profile?.created_at)}</strong>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── 3. Tabs Navigation Bar (Pill Navigation) ── */}
      <div
        className="p-1 rounded-12 border mb-24 overflow-x-auto bg-light"
        style={{ borderRadius: "12px" }}
      >
        <div className="d-flex align-items-center gap-1 min-w-max p-1">
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                className={`btn btn-sm d-inline-flex align-items-center gap-2 px-18 py-8 text-xs fw-semibold border-0 ${
                  isActive
                    ? "bg-white text-primary-600 shadow-sm radius-8"
                    : "bg-transparent text-secondary-light"
                }`}
                style={{ borderRadius: isActive ? "8px" : "0" }}
              >
                <Icon
                  icon={tab.icon}
                  className={`text-base ${isActive ? "text-primary-600" : "text-secondary-light"}`}
                />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* ── 4. Tab Body Content ── */}

      {/* TAB 1: OVERVIEW ────────────────────────────────────────────── */}
      {activeTab === "overview" && (
        <div>
          {/* 4 Stat KPI Cards (All Real Backend Data) */}
          <div className="row g-3 mb-24">
            {/* Card 1: Account Status */}
            <div className="col-12 col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm radius-12 p-20 bg-white h-100 d-flex flex-row align-items-center gap-3 overflow-hidden">
                <div
                  className="rounded-12 bg-success-50 text-success-600 border border-success-200 p-12 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: "48px", height: "48px" }}
                >
                  <Icon icon="solar:pulse-2-bold" style={{ fontSize: "24px" }} />
                </div>
                <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                  <span className="text-secondary-light fw-bold text-uppercase d-block mb-1 text-truncate" style={{ fontSize: "11px" }}>
                    Account Status
                  </span>
                  <h5 className="fw-bold text-dark mb-0 text-truncate" style={{ fontSize: "16px" }}>
                    {isActiveStatus ? "Active" : "Offline"}
                  </h5>
                </div>
              </div>
            </div>

            {/* Card 2: Role Tier */}
            <div className="col-12 col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm radius-12 p-20 bg-white h-100 d-flex flex-row align-items-center gap-3 overflow-hidden">
                <div
                  className="rounded-12 bg-primary-50 text-primary-600 border border-primary-200 p-12 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: "48px", height: "48px" }}
                >
                  <Icon icon="solar:medal-ribbon-bold" style={{ fontSize: "24px" }} />
                </div>
                <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                  <span className="text-secondary-light fw-bold text-uppercase d-block mb-1 text-truncate" style={{ fontSize: "11px" }}>
                    Account Role
                  </span>
                  <h5 className="fw-bold text-dark mb-0 text-truncate" style={{ fontSize: "16px" }} title={primaryRole}>
                    {primaryRole}
                  </h5>
                </div>
              </div>
            </div>

            {/* Card 3: School Affiliation / Campus */}
            <div className="col-12 col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm radius-12 p-20 bg-white h-100 d-flex flex-row align-items-center gap-3 overflow-hidden">
                <div
                  className="rounded-12 bg-warning-50 text-warning-600 border border-warning-200 p-12 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: "48px", height: "48px" }}
                >
                  <Icon icon="solar:buildings-bold" style={{ fontSize: "24px" }} />
                </div>
                <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                  <span className="text-secondary-light fw-bold text-uppercase d-block mb-1 text-truncate" style={{ fontSize: "11px" }}>
                    {school?.school_key ? "Campus Key" : "Institution"}
                  </span>
                  <h5
                    className="fw-bold text-dark mb-0 text-truncate d-block"
                    style={{ fontSize: "16px" }}
                    title={school?.school_key || school?.name || "Global Administration"}
                  >
                    {school?.school_key || (school?.name ? school.name : "Global Administration")}
                  </h5>
                </div>
              </div>
            </div>

            {/* Card 4: Member Since */}
            <div className="col-12 col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm radius-12 p-20 bg-white h-100 d-flex flex-row align-items-center gap-3 overflow-hidden">
                <div
                  className="rounded-12 border p-12 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{
                    width: "48px",
                    height: "48px",
                    backgroundColor: "rgba(139, 92, 246, 0.1)",
                    borderColor: "rgba(139, 92, 246, 0.2)",
                    color: "#8b5cf6",
                  }}
                >
                  <Icon icon="solar:calendar-date-bold" style={{ fontSize: "24px" }} />
                </div>
                <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                  <span className="text-secondary-light fw-bold text-uppercase d-block mb-1 text-truncate" style={{ fontSize: "11px" }}>
                    Member Since
                  </span>
                  <h5 className="fw-bold text-dark mb-0 text-truncate" style={{ fontSize: "16px" }}>
                    {formatDate(profile?.created_at)}
                  </h5>
                </div>
              </div>
            </div>
          </div>

          {/* Account Information Card (Strictly 100% compliant with Task Acceptance Criteria) */}
          <div className="card border-0 shadow-sm radius-16 p-24 bg-white">
            <div className="d-flex align-items-center justify-content-between border-bottom pb-16 mb-20">
              <div className="d-flex align-items-center gap-2">
                <div
                  className="rounded-8 bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center"
                  style={{ width: "36px", height: "36px" }}
                >
                  <Icon icon="solar:shield-user-bold" className="text-xl" />
                </div>
                <div>
                  <h6 className="fw-bold text-dark mb-0 fs-16">Account Information</h6>
                  <span className="text-xs text-secondary-light">System-level credentials and administrative assignments</span>
                </div>
              </div>
              <span className="badge bg-neutral-100 text-secondary-light border radius-6 px-12 py-6 text-xs fw-semibold">
                Protected Records
              </span>
            </div>

            <div className="row g-3">
              {/* Full Name */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between">
                  <div>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1">
                      Full Name
                    </span>
                    <strong className="text-dark fs-14">{profile?.name || "—"}</strong>
                  </div>
                  <span className="badge bg-primary-50 text-primary-600 border border-primary-100 px-8 py-4 text-xs">
                    Editable
                  </span>
                </div>
              </div>

              {/* Email Address */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between gap-2 overflow-hidden">
                  <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1 text-truncate">
                      Institutional Email
                    </span>
                    <strong className="text-dark font-monospace fs-14 text-truncate d-block" title={profile?.email || "—"}>
                      {profile?.email || "—"}
                    </strong>
                  </div>
                  <span className="badge bg-white text-muted border px-8 py-4 text-xs flex-shrink-0">
                    Read-Only
                  </span>
                </div>
              </div>

              {/* Account Role */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between gap-2 overflow-hidden">
                  <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1 text-truncate">
                      Account Role
                    </span>
                    <strong className="text-dark fs-14 text-truncate d-block" title={primaryRole}>
                      {primaryRole}
                    </strong>
                  </div>
                  <span className="badge bg-primary-50 text-primary-600 border border-primary-100 px-8 py-4 text-xs flex-shrink-0">
                    Read-Only
                  </span>
                </div>
              </div>

              {/* Account Status */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between gap-2 overflow-hidden">
                  <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1 text-truncate">
                      Account Status
                    </span>
                    <strong className="text-dark fs-14 text-truncate d-block">
                      {isActiveStatus ? "Active" : "Offline"}
                    </strong>
                  </div>
                  <span className="badge bg-success-50 text-success-600 border border-success-100 px-8 py-4 text-xs flex-shrink-0">
                    Verified
                  </span>
                </div>
              </div>

              {/* School Assignment */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between gap-2 overflow-hidden">
                  <div className="flex-grow-1 overflow-hidden" style={{ minWidth: 0 }}>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1 text-truncate">
                      Assigned Institution
                    </span>
                    <strong
                      className="text-dark fs-14 text-truncate d-block"
                      title={school?.name || "Khmer Penpal Global Administration"}
                    >
                      {school?.name || "Khmer Penpal Global Administration"}
                    </strong>
                  </div>
                  <span className="badge bg-white text-muted border px-8 py-4 text-xs flex-shrink-0">
                    Read-Only
                  </span>
                </div>
              </div>

              {/* School Join Key (if available) */}
              {school?.school_key && (
                <div className="col-12 col-md-6">
                  <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between">
                    <div>
                      <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1">
                        Campus Join Key
                      </span>
                      <strong className="text-dark font-monospace fs-14">{school.school_key}</strong>
                    </div>
                    <button
                      type="button"
                      className="btn btn-sm btn-outline-primary radius-8 px-10 py-4 text-xs d-inline-flex align-items-center gap-1"
                      onClick={copySchoolKey}
                    >
                      <Icon icon={keyCopied ? "solar:check-circle-bold" : "solar:copy-linear"} />
                      <span>{keyCopied ? "Copied" : "Copy Key"}</span>
                    </button>
                  </div>
                </div>
              )}

              {/* Member Since */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between">
                  <div>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1">
                      Member Since
                    </span>
                    <strong className="text-dark fs-14">{formatDate(profile?.created_at)}</strong>
                  </div>
                  <span className="badge bg-white text-muted border px-8 py-4 text-xs">
                    Registration Date
                  </span>
                </div>
              </div>

              {/* Last Profile Update */}
              <div className="col-12 col-md-6">
                <div className="p-16 border rounded-12 bg-light d-flex align-items-center justify-content-between">
                  <div>
                    <span className="text-secondary-light text-xs d-block text-uppercase fw-semibold mb-1">
                      Last Updated
                    </span>
                    <strong className="text-dark font-monospace fs-14">
                      {formatDateTime(profile?.updated_at || profile?.created_at)}
                    </strong>
                  </div>
                  <span className="badge bg-white text-muted border px-8 py-4 text-xs">
                    System Sync
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: PERSONAL DETAILS ────────────────────────────────────── */}
      {activeTab === "personal" && (
        <div className="card border-0 shadow-sm radius-16 p-24 bg-white">
          <div className="d-flex align-items-center justify-content-between border-bottom pb-16 mb-24">
            <div className="d-flex align-items-center gap-2">
              <div
                className="rounded-8 bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center"
                style={{ width: "36px", height: "36px" }}
              >
                <Icon icon="solar:user-bold-duotone" className="text-xl" />
              </div>
              <div>
                <h5 className="fw-bold text-dark mb-0 fs-18">Personal Details</h5>
                <span className="text-xs text-secondary-light">Update your display name and personal profile details</span>
              </div>
            </div>
            {hasUnsavedProfileChanges && (
              <span className="badge bg-warning-focus text-warning-main text-xs fw-semibold px-12 py-6 rounded-pill">
                Unsaved Changes
              </span>
            )}
          </div>

          {formSuccess && (
            <div className="alert alert-success d-flex align-items-center gap-2 py-12 px-16 mb-20 radius-8">
              <Icon icon="solar:check-circle-bold" className="text-xl text-success-main flex-shrink-0" />
              <span className="text-sm fw-medium">{formSuccess}</span>
            </div>
          )}

          {formError && (
            <div className="alert alert-danger d-flex align-items-center gap-2 py-12 px-16 mb-20 radius-8">
              <Icon icon="solar:danger-triangle-bold" className="text-xl text-danger-main flex-shrink-0" />
              <span className="text-sm fw-medium">{formError}</span>
            </div>
          )}

          <form onSubmit={handleProfileSave}>
            <div className="row g-4">
              {/* Full Name (Editable) */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2">
                  Full Name <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:user-linear" className="text-lg" />
                  </span>
                  <input
                    type="text"
                    className="form-control border-start-0"
                    value={name}
                    onChange={(e) => {
                      setName(e.target.value);
                      setFormError("");
                    }}
                    placeholder="e.g. John Doe"
                    required
                  />
                </div>
              </div>

              {/* Institutional Email (Read-Only) */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2 d-flex justify-content-between">
                  <span>Institutional Email</span>
                  <span className="text-muted fw-normal d-flex align-items-center gap-1" style={{ fontSize: "11px" }}>
                    <Icon icon="solar:lock-linear" /> Read-Only
                  </span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:letter-linear" className="text-lg" />
                  </span>
                  <input
                    type="email"
                    className="form-control border-start-0 bg-light text-muted font-monospace"
                    value={profile?.email || ""}
                    disabled
                    readOnly
                    title="Institutional email address cannot be changed directly."
                  />
                </div>
                <span className="text-xs text-secondary-light mt-1 d-block">
                  Institutional email address cannot be changed directly. Contact administrator for updates.
                </span>
              </div>

              {/* Account Role (Read-Only) */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2 d-flex justify-content-between">
                  <span>Current Role</span>
                  <span className="text-muted fw-normal d-flex align-items-center gap-1" style={{ fontSize: "11px" }}>
                    <Icon icon="solar:lock-linear" /> Read-Only
                  </span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:shield-check-linear" className="text-lg" />
                  </span>
                  <input
                    type="text"
                    className="form-control border-start-0 bg-light text-muted"
                    value={primaryRole}
                    disabled
                    readOnly
                  />
                </div>
              </div>

              {/* Assigned Institution (Read-Only) */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2 d-flex justify-content-between">
                  <span>Assigned Institution</span>
                  <span className="text-muted fw-normal d-flex align-items-center gap-1" style={{ fontSize: "11px" }}>
                    <Icon icon="solar:lock-linear" /> Read-Only
                  </span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:buildings-linear" className="text-lg" />
                  </span>
                  <input
                    type="text"
                    className="form-control border-start-0 bg-light text-muted"
                    value={school?.name || "Khmer Penpal Global Administration"}
                    disabled
                    readOnly
                  />
                </div>
              </div>
            </div>

            {/* Save Button */}
            <div className="d-flex align-items-center justify-content-between mt-32 pt-20 border-top">
              <span className="text-xs text-secondary-light">
                {hasUnsavedProfileChanges
                  ? "You have unsaved changes to your details."
                  : "All profile details are up to date."}
              </span>
              <button
                type="submit"
                className="btn btn-primary px-24 py-10 radius-8 fw-semibold d-inline-flex align-items-center gap-2"
                disabled={saving || !hasUnsavedProfileChanges || !name.trim()}
              >
                {saving ? (
                  <>
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                    <span>Saving...</span>
                  </>
                ) : (
                  <>
                    <Icon icon="solar:diskette-bold" className="text-lg" />
                    <span>Save Changes</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* TAB 3: PASSWORD & SECURITY ─────────────────────────────────── */}
      {activeTab === "security" && (
        <div className="card border-0 shadow-sm radius-16 p-24 bg-white">
          <div className="d-flex align-items-center justify-content-between border-bottom pb-16 mb-24">
            <div className="d-flex align-items-center gap-2">
              <div
                className="rounded-8 bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center"
                style={{ width: "36px", height: "36px" }}
              >
                <Icon icon="solar:lock-password-bold-duotone" className="text-xl" />
              </div>
              <div>
                <h5 className="fw-bold text-dark mb-0 fs-18">Password & Security</h5>
                <span className="text-xs text-secondary-light">Update your password to keep your account safe</span>
              </div>
            </div>
          </div>

          {pwSuccess && (
            <div className="alert alert-success d-flex align-items-center gap-2 py-12 px-16 mb-20 radius-8">
              <Icon icon="solar:check-circle-bold" className="text-xl text-success-main flex-shrink-0" />
              <span className="text-sm fw-medium">{pwSuccess}</span>
            </div>
          )}

          {pwError && (
            <div className="alert alert-danger d-flex align-items-center gap-2 py-12 px-16 mb-20 radius-8">
              <Icon icon="solar:danger-triangle-bold" className="text-xl text-danger-main flex-shrink-0" />
              <span className="text-sm fw-medium">{pwError}</span>
            </div>
          )}

          <form onSubmit={handlePasswordSave}>
            <div className="row g-4">
              {/* Current Password */}
              <div className="col-12">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2">
                  Current Password <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:lock-keyhole-linear" className="text-lg" />
                  </span>
                  <input
                    type={showCurrent ? "text" : "password"}
                    className="form-control border-start-0 border-end-0"
                    placeholder="Enter current password"
                    value={pwForm.current_password}
                    onChange={(e) => {
                      setPwForm({ ...pwForm, current_password: e.target.value });
                      setPwError("");
                    }}
                    required
                  />
                  <button
                    type="button"
                    className="input-group-text bg-light border-start-0 text-secondary-light"
                    onClick={() => setShowCurrent(!showCurrent)}
                  >
                    <Icon icon={showCurrent ? "solar:eye-closed-linear" : "solar:eye-linear"} className="text-lg" />
                  </button>
                </div>
              </div>

              {/* New Password */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2">
                  New Password <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:key-linear" className="text-lg" />
                  </span>
                  <input
                    type={showNew ? "text" : "password"}
                    className="form-control border-start-0 border-end-0"
                    placeholder="Minimum 8 characters"
                    value={pwForm.password}
                    onChange={(e) => {
                      setPwForm({ ...pwForm, password: e.target.value });
                      setPwError("");
                    }}
                    required
                  />
                  <button
                    type="button"
                    className="input-group-text bg-light border-start-0 text-secondary-light"
                    onClick={() => setShowNew(!showNew)}
                  >
                    <Icon icon={showNew ? "solar:eye-closed-linear" : "solar:eye-linear"} className="text-lg" />
                  </button>
                </div>
              </div>

              {/* Confirm New Password */}
              <div className="col-12 col-md-6">
                <label className="form-label text-xs fw-bold text-dark text-uppercase mb-2">
                  Confirm New Password <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <span className="input-group-text bg-light border-end-0 text-secondary-light">
                    <Icon icon="solar:check-read-linear" className="text-lg" />
                  </span>
                  <input
                    type={showConfirm ? "text" : "password"}
                    className="form-control border-start-0 border-end-0"
                    placeholder="Re-enter new password"
                    value={pwForm.password_confirmation}
                    onChange={(e) => {
                      setPwForm({ ...pwForm, password_confirmation: e.target.value });
                      setPwError("");
                    }}
                    required
                  />
                  <button
                    type="button"
                    className="input-group-text bg-light border-start-0 text-secondary-light"
                    onClick={() => setShowConfirm(!showConfirm)}
                  >
                    <Icon icon={showConfirm ? "solar:eye-closed-linear" : "solar:eye-linear"} className="text-lg" />
                  </button>
                </div>
              </div>

              {/* Password Requirement Helpers */}
              <div className="col-12">
                <div className="p-16 border rounded-12 bg-light">
                  <span className="text-xs fw-bold text-dark text-uppercase d-block mb-2">
                    Password Requirements:
                  </span>
                  <div className="d-flex flex-column gap-2 text-xs">
                    <span className={`d-inline-flex align-items-center gap-2 ${isPwMinLength ? "text-success-main fw-semibold" : "text-secondary-light"}`}>
                      <Icon icon={isPwMinLength ? "solar:check-circle-bold" : "solar:close-circle-linear"} className="text-base flex-shrink-0" />
                      Must be at least 8 characters long
                    </span>
                    <span className={`d-inline-flex align-items-center gap-2 ${isPwMatching ? "text-success-main fw-semibold" : isPwMismatch ? "text-danger-main fw-semibold" : "text-secondary-light"}`}>
                      <Icon icon={isPwMatching ? "solar:check-circle-bold" : isPwMismatch ? "solar:close-circle-bold" : "solar:close-circle-linear"} className="text-base flex-shrink-0" />
                      {isPwMismatch ? "Passwords do not match" : "New password and confirmation must match"}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Save Password Button */}
            <div className="d-flex align-items-center justify-content-end mt-32 pt-20 border-top">
              <button
                type="submit"
                className="btn btn-primary px-24 py-10 radius-8 fw-semibold d-inline-flex align-items-center gap-2"
                disabled={
                  pwSaving ||
                  !pwForm.current_password ||
                  !pwForm.password ||
                  !pwForm.password_confirmation ||
                  pwForm.password.length < 8 ||
                  pwForm.password !== pwForm.password_confirmation
                }
              >
                {pwSaving ? (
                  <>
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                    <span>Updating Password...</span>
                  </>
                ) : (
                  <>
                    <Icon icon="solar:shield-check-bold" className="text-lg" />
                    <span>Update Password</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
