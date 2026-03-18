import React, { useEffect, useMemo, useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const WorldEdit = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { hasPermission } = useAuth();

  const canEdit = hasPermission("worlds.update");
  const canToggle = hasPermission("worlds.enable_disable");
  const canView = hasPermission("worlds.view") || canEdit;

  const [schools, setSchools] = useState([]);
  const [schoolsLoading, setSchoolsLoading] = useState(false);
  const [schoolsError, setSchoolsError] = useState("");
  const [schoolSearch, setSchoolSearch] = useState("");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const [world, setWorld] = useState(null);

  const [form, setForm] = useState({
    name: "",
    name_en: "",
    description: "",
    description_en: "",
    audience: "schools",
    school_ids: [],
    is_unlocked_by_default: false,
  });

  const active = useMemo(() => {
    const v = world?.is_active;
    return v === true || String(v ?? "0") === "1";
  }, [world]);

  const fetchWorld = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/worlds/${id}`);
      const payload = res.data?.data ?? res.data;
      const w = payload?.world ?? null;
      const assignedIds = payload?.assigned_school_ids ?? [];

      setWorld(w);
      setForm({
        name: w?.name ?? "",
        name_en: w?.name_en ?? "",
        description: w?.description ?? "",
        description_en: w?.description_en ?? "",
        audience: w?.audience ?? "schools",
        school_ids: Array.isArray(assignedIds) ? assignedIds : [],
        is_unlocked_by_default: w?.is_unlocked_by_default === true || String(w?.is_unlocked_by_default ?? "0") === "1",
      });
    } catch (err) {
      console.error("Fetch world failed:", err);
      setError(err?.response?.data?.message || "Failed to load world.");
    } finally {
      setLoading(false);
    }
  };

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const save = async (e) => {
    e.preventDefault();
    if (!canEdit) return;

    setSaving(true);
    setError("");
    setMessage("");

    if (!form.name?.trim()) {
      setSaving(false);
      setError("Name is required.");
      return;
    }

    if (form.audience === "assigned" && (!form.school_ids || form.school_ids.length === 0)) {
      setSaving(false);
      setError("Please select at least 1 school for Assigned audience.");
      return;
    }

    try {
      await API.put(`/admin/worlds/${id}`, {
        name: form.name.trim(),
        name_en: form.name_en?.trim() || null,
        description: form.description?.trim() || null,
        description_en: form.description_en?.trim() || null,

        audience: form.audience,
        school_ids: form.audience === "assigned" ? form.school_ids : [],

        is_unlocked_by_default: !!form.is_unlocked_by_default,
      });

      if (window.history.length > 1) {
        navigate(-1);
      } else {
        navigate(`/admin/worlds/${id}`);
      }
      return;
    } catch (err) {
      console.error("Update failed:", err);
      setError(err?.response?.data?.message || "Update failed");
    } finally {
      setSaving(false);
    }
  };

  const toggleWorld = async () => {
    if (!canToggle) return;
    setError("");
    setMessage("");
    try {
      await API.put(`/admin/worlds/${id}/toggle`);
      setMessage("World status updated.");
      await fetchWorld();
    } catch (err) {
      console.error("Toggle failed:", err);
      setError(err?.response?.data?.message || "Toggle failed");
    }
  };

  const filteredSchools = useMemo(() => {
    const q = schoolSearch.trim().toLowerCase();
    if (!q) return schools;
    return schools.filter(s => (s?.name || "").toLowerCase().includes(q));
  }, [schools, schoolSearch]);

  useEffect(() => {
    if (!canView) return;
    fetchWorld();
  }, [id, canView]);


  useEffect(() => {
    if (form.audience !== "assigned") return;

    const t = setTimeout(async () => {
      setSchoolsLoading(true);
      setSchoolsError("");

      try {
        const res = await API.get("/admin/schools", {
          params: schoolSearch?.trim() ? { search: schoolSearch.trim() } : {},
        });
        setSchools(res?.data?.data ?? []);
      } catch (e) {
        setSchoolsError(e?.response?.data?.message || "Failed to load schools.");
      } finally {
        setSchoolsLoading(false);
      }
    }, 250);

    return () => clearTimeout(t);
  }, [form.audience, schoolSearch]);


  if (!canView) {
    return (
      <MasterLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to view this page.
        </div>
      </MasterLayout>
    );
  }

  if (!canEdit) {
    return (
      <MasterLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to edit worlds.
        </div>
      </MasterLayout>
    );
  }

  function prettyDateTime(d) {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleString();
  }

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Edit World</h5>
            <small className="text-muted">ID: {id}</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <Link
              onClick={() =>
                window.history.length > 1
                  ? navigate(-1)
                  : navigate("/admin/worlds")
              }
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </Link>

            {canToggle && (
              <button
                type="button"
                onClick={toggleWorld}
                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${active ? "btn-warning" : "btn-primary"
                  }`}
                title="Toggle Active"
              >
                <Icon icon="mdi:toggle-switch" className="me-6" />
                {active ? "Disable" : "Enable"}
              </button>
            )}
          </div>
        </div>

        <div className="card-body">
          {message && <div className="alert alert-success">{message}</div>}
          {error && <div className="alert alert-danger">{error}</div>}

          {loading ? (
            <div className="text-center py-40">
              <div className="spinner-border" role="status" />
              <div className="mt-12 text-muted">Loading world...</div>
            </div>
          ) : !world ? (
            <div className="text-center py-40 text-muted">World not found.</div>
          ) : (
            <form id="worldEditForm" onSubmit={save}>
              <div className="row g-3">
                {/* Left preview */}
                <div className="col-12 col-md-4 col-lg-3">
                  <div className="card border">
                    <div className="card-body text-center">
                      <div
                        className="d-inline-flex align-items-center justify-content-center"
                        style={{
                          width: 120,
                          height: 120,
                          borderRadius: 16,
                          background: "#e5e7eb",
                          border: "1px solid rgba(0,0,0,0.08)",
                        }}
                      >
                        <Icon icon="mdi:map" width={54} />
                      </div>

                      <h6 className="mt-3 mb-1">{form.name?.trim() || "—"}</h6>
                      <div className="text-muted small mb-3">{form.name_en?.trim() || "—"}</div>

                      <div className="d-flex justify-content-center gap-8 flex-wrap">
                        <span
                          className={`badge ${active ? "bg-success" : "bg-secondary"
                            }`}
                        >
                          {active ? "Active" : "Disabled"}
                        </span>

                        <span
                          className={`badge ${form.is_unlocked_by_default
                            ? "bg-primary"
                            : "bg-light text-dark"
                            }`}
                        >
                          {form.is_unlocked_by_default
                            ? "Default Unlock"
                            : "Not Default"}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="card border mt-3">
                    <div className="card-header">
                      <h6 className="mb-0">System</h6>
                    </div>
                    <div className="card-body">
                      <MiniRow
                        label="Created At"
                        value={prettyDateTime(world?.created_at)}
                      />
                      <MiniRow
                        label="Updated At"
                        value={prettyDateTime(world?.updated_at)}
                      />
                    </div>
                  </div>
                </div>

                {/* Right form */}
                <div className="col-12 col-md-8 col-lg-9">
                  <div className="card border mb-0">
                    <div className="card-header">
                      <h6 className="mb-0">World Information</h6>
                    </div>


                    <div className="card-body">

                      <div className="row g-3">
                        <Field label="Audience" colClass="col-12 col-lg-6">
                          <select className="form-select" value={form.audience} onChange={onChange("audience")}>
                            <option value="public">Public</option>
                            <option value="schools">Schools</option>
                            <option value="assigned">Assigned</option>
                          </select>
                        </Field>

                        {form.audience === "assigned" && (
                          <div className="col-12">
                            <div className="p-12 border radius-8">
                              <div className="text-muted small mb-2">Assigned Schools</div>

                              <input
                                className="form-control mb-2"
                                placeholder="Search school by name..."
                                value={schoolSearch}
                                onChange={(e) => setSchoolSearch(e.target.value)}
                              />

                              {schoolsError && <div className="alert alert-danger py-2">{schoolsError}</div>}

                              <div style={{ maxHeight: 240, overflow: "auto" }} className="border radius-8 p-2">
                                {schoolsLoading ? (
                                  <div className="text-muted">Loading schools...</div>
                                ) : (filteredSchools?.length ?? 0) === 0 ? (
                                  <div className="text-muted">No schools found.</div>
                                ) : (
                                  filteredSchools.map((s) => {
                                    const checked = form.school_ids.includes(s.id);
                                    return (
                                      <div key={s.id} className="form-check d-flex align-items-center gap-2 py-1">
                                        <input
                                          className="form-check-input m-0"
                                          type="checkbox"
                                          id={`school-${s.id}`}
                                          checked={checked}
                                          onChange={() => {
                                            setForm((p) => {
                                              const next = checked
                                                ? p.school_ids.filter((x) => x !== s.id)
                                                : [...p.school_ids, s.id];
                                              return { ...p, school_ids: next };
                                            });
                                          }}
                                        />
                                        <label className="form-check-label" htmlFor={`school-${s.id}`}>
                                          {s.name} <span className="text-muted">#{s.id}</span>
                                        </label>
                                      </div>
                                    );
                                  })
                                )}
                              </div>

                              <small className="text-muted d-block mt-2">Selected: {form.school_ids.length}</small>
                            </div>
                          </div>
                        )}

                        <Field label="Name (KH) *" colClass="col-12 col-lg-6">
                          <input
                            className="form-control"
                            value={form.name}
                            onChange={onChange("name")}
                            required
                            maxLength={255}
                          />
                        </Field>

                        <Field label="Name (EN)" colClass="col-12 col-lg-6">
                          <input
                            className="form-control"
                            value={form.name_en}
                            onChange={onChange("name_en")}
                            maxLength={255}
                            placeholder="Optional"
                          />
                        </Field>

                        <Field label="Description (KH)" colClass="col-12">
                          <textarea
                            className="form-control"
                            rows={4}
                            value={form.description}
                            onChange={onChange("description")}
                            placeholder="Optional"
                          />
                        </Field>

                        <Field label="Description (EN)" colClass="col-12">
                          <textarea
                            className="form-control"
                            rows={4}
                            value={form.description_en}
                            onChange={onChange("description_en")}
                            placeholder="Optional"
                          />
                        </Field>

                        <div className="col-12">
                          <div className="form-check d-flex align-content-center justify-content-end">
                            <input
                              className="form-check-input"
                              type="checkbox"
                              id="unlockedByDefault"
                              checked={!!form.is_unlocked_by_default}
                              onChange={onChange("is_unlocked_by_default")}
                            />
                            <label
                              className="form-check-label"
                              htmlFor="unlockedByDefault"
                            >
                              Unlocked by default
                            </label>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="d-flex justify-content-end gap-2">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => navigate("/admin/worlds")}
                    disabled={saving}
                  >
                    Cancel
                  </button>

                  <button
                    type="submit"
                    className="btn btn-primary"
                    disabled={saving}
                  >
                    {saving ? "Saving..." : "Save"}
                  </button>
                </div>
              </div>
            </form>
          )}
        </div>
      </div>
    </MasterLayout>
  );
};

const Field = ({ label, children, colClass = "col-12 col-md-6" }) => (
  <div className={colClass}>
    <div className="p-12 border radius-8 h-100">
      <div className="text-muted small mb-6">{label}</div>
      {children}
    </div>
  </div>
);

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between gap-1 py-6 border-bottom">
      <div className="text-muted small">{label}</div>
      <div className="fw-medium">{v}</div>
    </div>
  );
};

export default WorldEdit;
