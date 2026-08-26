import API from "../helper/api";

const invoiceService = {
  /**
   * Fetch plan prices from backend (USD amounts set in system_settings).
   */
  getPrices: () => API.get("admin/invoices/prices"),

  /**
   * List invoices with optional filters and pagination.
   * @param {Object} params - { invoice_number, customer_name, customer_type, status, plan, date_from, date_to, per_page, page }
   */
  list: (params = {}) => API.get("admin/invoices", { params }),

  /**
   * Get a single invoice by ID.
   */
  get: (id) => API.get(`admin/invoices/${id}`),

  /**
   * Trigger PDF download for an invoice.
   * Returns a blob response.
   */
  downloadPdf: (id) =>
    API.get(`admin/invoices/${id}/pdf`, { responseType: "blob" }),

  /**
   * Void an invoice.
   */
  void: (id, reason, deactivateSubscription = false) =>
    API.post(`admin/invoices/${id}/void`, {
      reason,
      deactivate_subscription: deactivateSubscription,
    }),
};

export default invoiceService;
