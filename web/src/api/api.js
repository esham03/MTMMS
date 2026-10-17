import axios from "axios";

/**
 * Dynamic centralized API URL resolution for MTMMS.
 *
 * Priority:
 * 1. Electron Desktop Bridge API (via preload contextBridge)
 * 2. Dynamic Browser Host/Tunnel Detection (e.g. http://<CURRENT_HOST>:8000/api or https://<TUNNEL_DOMAIN>/api)
 * 3. Saved user override in localStorage (if set manually)
 * 4. Vite Environment Variable (import.meta.env.VITE_API_URL)
 * 5. Fallback: http://127.0.0.1:8000/api
 */
export const getBaseUrl = () => {
  // 1. Electron desktop bridge API
  if (typeof window !== "undefined" && window.electronAPI?.apiUrl) {
    return window.electronAPI.apiUrl;
  }

  // 2. Dynamic browser hostname / tunnel detection
  // If the web app is loaded in any browser on any network, route API requests
  // directly to the same host/tunnel origin to ensure it works across all networks.
  if (typeof window !== "undefined" && window.location) {
    const currentHost = window.location.hostname;
    const protocol = window.location.protocol;
    const host = window.location.host;

    if (currentHost && !protocol.startsWith("file")) {
      // Check if accessed through a cloud tunnel (localtunnel, cloudflare, ngrok, etc.)
      if (
        host.includes(".loca.lt") ||
        host.includes(".trycloudflare.com") ||
        host.includes(".ngrok-free.app")
      ) {
        // If web is running through tunnel or environment points to tunnel
        if (import.meta.env?.VITE_TUNNEL_URL) {
          const tUrl = import.meta.env.VITE_TUNNEL_URL.replace(/\/+$/, "");
          return `${tUrl}/api`;
        }
        return `${window.location.origin}/api`;
      }

      // If running on local network IP (e.g. 192.168.x.x, 10.x.x.x, 172.x.x.x) or localhost
      const apiPort = import.meta.env?.VITE_API_PORT || 8000;
      return `http://${currentHost}:${apiPort}/api`;
    }
  }

  // 3. Saved user override in localStorage (if valid)
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
    if (config.baseURL && config.baseURL.includes(".loca.lt")) {
      config.headers["Bypass-Tunnel-Reminder"] = "true";
    }
    const token =
      localStorage.getItem("token") ||
      localStorage.getItem("mtmms_token") ||
      sessionStorage.getItem("mtmms_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Format standard error structures
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      localStorage.removeItem("mtmms_token");
      localStorage.removeItem("mtmms_user");
      sessionStorage.removeItem("mtmms_token");
      sessionStorage.removeItem("mtmms_user");
      if (
        typeof window !== "undefined" &&
        !window.location.pathname.includes("/login")
      ) {
        window.location.href = "/login";
      }
    }

    const message =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message ||
      "An unexpected network error occurred";

    return Promise.reject({
      ...error,
      customMessage: message,
    });
  }
);

export default api;
