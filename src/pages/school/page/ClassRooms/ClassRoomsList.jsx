import React, { useEffect, useRef, useState } from "react";
import QRCode from "react-qr-code";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../../../../helper/api";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import { useAuth } from "../../../../context/AuthContext";

const ClassRoomsList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const [classrooms, setClassrooms] = useState([]);

  const [message, setMessage] = useState("");

  const [qrModal, setQrModal] = useState({
    open: false,
    classroomId: null,
    value: "",
    title: "",
  });

  const [qrCopied, setQrCopied] = useState(false);
  const [regenLoading, setRegenLoading] = useState(false);

  const [copiedRowId, setCopiedRowId] = useState(null);

  const dtRef = useRef(null);

  const canAnyAction = hasAnyPermission([
    "classrooms.view",
    "classrooms.update",
    "classrooms.delete",
  ]);

  const normalize = (c) => {
    const teacher = c?.teacher || {};
    return {
      id: c?.id,
      name: c?.name || "Unnamed Classroom",
      join_code: c?.join_code || c?.code || "—",
      subject: teacher?.subject || c?.subject || "—",
      teacher_name: teacher?.name || c?.teacher_name || "Not Assigned",
      teacher_email: teacher?.email || c?.teacher_email || "",
      student_count: c?.students_count ?? c?.enrollments_count ?? 0,
      is_active:
        c?.is_active === true || String(c?.is_active ?? c?.status ?? "0") === "1",
      start_date: c?.start_date || null,
      end_date: c?.end_date || null,
    };
  };

  const fetchClassrooms = async () => {
    try {
      const res = await API.get("/school/classrooms");
      const rows = Array.isArray(res.data?.classrooms)
        ? res.data.classrooms
        : Array.isArray(res.data)
          ? res.data
          : [];
      setClassrooms(rows.map(normalize));
    } catch (err) {
      console.error("Fetch classrooms failed:", err);
      setMessage("Failed to load classrooms");
    }
  };

  const regenerateJoinCode = async () => {
    if (!qrModal.classroomId) return;

    try {
      setRegenLoading(true);

      const res = await API.post(`/school/classrooms/${qrModal.classroomId}/regenerate-join-code`);

      const raw = res?.data?.data?.classroom;
      const updated = raw ? normalize(raw) : null;
      if (!updated?.join_code || updated.join_code === "—") {
        setMessage("Regenerated, but no join code returned");
        return;
      }

      setClassrooms((prev) => prev.map((c) => (c.id === updated.id ? { ...c, join_code: updated.join_code } : c)));

      setQrModal((prev) => ({
        ...prev,
        value: updated.join_code,
        title: `${updated?.name || "Classroom"} (${updated.join_code})`,
      }));

      setQrCopied(false);
      setMessage("Join code regenerated");
    } catch (err) {
      console.error(err);
      setMessage(err?.response?.data?.message || "Failed to regenerate join code");
    } finally {
      setRegenLoading(false);
    }
  };


  const openQr = (classroom) => {
    const joinCode = classroom?.join_code && classroom.join_code !== "—" ? classroom.join_code : "";

    setQrModal({
      open: true,
      classroomId: classroom?.id ?? null,
      value: joinCode,
      title: `${classroom?.name || "Classroom"}${joinCode ? ` (${joinCode})` : ""}`,
    });

    setQrCopied(false);
    setMessage("");
  };

  const closeQr = () => {
    setQrModal({ open: false, classroomId: null, value: "", title: "" });
    setQrCopied(false);
    setMessage("");
  };


  const copyText = async (text) => {
    const c = String(text || "").trim();
    if (!c || c === "—") return false;

    try {
      await navigator.clipboard.writeText(c);
      return true;
    } catch {
      const ta = document.createElement("textarea");
      ta.value = c;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
      return true;
    }
  };

  const copyJoinCodeRow = async (classroomId, code) => {
    const ok = await copyText(code);
    if (!ok) return;

    setCopiedRowId(classroomId);

    window.setTimeout(() => setCopiedRowId((prev) => (prev === classroomId ? null : prev)), 1000);
  };

  const copyQrValue = async () => {
    const ok = await copyText(qrModal.value);
    if (!ok) return;

    setQrCopied(true);
    window.setTimeout(() => setQrCopied(false), 1000);
  };

  const downloadQrPng = () => {
    const svg = document.getElementById("classroom-qr-svg");
    if (!svg) return;

    const serializer = new XMLSerializer();
    const svgString = serializer.serializeToString(svg);

    const canvas = document.createElement("canvas");
    const size = 512;
    canvas.width = size;
    canvas.height = size;

    const ctx = canvas.getContext("2d");
    const img = new Image();

    const svgBlob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
    const url = URL.createObjectURL(svgBlob);

    img.onload = () => {
      ctx.fillStyle = "#ffffff";
      ctx.fillRect(0, 0, size, size);
      ctx.drawImage(img, 0, 0, size, size);
      URL.revokeObjectURL(url);

      const pngUrl = canvas.toDataURL("image/png");
      const a = document.createElement("a");
      a.href = pngUrl;
      a.download = `classroom-qr-${(qrModal.title || "code").replace(/\s+/g, "-")}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    };

    img.src = url;
  };

  useEffect(() => {
    const onKeyDown = (e) => e.key === "Escape" && closeQr();
    if (qrModal.open) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [qrModal.open]);

  useEffect(() => {
    fetchClassrooms();
  }, []);

  useEffect(() => {
    const id = setInterval(fetchClassrooms, 30000);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    if (!message) return;
    const t = window.setTimeout(() => setMessage(""), 2500);
    return () => window.clearTimeout(t);
  }, [message]);


  useEffect(() => {
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    if (classrooms.length > 0) {
      dtRef.current = $("#classroomTable").DataTable({
        destroy: true,
        pageLength: 10,
        scrollX: true,
        scrollCollapse: true,
        autoWidth: false,
        columnDefs: [
          { targets: 0, width: "60px" },
          { targets: 1, width: "260px" },
          { targets: 2, width: "160px" },
          { targets: 3, width: "180px" },
          { targets: 4, width: "260px" },
          { targets: 5, width: "120px" },
          { targets: 6, width: "120px" },
          ...(canAnyAction ? [{ targets: 7, width: "200px" }] : []),
        ],
      });
    }

    return () => {
      if (dtRef.current) {
        dtRef.current.destroy();
        dtRef.current = null;
      }
    };
  }, [classrooms, canAnyAction]);

  const deleteClassroom = async (id) => {
    if (
      !window.confirm(
        "Archive this classroom? This will make it inactive and students won't be able to join."
      )
    )
      return;

    try {
      await API.delete(`/school/classrooms/${id}`);
      setClassrooms((prev) => prev.filter((c) => c.id !== id));
      setMessage("Classroom archived successfully");
    } catch (err) {
      setMessage(err?.response?.data?.message || "Archive failed");
      console.error(err);
    }
  };

  const formatDateRange = (start, end) => {
    if (!start && !end) return "";
    const s = start ? new Date(start).toLocaleDateString() : "";
    const e = end ? new Date(end).toLocaleDateString() : "";
    return [s, e].filter(Boolean).join(" - ");
  };

  const CellEllipsis = ({ title, children, width = 220 }) => (
    <div
      title={title}
      style={{
        maxWidth: width,
        whiteSpace: "nowrap",
        overflow: "hidden",
        textOverflow: "ellipsis",
      }}
    >
      {children}
    </div>
  );

  return (
    <SchoolLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h5>Classrooms</h5>

          {hasPermission("classrooms.create") && (
            <Link to="/school/classrooms/create">
              <button type="button" className="btn btn-primary-600 radius-3 px-20 py-11">
                Add Classroom
              </button>
            </Link>
          )}
        </div>

        {message && <div className="alert alert-success">{message}</div>}

        <div className="card-body">
          <table className="table bordered-table mb-0" id="classroomTable" data-page-length={10}>
            <thead>
              <tr>
                <th>#</th>
                <th>Name</th>
                <th>Join Code</th>
                <th>Subject</th>
                <th>Teacher</th>
                <th>Students</th>
                <th>Status</th>
                {canAnyAction && <th>Action</th>}
              </tr>
            </thead>

            <tbody>
              {classrooms.length === 0 ? (
                <tr>
                  <td colSpan={canAnyAction ? 8 : 7} className="text-center">
                    No classrooms found
                  </td>
                </tr>
              ) : (
                classrooms.map((c, idx) => {
                  const isRowCopied = copiedRowId === c.id;

                  return (
                    <tr key={c.id} className={!c.is_active ? "table-light" : ""}>
                      <td>{idx + 1}</td>

                      <td>
                        <div className="d-flex flex-column">
                          <CellEllipsis title={c.name} width={260}>
                            <span className="fw-semibold">{c.name}</span>
                          </CellEllipsis>

                          {c.start_date || c.end_date ? (
                            <div className="text-muted small">
                              {formatDateRange(c.start_date, c.end_date)}
                            </div>
                          ) : null}
                        </div>
                      </td>

                      {/* ✅ Click-to-copy badge with hover effect + temporary text */}
                      <td>
                        {c.join_code && c.join_code !== "—" ? (
                          <button
                            type="button"
                            onClick={() => copyJoinCodeRow(c.id, c.join_code)}
                            className="badge bg-secondary border-0"
                            title="Click to copy"
                            style={{
                              cursor: "pointer",
                              padding: "8px 10px",
                              transition: "all .15s ease",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.classList.add("bg-secondary");
                              e.currentTarget.style.filter = "brightness(0.92)";
                              e.currentTarget.style.boxShadow = "0 6px 14px rgba(0,0,0,0.10)";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.filter = "none";
                              e.currentTarget.style.boxShadow = "none";
                            }}
                          >
                            <span className="d-inline-flex align-items-center gap-6">
                              <Icon icon={isRowCopied ? "mdi:check" : "mdi:content-copy"} />
                              {isRowCopied ? "Copied!" : c.join_code}
                            </span>
                          </button>
                        ) : (
                          <span className="text-muted">No code</span>
                        )}
                      </td>

                      <td>
                        <CellEllipsis title={c.subject} width={180}>
                          {c.subject || "—"}
                        </CellEllipsis>
                      </td>

                      <td>
                        <div className="d-flex flex-column">
                          <CellEllipsis title={c.teacher_name} width={240}>
                            {c.teacher_name}
                          </CellEllipsis>

                          {c.teacher_email ? (
                            <CellEllipsis title={c.teacher_email} width={240}>
                              <span className="text-muted small">{c.teacher_email}</span>
                            </CellEllipsis>
                          ) : null}
                        </div>
                      </td>

                      <td>
                        <span className="badge bg-primary">{c.student_count}</span>
                      </td>

                      <td>
                        <span
                          className={`px-24 py-4 rounded-pill fw-medium text-sm ${c.is_active
                            ? "bg-success-focus text-success-main"
                            : "bg-warning-focus text-warning-main"
                            }`}
                        >
                          {c.is_active ? "Active" : "Archived"}
                        </span>
                      </td>

                      {canAnyAction && (
                        <td>
                          {hasPermission("classrooms.view") && (
                            <Link
                              to={`/school/classrooms/${c.id}`}
                              className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="View"
                            >
                              <Icon icon="iconamoon:eye-light" />
                            </Link>
                          )}

                          {hasPermission("classrooms.update") && c.is_active && (
                            <Link
                              to={`/school/classrooms/${c.id}/edit`}
                              className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="Edit"
                            >
                              <Icon icon="lucide:edit" />
                            </Link>
                          )}

                          {hasPermission("classrooms.delete") && c.is_active && (
                            <button
                              type="button"
                              onClick={() => deleteClassroom(c.id)}
                              className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                              title="Archive"
                            >
                              <Icon icon="mingcute:delete-2-line" />
                            </button>
                          )}

                          {c.is_active && (
                            <button
                              type="button"
                              onClick={() => openQr(c)}
                              className="w-32-px h-32-px me-8 bg-info-focus text-info-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                              title="QR Code"
                            >
                              <Icon icon="mdi:qrcode" />
                            </button>
                          )}
                        </td>
                      )}
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ✅ QR Modal + copy shows "Copied!" for 1s */}
      {qrModal.open && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100"
          style={{
            background: "rgba(0,0,0,0.75)",
            zIndex: 1055,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 16,
          }}
          onClick={closeQr}
          role="dialog"
          aria-modal="true"
        >
          <div
            className="bg-white radius-12 p-16"
            style={{ width: "min(420px, 95vw)" }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="d-flex justify-content-between align-items-center mb-12">
              <div className="fw-semibold">QR Code</div>
              <button
                type="button"
                className="d-flex align-items-center btn btn-sm btn-outline-secondary"
                onClick={closeQr}
                title="Close"
              >
                <Icon icon="mdi:close" />
              </button>
            </div>

            <div
              className="d-flex align-items-center justify-content-center border radius-12 p-16 my-24"
              style={{ background: "#fff" }}
            >
              <QRCode id="classroom-qr-svg" value={qrModal.value || ""} size={220} />
            </div>

            <div className="d-flex align-items-center gap-2 flex-nowrap">
              <button
                type="button"
                className="btn btn-primary flex-grow-1 text-truncate"
                style={{ minWidth: 0 }}
                onClick={downloadQrPng}
              >
                <Icon icon="mdi:download" className="me-6" />
                Download
              </button>

              {hasPermission("classrooms.update") && (
                <button
                  type="button"
                  className=" btn btn-warning flex-shrink-0"
                  style={{ whiteSpace: "nowrap" }}
                  onClick={regenerateJoinCode}
                  disabled={regenLoading}
                  title="Regenerate join code"
                >
                  <Icon icon={regenLoading ? "mdi:loading" : "mdi:refresh"} className="me-6" />
                  {regenLoading ? "..." : "Regenerate"}
                </button>
              )}

              <button
                type="button"
                className={`btn flex-shrink-0 ${qrCopied ? "btn-success" : "btn-outline-secondary"}`}
                style={{ whiteSpace: "nowrap" }}
                onClick={copyQrValue}
                disabled={!qrModal.value}
                title="Copy join code"
              >
                <Icon icon={qrCopied ? "mdi:check" : "mdi:content-copy"} className="me-6" />
                {qrCopied ? "Copied!" : "Copy"}
              </button>
            </div>

          </div>
        </div>
      )}
    </SchoolLayout>
  );
};

export default ClassRoomsList;
