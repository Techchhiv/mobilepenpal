import React, { useMemo, useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useLocation } from "react-router-dom";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const Required = () => <span className="text-danger ms-1">*</span>;

const SchoolWorldCreate = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canCreate = hasPermission("worlds.create");
  const from = location.state?.from || "/school/worlds";

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [form, setForm] = useState({
    name: "",
    name_en: "",
    description: "",
    description_en: "",
    is_active: true,
    is_unlocked_by_default: false,
  });

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox" ? e.target.checked : e?.target?.value ?? "";
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

  const submit = async (e) => {
    e.preventDefault();
    if (!canCreate) return;

    setSaving(true);
    setError("");

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

      const res = await API.post("/school/worlds", payload);
      const createdWorld = res?.data?.data?.world ?? res?.data?.world ?? null;

      navigate(from, {
        state: {
          success: createdWorld?.name
            ? `World "${createdWorld.name}" created successfully!`
            : "World created successfully!",
        },
      });
    } catch (err) {
      console.error("Create school world error:", err);

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
      <SchoolLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to create worlds.
        </div>
      </SchoolLayout>
    );
  }

  return (
    <SchoolLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h3 className="card-title mb-0">Create New World</h3>
              <div className="text-muted small">Fill in Khmer and optionally English.</div>
            </div>

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
                      <Icon icon="mdi:map" width={72} />
                    </div>

                    <h6 className="mt-2 mb-0">{form.name?.trim() || "—"}</h6>
                    {form.name_en?.trim() ? (
                      <div className="text-muted small">
                        {form.name_en.trim()}
                      </div>
                    ) : (
                      <div className="mb-1" />
                    )}

                    <div className="d-flex justify-content-center gap-8 flex-wrap">
                      <span className={`badge ${previewActive ? "bg-success" : "bg-secondary"}`}>
                        {previewActive ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge ${
                          form.is_unlocked_by_default ? "bg-primary" : "bg-light text-dark"
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
                    <div className="row g-3">
                      {/* Names */}
                      <div className="col-md-6">
                        <label className="form-label">
                          Name (KH) <Required />
                        </label>
                        <input
                          className="form-control"
                          placeholder="ឧ. ព្យញ្ជនៈ"
                          value={form.name}
                          onChange={onChange("name")}
                          required
                          maxLength={255}
                        />
                      </div>

                      <div className="col-md-6">
                        <label className="form-label">Name (EN)</label>
                        <input
                          className="form-control"
                          placeholder="e.g. Consonants"
                          value={form.name_en}
                          onChange={onChange("name_en")}
                          maxLength={255}
                        />
                      </div>

                      {/* Descriptions */}
                      <div className="col-12">
                        <label className="form-label">Description (KH)</label>
                        <textarea
                          className="form-control"
                          placeholder="Optional description (KH)"
                          rows={3}
                          value={form.description}
                          onChange={onChange("description")}
                        />
                      </div>

                      <div className="col-12">
                        <label className="form-label">Description (EN)</label>
                        <textarea
                          className="form-control"
                          placeholder="Optional description (EN)"
                          rows={3}
                          value={form.description_en}
                          onChange={onChange("description_en")}
                        />
                      </div>

                      {/* Toggles */}
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
    </SchoolLayout>
  );
};

export default SchoolWorldCreate;