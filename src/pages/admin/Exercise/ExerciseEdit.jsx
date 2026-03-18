import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Required = () => <span className="text-danger ms-1">*</span>;

const Trunc = ({ value, maxWidth = 240 }) => {
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

const parseOptions = (raw) => {
  if (Array.isArray(raw)) return raw;
  if (typeof raw === "string" && raw.trim()) {
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
};

const normalizeType = (v) => {
  const s = String(v ?? "").trim();
  return s || "";
};

const ExerciseEdit = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { hasPermission } = useAuth();

  const canView = hasPermission("exercises.view") || hasPermission("exercises.update");
  const canEdit = hasPermission("exercises.update");

  const from = location.state?.from || "/admin/exercises";

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [exercise, setExercise] = useState(null);

  const [form, setForm] = useState({
    character_type: "",
    character: "",
    prompt: "",
    question: "",
    instruction: "",
    hint: "",
    example: "",
    correct_answer: "",
  });

  const [options, setOptions] = useState([]); // array of strings

  const [initialSnapshot, setInitialSnapshot] = useState(null);

  const onChange = (key) => (e) => {
    setForm((p) => ({ ...p, [key]: e.target.value }));
  };

  const fetchExercise = async () => {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await API.get(`/admin/exercises/${id}`);
      const payload = res.data?.data ?? res.data;
      const ex = payload?.exercise ?? payload ?? null;

      setExercise(ex);

      const nextForm = {
        character_type: normalizeType(ex?.character_type),
        character: ex?.character ?? "",
        prompt: ex?.prompt ?? "",
        question: ex?.question ?? "",
        instruction: ex?.instruction ?? "",
        hint: ex?.hint ?? "",
        example: ex?.example ?? "",
        correct_answer: ex?.correct_answer ?? "",
      };

      const nextOptions = parseOptions(ex?.options).map((x) => String(x ?? "").trim()).filter(Boolean);

      setForm(nextForm);
      setOptions(nextOptions);

      setInitialSnapshot({
        form: nextForm,
        options: nextOptions,
      });
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

  const headerTitle = useMemo(() => {
    const ct = form.character_type ? `(${form.character_type})` : "";
    const ch = form.character ? `"${form.character}"` : "";
    return `Exercise ${ct} ${ch}`.trim() || "Exercise";
  }, [form.character_type, form.character]);

  const addOption = () => setOptions((p) => [...p, ""]);
  const removeOption = (idx) => setOptions((p) => p.filter((_, i) => i !== idx));
  const updateOption = (idx, val) =>
    setOptions((p) => p.map((x, i) => (i === idx ? val : x)));

  const resetForm = () => {
    if (!initialSnapshot) return;
    setForm(initialSnapshot.form);
    setOptions(initialSnapshot.options);
    setError("");
    setMessage("");
  };

  const validate = () => {
    // character_type is required by DB (enum not null)
    if (!form.character_type) return "Character type is required.";

    // If they filled question/options, enforce consistency lightly:
    const cleanedOptions = options.map((x) => String(x ?? "").trim()).filter(Boolean);

    if (cleanedOptions.length > 0 && !form.question?.trim()) {
      return "Question is required when options are provided.";
    }

    if (form.correct_answer?.trim() && cleanedOptions.length > 0) {
      const ca = form.correct_answer.trim();
      const exists = cleanedOptions.some((x) => x === ca);
      if (!exists) {
        return "Correct answer must match one of the options (or clear it).";
      }
    }

    // If question exists, require correct_answer or allow empty? up to you
    // We'll not force it (some exercises might be drawing based).
    return null;
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!canEdit) return;

    setSaving(true);
    setError("");
    setMessage("");

    const errMsg = validate();
    if (errMsg) {
      setSaving(false);
      setError(errMsg);
      return;
    }

    try {
      const cleanedOptions = options.map((x) => String(x ?? "").trim()).filter(Boolean);

      const payload = {
        character_type: form.character_type,
        character: form.character?.trim() || null,
        prompt: form.prompt?.trim() || null,
        question: form.question?.trim() || null,
        instruction: form.instruction?.trim() || null,
        hint: form.hint?.trim() || null,
        example: form.example?.trim() || null,
        correct_answer: form.correct_answer?.trim() || null,
        options: cleanedOptions.length ? cleanedOptions : null,
      };

      await API.put(`/admin/exercises/${id}`, payload);

      navigate(`/admin/exercises/${id}`, { state: { from }, replace: true });
    } catch (err) {
      console.error("Update exercise failed:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.character_type?.[0] ||
          errors?.character?.[0] ||
          errors?.question?.[0] ||
          errors?.options?.[0] ||
          errors?.correct_answer?.[0] ||
          err?.response?.data?.message ||
          "Failed to update exercise."
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
          You don’t have permission to edit exercises.
        </div>
      </MasterLayout>
    );
  }

  return (
    <MasterLayout>
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h5 className="mb-0">Edit Exercise</h5>
            <small className="text-muted">ID: {id}</small>
          </div>

          <div className="d-flex gap-2 flex-wrap">
            <button
              type="button"
              onClick={() => navigate(from)}
              className="d-flex align-items-center btn btn-secondary radius-3 px-20 py-11"
              disabled={saving}
            >
              <Icon icon="mdi:arrow-left" className="me-6" />
              Back
            </button>

            <Link
              to={`/admin/exercises/${id}`}
              state={{ from }}
              className="d-flex align-items-center btn btn-outline-dark radius-3 px-20 py-11"
              title="View exercise"
            >
              <Icon icon="iconamoon:eye-light" className="me-6" />
              View
            </Link>
          </div>
        </div>

        <div className="card-body">
          {message && <div className="alert alert-success">{message}</div>}
          {error && <div className="alert alert-danger">{error}</div>}

          {loading ? (
            <div className="text-center py-40">
              <div className="spinner-border" role="status" />
              <div className="mt-12 text-muted">Loading exercise...</div>
            </div>
          ) : !exercise ? (
            <div className="text-center py-40 text-muted">Exercise not found.</div>
          ) : (
            <form onSubmit={submit}>
              <div className="row g-3">
                {/* Left preview */}
                <div className="col-12 col-lg-4">
                  <div className="card border">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:puzzle-outline" />
                      <h6 className="mb-0">Preview</h6>
                    </div>

                    <div className="card-body">
                      <div className="d-flex align-items-center gap-3">
                        <div
                          className="border radius-12 overflow-hidden bg-neutral-50 d-flex align-items-center justify-content-center"
                          style={{ width: 120, height: 120 }}
                          title={headerTitle}
                        >
                          <Icon icon="mdi:format-letter-case" width={48} />
                        </div>

                        <div className="flex-grow-1">
                          <div className="fw-semibold">
                            <Trunc value={headerTitle} maxWidth={220} />
                          </div>
                          <div className="text-muted small">Exercise ID: {id}</div>

                          <div className="mt-10 d-flex gap-2 flex-wrap">
                            <span className="badge bg-light text-dark">
                              Type: {form.character_type || "—"}
                            </span>
                            <span className="badge bg-light text-dark">
                              Char: {form.character?.trim() || "—"}
                            </span>
                            <span className="badge bg-light text-dark">
                              Options: {options.filter((x) => String(x).trim()).length || "—"}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="border-top mt-16 pt-12">
                        <div className="text-muted small mb-6">System</div>
                        <MiniRow label="Created At" value={prettyDateTime(exercise?.created_at)} />
                        <MiniRow label="Updated At" value={prettyDateTime(exercise?.updated_at)} />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right form */}
                <div className="col-12 col-lg-8">
                  <div className="card border mb-3">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:form-textbox" />
                      <h6 className="mb-0">Exercise Information</h6>
                    </div>

                    <div className="card-body">
                      <div className="row gy-3">
                        <div className="col-md-6">
                          <label className="form-label">
                            Character Type <Required />
                          </label>
                          <select
                            className="form-control"
                            value={form.character_type}
                            onChange={onChange("character_type")}
                            required
                          >
                            <option value="">Select type</option>
                            <option value="digits">digits</option>
                            <option value="consonants">consonants</option>
                            <option value="independent_vowels">independent_vowels</option>
                            <option value="dependent_vowels">dependent_vowels</option>
                          </select>
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">Character</label>
                          <input
                            className="form-control"
                            placeholder="e.g., ក"
                            value={form.character}
                            onChange={onChange("character")}
                          />
                        </div>

                        <div className="col-12">
                          <label className="form-label">Prompt</label>
                          <textarea
                            className="form-control"
                            rows={2}
                            value={form.prompt}
                            onChange={onChange("prompt")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-12">
                          <label className="form-label">Instruction</label>
                          <textarea
                            className="form-control"
                            rows={2}
                            value={form.instruction}
                            onChange={onChange("instruction")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-12">
                          <label className="form-label">Hint</label>
                          <textarea
                            className="form-control"
                            rows={2}
                            value={form.hint}
                            onChange={onChange("hint")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-12">
                          <label className="form-label">Example</label>
                          <input
                            className="form-control"
                            value={form.example}
                            onChange={onChange("example")}
                            placeholder="Optional"
                          />
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Quiz block */}
                  <div className="card border mb-3">
                    <div className="card-header d-flex align-items-center gap-2">
                      <Icon icon="mdi:help-circle-outline" />
                      <h6 className="mb-0">Question & Options</h6>
                    </div>

                    <div className="card-body">
                      <div className="row gy-3">
                        <div className="col-12">
                          <label className="form-label">Question</label>
                          <textarea
                            className="form-control"
                            rows={2}
                            value={form.question}
                            onChange={onChange("question")}
                            placeholder="Optional"
                          />
                        </div>

                        <div className="col-md-6">
                          <label className="form-label">Correct Answer</label>
                          <input
                            className="form-control"
                            value={form.correct_answer}
                            onChange={onChange("correct_answer")}
                            placeholder="Optional"
                          />
                          <div className="form-text">
                            If you have options, the correct answer should match one option exactly.
                          </div>
                        </div>

                        <div className="col-md-6 d-flex align-items-end justify-content-end">
                          <button
                            type="button"
                            className="btn btn-outline-primary"
                            onClick={addOption}
                          >
                            <Icon icon="mdi:plus" className="me-6" />
                            Add Option
                          </button>
                        </div>

                        <div className="col-12">
                          {options.length === 0 ? (
                            <div className="text-muted">No options.</div>
                          ) : (
                            <div className="table-responsive">
                              <table className="table bordered-table mb-0">
                                <thead>
                                  <tr>
                                    <th style={{ width: 70 }}>#</th>
                                    <th>Option</th>
                                    <th style={{ width: 90 }} className="text-center">
                                      Remove
                                    </th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {options.map((op, idx) => (
                                    <tr key={idx}>
                                      <td>{idx + 1}</td>
                                      <td>
                                        <input
                                          className="form-control"
                                          value={op}
                                          onChange={(e) => updateOption(idx, e.target.value)}
                                          placeholder={`Option ${idx + 1}`}
                                        />
                                      </td>
                                      <td className="text-center">
                                        <button
                                          type="button"
                                          className="btn btn-outline-danger btn-sm"
                                          onClick={() => removeOption(idx)}
                                          title="Remove option"
                                        >
                                          <Icon icon="radix-icons:cross-2" />
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          )}
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

const MiniRow = ({ label, value }) => {
  const v = value === null || value === undefined || value === "" ? "—" : value;
  return (
    <div className="d-flex justify-content-between gap-1 py-6 border-bottom">
      <div className="text-muted small">{label}</div>
      <div className="fw-medium">{v}</div>
    </div>
  );
};

export default ExerciseEdit;
