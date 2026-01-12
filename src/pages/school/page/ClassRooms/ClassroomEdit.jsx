import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";

import API from "../../../../helper/api";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import { useAuth } from "../../../../context/AuthContext";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function ClassroomEdit() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { hasPermission } = useAuth();

  const canEdit = hasPermission("classrooms.update");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState("");
  const [flash, setFlash] = useState("");

  const [classroom, setClassroom] = useState(null);

  const [form, setForm] = useState({
    name: "",
    start_date: "",
    end_date: "",
    is_active: true,
  });

  const setField = (k, v) => setForm((p) => ({ ...p, [k]: v }));

  const toDateInput = (d) => {
    if (!d) return "";
    if (/^\d{4}-\d{2}-\d{2}$/.test(String(d))) return String(d);
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return "";
    const yyyy = dt.getFullYear();
    const mm = String(dt.getMonth() + 1).padStart(2, "0");
    const dd = String(dt.getDate()).padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
  };

  const prettyDate = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleDateString();
  };

  const joinCode = useMemo(() => {
    const code = classroom?.join_code || classroom?.code || "";
    return code ? String(code) : "";
  }, [classroom]);

  const fetchClassroom = async () => {
    setLoading(true);
    setError("");
    setFlash("");
    try {
      const res = await API.get(`/school/classrooms/${id}`);
      const c = res?.data?.classroom ?? null;

      setClassroom(c);

      setForm({
        name: c?.name ?? "",
        start_date: toDateInput(c?.start_date),
        end_date: toDateInput(c?.end_date),
        is_active: Boolean(c?.is_active),
      });
    } catch (err) {
      console.error("Fetch classroom failed:", err);
      setError(err?.response?.data?.message || "Failed to load classroom.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (canEdit) fetchClassroom();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, canEdit]);

  const onSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");
    setFlash("");

    try {
      const payload = {
        name: form.name.trim(),
        start_date: form.start_date || null,
        end_date: form.end_date || null,
        is_active: form.is_active ? 1 : 0,
      };

      await API.put(`/school/classrooms/${id}`, payload);

      navigate(`/school/classrooms/${id}`, {
        replace: true,
        state: { flash: "Classroom updated successfully." },
      });
    } catch (err) {
      console.error("Update classroom failed:", err);
      const msg =
        err?.response?.data?.message ||
        (err?.response?.data?.errors
          ? Object.values(err.response.data.errors).flat().join("\n")
          : null) ||
        "Update failed.";
      setError(msg);
    } finally {
      setSaving(false);
    }
  };

  if (!canEdit) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to edit classrooms.
        </div>
      </SchoolLayout>
    );
  }

  return (
    <SchoolLayout>
      <div className="col-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h5 className="card-title mb-0">Edit Classroom</h5>
              <small className="text-muted">Update classroom information</small>
            </div>

            <Link
              to={`/school/classrooms/${id}`}
              className="btn btn-outline-secondary d-inline-flex align-items-center"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </Link>
          </div>

          <div className="card-body">
            {flash && <div className="alert alert-success">{flash}</div>}
            {error && (
              <div className="alert alert-danger" style={{ whiteSpace: "pre-line" }}>
                {error}
              </div>
            )}

            {loading ? (
              <div className="text-center py-40">
                <div className="spinner-border" role="status" />
                <div className="mt-12 text-muted">Loading classroom...</div>
              </div>
            ) : !classroom ? (
              <div className="text-center py-40 text-muted">Classroom not found.</div>
            ) : (
              <form onSubmit={onSubmit}>
                <div className="row g-3">
                  <div className="col-12 col-lg-8">
                    <div className="card border mb-3">
                      <div className="card-header d-flex align-items-center gap-2">
                        <Icon icon="mdi:clipboard-text-outline" />
                        <h6 className="mb-0">Classroom Information</h6>
                      </div>

                      <div className="card-body">
                        <div className="row gy-3">
                          <div className="col-12">
                            <label className="form-label">
                              Classroom Name <Required />
                            </label>
                            <input
                              className="form-control"
                              value={form.name}
                              onChange={(e) => setField("name", e.target.value)}
                              placeholder="Enter classroom name"
                              required
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Start Date</label>
                            <input
                              type="date"
                              className="form-control"
                              value={form.start_date}
                              onChange={(e) => setField("start_date", e.target.value)}
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">End Date</label>
                            <input
                              type="date"
                              className="form-control"
                              value={form.end_date}
                              onChange={(e) => setField("end_date", e.target.value)}
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="d-flex gap-2 flex-wrap">
                      <button
                        type="submit"
                        className="btn btn-primary d-inline-flex align-items-center"
                        disabled={saving}
                      >
                        <Icon icon={saving ? "line-md:loading-twotone-loop" : "mdi:content-save"} className="me-6" />
                        {saving ? "Saving..." : "Save Changes"}
                      </button>

                      <button
                        type="button"
                        className="btn btn-outline-secondary d-inline-flex align-items-center"
                        onClick={() => navigate(`/school/classrooms/${id}`)}
                        disabled={saving}
                      >
                        <Icon icon="mdi:close" className="me-6" />
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
}
