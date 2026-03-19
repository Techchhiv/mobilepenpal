import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const Required = () => <span className="text-danger ms-1">*</span>;
const boolish = (v) => v === true || String(v ?? "0") === "1";

function prettyDateTime(d) {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleString();
}

const SchoolLevelEdit = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  // NOTE: keeping your original permissions
  const canView = hasPermission("worlds.view") || hasPermission("worlds.update");
  const canEdit = hasPermission("worlds.update");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [level, setLevel] = useState(null);

  // ✅ bilingual form fields
  const [form, setForm] = useState({
    name: "",
    name_en: "",
    description: "",
    description_en: "",
    is_active: true,
    is_unlocked_by_default: false,
  });

  const [initialForm, setInitialForm] = useState(null);

  const onChange = (key) => (e) => {
    const val = e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const fetchLevel = async () => {
    setLoading(true);
    setError("");
    setMessage("");

    try {
      const res = await API.get(`/school/levels/${id}`);
      const payload = res.data?.data ?? res.data;
      const lv = payload?.level ?? payload ?? null;

      setLevel(lv);

      const next = {
        name: lv?.name ?? "",
        name_en: lv?.name_en ?? "",
        description: lv?.description ?? "",
        description_en: lv?.description_en ?? "",
        is_active: boolish(lv?.is_active),
        is_unlocked_by_default: boolish(lv?.is_unlocked_by_default),
      };

      setForm(next);
      setInitialForm(next);
    } catch (err) {
      console.error("Fetch school level failed:", err);
      setError(err?.response?.data?.message || "Failed to load level.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchLevel();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, canView]);

  const normalized = useMemo(() => {
    if (!level) return null;

    const world = level?.world ?? null;

    // same ownership logic you used before
    const owned_by_school =
      !!world?.owned_by_school || world?.school_id != null || level?.world?.school_id != null;

    return {
      ...level,
      owned_by_school,
      world,
    };
  }, [level]);

  const from =
    location.state?.from ||
    (normalized?.world?.id ? `/school/worlds/${normalized.world.id}` : "/school/worlds");

  const displayName = useMemo(() => form.name?.trim() || "Level", [form.name]);
  const displayNameEn = useMemo(() => form.name_en?.trim() || "—", [form.name_en]);

  const resetForm = () => {
    if (!initialForm) return;
    setForm(initialForm);
    setError("");
    setMessage("");
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!canEdit) return;

    if (!normalized?.owned_by_school) {
      setError("This level belongs to a global/admin world and cannot be edited by the school.");
      return;
    }

    setSaving(true);
    setError("");
    setMessage("");

    if (!form.name?.trim()) {
      setSaving(false);
      setError("Name (KH) is required.");
      return;
    }

    try {
      const payload = {
        name: form.name.trim(),
        name_en: form.name_en?.trim() || null,
        description: form.description?.trim() || null,
        description_en: form.description_en?.trim() || null,
        is_active: !!form.is_active,
        is_unlocked_by_default: !!form.is_unlocked_by_default,
      };

      await API.put(`/school/levels/${id}`, payload);

      navigate(from, {
        state: { success: `Level "${payload.name}" updated successfully!` },
      });
    } catch (err) {
      console.error("Update school level failed:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.name?.[0] ||
        errors?.name_en?.[0] ||
        errors?.description?.[0] ||
        errors?.description_en?.[0] ||
        errors?.order_index?.[0] ||
        err?.response?.data?.message ||
        "Failed to update level."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!canView) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">You don’t have permission to view this page.</div>
      </SchoolLayout>
    );
  }

  if (!canEdit) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">You don’t have permission to edit levels.</div>
      </SchoolLayout>
    );
  }

  const worldNameKh = normalized?.world?.name ?? "—";
  const worldNameEn = normalized?.world?.name_en ?? "";

  return (
    <SchoolLayout>
      <div className="col-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h4 className="card-title mb-0">Edit Level</h4>
              <div className="text-muted small">
                ID: {id}
                {normalized?.world?.name ? (
                  <>
                    {" "}
                    • World: {worldNameKh}
                    {worldNameEn ? ` (${worldNameEn})` : ""}
                  </>
                ) : (
                  ""
                )}
              </div>
            </div>

            <div className="d-flex gap-2 flex-wrap">
              <Link to={from} className="d-flex align-items-center btn btn-secondary">
                <Icon icon="mdi:arrow-left" className="me-6" />
                Back
              </Link>
            </div>
          </div>

          <div className="card-body">
            {error && <div className="alert alert-danger">{error}</div>}
            {message && <div className="alert alert-success">{message}</div>}

            {loading ? (
              <div className="text-center py-40">
                <div className="spinner-border" role="status" />
                <div className="mt-12 text-muted">Loading level...</div>
              </div>
            ) : !normalized ? (
              <div className="text-center py-40 text-muted">Level not found.</div>
            ) : (
              <>
                {!normalized.owned_by_school && (
                  <div className="alert alert-warning">
                    <Icon icon="mdi:alert" className="me-6" />
                    This level belongs to a global/admin world. Your school can view it, but cannot edit it.
                  </div>
                )}

                <form onSubmit={submit}>
                  <div className="row g-3">
                    {/* Left preview */}
                    <div className="col-12 col-lg-4">
                      <div className="card border">
                        <div className="card-header d-flex align-items-center gap-2">
                          <Icon icon="mdi:stairs" />
                          <h6 className="mb-0">Preview</h6>
                        </div>

                        <div className="card-body">
                          <div className="d-flex align-items-center gap-3">
                            <div
                              className="border radius-12 overflow-hidden bg-neutral-50 d-flex align-items-center justify-content-center"
                              style={{ width: 120, height: 120 }}
                            >
                              <Icon icon="mdi:stairs" width={48} />
                            </div>

                            <div className="flex-grow-1">
                              <div className="fw-semibold">{displayName}</div>
                              <div className="text-muted small">{displayNameEn}</div>
                              <div className="text-muted small mt-2">Level ID: {id}</div>

                              <div className="text-muted small mt-8">
                                World:{" "}
                                <span className="fw-medium">
                                  {worldNameKh}
                                  {worldNameEn ? ` (${worldNameEn})` : ""}
                                </span>
                              </div>

                              <div className="mt-10 d-flex gap-2 flex-wrap">
                                <span
                                  className={`px-16 py-4 rounded-pill fw-medium text-sm ${form.is_active
                                      ? "bg-success-focus text-success-main"
                                      : "bg-warning-focus text-warning-main"
                                    }`}
                                >
                                  {form.is_active ? "Active" : "Disabled"}
                                </span>

                                <span
                                  className={`px-16 py-4 rounded-pill fw-medium text-sm ${form.is_unlocked_by_default
                                      ? "bg-primary-light text-primary-600"
                                      : "bg-light text-dark"
                                    }`}
                                >
                                  {form.is_unlocked_by_default ? "Default Unlock" : "Not Default"}
                                </span>
                                {normalized?.owned_by_school && (
                                  <span className="px-16 py-4 rounded-pill fw-medium text-sm bg-warning-focus text-warning-main" title="Levels created by your school are always premium">
                                    <Icon icon="mdi:crown" className="me-1" />
                                    Premium (Always Included)
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>

                          <div className="border-top mt-16 pt-12">
                            <div className="text-muted small mb-6">System</div>
                            <div className="d-flex justify-content-between small py-4">
                              <div className="text-muted">Created At</div>
                              <div className="fw-medium">{prettyDateTime(normalized?.created_at)}</div>
                            </div>
                            <div className="d-flex justify-content-between small py-4">
                              <div className="text-muted">Updated At</div>
                              <div className="fw-medium">{prettyDateTime(normalized?.updated_at)}</div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Right form */}
                    <div className="col-12 col-lg-8">
                      <div className="card border mb-3">
                        <div className="card-header d-flex align-items-center gap-2">
                          <Icon icon="mdi:form-select" />
                          <h6 className="mb-0">Level Information</h6>
                        </div>

                        <div className="card-body">
                          <div className="row gy-3">
                            {/* ✅ Name KH/EN */}
                            <div className="col-md-6">
                              <label className="form-label">
                                Name (KH) <Required />
                              </label>
                              <input
                                className="form-control"
                                value={form.name}
                                onChange={onChange("name")}
                                required
                                maxLength={255}
                                disabled={!normalized.owned_by_school || saving}
                              />
                            </div>

                            <div className="col-md-6">
                              <label className="form-label">Name (EN)</label>
                              <input
                                className="form-control"
                                value={form.name_en}
                                onChange={onChange("name_en")}
                                maxLength={255}
                                placeholder="Optional"
                                disabled={!normalized.owned_by_school || saving}
                              />
                            </div>

                            {/* ✅ Description KH/EN */}
                            <div className="col-12">
                              <label className="form-label">Description (KH)</label>
                              <textarea
                                className="form-control"
                                rows={3}
                                value={form.description}
                                onChange={onChange("description")}
                                placeholder="Optional (KH)"
                                disabled={!normalized.owned_by_school || saving}
                              />
                            </div>

                            <div className="col-12">
                              <label className="form-label">Description (EN)</label>
                              <textarea
                                className="form-control"
                                rows={3}
                                value={form.description_en}
                                onChange={onChange("description_en")}
                                placeholder="Optional (EN)"
                                disabled={!normalized.owned_by_school || saving}
                              />
                            </div>

                            <div className="col-md-6">
                              <div className="form-check mt-2">
                                <input
                                  className="form-check-input"
                                  type="checkbox"
                                  id="isActive"
                                  checked={!!form.is_active}
                                  onChange={onChange("is_active")}
                                  disabled={!normalized.owned_by_school || saving}
                                />
                                <label className="form-check-label" htmlFor="isActive">
                                  Active
                                </label>
                              </div>
                            </div>

                            <div className="col-md-6">
                              <div className="form-check mt-2">
                                <input
                                  className="form-check-input"
                                  type="checkbox"
                                  id="unlockedByDefault"
                                  checked={!!form.is_unlocked_by_default}
                                  onChange={onChange("is_unlocked_by_default")}
                                  disabled={!normalized.owned_by_school || saving}
                                />
                                <label className="form-check-label" htmlFor="unlockedByDefault">
                                  Unlocked by default
                                </label>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="d-flex justify-content-end gap-3 flex-wrap">
                        <button
                          className="d-flex align-items-center btn btn-primary"
                          type="submit"
                          disabled={saving || !normalized.owned_by_school}
                        >
                          <Icon icon="mdi:content-save" className="me-6" />
                          {saving ? "Saving..." : "Save Changes"}
                        </button>

                        <button
                          type="button"
                          className="btn btn-outline-secondary"
                          onClick={() => navigate(from)}
                          disabled={saving}
                        >
                          Cancel
                        </button>

                        <button
                          type="button"
                          className="btn btn-outline-secondary"
                          onClick={resetForm}
                          disabled={saving}
                          title="Reset to last loaded values"
                        >
                          <Icon icon="mdi:refresh" className="me-6" />
                          Reset
                        </button>
                      </div>
                    </div>
                  </div>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
};

export default SchoolLevelEdit;
