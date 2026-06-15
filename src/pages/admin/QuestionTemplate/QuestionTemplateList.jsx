import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import { toast } from "react-toastify";

import API from "../../../helper/api";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Trunc = ({ value, maxWidth = 300 }) => {
    const v = value ?? "—";
    return (
        <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
            {v}
        </div>
    );
};

const QuestionTemplateList = () => {
    const [templates, setTemplates] = useState([]);
    const [loading, setLoading] = useState(true);
    const dtRef = useRef(null);

    const fetchTemplates = async () => {
        try {
            setLoading(true);
            const res = await API.get("/admin/question-templates?per_page=100");
            const payload = res.data?.data ?? res.data;
            const rows = Array.isArray(payload?.question_templates?.data) 
                ? payload.question_templates.data 
                : Array.isArray(payload?.question_templates) 
                    ? payload.question_templates 
                    : [];
            setTemplates(rows);
        } catch (err) {
            console.error("Fetch templates failed:", err);
            toast.error("Failed to load question templates");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTemplates();
    }, []);

    useEffect(() => {
        if (dtRef.current) {
            dtRef.current.destroy();
            dtRef.current = null;
        }

        if (templates.length > 0) {
            const t = setTimeout(() => {
                dtRef.current = $("#templateTable").DataTable({
                    destroy: true,
                    pageLength: 10,
                    scrollX: true,
                    scrollCollapse: true,
                    autoWidth: true,
                    order: [[0, "asc"]],
                    columnDefs: [
                        { targets: 0, width: "60px" },
                        { targets: 1, width: "250px" },
                        { targets: 2, width: "250px" },
                        { targets: 3, width: "100px" },
                        { targets: 4, width: "100px" },
                        { targets: 5, width: "100px" },
                        { targets: 6, width: "120px" },
                    ],
                });
            }, 0);

            return () => clearTimeout(t);
        }

        return () => {
            if (dtRef.current) {
                dtRef.current.destroy();
                dtRef.current = null;
            }
        };
    }, [templates]);

    const toggleStatus = async (item) => {
        try {
            const nextStatus = !item.is_active;
            await API.put(`/admin/question-templates/${item.id}`, {
                is_active: nextStatus
            });
            toast.success(`Template ${nextStatus ? 'activated' : 'disabled'} successfully`);
            fetchTemplates();
        } catch (err) {
            console.error(err);
            toast.error("Failed to update template status");
        }
    };

    const deleteTemplate = async (id) => {
        if (!window.confirm("Are you sure you want to delete this template?")) return;
        try {
            await API.delete(`/admin/question-templates/${id}`);
            toast.success("Template deleted successfully");
            fetchTemplates();
        } catch (err) {
            console.error(err);
            toast.error("Failed to delete template");
        }
    };

    return (
        <MasterLayout>
            <div className="card basic-data-table mt-24">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <h5>Question Templates</h5>
                    <Link to="/admin/question-templates/create">
                        <button type="button" className="d-flex align-items-center btn btn-primary-600 radius-3 px-20 py-11">
                            <Icon icon="mdi:plus" className="me-8" />
                            Create Template
                        </button>
                    </Link>
                </div>

                <div className="card-body">
                    {loading ? (
                        <div className="text-center py-4">Loading question templates...</div>
                    ) : (
                        <table className="table bordered-table mb-0" id="templateTable" data-page-length={10}>
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Question (EN)</th>
                                    <th>Question (KH)</th>
                                    <th className="text-center">Operation</th>
                                    <th className="text-center">Difficulty</th>
                                    <th className="text-center">Status</th>
                                    <th className="text-center">Action</th>
                                </tr>
                            </thead>

                            <tbody>
                                {templates.length === 0 ? (
                                    <tr>
                                        <td colSpan={7} className="text-center">
                                            No templates found
                                        </td>
                                    </tr>
                                ) : (
                                    templates.map((t, idx) => (
                                        <tr key={t.id} className={!t.is_active ? "table-light" : ""}>
                                            <td>{idx + 1}</td>
                                            <td>
                                                <Trunc value={t.question_en} />
                                            </td>
                                            <td>
                                                <Trunc value={t.question_kh} />
                                            </td>
                                            <td className="text-center text-capitalize">
                                                <span className="badge bg-light text-dark border">{t.operation}</span>
                                            </td>
                                            <td className="text-center text-capitalize">
                                                <span className={`badge ${
                                                    t.difficulty === 'easy' ? 'bg-success-focus text-success-main' :
                                                    t.difficulty === 'medium' ? 'bg-warning-focus text-warning-main' :
                                                    'bg-danger-focus text-danger-main'
                                                }`}>
                                                    {t.difficulty}
                                                </span>
                                            </td>
                                            <td className="text-center">
                                                <span className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                                                    t.is_active ? "bg-success-focus text-success-main" : "bg-warning-focus text-warning-main"
                                                }`}>
                                                    {t.is_active ? "Active" : "Disabled"}
                                                </span>
                                            </td>
                                            <td className="text-center">
                                                <Link
                                                    to={`/admin/question-templates/${t.id}/edit`}
                                                    className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                                                    title="Edit"
                                                >
                                                    <Icon icon="lucide:edit" />
                                                </Link>
                                                <button
                                                    type="button"
                                                    onClick={() => toggleStatus(t)}
                                                    className="w-32-px h-32-px me-8 bg-warning-focus text-warning-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                    title="Toggle Status"
                                                >
                                                    <Icon icon="mdi:toggle-switch" />
                                                </button>
                                                <button
                                                    type="button"
                                                    onClick={() => deleteTemplate(t.id)}
                                                    className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                                                    title="Delete"
                                                >
                                                    <Icon icon="lucide:trash" />
                                                </button>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>
        </MasterLayout>
    );
};

export default QuestionTemplateList;
