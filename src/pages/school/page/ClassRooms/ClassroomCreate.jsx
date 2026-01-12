import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";

export default function ClassroomCreate() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [teacherId, setTeacherId] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [description, setDescription] = useState("");

  const [teachers, setTeachers] = useState([]);
  const [loadingTeachers, setLoadingTeachers] = useState(false);

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const fetchTeachers = async () => {
      setLoadingTeachers(true);
      try {
        const res = await API.get("/school/teachers");
        const availableTeachers = Array.isArray(res.data)
          ? res.data.filter((teacher) => teacher.is_active)
          : [];
        setTeachers(availableTeachers);

        if (user?.email) {
          const currentTeacher = availableTeachers.find((t) => t.email === user.email);
          if (currentTeacher) setTeacherId(String(currentTeacher.id));
        }
      } catch (err) {
        console.error("Failed to fetch teachers:", err);
        setError("Could not load teachers list");
      } finally {
        setLoadingTeachers(false);
      }
    };

    fetchTeachers();
  }, [user]);

  useEffect(() => {
    const today = new Date().toISOString().split("T")[0];
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    const nextYearStr = nextYear.toISOString().split("T")[0];

    setStartDate(today);
    setEndDate(nextYearStr);
  }, []);

  const Required = () => <span className="text-danger ms-1">*</span>;

  const isTeacher = Boolean(user?.email && teachers.some((t) => t.email === user.email));

  const resetForm = () => {
    setName("");
    setDescription("");

    const today = new Date().toISOString().split("T")[0];
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    const nextYearStr = nextYear.toISOString().split("T")[0];

    setStartDate(today);
    setEndDate(nextYearStr);

    setError("");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (submitting) return;

    setError("");

    if (!name.trim()) {
      setError("Classroom name is required");
      return;
    }

    if (!teacherId) {
      setError("Please select a teacher for this classroom");
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        name: name.trim(),
        teacher_id: parseInt(teacherId, 10),
        start_date: startDate || new Date().toISOString().split("T")[0],
        end_date: endDate || null,
        description: description || null,
      };

      const res = await API.post("/school/classrooms", payload);
      const created = res?.data?.classroom || res?.data;

      // ✅ Redirect back to list with a flash message
      navigate("/school/classrooms", {
        state: {
          flash: `Classroom created successfully! Join Code: ${created?.join_code || "—"}`,
        },
        replace: true,
      });
    } catch (err) {
      console.error("Create classroom error:", err);
      setError(
        err?.response?.data?.errors?.name?.[0] ||
          err?.response?.data?.errors?.teacher_id?.[0] ||
          err?.response?.data?.message ||
          "Failed to create classroom. Please try again."
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <SchoolLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center">
            <h5 className="card-title mb-0">Create New Classroom</h5>
            <Link to="/school/classrooms" className="btn btn-secondary">
              Back to Classrooms
            </Link>
          </div>

          <div className="card-body">
            {error && <div className="alert alert-danger">{error}</div>}

            <form className="row gy-3" onSubmit={handleSubmit}>
              <div className="col-md-6">
                <label className="form-label">
                  Classroom Name <Required />
                </label>
                <input
                  className="form-control"
                  placeholder="e.g., Mr. Smith's Math Class"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  disabled={submitting}
                />
                <small className="text-muted">A descriptive name for the classroom</small>
              </div>

              <div className="col-md-3">
                <label className="form-label">Start Date</label>
                <input
                  type="date"
                  className="form-control"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  disabled={submitting}
                />
              </div>

              <div className="col-md-3">
                <label className="form-label">End Date (Optional)</label>
                <input
                  type="date"
                  className="form-control"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  min={startDate}
                  disabled={submitting}
                />
              </div>

              <div className="col-md-12">
                <label className="form-label">
                  Assigned Teacher <Required />
                </label>

                {loadingTeachers ? (
                  <div className="form-control">Loading teachers...</div>
                ) : isTeacher ? (
                  <input
                    type="text"
                    className="form-control"
                    value={teachers.find((t) => t.email === user.email)?.name || "Assigned Teacher"}
                    disabled
                  />
                ) : (
                  <select
                    className="form-control"
                    value={teacherId}
                    onChange={(e) => setTeacherId(e.target.value)}
                    required
                    disabled={submitting}
                  >
                    <option value="">Select a teacher</option>
                    {teachers.map((teacher) => (
                      <option key={teacher.id} value={teacher.id}>
                        {teacher.name} - {teacher.email}
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="col-md-12">
                <label className="form-label">Description (Optional)</label>
                <textarea
                  className="form-control"
                  placeholder="Enter a description for this classroom..."
                  rows="3"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  disabled={submitting}
                />
              </div>

              <div className="col-12">
                <div className="d-flex justify-content-end gap-3">
                  <button
                    className="d-flex align-items-center btn btn-primary"
                    type="submit"
                    disabled={submitting}
                  >
                    <Icon icon={submitting ? "mdi:loading" : "mdi:plus"} className="me-3" />
                    {submitting ? "Creating..." : "Create Classroom"}
                  </button>

                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={resetForm}
                    disabled={submitting}
                  >
                    Reset Form
                  </button>
                </div>

                {submitting && (
                  <div className="text-muted small mt-2 text-end">
                    Please wait… creating classroom
                  </div>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
}
