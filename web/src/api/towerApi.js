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

export const towerApi = {
  // Fetch towers with query filters (district_id, constituency_id, taluka_id, area_id, land_type, status, search, etc.)
  getTowers: async (params = {}) => {
    const queryParams = { all: true, ...params };
    const response = await api.get("/towers", { params: queryParams });
    return extractArray(response);
  },

  // Fetch single tower details with relationships
  getTower: async (id) => {
    const response = await api.get(`/towers/${id}`);
    return extractObject(response);
  },

  // Create new tower in backend
  createTower: async (payload) => {
    const response = await api.post("/towers", payload);
    return extractObject(response);
  },

  // Update existing tower
  updateTower: async (id, payload) => {
    const response = await api.put(`/towers/${id}`, payload);
    return extractObject(response);
  },

  // Delete / decommission tower
  deleteTower: async (id) => {
    const response = await api.delete(`/towers/${id}`);
    return response.data;
  },

  // Assign / Synchronize operators using this tower
  syncTowerOperators: async (towerId, operatorIds) => {
    const response = await api.post(`/towers/${towerId}/operators`, {
      operator_ids: operatorIds,
    });
    return extractObject(response);
  },

  // Geographical Locations
  getDistricts: async () => {
    const response = await api.get("/districts");
    return extractArray(response);
  },

  getConstituencies: async (districtId = null) => {
    const response = await api.get("/constituencies", {
      params: districtId ? { district_id: districtId } : {},
    });
    return extractArray(response);
  },

  getTalukas: async (params = {}) => {
    const queryParams = typeof params === "object" ? params : { district_id: params };
    const response = await api.get("/talukas", {
      params: queryParams,
    });
    return extractArray(response);
  },

  getAreas: async (talukaId = null) => {
    const response = await api.get("/areas", {
      params: talukaId ? { taluka_id: talukaId } : {},
    });
    return extractArray(response);
  },

  // Tower / Land Owners
  getOwners: async (params = {}) => {
    const queryParams = { all: true, ...params };
    const response = await api.get("/owners", { params: queryParams });
    return extractArray(response);
  },

  createOwner: async (payload) => {
    const response = await api.post("/owners", payload);
    return extractObject(response);
  },

  updateOwner: async (id, payload) => {
    const response = await api.put(`/owners/${id}`, payload);
    return extractObject(response);
  },

  deleteOwner: async (id) => {
    const response = await api.delete(`/owners/${id}`);
    return response.data;
  },

  // Telecom Operators
  getOperators: async (params = {}) => {
    const queryParams = { all: true, ...params };
    const response = await api.get("/operators", { params: queryParams });
    return extractArray(response);
  },

  createOperator: async (payload) => {
    const response = await api.post("/operators", payload);
    return extractObject(response);
  },

  updateOperator: async (id, payload) => {
    const response = await api.put(`/operators/${id}`, payload);
    return extractObject(response);
  },

  deleteOperator: async (id) => {
    const response = await api.delete(`/operators/${id}`);
    return response.data;
  },
};

export default towerApi;
