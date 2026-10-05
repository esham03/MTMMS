import React, { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  Antenna,
  Plus,
  Radio,
  Edit2,
  Trash2,
  X,
  RefreshCw,
  Phone,
  Mail,
} from "lucide-react";
import DataTable from "../components/DataTable";
import towerApi from "../api/towerApi";

export const Operators = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [operators, setOperators] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("create");
  const [selectedOp, setSelectedOp] = useState(null);

  const [formData, setFormData] = useState({
    name: "",
    short_name: "",
    license_no: "",
    contact_person: "",
    contact_number: "",
    email: "",
  });

  const fetchOperators = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await towerApi.getOperators();
      setOperators(data);
    } catch (e) {
      console.error("Failed to load operators", e);
      setError(e.response?.data?.message || e.message || "Failed to load operators from database.");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOperators();
  }, []);

  const handleOpenCreate = () => {
    setModalMode("create");
    setFormData({
      name: "",
      short_name: "",
      license_no: "",
      contact_person: "",
      contact_number: "",
      email: "",
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (op, e) => {
    e.stopPropagation();
    setModalMode("edit");
    setSelectedOp(op);
    setFormData({
      name: op.name || "",
      short_name: op.short_name || "",
      license_no: op.license_no || "",
      contact_person: op.contact_person || "",
      contact_number: op.contact_number || "",
      email: op.email || "",
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id, e) => {
    e.stopPropagation();
    if (window.confirm("Are you sure you want to remove this licensed operator from the database?")) {
      try {
        await towerApi.deleteOperator(id);
        fetchOperators();
      } catch (err) {
        alert(err.response?.data?.message || "Failed to delete operator.");
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      if (modalMode === "create") {
        await towerApi.createOperator(formData);
      } else {
        await towerApi.updateOperator(selectedOp.id, formData);
      }
      setIsModalOpen(false);
      fetchOperators();
    } catch (err) {
      alert(err.response?.data?.message || "Failed to save operator details.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns = [
    {
      key: "name",
      title: "Telecom Operator",
      render: (val, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: "var(--radius-md)",
              background: "rgba(99, 102, 241, 0.15)",
              color: "var(--primary-light)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontWeight: 800,
              fontSize: "0.85rem",
            }}
          >
            {row.short_name || val?.slice(0, 3).toUpperCase()}
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>{val}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
              License: {row.license_no || "DOIT Certified"}
            </div>
          </div>
        </div>
      ),
    },
    {
      key: "short_name",
      title: "Code",
      render: (val) => (
        <span className="badge badge-info">{val || "OP"}</span>
      ),
    },
    {
      key: "towers_count",
      title: "Towers Used",
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
              border: "1px solid rgba(6, 182, 212, 0.3)",
              background: "rgba(6, 182, 212, 0.12)",
              color: "var(--accent-cyan)",
              fontWeight: 700,
            }}
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/towers?search=${encodeURIComponent(row.name)}`);
            }}
            title={`View all ${count} towers used by ${row.name}`}
          >
            <Radio size={12} />
            <span>{count} Tower{count === 1 ? "" : "s"}</span>
          </button>
        );
      },
    },
    {
      key: "contact_person",
      title: "Nodal Contact",
      render: (val, row) => (
        <div style={{ fontSize: "0.85rem" }}>
          <div style={{ fontWeight: 600 }}>{val || "Circle Officer"}</div>
          <div style={{ color: "var(--text-muted)", fontSize: "0.75rem" }}>
            {row.contact_number} {row.email ? `• ${row.email}` : ""}
          </div>
        </div>
      ),
    },
    {
      key: "actions",
      title: "Actions",
      sortable: false,
      render: (_, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            onClick={(e) => handleOpenEdit(row, e)}
            title="Edit Operator"
          >
            <Edit2 size={14} />
          </button>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            style={{ color: "var(--danger)" }}
            onClick={(e) => handleDelete(row.id, e)}
            title="Delete Operator"
          >
            <Trash2 size={14} />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h1>Telecom Operators Directory</h1>
          <p>Live registry of cellular providers in the MySQL database</p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary btn-sm" onClick={fetchOperators}>
            <RefreshCw size={14} />
            <span>Refresh</span>
          </button>
          <button className="btn btn-primary btn-sm" onClick={handleOpenCreate}>
            <Plus size={15} />
            <span>Register Operator</span>
          </button>
        </div>
      </div>

      {error && (
        <div
          style={{
            background: "var(--danger-bg)",
            border: "1px solid var(--danger-border)",
            color: "#f87171",
            padding: "10px 14px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
          }}
        >
          {error}
        </div>
      )}

      <DataTable
        columns={columns}
        data={operators}
        initialSearch={searchParams.get("search") || searchParams.get("q") || ""}
        searchPlaceholder="Search live operators by name, short code, contact..."
        isLoading={isLoading}
        emptyMessage="No telecom operators recorded in the database yet."
        onRowClick={(row) => navigate(`/towers?search=${encodeURIComponent(row.name)}`)}
      />

      {isModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>
                {modalMode === "create" ? "Register Telecom Operator" : "Edit Operator"}
              </h3>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsModalOpen(false)}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Operator Full Name</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="e.g. Bharti Airtel"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Short Code / Acronym</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.short_name}
                      onChange={(e) =>
                        setFormData({ ...formData, short_name: e.target.value })
                      }
                      placeholder="e.g. Airtel"
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">DOIT License Number</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.license_no}
                    onChange={(e) =>
                      setFormData({ ...formData, license_no: e.target.value })
                    }
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Nodal Contact Person</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.contact_person}
                      onChange={(e) =>
                        setFormData({ ...formData, contact_person: e.target.value })
                      }
                      placeholder="Officer Name"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Phone Number</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.contact_number}
                      onChange={(e) =>
                        setFormData({ ...formData, contact_number: e.target.value })
                      }
                      placeholder="+91 "
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input
                    type="email"
                    className="form-control"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="nodal.officer@operator.com"
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => setIsModalOpen(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary btn-sm"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Saving..." : modalMode === "create" ? "Register Operator" : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Operators;
