import React, { useState, useEffect, useCallback } from "react";
import MasterLayout from "../../masterLayout/MasterLayout";
import AuditLogDetailModal from "../../components/admin/AuditLogDetailModal";
import { getAuditLogs, getAuditLog, exportAuditLogs } from "../../services/auditLogService";

// ─── Constants ─────────────────────────────────────────────────────────────────

const CATEGORIES = ["auth", "account", "school", "subscription", "system", "curriculum", "audit"];
const SEVERITIES  = ["info", "warning", "critical"];

const SEVERITY_STYLES = {
  info:     { background: "#e0f2fe", color: "#0369a1" },
  warning:  { background: "#fef9c3", color: "#92400e" },
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

const inputStyle = {
  height: 36, borderRadius: 6, border: "1px solid #d1d5db", padding: "0 10px",
  fontSize: 13, outline: "none", background: "#fff",
};

const btnStyle = {
  height: 36, borderRadius: 6, border: "none", padding: "0 16px",
  fontSize: 13, cursor: "pointer", fontWeight: 600,
};

// ─── Page Component ────────────────────────────────────────────────────────────

export default function AuditLogPage() {
  // Filters
  const [filters, setFilters] = useState({
    search: "", category: "", action: "", severity: "",
    actor: "", school_id: "", date_from: "", date_to: "",
  });
  const [pending, setPending] = useState({ ...filters });

  // Data
  const [logs,       setLogs]       = useState([]);
  const [pagination, setPagination] = useState(null);
  const [page,       setPage]       = useState(1);
  const [loading,    setLoading]    = useState(false);
  const [error,      setError]      = useState(null);

  // Detail modal
  const [selectedLog,    setSelectedLog]    = useState(null);
  const [detailLoading,  setDetailLoading]  = useState(false);

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
      const result   = data?.data;
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
      const a   = document.createElement("a");
      a.href     = url;
      a.download = `audit_logs_${new Date().toISOString().slice(0,10)}.csv`;
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
      <div style={{ padding: "24px 28px", maxWidth: 1400, margin: "0 auto" }}>

        {/* Page Header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
          <div>
            <h1 style={{ margin: 0, fontSize: 24, fontWeight: 800, color: "#111827" }}>
              System Audit Logs
            </h1>
            <p style={{ margin: "4px 0 0", color: "#6b7280", fontSize: 14 }}>
              Read-only record of all important system activities. Super Admin access only.
            </p>
          </div>
          <button
            onClick={handleExport}
            disabled={exporting}
            style={{
              ...btnStyle,
              background: exporting ? "#d1fae5" : "#059669",
              color: "#fff",
              display: "flex", alignItems: "center", gap: 6,
            }}
          >
            {exporting ? "Exporting…" : "⬇ Export CSV"}
          </button>
        </div>

        {/* Filter Bar */}
        <div style={{
          background: "#fff", borderRadius: 10, padding: "18px 20px",
          marginBottom: 20, boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
          display: "flex", flexWrap: "wrap", gap: 10, alignItems: "flex-end",
        }}>
          {/* Search */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>SEARCH</label>
            <input
              style={{ ...inputStyle, width: 200 }}
              placeholder="Actor, action, description…"
              value={pending.search}
              onChange={e => setPending(p => ({ ...p, search: e.target.value }))}
              onKeyDown={e => e.key === "Enter" && handleSearch()}
            />
          </div>

          {/* Category */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>CATEGORY</label>
            <select style={inputStyle} value={pending.category}
              onChange={e => setPending(p => ({ ...p, category: e.target.value }))}>
              <option value="">All</option>
              {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          {/* Severity */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>SEVERITY</label>
            <select style={inputStyle} value={pending.severity}
              onChange={e => setPending(p => ({ ...p, severity: e.target.value }))}>
              <option value="">All</option>
              {SEVERITIES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          {/* Actor */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>ACTOR</label>
            <input style={{ ...inputStyle, width: 150 }} placeholder="Name or email"
              value={pending.actor}
              onChange={e => setPending(p => ({ ...p, actor: e.target.value }))}
              onKeyDown={e => e.key === "Enter" && handleSearch()}
            />
          </div>

          {/* Date From */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>DATE FROM</label>
            <input type="date" style={inputStyle} value={pending.date_from}
              onChange={e => setPending(p => ({ ...p, date_from: e.target.value }))} />
          </div>

          {/* Date To */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <label style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>DATE TO</label>
            <input type="date" style={inputStyle} value={pending.date_to}
              onChange={e => setPending(p => ({ ...p, date_to: e.target.value }))} />
          </div>

          {/* Buttons */}
          <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
            <button onClick={handleSearch} style={{ ...btnStyle, background: "#4f46e5", color: "#fff" }}>
              Search
            </button>
            <button onClick={handleReset} style={{ ...btnStyle, background: "#f3f4f6", color: "#374151" }}>
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

        {pagination && (
          <div style={{ fontSize: 13, color: "#6b7280", marginBottom: 8 }}>
            Showing {pagination.from ?? 0}–{pagination.to ?? 0} of {pagination.total ?? 0} records
          </div>
        )}

        {/* Table */}
        <div style={{
          background: "#fff", borderRadius: 10, boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
          overflow: "hidden",
        }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
            <thead>
              <tr style={{ background: "#f9fafb" }}>
                {["Date / Time", "Actor", "Category", "Action", "Target", "Description", "Severity", "Details"].map(col => (
                  <th key={col} style={{
                    padding: "12px 14px", textAlign: "left", fontWeight: 700, fontSize: 12,
                    color: "#6b7280", borderBottom: "1px solid #e5e7eb", whiteSpace: "nowrap",
                  }}>
                    {col}
                  </th>
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
                  <tr key={log.id} style={{ background: i % 2 === 0 ? "#fff" : "#f9fafb" }}>
                    <td style={tdS}>
                      <span style={{ whiteSpace: "nowrap", fontSize: 12 }}>
                        {log.occurred_at ? new Date(log.occurred_at).toLocaleString() : "—"}
                      </span>
                    </td>
                    <td style={tdS}>
                      <div style={{ fontWeight: 600 }}>{log.actor_name || "System"}</div>
                      <div style={{ color: "#9ca3af", fontSize: 11 }}>{log.actor_email || ""}</div>
                    </td>
                    <td style={tdS}>
                      <code style={{ background: "#f3f4f6", padding: "1px 6px", borderRadius: 4, fontSize: 11 }}>
                        {log.category}
                      </code>
                    </td>
                    <td style={tdS}>
                      <code style={{ color: "#4f46e5", fontSize: 11 }}>{log.action}</code>
                    </td>
                    <td style={tdS}>
                      {log.target_type ? (
                        <span>
                          <span style={{ color: "#9ca3af" }}>{log.target_type.split("\\").pop()}</span>
                          {log.target_id && <span style={{ color: "#6b7280" }}> #{log.target_id}</span>}
                        </span>
                      ) : "—"}
                    </td>
                    <td style={{ ...tdS, maxWidth: 240 }}>
                      <span style={{ display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                        {log.description || "—"}
                      </span>
                    </td>
                    <td style={tdS}>
                      <SeverityBadge severity={log.severity} />
                    </td>
                    <td style={tdS}>
                      <button
                        onClick={() => handleViewDetail(log.id)}
                        disabled={detailLoading}
                        style={{
                          background: "#eef2ff", color: "#4f46e5", border: "none",
                          borderRadius: 6, padding: "4px 12px", cursor: "pointer",
                          fontSize: 12, fontWeight: 600,
                        }}
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

        {/* Pagination */}
        {pagination && totalPages > 1 && (
          <div style={{ display: "flex", justifyContent: "center", gap: 6, marginTop: 20, flexWrap: "wrap" }}>
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              style={{ ...btnStyle, background: "#f3f4f6", color: "#374151" }}
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
                  style={{
                    ...btnStyle,
                    background: pg === page ? "#4f46e5" : "#f3f4f6",
                    color: pg === page ? "#fff" : "#374151",
                    minWidth: 36, padding: "0 10px",
                  }}
                >
                  {pg}
                </button>
              );
            })}
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              style={{ ...btnStyle, background: "#f3f4f6", color: "#374151" }}
            >
              Next →
            </button>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {selectedLog && (
        <AuditLogDetailModal log={selectedLog} onClose={() => setSelectedLog(null)} />
      )}
    </MasterLayout>
  );
}

const tdS = {
  padding: "10px 14px", borderBottom: "1px solid #f3f4f6", verticalAlign: "top",
};
