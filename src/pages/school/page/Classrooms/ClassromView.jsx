import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";

import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ClassroomView = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { hasPermission } = useAuth();

  const [loading, setLoading] = useState(true);
  const [classroom, setClassroom] = useState(null);
  const [enrollments, setEnrollments] = useState([]);

  const [error, setError] = useState("");
  const [flash, setFlash] = useState("");

  const canView = hasPermission("classrooms.view");
  const canEdit = hasPermission("classrooms.update");
  const canDelete = hasPermission("classrooms.delete");


  const avatarUrl = (path) => {
    if (!path) return null;
    if (String(path).startsWith("http")) return path;
    return `${API_BASE_URL}/${String(path).replace(/^\/+/, "")}`;
  };

  const prettyDate = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
  };

  const formatRange = (start, end) => {
    const s = start ? prettyDate(start) : "";
    const e = end ? prettyDate(end) : "";
    return [s, e].filter(Boolean).join(" - ") || "—";
  };

  const joinCode = useMemo(() => {
    const code = classroom?.join_code || classroom?.code || "";
    return code ? String(code) : "";
  }, [classroom]);

  const copyText = async (text) => {
    const c = String(text || "").trim();
    if (!c) return false;

    try {
      await navigator.clipboard.writeText(c);
      return true;
    } catch {
      const ta = document.createElement("textarea");
      ta.value = c;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
      return true;
    }
  };

  const fetchClassroom = async () => {
    setLoading(true);
    setError("");
    setFlash("");
    try {
      const res = await API.get(`/school/classrooms/${id}`);
      setClassroom(res?.data?.classroom ?? null);
      setEnrollments(Array.isArray(res?.data?.enrollments) ? res.data.enrollments : []);
    } catch (err) {
      console.error("Fetch classroom failed:", err);
      setError(err?.response?.data?.message || "Failed to load classroom.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (canView) fetchClassroom();
  }, [id, canView]);

  const archiveClassroom = async () => {
    if (!window.confirm("Archive this classroom? Students won't be able to join.")) return;
    setError("");
    setFlash("");

    try {
      await API.delete(`/school/classrooms/${id}`);
      setFlash("Classroom archived successfully");
      navigate("/school/classrooms", { state: { flash: "Classroom archived successfully" }, replace: true });
    } catch (err) {
      console.error(err);
      setError(err?.response?.data?.message || "Archive failed");
    }
  };

  const removeStudent = async (studentId) => {
    if (!window.confirm("Are you sure you want to remove this student from the classroom?")) return;
    setError("");
    setFlash("");

    try {
      await API.post(`/school/classrooms/${id}/students/${studentId}/remove`);
      setFlash("Student removed successfully");
      setEnrollments((prev) => prev.filter((en) => en.student_id !== studentId && en.student?.id !== studentId));
    } catch (err) {
      console.error(err);
      setError(err?.response?.data?.message || "Failed to remove student");
    }
  };

  if (!canView) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">You don’t have permission to view classroom details.</div>
      </SchoolLayout>
    );
  }

  return (
    <SchoolLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Classroom Details</h5>
            <small className="text-muted">ID: {id}</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <div className="d-flex gap-2 flex-wrap">
              <Link
                to="/school/classrooms"
                className="btn btn-outline-secondary d-inline-flex align-items-center gap-2"
              >
                <Icon icon="mdi:arrow-left" />
                <span className="btn-label">Back</span>
              </Link>

              {!!(canEdit && classroom?.is_active) && (
                <Link
                  to={`/school/classrooms/${id}/edit`}
                  className="btn btn-success d-inline-flex align-items-center gap-2"
                >
                  <Icon icon="lucide:edit" />
                  <span className="btn-label">Edit</span>
                </Link>
              )}


              {!!(canDelete && classroom?.is_active) && (
                <button
                  type="button"
                  onClick={archiveClassroom}
                  className="btn btn-danger d-inline-flex align-items-center gap-2"
                >
                  <Icon icon="mdi:archive" />
                  <span className="btn-label">Archive</span>
                </button>
              )}
            </div>
          </div>
        </div>

        <div className="card-body">
          {flash && <div className="alert alert-success">{flash}</div>}
          {error && <div className="alert alert-danger">{error}</div>}

          {loading ? (
            <div className="text-center py-40">
              <div className="spinner-border" role="status" />
              <div className="mt-12 text-muted">Loading classroom...</div>
            </div>
          ) : !classroom ? (
            <div className="text-center py-40 text-muted">Classroom not found.</div>
          ) : (
            <div className="row g-3">
              {/* LEFT: quick summary */}
              <div className="col-12 col-md-4 col-lg-3">
                <div className="card border">
                  <div className="card-body">
                    <div className="d-flex align-items-start justify-content-between gap-2">
                      <div>
                        <div className="text-muted small">Classroom</div>
                        <h6 className="mb-0">{classroom.name || "—"}</h6>
                      </div>
                      <span
                        className={`badge ${classroom.is_active ? "bg-success" : "bg-warning text-dark"
                          }`}
                      >
                        {classroom.is_active ? "Active" : "Archived"}
                      </span>
                    </div>

                    <div className="mt-12">
                      <div className="text-muted small">Join Code</div>
                      {joinCode ? (
                        <button
                          type="button"
                          className="badge bg-secondary border-0"
                          title="Click to copy"
                          onClick={async () => {
                            const ok = await copyText(joinCode);
                            if (ok) {
                              setFlash("Join code copied!");
                              window.setTimeout(() => setFlash(""), 1000);
                            }
                          }}
                          style={{
                            cursor: "pointer",
                            padding: "8px 10px",
                            transition: "all .15s ease",
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.filter = "brightness(0.92)";
                            e.currentTarget.style.boxShadow = "0 6px 14px rgba(0,0,0,0.10)";
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.filter = "none";
                            e.currentTarget.style.boxShadow = "none";
                          }}
                        >
                          <span className="d-inline-flex align-items-center gap-6">
                            <Icon icon="mdi:content-copy" />
                            {joinCode}
                          </span>
                        </button>
                      ) : (
                        <div className="text-muted">—</div>
                      )}
                    </div>

                    <div className="mt-12">
                      <div className="text-muted small">Date Range</div>
                      <div className="fw-medium">{formatRange(classroom.start_date, classroom.end_date)}</div>
                    </div>

                    <div className="mt-12">
                      <div className="text-muted small">Students Enrolled</div>
                      <div className="fw-medium">{enrollments.length}</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* RIGHT: details + enrolled students */}
              <div className="col-12 col-md-8 col-lg-9">
                <div className="card border mb-3">
                  <div className="card-header">
                    <h6 className="mb-0">Classroom Information</h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <InfoItem label="Name" value={classroom.name} />
                      <InfoItem label="Join Code" value={joinCode || "—"} />
                      <InfoItem label="Start Date" value={prettyDate(classroom.start_date)} />
                      <InfoItem label="End Date" value={prettyDate(classroom.end_date)} />
                      <InfoItem label="Created At" value={prettyDate(classroom.created_at)} />
                      <InfoItem label="Updated At" value={prettyDate(classroom.updated_at)} />
                    </div>
                  </div>
                </div>

                <div className="card border">
                  <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h6 className="mb-0">Enrolled Students</h6>
                    <span className="text-muted small">{enrollments.length} students</span>
                  </div>

                  <div className="card-body">
                    {enrollments.length === 0 ? (
                      <div className="text-center text-muted py-20">No enrolled students.</div>
                    ) : (
                      <div className="table-responsive">
                        <table className="table bordered-table mb-0">
                          <thead>
                            <tr>
                              <th>#</th>
                              <th>Avatar</th>
                              <th>Name</th>
                              <th>Nickname</th>
                              <th>Action</th>
                            </tr>
                          </thead>
                          <tbody>
                            {enrollments.map((en, idx) => {
                              const s = en?.student || {};
                              const name =
                                [s?.first_name, s?.last_name].filter(Boolean).join(" ").trim() || "—";
                              const avatar = avatarUrl(s?.avatar);
                              return (
                                <tr key={en?.id ?? `${s?.id}-${idx}`}>
                                  <td>{idx + 1}</td>
                                  <td>
                                    {avatar ? (
                                      <img
                                        src={avatar}
                                        alt={name}
                                        style={{
                                          width: 40,
                                          height: 40,
                                          objectFit: "cover",
                                          borderRadius: "50%",
                                        }}
                                      />
                                    ) : (
                                      <div
                                        className="d-inline-flex align-items-center justify-content-center bg-light"
                                        style={{
                                          width: 40,
                                          height: 40,
                                          borderRadius: "50%",
                                        }}
                                        title="No image"
                                      >
                                        <Icon icon="mdi:account" />
                                      </div>
                                    )}
                                  </td>
                                  <td>{name}</td>
                                  <td>{s?.nickname || "—"}</td>
                                  <td>
                                    <Link
                                      to={`/school/students/${s?.id}`}
                                      className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                                      title="View Student"
                                    >
                                      <Icon icon="iconamoon:eye-light" />
                                    </Link>
                                    <Link
                                      to={`/school/classrooms/${id}/students/${s?.id}/progress`}
                                      className="w-32-px h-32-px me-8 bg-success-light text-success rounded-circle d-inline-flex align-items-center justify-content-center"
                                      title="View Progress"
                                    >
                                      <Icon icon="mdi:chart-line" />
                                    </Link>

                                    {!!(canEdit && classroom?.is_active) && (
                                      <button
                                        type="button"
                                        onClick={() => removeStudent(s?.id)}
                                        className="w-32-px h-32-px bg-danger-light text-danger rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                        title="Remove Student"
                                      >
                                        <Icon icon="mingcute:delete-2-line" />
                                      </button>
                                    )}
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </SchoolLayout>
  );
};


const InfoItem = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="col-12 col-md-6 col-lg-4">
      <div className="p-12 border radius-8 h-100">
        <div className="text-muted small">{label}</div>
        <div className="fw-medium" style={{ wordBreak: "break-word" }}>
          {v}
        </div>
      </div>
    </div>
  );
};

export default ClassroomView;
