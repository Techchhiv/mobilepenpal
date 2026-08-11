// src/services/auditLogService.js
import API from "../helper/api";

const BASE = "/admin/audit-logs";

/**
 * Fetch paginated audit logs with optional filters.
 * @param {object} params - { search, category, action, severity, actor, school_id, target_type, date_from, date_to, page, per_page }
 */
export const getAuditLogs = (params = {}) => {
  return API.get(BASE + "/", { params });
};

/**
 * Fetch a single audit log by ID.
 */
export const getAuditLog = (id) => {
  return API.get(`${BASE}/${id}`);
};

/**
 * Download filtered audit logs as CSV.
 * Returns a Blob so the caller can trigger a download.
 */
export const exportAuditLogs = async (params = {}) => {
  const response = await API.get(BASE + "/export", {
    params,
    responseType: "blob",
  });
  return response;
};
