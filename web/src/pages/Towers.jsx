import React, { useState, useEffect, useMemo, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  Radio,
  Plus,
  Eye,
  Edit2,
  Trash2,
  MapPin,
  AlertTriangle,
  X,
  RefreshCw,
} from "lucide-react";
import DataTable from "../components/DataTable";
import towerApi from "../api/towerApi";
import { GOA_EXACT_LOCATION_COORDS } from "./MapView";

export const Towers = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [towers, setTowers] = useState([]);
  const [districts, setDistricts] = useState([]);
  const [talukas, setTalukas] = useState([]);
  const [constituencies, setConstituencies] = useState([]);
  const [areas, setAreas] = useState([]);
  const [owners, setOwners] = useState([]);
  const [operators, setOperators] = useState([]);

  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);

  // Filters
  const [landFilter, setLandFilter] = useState(searchParams.get("land_type") || "all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [districtFilter, setDistrictFilter] = useState("all");
  const [companyFilter, setCompanyFilter] = useState(
    searchParams.get("company") || searchParams.get("operator") || (searchParams.get("operator_id") ? `op_id:${searchParams.get("operator_id")}` : "all")
  );
  const [searchTerm, setSearchTerm] = useState(
    searchParams.get("search") || searchParams.get("q") || ""
  );

  useEffect(() => {
    const q = searchParams.get("search") || searchParams.get("q");
    if (q !== null && q !== undefined) {
      setSearchTerm(q);
    }
    const comp = searchParams.get("company") || searchParams.get("operator");
    if (comp) {
      setCompanyFilter(comp);
    } else if (searchParams.get("operator_id")) {
      setCompanyFilter(`op_id:${searchParams.get("operator_id")}`);
    }
  }, [searchParams]);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(searchParams.get("action") === "create");
  const [modalMode, setModalMode] = useState("create"); // 'create' | 'edit'
  const [selectedTower, setSelectedTower] = useState(null);
  const [heightUnit, setHeightUnit] = useState("m"); // 'm' | 'ft'
  const [widthUnit, setWidthUnit] = useState("m");   // 'm' | 'ft'

  const handleSwitchHeightUnit = (newUnit) => {
    if (newUnit === heightUnit) return;
    const currentVal = parseFloat(formData.height);
    if (!isNaN(currentVal) && currentVal > 0) {
      const converted = newUnit === "ft" ? (currentVal * 3.28084).toFixed(1) : (currentVal * 0.3048).toFixed(1);
      setFormData((prev) => ({ ...prev, height: converted }));
    }
    setHeightUnit(newUnit);
  };

  const handleSwitchWidthUnit = (newUnit) => {
    if (newUnit === widthUnit) return;
    const currentVal = parseFloat(formData.width);
    if (!isNaN(currentVal) && currentVal > 0) {
      const converted = newUnit === "ft" ? (currentVal * 3.28084).toFixed(1) : (currentVal * 0.3048).toFixed(1);
      setFormData((prev) => ({ ...prev, width: converted }));
    }
    setWidthUnit(newUnit);
  };

  // Form State
  const initialFormState = {
    tower_unique_id: "",
    district_id: "",
    taluka_id: "",
    constituency_id: "",
    area_id: "",
    owner_id: "",
    land_type: "government",
    height: "",
    width: "",
    frequency: "4G/5G",
    status: "active",
    yearly_rent: "",
    rent_cycle_years: 1,
    installation_date: new Date().toISOString().split("T")[0],
    rent_start_date: new Date().toISOString().split("T")[0],
    address: "",
    latitude: "",
    longitude: "",
    operator_ids: [],
  };

  const [formData, setFormData] = useState(initialFormState);

  // Auto-detect exact GPS coordinates from selected Area or Address
  const handleAutoFillGps = (areaId = formData.area_id, address = formData.address) => {
    const selectedArea = areas.find((a) => String(a.id) === String(areaId));
    const areaName = String(selectedArea?.name || "").toLowerCase().trim();
    const addr = String(address || "").toLowerCase().trim();

    let matched = null;
    for (const [key, coords] of Object.entries(GOA_EXACT_LOCATION_COORDS)) {
      if (key.length > 5 && addr.includes(key)) {
        matched = coords;
        break;
      }
    }
    if (!matched && areaName && GOA_EXACT_LOCATION_COORDS[areaName]) {
      matched = GOA_EXACT_LOCATION_COORDS[areaName];
    }
    if (matched) {
      setFormData((prev) => ({
        ...prev,
        latitude: matched[0].toString(),
        longitude: matched[1].toString(),
      }));
    }
  };

  // Inline Owner Registration Mode ('select' or 'new')
  const [ownerMode, setOwnerMode] = useState("select");
  const [newOwnerData, setNewOwnerData] = useState({
    name: "",
    type: "private",
    contact_number: "",
    email: "",
    address: "",
  });

  const fetchTowersAndMetadata = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const params = {};
      if (landFilter !== "all") params.land_type = landFilter;
      if (statusFilter !== "all") params.status = statusFilter;
      if (districtFilter !== "all") params.district_id = districtFilter;

      const [towerList, districtList, constituencyList, talukaList, areaList, ownerList, operatorList] =
        await Promise.all([
          towerApi.getTowers(params),
          towerApi.getDistricts().catch(() => []),
          towerApi.getConstituencies().catch(() => []),
          towerApi.getTalukas().catch(() => []),
          towerApi.getAreas().catch(() => []),
          towerApi.getOwners().catch(() => []),
          towerApi.getOperators().catch(() => []),
        ]);

      setTowers(Array.isArray(towerList) ? towerList : []);
      setDistricts(Array.isArray(districtList) ? districtList : []);
      setConstituencies(Array.isArray(constituencyList) ? constituencyList : []);
      setTalukas(Array.isArray(talukaList) ? talukaList : []);
      setAreas(Array.isArray(areaList) ? areaList : []);
      setOwners(Array.isArray(ownerList) ? ownerList : []);
      setOperators(Array.isArray(operatorList) ? operatorList : []);
    } catch (e) {
      console.error("Failed to fetch towers data", e);
      setError(e.response?.data?.message || e.message || "Failed to load towers from server.");
    } finally {
      setIsLoading(false);
    }
  }, [landFilter, statusFilter, districtFilter]);

  useEffect(() => {
    fetchTowersAndMetadata();
  }, [fetchTowersAndMetadata]);

  // Filtered Talukas & Areas for Form
  const filteredTalukas = useMemo(() => {
    if (!formData.district_id) return talukas;
    return talukas.filter((t) => {
      const dId = t.district_id ?? (typeof t.constituency === "object" ? t.constituency?.district_id : null);
      if (dId !== undefined && dId !== null) {
        return String(dId) === String(formData.district_id);
      }
      if (t.constituency && constituencies.length > 0) {
        const c = constituencies.find((item) => String(item.id) === String(t.constituency));
        if (c) {
          const cDistId = c.district_id ?? (typeof c.district === "object" ? c.district?.id : c.district);
          if (cDistId !== undefined && cDistId !== null) {
            return String(cDistId) === String(formData.district_id);
          }
        }
      }
      return false;
    });
  }, [talukas, constituencies, formData.district_id]);

  const filteredAreas = useMemo(() => {
    if (!formData.taluka_id) return [];
    return areas.filter((a) => {
      const tId = a.taluka_id ?? (typeof a.taluka === "object" ? a.taluka?.id : a.taluka);
      return String(tId) === String(formData.taluka_id);
    });
  }, [areas, formData.taluka_id]);

  const handleOpenCreate = () => {
    setModalMode("create");
    setSelectedTower(null);
    setFormData(initialFormState);
    setOwnerMode("select");
    setNewOwnerData({ name: "", type: "private", contact_number: "", email: "", address: "" });
    setHeightUnit("m");
    setWidthUnit("m");
    setIsModalOpen(true);
  };

  const handleOpenEdit = (tower, e) => {
    if (e) e.stopPropagation();
    setModalMode("edit");
    setSelectedTower(tower);

    const assignedOpIds = Array.isArray(tower.operators)
      ? tower.operators.map((op) => op.id)
      : [];

    const areaObj = tower.area || {};
    const talukaObj = areaObj.taluka || {};
    const constObj = talukaObj.constituency || {};
    const distObj = constObj.district || {};

    const rawInstallDate = tower.installation_date ? String(tower.installation_date).split("T")[0] : "";
    const rawRentStartDate = tower.rent_start_date ? String(tower.rent_start_date).split("T")[0] : "";

    const resolvedAreaId = tower.area_id || areaObj.id || "";
    let resolvedTalukaId = talukaObj.id || "";
    let resolvedDistrictId = distObj.id || "";

    if (!resolvedTalukaId && resolvedAreaId) {
      const matchedArea = areas.find((a) => String(a.id) === String(resolvedAreaId));
      if (matchedArea) {
        resolvedTalukaId = matchedArea.taluka_id ?? (typeof matchedArea.taluka === "object" ? matchedArea.taluka?.id : matchedArea.taluka) ?? "";
      }
    }
    if (!resolvedDistrictId && resolvedTalukaId) {
      const matchedTaluka = talukas.find((t) => String(t.id) === String(resolvedTalukaId));
      if (matchedTaluka) {
        resolvedDistrictId = matchedTaluka.district_id ?? (typeof matchedTaluka.constituency === "object" ? matchedTaluka.constituency?.district_id : null) ?? "";
      }
    }

    setFormData({
      tower_unique_id: tower.tower_unique_id || "",
      district_id: resolvedDistrictId,
      taluka_id: resolvedTalukaId,
      constituency_id: constObj.id || "",
      area_id: resolvedAreaId,
      owner_id: tower.owner_id || tower.owner?.id || "",
      land_type: tower.land_type || "government",
      height: tower.height ?? tower.height_meters ?? "",
      width: tower.width ?? tower.width_meters ?? tower.base_width ?? "",
      frequency: tower.frequency || "4G/5G",
      status: tower.status || "active",
      yearly_rent: tower.yearly_rent || "",
      rent_cycle_years: tower.rent_cycle_years || 1,
      installation_date: rawInstallDate || new Date().toISOString().split("T")[0],
      rent_start_date: rawRentStartDate || new Date().toISOString().split("T")[0],
      address: tower.address || "",
      latitude: tower.latitude != null ? String(tower.latitude) : "",
      longitude: tower.longitude != null ? String(tower.longitude) : "",
      operator_ids: assignedOpIds,
    });
    setOwnerMode("select");
    setNewOwnerData({ name: "", type: "private", contact_number: "", email: "", address: "" });
    setHeightUnit("m");
    setWidthUnit("m");
    setIsModalOpen(true);
  };

  const handleDelete = async (id, e) => {
    if (e) e.stopPropagation();
    if (window.confirm("Are you sure you want to delete this tower record?")) {
      try {
        await towerApi.deleteTower(id);
        fetchTowersAndMetadata();
      } catch (err) {
        alert(err.response?.data?.message || "Failed to delete tower.");
      }
    }
  };

  const handleOperatorToggle = (operatorId) => {
    const current = [...formData.operator_ids];
    if (current.includes(operatorId)) {
      setFormData({
        ...formData,
        operator_ids: current.filter((id) => id !== operatorId),
      });
    } else {
      setFormData({
        ...formData,
        operator_ids: [...current, operatorId],
      });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.tower_unique_id.trim()) {
      alert("Please enter a Tower ID.");
      return;
    }
    if (!formData.area_id) {
      alert("Please select a Location Area.");
      return;
    }

    let targetOwnerId = formData.owner_id;

    setIsSubmitting(true);
    try {
      // If registering new owner inline, create the owner first seamlessly
      if (ownerMode === "new") {
        if (!newOwnerData.name.trim()) {
          alert("Please enter the New Owner Name.");
          setIsSubmitting(false);
          return;
        }
        const ownerPhone = (newOwnerData.contact_number || "").trim();
        const ownerPayload = {
          name: newOwnerData.name.trim(),
          type: newOwnerData.type,
          contact_number: ownerPhone,
          phone: ownerPhone,
          contact_no: ownerPhone,
          phone_number: ownerPhone,
          mobile: ownerPhone,
          contact: ownerPhone,
          email: (newOwnerData.email || "").trim(),
          address: (newOwnerData.address || "").trim(),
        };
        const createdOwner = await towerApi.createOwner(ownerPayload);
        targetOwnerId = createdOwner.id;
        const updatedOwners = await towerApi.getOwners();
        setOwners(updatedOwners);
      }

      if (!targetOwnerId) {
        alert("Please select or register a Tower Owner.");
        setIsSubmitting(false);
        return;
      }

      const cleanInstallDate = formData.installation_date
        ? String(formData.installation_date).split("T")[0]
        : null;
      const cleanRentStartDate = formData.rent_start_date
        ? String(formData.rent_start_date).split("T")[0]
        : null;

      const payload = {
        tower_unique_id: formData.tower_unique_id.trim(),
        area_id: parseInt(formData.area_id, 10),
        owner_id: parseInt(targetOwnerId, 10),
        land_type: formData.land_type,
        height: heightUnit === "ft" ? (parseFloat(formData.height) || 0) * 0.3048 : parseFloat(formData.height) || 0,
        width: widthUnit === "ft" ? (parseFloat(formData.width) || 0) * 0.3048 : parseFloat(formData.width) || 0,
        height_meters: heightUnit === "ft" ? (parseFloat(formData.height) || 0) * 0.3048 : parseFloat(formData.height) || 0,
        width_meters: widthUnit === "ft" ? (parseFloat(formData.width) || 0) * 0.3048 : parseFloat(formData.width) || 0,
        base_width: widthUnit === "ft" ? (parseFloat(formData.width) || 0) * 0.3048 : parseFloat(formData.width) || 0,
        frequency: formData.frequency,
        status: formData.status,
        yearly_rent: parseFloat(formData.yearly_rent) || 0,
        rent_cycle_years: parseInt(formData.rent_cycle_years, 10) || 1,
        installation_date: cleanInstallDate,
        rent_start_date: cleanRentStartDate,
        address: formData.address,
        latitude: formData.latitude !== "" && !isNaN(parseFloat(formData.latitude)) ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude !== "" && !isNaN(parseFloat(formData.longitude)) ? parseFloat(formData.longitude) : null,
      };

      let savedTowerId = null;
      if (modalMode === "create") {
        const created = await towerApi.createTower(payload);
        savedTowerId = created.id;
      } else {
        const updated = await towerApi.updateTower(selectedTower.id, payload);
        savedTowerId = updated.id || selectedTower.id;
      }

      // Synchronize assigned operators
      if (savedTowerId && formData.operator_ids) {
        await towerApi.syncTowerOperators(savedTowerId, formData.operator_ids);
      }

      setIsModalOpen(false);
      fetchTowersAndMetadata();
    } catch (err) {
      if (err.response?.status === 401) {
        alert("Your session has expired. Please sign in again.");
      } else {
        alert(
          err.response?.data?.message ||
            err.message ||
            "Failed to save tower record."
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  // Table Columns
  const columns = [
    {
      title: "Tower ID",
      key: "tower_unique_id",
      render: (val, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 150 }}>
          <div
            style={{
              width: 32,
              height: 32,
              borderRadius: "var(--radius-sm)",
              background: "rgba(6, 182, 212, 0.15)",
              color: "var(--accent-cyan)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <Radio size={16} />
          </div>
          <div>
            <div style={{ fontWeight: 700, color: "var(--text-primary)", whiteSpace: "nowrap" }}>{val}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
              {row.frequency || "4G/5G"} • {(row.height ?? row.height_meters) ? `${row.height ?? row.height_meters}m` : "-"}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: "Tower Owner",
      key: "owner",
      render: (val, row) => (
        <div style={{ minWidth: 130 }}>
          <div style={{ fontWeight: 600, whiteSpace: "nowrap" }}>{row.owner?.name || "Unassigned"}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "capitalize", whiteSpace: "nowrap" }}>
            {row.owner?.type || row.land_type} Owner
          </div>
        </div>
      ),
    },
    {
      title: "Operators Using This Tower",
      key: "operators",
      render: (val, row) => {
        const ops = Array.isArray(row.operators) ? row.operators : [];
        if (ops.length === 0) {
          return <span style={{ color: "var(--text-muted)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>None Assigned</span>;
        }
        return (
          <div style={{ display: "flex", gap: 4, flexWrap: "wrap", maxWidth: 180 }}>
            {ops.map((op) => (
              <span
                key={op.id}
                className="badge badge-info"
                style={{ fontSize: "0.7rem", padding: "2px 7px", whiteSpace: "nowrap" }}
              >
                {op.short_name || op.name}
              </span>
            ))}
          </div>
        );
      },
    },
    {
      title: "Location Hierarchy",
      key: "location",
      render: (val, row) => {
        const area = row.area || {};
        const taluka = area.taluka || {};
        const constituency = taluka.constituency || {};
        const district = constituency.district || {};

        return (
          <div style={{ minWidth: 130 }}>
            <div style={{ fontWeight: 600, display: "flex", alignItems: "center", gap: 4, whiteSpace: "nowrap" }}>
              <MapPin size={13} color="var(--accent-cyan)" />
              <span>{area.name || "Area N/A"}</span>
            </div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
              {taluka.name ? `${taluka.name}, ` : ""}{district.name || "Goa"}
            </div>
          </div>
        );
      },
    },
    {
      title: "Land Type",
      key: "land_type",
      render: (val) => (
        <span
          className={`badge ${val === "government" ? "badge-success" : "badge-neutral"}`}
          style={{ whiteSpace: "nowrap" }}
        >
          {val === "government" ? "Government Land" : "Private Land"}
        </span>
      ),
    },
    {
      title: "Yearly Rent",
      key: "yearly_rent",
      render: (val, row) => (
        <div style={{ minWidth: 100 }}>
          <div style={{ fontWeight: 700, color: "var(--text-primary)", whiteSpace: "nowrap" }}>
            ₹{Number(val || 0).toLocaleString("en-IN")} / yr
          </div>
          <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
            Cycle: {row.rent_cycle_years || 1} Year{row.rent_cycle_years > 1 ? "s" : ""}
          </div>
        </div>
      ),
    },
    {
      title: "Payment Status",
      key: "payment_status",
      render: (val, row) => {
        const status = row.payment_status || (row.rent_due ? "due" : "paid");
        return (
          <span
            className={`badge ${
              status === "paid"
                ? "badge-success"
                : status === "due"
                ? "badge-warning"
                : "badge-danger"
            }`}
            style={{ whiteSpace: "nowrap" }}
          >
            {status}
          </span>
        );
      },
    },
    {
      title: "Actions",
      key: "actions",
      sortable: false,
      render: (val, row) => (
        <div style={{ display: "flex", gap: 6, justifyContent: "flex-end", whiteSpace: "nowrap" }}>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/towers/${row.id || row.tower_unique_id}`);
            }}
            title="View Full Specifications & Payment History"
          >
            <Eye size={14} />
          </button>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            onClick={(e) => handleOpenEdit(row, e)}
            title="Edit Tower Record"
          >
            <Edit2 size={14} />
          </button>
          <button
            className="btn btn-danger btn-icon btn-sm"
            onClick={(e) => handleDelete(row.id, e)}
            title="Delete Record"
          >
            <Trash2 size={14} />
          </button>
        </div>
      ),
    },
  ];

  const displayedTowers = useMemo(() => {
    if (companyFilter === "all") return towers;
    const filterVal = companyFilter.toLowerCase().trim();

    return towers.filter((tower) => {
      if (filterVal.startsWith("op_id:")) {
        const targetId = filterVal.replace("op_id:", "").trim();
        return Array.isArray(tower.operators) && tower.operators.some((op) => String(op.id) === targetId);
      }
      if (filterVal.startsWith("op:")) {
        const targetName = filterVal.replace("op:", "").trim();
        return Array.isArray(tower.operators) && tower.operators.some((op) =>
          (op.name || "").toLowerCase() === targetName ||
          (op.short_name || "").toLowerCase() === targetName
        );
      }
      if (filterVal.startsWith("ow:")) {
        const targetName = filterVal.replace("ow:", "").trim();
        return (tower.owner?.name || "").toLowerCase() === targetName;
      }

      const opMatch = Array.isArray(tower.operators) && tower.operators.some((op) =>
        (op.name || "").toLowerCase().includes(filterVal) ||
        (op.short_name || "").toLowerCase().includes(filterVal)
      );
      const ownerMatch = (tower.owner?.name || "").toLowerCase().includes(filterVal);
      return opMatch || ownerMatch;
    });
  }, [towers, companyFilter]);

  return (
    <div>
      {/* Official Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Tower Management</h1>
          <p>
            Registry of mobile telecommunication towers, tenancies, location hierarchy, and rent cycles
          </p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary" onClick={fetchTowersAndMetadata}>
            <RefreshCw size={16} />
            <span>Refresh</span>
          </button>
          <button className="btn btn-primary" onClick={handleOpenCreate}>
            <Plus size={16} />
            <span>Register New Tower</span>
          </button>
        </div>
      </div>

      {/* Error Alert */}
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
        data={displayedTowers}
        initialSearch={searchTerm}
        searchPlaceholder="Search by Tower ID, operator, company, address, area, owner..."
        isLoading={isLoading}
        emptyMessage={
          companyFilter !== "all" || searchTerm
            ? "No towers match the specified operator/company search criteria."
            : "No mobile towers registered in database yet. Click 'Register New Tower' to add."
        }
        exportFilename="MTMMS_Towers"
        onRowClick={(row) => navigate(`/towers/${row.id || row.tower_unique_id}`)}
        filterSlot={
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={companyFilter}
                onChange={(e) => setCompanyFilter(e.target.value)}
              >
                <option value="all">All Operators / Companies</option>
                {operators.length > 0 && (
                  <optgroup label="Telecom Operators">
                    {operators.map((op) => (
                      <option key={`op-${op.id}`} value={`op:${(op.name || "").toLowerCase()}`}>
                        {op.name} ({op.short_name || "OP"})
                      </option>
                    ))}
                  </optgroup>
                )}
                {owners.length > 0 && (
                  <optgroup label="Tower Companies & Owners">
                    {owners.map((ow) => (
                      <option key={`ow-${ow.id}`} value={`ow:${(ow.name || "").toLowerCase()}`}>
                        {ow.name}
                      </option>
                    ))}
                  </optgroup>
                )}
              </select>

              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={districtFilter}
                onChange={(e) => setDistrictFilter(e.target.value)}
              >
                <option value="all">All Districts</option>
                {districts.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </select>

              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={landFilter}
                onChange={(e) => setLandFilter(e.target.value)}
              >
                <option value="all">All Land Types</option>
                <option value="government">Government Land</option>
                <option value="private">Private Land</option>
              </select>

              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="all">All Statuses</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="maintenance">Maintenance</option>
              </select>

              {companyFilter !== "all" && (
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  style={{ fontSize: "0.75rem", padding: "4px 8px" }}
                  onClick={() => setCompanyFilter("all")}
                >
                  <X size={12} />
                  <span>Clear Company</span>
                </button>
              )}
            </div>
          }
        />

      {/* ========================================================
          REGISTER / EDIT TOWER MODAL
         ======================================================== */}
      {isModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
          <div
            className="modal-content"
            style={{ maxWidth: 780 }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <Radio size={20} color="var(--accent-cyan)" />
                <h3 style={{ fontSize: "1.15rem" }}>
                  {modalMode === "create" ? "Register New Mobile Tower" : "Edit Tower Record"}
                </h3>
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
                {/* 1. Identification & Land Ownership */}
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                  <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)" }}>
                    1. Identification & Land Ownership
                  </div>
                  <div style={{ display: "flex", gap: 6 }}>
                    <button
                      type="button"
                      className={`btn btn-sm ${ownerMode === "select" ? "btn-primary" : "btn-secondary"}`}
                      onClick={() => setOwnerMode("select")}
                      style={{ padding: "3px 10px", fontSize: "0.75rem" }}
                    >
                      Existing Owner
                    </button>
                    <button
                      type="button"
                      className={`btn btn-sm ${ownerMode === "new" ? "btn-primary" : "btn-secondary"}`}
                      onClick={() => setOwnerMode("new")}
                      style={{ padding: "3px 10px", fontSize: "0.75rem" }}
                    >
                      + Register New Owner
                    </button>
                  </div>
                </div>

                <div className="form-grid-2" style={{ marginBottom: 12 }}>
                  <div className="form-group">
                    <label className="form-label">Tower Unique ID *</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. TWR-GOA-0001"
                      value={formData.tower_unique_id}
                      onChange={(e) => setFormData({ ...formData, tower_unique_id: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Land Ownership *</label>
                    <select
                      className="form-select"
                      value={formData.land_type}
                      onChange={(e) => setFormData({ ...formData, land_type: e.target.value })}
                    >
                      <option value="government">Government Land</option>
                      <option value="private">Private Land</option>
                    </select>
                  </div>
                </div>

                {/* Owner Selection vs Inline Owner Registration */}
                {ownerMode === "select" ? (
                  <div className="form-group" style={{ marginBottom: 16 }}>
                    <label className="form-label">Registered Tower Owner *</label>
                    <select
                      className="form-select"
                      value={formData.owner_id}
                      onChange={(e) => setFormData({ ...formData, owner_id: e.target.value })}
                      required={ownerMode === "select"}
                    >
                      <option value="">-- Select Registered Owner --</option>
                      {owners.map((o) => {
                        const phone = o.contact_number || o.phone || o.contact_no || o.phone_number || o.mobile || "";
                        return (
                          <option key={o.id} value={o.id}>
                            {o.name} ({o.type || "Provider"}) {phone ? `• ${phone}` : ""}
                          </option>
                        );
                      })}
                    </select>
                  </div>
                ) : (
                  <div
                    style={{
                      background: "rgba(6, 182, 212, 0.06)",
                      border: "1px solid rgba(6, 182, 212, 0.25)",
                      borderRadius: "var(--radius-md)",
                      padding: "14px 16px",
                      marginBottom: 16,
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
                      <span style={{ fontSize: "0.82rem", fontWeight: 700, color: "var(--accent-cyan)" }}>
                        ✦ New Tower / Land Owner Details (Saved Inline)
                      </span>
                    </div>

                    <div className="form-grid-3">
                      <div className="form-group">
                        <label className="form-label">Owner Name *</label>
                        <input
                          type="text"
                          className="form-control"
                          placeholder="e.g. Goa Telecom Pvt Ltd"
                          value={newOwnerData.name}
                          onChange={(e) => setNewOwnerData({ ...newOwnerData, name: e.target.value })}
                          required={ownerMode === "new"}
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Owner Type</label>
                        <select
                          className="form-select"
                          value={newOwnerData.type}
                          onChange={(e) => setNewOwnerData({ ...newOwnerData, type: e.target.value })}
                        >
                          <option value="private">Private Property Owner</option>
                          <option value="government">Government Body</option>
                          <option value="panchayat">Village Panchayat</option>
                          <option value="municipality">Municipal Council</option>
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="form-label">Contact Number</label>
                        <input
                          type="text"
                          className="form-control"
                          placeholder="e.g. 9876543210"
                          value={newOwnerData.contact_number}
                          onChange={(e) => setNewOwnerData({ ...newOwnerData, contact_number: e.target.value })}
                        />
                      </div>
                    </div>
                  </div>
                )}

                {/* 2. Geographical Location Hierarchy */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginTop: 16, marginBottom: 12 }}>
                  2. Geographic Location Hierarchy
                </div>

                <div className="form-grid-3">
                  <div className="form-group">
                    <label className="form-label">District</label>
                    <select
                      className="form-select"
                      value={formData.district_id}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          district_id: e.target.value,
                          taluka_id: "",
                          area_id: "",
                        })
                      }
                    >
                      <option value="">-- Select District --</option>
                      {districts.map((d) => (
                        <option key={d.id} value={d.id}>
                          {d.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Taluka</label>
                    <select
                      className="form-select"
                      value={formData.taluka_id}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          taluka_id: e.target.value,
                          area_id: "",
                        })
                      }
                    >
                      <option value="">-- Select Taluka --</option>
                      {filteredTalukas.map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Area / Panchayat *</label>
                    <select
                      className="form-select"
                      value={formData.area_id}
                      onChange={(e) => setFormData({ ...formData, area_id: e.target.value })}
                      required
                      disabled={!formData.taluka_id}
                    >
                      <option value="">
                        {!formData.taluka_id
                          ? "-- Select Taluka First --"
                          : filteredAreas.length === 0
                          ? "-- No Areas in Selected Taluka --"
                          : `-- Select Area / Panchayat (${filteredAreas.length} Available) --`}
                      </option>
                      {filteredAreas.map((a) => (
                        <option key={a.id} value={a.id}>
                          {a.name} {a.pincode ? `(${a.pincode})` : ""}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: 12 }}>
                  <label className="form-label">Detailed Site Address</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="Plot / Survey No, Landmark, Village / Ward"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  />
                </div>

                {/* Exact GPS Coordinates Section */}
                <div
                  style={{
                    background: "rgba(255, 81, 0, 0.05)",
                    border: "1px solid rgba(255, 81, 0, 0.25)",
                    borderRadius: "var(--radius-md)",
                    padding: "12px 14px",
                    marginBottom: 16,
                  }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                    <div style={{ fontSize: "0.82rem", fontWeight: 700, color: "var(--primary-dark)", display: "flex", alignItems: "center", gap: 6 }}>
                      <MapPin size={14} color="#ff5100" />
                      <span>Exact GIS Map Coordinates (Real-World GPS)</span>
                    </div>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ fontSize: "0.72rem", padding: "3px 8px", display: "flex", alignItems: "center", gap: 4 }}
                      onClick={() => handleAutoFillGps(formData.area_id, formData.address)}
                    >
                      <MapPin size={11} color="#ff5100" />
                      <span>Auto-fill from Area/Address</span>
                    </button>
                  </div>

                  <div className="form-grid-2">
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label" style={{ fontSize: "0.78rem" }}>Exact Latitude (°N)</label>
                      <input
                        type="number"
                        step="0.000001"
                        className="form-control"
                        placeholder="e.g. 15.40182"
                        value={formData.latitude}
                        onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                      />
                    </div>

                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label" style={{ fontSize: "0.78rem" }}>Exact Longitude (°E)</label>
                      <input
                        type="number"
                        step="0.000001"
                        className="form-control"
                        placeholder="e.g. 74.01525"
                        value={formData.longitude}
                        onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                      />
                    </div>
                  </div>
                </div>

                {/* 3. Technical Specifications */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginTop: 16, marginBottom: 12 }}>
                  3. Technical Specifications
                </div>

                <div className="form-grid-3">
                  <div className="form-group">
                    <label className="form-label" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      Tower Height
                      <span style={{ display: "flex", gap: 0, border: "1px solid var(--border-color)", borderRadius: 6, overflow: "hidden", marginLeft: 4 }}>
                        {["m", "ft"].map((u) => (
                          <button
                            key={u}
                            type="button"
                            onClick={() => handleSwitchHeightUnit(u)}
                            style={{
                              padding: "1px 8px",
                              fontSize: "0.7rem",
                              fontWeight: 600,
                              background: heightUnit === u ? "var(--accent-cyan)" : "transparent",
                              color: heightUnit === u ? "#0a0f1e" : "var(--text-secondary)",
                              border: "none",
                              cursor: "pointer",
                              transition: "all 0.15s",
                            }}
                          >{u === "m" ? "m" : "ft"}</button>
                        ))}
                      </span>
                    </label>
                    <input
                      type="number"
                      step="0.1"
                      className="form-control"
                      placeholder={heightUnit === "m" ? "e.g. 35.0" : "e.g. 114.8"}
                      value={formData.height}
                      onChange={(e) => setFormData({ ...formData, height: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      Tower Width / Base
                      <span style={{ display: "flex", gap: 0, border: "1px solid var(--border-color)", borderRadius: 6, overflow: "hidden", marginLeft: 4 }}>
                        {["m", "ft"].map((u) => (
                          <button
                            key={u}
                            type="button"
                            onClick={() => handleSwitchWidthUnit(u)}
                            style={{
                              padding: "1px 8px",
                              fontSize: "0.7rem",
                              fontWeight: 600,
                              background: widthUnit === u ? "var(--accent-cyan)" : "transparent",
                              color: widthUnit === u ? "#0a0f1e" : "var(--text-secondary)",
                              border: "none",
                              cursor: "pointer",
                              transition: "all 0.15s",
                            }}
                          >{u === "m" ? "m" : "ft"}</button>
                        ))}
                      </span>
                    </label>
                    <input
                      type="number"
                      step="0.1"
                      className="form-control"
                      placeholder={widthUnit === "m" ? "e.g. 2.5" : "e.g. 8.2"}
                      value={formData.width}
                      onChange={(e) => setFormData({ ...formData, width: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Operating Frequency / Tech</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. 4G / 5G / 3.5GHz"
                      value={formData.frequency}
                      onChange={(e) => setFormData({ ...formData, frequency: e.target.value })}
                    />
                  </div>
                </div>

                {/* 4. Financial & Rent Cycle Parameters */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginTop: 16, marginBottom: 12 }}>
                  4. Financial & Rent Cycle Parameters
                </div>

                <div className="form-grid-3">
                  <div className="form-group">
                    <label className="form-label">Yearly Rent (₹) *</label>
                    <input
                      type="number"
                      className="form-control"
                      placeholder="e.g. 60000"
                      value={formData.yearly_rent}
                      onChange={(e) => setFormData({ ...formData, yearly_rent: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rent Cycle Period *</label>
                    <select
                      className="form-select"
                      value={formData.rent_cycle_years}
                      onChange={(e) => setFormData({ ...formData, rent_cycle_years: parseInt(e.target.value, 10) })}
                      required
                    >
                      <option value={1}>1 Year Cycle</option>
                      <option value={5}>5 Years Cycle</option>
                      <option value={10}>10 Years Cycle</option>
                      <option value={15}>15 Years Cycle</option>
                      <option value={20}>20 Years Cycle</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rent Start Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={formData.rent_start_date}
                      onChange={(e) => setFormData({ ...formData, rent_start_date: e.target.value })}
                    />
                  </div>
                </div>

                {/* Calculated Total Amount Highlight Box */}
                <div
                  className="calculated-total-box"
                  style={{
                    background: "rgba(6, 182, 212, 0.08)",
                    border: "1.5px solid rgba(6, 182, 212, 0.25)",
                    borderRadius: "var(--radius-md)",
                    padding: "12px 18px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    marginTop: 6,
                    marginBottom: 16,
                  }}
                >
                  <div>
                    <div style={{ fontSize: "0.85rem", fontWeight: 700, color: "var(--text-primary)" }}>
                      Calculated Total Amount
                    </div>
                    <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 2 }}>
                      Yearly Rent (₹{Number(formData.yearly_rent || 0).toLocaleString("en-IN")}) × {formData.rent_cycle_years || 1} Year{(formData.rent_cycle_years || 1) > 1 ? "s" : ""}
                    </div>
                  </div>

                  <div style={{ textAlign: "right" }}>
                    <div
                      className="calc-amount"
                      style={{
                        fontSize: "1.45rem",
                        fontWeight: 800,
                        color: "var(--accent-cyan)",
                        letterSpacing: "0.02em",
                      }}
                    >
                      ₹{((Number(formData.yearly_rent) || 0) * (parseInt(formData.rent_cycle_years, 10) || 1)).toLocaleString("en-IN")}
                    </div>
                    <div style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}>
                      Total Cycle Valuation
                    </div>
                  </div>
                </div>

                {/* 5. Operators Using This Tower */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginTop: 16, marginBottom: 10 }}>
                  5. Operators Using This Tower
                </div>

                <div
                  style={{
                    background: "var(--bg-surface-elevated)",
                    border: "1px solid var(--border-color)",
                    borderRadius: "var(--radius-md)",
                    padding: "14px",
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))",
                    gap: 10,
                  }}
                >
                  {operators.length === 0 ? (
                    <div style={{ fontSize: "0.82rem", color: "var(--text-muted)" }}>
                      No telecom operators registered yet.
                    </div>
                  ) : (
                    operators.map((op) => {
                      const isChecked = formData.operator_ids.includes(op.id);
                      return (
                        <label
                          key={op.id}
                          style={{
                            display: "flex",
                            alignItems: "center",
                            gap: 8,
                            cursor: "pointer",
                            padding: "6px 10px",
                            background: isChecked ? "rgba(6, 182, 212, 0.15)" : "transparent",
                            border: `1px solid ${isChecked ? "var(--accent-cyan)" : "transparent"}`,
                            borderRadius: "var(--radius-sm)",
                            fontSize: "0.85rem",
                          }}
                        >
                          <input
                            type="checkbox"
                            checked={isChecked}
                            onChange={() => handleOperatorToggle(op.id)}
                            style={{ accentColor: "var(--accent-cyan)" }}
                          />
                          <span style={{ fontWeight: 600 }}>{op.short_name || op.name}</span>
                        </label>
                      );
                    })
                  )}
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
                  {isSubmitting ? "Saving Tower Record..." : modalMode === "create" ? "Register Tower" : "Update Tower"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Towers;
