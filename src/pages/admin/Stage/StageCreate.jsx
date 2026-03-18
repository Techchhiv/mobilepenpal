import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useSearchParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Required = () => <span className="text-danger ms-1">*</span>;

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const normalizeLevel = (lv) => ({
  ...lv,
  is_active: normalizeBool(lv?.is_active),
  world_name: lv?.world?.name ?? "—",
  level_name: lv?.name ?? "—",
  label: `${lv?.world?.name ?? "—"} → ${lv?.name ?? "—"} (#${lv?.id ?? "?"})`,
});

const StageCreate = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const [searchParams] = useSearchParams();
  const levelIdPrefill = searchParams.get("level_id"); // optional

  const canCreate = hasPermission("stages.create");
  const from = location.state?.from || "/admin/stages";

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [levels, setLevels] = useState([]);
  const [levelsLoading, setLevelsLoading] = useState(true);
  const [levelQ, setLevelQ] = useState("");

  const [form, setForm] = useState({
    level_id: levelIdPrefill || "",
    name: "",
    description: "",
    instruction: "",
    max_stars: 3,
    order_index: "",
    is_active: true,
  });

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const fetchLevels = async () => {
    setLevelsLoading(true);
    setError("");
    try {
      const res = await API.get("/admin/levels?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.levels) ? payload.levels : [];

      const mapped = rows.map(normalizeLevel);

      // sort by world name then order_index then level name
      mapped.sort((a, b) => {
        const wa = String(a.world_name || "").localeCompare(String(b.world_name || ""));
        if (wa !== 0) return wa;
        const oa = (a.order_index ?? 0) - (b.order_index ?? 0);
        if (oa !== 0) return oa;
        return String(a.level_name || "").localeCompare(String(b.level_name || ""));
      });

      setLevels(mapped);

      // if prefill exists but not found, clear it
      if (levelIdPrefill && !mapped.some((x) => String(x.id) === String(levelIdPrefill))) {
        setForm((p) => ({ ...p, level_id: "" }));
      }
    } catch (err) {
      console.error("Fetch levels failed:", err);
      setError(err?.response?.data?.message || "Failed to load levels.");
    } finally {
      setLevelsLoading(false);
    }
  };

  useEffect(() => {
    if (!canCreate) return;
    fetchLevels();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canCreate]);

  const filteredLevels = useMemo(() => {
    const q = levelQ.trim().toLowerCase();
    if (!q) return levels;

    return levels.filter((lv) => {
      const label = String(lv.label ?? "").toLowerCase();
      const name = String(lv.level_name ?? "").toLowerCase();
      const world = String(lv.world_name ?? "").toLowerCase();
      const id = String(lv.id ?? "");
      return label.includes(q) || name.includes(q) || world.includes(q) || id.includes(q);
    });
  }, [levelQ, levels]);

  const selectedLevel = useMemo(() => {
    const id = String(form.level_id || "");
    if (!id) return null;
    return levels.find((lv) => String(lv.id) === id) || null;
  }, [form.level_id, levels]);

  const resetForm = () => {
    setForm({
      level_id: levelIdPrefill || "",
      name: "",
      description: "",
      instruction: "",
      max_stars: 3,
      order_index: "",
      is_active: true,
    });
    setLevelQ("");
    setError("");
  };

  const submit = async (e) => {
    e.preventDefault();
    setError("");

    if (!form.level_id) {
      setError("Please select a level.");
      return;
    }
    if (!form.name?.trim()) {
      setError("Name is required.");
      return;
    }

    // max_stars is optional but you have rule min 1 max 10
    const ms = parseInt(form.max_stars, 10);
    if (Number.isNaN(ms) || ms < 1 || ms > 10) {
      setError("Max stars must be between 1 and 10.");
      return;
    }

    setSaving(true);

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

      const res = await API.post("/admin/stages", payload);

      const created = res?.data?.data?.stage ?? res?.data?.stage ?? null;

      navigate(from, {
        state: {
          success: created?.name
            ? `Stage "${created.name}" created successfully!`
            : "Stage created successfully!",
        },
      });
    } catch (err) {
      console.error("Create stage error:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.level_id?.[0] ||
          errors?.name?.[0] ||
          errors?.max_stars?.[0] ||
          errors?.order_index?.[0] ||
          err?.response?.data?.message ||
          "Failed to create stage. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!canCreate) {
    return (
      <MasterLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to create stages.
        </div>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Create Stage</h5>
            <small className="text-muted">Create a new stage under a level</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <Link
              to={from}
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </Link>
          </div>
        </div>

        <div className="card-body">
          {error && (
            <div className="alert alert-danger">
              <Icon icon="mdi:alert-circle" className="me-2" />
              {error}
            </div>
          )}

          <form className="row gy-4" onSubmit={submit}>
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
                    <Icon icon="mdi:layers" width={72} />
                  </div>

                  <h6 className="mt-2 mb-1">{form.name?.trim() || "—"}</h6>

                  <div className="small text-muted">
                    World:{" "}
                    <span className="fw-medium">{selectedLevel?.world_name ?? "—"}</span>
                  </div>

                  <div className="small text-muted">
                    Level:{" "}
                    <span className="fw-medium">{selectedLevel?.level_name ?? "—"}</span>
                  </div>

                  <div className="d-flex justify-content-center gap-8 flex-wrap mt-2">
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
                      Max Stars: {form.max_stars || 3}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Right: Form */}
            <div className="col-md-8">
              <div className="card mb-0">
                <div className="card-header bg-light">
                  <h6 className="d-flex align-content-center mb-0">
                    <Icon icon="mdi:form-select" className="me-3" />
                    Stage Information
                  </h6>
                </div>

                <div className="card-body">
                  <div className="row g-3">
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

                    {/* Name */}
                    <div className="col-md-6">
                      <label className="form-label">
                        Name <Required />
                      </label>
                      <input
                        className="form-control"
                        placeholder="Enter stage name"
                        value={form.name}
                        onChange={onChange("name")}
                        required
                        maxLength={255}
                      />
                    </div>

                    {/* Order */}
                    <div className="col-md-3">
                      <label className="form-label">Order Index</label>
                      <input
                        type="number"
                        className="form-control"
                        placeholder="Auto if blank"
                        value={form.order_index}
                        onChange={onChange("order_index")}
                        min={1}
                      />
                      <small className="text-muted">
                        Leave blank to auto-append.
                      </small>
                    </div>

                    {/* Max stars */}
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

                    {/* Instruction */}
                    <div className="col-12">
                      <label className="form-label">Instruction</label>
                      <textarea
                        className="form-control"
                        rows={3}
                        placeholder="Optional instruction shown to student"
                        value={form.instruction}
                        onChange={onChange("instruction")}
                      />
                    </div>

                    {/* Description */}
                    <div className="col-12">
                      <label className="form-label">Description</label>
                      <textarea
                        className="form-control"
                        rows={3}
                        placeholder="Optional description"
                        value={form.description}
                        onChange={onChange("description")}
                      />
                    </div>

                    {/* Active */}
                    <div className="col-12">
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

                    {/* Actions */}
                    <div className="col-12">
                      <div className="d-flex justify-content-end gap-2">
                        <button
                          type="button"
                          className="d-flex align-items-center btn btn-secondary"
                          onClick={resetForm}
                          disabled={saving}
                        >
                          <Icon icon="mdi:refresh" className="me-2" />
                          Reset
                        </button>

                        <button
                          type="submit"
                          className="d-flex align-items-center btn btn-primary-600"
                          disabled={saving || levelsLoading}
                        >
                          <Icon icon="mdi:plus" className="me-2" />
                          {saving ? "Creating..." : "Create"}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>
    </MasterLayout>
  );
};

export default StageCreate;
