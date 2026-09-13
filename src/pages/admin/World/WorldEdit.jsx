import React, { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";

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
    is_premium: false,
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
        is_premium: w?.is_premium === true || String(w?.is_premium ?? "0") === "1",
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

        is_premium: !!form.is_premium,
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
      <div className="py-12">
        <AdminPageHeader
          title={`Edit World — ${form.name || `#${id}`}`}
          subtitle="Update world title, audience scope, and status"
        />

        <div className="card border radius-12 shadow-none">
          <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
            <div>
              <h6 className="fw-bold mb-0 text-dark">Edit World <span className="text-secondary-light text-xs font-normal">#{id}</span></h6>
            </div>

            <div className="d-flex gap-8 flex-wrap">
              <button
                type="button"
                onClick={() =>
                  window.history.length > 1
                    ? navigate(-1)
                    : navigate("/admin/worlds")
                }
                className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
              >
                <Icon icon="mdi:arrow-left" />
                <span>Back</span>
              </button>

              {canToggle && (
                <button
                  type="button"
                  onClick={toggleWorld}
                  className={`btn btn-sm radius-8 d-inline-flex align-items-center gap-6 ${active ? "btn-outline-warning" : "btn-primary"
                    }`}
                  title="Toggle Active"
                >
                  <Icon icon="mdi:toggle-switch" />
                  <span>{active ? "Disable" : "Enable"}</span>
                </button>
              )}
            </div>
          </div>

          <div className="card-body p-24">
            {message && <div className="alert alert-success mb-20 radius-8">{message}</div>}
            {error && <div className="alert alert-danger mb-20 radius-8">{error}</div>}

            {loading ? (
              <div className="text-center py-40 text-secondary-light">
                <div className="spinner-border spinner-border-sm me-2" role="status" />
                <span>Loading world...</span>
              </div>
            ) : !world ? (
              <div className="text-center py-40 text-secondary-light">World not found.</div>
            ) : (
              <form id="worldEditForm" onSubmit={save}>
                <div className="row g-3">
                  {/* Left preview */}
                  <div className="col-12 col-md-4 col-lg-3">
                    <div className="card border radius-12 shadow-none">
                      <div className="card-body text-center p-20">
                        <div
                          className="d-inline-flex align-items-center justify-content-center border radius-16 bg-neutral-100 text-secondary-light"
                          style={{
                            width: 110,
                            height: 110,
                          }}
                        >
                          <Icon icon="mdi:map" width={48} />
                        </div>

                        <h6 className="mt-3 mb-1 fw-bold text-dark">{form.name?.trim() || "—"}</h6>
                        <div className="text-secondary-light small mb-3">{form.name_en?.trim() || "—"}</div>

                        <div className="d-flex justify-content-center gap-8 flex-wrap">
                          <span
                            className={`status-badge px-10 py-4 radius-6 text-xs fw-semibold ${active ? "status-active" : "status-inactive"
                              }`}
                          >
                            {active ? "Active" : "Disabled"}
                          </span>

                          <span
                            className={`badge px-10 py-4 radius-6 text-xs fw-semibold ${form.is_unlocked_by_default
                              ? "bg-primary-50 text-primary-600"
                              : "bg-neutral-100 text-secondary-light border border-neutral-200"
                              }`}
                          >
                            {form.is_unlocked_by_default
                              ? "Default Unlock"
                              : "Not Default"}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="card border radius-12 shadow-none mt-3">
                      <div className="card-header border-bottom py-12 px-16 bg-base">
                        <h6 className="mb-0 fw-bold text-dark text-sm">System Info</h6>
                      </div>
                      <div className="card-body p-16">
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
                    <div className="card border radius-12 shadow-none mb-4">
                      <div className="card-header border-bottom py-12 px-16 bg-base">
                        <h6 className="mb-0 fw-bold text-dark text-sm">World Information</h6>
                      </div>


                      <div className="card-body p-20">

                        <div className="row g-3">
                          <Field label="Audience" colClass="col-12 col-lg-6">
                            <select className="form-select form-select-sm radius-8" value={form.audience} onChange={onChange("audience")}>
                              <option value="public">Public</option>
                              <option value="schools">Schools</option>
                              <option value="assigned">Assigned</option>
                            </select>
                          </Field>

                          {form.audience === "assigned" && (
                            <div className="col-12">
                              <div className="p-12 border radius-8 bg-base">
                                <div className="text-secondary-light small mb-2">Assigned Schools</div>

                                <input
                                  className="form-control form-control-sm radius-8 mb-2"
                                  placeholder="Search school by name..."
                                  value={schoolSearch}
                                  onChange={(e) => setSchoolSearch(e.target.value)}
                                />

                                {schoolsError && <div className="alert alert-danger py-2">{schoolsError}</div>}

                                <div style={{ maxHeight: 240, overflow: "auto" }} className="border radius-8 p-12 bg-base">
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

                                <small className="text-secondary-light d-block mt-2">Selected: {form.school_ids.length}</small>
                              </div>
                            </div>
                          )}

                          <Field label="Name (KH) *" colClass="col-12 col-lg-6">
                            <input
                              className="form-control form-control-sm radius-8"
                              value={form.name}
                              onChange={onChange("name")}
                              required
                              maxLength={255}
                            />
                          </Field>

                          <Field label="Name (EN)" colClass="col-12 col-lg-6">
                            <input
                              className="form-control form-control-sm radius-8"
                              value={form.name_en}
                              onChange={onChange("name_en")}
                              maxLength={255}
                              placeholder="Optional"
                            />
                          </Field>

                          <Field label="Description (KH)" colClass="col-12">
                            <textarea
                              className="form-control radius-8"
                              rows={4}
                              value={form.description}
                              onChange={onChange("description")}
                              placeholder="Optional"
                            />
                          </Field>

                          <Field label="Description (EN)" colClass="col-12">
                            <textarea
                              className="form-control radius-8"
                              rows={4}
                              value={form.description_en}
                              onChange={onChange("description_en")}
                              placeholder="Optional"
                            />
                          </Field>

                          <div className="col-12">
                            <div className="d-flex justify-content-end gap-4 flex-wrap">

                              <div className="form-check d-flex align-items-center gap-2">
                                <input
                                  className="form-check-input"
                                  type="checkbox"
                                  id="unlockedByDefault"
                                  checked={!!form.is_unlocked_by_default}
                                  onChange={onChange("is_unlocked_by_default")}
                                />
                                <label
                                  className="form-check-label text-sm fw-semibold text-dark mb-0"
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
                  </div>

                  {/* Actions */}
                  <div className="d-flex justify-content-end gap-12">
                    <button
                      type="button"
                      className="btn btn-outline-secondary btn-sm radius-8 px-20"
                      onClick={() => navigate("/admin/worlds")}
                      disabled={saving}
                    >
                      Cancel
                    </button>

                    <button
                      type="submit"
                      className="btn btn-primary btn-sm radius-8 px-20"
                      disabled={saving}
                    >
                      {saving ? "Saving..." : "Save World"}
                    </button>
                  </div>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    </MasterLayout>
  );
};

const Field = ({ label, children, colClass = "col-12 col-md-6" }) => (
  <div className={colClass}>
    <div className="p-12 border radius-8 h-100 bg-base">
      <div className="text-secondary-light text-xs fw-semibold mb-6">{label}</div>
      {children}
    </div>
  </div>
);

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between gap-1 py-6 border-bottom">
      <div className="text-secondary-light text-xs">{label}</div>
      <div className="fw-semibold text-dark text-xs">{v}</div>
    </div>
  );
};

export default WorldEdit;
