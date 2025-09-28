import React, { useState, useEffect } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import API from "../../../helper/api";
import SchoolLayout from "../masterLayout/SchoolLayout";
import { useAuth } from "../../../context/AuthContext";
import { Link } from "react-router-dom";

const ManageTeacherList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState("");
  const [err, setErr] = useState("");

  // Form state
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [subject, setSubject] = useState("");
  const [photo, setPhoto] = useState(null);

  const fetchTeachers = async () => {
    setLoading(true);
    try {
      const res = await API.get("/school/teachers");
      setTeachers(Array.isArray(res.data) ? res.data : res.data.data || []);
    } catch (error) {
      setErr("Failed to load teachers");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchTeachers(); }, []);

  // Initialize DataTable
  useEffect(() => {
    if (teachers.length > 0) {
      const table = $("#dataTable").DataTable({ destroy: true, pageLength: 10 });
      return () => table.destroy(true);
    }
  }, [teachers]);

  const flash = (text, isError = false) => {
    isError ? setErr(text) : setMsg(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 2500);
  };

  // Add Teacher
  const addTeacher = async (e) => {
    e.preventDefault();
    try {
      const formData = new FormData();
      formData.append("name", name);
      formData.append("email", email);
      formData.append("phone", phone);
      formData.append("subject", subject);
      if (photo) formData.append("photo", photo);

      await API.post("/school/teachers", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setName(""); setEmail(""); setPhone(""); setSubject(""); setPhoto(null);
      await fetchTeachers();
      flash("Teacher added successfully");
    } catch (error) {
      flash(error?.response?.data?.message || "Create failed", true);
      console.error(error);
    }
  };

  // Delete teacher
  const deleteTeacher = async (id) => {
    if (!window.confirm("Delete this teacher?")) return;
    try {
      await API.delete(`/school/teachers/${id}`);
      setTeachers((prev) => prev.filter((t) => t.id !== id));
      flash("Teacher deleted successfully");
    } catch (error) {
      flash(error?.response?.data?.message || "Delete failed", true);
      console.error(error);
    }
  };

  return (
    <SchoolLayout>
      <div className="row g-4">
        {/* Add Teacher Form */}
        {hasPermission("teachers.create") && (
          <div className="col-12 col-xl-4">
            <div className="card h-100">
              <div className="card-header"><h6>Add New Teacher</h6></div>
              <div className="card-body">
                <form onSubmit={addTeacher} className="d-flex flex-column gap-3">
                  <div>
                    <label className="form-label">Name</label>
                    <input className="form-control" value={name} onChange={e => setName(e.target.value)} required />
                  </div>
                  <div>
                    <label className="form-label">Email</label>
                    <input type="email" className="form-control" value={email} onChange={e => setEmail(e.target.value)} required />
                  </div>
                  <div>
                    <label className="form-label">Phone</label>
                    <input className="form-control" value={phone} onChange={e => setPhone(e.target.value)} />
                  </div>
                  <div>
                    <label className="form-label">Subject</label>
                    <input className="form-control" value={subject} onChange={e => setSubject(e.target.value)} />
                  </div>
                  <div>
                    <label className="form-label">Photo</label>
                    <input type="file" className="form-control" onChange={e => setPhoto(e.target.files[0])} />
                  </div>
                  <button className="btn btn-primary"><Icon icon="lucide:plus" className="me-1" /> Add Teacher</button>
                  {msg && <span className="text-success">{msg}</span>}
                  {err && <span className="text-danger">{err}</span>}
                </form>
              </div>
            </div>
          </div>
        )}

        {/* Teacher Table */}
        <div className="col-12 col-xl-8">
          <div className="card h-100">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h6>Teachers</h6>
              <span className="badge bg-neutral-200 text-neutral-800">{teachers.length}</span>
            </div>
            <div className="card-body">
              {loading ? (
                <div>Loading teachers…</div>
              ) : (
                <table className="table table-bordered" id="dataTable">
                  <thead>
                    <tr>
                      <th>S.L</th>
                      <th>Name</th>
                      <th>Email</th>
                      <th>Phone</th>
                      <th>Subject</th>
                      <th>Teacher ID</th>
                      <th>School Key</th>
                      {hasAnyPermission(["teachers.update","teachers.delete"]) && <th>Action</th>}
                    </tr>
                  </thead>
                  <tbody>
                    {teachers.map((t, idx) => (
                      <tr key={t.id}>
                        <td>{idx + 1}</td>
                        <td>{t.name}</td>
                        <td>{t.email}</td>
                        <td>{t.phone}</td>
                        <td>{t.subject}</td>
                        <td>{t.teacher_id}</td>
                        <td>{t.school_key}</td>
                        {hasAnyPermission(["teachers.update","teachers.delete"]) && (
                          <td>
                            {hasPermission("teachers.update") && (
                              <Link to={`/school/teachers/edit/${t.id}`} className="btn btn-sm btn-success me-2">
                                <Icon icon="lucide:edit" />
                              </Link>
                            )}
                            {hasPermission("teachers.delete") && (
                              <button onClick={() => deleteTeacher(t.id)} className="btn btn-sm btn-danger">
                                <Icon icon="mingcute:delete-2-line" />
                              </button>
                            )}
                          </td>
                        )}
                      </tr>
                    ))}
                    {teachers.length === 0 && (
                      <tr>
                        <td colSpan={8} className="text-center text-muted py-4">No teachers found</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
};

export default ManageTeacherList;
