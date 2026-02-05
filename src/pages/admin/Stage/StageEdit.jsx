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
  const worldNameEn = lv?.world?.name_en ?? "";
  const levelName = lv?.name ?? "—";
  const levelNameEn = lv?.name_en ?? "";
  return {
    ...lv,
    is_active: normalizeBool(lv?.is_active),
    world_name: worldName,
    world_name_en: worldNameEn,
    level_name: levelName,
    level_name_en: levelNameEn,
    label: `${worldName}${worldNameEn ? ` / ${worldNameEn}` : ""} → ${levelName}${levelNameEn ? ` / ${levelNameEn}` : ""
      } (#${lv?.id ?? "?"})`,
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
    name_en: "",
    description: "",
    description_en: "",
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
        name_en: s?.name_en ?? "",
        description: s?.description ?? "",
        description_en: s?.description_en ?? "",
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
  }, [id, canView]);

  const filteredLevels = useMemo(() => {
    const q = levelQ.trim().toLowerCase();
    if (!q) return levels;

    return levels.filter((lv) => {
      const label = String(lv.label ?? "").toLowerCase();
      const name = String(lv.level_name ?? "").toLowerCase();
      const nameEn = String(lv.level_name_en ?? "").toLowerCase();
      const world = String(lv.world_name ?? "").toLowerCase();
      const worldEn = String(lv.world_name_en ?? "").toLowerCase();
      const idStr = String(lv.id ?? "");
      return (
        label.includes(q) ||
        name.includes(q) ||
        nameEn.includes(q) ||
        world.includes(q) ||
        worldEn.includes(q) ||
        idStr.includes(q)
      );
    });
  }, [levelQ, levels]);

  const selectedLevel = useMemo(() => {
    const lid = String(form.level_id || "");
    if (!lid) return stage?.level ?? null;
    return levels.find((lv) => String(lv.id) === lid) || stage?.level || null;
  }, [form.level_id, levels, stage]);

  const active = useMemo(() => normalizeBool(stage?.is_active), [stage]);

  const displayNameKh = useMemo(() => form.name?.trim() || "Stage", [form.name]);
  const displayNameEn = useMemo(() => form.name_en?.trim() || "", [form.name_en]);

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
      setError("Name (KH) is required.");
      return;
    }
    if (!form.name_en?.trim()) {
      setSaving(false);
      setError("Name (EN) is required.");
      return;
    }

    try {
      const payload = {
        level_id: parseInt(form.level_id, 10),
        name: form.name.trim(),
        name_en: form.name_en.trim(),
        description: form.description?.trim() || null,
        description_en: form.description_en?.trim() || null,
        is_active: !!form.is_active,
      };

      await API.put(`/admin/stages/${id}`, payload);

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
        errors?.name_en?.[0] ||
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

  const worldName =
    selectedLevel?.world?.name ??
    selectedLevel?.world_name ??
    stage?.level?.world?.name ??
    "—";

  const worldNameEn =
    selectedLevel?.world?.name_en ??
    selectedLevel?.world_name_en ??
    stage?.level?.world?.name_en ??
    "";

  const levelName =
    selectedLevel?.name ??
    selectedLevel?.level_name ??
    stage?.level?.name ??
    "—";

  const levelNameEn =
    selectedLevel?.name_en ??
    selectedLevel?.level_name_en ??
    stage?.level?.name_en ??
    "";

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Edit Stage</h5>
            <small className="text-muted">
              ID: {id} • {worldName}
              {worldNameEn ? ` / ${worldNameEn}` : ""} → {levelName}
              {levelNameEn ? ` / ${levelNameEn}` : ""}
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
                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${active ? "btn-warning" : "btn-primary"
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
                          <div className="fw-semibold">{displayNameKh}</div>
                          <div className="text-muted small">
                            {displayNameEn || "—"}
                          </div>

                          <div className="text-muted small mt-6">Stage ID: {id}</div>

                          <div className="text-muted small mt-8">
                            World: <span className="fw-medium">{worldName}</span>
                            {worldNameEn ? (
                              <span className="text-muted"> • {worldNameEn}</span>
                            ) : null}
                          </div>
                          <div className="text-muted small">
                            Level: <span className="fw-medium">{levelName}</span>
                            {levelNameEn ? (
                              <span className="text-muted"> • {levelNameEn}</span>
                            ) : null}
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
                                    {lv.label}
                                    {lv.is_active ? "" : " • Disabled"}
                                  </option>
                                ))}
                              </select>
                              <small className="text-muted">
                                Type in search to filter the dropdown list.
                              </small>
                            </div>
                          </div>
                        </div>

                        {/* Name KH / EN */}
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
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">
                            Name (EN) <Required />
                          </label>
                          <input
                            className="form-control"
                            value={form.name_en}
                            onChange={onChange("name_en")}
                            required
                            maxLength={255}
                          />
                        </div>

                        {/* Description KH / EN */}
                        <div className="col-md-6">
                          <label className="form-label">Description (KH)</label>
                          <textarea
                            className="form-control"
                            rows={3}
                            value={form.description}
                            onChange={onChange("description")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">Description (EN)</label>
                          <textarea
                            className="form-control"
                            rows={3}
                            value={form.description_en}
                            onChange={onChange("description_en")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-12">
                          <div className="form-check mt-2 d-flex justify-content-end align-items-center">
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
                      className="btn btn-outline-secondary d-flex align-items-center"
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
