import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useLocation } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const WorldCreate = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canCreate = hasPermission("worlds.create");
  const from = location.state?.from || "/admin/worlds";
  const [schools, setSchools] = useState([]);
  const [schoolsLoading, setSchoolsLoading] = useState(false);
  const [schoolsError, setSchoolsError] = useState("");
  const [schoolSearch, setSchoolSearch] = useState("");


  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [form, setForm] = useState({
    name: "",
    name_en: "",
    description: "",
    description_en: "",
    audience: "schools",
    is_active: true,
    is_unlocked_by_default: false,
    school_ids: [],
  });

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox"
        ? e.target.checked
        : e?.target?.value ?? "";
    setForm((p) => ({ ...p, [key]: val }));
  };

  const resetForm = () => {
    setForm({
      name: "",
      name_en: "",
      description: "",
      description_en: "",
      is_active: true,
      is_unlocked_by_default: false,
    });
    setError("");
  };

  const previewActive = useMemo(() => !!form.is_active, [form.is_active]);

  useEffect(() => {
    if (form.audience !== "assigned") return;

    const t = setTimeout(async () => {
      setSchoolsLoading(true);
      setSchoolsError("");

      try {
        const res = await API.get("/admin/schools", {
          params: schoolSearch?.trim() ? { search: schoolSearch.trim() } : {},
        });

        const rows = res?.data?.data ?? [];
        setSchools(rows);
      } catch (e) {
        setSchoolsError(e?.response?.data?.message || "Failed to load schools.");
      } finally {
        setSchoolsLoading(false);
      }
    }, 250);

    return () => clearTimeout(t);
  }, [form.audience, schoolSearch]);

  const filteredSchools = useMemo(() => {
    const q = schoolSearch.trim().toLowerCase();
    if (!q) return schools;
    return schools.filter(s => (s?.name || "").toLowerCase().includes(q));
  }, [schools, schoolSearch]);

  const submit = async (e) => {
    e.preventDefault();
    if (!canCreate) return;

    setSaving(true);
    setError("");

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
      const payload = {
        name: form.name.trim(),
        name_en: form.name_en?.trim() || null,
        description: form.description?.trim() || null,
        description_en: form.description_en?.trim() || null,
        audience: form.audience,
        is_active: !!form.is_active,
        is_unlocked_by_default: !!form.is_unlocked_by_default,
        school_ids: form.audience === "assigned" ? form.school_ids : [],
      };

      const res = await API.post("/admin/worlds", payload);

      const createdWorld = res?.data?.data?.world ?? res?.data?.world ?? null;

      navigate(from, {
        state: {
          success: createdWorld?.name
            ? `World "${createdWorld.name}" created successfully!`
            : "World created successfully!",
        },
      });
    } catch (err) {
      console.error("Create world error:", err);

      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.name?.[0] ||
        errors?.name_en?.[0] ||
        errors?.description?.[0] ||
        errors?.description_en?.[0] ||
        errors?.is_active?.[0] ||
        errors?.is_unlocked_by_default?.[0] ||
        err?.response?.data?.message ||
        "Failed to create world. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!canCreate) {
    return (
      <MasterLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to create worlds.
        </div>
      </MasterLayout>
    );
  }

  const Required = () => <span className="text-danger ms-1">*</span>;

  return (
    <MasterLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <h3 className="card-title mb-0">Create New World</h3>

            <Link to={from} className="d-flex align-items-center btn btn-secondary">
              <Icon icon="mdi:arrow-left" className="me-3" />
              Back to Worlds
            </Link>
          </div>

          <div className="card-body">
            {error && (
              <div className="alert alert-danger">
                <Icon icon="mdi:alert-circle" className="me-2" />
                {error}
              </div>
            )}

            <form className="row gy-4 align-items-start" onSubmit={submit}>
              {/* Left: Preview */}
              <div className="col-md-4">
                <div className="card h-100">
                  <div className="card-header bg-light">
                    <h6 className="mb-0">Preview</h6>
                  </div>

                  <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                    <div
                      className="mx-auto d-flex align-items-center justify-content-center border overflow-hidden"
                      style={{
                        width: 150,
                        height: 150,
                        borderRadius: 16,
                        background: "#f1f5f9",
                      }}
                    >
                      <Icon icon="mdi:map" width={72} />
                    </div>

                    <h6 className="mt-2 mb-1">{form.name?.trim() || "—"}</h6>
                    {form.name_en?.trim() ? (
                      <div className="text-muted small">{form.name_en.trim()}</div>
                    ) : null}

                    <div className="d-flex justify-content-center gap-8 flex-wrap">
                      <span className={`badge ${previewActive ? "bg-success" : "bg-secondary"}`}>
                        {previewActive ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge ${form.is_unlocked_by_default ? "bg-primary" : "bg-light text-dark"
                          }`}
                      >
                        {form.is_unlocked_by_default ? "Default Unlock" : "Not Default"}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right: Form */}
              <div className="col-md-8">
                <div className="card mb-4">
                  <div className="card-header bg-light">
                    <h6 className="d-flex align-content-center mb-0">
                      <Icon icon="mdi:earth" className="me-3" />
                      World Information
                    </h6>
                  </div>

                  <div className="card-body">
                    <div className="col-md-12">
                      <label className="form-label">Audience</label>
                      <select className="form-select" value={form.audience} onChange={onChange("audience")}>
                        <option value="public">Public (no-school users)</option>
                        <option value="schools">Schools (all registered schools)</option>
                        <option value="assigned">Assigned (selected schools only)</option>
                      </select>

                      <small className="text-muted d-block mt-1">
                        • Public: students without school_id<br />
                        • Schools: any school student<br />
                        • Assigned: only selected schools via school_worlds
                      </small>
                    </div>

                    {form.audience === "assigned" && (
                      <div className="col-12">
                        <label className="form-label">Assign to Schools</label>

                        <input
                          className="form-control mb-2"
                          placeholder="Search school by name..."
                          value={schoolSearch}
                          onChange={(e) => setSchoolSearch(e.target.value)}
                        />

                        {schoolsError && <div className="alert alert-danger py-2">{schoolsError}</div>}

                        <div className="border radius-8 p-2" style={{ maxHeight: 240, overflow: "auto" }}>
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

                        <small className="text-muted d-block mt-2">
                          Selected: {form.school_ids.length}
                        </small>
                      </div>
                    )}


                    <div className="row g-3">
                      <div className="col-md-12">
                        <label className="form-label">
                          Name (KH) <Required />
                        </label>
                        <input
                          className="form-control"
                          placeholder="Enter world name (Khmer)"
                          value={form.name}
                          onChange={onChange("name")}
                          required
                          maxLength={255}
                        />
                      </div>

                      <div className="col-md-12">
                        <label className="form-label">Name (EN)</label>
                        <input
                          className="form-control"
                          placeholder="Enter world name (English)"
                          value={form.name_en}
                          onChange={onChange("name_en")}
                          maxLength={255}
                        />
                      </div>

                      <div className="col-12">
                        <label className="form-label">Description (KH)</label>
                        <textarea
                          className="form-control"
                          placeholder="Optional description (Khmer)"
                          rows={3}
                          value={form.description}
                          onChange={onChange("description")}
                        />
                      </div>

                      <div className="col-12">
                        <label className="form-label">Description (EN)</label>
                        <textarea
                          className="form-control"
                          placeholder="Optional description (English)"
                          rows={3}
                          value={form.description_en}
                          onChange={onChange("description_en")}
                        />
                      </div>

                      <div className="col-md-6 d-flex align-items-end">
                        <div className="form-check d-flex align-items-center">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isActive"
                            checked={!!form.is_active}
                            onChange={onChange("is_active")}
                          />
                          <label className="form-check-label" htmlFor="isActive">
                            Active
                          </label>
                        </div>
                      </div>

                      <div className="col-md-6 d-flex align-items-end">
                        <div className="form-check d-flex align-items-center">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="unlockedByDefault"
                            checked={!!form.is_unlocked_by_default}
                            onChange={onChange("is_unlocked_by_default")}
                          />
                          <label className="form-check-label" htmlFor="unlockedByDefault">
                            Unlocked by default
                          </label>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="d-flex justify-content-end align-items-end gap-2">
                  <button
                    className="d-flex align-items-center btn btn-primary"
                    type="submit"
                    disabled={saving}
                  >
                    <Icon icon="mdi:plus" className="me-3" />
                    <div>{saving ? "Creating..." : "Create World"}</div>
                  </button>

                  <button
                    type="button"
                    className="d-flex align-items-center btn btn-secondary"
                    onClick={resetForm}
                    disabled={saving}
                  >
                    <Icon icon="mdi:refresh" className="me-3" />
                    Reset Form
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </MasterLayout>
  );
};

export default WorldCreate;
