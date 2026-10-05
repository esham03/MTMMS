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

export const userApi = {
  // Get all authorized users / officers
  getUsers: async (params = {}) => {
    const response = await api.get("/users", { params: { per_page: 100, ...params } });
    return extractArray(response);
  },

  // Create a new authorized officer with login credentials
  createUser: async (userData) => {
    const response = await api.post("/users", userData);
    return extractObject(response);
  },

  // Update existing officer details / role / department / password
  updateUser: async (id, userData) => {
    const response = await api.put(`/users/${id}`, userData);
    return extractObject(response);
  },

  // Delete / revoke an authorized officer
  deleteUser: async (id) => {
    const response = await api.delete(`/users/${id}`);
    return response.data;
  },

  // Reset officer password
  resetPassword: async (id, newPassword) => {
    const response = await api.post(`/users/${id}/reset-password`, {
      password: newPassword,
    });
    return response.data;
  },
};

export default userApi;
