import api from "./api";

const extractArray = (res) => {
  if (!res) return [];
  const body = res.data ?? res;
  if (Array.isArray(body)) return body;
  if (Array.isArray(body?.data)) return body.data;
  if (Array.isArray(body?.results)) return body.results;
  return [];
};

const extractObject = (res) => {
  if (!res) return null;
  const body = res.data ?? res;
  if (body?.data && typeof body.data === "object" && !Array.isArray(body.data)) {
    return body.data;
  }
  return body;
};

export const rentApi = {
  // Get all rent payments with filtering from backend
  getPayments: async (params = {}) => {
    const queryParams = { all: true, ...params };
    const response = await api.get("/rent-payments", { params: queryParams });
    return extractArray(response);
  },

  // Get single payment details
  getPayment: async (id) => {
    const response = await api.get(`/rent-payments/${id}`);
    return extractObject(response);
  },

  // Record a payment directly in backend
  createPayment: async (payload) => {
    const response = await api.post("/rent-payments", payload);
    return extractObject(response);
  },

  // Update payment record
  updatePayment: async (id, payload) => {
    const response = await api.put(`/rent-payments/${id}`, payload);
    return extractObject(response);
  },

  // Delete payment record
  deletePayment: async (id) => {
    const response = await api.delete(`/rent-payments/${id}`);
    return response.data;
  },

  // Tower specific rent info
  getTowerRent: async (towerId) => {
    const response = await api.get(`/towers/${towerId}/rent`);
    return extractObject(response);
  },

  // Tower specific payment history
  getTowerPayments: async (towerId) => {
    const response = await api.get(`/towers/${towerId}/payments`);
    return extractArray(response);
  },
};

export default rentApi;
