import axios from "axios";

/**
 * Dynamic centralized API URL resolution for MTMMS.
 *
 * Priority:
 * 1. Electron Desktop Bridge API (via preload contextBridge)
 * 2. Dynamic Browser Host Detection (e.g. http://<CURRENT_HOST>:8000/api)
 * 3. Vite Environment Variable (import.meta.env.VITE_API_URL)
 * 4. LocalStorage manual override (if set)
 * 5. Fallback: http://127.0.0.1:8000/api
 */
export const getBaseUrl = () => {
  // 1. Electron desktop bridge API
  if (typeof window !== "undefined" && window.electronAPI?.apiUrl) {
    return window.electronAPI.apiUrl;
  }

  // 2. Saved user override in localStorage (if valid)
  if (typeof window !== "undefined" && window.localStorage) {
    const saved = localStorage.getItem("mtmms_api_url");
    if (
      saved &&
      (saved.startsWith("http://") || saved.startsWith("https://")) &&
      !saved.includes("42web.io") &&
      !saved.includes("infinityfree")
    ) {
      return saved;
    }
  }

  // 3. Dynamic browser hostname detection
  // If the web app was opened in a browser (e.g. http://192.168.1.15:5174/ or http://172.20.10.2:5174/),
  // automatically route API requests to that same server host on port 8000.
  if (typeof window !== "undefined" && window.location) {
    const currentHost = window.location.hostname;
    const protocol = window.location.protocol;

    if (currentHost && !protocol.startsWith("file")) {
      const apiPort = import.meta.env?.VITE_API_PORT || 8000;
      return `http://${currentHost}:${apiPort}/api`;
    }
  }

  // 4. Explicit Vite environment variable
  if (import.meta.env?.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  if (import.meta.env?.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL;
  }

  return "http://127.0.0.1:8000/api";
};

export const setBaseUrl = (url) => {
  let cleaned = (url || "").trim();
  while (cleaned.endsWith("/")) {
    cleaned = cleaned.slice(0, -1);
  }
  if (!cleaned.endsWith("/api")) {
    cleaned = `${cleaned}/api`;
  }
  localStorage.setItem("mtmms_api_url", cleaned);
  api.defaults.baseURL = cleaned;
  return cleaned;
};

const api = axios.create({
  baseURL: getBaseUrl(),
  timeout: 15000,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

// Request Interceptor: Attach Auth Token and ensure current baseURL
api.interceptors.request.use(
  (config) => {
    config.baseURL = getBaseUrl();
    const token =
      localStorage.getItem("mtmms_token") ||
      sessionStorage.getItem("mtmms_token");
    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Global response handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token on 401 if not already on login page
      if (typeof window !== "undefined" && window.location.pathname !== "/login") {
        localStorage.removeItem("mtmms_token");
        localStorage.removeItem("mtmms_user");
        sessionStorage.removeItem("mtmms_token");
        sessionStorage.removeItem("mtmms_user");
        window.dispatchEvent(new Event("auth_invalid"));
      }
    }
    return Promise.reject(error);
  }
);

export default api;
