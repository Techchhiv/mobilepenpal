import React, { useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";

import API from "../../../helper/api";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";

const QuestionTemplateCreate = () => {
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [form, setForm] = useState({
    question_en: "",
    question_kh: "",
    operation: "add",
    difficulty: "easy",
    is_active: true,
  });

  const onChange = (key) => (e) => {
    const val =
      e?.target?.type === "checkbox"
        ? e.target.checked
        : e?.target?.value ?? "";
    setForm((p) => ({ ...p, [key]: val }));
  };

  const submit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    if (!form.question_en.trim() || !form.question_kh.trim()) {
      setSaving(false);
      setError("Both English and Khmer question texts are required.");
      return;
    }

    try {
      const payload = {
        question_en: form.question_en.trim(),
        question_kh: form.question_kh.trim(),
        operation: form.operation,
        difficulty: form.difficulty,
        is_active: !!form.is_active,
      };

      await API.post("/admin/question-templates", payload);
      toast.success("Question template created successfully!");
      navigate("/admin/question-templates");
    } catch (err) {
      console.error("Create template error:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.question_en?.[0] ||
        errors?.question_kh?.[0] ||
        errors?.operation?.[0] ||
        errors?.difficulty?.[0] ||
        err?.response?.data?.message ||
        "Failed to create template. Please check your inputs."
      );
    } finally {
      setSaving(false);
    }
  };

  const Required = () => <span className="text-danger ms-1">*</span>;

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Create New Question Template"
          subtitle="Configure new question template texts, placeholders, operation, and difficulty level"
        />

        <div className="card border radius-12 shadow-none">
          <div className="card-header border-bottom py-16 px-24 bg-base d-flex justify-content-between align-items-center flex-wrap gap-12">
            <h6 className="fw-bold mb-0 text-dark">Create Template Form</h6>
            <Link
              to="/admin/question-templates"
              className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
            >
              <Icon icon="mdi:arrow-left" />
              <span>Back to Templates</span>
            </Link>
          </div>

          <div className="card-body p-24">
            {error && (
              <div className="alert alert-danger d-flex align-items-center gap-2 mb-20 radius-8">
                <Icon icon="mdi:alert-circle" className="text-xl flex-shrink-0" />
                <div>{error}</div>
              </div>
            )}

            <form className="row gy-4" onSubmit={submit}>
              <div className="col-md-6">
                <label className="form-label text-sm fw-semibold text-dark">
                  Question (EN) <Required />
                </label>
                <textarea
                  className="form-control radius-8"
                  placeholder="I have {a} {fruit} and get {b} more. How many do I have now?"
                  rows={4}
                  value={form.question_en}
                  onChange={onChange("question_en")}
                  required
                />
                <small className="text-xs text-secondary-light d-block mt-6">
                  Use placeholders: <code>{`{a}`}</code> (first value), <code>{`{b}`}</code> (second value), <code>{`{fruit}`}</code> (dynamic name).
                </small>
              </div>

              <div className="col-md-6">
                <label className="form-label text-sm fw-semibold text-dark">
                  Question (KH) <Required />
                </label>
                <textarea
                  className="form-control radius-8"
                  placeholder="ខ្ញុំមាន {fruit} {a} ហើយទទួលបាន {b} ទៀត។ តើឥឡូវខ្ញុំមានប៉ុន្មាន?"
                  rows={4}
                  value={form.question_kh}
                  onChange={onChange("question_kh")}
                  required
                />
                <small className="text-xs text-secondary-light d-block mt-6">
                  Use placeholders: <code>{`{a}`}</code>, <code>{`{b}`}</code>, <code>{`{fruit}`}</code>.
                </small>
              </div>

              <div className="col-md-4">
                <label className="form-label text-sm fw-semibold text-dark">Operation</label>
                <select className="form-select radius-8" value={form.operation} onChange={onChange("operation")}>
                  <option value="add">Addition (+)</option>
                  <option value="sub">Subtraction (-)</option>
                  <option value="mul">Multiplication (×)</option>
                  <option value="div">Division (÷)</option>
                </select>
              </div>

              <div className="col-md-4">
                <label className="form-label text-sm fw-semibold text-dark">Difficulty</label>
                <select className="form-select radius-8" value={form.difficulty} onChange={onChange("difficulty")}>
                  <option value="easy">Easy (Addition / Subtraction)</option>
                  <option value="medium">Medium (Multiplication / Division)</option>
                  <option value="hard">Hard (Multi-step)</option>
                </select>
              </div>

              <div className="col-md-4 d-flex align-items-end">
                <div className="form-check d-flex align-items-center mb-12">
                  <input
                    className="form-check-input"
                    type="checkbox"
                    id="isActive"
                    checked={!!form.is_active}
                    onChange={onChange("is_active")}
                  />
                  <label className="form-check-label ms-2 text-sm text-dark" htmlFor="isActive">
                    Active (Available in game pool)
                  </label>
                </div>
              </div>

              <div className="col-12 d-flex justify-content-end gap-12 mt-24">
                <Link
                  to="/admin/question-templates"
                  className="btn btn-outline-secondary radius-8 px-20"
                >
                  Cancel
                </Link>
                <button
                  className="btn btn-primary radius-8 d-inline-flex align-items-center gap-6 px-20"
                  type="submit"
                  disabled={saving}
                >
                  <Icon icon="mdi:plus" />
                  <span>{saving ? "Creating..." : "Create Template"}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </MasterLayout>
  );
};

export default QuestionTemplateCreate;
