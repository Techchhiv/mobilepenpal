import API from "../helper/api";

const schoolBillingService = {
  /**
   * Fetch current subscription, history, and invoice metadata for the authenticated school.
   */
  getBillingSummary: () => API.get("/school/billing"),

  /**
   * Get full details for a specific invoice belonging to the authenticated school.
   * @param {number|string} id - Invoice ID
   */
  getInvoiceDetails: (id) => API.get(`/school/billing/invoices/${id}`),

  /**
   * Download the official invoice PDF for the authenticated school.
   * Returns a binary blob response.
   * @param {number|string} id - Invoice ID
   */
  downloadInvoicePdf: (id) =>
    API.get(`/school/billing/invoices/${id}/pdf`, { responseType: "blob" }),
};

export default schoolBillingService;
