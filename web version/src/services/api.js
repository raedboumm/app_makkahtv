// src/services/api.js
import axios from "axios";

// Detect correct API URL
function inferApiBase() {
  const env = import.meta.env?.VITE_API_URL;
  if (env && env.trim()) return env.replace(/\/$/, ""); // remove trailing slash

  // Local dev (Vite frontend)
  if (window.location.origin.includes("localhost:5173")) {
    return "https://makkah-backend.onrender.com"; // backend is deployed here
  }

  // ✅ Fallback for production (Funio hosting ONLY frontend)
  return "https://makkah-backend.onrender.com";
}

// Base URL + /api
const API_BASE = inferApiBase();
const API_PREFIX = "/api";

export const http = axios.create({
  baseURL: `${API_BASE}${API_PREFIX}`,   // example: https://makkah-backend.onrender.com/api
  timeout: 15000,
});

const api = {
  async get(endpoint, config) {
    const { data } = await http.get(endpoint, config);
    return data;
  },
  async post(endpoint, payload, config) {
    const { data } = await http.post(endpoint, payload, config);
    return data;
  },
};

export default api;
