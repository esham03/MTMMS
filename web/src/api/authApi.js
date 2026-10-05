import api from "./api";

export const authApi = {
  // Login with credentials directly against Laravel Sanctum
  login: async (credentials) => {
    try {
      const response = await api.post("/auth/login", credentials);
      return response.data;
    } catch (error) {
      if (error.response?.status === 404) {
        // Fallback to /login if /auth/login is not routed
        const fallbackRes = await api.post("/login", credentials);
        return fallbackRes.data;
      }
      throw error;
    }
  },

  // Logout current session on backend
  logout: async () => {
    try {
      await api.post("/auth/logout");
    } catch {
      try {
        await api.post("/logout");
      } catch {}
    } finally {
      localStorage.removeItem("mtmms_token");
      localStorage.removeItem("mtmms_user");
    }
  },

  // Fetch authenticated user profile from backend
  getMe: async () => {
    const response = await api.get("/user");
    return response.data;
  },
};

export default authApi;
