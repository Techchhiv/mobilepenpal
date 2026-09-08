import React from "react";
import "../../assets/css/auditLog.css";

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
    <table className="audit-diff-table">
      <thead>
        <tr>
          <th className="audit-diff-th">Field</th>
          <th className="audit-diff-th" style={{ color: "#b91c1c" }}>Before</th>
          <th className="audit-diff-th" style={{ color: "#15803d" }}>After</th>
        </tr>
      </thead>
      <tbody>
        {keys.map((key) => {
          const before = oldVal?.[key] ?? "—";
          const after  = newVal?.[key] ?? "—";
          const changed = before !== after;
          return (
            <tr key={key} className={changed ? "audit-diff-row-changed" : ""}>
              <td className="audit-diff-td"><strong>{key}</strong></td>
              <td className="audit-diff-td" style={{ color: "#b91c1c" }}>
                {typeof before === "object" ? JSON.stringify(before) : String(before)}
              </td>
              <td className="audit-diff-td" style={{ color: "#15803d" }}>
                {typeof after === "object" ? JSON.stringify(after) : String(after)}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

function InfoRow({ label, value }) {
  if (!value && value !== 0) return null;
  return (
    <div className="audit-info-row">
      <span className="audit-info-label">{label}</span>
      <span className="audit-info-value">{String(value)}</span>
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
    <div className="audit-modal-overlay" onClick={handleOverlayClick}>
      <div className="audit-modal-content">
        {/* Header */}
        <div className="audit-modal-header">
          <div>
            <h3 className="audit-modal-title">
              Audit Log Detail
            </h3>
            <div style={{ display: "flex", gap: 8, marginTop: 4, alignItems: "center" }}>
              <SeverityBadge severity={log.severity} />
              <code style={{ fontSize: 13, color: "#4f46e5", background: "rgba(79,70,229,0.12)", padding: "1px 8px", borderRadius: 4 }}>
                {log.action}
              </code>
            </div>
          </div>
          <button onClick={onClose} className="audit-modal-close">
            ×
          </button>
        </div>

        <div className="audit-modal-body">
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
                <span className="audit-info-label" style={{ display: "block", marginBottom: 4 }}>Snapshot</span>
                <pre className="audit-snapshot-pre">
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
      <h4 className="audit-section-title">
        {title}
      </h4>
      {children}
    </div>
  );
}
