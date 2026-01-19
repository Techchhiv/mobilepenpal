import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Required = () => <span className="text-danger ms-1">*</span>;

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const LevelEdit = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("levels.view") || hasPermission("levels.update");
  const canEdit = hasPermission("levels.update");

  const from = location.state?.from || "/admin/levels";

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [level, setLevel] = useState(null);

  const [worlds, setWorlds] = useState([]);
  const [worldLoading, setWorldLoading] = useState(true);
  const [worldQ, setWorldQ] = useState("");

  const [form, setForm] = useState({
    world_id: "",
    name: "",
    description: "",
    background_image: "",
    order_index: "",
    is_active: true,
    is_unlocked_by_default: false,
  });

  const [initialForm, setInitialForm] = useState(null);

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const fetchWorlds = async () => {
    setWorldLoading(true);
    try {
      const res = await API.get("/admin/worlds?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.worlds) ? payload.worlds : [];
      setWorlds(rows);
    } catch (err) {
      console.error("Fetch worlds failed:", err);
      // non-fatal; still can edit other fields
    } finally {
      setWorldLoading(false);
    }
  };

  const fetchLevel = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/levels/${id}`);
      const payload = res.data?.data ?? res.data;
      const lv = payload?.level ?? payload ?? null;

      setLevel(lv);

      const next = {
        world_id: lv?.world_id ? String(lv.world_id) : "",
        name: lv?.name ?? "",
        description: lv?.description ?? "",
        background_image: lv?.background_image ?? "",
        order_index: lv?.order_index ?? "",
        is_active: normalizeBool(lv?.is_active),
        is_unlocked_by_default: normalizeBool(lv?.is_unlocked_by_default),
      };

      setForm(next);
      setInitialForm(next);
    } catch (err) {
      console.error("Fetch level failed:", err);
      setError(err?.response?.data?.message || "Failed to load level.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchLevel();
    fetchWorlds();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, canView]);

  const filteredWorlds = useMemo(() => {
    const q = worldQ.trim().toLowerCase();
    if (!q) return worlds;

    return worlds.filter((w) => {
      const name = String(w?.name ?? "").toLowerCase();
      const desc = String(w?.description ?? "").toLowerCase();
      const wid = String(w?.id ?? "");
      return name.includes(q) || desc.includes(q) || wid.includes(q);
    });
  }, [worldQ, worlds]);

  const selectedWorld = useMemo(() => {
    const wid = String(form.world_id || "");
    if (!wid) return null;
    return worlds.find((w) => String(w.id) === wid) || level?.world || null;
  }, [form.world_id, worlds, level]);

  const displayName = useMemo(() => {
    return form.name?.trim() || "Level";
  }, [form.name]);

  const prettyDateTime = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleString();
  };

  const resetForm = () => {
    if (!initialForm) return;
    setForm(initialForm);
    setWorldQ("");
    setError("");
    setMessage("");
  };

  const submit = async (e) => {
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

    if (!form.world_id) {
      setSaving(false);
      setError("Please select a world.");
      return;
    }

    try {
      const payload = {
        world_id: parseInt(form.world_id, 10),
        name: form.name.trim(),
        description: form.description?.trim() || null,
        background_image: form.background_image?.trim() || null,
        is_active: !!form.is_active,
        is_unlocked_by_default: !!form.is_unlocked_by_default,
      };

      if (String(form.order_index).trim() !== "") {
        payload.order_index = parseInt(form.order_index, 10);
      } else {
        payload.order_index = null; // optional: let backend ignore / keep current
      }

      await API.put(`/admin/levels/${id}`, payload);

      navigate(from, {
        state: { success: `Level "${payload.name}" updated successfully!` },
      });
    } catch (err) {
      console.error("Update failed:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.world_id?.[0] ||
          errors?.name?.[0] ||
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
          You don’t have permission to edit levels.
        </div>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="col-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h4 className="card-title mb-0">Edit Level</h4>
              <div className="text-muted small">
                ID: {id} {selectedWorld?.name ? `• World: ${selectedWorld.name}` : ""}
              </div>
            </div>

            <div className="d-flex gap-2 flex-wrap">
              <Link
                to={from}
                className="d-flex align-items-center btn btn-secondary"
              >
                <Icon icon="mdi:arrow-left" className="me-6" />
                Back
              </Link>

              <Link
                to={`/admin/levels/${id}`}
                state={{ from }}
                className="d-flex align-items-center btn btn-outline-dark"
                title="View level"
              >
                <Icon icon="iconamoon:eye-light" className="me-6" />
                View
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
            ) : (
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
                            <div className="text-muted small">Level ID: {id}</div>

                            <div className="text-muted small mt-8">
                              World:{" "}
                              <span className="fw-medium">
                                {selectedWorld?.name ?? "—"}
                              </span>
                            </div>

                            <div className="mt-10 d-flex gap-2 flex-wrap">
                              <span
                                className={`px-16 py-4 rounded-pill fw-medium text-sm ${
                                  form.is_active
                                    ? "bg-success-focus text-success-main"
                                    : "bg-warning-focus text-warning-main"
                                }`}
                              >
                                {form.is_active ? "Active" : "Disabled"}
                              </span>

                              <span
                                className={`px-16 py-4 rounded-pill fw-medium text-sm ${
                                  form.is_unlocked_by_default
                                    ? "bg-primary-light text-primary-600"
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

                        <div className="border-top mt-16 pt-12">
                          <div className="text-muted small mb-6">System</div>
                          <div className="d-flex justify-content-between small py-4">
                            <div className="text-muted">Created At</div>
                            <div className="fw-medium">
                              {prettyDateTime(level?.created_at)}
                            </div>
                          </div>
                          <div className="d-flex justify-content-between small py-4">
                            <div className="text-muted">Updated At</div>
                            <div className="fw-medium">
                              {prettyDateTime(level?.updated_at)}
                            </div>
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
                          {/* World search + select */}
                          <div className="col-12">
                            <label className="form-label">
                              World <Required />
                            </label>

                            <div className="row g-2">
                              <div className="col-md-5">
                                <div className="input-group">
                                  <span className="input-group-text">
                                    <Icon icon="mdi:magnify" />
                                  </span>
                                  <input
                                    className="form-control"
                                    placeholder="Search worlds..."
                                    value={worldQ}
                                    onChange={(e) => setWorldQ(e.target.value)}
                                    disabled={worldLoading}
                                  />
                                </div>
                              </div>

                              <div className="col-md-7">
                                <select
                                  className="form-control"
                                  value={form.world_id}
                                  onChange={onChange("world_id")}
                                  required
                                  disabled={worldLoading}
                                >
                                  <option value="">
                                    {worldLoading
                                      ? "Loading worlds..."
                                      : "Select a world"}
                                  </option>

                                  {filteredWorlds.map((w) => (
                                    <option key={w.id} value={w.id}>
                                      {w.name} (#{w.id})
                                    </option>
                                  ))}
                                </select>

                                <small className="text-muted">
                                  Type in search to filter the dropdown list.
                                </small>
                              </div>
                            </div>
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">
                              Name <Required />
                            </label>
                            <input
                              className="form-control"
                              value={form.name}
                              onChange={onChange("name")}
                              required
                              maxLength={255}
                            />
                          </div>

                          <div className="col-md-6">
                            <label className="form-label">Order Index</label>
                            <input
                              type="number"
                              className="form-control"
                              value={form.order_index}
                              onChange={onChange("order_index")}
                              min={1}
                            />
                            <small className="text-muted">
                              Optional. Leave as-is unless you want reorder.
                            </small>
                          </div>

                          <div className="col-12">
                            <label className="form-label">Background Image URL</label>
                            <input
                              className="form-control"
                              value={form.background_image}
                              onChange={onChange("background_image")}
                              maxLength={2048}
                              placeholder="https://..."
                            />
                          </div>

                          <div className="col-12">
                            <label className="form-label">Description</label>
                            <textarea
                              className="form-control"
                              rows={3}
                              value={form.description}
                              onChange={onChange("description")}
                              placeholder="Optional"
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

                    {/* Actions */}
                    <div className="d-flex justify-content-end gap-3 flex-wrap">
                      <button
                        className="d-flex align-items-center btn btn-primary"
                        type="submit"
                        disabled={saving}
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
            )}
          </div>
        </div>
      </div>
    </MasterLayout>
  );
};

export default LevelEdit;
