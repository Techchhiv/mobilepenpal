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

const prettyDateTime = (d) => {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleString();
};

const asArray = (v) => (Array.isArray(v) ? v : []);
const safeString = (v) => (v === null || v === undefined || v === "" ? "—" : String(v));

const ExerciseView = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("exercises.view") || hasPermission("exercises.update");
  const canEdit = hasPermission("exercises.update");

  const from = location.state?.from || "/admin/exercises";

  const [loading, setLoading] = useState(true);
  const [exercise, setExercise] = useState(null);
  const [error, setError] = useState("");

  const fetchExercise = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await API.get(`/admin/exercises/${id}`);
      const payload = res.data?.data ?? res.data;

      // common patterns: { data: { exercise: {...} } } OR { exercise: {...} }
      const ex = payload?.exercise ?? payload ?? null;
      setExercise(ex);
    } catch (err) {
      console.error("Fetch exercise failed:", err);
      setError(err?.response?.data?.message || "Failed to load exercise.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!canView) return;
    fetchExercise();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, canView]);

  const options = useMemo(() => {
    // options may be array (recommended) or json-string (older)
    const raw = exercise?.options;
    if (Array.isArray(raw)) return raw;
    if (typeof raw === "string") {
      try {
        const parsed = JSON.parse(raw);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    }
    return [];
  }, [exercise]);

  const usageRows = useMemo(() => {
    const raw = exercise?.stage_exercises ?? exercise?.stageExercises ?? [];
    return asArray(raw);
  }, [exercise]);

  const headerTitle = useMemo(() => {
    const ct = exercise?.character_type ? `(${exercise.character_type})` : "";
    const ch = exercise?.character ? `"${exercise.character}"` : "";
    return `Exercise ${ct} ${ch}`.trim() || "Exercise";
  }, [exercise]);

  const goBack = () => {
    if (window.history.length > 1) navigate(-1);
    else navigate(from);
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
            <h5 className="mb-0">Exercise Details</h5>
            <small className="text-muted">ID: {id}</small>
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
                to={`/admin/exercises/${id}/edit`}
                state={{ from }}
                className="d-flex align-items-center btn btn-primary radius-3 px-20 py-11"
              >
                <Icon icon="lucide:edit" className="me-6" />
                Edit
              </Link>
            )}
          </div>
        </div>

        <div className="card-body">
          {error && <div className="alert alert-danger">{error}</div>}

          {loading ? (
            <div className="text-center py-40">
              <div className="spinner-border" role="status" />
              <div className="mt-12 text-muted">Loading exercise...</div>
            </div>
          ) : !exercise ? (
            <div className="text-center py-40 text-muted">Exercise not found.</div>
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
                      title={headerTitle}
                    >
                      <Icon icon="mdi:format-letter-case" width={54} />
                    </div>

                    <h6 className="mt-3 mb-2">
                      <Trunc value={headerTitle} maxWidth={220} />
                    </h6>

                    <div className="d-flex justify-content-center gap-8 flex-wrap">
                      <span className="badge bg-light text-dark">
                        Type: {safeString(exercise?.character_type)}
                      </span>
                      <span className="badge bg-light text-dark">
                        Char: {safeString(exercise?.character)}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="card border mt-3">
                  <div className="card-header">
                    <h6 className="mb-0">System</h6>
                  </div>
                  <div className="card-body">
                    <MiniRow label="Exercise ID" value={exercise?.id} />
                    <MiniRow label="Created At" value={prettyDateTime(exercise?.created_at)} />
                    <MiniRow label="Updated At" value={prettyDateTime(exercise?.updated_at)} />
                  </div>
                </div>
              </div>

              {/* Right */}
              <div className="col-12 col-md-8 col-lg-9">
                <div className="card border mb-0">
                  <div className="card-header">
                    <h6 className="mb-0">Exercise Information</h6>
                  </div>

                  <div className="card-body">
                    <div className="row g-3">
                      <Info label="Prompt" value={exercise?.prompt || "—"} colClass="col-12" />
                      <Info label="Question" value={exercise?.question || "—"} colClass="col-12" />
                      <Info label="Instruction" value={exercise?.instruction || "—"} colClass="col-12" />
                      <Info label="Hint" value={exercise?.hint || "—"} colClass="col-12" />
                      <Info label="Example" value={exercise?.example || "—"} colClass="col-12" />

                      <Info label="Correct Answer" value={exercise?.correct_answer || "—"} />

                      <Info label="Options (JSON)" value={options.length ? `${options.length} option(s)` : "—"} />

                      {options.length > 0 && (
                        <div className="col-12">
                          <div className="p-12 border radius-8">
                            <div className="text-muted small mb-6">Options</div>
                            <ul className="mb-0 ps-18">
                              {options.map((op, idx) => (
                                <li key={idx}>
                                  <span className="fw-medium">{safeString(op)}</span>
                                </li>
                              ))}
                            </ul>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Usage table */}
                <div className="card border mt-3">
                  <div className="card-header d-flex justify-content-between align-items-center">
                    <h6 className="mb-0">Used In Stages</h6>
                    <small className="text-muted">{usageRows.length} record(s)</small>
                  </div>

                  <div className="card-body">
                    {usageRows.length === 0 ? (
                      <div className="text-center text-muted py-24">No data</div>
                    ) : (

                      <div className="table-responsive">
                        <table className="table bordered-table mb-0">
                          <thead>
                            <tr>
                              <th style={{ width: 70 }}>#</th>
                              <th>World</th>
                              <th>Level</th>
                              <th>Stage</th>
                              <th style={{ width: 90 }} className="text-center">
                                Order
                              </th>
                              <th style={{ width: 110 }} className="text-center">
                                Repeat
                              </th>
                              <th style={{ width: 140 }} className="text-center">
                                Status
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            {usageRows.map((se, idx) => {
                              const stage = se?.stage ?? se?.stage_exercise?.stage ?? null;
                              const level = stage?.level ?? null;
                              const world = level?.world ?? null;

                              const isActive =
                                se?.is_active === true || String(se?.is_active ?? "0") === "1";

                              return (
                                <tr key={se?.id ?? idx} className={!isActive ? "table-light" : ""}>
                                  <td>{idx + 1}</td>
                                  <td>
                                    <Trunc value={world?.name ?? "—"} maxWidth={240} />
                                  </td>
                                  <td>
                                    <Trunc value={level?.name ?? "—"} maxWidth={240} />
                                  </td>
                                  <td>
                                    <Trunc value={stage?.name ?? "—"} maxWidth={320} />
                                  </td>
                                  <td className="text-center">{se?.order_index ?? "—"}</td>
                                  <td className="text-center">{se?.repeat_count ?? "—"}</td>
                                  <td className="text-center">
                                    <span
                                      className={`px-24 py-4 rounded-pill fw-medium text-sm ${isActive
                                          ? "bg-success-focus text-success-main"
                                          : "bg-warning-focus text-warning-main"
                                        }`}
                                    >
                                      {isActive ? "Active" : "Disabled"}
                                    </span>
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
      <div className="fw-medium" style={{ whiteSpace: "pre-wrap" }}>
        {value ?? "—"}
      </div>
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

export default ExerciseView;
