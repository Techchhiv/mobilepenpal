import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Trunc = ({ value, maxWidth = 360 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const normalizeBool = (v) => v === true || String(v ?? "0") === "1";

const LevelView = () => {
  const { id } = useParams();
  const levelId = id;
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("levels.view") || hasPermission("levels.update");
  const canEdit = hasPermission("levels.update");
  const canToggle = hasPermission("levels.enable_disable");

  const canCreateStage =
    hasPermission("stages.create") || hasPermission("levels.update");
  const canAttachExercise =
    hasPermission("stage_exercises.create") ||
    hasPermission("stages.update") ||
    hasPermission("levels.update");

  const from = location.state?.from || "/admin/levels";

  const [loading, setLoading] = useState(true);
  const [level, setLevel] = useState(null);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createError, setCreateError] = useState("");

  const [stName, setStName] = useState("");
  const [stDescription, setStDescription] = useState("");
  const [stNameEn, setStNameEn] = useState("");
  const [stDescriptionEn, setStDescriptionEn] = useState("");
  const [stActive, setStActive] = useState(true);

  const [exLoading, setExLoading] = useState(false);
  const [exError, setExError] = useState("");
  const [exerciseQuery, setExerciseQuery] = useState("");
  const [characterType, setCharacterType] = useState("");
  const [exerciseRows, setExerciseRows] = useState([]);

  const [selectedExercises, setSelectedExercises] = useState([]);

  const moveSelectedUp = (exerciseId) => moveSelected(exerciseId, -1);
  const moveSelectedDown = (exerciseId) => moveSelected(exerciseId, 1);

  const MAX_REPEAT_TOTAL = 20;

  const cap1 = (s) => {
    const v = String(s ?? "").trim();
    return v ? v.charAt(0).toUpperCase() + v.slice(1) : "";
  };

  const mathOpSymbol = (op) => {
    switch (String(op ?? "").toLowerCase()) {
      case "add":
        return "+";
      case "sub":
        return "−";
      case "mul":
        return "×";
      case "div":
        return "÷";
      default:
        return "?";
    }
  };

  const mathOpLabel = (op) => {
    switch (String(op ?? "").toLowerCase()) {
      case "add":
        return "Addition";
      case "sub":
        return "Subtraction";
      case "mul":
        return "Multiplication";
      case "div":
        return "Division";
      default:
        return cap1(op);
    }
  };


  const fetchLevel = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/levels/${levelId}`);
      const payload = res.data?.data ?? res.data;
      const lv = payload?.level ?? payload ?? null;
      setLevel(lv);
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
  }, [levelId, canView]);

  const active = useMemo(() => normalizeBool(level?.is_active), [level]);
  const stages = Array.isArray(level?.stages) ? level.stages : [];

  const prettyDateTime = (d) => {
    if (!d) return "—";
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return String(d);
    return dt.toLocaleString();
  };

  const toggleLevel = async () => {
    if (!canToggle) return;
    setError("");
    setMessage("");
    try {
      await API.put(`/admin/levels/${levelId}/toggle`);
      setMessage("Level status updated.");
      await fetchLevel();
    } catch (err) {
      console.error("Toggle failed:", err);
      setError(err?.response?.data?.message || "Toggle failed.");
    }
  };

  const totalRepeat = useMemo(() => {
    return selectedExercises.reduce(
      (sum, x) => sum + Math.max(1, Number(x.repeat_count || 1)),
      0
    );
  }, [selectedExercises]);

  const remainingRepeat = MAX_REPEAT_TOTAL - totalRepeat;

  const getMaxRepeatFor = (exerciseId) => {
    const used = totalRepeat;
    const current = selectedExercises.find((x) => x.id === exerciseId);
    const currentRepeat = Math.max(1, Number(current?.repeat_count || 1));
    return Math.max(1, MAX_REPEAT_TOTAL - (used - currentRepeat));
  };

  const moveSelected = (exerciseId, dir) => {
    setSelectedExercises((prev) => {
      const i = prev.findIndex((x) => x.id === exerciseId);
      if (i === -1) return prev;

      const j = i + dir;
      if (j < 0 || j >= prev.length) return prev;

      const next = prev.slice();
      [next[i], next[j]] = [next[j], next[i]];
      return next;
    });
  };

  const goBack = () => {
    if (window.history.length > 1) navigate(-1);
    else navigate(from);
  };

  const openCreateStage = async () => {
    setCreateError("");
    setExError("");
    setMessage("");
    setError("");

    setStName("");
    setStNameEn("");
    setStDescription("");
    setStDescriptionEn("");
    setStActive(true);

    setSelectedExercises([]);

    setExerciseQuery("");
    setCharacterType("");
    setExerciseRows([]);

    setCreateOpen(true);

    await searchExercises({ q: "", character_type: "" });
  };

  const closeCreateStage = () => {
    if (createLoading) return;
    setCreateOpen(false);
    setCreateError("");
    setExError("");
  };

  const searchExercises = async ({ q, character_type }) => {
    setExLoading(true);
    setExError("");
    try {
      const res = await API.get("/admin/exercises", {
        params: {
          per_page: 50,
          q: q || undefined,
          character_type: character_type || undefined,
        },
      });

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
      setExError(err?.response?.data?.message || "Failed to load exercises.");
    } finally {
      setExLoading(false);
    }
  };

  const isSelected = (exerciseId) =>
    selectedExercises.some((x) => x.id === exerciseId);

  const toggleSelectExercise = (ex) => {
    if (!ex?.id) return;

    setSelectedExercises((prev) => {
      if (prev.some((x) => x.id === ex.id)) {
        return prev.filter((x) => x.id !== ex.id);
      }

      const used = prev.reduce(
        (sum, x) => sum + Math.max(1, Number(x.repeat_count || 1)),
        0
      );
      const remaining = MAX_REPEAT_TOTAL - used;

      if (remaining <= 0) {
        return prev;
      }

      const defaultRepeatForNew = prev.length === 0 ? MAX_REPEAT_TOTAL : 1;
      const repeat_count = Math.min(defaultRepeatForNew, remaining);

      return [
        ...prev,
        {
          id: ex.id,
          character: ex.character ?? "—",
          character_type: ex.character_type ?? "—",
          difficulty: ex.difficulty ?? null,
          math_op: ex.math_op ?? null,
          prompt: ex.prompt ?? ex.question ?? "",
          repeat_count,
        },
      ];

    });
  };


  const changeRepeatForSelected = (exerciseId, repeat) => {
    setSelectedExercises((prev) => {
      const used = prev.reduce(
        (sum, x) => sum + Math.max(1, Number(x.repeat_count || 1)),
        0
      );

      return prev.map((x) => {
        if (x.id !== exerciseId) return x;

        const current = Math.max(1, Number(x.repeat_count || 1));
        const maxAllowed = Math.max(1, MAX_REPEAT_TOTAL - (used - current));

        const next = Math.max(1, Math.min(Number(repeat || 1), maxAllowed));
        return { ...x, repeat_count: next };
      });
    });
  };


  const removeSelected = (exerciseId) => {
    setSelectedExercises((prev) => prev.filter((x) => x.id !== exerciseId));
  };

  const createStageAndAttach = async () => {
    if (!canCreateStage) return;

    setCreateError("");
    setMessage("");
    setError("");

    const name = (stName || "").trim();
    const name_en = (stNameEn || "").trim();

    if (!name) {
      setCreateError("Stage name (KH) is required.");
      return;
    }

    setCreateLoading(true);
    try {
      const stageRes = await API.post(`/admin/levels/${levelId}/stages`, {
        name,
        name_en: name_en || null,

        description: (stDescription || "").trim() || null,
        description_en: (stDescriptionEn || "").trim() || null,

        is_active: !!stActive,
      });


      const stagePayload = stageRes.data?.data ?? stageRes.data;
      const createdStage =
        stagePayload?.stage ?? stagePayload?.data?.stage ?? stagePayload ?? null;

      const newStageId = createdStage?.id;
      if (!newStageId) {
        throw new Error("Stage created but stage id not found in response.");
      }

      if (selectedExercises.length > 0 && canAttachExercise) {
        for (const ex of selectedExercises) {
          await API.post(`/admin/stages/${newStageId}/exercises`, {
            exercise_id: ex.id,
            repeat_count: Math.max(1, Number(ex.repeat_count || 1)),
            is_active: true,
          });
        }
      }

      setMessage(
        selectedExercises.length > 0
          ? "Stage created and exercises attached."
          : "Stage created."
      );

      closeCreateStage();
      await fetchLevel();
    } catch (err) {
      console.error("Create stage failed:", err);
      setCreateError(
        err?.response?.data?.message ||
        err?.message ||
        "Failed to create stage."
      );
    } finally {
      setCreateLoading(false);
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

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Level Details</h5>
            <small className="text-muted">ID: {levelId}</small>
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
              <Link
                to={`/admin/levels/${levelId}/edit`}
                state={{ from }}
                className="d-flex align-items-center btn btn-primary radius-3 px-20 py-11"
              >
                <Icon icon="lucide:edit" className="me-6" />
                Edit
              </Link>
            )}

            {canToggle && (
              <button
                type="button"
                onClick={toggleLevel}
                className={`btn radius-3 px-20 py-11 d-flex align-items-center ${active ? "btn-warning" : "btn-primary"
                  }`}
                title="Toggle Active"
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
              <div className="mt-12 text-muted">Loading level...</div>
            </div>
          ) : !level ? (
            <div className="text-center py-40 text-muted">Level not found.</div>
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
                      title={level?.name || "—"}
                    >
                      <Icon icon="mdi:stairs" width={54} />
                    </div>

                    <h6 className="mt-3 mb-1">
                      <Trunc value={level?.name ?? "—"} maxWidth={220} />
                    </h6>

                    {level?.name_en ? (
                      <div className="text-muted small mb-2">
                        <Trunc value={level.name_en} maxWidth={220} />
                      </div>
                    ) : (
                      <div className="mb-2" />
                    )}

                    <div className="text-muted small mb-2">
                      World:{" "}
                      <span className="fw-medium">
                        {level?.world?.name ?? level?.world_name ?? "—"}
                      </span>
                    </div>

                    <div className="d-flex justify-content-center gap-8 flex-wrap">
                      <span
                        className={`badge ${active ? "bg-success" : "bg-secondary"
                          }`}
                      >
                        {active ? "Active" : "Disabled"}
                      </span>

                      <span
                        className={`badge ${normalizeBool(level?.is_unlocked_by_default)
                          ? "bg-primary"
                          : "bg-light text-dark"
                          }`}
                      >
                        {normalizeBool(level?.is_unlocked_by_default)
                          ? "Default Unlock"
                          : "Not Default"}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="card border mt-3">
                  <div className="card-header">
                    <h6 className="mb-0">System</h6>
                  </div>
                  <div className="card-body">
                    <MiniRow label="Order Index" value={level?.order_index ?? "—"} />
                    <MiniRow
                      label="Stages"
                      value={
                        level?.active_stages_count !== undefined &&
                          level?.stages_count !== undefined
                          ? `${level.active_stages_count}/${level.stages_count}`
                          : "—"
                      }
                    />
                    <MiniRow label="Created At" value={prettyDateTime(level?.created_at)} />
                    <MiniRow label="Updated At" value={prettyDateTime(level?.updated_at)} />
                  </div>
                </div>
              </div>

              {/* Right */}
              <div className="col-12 col-md-8 col-lg-9">
                <div className="card border mb-0">
                  <div className="card-header">
                    <h6 className="mb-0">Level Information</h6>
                  </div>

                  <div className="card-body">
                    <div className="row g-3">
                      <Info label="Name (KH)" value={level?.name} />
                      <Info label="Name (EN)" value={level?.name_en || "—"} />

                      <Info label="World" value={level?.world?.name ?? "—"} colClass="col-12" />

                      <Info
                        label="Description (KH)"
                        value={level?.description || "—"}
                        colClass="col-12"
                      />

                      <Info
                        label="Description (EN)"
                        value={level?.description_en || "—"}
                        colClass="col-12"
                      />

                      {level?.background_image ? (
                        <div className="col-12">
                          <div className="border radius-8 p-12">
                            <div className="text-muted small mb-8">Background Preview</div>
                            <img
                              src={level.background_image}
                              alt="Background"
                              style={{
                                width: "100%",
                                maxHeight: 260,
                                objectFit: "cover",
                                borderRadius: 8,
                              }}
                              onError={(e) => {
                                e.currentTarget.style.display = "none";
                              }}
                            />
                          </div>
                        </div>
                      ) : null}
                    </div>

                  </div>
                </div>

                {/* ✅ Stages table */}
                <div className="card border mt-3">
                  <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                      <h6 className="mb-0">Stages</h6>
                      <small className="text-muted">{stages.length} total</small>
                    </div>

                    {canCreateStage && (
                      <button
                        type="button"
                        className="btn btn-primary d-flex align-items-center"
                        onClick={openCreateStage}
                      >
                        <Icon icon="mdi:plus" className="me-6" />
                        Insert Stage
                      </button>
                    )}
                  </div>

                  <div className="card-body">
                    {stages.length === 0 ? (
                      <div className="text-center text-muted py-24">
                        No stages found.
                      </div>
                    ) : (
                      <div className="table-responsive">
                        <table className="table bordered-table mb-0">
                          <thead>
                            <tr>
                              <th style={{ width: 70 }}>#</th>
                              <th style={{ width: 90 }}>Order</th>
                              <th>Name</th>
                              <th>Description</th>
                              <th style={{ width: 140 }} className="text-center">
                                Status
                              </th>
                              <th style={{ width: 80 }} className="text-center">
                                Action
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            {stages
                              .slice()
                              .sort(
                                (a, b) =>
                                  (a?.order_index ?? 0) - (b?.order_index ?? 0)
                              )
                              .map((s, idx) => {
                                const sActive =
                                  s?.is_active === true ||
                                  String(s?.is_active ?? "0") === "1";

                                return (
                                  <tr
                                    key={s.id}
                                    className={!sActive ? "table-light" : ""}
                                  >
                                    <td>{idx + 1}</td>
                                    <td>{s?.order_index ?? "—"}</td>
                                    <td>
                                      <Trunc value={s?.name ?? "—"} maxWidth={340} />
                                    </td>
                                    <td>
                                      <Trunc
                                        value={s?.description ?? "—"}
                                        maxWidth={380}
                                      />
                                    </td>

                                    <td className="text-center align-middle">
                                      <span
                                        className={`px-24 py-4 rounded-pill fw-medium text-sm ${sActive
                                          ? "bg-success-focus text-success-main"
                                          : "bg-warning-focus text-warning-main"
                                          }`}
                                      >
                                        {sActive ? "Active" : "Disabled"}
                                      </span>
                                    </td>

                                    <td className="text-center align-middle">
                                      <Link
                                        to={`/admin/stages/${s.id}`}
                                        state={{ from: `/admin/levels/${levelId}` }}
                                        title="View Stage"
                                        className="w-32-px h-32-px bg-primary-focus text-primary-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                        style={{ textDecoration: "none" }}
                                      >
                                        <Icon icon="mdi:eye-outline" />
                                      </Link>
                                    </td>
                                  </tr>
                                );
                              })}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>
                </div>

                {/* ✅ Create Stage Modal */}
                {createOpen && (
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
                    onClick={closeCreateStage}
                    role="dialog"
                    aria-modal="true"
                  >
                    <div
                      className="card"
                      style={{
                        width: "min(1100px, 96vw)",
                        maxHeight: "92vh",
                        overflow: "hidden",
                      }}
                      onClick={(e) => e.stopPropagation()}
                    >
                      <div className="card-header d-flex justify-content-between align-items-center">
                        <div>
                          <h6 className="mb-0">Insert Stage</h6>
                          <small className="text-muted">
                            Create a stage and optionally attach exercises
                          </small>
                        </div>

                        <button
                          className="btn btn-light d-flex align-items-center justify-content-center w-32-px h-32-px p-0 border-0 radius-3"
                          type="button"
                          onClick={closeCreateStage}
                          title="Close"
                          disabled={createLoading}
                        >
                          <Icon icon="radix-icons:cross-2" />
                        </button>
                      </div>

                      <div className="card-body" style={{ overflow: "auto" }}>
                        {createError && (
                          <div className="alert alert-danger">{createError}</div>
                        )}

                        {/* Stage Fields */}
                        <div className="row g-3 mb-3">
                          <div className="col-12 col-md-5">
                            <label className="form-label">Stage Name (KH) *</label>
                            <input
                              className="form-control"
                              value={stName}
                              onChange={(e) => setStName(e.target.value)}
                              placeholder="ឧ. រៀនអក្សរ ក"
                            />
                          </div>

                          <div className="col-12 col-md-5">
                            <label className="form-label">Stage Name (EN)</label>
                            <input
                              className="form-control"
                              value={stNameEn}
                              onChange={(e) => setStNameEn(e.target.value)}
                              placeholder="e.g. Learn letter KA"
                            />
                          </div>


                          <div className="col-12 col-md-2 d-flex align-items-end">
                            <div className="form-check d-flex align-items-center">
                              <input
                                className="form-check-input"
                                type="checkbox"
                                id="stActive"
                                checked={!!stActive}
                                onChange={(e) => setStActive(e.target.checked)}
                              />
                              <label className="form-check-label" htmlFor="stActive">
                                Active
                              </label>
                            </div>
                          </div>

                          <div className="col-12 col-md-6">
                            <label className="form-label">Description (KH)</label>
                            <input
                              className="form-control"
                              value={stDescription}
                              onChange={(e) => setStDescription(e.target.value)}
                              placeholder="Optional (KH)"
                            />
                          </div>

                          <div className="col-12 col-md-6">
                            <label className="form-label">Description (EN)</label>
                            <input
                              className="form-control"
                              value={stDescriptionEn}
                              onChange={(e) => setStDescriptionEn(e.target.value)}
                              placeholder="Optional (EN)"
                            />
                          </div>

                        </div>

                        <hr className="my-3" />

                        <div className="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-2">
                          <div>
                            <h6 className="mb-0">Attach Exercises (optional)</h6>
                          </div>

                          <div className="d-flex align-items-center gap-2">
                            <span className="badge bg-primary">
                              Slots: {totalRepeat}/{MAX_REPEAT_TOTAL}
                            </span>
                          </div>
                        </div>

                        <div className="row g-2 align-items-end">
                          <div className="col-12 col-md-6">
                            <label className="form-label">Search</label>
                            <input
                              className="form-control"
                              placeholder="Search prompt / character..."
                              value={exerciseQuery}
                              onChange={(e) => setExerciseQuery(e.target.value)}
                              disabled={createLoading}
                            />
                          </div>

                          <div className="col-12 col-md-4">
                            <label className="form-label">Character Type</label>
                            <select
                              className="form-control"
                              value={characterType}
                              onChange={(e) => setCharacterType(e.target.value)}
                              disabled={createLoading}
                            >
                              <option value="">All</option>
                              <option value="digits">Digits</option>
                              <option value="consonants">Consonants</option>
                              <option value="independent_vowels">Independent Vowels</option>
                              <option value="dependent_vowels">Dependent Vowels</option>
                              <option value="math">Math</option>
                            </select>
                          </div>

                          <div className="col-12 col-md-2">
                            <button
                              type="button"
                              className="btn btn-primary w-100"
                              onClick={() =>
                                searchExercises({
                                  q: exerciseQuery,
                                  character_type: characterType,
                                })
                              }
                              disabled={exLoading || createLoading}
                            >
                              {exLoading ? "..." : "Search"}
                            </button>
                          </div>
                        </div>

                        {selectedExercises.length > 0 && (
                          <div className="mt-3 border radius-8 p-12">
                            <div className="d-flex justify-content-between align-items-center mb-2">
                              <div className="fw-semibold">
                                Selected: {selectedExercises.length}
                              </div>
                              <div className="text-muted small">
                                Maximum of all repeats is 3
                              </div>
                            </div>

                            <div className="table-responsive">
                              <table className="table bordered-table mb-0">
                                <thead>
                                  <tr>
                                    <th style={{ width: 70 }} className="text-center">Order</th>
                                    {/* <th style={{ width: 100 }}>ID</th> */}
                                    <th style={{ width: 200 }}>Character</th>
                                    <th style={{ width: 160 }} className="text-center">Repeat</th>
                                    <th style={{ width: 120 }} className="text-center">Move</th>
                                    <th style={{ width: 90 }} className="text-center">Remove</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {selectedExercises.map((x, idx) => (
                                    <tr key={x.id}>
                                      <td className="text-center">{idx + 1}</td>
                                      {/* <td>{x.id}</td> */}
                                      <td>
                                        {x.character_type === "math" ? (
                                          <>
                                            <div className="fw-semibold">
                                              {mathOpSymbol(x.math_op)} ({cap1(x.difficulty)})
                                            </div>
                                            <div className="text-muted small">{mathOpLabel(x.math_op)}</div>
                                          </>
                                        ) : (
                                          <>
                                            <div className="fw-semibold">{x.character}</div>
                                            <div className="text-muted small">
                                              {x.character_type}
                                              {x.difficulty ? ` • ${cap1(x.difficulty)}` : ""}
                                              {x.math_op ? ` • ${mathOpLabel(x.math_op)}` : ""}
                                            </div>
                                          </>
                                        )}
                                      </td>

                                      <td className="text-center">
                                        <input
                                          type="number"
                                          min={1}
                                          className="form-control"
                                          style={{ width: 110, margin: "0 auto" }}
                                          value={x.repeat_count}
                                          onChange={(e) =>
                                            changeRepeatForSelected(x.id, e.target.value)
                                          }
                                          disabled={createLoading}
                                        />
                                      </td>
                                      <td className="text-center">
                                        <div className="d-inline-flex gap-2">
                                          <button
                                            type="button"
                                            className="btn btn-light d-flex align-items-center"
                                            style={{ padding: "4px" }}
                                            onClick={() => moveSelectedUp(x.id)}
                                            disabled={createLoading || idx === 0}
                                            title="Move up"
                                          >
                                            <Icon icon="mdi:chevron-up" />
                                          </button>

                                          <button
                                            type="button"
                                            className="btn btn-light d-flex align-items-center"
                                            style={{ padding: "4px" }}
                                            onClick={() => moveSelectedDown(x.id)}
                                            disabled={createLoading || idx === selectedExercises.length - 1}
                                            title="Move down"
                                          >
                                            <Icon icon="mdi:chevron-down" />
                                          </button>
                                        </div>
                                      </td>

                                      <td className="text-center">
                                        <button
                                          type="button"
                                          className="w-32-px h-32-px bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                          onClick={() => removeSelected(x.id)}
                                          disabled={createLoading}
                                          title="Remove"
                                        >
                                          <Icon icon="mdi:trash-can-outline" />
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        )}

                        <div className="mt-3">
                          {exLoading ? (
                            <div className="text-center py-24 text-muted">
                              <div className="spinner-border" role="status" />
                              <div className="mt-10">Loading exercises...</div>
                            </div>
                          ) : exerciseRows.length === 0 ? (
                            <div className="text-center text-muted py-24">
                              No exercises found.
                            </div>
                          ) : (
                            <div className="table-responsive">
                              <table className="table bordered-table mb-0">
                                <thead>
                                  <tr>
                                    <th style={{ width: 90 }}>ID</th>
                                    <th style={{ width: 190 }}>Character</th>
                                    {/* <th>Prompt / Question</th> */}
                                    <th style={{ width: 120 }} className="text-center">
                                      Select
                                    </th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {exerciseRows.map((ex) => {
                                    const selected = isSelected(ex.id);

                                    const blocked = !selected && remainingRepeat <= 0;

                                    const tooltipText = !canAttachExercise
                                      ? "No permission to attach exercises"
                                      : blocked
                                        ? "Exercise maximum reached"
                                        : selected
                                          ? "Unselect"
                                          : "Select";

                                    return (
                                      <tr key={ex.id} className={selected ? "table-success" : ""}>
                                        <td>{ex.id}</td>
                                        <td>
                                          {ex.character_type === "math" ? (
                                            <>
                                              <div className="fw-semibold">
                                                {mathOpSymbol(ex.math_op)} ({cap1(ex.difficulty)})
                                              </div>
                                              <div className="text-muted small">{mathOpLabel(ex.math_op)}</div>
                                            </>
                                          ) : (
                                            <>
                                              <div className="fw-semibold">{ex.character ?? "—"}</div>
                                              <div className="text-muted small">{ex.character_type ?? "—"}</div>
                                            </>
                                          )}

                                        </td>
                                        <td className="text-center">
                                          <button
                                            type="button"
                                            onClick={() => {
                                              if (!canAttachExercise || createLoading) return;
                                              if (blocked) return;
                                              toggleSelectExercise(ex);
                                            }}
                                            disabled={!canAttachExercise || createLoading}
                                            title={tooltipText}
                                            style={{
                                              cursor: blocked ? "not-allowed" : "pointer",
                                              opacity: blocked ? 0.55 : 1,
                                            }}
                                            className={`w-32-px h-32-px rounded-circle d-inline-flex align-items-center justify-content-center border-0 ${blocked
                                              ? "bg-secondary text-white"
                                              : selected
                                                ? "bg-danger-focus text-danger-main"
                                                : "bg-success-focus text-success-main"
                                              }`}
                                          >
                                            <Icon icon={blocked ? "mdi:lock" : selected ? "mdi:minus" : "mdi:plus"} />
                                          </button>
                                        </td>
                                      </tr>
                                    );
                                  })}
                                </tbody>
                              </table>

                              {!canAttachExercise && (
                                <div className="alert alert-warning mt-3 mb-0">
                                  You don’t have permission to attach exercises. You can still create a stage.
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="card-footer d-flex justify-content-between align-items-center">
                        <div className="text-muted small">
                          Creating stage in Level ID: <span className="fw-semibold">{levelId}</span>
                        </div>

                        <div className="d-flex gap-2">
                          <button
                            type="button"
                            className="btn btn-secondary"
                            onClick={closeCreateStage}
                            disabled={createLoading}
                          >
                            Cancel
                          </button>
                          <button
                            type="button"
                            className="btn btn-primary"
                            onClick={createStageAndAttach}
                            disabled={createLoading}
                          >
                            {createLoading ? "Saving..." : "Create Stage"}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </MasterLayout>
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

export default LevelView;
