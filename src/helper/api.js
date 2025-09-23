// src/helper/api.js
import axios from "axios";

// Works in both Vite and CRA
const viteEnv = (typeof import.meta !== "undefined" && import.meta.env) || {};
const API_BASE =
  viteEnv.VITE_API_BASE ||
  viteEnv.VITE_APP_API_BASE ||              // just in case you used this name
  process.env.REACT_APP_API_BASE ||         // CRA style
  "http://127.0.0.1:8000/api";              // fallback

const API = axios.create({
  baseURL: API_BASE,
  headers: { Accept: "application/json" },
  withCredentials: false, // ⬅️ we're using Bearer tokens, not cookies
});

// Persist/clear the Bearer token
export const setAuthToken = (token) => {
  if (token) {
    API.defaults.headers.common.Authorization = `Bearer ${token}`;
    localStorage.setItem("token", token);
  } else {
    delete API.defaults.headers.common.Authorization;
    localStorage.removeItem("token");
  }
};

// Bootstrap from localStorage on app load
const saved = localStorage.getItem("token");
if (saved) setAuthToken(saved);

export default API;
