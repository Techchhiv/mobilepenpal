import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import API_BASE_URL from "../../../helper/Base_urls";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminEmptyState from "../../../components/admin/common/AdminEmptyState";
import AdminErrorState from "../../../components/admin/common/AdminErrorState";
import ConfirmModal from "../../../components/admin/common/ConfirmModal";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

function prettyDate(d) {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleDateString();
}

function calcAgeFromDob(dob) {
  if (!dob) return null;
  const d = new Date(dob);
  if (Number.isNaN(d.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - d.getFullYear();
  const m = now.getMonth() - d.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < d.getDate())) age--;
  return age >= 0 ? age : null;
}

const formatEnrollmentYear = (v) => {
  if (!v) return "—";
  const s = String(v).trim();
  if (/^\d{4}$/.test(s)) return s;
  const d = new Date(s);
  if (!Number.isNaN(d.getTime())) {
    const y = d.getFullYear();
    if (y === 1970) return "—";
    return String(y);
  }
  return "—";
};

export default function AdminStudentView() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const fullName = (s) =>
    [s?.first_name, s?.last_name].filter(Boolean).join(" ").trim() || "—";

  const isOnline = (s) => {
    const flag = s?.is_online === true || String(s?.is_online) === "1";
    const last = s?.last_seen_at ? new Date(s.last_seen_at) : null;
    const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
    return flag || fresh;
  };

  const fetchStudent = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/students/${id}`);
      setStudent(res.data?.data?.student ?? res.data?.student ?? null);
    } catch (err) {
      console.error("Fetch student failed:", err);
      setError(err?.response?.data?.message || "Failed to load student.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStudent();
  }, [id]);

  const normalized = useMemo(() => {
    if (!student) return null;

    const active =
      student?.is_active === true ||
      String(student?.is_active ?? student?.status ?? "0") === "1";

    const computedAge =
      student?.age ?? calcAgeFromDob(student?.date_of_birth) ?? "—";

    const parentName =
      [student?.parent_first_name, student?.parent_last_name]
        .filter(Boolean)
        .join(" ")
        .trim() || "—";

    return {
      ...student,
      name: fullName(student),
      active,
      online: isOnline(student),
      computedAge,
      parentName,
    };
  }, [student]);

  const avatarUrl = useMemo(() => {
    if (!normalized?.avatar) return null;
    return String(normalized.avatar).startsWith("http")
      ? normalized.avatar
      : `${API_BASE_URL}/${String(normalized.avatar).replace(/^\/+/, "")}`;
  }, [normalized]);

  const handleDelete = async () => {
    setDeleting(true);
    setError("");
    setMessage("");
    try {
      await API.delete(`/admin/students/${id}`);
      setShowDeleteModal(false);
      navigate("/admin/students", { state: { success: "Student deleted successfully" } });
    } catch (err) {
      console.error("Delete failed:", err);
      setError(err?.response?.data?.message || "Delete failed");
    } finally {
      setDeleting(false);
    }
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title={normalized ? `Student Details — ${normalized.name}` : "Student Details"}
          subtitle={normalized ? `Profile, contact information, and activity details for ID: #${id}` : `Student ID: #${id}`}
          actionLabel="Back to Students"
          actionIcon="mdi:arrow-left"
          onAction={() => navigate("/admin/students")}
        />

        {message && (
          <div className="alert alert-success d-flex align-items-center gap-2 mb-24 radius-8">
            <Icon icon="mdi:check-circle" className="text-xl flex-shrink-0" />
            <div>{message}</div>
          </div>
        )}

        {error && (
          <AdminErrorState
            title="Failed to Load Student"
            message={error}
            onRetry={fetchStudent}
          />
        )}

        {loading ? (
          <div className="card border radius-12 shadow-none p-40 text-center">
            <div className="spinner-border text-primary mx-auto mb-16" role="status" />
            <div className="text-secondary-light">Loading student profile...</div>
          </div>
        ) : !normalized ? (
          <AdminEmptyState
            title="Student Not Found"
            message="The requested student profile could not be retrieved or has been removed."
            actionLabel="Return to Student Directory"
            onAction={() => navigate("/admin/students")}
          />
        ) : (
          <div className="row g-4">
            {/* Left Column */}
            <div className="col-12 col-md-4 col-lg-3">
              <div className="card border radius-12 shadow-none text-center p-20">
                <div className="card-body p-0">
                  {avatarUrl ? (
                    <img
                      src={avatarUrl}
                      alt={normalized.name}
                      className="mx-auto rounded-circle border border-neutral-200 object-fit-cover mb-16"
                      style={{ width: 120, height: 120 }}
                    />
                  ) : (
                    <div
                      className="d-inline-flex align-items-center justify-content-center bg-neutral-100 border border-neutral-200 rounded-circle mb-16"
                      style={{ width: 120, height: 120 }}
                    >
                      <Icon icon="mdi:account" width={48} className="text-secondary-light" />
                    </div>
                  )}

                  <h6 className="fw-bold text-dark mb-4">{normalized.name}</h6>

                  <div className="d-flex justify-content-center gap-2 mb-12 flex-wrap">
                    <span className={`badge ${normalized.active ? "bg-success-100 text-success-600" : "bg-neutral-200 text-secondary-light"}`}>
                      {normalized.active ? "Active" : "Inactive"}
                    </span>
                    <span
                      className={`badge ${normalized.online ? "bg-primary-100 text-primary-600" : "bg-neutral-200 text-secondary-light"}`}
                      title={normalized.last_seen_at ? `Last seen: ${normalized.last_seen_at}` : ""}
                    >
                      {normalized.online ? "Online" : "Offline"}
                    </span>
                  </div>

                  <div className="text-secondary-light text-sm mb-16">
                    Nickname: <span className="text-dark fw-semibold">{normalized.nickname || "—"}</span>
                  </div>

                  <div className="d-flex gap-2 justify-content-center flex-wrap">
                    <Link
                      to={`/admin/students/${id}/edit`}
                      className="btn btn-outline-primary btn-sm radius-8 px-16 py-8 d-inline-flex align-items-center justify-content-center gap-6"
                    >
                      <Icon icon="lucide:edit" className="font-18" />
                      <span>Edit</span>
                    </Link>
                    <button
                      type="button"
                      onClick={() => setShowDeleteModal(true)}
                      className="btn btn-outline-danger btn-sm radius-8 px-16 py-8 d-inline-flex align-items-center justify-content-center gap-6"
                    >
                      <Icon icon="mingcute:delete-2-line" className="font-18" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </div>

              <div className="card border radius-12 shadow-none mt-3">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold text-dark mb-0">School</h6>
                </div>
                <div className="card-body p-20">
                  <MiniRow label="School ID" value={normalized.school_id ?? "—"} />
                  <MiniRow label="School Key" value={normalized.school_key ?? "—"} />
                  <MiniRow
                    label="Affiliation"
                    value={
                      normalized.school_id ? (
                        <span className="badge bg-primary-100 text-primary-600">School</span>
                      ) : (
                        <span className="badge bg-warning-100 text-warning-600">Public</span>
                      )
                    }
                  />
                </div>
              </div>

              <div className="card border radius-12 shadow-none mt-3">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold text-dark mb-0">Stats</h6>
                </div>
                <div className="card-body p-20">
                  <MiniRow label="Coins" value={normalized.coins ?? "—"} />
                  <MiniRow label="Streak" value={normalized.streak ?? "—"} />
                </div>
              </div>
            </div>

            {/* Right Column */}
            <div className="col-12 col-md-8 col-lg-9">
              {/* Student Information */}
              <div className="card border radius-12 shadow-none mb-4">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold text-dark mb-0">Student Information</h6>
                </div>
                <div className="card-body p-24">
                  <div className="row g-3">
                    <InfoItem label="First Name" value={normalized.first_name} />
                    <InfoItem label="Last Name" value={normalized.last_name} />
                    <InfoItem label="Gender" value={normalized.gender} />
                    <InfoItem label="Date of Birth" value={prettyDate(normalized.date_of_birth)} />
                    <InfoItem label="Age" value={normalized.computedAge} />
                    <InfoItem label="Enrollment Year" value={formatEnrollmentYear(normalized.enrollment_year)} />
                    <InfoItem label="Address" value={normalized.address} colClass="col-12" />
                  </div>
                </div>
              </div>

              {/* Contact & Parent */}
              <div className="card border radius-12 shadow-none mb-4">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold text-dark mb-0">Contact & Parent</h6>
                </div>
                <div className="card-body p-24">
                  <div className="row g-3">
                    <InfoItem label="Phone" value={normalized.phone} />
                    <InfoItem label="Email" value={normalized.email} />
                    <InfoItem label="Parent Name" value={normalized.parentName} colClass="col-12" />
                  </div>
                </div>
              </div>

              {/* System */}
              <div className="card border radius-12 shadow-none">
                <div className="card-header border-bottom py-16 px-24 bg-base">
                  <h6 className="fw-bold text-dark mb-0">System</h6>
                </div>
                <div className="card-body p-24">
                  <div className="row g-3">
                    <InfoItem label="Created At" value={prettyDate(normalized.created_at)} />
                    <InfoItem label="Updated At" value={prettyDate(normalized.updated_at)} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        <ConfirmModal
          open={showDeleteModal}
          title="Delete Student Account"
          message={`Are you sure you want to permanently delete student profile "${normalized?.name}"? This action cannot be undone.`}
          confirmLabel="Delete Student"
          variant="danger"
          loading={deleting}
          onConfirm={handleDelete}
          onCancel={() => setShowDeleteModal(false)}
        />
      </div>
    </MasterLayout>
  );
}

const InfoItem = ({ label, value, colClass = "col-12 col-md-6 col-lg-4" }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className={colClass}>
      <div className="p-16 border border-neutral-200 radius-8 h-100 bg-base">
        <div className="text-secondary-light text-xs mb-4">{label}</div>
        <div className="fw-semibold text-dark" style={{ wordBreak: "break-word" }}>
          {v}
        </div>
      </div>
    </div>
  );
};

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between align-items-center gap-2 py-8 border-bottom border-neutral-200">
      <div className="text-secondary-light text-xs">{label}</div>
      <div className="fw-semibold text-dark text-sm">{v}</div>
    </div>
  );
};
