import React, { useEffect, useState, useRef } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import API_BASE_URL from "../../../../helper/Base_urls";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

const Trunc = ({ value, maxWidth = 200 }) => {
  const v = value ?? "—";
  return (
    <div
      className="text-truncate"
      style={{ maxWidth }}
      title={String(v)}
    >
      {v}
    </div>
  );
};

const StudentList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [students, setStudents] = useState([]);
  const [message, setMessage] = useState("");
  const dtRef = useRef(null);

  const [previewSrc, setPreviewSrc] = useState(null);
  const closePreview = () => setPreviewSrc(null);

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && closePreview();
    if (previewSrc) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [previewSrc]);

  const fullName = (s) =>
    [s?.first_name, s?.last_name].filter(Boolean).join(" ").trim() || "—";

  const isOnline = (s) => {
    const flag = s?.is_online === true || String(s?.is_online) === "1";
    const last = s?.last_seen_at ? new Date(s.last_seen_at) : null;
    const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
    return flag || fresh;
  };

  const normalizeStudent = (s) => ({
    ...s,
    active:
      s?.is_active === true ||
      String(s?.is_active ?? s?.status ?? "0") === "1",
    online: isOnline(s),
    name: fullName(s),
  });

  const avatarUrl = (avatar) => {
    if (!avatar) return null;
    return String(avatar).startsWith("http")
      ? avatar
      : `${API_BASE_URL}/${String(avatar).replace(/^\/+/, "")}`;
  };

  const fetchStudents = async () => {
    try {
      const res = await API.get("/school/students");
      const rows = Array.isArray(res.data?.student?.data)
        ? res.data.student.data
        : [];
      setStudents(rows.map(normalizeStudent));
    } catch (err) {
      console.error("Fetch students failed:", err);
    }
  };

  useEffect(() => {
    fetchStudents();
  }, []);

  useEffect(() => {
    const id = setInterval(fetchStudents, 20000);
    return () => clearInterval(id);
  }, []);

  const canAnyAction = hasAnyPermission([
    "children.view",
    "children.update",
    "children.delete",
  ]);


  useEffect(() => {
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (students.length > 0) {
      dtRef.current = $("#studentTable").DataTable({
        destroy: true,
        pageLength: 10,
        scrollX: true,
        scrollCollapse: true,
        autoWidth: false,

        columnDefs: [
          { targets: 0, width: "60px" },
          { targets: 1, width: "90px" },
          { targets: 2, width: "220px" },
          { targets: 3, width: "160px" },
          { targets: 4, width: "90px" },
          { targets: 5, width: "110px" },
          { targets: 6, width: "160px" },
          { targets: 7, width: "220px" },
          ...(canAnyAction ? [{ targets: 8, width: "150px" }] : []),
        ],
      });
    }

    return () => {
      if (dtRef.current) {
        dtRef.current.destroy();
        dtRef.current = null;
      }
    };
  }, [students, canAnyAction]);

  const deleteStudent = async (id) => {
    if (!window.confirm("Delete this student?")) return;
    try {
      await API.delete(`/school/students/${id}`);
      setStudents((prev) => prev.filter((s) => s.id !== id));
      setMessage("Student deleted successfully");
    } catch (err) {
      setMessage(err?.response?.data?.message || "Delete failed");
      console.error(err);
    }
  };

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Students</h5>

          {hasPermission("children.create") && (
            <Link to="/school/students/create">
              <button
                type="button"
                className="btn btn-primary-600 radius-3 px-20 py-11"
              >
                Add Student
              </button>
            </Link>
          )}
        </div>

        {message && <div className="alert alert-success">{message}</div>}

        <div className="card-body">
          <table className="table bordered-table mb-0" id="studentTable">
            <thead>
              <tr>
                <th>#</th>
                <th>Avatar</th>
                <th>Name</th>
                <th>Nickname</th>
                <th>Age</th>
                <th>Gender</th>
                <th>Phone</th>
                <th>Parent</th>
                {canAnyAction && <th>Action</th>}
              </tr>
            </thead>

            <tbody>
              {students.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center">
                    No students found
                  </td>
                </tr>
              ) : (
                students.map((s, idx) => {
                  const url = avatarUrl(s.avatar);
                  const parentName =
                    [s.parent_first_name, s.parent_last_name]
                      .filter(Boolean)
                      .join(" ")
                      .trim() || "—";

                  return (
                    <tr key={s.id}>
                      <td>{idx + 1}</td>

                      <td>
                        {(() => {
                          const url = avatarUrl(s.avatar);

                          if (url) {
                            return (
                              <button
                                type="button"
                                className="p-0 border-0 bg-transparent"
                                onClick={() => setPreviewSrc(url)}
                                title="Click to view"
                                style={{ cursor: "zoom-in" }}
                              >
                                <img
                                  src={url}
                                  alt={s.name}
                                  style={{
                                    width: 40,
                                    height: 40,
                                    objectFit: "cover",
                                    borderRadius: "50%",
                                    display: "block",
                                  }}
                                />
                              </button>
                            );
                          }

                          return (
                            <div
                              className="d-inline-flex align-items-center justify-content-center bg-light text-muted"
                              style={{
                                width: 40,
                                height: 40,
                                borderRadius: "50%",
                              }}
                              title="No avatar"
                            >
                              <Icon icon="mdi:account" width={22} />
                            </div>
                          );
                        })()}
                      </td>

                      <td><Trunc value={s.name} maxWidth={220} /></td>
                      <td><Trunc value={s.nickname || "—"} maxWidth={160} /></td>
                      <td>{s.age ?? "—"}</td>
                      <td>{s.gender || "—"}</td>
                      <td><Trunc value={s.phone || "—"} maxWidth={160} /></td>
                      <td><Trunc value={parentName} maxWidth={220} /></td>

                      {canAnyAction && (
                        <td>
                          {hasPermission("children.view") && (
                            <Link
                              to={`/school/students/${s.id}`}
                              className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="View"
                            >
                              <Icon icon="iconamoon:eye-light" />
                            </Link>
                          )}

                          {hasPermission("children.update") && (
                            <Link
                              to={`/school/students/${s.id}/edit`}
                              className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="Edit"
                            >
                              <Icon icon="lucide:edit" />
                            </Link>
                          )}

                          {hasPermission("children.delete") && (
                            <button
                              type="button"
                              onClick={() => deleteStudent(s.id)}
                              className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                              title="Delete"
                            >
                              <Icon icon="mingcute:delete-2-line" />
                            </button>
                          )}
                        </td>
                      )}
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ✅ Image only preview, click outside closes */}
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
            alt="Avatar Preview"
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
};

export default StudentList;
