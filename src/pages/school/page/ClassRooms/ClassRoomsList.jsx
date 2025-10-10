import React, { useEffect, useState, useRef } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../../../helper/api";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import { useAuth } from "../../../../context/AuthContext";
import API_BASE_URL from "../../../../helper/Base_urls";

const ONLINE_GRACE_MS = 2 * 60 * 1000; // 2 minutes

const ClassRoomsList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [teachers, setTeachers] = useState([]);
  const [message, setMessage] = useState("");
  const dtRef = useRef(null);


  const fetchTeachers = async () => {
    try {
      const res = await API.get("/school/teachers");
      const rows = Array.isArray(res.data) ? res.data : [];
      // setTeachers(rows.map(normalizeTeacher));
    } catch (err) {
      console.error("Fetch teachers failed:", err);
    }
  };

  // initial load
  useEffect(() => { fetchTeachers(); }, []);

  // auto refresh every 20s (updates Online)
  useEffect(() => {
    const id = setInterval(fetchTeachers, 20000);
    return () => clearInterval(id);
  }, []);

  // (re)build DataTable when rows change
  useEffect(() => {
    if (dtRef.current) {
      dtRef.current.destroy(true);
      dtRef.current = null;
    }
    if (teachers.length > 0) {
      dtRef.current = $("#teacherTable").DataTable({ destroy: true, pageLength: 10 });
    }
    return () => {
      if (dtRef.current) {
        dtRef.current.destroy(true);
        dtRef.current = null;
      }
    };
  }, [teachers]);

  const deleteTeacher = async (id) => {
    if (!window.confirm("Delete this teacher?")) return;
    try {
      await API.delete(`#`);
      setTeachers((prev) => prev.filter((t) => t.id !== id));
      setMessage("Teacher deleted successfully");
    } catch (err) {
      setMessage(err?.response?.data?.message || "Delete failed");
      console.error(err);
    }
  };

  const canAnyAction = hasAnyPermission(["teachers.view", "teachers.update", "teachers.delete"]);

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Teachers</h5>
          {hasPermission("teachers.create") && (
            <Link to="3">
              <button type="button" className="btn btn-primary-600 radius-3 px-20 py-11">
                Add ClassRooms
              </button>
            </Link>
          )}
        </div>

        {message && <div className="alert alert-success">{message}</div>}

        <div className="card-body">
          <table className="table bordered-table mb-0" id="teacherTable" data-page-length={10}>
            <thead>
              <tr>
                <th>#</th>
                <th>Photo</th>
                <th>Name</th>
                <th>Teacher ID</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Subject</th>
                {/* <th>Status</th> */}
                <th>Online</th>
                {canAnyAction && <th>Action</th>}
              </tr>
            </thead>
            <tbody>
              {teachers.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 10 : 9} className="text-center">
                    No teachers found
                  </td>
                </tr>
              ) : (
                teachers.map((t, idx) => (
                  <tr key={t.id}>
                    <td>{idx + 1}</td>
                    <td>
                      {t.photo ? (
                        <img
                          src={`${API_BASE_URL}/storage/${t.photo}`}
                          alt={t.name}
                          style={{ width: 40, height: 40, objectFit: "cover", borderRadius: "50%" }}
                        />
                      ) : (
                        <span className="text-muted">No Image</span>
                      )}
                    </td>
                    <td>{t.name}</td>
                    <td>{t.teacher_id}</td>
                    <td>{t.email}</td>
                    <td>{t.phone}</td>
                    <td>{t.subject}</td>

                    {/* <td>
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          t.active ? "bg-success-focus text-success-main" : "bg-danger-focus text-danger-main"
                        }`}
                      >
                        {t.active ? "Active" : "Inactive"}
                      </span>
                    </td> */}

                    <td>
                      <span
                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                          t.online ? "bg-success-focus text-success-main" : "bg-danger-focus text-danger-main"
                        }`}
                        title={t.last_seen_at ? `Last seen: ${new Date(t.last_seen_at).toLocaleString()}` : ""}
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
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </SchoolLayout>
  );
};

export default ClassRoomsList;
