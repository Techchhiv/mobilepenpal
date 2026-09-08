// baseUrl.js

const rawApiUrl =
  (typeof import.meta !== "undefined" && import.meta.env?.VITE_API_BASE) ||
  process.env.REACT_APP_API_URL ||
  "http://127.0.0.1:8000/api";

const API_BASE_URL = rawApiUrl.replace(/\/api\/?$/, "");

export default API_BASE_URL;
