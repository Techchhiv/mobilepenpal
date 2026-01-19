import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const normalizeWorld = (w) => ({
  ...w,
  is_active: w?.is_active === true || String(w?.is_active ?? "0") === "1",
});

const LevelCreate = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canCreate = hasPermission("levels.create");
  const from = location.state?.from || "/admin/levels";

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [worlds, setWorlds] = useState([]);
  const [worldLoading, setWorldLoading] = useState(true);

  // ✅ IMPORTANT: this is the searchable text input value
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

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e.target.value;
    setForm((p) => ({ ...p, [key]: val }));
  };

  const fetchWorlds = async () => {
    setWorldLoading(true);
    setError("");

    try {
      // If your backend doesn't support include_inactive, remove it.
      const res = await API.get("/admin/worlds?include_inactive=1");
      const payload = res.data?.data ?? res.data;
      const rows = Array.isArray(payload?.worlds) ? payload.worlds : [];
      setWorlds(rows.map(normalizeWorld));
    } catch (err) {
      console.error("Fetch worlds failed:", err);
      setError(err?.response?.data?.message || "Failed to load worlds.");
    } finally {
      setWorldLoading(false);
    }
  };

  useEffect(() => {
    if (!canCreate) return;
    fetchWorlds();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canCreate]);

  // ✅ Filter worlds as user types (this is what you want)
  const filteredWorlds = useMemo(() => {
    const q = worldQ.trim().toLowerCase();
    if (!q) return worlds;

    return worlds.filter((w) => {
      const name = String(w?.name ?? "").toLowerCase();
      const desc = String(w?.description ?? "").toLowerCase();
      const id = String(w?.id ?? "");
      return name.includes(q) || desc.includes(q) || id.includes(q);
    });
  }, [worldQ, worlds]);

  const selectedWorld = useMemo(() => {
    const id = String(form.world_id || "");
    if (!id) return null;
    return worlds.find((w) => String(w.id) === id) || null;
  }, [form.world_id, worlds]);

  const resetForm = () => {
    setForm({
      world_id: "",
      name: "",
      description: "",
      background_image: "",
      order_index: "",
      is_active: true,
      is_unlocked_by_default: false,
    });
    setWorldQ("");
    setError("");
  };

  const submit = async (e) => {
    e.preventDefault();
    setError("");

    if (!form.world_id) {
      setError("Please select a world.");
      return;
    }
    if (!form.name?.trim()) {
      setError("Name is required.");
      return;
    }

    setSaving(true);

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
      }

      const res = await API.post("/admin/levels", payload);
      const created = res?.data?.data?.level ?? res?.data?.level ?? null;

      navigate(from, {
        state: {
          success: created?.name
            ? `Level "${created.name}" created successfully!`
            : "Level created successfully!",
        },
      });
    } catch (err) {
      console.error("Create level error:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.world_id?.[0] ||
          errors?.name?.[0] ||
          errors?.order_index?.[0] ||
          err?.response?.data?.message ||
          "Failed to create level. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!canCreate) {
    return (
      <MasterLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to create levels.
        </div>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Create Level</h5>
            <small className="text-muted">
              Create a new level under a world
            </small>
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
                    <Icon icon="mdi:stairs" width={72} />
                  </div>

                  <h6 className="mt-2 mb-1">{form.name?.trim() || "—"}</h6>

                  <div className="small text-muted">
                    World:{" "}
                    <span className="fw-medium">
                      {selectedWorld?.name ?? "—"}
                    </span>
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
            </div>

            {/* Right: Form */}
            <div className="col-md-8">
              <div className="card mb-0">
                <div className="card-header bg-light">
                  <h6 className="d-flex align-content-center mb-0">
                    <Icon icon="mdi:form-select" className="me-3" />
                    Level Information
                  </h6>
                </div>

                <div className="card-body">
                  <div className="row g-3">
                    {/* ✅ SEARCH + SELECT (this fixes your issue) */}
                    <div className="col-12">
                      <label className="form-label">World *</label>

                      <div className="row g-2">
                        <div className="col-md-5">
                          <div className="input-group">
                            <span className="input-group-text">
                              <Icon icon="mdi:magnify" />
                            </span>
                            <input
                              className="form-control"
                              placeholder="Search worlds..."
                              value={worldQ}                 // ✅ show typing
                              onChange={(e) => setWorldQ(e.target.value)} // ✅ update as type
                              disabled={worldLoading}
                            />
                          </div>
                          <small className="text-muted">
                            Type to filter the list.
                          </small>
                        </div>

                        <div className="col-md-7">
                          <select
                            className="form-control"
                            value={form.world_id}
                            onChange={onChange("world_id")}
                            disabled={worldLoading}
                            required
                          >
                            <option value="">
                              {worldLoading
                                ? "Loading worlds..."
                                : `Select a world (${filteredWorlds.length})`}
                            </option>

                            {filteredWorlds.map((w) => (
                              <option key={w.id} value={w.id}>
                                {w.name} (#{w.id})
                                {w.is_active ? "" : " • Disabled"}
                              </option>
                            ))}
                          </select>

                          <small className="text-muted">
                            Select from the filtered results.
                          </small>
                        </div>
                      </div>
                    </div>

                    {/* Name */}
                    <div className="col-md-6">
                      <label className="form-label">Name *</label>
                      <input
                        className="form-control"
                        placeholder="Enter level name"
                        value={form.name}
                        onChange={onChange("name")}
                        required
                        maxLength={255}
                      />
                    </div>

                    {/* Order */}
                    <div className="col-md-6">
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
                        Leave blank to auto-append within the selected world.
                      </small>
                    </div>

                    {/* Background image */}
                    <div className="col-12">
                      <label className="form-label">Background Image URL</label>
                      <input
                        className="form-control"
                        placeholder="https://..."
                        value={form.background_image}
                        onChange={onChange("background_image")}
                        maxLength={2048}
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

                    {/* Toggles */}
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

                    {/* Actions */}
                    <div className="col-12">
                      <div className="d-flex justify-content-end gap-2">
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={resetForm}
                          disabled={saving}
                        >
                          <Icon icon="mdi:refresh" className="me-2" />
                          Reset
                        </button>

                        <button
                          type="submit"
                          className="btn btn-primary-600"
                          disabled={saving || worldLoading}
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

export default LevelCreate;
