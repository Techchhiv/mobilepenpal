import React from "react";

const SEVERITY_STYLES = {
  info:     { bg: "#e0f2fe", color: "#0369a1", label: "INFO" },
  warning:  { bg: "#fef9c3", color: "#b45309", label: "WARNING" },
  critical: { bg: "#fee2e2", color: "#b91c1c", label: "CRITICAL" },
};

function SeverityBadge({ severity }) {
  const s = SEVERITY_STYLES[severity] || SEVERITY_STYLES.info;
  return (
    <span style={{
      background: s.bg, color: s.color, fontWeight: 700,
      borderRadius: 6, padding: "2px 10px", fontSize: 12, letterSpacing: 0.5,
    }}>
      {s.label}
    </span>
  );
}

function DiffTable({ old: oldVal, newVal }) {
  if (!oldVal && !newVal) return <span style={{ color: "#9ca3af" }}>—</span>;

  const keys = Array.from(new Set([
    ...Object.keys(oldVal || {}),
    ...Object.keys(newVal || {}),
  ]));

  if (keys.length === 0) return <span style={{ color: "#9ca3af" }}>—</span>;

  return (
    <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
      <thead>
        <tr>
          <th style={thStyle}>Field</th>
          <th style={{ ...thStyle, color: "#b91c1c" }}>Before</th>
          <th style={{ ...thStyle, color: "#15803d" }}>After</th>
        </tr>
      </thead>
      <tbody>
        {keys.map((key) => {
          const before = oldVal?.[key] ?? "—";
          const after  = newVal?.[key] ?? "—";
          const changed = before !== after;
          return (
            <tr key={key} style={{ background: changed ? "#fffbeb" : "transparent" }}>
              <td style={tdStyle}><strong>{key}</strong></td>
              <td style={{ ...tdStyle, color: "#b91c1c" }}>
                {typeof before === "object" ? JSON.stringify(before) : String(before)}
              </td>
              <td style={{ ...tdStyle, color: "#15803d" }}>
                {typeof after === "object" ? JSON.stringify(after) : String(after)}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

const thStyle = {
  padding: "6px 10px", background: "#f3f4f6", textAlign: "left",
  fontWeight: 600, borderBottom: "1px solid #e5e7eb", fontSize: 12,
};
const tdStyle = {
  padding: "5px 10px", borderBottom: "1px solid #f3f4f6",
  wordBreak: "break-all",
};

function InfoRow({ label, value }) {
  if (!value && value !== 0) return null;
  return (
    <div style={{ display: "flex", gap: 8, padding: "6px 0", borderBottom: "1px solid #f3f4f6", alignItems: "flex-start" }}>
      <span style={{ minWidth: 140, fontWeight: 600, color: "#6b7280", fontSize: 13 }}>{label}</span>
      <span style={{ color: "#111827", fontSize: 13, wordBreak: "break-all" }}>{String(value)}</span>
    </div>
  );
}

export default function AuditLogDetailModal({ log, onClose }) {
  if (!log) return null;

  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) onClose();
  };

  const roles = Array.isArray(log.actor_roles) ? log.actor_roles.join(", ") : "—";
  const oldValues = log.old_values || null;
  const newValues = log.new_values || null;
  const metadata  = log.metadata || null;

  return (
    <div
      onClick={handleOverlayClick}
      style={{
        position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)",
        display: "flex", alignItems: "center", justifyContent: "center",
        zIndex: 9999, padding: 16,
      }}
    >
      <div style={{
        background: "#fff", borderRadius: 12, width: "100%", maxWidth: 780,
        maxHeight: "90vh", overflowY: "auto", boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
      }}>
        {/* Header */}
        <div style={{
          display: "flex", justifyContent: "space-between", alignItems: "center",
          padding: "20px 24px", borderBottom: "1px solid #e5e7eb",
          position: "sticky", top: 0, background: "#fff", zIndex: 1,
        }}>
          <div>
            <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: "#111827" }}>
              Audit Log Detail
            </h3>
            <div style={{ display: "flex", gap: 8, marginTop: 4, alignItems: "center" }}>
              <SeverityBadge severity={log.severity} />
              <code style={{ fontSize: 13, color: "#4f46e5", background: "#eef2ff", padding: "1px 8px", borderRadius: 4 }}>
                {log.action}
              </code>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              background: "none", border: "none", cursor: "pointer",
              fontSize: 22, color: "#9ca3af", lineHeight: 1,
            }}
          >
            ×
          </button>
        </div>

        <div style={{ padding: 24 }}>
          {/* Event Info */}
          <Section title="Event Information">
            <InfoRow label="Event UUID"   value={log.event_uuid} />
            <InfoRow label="Category"     value={log.category} />
            <InfoRow label="Action"       value={log.action} />
            <InfoRow label="Occurred At"  value={log.occurred_at} />
            <InfoRow label="Description"  value={log.description} />
          </Section>

          {/* Actor */}
          <Section title="Performed By">
            <InfoRow label="Name"   value={log.actor_name || "—"} />
            <InfoRow label="Email"  value={log.actor_email || "—"} />
            <InfoRow label="Roles"  value={roles || "—"} />
            <InfoRow label="Actor ID"    value={log.actor_id} />
          </Section>

          {/* Target */}
          <Section title="Target">
            <InfoRow label="Type" value={log.target_type || "—"} />
            <InfoRow label="ID"   value={log.target_id} />
            {metadata && (
              <div style={{ marginTop: 8 }}>
                <span style={{ fontWeight: 600, color: "#6b7280", fontSize: 13 }}>Snapshot</span>
                <pre style={{
                  background: "#f9fafb", borderRadius: 6, padding: "10px 14px",
                  fontSize: 12, overflowX: "auto", marginTop: 4, color: "#111827",
                }}>
                  {JSON.stringify(metadata, null, 2)}
                </pre>
              </div>
            )}
          </Section>

          {/* Changes */}
          {(oldValues || newValues) && (
            <Section title="Changes (Before → After)">
              <DiffTable old={oldValues} newVal={newValues} />
            </Section>
          )}

          {/* Request Info */}
          <Section title="Request Information">
            <InfoRow label="IP Address"  value={log.ip_address} />
            <InfoRow label="HTTP Method" value={log.http_method} />
            <InfoRow label="Route"       value={log.route} />
            <InfoRow label="Source"      value={log.source} />
            <InfoRow label="Request ID"  value={log.request_id} />
            <InfoRow label="User Agent"  value={log.user_agent} />
          </Section>
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <h4 style={{
        fontSize: 13, fontWeight: 700, color: "#6b7280", textTransform: "uppercase",
        letterSpacing: 0.8, margin: "0 0 10px", paddingBottom: 6,
        borderBottom: "2px solid #e5e7eb",
      }}>
        {title}
      </h4>
      {children}
    </div>
  );
}
