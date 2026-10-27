import React, { useState, useEffect, useMemo } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  Building2,
  Plus,
  Phone,
  Mail,
  Edit2,
  Trash2,
  X,
  User,
  Radio,
  RefreshCw,
  AlertTriangle,
  Landmark,
  Shield,
  MapPin,
} from "lucide-react";
import DataTable from "../components/DataTable";
import towerApi from "../api/towerApi";

export const Owners = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [owners, setOwners] = useState([]);
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("create");
  const [selectedOwner, setSelectedOwner] = useState(null);

  const [formData, setFormData] = useState({
    name: "",
    type: "private",
    contact_number: "",
    email: "",
    address: "",
  });

  const fetchOwners = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await towerApi.getOwners();
      setOwners(Array.isArray(data) ? data : []);
    } catch (e) {
      console.error("Failed to load owners", e);
      setError(e.response?.data?.message || e.message || "Failed to load owners from database.");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOwners();
  }, []);

  // Helper to reliably get owner category / entity type
  const getOwnerType = (o) => {
    const rawType = (o?.type || "").toLowerCase().trim();
    if (rawType && ["government", "private", "panchayat", "municipality"].includes(rawType)) {
      return rawType;
    }
    // Fallback: Check associated towers' land_type
    const towersList = Array.isArray(o?.towers) ? o.towers : [];
    if (towersList.length > 0) {
      const land = (towersList[0]?.land_type || "").toLowerCase().trim();
      if (land === "government") return "government";
      if (land === "panchayat" || land === "village") return "panchayat";
      if (land === "municipality") return "municipality";
      if (land === "private") return "private";
    }
    // Default fallback to government if associated with a govt site, else private
    return rawType || "government";
  };

  const getOwnerTowerCount = (o) => {
    if (o?.towers_count !== undefined && o?.towers_count !== null) return Number(o.towers_count);
    if (Array.isArray(o?.towers)) return o.towers.length;
    return 0;
  };

  // Filtered owners list
  const filteredOwners = useMemo(() => {
    if (categoryFilter === "all") return owners;
    return owners.filter((o) => {
      const t = getOwnerType(o);
      if (categoryFilter === "panchayat_municipality") {
        return t === "panchayat" || t === "municipality";
      }
      return t === categoryFilter.toLowerCase();
    });
  }, [owners, categoryFilter]);

  // Total Metrics
  const totalCount = owners.length;
  const totalTowersCount = owners.reduce((sum, o) => sum + getOwnerTowerCount(o), 0);

  // Group metrics
  const govtOwners = owners.filter((o) => getOwnerType(o) === "government");
  const pvtOwners = owners.filter((o) => getOwnerType(o) === "private");
  const panchayatOwners = owners.filter((o) => {
    const t = getOwnerType(o);
    return t === "panchayat" || t === "municipality";
  });

  const govtCount = govtOwners.length;
  const privateCount = pvtOwners.length;
  const panchayatCount = panchayatOwners.length;

  const govtTowersCount = govtOwners.reduce((sum, o) => sum + getOwnerTowerCount(o), 0);
  const pvtTowersCount = pvtOwners.reduce((sum, o) => sum + getOwnerTowerCount(o), 0);
  const panchayatTowersCount = panchayatOwners.reduce((sum, o) => sum + getOwnerTowerCount(o), 0);

  const getOwnerPhone = (o) => {
    if (!o) return "";
    return o.contact_number || o.phone || o.contact_no || o.phone_number || o.mobile || o.contact || "";
  };

  const handleOpenCreate = () => {
    setModalMode("create");
    setFormData({
      name: "",
      type: "government",
      contact_number: "",
      email: "",
      address: "",
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (owner, e) => {
    if (e) e.stopPropagation();
    setModalMode("edit");
    setSelectedOwner(owner);
    setFormData({
      name: owner.name || "",
      type: getOwnerType(owner),
      contact_number: getOwnerPhone(owner),
      email: owner.email || "",
      address: owner.address || "",
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id, name, e) => {
    if (e) e.stopPropagation();
    if (window.confirm(`Are you sure you want to delete owner "${name || "this owner"}"? This action cannot be undone.`)) {
      try {
        await towerApi.deleteOwner(id);
        fetchOwners();
      } catch (err) {
        if (err.response?.status === 401) {
          alert("Your session has expired. Please sign in again.");
        } else {
          alert(err.response?.data?.message || "Failed to delete owner.");
        }
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      alert("Please enter the Owner / Entity Name.");
      return;
    }
    setIsSubmitting(true);
    try {
      const payload = {
        name: formData.name.trim(),
        type: formData.type,
        contact_number: formData.contact_number.trim(),
        phone: formData.contact_number.trim(),
        contact_no: formData.contact_number.trim(),
        phone_number: formData.contact_number.trim(),
        mobile: formData.contact_number.trim(),
        contact: formData.contact_number.trim(),
        email: formData.email.trim(),
        address: formData.address.trim(),
      };

      if (modalMode === "create") {
        await towerApi.createOwner(payload);
      } else {
        await towerApi.updateOwner(selectedOwner.id, payload);
      }
      setIsModalOpen(false);
      fetchOwners();
    } catch (err) {
      if (err.response?.status === 401) {
        alert("Your session has expired. Please sign in again.");
      } else {
        alert(err.response?.data?.message || err.message || "Failed to save owner details.");
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns = [
    {
      key: "name",
      title: "Owner / Entity",
      render: (val, row) => {
        const typeStr = getOwnerType(row);
        const isGovt = typeStr === "government";
        const isPanchayat = typeStr === "panchayat" || typeStr === "municipality";

        return (
          <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 180 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: "var(--radius-md)",
                background: isGovt
                  ? "rgba(16, 185, 129, 0.15)"
                  : isPanchayat
                  ? "rgba(245, 158, 11, 0.15)"
                  : "rgba(6, 182, 212, 0.15)",
                color: isGovt
                  ? "#10b981"
                  : isPanchayat
                  ? "var(--warning)"
                  : "var(--accent-cyan)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              {isGovt ? <Shield size={18} /> : isPanchayat ? <Landmark size={18} /> : <User size={18} />}
            </div>
            <div>
              <div style={{ fontWeight: 700, color: "var(--text-primary)", whiteSpace: "nowrap" }}>{val}</div>
              <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                {row.address ? row.address.slice(0, 35) : "Goa Region"}
              </div>
            </div>
          </div>
        );
      },
    },
    {
      key: "type",
      title: "Category",
      render: (val, row) => {
        const typeStr = getOwnerType(row);
        if (typeStr === "government") {
          return <span className="badge badge-success" style={{ whiteSpace: "nowrap" }}>• Government Body</span>;
        }
        if (typeStr === "panchayat") {
          return <span className="badge badge-warning" style={{ whiteSpace: "nowrap" }}>• Village Panchayat</span>;
        }
        if (typeStr === "municipality") {
          return <span className="badge badge-warning" style={{ whiteSpace: "nowrap" }}>• Municipal Council</span>;
        }
        return <span className="badge badge-info" style={{ whiteSpace: "nowrap" }}>• Private Owner</span>;
      },
    },
    {
      key: "towers_count",
      title: "Towers Installed",
      render: (val, row) => {
        const count = val !== undefined ? val : (Array.isArray(row.towers) ? row.towers.length : 0);
        return (
          <button
            type="button"
            className="badge badge-info"
            style={{
              cursor: "pointer",
              display: "inline-flex",
              alignItems: "center",
              gap: 5,
              padding: "4px 10px",
              border: "1px solid rgba(99, 102, 241, 0.3)",
              background: "rgba(99, 102, 241, 0.12)",
              color: "var(--primary-light)",
              fontWeight: 700,
            }}
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/towers?search=${encodeURIComponent(row.name)}`);
            }}
            title={`View all ${count} towers owned or managed by ${row.name}`}
          >
            <Radio size={12} />
            <span>{count} Tower{count === 1 ? "" : "s"}</span>
          </button>
        );
      },
    },
    {
      key: "contact_number",
      title: "Contact Phone",
      render: (val, row) => {
        const phone = getOwnerPhone(row) || val;
        return (
          <div style={{ display: "flex", alignItems: "center", gap: 6, whiteSpace: "nowrap" }}>
            <Phone size={13} color="var(--accent-cyan)" />
            <span style={{ fontWeight: 600 }}>{phone || "N/A"}</span>
          </div>
        );
      },
    },
    {
      key: "email",
      title: "Official Email",
      render: (val) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--text-muted)", fontSize: "0.82rem", whiteSpace: "nowrap" }}>
          <Mail size={13} />
          <span>{val || "N/A"}</span>
        </div>
      ),
    },
    {
      key: "address",
      title: "Registered Address",
      render: (val) => (
        <div style={{ fontSize: "0.82rem", color: "var(--text-secondary)", maxWidth: 220 }}>
          {val || "Goa, India"}
        </div>
      ),
    },
    {
      key: "actions",
      title: "Actions",
      sortable: false,
      render: (_, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6, justifyContent: "flex-end", whiteSpace: "nowrap" }}>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            onClick={(e) => handleOpenEdit(row, e)}
            title="Edit Owner Details"
          >
            <Edit2 size={14} />
          </button>
          <button
            className="btn btn-danger btn-icon btn-sm"
            onClick={(e) => handleDelete(row.id, row.name, e)}
            title="Delete Owner Record"
          >
            <Trash2 size={14} />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Tower & Land Owners</h1>
          <p>Official registry of government bodies, private property owners, panchayats, and municipalities</p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary" onClick={fetchOwners} disabled={isLoading}>
            <RefreshCw size={15} className={isLoading ? "animate-spin" : ""} />
            <span>Refresh</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Register New Owner</span>
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid-cols-4" style={{ marginBottom: 24 }}>
        <div className="card" style={{ padding: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: "0.78rem", fontWeight: 700, color: "var(--text-secondary)", textTransform: "uppercase" }}>
                Total Towers
              </div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, marginTop: 4 }}>
                {totalTowersCount || totalCount}
              </div>
              <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 2 }}>
                {totalCount} Registered Owner{totalCount === 1 ? "" : "s"}
              </div>
            </div>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: "var(--radius-md)",
                background: "rgba(6, 182, 212, 0.15)",
                color: "var(--accent-cyan)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Radio size={22} />
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: "0.78rem", fontWeight: 700, color: "var(--text-secondary)", textTransform: "uppercase" }}>
                Government Bodies
              </div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#10b981", marginTop: 4 }}>
                {govtTowersCount || govtCount}
              </div>
              <div style={{ fontSize: "0.75rem", color: "#10b981", marginTop: 2 }}>
                {govtCount} Entity • {govtTowersCount} Tower{govtTowersCount === 1 ? "" : "s"}
              </div>
            </div>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: "var(--radius-md)",
                background: "rgba(16, 185, 129, 0.15)",
                color: "#10b981",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Shield size={22} />
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: "0.78rem", fontWeight: 700, color: "var(--text-secondary)", textTransform: "uppercase" }}>
                Private Owners
              </div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#38bdf8", marginTop: 4 }}>
                {pvtTowersCount || privateCount}
              </div>
              <div style={{ fontSize: "0.75rem", color: "#38bdf8", marginTop: 2 }}>
                {privateCount} Owner{privateCount === 1 ? "" : "s"} • {pvtTowersCount} Tower{pvtTowersCount === 1 ? "" : "s"}
              </div>
            </div>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: "var(--radius-md)",
                background: "rgba(56, 189, 248, 0.15)",
                color: "#38bdf8",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <User size={22} />
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: "0.78rem", fontWeight: 700, color: "var(--text-secondary)", textTransform: "uppercase" }}>
                Panchayats / Municipalities
              </div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#f59e0b", marginTop: 4 }}>
                {panchayatTowersCount || panchayatCount}
              </div>
              <div style={{ fontSize: "0.75rem", color: "#f59e0b", marginTop: 2 }}>
                {panchayatCount} Local Bod{panchayatCount === 1 ? "y" : "ies"} • {panchayatTowersCount} Tower{panchayatTowersCount === 1 ? "" : "s"}
              </div>
            </div>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: "var(--radius-md)",
                background: "rgba(245, 158, 11, 0.15)",
                color: "#f59e0b",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Landmark size={22} />
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div
          className="badge-danger"
          style={{
            padding: "12px 16px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <AlertTriangle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* Main DataTable */}
      <DataTable
        columns={columns}
        data={filteredOwners}
        initialSearch={searchParams.get("search") || searchParams.get("q") || ""}
        searchPlaceholder="Search owners & companies by name, contact, email, address..."
        isLoading={isLoading}
        emptyMessage="No tower or land owners recorded yet. Click 'Register New Owner' to add."
        onRowClick={(row) => navigate(`/towers?search=${encodeURIComponent(row.name)}`)}
        filterSlot={
          <select
            className="form-select form-select-sm"
            style={{ width: "auto" }}
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="all">All Owner Categories</option>
            <option value="government">Government Bodies</option>
            <option value="private">Private Owners</option>
            <option value="panchayat_municipality">Panchayats & Municipalities</option>
            <option value="panchayat">Village Panchayats</option>
            <option value="municipality">Municipal Councils</option>
          </select>
        }
      />

      {/* Register / Edit Owner Modal */}
      {isModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" style={{ maxWidth: 540 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <h2>
                  {modalMode === "create" ? "Register Tower / Land Owner" : "Edit Owner Details"}
                </h2>
                <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginTop: 2 }}>
                  {modalMode === "create"
                    ? "Add a new infrastructure owner or landowner entity into the registry"
                    : `Updating owner records for ${selectedOwner?.name}`}
                </p>
              </div>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsModalOpen(false)}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Owner / Entity Name *</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Goa Telecom Infrastructure Corp / John D'Souza"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Owner Category *</label>
                    <select
                      className="form-select"
                      value={formData.type}
                      onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                    >
                      <option value="private">Private Property Owner</option>
                      <option value="government">Government Body / Public Sector</option>
                      <option value="panchayat">Village Panchayat</option>
                      <option value="municipality">Municipal Council</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Contact Phone Number</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.contact_number}
                      onChange={(e) => setFormData({ ...formData, contact_number: e.target.value })}
                      placeholder="e.g. +91 9876543210"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Official Email Address</label>
                  <input
                    type="email"
                    className="form-control"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="e.g. contact@entity.gov.in / owner@gmail.com"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Physical / Registered Postal Address</label>
                  <textarea
                    className="form-control"
                    rows={3}
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    placeholder="e.g. Plot No. 12, EDC Complex, Patto Plaza, Panaji, Goa - 403001"
                  ></textarea>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setIsModalOpen(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={isSubmitting}
                >
                  {isSubmitting
                    ? "Saving Owner..."
                    : modalMode === "create"
                    ? "Register Owner"
                    : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Owners;
