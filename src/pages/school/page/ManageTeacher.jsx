// src/pages/school/ManageTeacher.jsx
import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import API from "../../../helper/api";
import SchoolLayout from "../masterLayout/SchoolLayout";

function ManageTeacher() {
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");

  // form
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const res = await API.get("/school/teachers");
      setTeachers(Array.isArray(res.data) ? res.data : res.data.data || []);
    } catch (e) {
      setErr(e?.response?.data?.message || "Failed to load teachers");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const flash = (text, isError = false) => {
    (isError ? setErr : setMsg)(text);
    setTimeout(() => (isError ? setErr("") : setMsg("")), 2500);
  };

  const createTeacher = async (e) => {
    e.preventDefault();
    try {
      await API.post("/school/teachers", { name, email });
      setName("");
      setEmail("");
      await load();
      flash("Teacher added");
    } catch (e) {
      flash(e?.response?.data?.message || "Create failed", true);
    }
  };

  const deleteTeacher = async (id) => {
    if (!window.confirm("Delete this teacher?")) return;
    try {
      await API.delete(`/school/teachers/${id}`);
      setTeachers((prev) => prev.filter((t) => t.id !== id));
      flash("Teacher deleted");
    } catch (e) {
      flash(e?.response?.data?.message || "Delete failed", true);
    }
  };

  return (
    <SchoolLayout>
      <div className="row g-4">
        {/* Add Teacher */}
        <div className="col-12 col-xl-4">
          <div className="card h-100">
            <div className="card-header">
              <h6 className="mb-0">Add New Teacher</h6>
            </div>
            <div className="card-body">
              <form onSubmit={createTeacher} className="d-flex flex-column gap-3">
                <div>
                  <label className="form-label">Name</label>
                  <input
                    className="form-control"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                  />
                </div>

                <div>
                  <label className="form-label">Email</label>
                  <input
                    type="email"
                    className="form-control"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>

                <button className="btn btn-primary">
                  <Icon icon="lucide:plus" className="me-1" /> Add Teacher
                </button>
                {msg && <span className="text-success">{msg}</span>}
                {err && <span className="text-danger">{err}</span>}
              </form>
            </div>
          </div>
        </div>

        {/* Teacher List */}
        <div className="col-12 col-xl-8">
          <div className="card h-100">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h6 className="mb-0">Teachers</h6>
              <span className="badge bg-neutral-200 text-neutral-800">
                {teachers.length}
              </span>
            </div>
            <div className="card-body">
              {loading ? (
                <div>Loading teachers…</div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-bordered">
                    <thead>
                      <tr>
                        <th style={{ width: 70 }}>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th style={{ width: 120 }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {teachers.map((t) => (
                        <tr key={t.id}>
                          <td>{t.id}</td>
                          <td>{t.name}</td>
                          <td>{t.email}</td>
                          <td>
                            <button
                              className="btn btn-sm btn-danger"
                              onClick={() => deleteTeacher(t.id)}
                            >
                              <Icon icon="mingcute:delete-2-line" />
                            </button>
                          </td>
                        </tr>
                      ))}
                      {!teachers.length && (
                        <tr>
                          <td colSpan={4} className="text-center text-muted py-4">
                            No teachers found
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
}

export default ManageTeacher;
