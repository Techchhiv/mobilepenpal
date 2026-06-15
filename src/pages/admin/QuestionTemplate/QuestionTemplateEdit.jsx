import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { toast } from "react-toastify";

import API from "../../../helper/api";
import MasterLayout from "../../../masterLayout/MasterLayout";

const QuestionTemplateEdit = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const [form, setForm] = useState({
    question_en: "",
    question_kh: "",
    operation: "add",
    difficulty: "easy",
    is_active: true,
  });

  useEffect(() => {
    const fetchTemplate = async () => {
      try {
        setLoading(true);
        const res = await API.get(`/admin/question-templates/${id}`);
        const payload = res.data?.data ?? res.data;
        const data = payload?.question_template ?? payload;
        if (data) {
          setForm({
            question_en: data.question_en ?? "",
            question_kh: data.question_kh ?? "",
            operation: data.operation ?? "add",
            difficulty: data.difficulty ?? "easy",
            is_active: data.is_active === true || String(data.is_active) === "1",
          });
        }
      } catch (err) {
        console.error("Fetch template error:", err);
        toast.error("Failed to load question template.");
        navigate("/admin/question-templates");
      } finally {
        setLoading(false);
      }
    };
    fetchTemplate();
  }, [id, navigate]);

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

      await API.put(`/admin/question-templates/${id}`, payload);
      toast.success("Question template updated successfully!");
      navigate("/admin/question-templates");
    } catch (err) {
      console.error("Update template error:", err);
      const errors = err?.response?.data?.errors || {};
      setError(
        errors?.question_en?.[0] ||
        errors?.question_kh?.[0] ||
        errors?.operation?.[0] ||
        errors?.difficulty?.[0] ||
        err?.response?.data?.message ||
        "Failed to update template. Please check your inputs."
      );
    } finally {
      setSaving(false);
    }
  };

  const Required = () => <span className="text-danger ms-1">*</span>;

  return (
    <MasterLayout>
      <div className="col-lg-12 mt-24">
        <div className="card">
          <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <h3 className="card-title mb-0">Edit Question Template #{id}</h3>
            <Link to="/admin/question-templates" className="d-flex align-items-center btn btn-secondary">
              <Icon icon="mdi:arrow-left" className="me-3" />
              Back to Templates
            </Link>
          </div>

          <div className="card-body">
            {loading ? (
              <div className="text-center py-4">Loading template details...</div>
            ) : (
              <>
                {error && (
                  <div className="alert alert-danger">
                    <Icon icon="mdi:alert-circle" className="me-2" />
                    {error}
                  </div>
                )}

                <form className="row gy-4" onSubmit={submit}>
                  <div className="col-md-6">
                    <label className="form-label">
                      Question (EN) <Required />
                    </label>
                    <textarea
                      className="form-control"
                      placeholder="I have {a} {fruit} and get {b} more. How many do I have now?"
                      rows={4}
                      value={form.question_en}
                      onChange={onChange("question_en")}
                      required
                    />
                    <small className="text-muted d-block mt-1">
                      Use placeholders: <code>{`{a}`}</code> (first value), <code>{`{b}`}</code> (second value), <code>{`{fruit}`}</code> (dynamic name).
                    </small>
                  </div>

                  <div className="col-md-6">
                    <label className="form-label">
                      Question (KH) <Required />
                    </label>
                    <textarea
                      className="form-control"
                      placeholder="ខ្ញុំមាន {fruit} {a} ហើយទទួលបាន {b} ទៀត។ តើឥឡូវខ្ញុំមានប៉ុន្មាន?"
                      rows={4}
                      value={form.question_kh}
                      onChange={onChange("question_kh")}
                      required
                    />
                    <small className="text-muted d-block mt-1">
                      Use placeholders: <code>{`{a}`}</code>, <code>{`{b}`}</code>, <code>{`{fruit}`}</code>.
                    </small>
                  </div>

                  <div className="col-md-4">
                    <label className="form-label">Operation</label>
                    <select className="form-select" value={form.operation} onChange={onChange("operation")}>
                      <option value="add">Addition (+)</option>
                      <option value="sub">Subtraction (-)</option>
                      <option value="mul">Multiplication (×)</option>
                      <option value="div">Division (÷)</option>
                    </select>
                  </div>

                  <div className="col-md-4">
                    <label className="form-label">Difficulty</label>
                    <select className="form-select" value={form.difficulty} onChange={onChange("difficulty")}>
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
                      <label className="form-check-label ms-2" htmlFor="isActive">
                        Active (Available in game pool)
                      </label>
                    </div>
                  </div>

                  <div className="col-12 d-flex justify-content-end gap-2 mt-24">
                    <button className="d-flex align-items-center btn btn-primary" type="submit" disabled={saving}>
                      <Icon icon="mdi:content-save-outline" className="me-3" />
                      {saving ? "Saving..." : "Save Changes"}
                    </button>
                  </div>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </MasterLayout>
  );
};

export default QuestionTemplateEdit;
