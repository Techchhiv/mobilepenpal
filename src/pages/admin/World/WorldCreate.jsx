import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useLocation } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";

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
    is_premium: false,
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
      is_premium: false,
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
        is_premium: !!form.is_premium,
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
        errors?.is_premium?.[0] ||
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
      <div className="py-12">
        <AdminPageHeader
          title="Create New World"
          subtitle="Configure new learning world settings, audience scope, and content defaults"
        />

        <div className="card border radius-12 shadow-none">
          <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
            <h6 className="fw-bold mb-0 text-dark">Create World Form</h6>

            <Link to={from} className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6">
              <Icon icon="mdi:arrow-left" />
              <span>Back to Worlds</span>
            </Link>
          </div>

          <div className="card-body p-24">
            {error && (
              <div className="alert alert-danger d-flex align-items-center gap-2 mb-20 radius-8">
                <Icon icon="mdi:alert-circle" className="text-xl flex-shrink-0" />
                <div>{error}</div>
              </div>
            )}

            <form className="row gy-4 align-items-start" onSubmit={submit}>
              {/* Left: Preview */}
              <div className="col-md-4">
                <div className="card border radius-12 shadow-none h-100">
                  <div className="card-header border-bottom py-12 px-16 bg-base">
                    <h6 className="mb-0 fw-bold text-dark text-sm">Preview</h6>
                  </div>

                  <div className="card-body text-center d-flex flex-column justify-content-center gap-2 p-20">
                    <div
                      className="mx-auto d-flex align-items-center justify-content-center border radius-16 bg-neutral-100 text-secondary-light"
                      style={{
                        width: 130,
                        height: 130,
                      }}
                    >
                      <Icon icon="mdi:map" width={64} />
                    </div>

                    <h6 className="mt-2 mb-1 fw-bold text-dark">{form.name?.trim() || "—"}</h6>
                    {form.name_en?.trim() ? (
                      <div className="text-secondary-light small">{form.name_en.trim()}</div>
                    ) : null}

                    <div className="d-flex justify-content-center gap-8 flex-wrap mt-2">
                      <span className={`status-badge px-10 py-4 radius-6 text-xs fw-semibold ${previewActive ? "status-badge-active" : "status-badge-inactive"}`}>
                        {previewActive ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge px-10 py-4 radius-6 text-xs fw-semibold ${form.is_unlocked_by_default ? "bg-primary-50 text-primary-600" : "bg-neutral-100 text-secondary-light border border-neutral-200"
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
                <div className="card border radius-12 shadow-none mb-4">
                  <div className="card-header border-bottom py-12 px-16 bg-base">
                    <h6 className="d-flex align-items-center mb-0 fw-bold text-dark text-sm gap-2">
                      <Icon icon="mdi:earth" className="text-primary-600 text-lg" />
                      <span>World Information</span>
                    </h6>
                  </div>

                  <div className="card-body p-20">
                    <div className="col-md-12 mb-20">
                      <label className="form-label text-sm fw-semibold text-dark">Audience</label>
                      <select className="form-select form-select-sm radius-8" value={form.audience} onChange={onChange("audience")}>
                        <option value="public">Public (no-school users)</option>
                        <option value="schools">Schools (all registered schools)</option>
                        <option value="assigned">Assigned (selected schools only)</option>
                      </select>

                      <small className="text-secondary-light d-block mt-6">
                        • Public: students without school_id<br />
                        • Schools: any school student<br />
                        • Assigned: only selected schools via school_worlds
                      </small>
                    </div>

                    {form.audience === "assigned" && (
                      <div className="col-12 mb-20">
                        <label className="form-label text-sm fw-semibold text-dark">Assign to Schools</label>

                        <input
                          className="form-control form-control-sm radius-8 mb-2"
                          placeholder="Search school by name..."
                          value={schoolSearch}
                          onChange={(e) => setSchoolSearch(e.target.value)}
                        />

                        {schoolsError && <div className="alert alert-danger py-2">{schoolsError}</div>}

                        <div className="border radius-8 p-12 bg-base" style={{ maxHeight: 240, overflow: "auto" }}>
                          {schoolsLoading ? (
                            <div className="text-secondary-light text-sm">Loading schools...</div>
                          ) : (filteredSchools?.length ?? 0) === 0 ? (
                            <div className="text-secondary-light text-sm">No schools found.</div>
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
                                  <label className="form-check-label text-sm text-dark" htmlFor={`school-${s.id}`}>
                                    {s.name} <span className="text-secondary-light">#{s.id}</span>
                                  </label>
                                </div>
                              );
                            })
                          )}
                        </div>

                        <small className="text-secondary-light d-block mt-2">
                          Selected: {form.school_ids.length}
                        </small>
                      </div>
                    )}


                    <div className="row g-3">
                      <div className="col-md-12">
                        <label className="form-label text-sm fw-semibold text-dark">
                          Name (KH) <Required />
                        </label>
                        <input
                          className="form-control radius-8"
                          placeholder="Enter world name (Khmer)"
                          value={form.name}
                          onChange={onChange("name")}
                          required
                          maxLength={255}
                        />
                      </div>

                      <div className="col-md-12">
                        <label className="form-label text-sm fw-semibold text-dark">Name (EN)</label>
                        <input
                          className="form-control radius-8"
                          placeholder="Enter world name (English)"
                          value={form.name_en}
                          onChange={onChange("name_en")}
                          maxLength={255}
                        />
                      </div>

                      <div className="col-12">
                        <label className="form-label text-sm fw-semibold text-dark">Description (KH)</label>
                        <textarea
                          className="form-control radius-8"
                          placeholder="Optional description (Khmer)"
                          rows={3}
                          value={form.description}
                          onChange={onChange("description")}
                        />
                      </div>

                      <div className="col-12">
                        <label className="form-label text-sm fw-semibold text-dark">Description (EN)</label>
                        <textarea
                          className="form-control radius-8"
                          placeholder="Optional description (English)"
                          rows={3}
                          value={form.description_en}
                          onChange={onChange("description_en")}
                        />
                      </div>

                      <div className="col-md-6 d-flex align-items-center">
                        <div className="form-check d-flex align-items-center gap-2">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isActive"
                            checked={!!form.is_active}
                            onChange={onChange("is_active")}
                          />
                          <label className="form-check-label text-sm fw-semibold text-dark mb-0" htmlFor="isActive">
                            Active
                          </label>
                        </div>
                      </div>

                      <div className="col-md-6 d-flex align-items-center">
                        <div className="form-check d-flex align-items-center gap-2">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="unlockedByDefault"
                            checked={!!form.is_unlocked_by_default}
                            onChange={onChange("is_unlocked_by_default")}
                          />
                          <label className="form-check-label text-sm fw-semibold text-dark mb-0" htmlFor="unlockedByDefault">
                            Unlocked by default
                          </label>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="d-flex justify-content-end align-items-center gap-12">
                  <button
                    type="button"
                    className="btn btn-outline-secondary btn-sm radius-8 px-20 d-inline-flex align-items-center gap-6"
                    onClick={resetForm}
                    disabled={saving}
                  >
                    <Icon icon="mdi:refresh" />
                    <span>Reset Form</span>
                  </button>

                  <button
                    className="btn btn-primary btn-sm radius-8 px-20 d-inline-flex align-items-center gap-6"
                    type="submit"
                    disabled={saving}
                  >
                    {saving ? (
                      <>
                        <span className="spinner-border spinner-border-sm" />
                        <span>Creating…</span>
                      </>
                    ) : (
                      <>
                        <Icon icon="mdi:plus" />
                        <span>Create World</span>
                      </>
                    )}
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
