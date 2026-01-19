import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Required = () => <span className="text-danger ms-1">*</span>;

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const normalizeLevel = (lv) => {
  const worldName = lv?.world?.name ?? "—";
  const levelName = lv?.name ?? "—";
  return {
    ...lv,
    is_active: normalizeBool(lv?.is_active),
    world_name: worldName,
    level_name: levelName,
    label: `${worldName} → ${levelName} (#${lv?.id ?? "?"})`,
  };
};

const StageEdit = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("stages.view") || hasPermission("stages.update");
  const canEdit = hasPermission("stages.update");
  const canToggle = hasPermission("stages.enable_disable");

  const from = location.state?.from || "/admin/stages";

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const [stage, setStage] = useState(null);

  const [levels, setLevels] = useState([]);
  const [levelsLoading, setLevelsLoading] = useState(true);
  const [levelQ, setLevelQ] = useState("");

  const [form, setForm] = useState({
    level_id: "",
    name: "",
    description: "",
    instruction: "",
    max_stars: 3,
    order_index: "",
    is_active: true,
  });

  const [initialForm, setInitialForm] = useState(null);

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const fetchLevels = async () => {
    setLevelsLoading(true);
    try {
      const res = await API.get("/admin/levels?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.levels) ? payload.levels : [];

      const mapped = rows.map(normalizeLevel);
      mapped.sort((a, b) => {
        const wa = String(a.world_name || "").localeCompare(String(b.world_name || ""));
        if (wa !== 0) return wa;
        const oa = (a.order_index ?? 0) - (b.order_index ?? 0);
        if (oa !== 0) return oa;
        return String(a.level_name || "").localeCompare(String(b.level_name || ""));
      });

      setLevels(mapped);
    } catch (err) {
      console.error("Fetch levels failed:", err);
      // non-fatal; stage can still load
    } finally {
      setLevelsLoading(false);
    }
  };

  const fetchStage = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/stages/${id}`);
      const payload = res.data?.data ?? res.data;
      const s = payload?.stage ?? payload ?? null;

      setStage(s);

      const next = {
        level_id: s?.level_id ? String(s.level_id) : "",
        name: s?.name ?? "",
        description: s?.description ?? "",
        instruction: s?.instruction ?? "",
        max_stars: s?.max_stars ?? 3,
        order_index: s?.order_index ?? "",
        is_active: normalizeBool(s?.is_active),
      };

      setForm(next);
      setInitialForm(next);
    } catch (err) {
      console.error("Fetch stage failed:", err);
      setError(err?.response?.data?.message || "Failed to load stage.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchStage();
    fetchLevels();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, canView]);

  const filteredLevels = useMemo(() => {
    const q = levelQ.trim().toLowerCase();
    if (!q) return levels;

    return levels.filter((lv) => {
      const label = String(lv.label ?? "").toLowerCase();
      const name = String(lv.level_name ?? "").toLowerCase();
      const world = String(lv.world_name ?? "").toLowerCase();
      const idStr = String(lv.id ?? "");
      return label.includes(q) || name.includes(q) || world.includes(q) || idStr.includes(q);
    });
  }, [levelQ, levels]);

  const selectedLevel = useMemo(() => {
    const lid = String(form.level_id || "");
    if (!lid) return stage?.level ?? null;
    return levels.find((lv) => String(lv.id) === lid) || stage?.level || null;
  }, [form.level_id, levels, stage]);

  const active = useMemo(() => normalizeBool(stage?.is_active), [stage]);

  const displayName = useMemo(() => form.name?.trim() || "Stage", [form.name]);

  const prettyDateTime = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleString();
  };

  const resetForm = () => {
    if (!initialForm) return;
    setForm(initialForm);
    setLevelQ("");
    setError("");
    setMessage("");
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!canEdit) return;

    setSaving(true);
    setError("");
    setMessage("");

    if (!form.level_id) {
      setSaving(false);
      setError("Please select a level.");
      return;
    }
    if (!form.name?.trim()) {
      setSaving(false);
      setError("Name is required.");
      return;
    }

    const ms = parseInt(form.max_stars, 10);
    if (Number.isNaN(ms) || ms < 1 || ms > 10) {
      setSaving(false);
      setError("Max stars must be between 1 and 10.");
      return;
    }

    try {
      const payload = {
        level_id: parseInt(form.level_id, 10),
        name: form.name.trim(),
        description: form.description?.trim() || null,
        instruction: form.instruction?.trim() || null,
        max_stars: ms,
        is_active: !!form.is_active,
      };

      if (String(form.order_index).trim() !== "") {
        payload.order_index = parseInt(form.order_index, 10);
      }

      await API.put(`/admin/stages/${id}`, payload);

      // go back to view (or list), keeping your "from"
      navigate(`/admin/stages/${id}`, {
        state: { from },
        replace: true,
      });
    } catch (err) {
      console.error("Update stage error:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.level_id?.[0] ||
          errors?.name?.[0] ||
          errors?.max_stars?.[0] ||
          errors?.order_index?.[0] ||
          err?.response?.data?.message ||
          "Failed to update stage."
      );
    } finally {
      setSaving(false);
    }
  };

  const toggleStage = async () => {
    if (!canToggle) return;
    setError("");
    setMessage("");
    try {
      await API.put(`/admin/stages/${id}/toggle`);
      setMessage("Stage status updated.");
      await fetchStage();
    } catch (err) {
      console.error("Toggle failed:", err);
      setError(err?.response?.data?.message || "Toggle failed.");
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
          You don’t have permission to edit stages.
        </div>
      </MasterLayout>
    );
  }

  const worldName = selectedLevel?.world?.name ?? selectedLevel?.world_name ?? stage?.level?.world?.name ?? "—";
  const levelName = selectedLevel?.name ?? selectedLevel?.level_name ?? stage?.level?.name ?? "—";

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Edit Stage</h5>
            <small className="text-muted">
              ID: {id} • {worldName} → {levelName}
            </small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <button
              type="button"
              onClick={() => navigate(from)}
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </button>

            <Link
              to={`/admin/stages/${id}`}
              state={{ from }}
              className="d-flex align-items-center btn btn-outline-dark radius-3 px-20 py-11"
              title="View stage"
            >
              <Icon icon="iconamoon:eye-light" className="me-6" />
              View
            </Link>

            {canToggle && (
              <button
                type="button"
                onClick={toggleStage}
                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${
                  active ? "btn-warning" : "btn-primary"
                }`}
                title="Toggle Active"
                disabled={saving}
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
              <div className="mt-12 text-muted">Loading stage...</div>
            </div>
          ) : !stage ? (
            <div className="text-center py-40 text-muted">Stage not found.</div>
          ) : (
            <form onSubmit={submit}>
              <div className="row g-3">
                {/* Left preview */}
                <div className="col-12 col-lg-4">
                  <div className="card border">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:layers" />
                      <h6 className="mb-0">Preview</h6>
                    </div>

                    <div className="card-body">
                      <div className="d-flex align-items-center gap-3">
                        <div
                          className="border radius-12 overflow-hidden bg-neutral-50 d-flex align-items-center justify-content-center"
                          style={{ width: 120, height: 120 }}
                        >
                          <Icon icon="mdi:layers" width={48} />
                        </div>

                        <div className="flex-grow-1">
                          <div className="fw-semibold">{displayName}</div>
                          <div className="text-muted small">Stage ID: {id}</div>

                          <div className="text-muted small mt-8">
                            World: <span className="fw-medium">{worldName}</span>
                          </div>
                          <div className="text-muted small">
                            Level: <span className="fw-medium">{levelName}</span>
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

                            <span className="px-16 py-4 rounded-pill fw-medium text-sm bg-light text-dark">
                              Max Stars: {form.max_stars ?? "—"}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="border-top mt-16 pt-12">
                        <div className="text-muted small mb-6">System</div>
                        <div className="d-flex justify-content-between small py-4">
                          <div className="text-muted">Created At</div>
                          <div className="fw-medium">
                            {prettyDateTime(stage?.created_at)}
                          </div>
                        </div>
                        <div className="d-flex justify-content-between small py-4">
                          <div className="text-muted">Updated At</div>
                          <div className="fw-medium">
                            {prettyDateTime(stage?.updated_at)}
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
                      <h6 className="mb-0">Stage Information</h6>
                    </div>

                    <div className="card-body">
                      <div className="row gy-3">
                        {/* Level search + select */}
                        <div className="col-12">
                          <label className="form-label">
                            Level <Required />
                          </label>

                          <div className="row g-2">
                            <div className="col-md-5">
                              <div className="input-group">
                                <span className="input-group-text">
                                  <Icon icon="mdi:magnify" />
                                </span>
                                <input
                                  className="form-control"
                                  placeholder="Search levels..."
                                  value={levelQ}
                                  onChange={(e) => setLevelQ(e.target.value)}
                                  disabled={levelsLoading}
                                />
                              </div>
                            </div>

                            <div className="col-md-7">
                              <select
                                className="form-control"
                                value={form.level_id}
                                onChange={onChange("level_id")}
                                disabled={levelsLoading}
                                required
                              >
                                <option value="">
                                  {levelsLoading ? "Loading levels..." : "Select a level"}
                                </option>

                                {filteredLevels.map((lv) => (
                                  <option key={lv.id} value={lv.id}>
                                    {lv.label}{lv.is_active ? "" : " • Disabled"}
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

                        <div className="col-md-3">
                          <label className="form-label">Order Index</label>
                          <input
                            type="number"
                            className="form-control"
                            value={form.order_index}
                            onChange={onChange("order_index")}
                            min={1}
                          />
                        </div>

                        <div className="col-md-3">
                          <label className="form-label">Max Stars</label>
                          <input
                            type="number"
                            className="form-control"
                            value={form.max_stars}
                            onChange={onChange("max_stars")}
                            min={1}
                            max={10}
                          />
                        </div>

                        <div className="col-12">
                          <label className="form-label">Instruction</label>
                          <textarea
                            className="form-control"
                            rows={3}
                            value={form.instruction}
                            onChange={onChange("instruction")}
                            placeholder="Optional"
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

                        <div className="col-12">
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
    </MasterLayout>
  );
};

export default StageEdit;
