import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";
import SchoolLayout from "../../masterLayout/SchoolLayout";

const Trunc = ({ value, maxWidth = 360 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const boolish = (v) => v === true || String(v ?? "0") === "1";

const prettyDateTime = (d) => {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleString();
};

const SchoolStageView = () => {
  const { id } = useParams();
  const stageId = id;

  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("worlds.view") || hasPermission("worlds.update");
  const canEdit = hasPermission("worlds.update");

  const [loading, setLoading] = useState(true);
  const [stage, setStage] = useState(null);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // Edit Stage Modal State
  const [editOpen, setEditOpen] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editError, setEditError] = useState("");
  const [editName, setEditName] = useState("");
  const [editNameEn, setEditNameEn] = useState("");
  const [editDescription, setEditDescription] = useState("");
  const [editDescriptionEn, setEditDescriptionEn] = useState("");
  const [editActive, setEditActive] = useState(true);

  // Exercise inline editing state
  const [editingExerciseId, setEditingExerciseId] = useState(null);
  const [editRepeatInput, setEditRepeatInput] = useState(1);
  const [updatingExerciseId, setUpdatingExerciseId] = useState(null);

  // Attach Exercise Modal State
  const [attachOpen, setAttachOpen] = useState(false);
  const [attachLoading, setAttachLoading] = useState(false);
  const [attachError, setAttachError] = useState("");
  const [exerciseQuery, setExerciseQuery] = useState("");
  const [characterType, setCharacterType] = useState("");
  const [exerciseRows, setExerciseRows] = useState([]);
  const [selectedExerciseId, setSelectedExerciseId] = useState(null);
  const [attachRepeatCount, setAttachRepeatCount] = useState(1);

  const fetchStage = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await API.get(`/school/stages/${stageId}`);
      const payload = res.data?.data ?? res.data;
      const st = payload?.stage ?? payload ?? null;
      setStage(st);
    } catch (err) {
      console.error("Fetch school stage failed:", err);
      setError(err?.response?.data?.message || "Failed to load stage.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchStage();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stageId, canView]);

  const normalized = useMemo(() => {
    if (!stage) return null;

    const level = stage?.level ?? null;
    const world = level?.world ?? null;

    const active = boolish(stage?.is_active);
    const unlocked = boolish(stage?.is_unlocked_by_default);

    const exercises = Array.isArray(stage?.stage_exercises)
      ? stage.stage_exercises
      : Array.isArray(stage?.stageExercises)
      ? stage.stageExercises
      : [];

    return {
      ...stage,
      level,
      world,
      active,
      unlocked,
      exercises,
    };
  }, [stage]);

  const from =
    location.state?.from ||
    (normalized?.level?.id
      ? `/school/levels/${normalized.level.id}`
      : "/school/worlds");

  const goBack = () => {
    navigate(from);
  };

  // Edit stage modal handlers
  const openEditModal = () => {
    if (!normalized) return;
    setEditName(normalized.name ?? "");
    setEditNameEn(normalized.name_en ?? "");
    setEditDescription(normalized.description ?? "");
    setEditDescriptionEn(normalized.description_en ?? "");
    setEditActive(normalized.active);
    setEditError("");
    setEditOpen(true);
  };

  const closeEditModal = () => {
    if (editLoading) return;
    setEditOpen(false);
    setEditError("");
  };

  const submitEditStage = async () => {
    if (!canEdit) return;
    const name = (editName || "").trim();
    if (!name) {
      setEditError("Stage name (KH) is required.");
      return;
    }

    setEditLoading(true);
    setEditError("");
    try {
      await API.put(`/school/stages/${stageId}`, {
        name,
        name_en: (editNameEn || "").trim() || null,
        description: (editDescription || "").trim() || null,
        description_en: (editDescriptionEn || "").trim() || null,
        is_active: !!editActive,
      });

      setMessage("Stage updated successfully.");
      closeEditModal();
      await fetchStage();
    } catch (err) {
      console.error("Update stage failed:", err);
      const errors = err?.response?.data?.errors || {};
      setEditError(
        errors?.name?.[0] ||
          errors?.name_en?.[0] ||
          errors?.description?.[0] ||
          err?.response?.data?.message ||
          "Failed to update stage."
      );
    } finally {
      setEditLoading(false);
    }
  };

  // Inline exercise edit handlers
  const startEditExercise = (se) => {
    setEditingExerciseId(se.id);
    setEditRepeatInput(se?.repeat_count ?? 1);
  };

  const cancelEditExercise = () => {
    setEditingExerciseId(null);
  };

  const saveExerciseRepeat = async (stageExerciseId) => {
    if (!canEdit) return;
    const rawVal = Number(editRepeatInput || 1);
    const count = Math.min(3, Math.max(1, rawVal));
    setUpdatingExerciseId(stageExerciseId);
    setError("");
    setMessage("");

    try {
      await API.put(`/school/stage-exercises/${stageExerciseId}`, {
        repeat_count: count,
      });
      setMessage("Exercise repeat updated successfully.");
      setEditingExerciseId(null);
      await fetchStage();
    } catch (err) {
      console.error("Update repeat failed:", err);
      setError(err?.response?.data?.message || "Failed to update repeat count.");
    } finally {
      setUpdatingExerciseId(null);
    }
  };

  // Toggle Exercise Active
  const toggleStageExercise = async (stageExerciseId) => {
    if (!canEdit) return;

    setUpdatingExerciseId(stageExerciseId);
    setError("");
    setMessage("");

    try {
      await API.put(`/school/stage-exercises/${stageExerciseId}/toggle`);
      setMessage("Exercise status updated.");
      await fetchStage();
    } catch (err) {
      console.error("Toggle stage exercise failed:", err);
      setError(err?.response?.data?.message || "Failed to toggle exercise status.");
    } finally {
      setUpdatingExerciseId(null);
    }
  };

  // Exercises search & Attach modal handlers
  const searchExercises = async ({ q, character_type }) => {
    try {
      const params = {
        per_page: 50,
        q: q || undefined,
        character_type: character_type || undefined,
      };

      let res;
      try {
        res = await API.get("/school/exercises", { params });
      } catch (e) {
        res = await API.get("/admin/exercises", { params });
      }

      const payload = res.data?.data ?? res.data;
      const list =
        payload?.exercises?.data && Array.isArray(payload.exercises.data)
          ? payload.exercises.data
          : Array.isArray(payload?.exercises)
          ? payload.exercises
          : [];

      setExerciseRows(list);
    } catch (err) {
      console.error("Fetch exercises failed:", err);
      setAttachError(err?.response?.data?.message || "Failed to load exercises.");
    }
  };

  const openAttachModal = async () => {
    setAttachError("");
    setSelectedExerciseId(null);
    setAttachRepeatCount(1);
    setExerciseQuery("");
    setCharacterType("");
    setExerciseRows([]);
    setAttachOpen(true);
    await searchExercises({ q: "", character_type: "" });
  };

  const closeAttachModal = () => {
    if (attachLoading) return;
    setAttachOpen(false);
    setAttachError("");
  };

  const submitAttachExercise = async () => {
    if (!selectedExerciseId) {
      setAttachError("Please select an exercise to attach.");
      return;
    }

    setAttachLoading(true);
    setAttachError("");
    try {
      await API.post(`/school/stages/${stageId}/exercises`, {
        exercise_id: selectedExerciseId,
        repeat_count: Math.min(3, Math.max(1, Number(attachRepeatCount || 1))),
        is_active: true,
      });

      setMessage("Exercise attached successfully.");
      closeAttachModal();
      await fetchStage();
    } catch (err) {
      console.error("Attach exercise failed:", err);
      setAttachError(err?.response?.data?.message || "Failed to attach exercise.");
    } finally {
      setAttachLoading(false);
    }
  };

  if (!canView) {
    return (
      <SchoolLayout>
        <div className="alert alert-danger mb-0">
          You don’t have permission to view this page.
        </div>
      </SchoolLayout>
    );
  }

  return (
    <SchoolLayout>
      <div className="card">
        {/* Header */}
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Stage Details</h5>
            <small className="text-muted">ID: {stageId}</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <button
              type="button"
              onClick={goBack}
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </button>

            {canEdit && (
              <button
                type="button"
                onClick={openEditModal}
                className="d-flex align-items-center btn btn-primary radius-3 px-20 py-11"
              >
                <Icon icon="lucide:edit" className="me-6" />
                Edit Stage
              </button>
            )}
          </div>
        </div>

        {/* Body */}
        <div className="card-body">
          {message && <div className="alert alert-success">{message}</div>}
          {error && <div className="alert alert-danger">{error}</div>}

          {loading ? (
            <div className="text-center py-40">
              <div className="spinner-border" role="status" />
              <div className="mt-12 text-muted">Loading stage...</div>
            </div>
          ) : !normalized ? (
            <div className="text-center py-40 text-muted">Stage not found.</div>
          ) : (
            <div className="row g-3">
              {/* Left Column: Centered Stage Icon & Info */}
              <div className="col-12 col-md-4 col-lg-3">
                <div className="card border">
                  <div className="card-body text-center d-flex flex-column align-items-center justify-content-center">
                    <div
                      className="d-flex align-items-center justify-content-center mx-auto"
                      style={{
                        width: 100,
                        height: 100,
                        borderRadius: 16,
                        background: "#e5e7eb",
                        border: "1px solid rgba(0,0,0,0.08)",
                      }}
                      title={normalized?.name || "—"}
                    >
                      <Icon icon="mdi:flag" width={48} />
                    </div>

                    <h6 className="mt-3 mb-1 text-center">
                      <Trunc value={normalized?.name ?? "—"} maxWidth={220} />
                    </h6>

                    {normalized?.name_en ? (
                      <div className="text-muted small mb-2 text-center">
                        <Trunc value={normalized.name_en} maxWidth={220} />
                      </div>
                    ) : (
                      <div className="mb-2" />
                    )}

                    {/* Parent Info */}
                    <div className="text-muted small mb-1 text-center">
                      World:{" "}
                      <span className="fw-medium">
                        {normalized?.world?.name ?? "—"}
                      </span>
                    </div>
                    <div className="text-muted small mb-2 text-center">
                      Level:{" "}
                      <span className="fw-medium">
                        {normalized?.level?.name ?? "—"}
                      </span>
                    </div>

                    <div className="d-flex justify-content-center gap-2 flex-wrap">
                      <span
                        className={`badge ${
                          normalized.active ? "bg-success" : "bg-secondary"
                        }`}
                      >
                        {normalized.active ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge ${
                          normalized.unlocked
                            ? "bg-primary"
                            : "bg-light text-dark"
                        }`}
                      >
                        {normalized.unlocked
                          ? "Default Unlock"
                          : "Not Default"}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="card border mt-3">
                  <div className="card-header">
                    <h6 className="mb-0">System Info</h6>
                  </div>
                  <div className="card-body">
                    <MiniRow
                      label="Order Index"
                      value={normalized?.order_index ?? "—"}
                    />
                    <MiniRow
                      label="Exercises"
                      value={normalized.exercises.length}
                    />
                    <MiniRow
                      label="Created At"
                      value={prettyDateTime(normalized?.created_at)}
                    />
                    <MiniRow
                      label="Updated At"
                      value={prettyDateTime(normalized?.updated_at)}
                    />
                  </div>
                </div>
              </div>

              {/* Right Column: Stage Information & Attached Exercises */}
              <div className="col-12 col-md-8 col-lg-9">
                <div className="card border mb-3">
                  <div className="card-header d-flex justify-content-between align-items-center">
                    <h6 className="mb-0">Stage Information</h6>
                    {canEdit && (
                      <button
                        type="button"
                        onClick={openEditModal}
                        className="btn btn-sm btn-outline-primary d-flex align-items-center"
                      >
                        <Icon icon="lucide:edit" className="me-1" />
                        Edit
                      </button>
                    )}
                  </div>
                  <div className="card-body">
                    <div className="row g-3">
                      <Info label="Name (KH)" value={normalized?.name || "—"} />
                      <Info label="Name (EN)" value={normalized?.name_en || "—"} />

                      <Info
                        label="Description (KH)"
                        value={normalized?.description || "—"}
                        colClass="col-12"
                      />
                      <Info
                        label="Description (EN)"
                        value={normalized?.description_en || "—"}
                        colClass="col-12"
                      />
                    </div>
                  </div>
                </div>

                {/* Attached Exercises */}
                <div className="card border">
                  <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                      <h6 className="mb-0">Attached Exercises</h6>
                      <small className="text-muted">
                        {normalized.exercises.length} total
                      </small>
                    </div>

                    {canEdit && (
                      <button
                        type="button"
                        onClick={openAttachModal}
                        className="btn btn-sm btn-primary d-flex align-items-center"
                      >
                        <Icon icon="mdi:plus" className="me-1" />
                        Attach Exercise
                      </button>
                    )}
                  </div>

                  <div className="card-body">
                    {normalized.exercises.length === 0 ? (
                      <div className="text-center text-muted py-24">
                        No exercises attached to this stage.
                      </div>
                    ) : (
                      <div className="table-responsive">
                        <table className="table table-bordered mb-0 align-middle">
                          <thead>
                            <tr>
                              <th style={{ width: 60 }} className="text-center">#</th>
                              <th>Character / Prompt</th>
                              <th>Type</th>
                              <th style={{ width: 130 }} className="text-center">
                                Repeat
                              </th>
                              <th style={{ width: 100 }} className="text-center">
                                Status
                              </th>
                              {canEdit && (
                                <th style={{ width: 120 }} className="text-center">
                                  Actions
                                </th>
                              )}
                            </tr>
                          </thead>
                          <tbody>
                            {normalized.exercises.map((se, idx) => {
                              const ex = se?.exercise ?? se;
                              const exActive = boolish(se?.is_active ?? ex?.is_active);
                              const isEditing = editingExerciseId === se.id;
                              const isBusy = updatingExerciseId === se.id;

                              return (
                                <tr key={se.id || idx}>
                                  <td className="text-center align-middle">{idx + 1}</td>
                                  <td className="align-middle">
                                    <div className="fw-medium">
                                      {ex?.character ? (
                                        <span className="badge bg-light text-dark me-2 border">
                                          {ex.character}
                                        </span>
                                      ) : null}
                                      {ex?.prompt ?? ex?.question ?? "—"}
                                    </div>
                                  </td>
                                  <td className="align-middle">
                                    <span className="text-capitalize">
                                      {ex?.character_type ?? "—"}
                                    </span>
                                  </td>

                                  {/* Repeat column (number or input when editing) */}
                                  <td className="text-center align-middle">
                                    {isEditing ? (
                                      <input
                                        type="number"
                                        min="1"
                                        max="3"
                                        className="form-control form-control-sm text-center mx-auto"
                                        style={{ width: 80 }}
                                        value={editRepeatInput}
                                        onChange={(e) => {
                                          const val = Number(e.target.value);
                                          if (val > 3) setEditRepeatInput(3);
                                          else if (val < 1 && e.target.value !== "") setEditRepeatInput(1);
                                          else setEditRepeatInput(e.target.value);
                                        }}
                                        disabled={isBusy}
                                      />
                                    ) : (
                                      <span className="fw-semibold">{se?.repeat_count ?? 1}</span>
                                    )}
                                  </td>

                                  {/* Status */}
                                  <td className="text-center align-middle">
                                    <span
                                      className={`badge ${
                                        exActive
                                          ? "bg-success"
                                          : "bg-secondary"
                                      }`}
                                    >
                                      {exActive ? "Active" : "Disabled"}
                                    </span>
                                  </td>

                                  {/* Actions */}
                                  {canEdit && (
                                    <td className="text-center align-middle">
                                      {isEditing ? (
                                        <div className="d-flex align-items-center justify-content-center gap-1">
                                          <button
                                            type="button"
                                            title="Save Repeat"
                                            className="w-32-px h-32-px bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                            onClick={() => saveExerciseRepeat(se.id)}
                                            disabled={isBusy}
                                          >
                                            <Icon icon="mdi:check" />
                                          </button>
                                          <button
                                            type="button"
                                            title="Cancel"
                                            className="w-32-px h-32-px bg-secondary-focus text-secondary-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                            onClick={cancelEditExercise}
                                            disabled={isBusy}
                                          >
                                            <Icon icon="radix-icons:cross-2" />
                                          </button>
                                        </div>
                                      ) : (
                                        <div className="d-flex align-items-center justify-content-center gap-1">
                                          <button
                                            type="button"
                                            title="Edit Repeat"
                                            className="w-32-px h-32-px bg-primary-focus text-primary-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                            onClick={() => startEditExercise(se)}
                                            disabled={isBusy}
                                          >
                                            <Icon icon="lucide:edit" />
                                          </button>
                                          <button
                                            type="button"
                                            title={exActive ? "Disable Exercise" : "Enable Exercise"}
                                            className={`w-32-px h-32-px rounded-circle d-inline-flex align-items-center justify-content-center border-0 ${
                                              exActive
                                                ? "bg-warning-focus text-warning-main"
                                                : "bg-info-focus text-info-main"
                                            }`}
                                            onClick={() => toggleStageExercise(se.id)}
                                            disabled={isBusy}
                                          >
                                            <Icon
                                              icon={
                                                exActive
                                                  ? "mdi:toggle-switch"
                                                  : "mdi:toggle-switch-off-outline"
                                              }
                                            />
                                          </button>
                                        </div>
                                      )}
                                    </td>
                                  )}
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Edit Stage Modal */}
      {editOpen && (
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
          onClick={closeEditModal}
          role="dialog"
          aria-modal="true"
        >
          <div
            className="card"
            style={{ width: "min(600px, 96vw)", maxHeight: "92vh", overflow: "hidden" }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="card-header d-flex justify-content-between align-items-center">
              <div>
                <h6 className="mb-0">Edit Stage Details</h6>
                <small className="text-muted">ID: {stageId}</small>
              </div>
              <button
                className="btn btn-light d-flex align-items-center justify-content-center w-32-px h-32-px p-0 border-0 radius-3"
                type="button"
                onClick={closeEditModal}
                disabled={editLoading}
              >
                <Icon icon="radix-icons:cross-2" />
              </button>
            </div>

            <div className="card-body" style={{ overflow: "auto" }}>
              {editError && <div className="alert alert-danger">{editError}</div>}

              <div className="row g-3">
                <div className="col-12 col-md-6">
                  <label className="form-label">Stage Name (KH) *</label>
                  <input
                    className="form-control"
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    placeholder="ឧ. រៀនអក្សរ ក"
                    disabled={editLoading}
                  />
                </div>

                <div className="col-12 col-md-6">
                  <label className="form-label">Stage Name (EN)</label>
                  <input
                    className="form-control"
                    value={editNameEn}
                    onChange={(e) => setEditNameEn(e.target.value)}
                    placeholder="e.g. Learn letter KA"
                    disabled={editLoading}
                  />
                </div>

                <div className="col-12 col-md-6">
                  <label className="form-label">Description (KH)</label>
                  <input
                    className="form-control"
                    value={editDescription}
                    onChange={(e) => setEditDescription(e.target.value)}
                    placeholder="Optional (KH)"
                    disabled={editLoading}
                  />
                </div>

                <div className="col-12 col-md-6">
                  <label className="form-label">Description (EN)</label>
                  <input
                    className="form-control"
                    value={editDescriptionEn}
                    onChange={(e) => setEditDescriptionEn(e.target.value)}
                    placeholder="Optional (EN)"
                    disabled={editLoading}
                  />
                </div>

                <div className="col-12">
                  <div className="form-check">
                    <input
                      className="form-check-input"
                      type="checkbox"
                      id="editStageActiveCheck"
                      checked={!!editActive}
                      onChange={(e) => setEditActive(e.target.checked)}
                      disabled={editLoading}
                    />
                    <label className="form-check-label" htmlFor="editStageActiveCheck">
                      Active
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <div className="card-footer d-flex justify-content-end gap-2">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={closeEditModal}
                disabled={editLoading}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={submitEditStage}
                disabled={editLoading}
              >
                {editLoading ? "Saving..." : "Save Changes"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Attach Exercise Modal */}
      {attachOpen && (
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
          onClick={closeAttachModal}
          role="dialog"
          aria-modal="true"
        >
          <div
            className="card"
            style={{ width: "min(700px, 96vw)", maxHeight: "92vh", overflow: "hidden" }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="card-header d-flex justify-content-between align-items-center">
              <div>
                <h6 className="mb-0">Attach Exercise to Stage</h6>
              </div>
              <button
                className="btn btn-light d-flex align-items-center justify-content-center w-32-px h-32-px p-0 border-0 radius-3"
                type="button"
                onClick={closeAttachModal}
                disabled={attachLoading}
              >
                <Icon icon="radix-icons:cross-2" />
              </button>
            </div>

            <div className="card-body" style={{ overflow: "auto" }}>
              {attachError && <div className="alert alert-danger">{attachError}</div>}

              <div className="row g-2 mb-3 align-items-end">
                <div className="col-12 col-md-7">
                  <label className="form-label">Search Exercise</label>
                  <input
                    className="form-control"
                    placeholder="Search character or prompt..."
                    value={exerciseQuery}
                    onChange={(e) => {
                      setExerciseQuery(e.target.value);
                      searchExercises({ q: e.target.value, character_type: characterType });
                    }}
                  />
                </div>
                <div className="col-12 col-md-5">
                  <label className="form-label">Character Type</label>
                  <select
                    className="form-control"
                    value={characterType}
                    onChange={(e) => {
                      setCharacterType(e.target.value);
                      searchExercises({ q: exerciseQuery, character_type: e.target.value });
                    }}
                  >
                    <option value="">All Types</option>
                    <option value="consonants">Consonants</option>
                    <option value="vowels">Vowels</option>
                    <option value="subscript">Subscript</option>
                    <option value="numbers">Numbers</option>
                  </select>
                </div>
              </div>

              {/* Exercise Selector */}
              <label className="form-label">Select Exercise *</label>
              <div
                className="border rounded p-2 mb-3"
                style={{ maxHeight: 200, overflowY: "auto" }}
              >
                {exerciseRows.length === 0 ? (
                  <div className="text-muted text-center py-2">No exercises found.</div>
                ) : (
                  exerciseRows.map((ex) => (
                    <div
                      key={ex.id}
                      onClick={() => setSelectedExerciseId(ex.id)}
                      className={`p-2 border-bottom d-flex align-items-center justify-content-between ${
                        selectedExerciseId === ex.id ? "bg-primary-focus" : ""
                      }`}
                      style={{ cursor: "pointer" }}
                    >
                      <div>
                        {ex.character && (
                          <span className="badge bg-light text-dark me-2 border">
                            {ex.character}
                          </span>
                        )}
                        <span className="fw-medium">{ex.prompt || ex.question || `Exercise #${ex.id}`}</span>
                      </div>
                      <span className="badge bg-secondary text-capitalize">
                        {ex.character_type || "exercise"}
                      </span>
                    </div>
                  ))
                )}
              </div>

              <div className="row g-3">
                <div className="col-12 col-md-6">
                  <label className="form-label">Repeat Count * (Max 3)</label>
                  <input
                    type="number"
                    min="1"
                    max="3"
                    className="form-control"
                    value={attachRepeatCount}
                    onChange={(e) => {
                      const val = Number(e.target.value);
                      if (val > 3) setAttachRepeatCount(3);
                      else if (val < 1 && e.target.value !== "") setAttachRepeatCount(1);
                      else setAttachRepeatCount(e.target.value);
                    }}
                  />
                </div>
              </div>
            </div>

            <div className="card-footer d-flex justify-content-end gap-2">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={closeAttachModal}
                disabled={attachLoading}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={submitAttachExercise}
                disabled={attachLoading || !selectedExerciseId}
              >
                {attachLoading ? "Attaching..." : "Attach Exercise"}
              </button>
            </div>
          </div>
        </div>
      )}
    </SchoolLayout>
  );
};

const Info = ({ label, value, colClass = "col-12 col-md-6" }) => (
  <div className={colClass}>
    <div className="p-12 border radius-8 h-100">
      <div className="text-muted small mb-6">{label}</div>
      <div className="fw-medium">{value ?? "—"}</div>
    </div>
  </div>
);

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between gap-1 py-6 border-bottom">
      <div className="text-muted small">{label}</div>
      <div className="fw-medium">{v}</div>
    </div>
  );
};

export default SchoolStageView;
