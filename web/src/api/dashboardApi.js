import api from "./api";

export const dashboardApi = {
  // Fetch real-time dashboard analytics directly from Laravel backend
  getStats: async () => {
    const response = await api.get("/dashboard");
    return response.data?.data || response.data;
  },
};

export default dashboardApi;
