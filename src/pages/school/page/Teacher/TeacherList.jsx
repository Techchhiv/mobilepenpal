import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import API_BASE_URL from "../../../../helper/Base_urls";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const ONLINE_GRACE_MS = 2 * 60 * 1000;

const Trunc = ({ value, maxWidth = 220 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const TeacherList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [teachers, setTeachers] = useState([]);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);

  const dtRef = useRef(null);
  const tableId = "teacherTable";


  const [previewSrc, setPreviewSrc] = useState(null);
  const closePreview = () => setPreviewSrc(null);

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && closePreview();
    if (previewSrc) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [previewSrc]);

  const canAnyAction = hasAnyPermission([
    "teachers.view",
    "teachers.update",
    "teachers.delete",
  ]);

  const photoUrl = (photo) => {
    if (!photo) return null;

    if (String(photo).startsWith("http")) return photo;

    return `${API_BASE_URL}/${String(photo).replace(/^\/+/, "")}`;
  };


  const isOnline = (t) => {
    const flag = t?.is_online === true || String(t?.is_online) === "1";
    const last = t?.last_seen_at ? new Date(t.last_seen_at) : null;
    const fresh = last ? Date.now() - last.getTime() <= ONLINE_GRACE_MS : false;
    return flag || fresh;
  };

  const normalizeTeacher = (t) => ({
    ...t,
    active:
      t?.is_active === true || String(t?.is_active ?? t?.status ?? "0") === "1",
    online: isOnline(t),
  });

  const fetchTeachers = async () => {
    try {
      const res = await API.get("/school/teachers");
      const rows = Array.isArray(res.data) ? res.data : [];
      setTeachers(rows.map(normalizeTeacher));
    } catch (err) {
      console.error("Fetch teachers failed:", err);
    } finally {
      setLoading(false);
    }
  };


  useEffect(() => {
    fetchTeachers();
  }, []);


  useEffect(() => {
    const id = setInterval(fetchTeachers, 20000);
    return () => clearInterval(id);
  }, []);


  useEffect(() => {

    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (teachers.length > 0) {
      dtRef.current = $("#teacherTable").DataTable({
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
          { targets: 4, width: "240px" },
          { targets: 5, width: "160px" },
          { targets: 6, width: "180px" },
          { targets: 7, width: "120px" },
          ...(canAnyAction ? [{ targets: 8, width: "170px" }] : []),
        ],
      });
    }

    return () => {
      if (dtRef.current) {
        dtRef.current.destroy();
        dtRef.current = null;
      }
    };
  }, [teachers, canAnyAction]);



  useEffect(() => {
    if (!dtRef.current) return;


    const t = setTimeout(() => {
      try {
        dtRef.current.columns.adjust().draw(false);
      } catch (e) {

        console.warn("DataTable adjust failed:", e);
      }
    }, 0);

    return () => clearTimeout(t);
  }, [teachers]);

  const deleteTeacher = async (id) => {
    if (!window.confirm("Delete this teacher?")) return;
    try {
      await API.delete(`/school/teachers/${id}`);
      setTeachers((prev) => prev.filter((t) => t.id !== id));
      setMessage("Teacher deleted successfully");
    } catch (err) {
      setMessage(err?.response?.data?.message || "Delete failed");
      console.error(err);
    }
  };

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Teachers</h5>

          {hasPermission("teachers.create") && (
            <Link to="/school/teachers/create">
              <button
                type="button"
                className="btn btn-primary-600 radius-3 px-20 py-11"
              >
                Add Teacher
              </button>
            </Link>
          )}
        </div>

        {message && <div className="alert alert-success">{message}</div>}

        <div className="card-body">
          <table
            className="table bordered-table mb-0"
            id={tableId}
            data-page-length={10}
          >
            <thead>
              <tr>
                <th>#</th>
                <th>Photo</th>
                <th>Name</th>
                <th>Teacher ID</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Subject</th>
                <th>Online</th>
                {canAnyAction && <th>Action</th>}
              </tr>
            </thead>

            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center py-4">
                    <div className="spinner-border spinner-border-sm" role="status" />
                    <div className="mt-2 text-muted">Loading teachers…</div>
                  </td>
                </tr>
              ) : teachers.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 9 : 8} className="text-center">
                    No teachers found
                  </td>
                </tr>
              ) : (
                teachers.map((t, idx) => {
                  return (
                    <tr key={t.id}>
                      <td>{idx + 1}</td>

                      <td>
                        {(() => {
                          const url = photoUrl(t.photo);

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
                                  alt={t.name}
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
                              style={{ width: 40, height: 40, borderRadius: "50%" }}
                              title="No photo"
                            >
                              <Icon icon="mdi:account" width={22} />
                            </div>
                          );
                        })()}
                      </td>

                      <td>
                        <Trunc value={t.name} maxWidth={220} />
                      </td>

                      <td>
                        <Trunc value={t.teacher_id} maxWidth={160} />
                      </td>

                      <td>
                        <Trunc value={t.email} maxWidth={240} />
                      </td>

                      <td>
                        <Trunc value={t.phone || "—"} maxWidth={160} />
                      </td>

                      <td>
                        <Trunc value={t.subject || "—"} maxWidth={180} />
                      </td>

                      <td>
                        <span
                          className={`px-24 py-4 rounded-pill fw-medium text-sm ${t.online
                            ? "bg-success-focus text-success-main"
                            : "bg-danger-focus text-danger-main"
                            }`}
                          title={
                            t.last_seen_at
                              ? `Last seen: ${new Date(t.last_seen_at).toLocaleString()}`
                              : ""
                          }
                        >
                          {t.online ? "Online" : "Offline"}
                        </span>
                      </td>

                      {canAnyAction && (
                        <td>
                          {hasPermission("teachers.view") && (
                            <Link
                              to={`/school/teachers/${t.id}`}
                              className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="View"
                            >
                              <Icon icon="iconamoon:eye-light" />
                            </Link>
                          )}

                          {hasPermission("teachers.update") && (
                            <Link
                              to={`/school/teachers/${t.id}/edit`}
                              className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="Edit"
                            >
                              <Icon icon="lucide:edit" />
                            </Link>
                          )}

                          {hasPermission("teachers.delete") && (
                            <button
                              type="button"
                              onClick={() => deleteTeacher(t.id)}
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
};

export default TeacherList;
