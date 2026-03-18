import React, { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Icon } from "@iconify/react";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

function prettyDate(d) {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleDateString();
}

const boolish = (v) => v === true || String(v ?? "0") === "1";

const SchoolWorldView = () => {
  const { id } = useParams();
  const { hasPermission } = useAuth();

  const [world, setWorld] = useState(null);
  const [loading, setLoading] = useState(true);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const canView = hasPermission("worlds.view");
  const canEdit = hasPermission("worlds.update");
  const canToggle = hasPermission("worlds.enable_disable");

  const canEditLevelBase = hasPermission("worlds.update");
  const canCreateLevelBase =
    hasPermission("levels.create") || hasPermission("worlds.update");

  const [insertLevelOpen, setInsertLevelOpen] = useState(false);
  const [insertLevelLoading, setInsertLevelLoading] = useState(false);
  const [insertLevelError, setInsertLevelError] = useState("");

  // ✅ Level insert fields (KH + EN)
  const [newLevelName, setNewLevelName] = useState("");
  const [newLevelNameEn, setNewLevelNameEn] = useState("");
  const [newLevelDescription, setNewLevelDescription] = useState("");
  const [newLevelDescriptionEn, setNewLevelDescriptionEn] = useState("");
  const [newLevelActive, setNewLevelActive] = useState(true);
  const [newLevelUnlockedByDefault, setNewLevelUnlockedByDefault] =
    useState(false);

  const fetchWorld = async () => {
    setLoading(true);
    setError("");
    setMessage("");

    try {
      const res = await API.get(`/school/worlds/${id}`);
      const payload = res.data?.data ?? res.data;
      setWorld(payload?.world ?? null);
    } catch (err) {
      console.error("Fetch school world failed:", err);
      setError(err?.response?.data?.message || "Failed to load world.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchWorld();
  }, [id, canView]);

  const normalized = useMemo(() => {
    if (!world) return null;

    const is_active = boolish(world?.is_active);
    const is_unlocked_by_default = boolish(world?.is_unlocked_by_default);

    const owned_by_school =
      !!world?.owned_by_school || world?.school_id != null;
    const is_hidden_for_school = !!world?.is_hidden_for_school;

    const levels = Array.isArray(world?.levels) ? world.levels : [];

    const levels_count = levels.length;
    const active_levels_count =
      Number(world?.active_levels_count) ||
      levels.filter((l) => boolish(l?.is_active)).length;

    const stages_count = levels.reduce(
      (sum, l) => sum + (Number(l?.stages_count) || 0),
      0
    );
    const active_stages_count = levels.reduce(
      (sum, l) => sum + (Number(l?.active_stages_count) || 0),
      0
    );

    const stack_order_index = world?.stack_order_index ?? null;

    return {
      ...world,
      is_active,
      is_unlocked_by_default,
      owned_by_school,
      is_hidden_for_school,
      stack_order_index,
      levels,
      levels_count,
      active_levels_count,
      stages_count,
      active_stages_count,
    };
  }, [world]);

  const canCreateLevel = !!(canCreateLevelBase && normalized?.owned_by_school);
  const canEditLevel = !!(canEditLevelBase && normalized?.owned_by_school);

  const openInsertLevel = () => {
    setInsertLevelError("");

    setNewLevelName("");
    setNewLevelNameEn("");
    setNewLevelDescription("");
    setNewLevelDescriptionEn("");

    setNewLevelActive(true);
    setNewLevelUnlockedByDefault(false);

    setInsertLevelOpen(true);
  };

  const closeInsertLevel = () => {
    if (insertLevelLoading) return;
    setInsertLevelOpen(false);
    setInsertLevelError("");
  };

  const submitInsertLevel = async () => {
    if (!normalized?.owned_by_school) {
      setInsertLevelError("You can only add levels to worlds owned by your school.");
      return;
    }

    setInsertLevelLoading(true);
    setInsertLevelError("");
    setError("");
    setMessage("");

    try {
      const name = newLevelName.trim();
      const name_en = newLevelNameEn.trim();

      if (!name) {
        setInsertLevelError("Level name (KH) is required.");
        return;
      }

      const payload = {
        name,
        name_en: name_en || null,
        description: newLevelDescription.trim() || null,
        description_en: newLevelDescriptionEn.trim() || null,
        is_active: newLevelActive ? 1 : 0,
        is_unlocked_by_default: newLevelUnlockedByDefault ? 1 : 0,
      };

      await API.post(`/school/worlds/${id}/levels`, payload);

      setMessage("Level created.");
      closeInsertLevel();
      await fetchWorld();
    } catch (err) {
      console.error("Create level failed:", err);
      const errors = err?.response?.data?.errors || {};
      setInsertLevelError(
        errors?.name?.[0] ||
          errors?.name_en?.[0] ||
          errors?.description?.[0] ||
          errors?.description_en?.[0] ||
          err?.response?.data?.message ||
          "Failed to create level."
      );
    } finally {
      setInsertLevelLoading(false);
    }
  };

  const toggleWorld = async () => {
    if (!normalized) return;

    setError("");
    setMessage("");

    try {
      await API.put(`/school/worlds/${id}/toggle`);
      setMessage("World updated");
      await fetchWorld();
    } catch (err) {
      console.error("Toggle failed:", err);
      setError(err?.response?.data?.message || "Toggle failed");
    }
  };

  if (!canView) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to view world details.
        </div>
      </SchoolLayout>
    );
  }

  const toggleLabel = normalized?.owned_by_school
    ? normalized?.is_active
      ? "Disable"
      : "Enable"
    : normalized?.is_hidden_for_school
      ? "Unhide"
      : "Hide";

  const toggleBtnClass = normalized?.owned_by_school
    ? normalized?.is_active
      ? "btn-warning"
      : "btn-primary"
    : normalized?.is_hidden_for_school
      ? "btn-primary"
      : "btn-warning";

  return (
    <SchoolLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">World Details</h5>
            <small className="text-muted">ID: {id}</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <Link
              to="/school/worlds"
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </Link>

            {canEdit && normalized?.owned_by_school && (
              <Link
                to={`/school/worlds/${id}/edit`}
                className="d-flex align-items-center btn btn-success radius-3 px-20 py-11"
              >
                <Icon icon="lucide:edit" className="me-6" />
                Edit
              </Link>
            )}

            {canToggle && normalized && (
              <button
                type="button"
                onClick={toggleWorld}
                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${toggleBtnClass}`}
                title="Toggle"
              >
                <Icon icon="mdi:toggle-switch" className="me-6" />
                {toggleLabel}
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
              <div className="mt-12 text-muted">Loading world...</div>
            </div>
          ) : !normalized ? (
            <div className="text-center py-40 text-muted">World not found.</div>
          ) : (
            <div className="row g-3">
              {/* Left */}
              <div className="col-12 col-md-4 col-lg-3">
                <div className="card border">
                  <div className="card-body text-center">
                    <div
                      className="d-inline-flex align-items-center justify-content-center"
                      style={{
                        width: 120,
                        height: 120,
                        borderRadius: 16,
                        background: "#e5e7eb",
                        border: "1px solid rgba(0,0,0,0.08)",
                      }}
                      title={normalized.theme_color || "—"}
                    >
                      <Icon icon="mdi:map" width={54} />
                    </div>

                    <h6 className="mt-16 mb-1">{normalized.name || "—"}</h6>
                    {normalized.name_en ? (
                      <div className="text-muted small mb-2">{normalized.name_en}</div>
                    ) : (
                      <div className="mb-2" />
                    )}

                    <div className="d-flex justify-content-center gap-8 flex-wrap mt-3">
                      <span
                        className={`badge ${normalized.is_active ? "bg-success" : "bg-secondary"}`}
                      >
                        {normalized.is_active ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge ${normalized.owned_by_school ? "bg-info" : "bg-light text-dark"}`}
                      >
                        {normalized.owned_by_school ? "School-owned" : "Global"}
                      </span>

                      {!normalized.owned_by_school && (
                        <span
                          className={`badge ${normalized.is_hidden_for_school ? "bg-warning" : "bg-light text-dark"}`}
                        >
                          {normalized.is_hidden_for_school ? "Hidden" : "Visible"}
                        </span>
                      )}
                    </div>

                    <div className="mt-10 text-muted">
                      Order Index:{" "}
                      <span className="text-dark">{normalized.order_index ?? "—"}</span>
                    </div>

                    {normalized.stack_order_index !== null && (
                      <div className="mt-2 text-muted">
                        Stack Order:{" "}
                        <span className="text-dark">{normalized.stack_order_index}</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="card border mt-3">
                  <div className="card-header">
                    <h6 className="mb-0">Content Summary</h6>
                  </div>
                  <div className="card-body">
                    <MiniRow
                      label="Levels"
                      value={`${normalized.active_levels_count}/${normalized.levels_count}`}
                    />
                    <MiniRow
                      label="Stages"
                      value={`${normalized.active_stages_count}/${normalized.stages_count}`}
                    />
                  </div>
                </div>
              </div>

              {/* Right */}
              <div className="col-12 col-md-8 col-lg-9">
                <div className="card border mb-3">
                  <div className="card-header">
                    <h6 className="mb-0">World Information</h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      {/* ✅ KH/EN fields */}
                      <InfoItem label="Name (KH)" value={normalized.name} />
                      <InfoItem label="Name (EN)" value={normalized.name_en || "—"} />
                      <InfoItem label="Audience" value={normalized.audience ?? "—"} />
                      <InfoItem
                        label="Default Unlocked"
                        value={normalized.is_unlocked_by_default ? "Yes" : "No"}
                      />

                      <InfoItem
                        label="Description (KH)"
                        value={normalized.description || "—"}
                        colClass="col-12"
                      />
                      <InfoItem
                        label="Description (EN)"
                        value={normalized.description_en || "—"}
                        colClass="col-12"
                      />
                    </div>
                  </div>
                </div>

                <div className="card border">
                  <div className="card-header">
                    <h6 className="mb-0">System</h6>
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <InfoItem label="Created At" value={prettyDate(normalized.created_at)} />
                      <InfoItem label="Updated At" value={prettyDate(normalized.updated_at)} />
                    </div>
                  </div>
                </div>

                <div className="card border mt-3">
                  <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h6 className="mb-0">Levels</h6>

                    {canCreateLevel && (
                      <button
                        type="button"
                        className="btn btn-primary d-flex align-items-center"
                        onClick={openInsertLevel}
                      >
                        <Icon icon="mdi:plus" className="me-6" />
                        Insert Level
                      </button>
                    )}
                  </div>

                  <div className="card-body">
                    {normalized.levels.length === 0 ? (
                      <div className="text-muted">No levels.</div>
                    ) : (
                      <div className="table-responsive">
                        <table className="table bordered-table mb-0">
                          <thead>
                            <tr>
                              <th>Order</th>
                              <th>Name</th>
                              <th>Status</th>
                              <th>Stages</th>
                              <th style={{ width: 120 }} className="text-center">
                                Action
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            {normalized.levels
                              .slice()
                              .sort(
                                (a, b) =>
                                  (a.order_index ?? 0) - (b.order_index ?? 0)
                              )
                              .map((l) => {
                                const active = boolish(l?.is_active);
                                const stagesCount = l?.stages_count ?? "—";
                                const activeStagesCount =
                                  l?.active_stages_count ?? "—";

                                return (
                                  <tr key={l.id} className={!active ? "table-light" : ""}>
                                    <td>{l.order_index ?? "—"}</td>

                                    {/* ✅ KH + EN display */}
                                    <td>
                                      <div className="fw-medium">{l.name ?? "—"}</div>
                                      {l.name_en ? (
                                        <div className="text-muted small">{l.name_en}</div>
                                      ) : null}
                                    </td>

                                    <td>
                                      <span
                                        className={`badge ${active ? "bg-success" : "bg-secondary"}`}
                                      >
                                        {active ? "Active" : "Disabled"}
                                      </span>
                                    </td>
                                    <td>
                                      {activeStagesCount}/{stagesCount}
                                    </td>
                                    <td className="text-center align-middle">
                                      <Link
                                        to={`/school/levels/${l.id}`}
                                        state={{ from: `/school/worlds/${id}` }}
                                        title="View Level"
                                        className="w-32-px h-32-px me-8 bg-primary-focus text-primary-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                        style={{ textDecoration: "none" }}
                                      >
                                        <Icon icon="mdi:eye-outline" />
                                      </Link>

                                      {canEditLevel && (
                                        <Link
                                          to={`/school/levels/${l.id}/edit`}
                                          state={{ from: `/school/worlds/${id}` }}
                                          title="Edit Level"
                                          className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                          style={{ textDecoration: "none" }}
                                        >
                                          <Icon icon="lucide:edit" />
                                        </Link>
                                      )}
                                    </td>
                                  </tr>
                                );
                              })}
                          </tbody>
                        </table>
                      </div>
                    )}

                    {!normalized.owned_by_school && (
                      <div className="mt-12 text-muted small">
                        Note: This is a global/admin world. Your school can hide/unhide it, but cannot add levels.
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ✅ Insert Level Modal */}
        {insertLevelOpen && (
          <div
            className="position-fixed top-0 start-0 w-100 h-100"
            style={{
              background: "rgba(0,0,0,0.55)",
              zIndex: 1055,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              padding: 16,
            }}
            onClick={closeInsertLevel}
            role="dialog"
            aria-modal="true"
          >
            <div
              className="card"
              style={{
                width: "min(860px, 96vw)",
                maxHeight: "90vh",
                overflow: "hidden",
              }}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="card-header d-flex justify-content-between align-items-center">
                <div>
                  <h6 className="mb-0">Insert Level</h6>
                  <small className="text-muted">Create a new level for this world</small>
                </div>

                <button className="btn btn-light d-flex" type="button" onClick={closeInsertLevel} title="Close">
                  <Icon icon="radix-icons:cross-2" />
                </button>
              </div>

              <div className="card-body" style={{ overflow: "auto" }}>
                {insertLevelError && (
                  <div className="alert alert-danger">{insertLevelError}</div>
                )}

                <div className="row g-3">
                  {/* ✅ Name KH/EN */}
                  <div className="col-12 col-md-6">
                    <label className="form-label">Level Name (KH) *</label>
                    <input
                      className="form-control"
                      value={newLevelName}
                      onChange={(e) => setNewLevelName(e.target.value)}
                      placeholder="ឧ. ក - ង"
                      disabled={insertLevelLoading}
                    />
                  </div>

                  <div className="col-12 col-md-6">
                    <label className="form-label">Level Name (EN)</label>
                    <input
                      className="form-control"
                      value={newLevelNameEn}
                      onChange={(e) => setNewLevelNameEn(e.target.value)}
                      placeholder="e.g. KA - NGO"
                      disabled={insertLevelLoading}
                    />
                  </div>

                  {/* ✅ Description KH/EN */}
                  <div className="col-12">
                    <label className="form-label">Description (KH)</label>
                    <textarea
                      className="form-control"
                      rows={3}
                      value={newLevelDescription}
                      onChange={(e) => setNewLevelDescription(e.target.value)}
                      placeholder="Optional (KH)"
                      disabled={insertLevelLoading}
                    />
                  </div>

                  <div className="col-12">
                    <label className="form-label">Description (EN)</label>
                    <textarea
                      className="form-control"
                      rows={3}
                      value={newLevelDescriptionEn}
                      onChange={(e) => setNewLevelDescriptionEn(e.target.value)}
                      placeholder="Optional (EN)"
                      disabled={insertLevelLoading}
                    />
                  </div>

                  <div className="col-12 col-md-6">
                    <div className="form-check d-flex align-items-center gap-2">
                      <input
                        className="form-check-input m-0"
                        type="checkbox"
                        id="newLevelActive"
                        checked={!!newLevelActive}
                        onChange={(e) => setNewLevelActive(e.target.checked)}
                        style={{ marginTop: 0 }}
                        disabled={insertLevelLoading}
                      />
                      <label className="form-check-label mb-0" htmlFor="newLevelActive">
                        Active
                      </label>
                    </div>
                    <small className="text-muted d-block">
                      If unchecked, this level will be hidden from students.
                    </small>
                  </div>

                  <div className="col-12 col-md-6">
                    <div className="form-check d-flex align-items-center gap-2">
                      <input
                        className="form-check-input m-0"
                        type="checkbox"
                        id="newLevelUnlockedByDefault"
                        checked={!!newLevelUnlockedByDefault}
                        onChange={(e) =>
                          setNewLevelUnlockedByDefault(e.target.checked)
                        }
                        style={{ marginTop: 0 }}
                        disabled={insertLevelLoading}
                      />
                      <label className="form-check-label mb-0" htmlFor="newLevelUnlockedByDefault">
                        Unlocked by default
                      </label>
                    </div>
                    <small className="text-muted d-block">
                      Students start with this level unlocked.
                    </small>
                  </div>
                </div>
              </div>

              <div className="card-footer d-flex justify-content-end gap-2">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={closeInsertLevel}
                  disabled={insertLevelLoading}
                >
                  Cancel
                </button>

                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={submitInsertLevel}
                  disabled={insertLevelLoading}
                >
                  {insertLevelLoading ? "Saving..." : "Create"}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </SchoolLayout>
  );
};

const InfoItem = ({ label, value, colClass = "col-12 col-md-6 col-lg-4" }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className={colClass}>
      <div className="p-12 border radius-8 h-100">
        <div className="text-muted small">{label}</div>
        <div className="fw-medium" style={{ wordBreak: "break-word" }}>
          {v}
        </div>
      </div>
    </div>
  );
};

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between gap-2 py-6 border-bottom">
      <div className="text-muted small">{label}</div>
      <div className="fw-medium">{v}</div>
    </div>
  );
};

export default SchoolWorldView;