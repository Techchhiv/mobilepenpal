import React, { useState, useEffect, useCallback } from "react";
import MasterLayout from "../../masterLayout/MasterLayout";
import AuditLogDetailModal from "../../components/admin/AuditLogDetailModal";
import { getAuditLogs, getAuditLog, exportAuditLogs } from "../../services/auditLogService";
import AdminPageHeader from "../../components/admin/common/AdminPageHeader";
import "../../assets/css/auditLog.css";

// ─── Constants ─────────────────────────────────────────────────────────────────

const CATEGORIES = ["auth", "account", "school", "subscription", "system", "curriculum", "audit"];
const SEVERITIES = ["info", "warning", "critical"];

const SEVERITY_STYLES = {
  info: { background: "#e0f2fe", color: "#0369a1" },
  warning: { background: "#fef9c3", color: "#92400e" },
  critical: { background: "#fee2e2", color: "#b91c1c" },
};

function SeverityBadge({ severity }) {
  const s = SEVERITY_STYLES[severity] || SEVERITY_STYLES.info;
  return (
    <span style={{
      ...s, fontWeight: 700, borderRadius: 6,
      padding: "2px 10px", fontSize: 11, letterSpacing: 0.5, textTransform: "uppercase",
    }}>
      {severity}
    </span>
  );
}

// ─── Page Component ────────────────────────────────────────────────────────────

export default function AuditLogPage() {
  // Filters
  const [filters, setFilters] = useState({
    search: "", category: "", action: "", severity: "",
    actor: "", school_id: "", date_from: "", date_to: "",
  });
  const [pending, setPending] = useState({ ...filters });

  // Data
  const [logs, setLogs] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Detail modal
  const [selectedLog, setSelectedLog] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // Export
  const [exporting, setExporting] = useState(false);

  // ── Fetch logs ────────────────────────────────────────────────────────────
  const fetchLogs = useCallback(async (f, p) => {
    setLoading(true);
    setError(null);
    try {
      const params = { ...f, page: p, per_page: 20 };
      // Strip empty values
      Object.keys(params).forEach(k => !params[k] && delete params[k]);

      const { data } = await getAuditLogs(params);
      const result = data?.data;
      setLogs(result?.data || []);
      setPagination(result);
    } catch (err) {
      setError("Failed to load audit logs. Please try again.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLogs(filters, page);
  }, [filters, page, fetchLogs]);

  // ── Handlers ───────────────────────────────────────────────────────────────
  const handleSearch = () => {
    setFilters({ ...pending });
    setPage(1);
  };

  const handleReset = () => {
    const blank = {
      search: "", category: "", action: "", severity: "",
      actor: "", school_id: "", date_from: "", date_to: "",
    };
    setPending(blank);
    setFilters(blank);
    setPage(1);
  };

  const handleViewDetail = async (id) => {
    setDetailLoading(true);
    try {
      const { data } = await getAuditLog(id);
      setSelectedLog(data?.data || null);
    } catch {
      alert("Failed to load log details.");
    } finally {
      setDetailLoading(false);
    }
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const params = { ...filters };
      Object.keys(params).forEach(k => !params[k] && delete params[k]);
      const response = await exportAuditLogs(params);
      const url = URL.createObjectURL(new Blob([response.data]));
      const a = document.createElement("a");
      a.href = url;
      a.download = `audit_logs_${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      alert("Export failed. Please try again.");
    } finally {
      setExporting(false);
    }
  };

  // ── Pagination helpers ────────────────────────────────────────────────────
  const totalPages = pagination?.last_page || 1;

  return (
    <MasterLayout>
      <div className="py-12 audit-log-page">
        <AdminPageHeader
          title="System Audit Logs"
          subtitle="Read-only record of all important system activities, security events, and administrative operations"
          actionLabel={exporting ? "Exporting..." : "Export CSV"}
          actionIcon="lucide:download"
          onAction={handleExport}
        />

        {/* Filter Bar */}
        <div className="audit-filter-card">
          {/* Search */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">SEARCH</label>
            <input
              className="audit-filter-input"
              style={{ width: 200 }}
              placeholder="Actor, action, description…"
              value={pending.search}
              onChange={e => setPending(p => ({ ...p, search: e.target.value }))}
              onKeyDown={e => e.key === "Enter" && handleSearch()}
            />
          </div>

          {/* Category */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">CATEGORY</label>
            <select
              className="audit-filter-select"
              value={pending.category}
              onChange={e => setPending(p => ({ ...p, category: e.target.value }))}
            >
              <option value="">All</option>
              {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          {/* Severity */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">SEVERITY</label>
            <select
              className="audit-filter-select"
              value={pending.severity}
              onChange={e => setPending(p => ({ ...p, severity: e.target.value }))}
            >
              <option value="">All</option>
              {SEVERITIES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          {/* Actor */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">ACTOR</label>
            <input
              className="audit-filter-input"
              style={{ width: 150 }}
              placeholder="Name or email"
              value={pending.actor}
              onChange={e => setPending(p => ({ ...p, actor: e.target.value }))}
              onKeyDown={e => e.key === "Enter" && handleSearch()}
            />
          </div>

          {/* Date From */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">DATE FROM</label>
            <input
              type="date"
              className="audit-filter-date"
              value={pending.date_from}
              onChange={e => setPending(p => ({ ...p, date_from: e.target.value }))}
            />
          </div>

          {/* Date To */}
          <div className="audit-filter-group">
            <label className="audit-filter-label">DATE TO</label>
            <input
              type="date"
              className="audit-filter-date"
              value={pending.date_to}
              onChange={e => setPending(p => ({ ...p, date_to: e.target.value }))}
            />
          </div>

          {/* Buttons */}
          <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
            <button onClick={handleSearch} className="audit-btn audit-btn-primary">
              Search
            </button>
            <button onClick={handleReset} className="audit-btn audit-btn-secondary">
              Reset
            </button>
          </div>
        </div>

        {/* Status */}
        {error && (
          <div style={{ background: "#fee2e2", color: "#b91c1c", padding: "10px 16px", borderRadius: 8, marginBottom: 16 }}>
            {error}
          </div>
        )}

        {/* Table Card */}
        <div className="audit-table-card">
          <div style={{ overflowX: "auto" }}>
            <table className="audit-table">
              <thead>
                <tr>
                  {["Date / Time", "Actor", "Category", "Action", "Target", "Description", "Severity", "Details"].map(col => (
                    <th key={col}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={8} style={{ padding: 40, textAlign: "center", color: "#9ca3af" }}>
                      Loading…
                    </td>
                  </tr>
                ) : logs.length === 0 ? (
                  <tr>
                    <td colSpan={8} style={{ padding: 40, textAlign: "center", color: "#9ca3af" }}>
                      No audit logs found.
                    </td>
                  </tr>
                ) : (
                  logs.map((log, i) => (
                    <tr key={log.id} className={i % 2 === 0 ? "row-even" : "row-odd"}>
                      <td>
                        <span style={{ whiteSpace: "nowrap", fontSize: 12 }}>
                          {log.occurred_at ? new Date(log.occurred_at).toLocaleString() : "—"}
                        </span>
                      </td>
                      <td>
                        <div className="audit-actor-name">{log.actor_name || "System"}</div>
                        <div className="audit-actor-email">{log.actor_email || ""}</div>
                      </td>
                      <td>
                        <code className="audit-code-badge">
                          {log.category}
                        </code>
                      </td>
                      <td>
                        <code style={{ color: "#4f46e5", fontSize: 11 }}>{log.action}</code>
                      </td>
                      <td>
                        {log.target_type ? (
                          <span>
                            <span>{log.target_type.split("\\").pop()}</span>
                            {log.target_id && <span> #{log.target_id}</span>}
                          </span>
                        ) : "—"}
                      </td>
                      <td style={{ maxWidth: 240 }}>
                        <span style={{ display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                          {log.description || "—"}
                        </span>
                      </td>
                      <td>
                        <SeverityBadge severity={log.severity} />
                      </td>
                      <td>
                        <button
                          onClick={() => handleViewDetail(log.id)}
                          disabled={detailLoading}
                          className="audit-view-btn"
                        >
                          View
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Card Footer Pagination */}
          {pagination && (
            <div className="audit-card-footer">
              <div className="audit-counter text-secondary mb-0">
                Showing {pagination.from ?? 0}–{pagination.to ?? 0} of {pagination.total ?? 0} records
              </div>

              {totalPages > 1 && (
                <div className="audit-pagination-container">
                  <button
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="audit-btn audit-btn-secondary"
                  >
                    ← Prev
                  </button>
                  {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
                    const pg = totalPages <= 7 ? i + 1 : Math.max(1, page - 3) + i;
                    if (pg > totalPages) return null;
                    return (
                      <button
                        key={pg}
                        onClick={() => setPage(pg)}
                        className={`audit-btn ${pg === page ? "audit-btn-primary" : "audit-btn-secondary"}`}
                        style={{ minWidth: 36, padding: "0 10px" }}
                      >
                        {pg}
                      </button>
                    );
                  })}
                  <button
                    onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages}
                    className="audit-btn audit-btn-secondary"
                  >
                    Next →
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Detail Modal */}
      {selectedLog && (
        <AuditLogDetailModal log={selectedLog} onClose={() => setSelectedLog(null)} />
      )}
    </MasterLayout>
  );
}
