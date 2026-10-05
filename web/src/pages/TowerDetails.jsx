import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  Radio,
  ArrowLeft,
  Antenna,
  CreditCard,
  AlertTriangle,
  RefreshCw,
  Plus,
  Edit2,
  Trash2,
  X,
  MapPin,
  Building2,
  Calendar,
  IndianRupee,
  Layers,
} from "lucide-react";
import Loading from "../components/Loading";
import towerApi from "../api/towerApi";
import rentApi from "../api/rentApi";
import { GOA_EXACT_LOCATION_COORDS } from "./MapView";

export const TowerDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [tower, setTower] = useState(null);
  const [payments, setPayments] = useState([]);
  const [allOperators, setAllOperators] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // Operator Management Modal State
  const [isOpModalOpen, setIsOpModalOpen] = useState(false);
  const [selectedOpIds, setSelectedOpIds] = useState([]);
  const [isSavingOps, setIsSavingOps] = useState(false);

  // Payment Recording Modal State
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentForm, setPaymentForm] = useState({
    amount: "",
    payment_date: new Date().toISOString().split("T")[0],
    challan_number: "",
    payment_mode: "online",
    remarks: "Official rent payment",
  });
  const [isSavingPayment, setIsSavingPayment] = useState(false);

  // Edit Tower Modal State
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [districts, setDistricts] = useState([]);
  const [talukas, setTalukas] = useState([]);
  const [areas, setAreas] = useState([]);
  const [owners, setOwners] = useState([]);
  const [isSavingTower, setIsSavingTower] = useState(false);
  const [isDeletingTower, setIsDeletingTower] = useState(false);
  const [editHeightUnit, setEditHeightUnit] = useState("m"); // 'm' | 'ft'
  const [editWidthUnit, setEditWidthUnit] = useState("m");   // 'm' | 'ft'
  const [displayUnit, setDisplayUnit] = useState("both");     // 'both' | 'm' | 'ft'

  const [editFormData, setEditFormData] = useState({
    tower_unique_id: "",
    district_id: "",
    taluka_id: "",
    area_id: "",
    owner_id: "",
    land_type: "government",
    height: "",
    width: "",
    frequency: "4G/5G",
    status: "active",
    yearly_rent: "",
    rent_cycle_years: 1,
    installation_date: "",
    rent_start_date: "",
    address: "",
  });

  const loadDetails = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [towerData, paymentsData, operatorsData] = await Promise.all([
        towerApi.getTower(id),
        rentApi.getTowerPayments(id).catch(() => []),
        towerApi.getOperators().catch(() => []),
      ]);
      setTower(towerData);
      setPayments(paymentsData || towerData?.rent_payments || []);
      setAllOperators(operatorsData);

      const assigned = Array.isArray(towerData?.operators)
        ? towerData.operators.map((op) => op.id)
        : [];
      setSelectedOpIds(assigned);
    } catch (e) {
      console.error("Failed to load tower details", e);
      setError(
        e.response?.data?.message ||
          e.message ||
          "Failed to load tower record from database."
      );
    } finally {
      setIsLoading(false);
    }
  }, [id]);

  useEffect(() => {
    loadDetails();
  }, [loadDetails]);

  const handleOpenOpModal = () => {
    const assigned = Array.isArray(tower?.operators)
      ? tower.operators.map((op) => op.id)
      : [];
    setSelectedOpIds(assigned);
    setIsOpModalOpen(true);
  };

  const handleToggleOp = (opId) => {
    if (selectedOpIds.includes(opId)) {
      setSelectedOpIds(selectedOpIds.filter((i) => i !== opId));
    } else {
      setSelectedOpIds([...selectedOpIds, opId]);
    }
  };

  const handleSaveOperators = async () => {
    setIsSavingOps(true);
    try {
      await towerApi.syncTowerOperators(tower.id, selectedOpIds);
      setIsOpModalOpen(false);
      loadDetails();
    } catch (err) {
      alert(err.response?.data?.message || "Failed to update assigned operators.");
    } finally {
      setIsSavingOps(false);
    }
  };

  const handleRecordPayment = async (e) => {
    e.preventDefault();
    if (!paymentForm.amount || !paymentForm.challan_number.trim()) {
      alert("Please enter both payment amount and Challan number.");
      return;
    }
    setIsSavingPayment(true);
    try {
      await rentApi.recordPayment({
        tower_id: tower.id,
        amount: parseFloat(paymentForm.amount),
        payment_date: paymentForm.payment_date,
        challan_number: paymentForm.challan_number.trim(),
        payment_mode: paymentForm.payment_mode,
        remarks: paymentForm.remarks,
      });
      setIsPaymentModalOpen(false);
      setPaymentForm({
        amount: "",
        payment_date: new Date().toISOString().split("T")[0],
        challan_number: "",
        payment_mode: "online",
        remarks: "Official rent payment",
      });
      loadDetails();
    } catch (err) {
      alert(err.response?.data?.message || "Failed to record payment.");
    } finally {
      setIsSavingPayment(false);
    }
  };

  // Open Edit Modal and prefill metadata
  const handleOpenEditModal = async () => {
    try {
      const [distList, talList, areaList, ownerList] = await Promise.all([
        towerApi.getDistricts().catch(() => []),
        towerApi.getTalukas().catch(() => []),
        towerApi.getAreas().catch(() => []),
        towerApi.getOwners().catch(() => []),
      ]);
      setDistricts(distList);
      setTalukas(talList);
      setAreas(areaList);
      setOwners(ownerList);

      const areaObj = tower.area || {};
      const talukaObj = areaObj.taluka || {};
      const constObj = talukaObj.constituency || {};
      const distObj = constObj.district || {};

      const resolvedAreaId = tower.area_id || areaObj.id || "";
      let resolvedTalukaId = talukaObj.id || "";
      let resolvedDistrictId = distObj.id || "";

      if (!resolvedTalukaId && resolvedAreaId) {
        const matchedArea = areaList.find((a) => String(a.id) === String(resolvedAreaId));
        if (matchedArea) {
          resolvedTalukaId = matchedArea.taluka_id ?? (typeof matchedArea.taluka === "object" ? matchedArea.taluka?.id : matchedArea.taluka) ?? "";
        }
      }
      if (!resolvedDistrictId && resolvedTalukaId) {
        const matchedTaluka = talList.find((t) => String(t.id) === String(resolvedTalukaId));
        if (matchedTaluka) {
          resolvedDistrictId = matchedTaluka.district_id ?? (typeof matchedTaluka.constituency === "object" ? matchedTaluka.constituency?.district_id : null) ?? "";
        }
      }

      setEditFormData({
        tower_unique_id: tower.tower_unique_id || "",
        district_id: resolvedDistrictId,
        taluka_id: resolvedTalukaId,
        area_id: resolvedAreaId,
        owner_id: tower.owner_id || tower.owner?.id || "",
        land_type: tower.land_type || "government",
        height: tower.height ?? tower.height_meters ?? "",
        width: tower.width ?? tower.width_meters ?? tower.base_width ?? "",
        frequency: tower.frequency || "4G/5G",
        status: tower.status || "active",
        yearly_rent: tower.yearly_rent || "",
        rent_cycle_years: tower.rent_cycle_years || 1,
        installation_date: tower.installation_date ? String(tower.installation_date).split("T")[0] : "",
        rent_start_date: tower.rent_start_date ? String(tower.rent_start_date).split("T")[0] : "",
        address: tower.address || "",
        latitude: tower.latitude != null ? String(tower.latitude) : "",
        longitude: tower.longitude != null ? String(tower.longitude) : "",
      });

      setEditHeightUnit("m");
      setEditWidthUnit("m");
      setIsEditModalOpen(true);
    } catch (e) {
      alert("Failed to load metadata for editing.");
    }
  };

  const handleSwitchEditHeightUnit = (newUnit) => {
    if (newUnit === editHeightUnit) return;
    const currentVal = parseFloat(editFormData.height);
    if (!isNaN(currentVal) && currentVal > 0) {
      const converted = newUnit === "ft" ? (currentVal * 3.28084).toFixed(1) : (currentVal * 0.3048).toFixed(1);
      setEditFormData((prev) => ({ ...prev, height: converted }));
    }
    setEditHeightUnit(newUnit);
  };

  const handleSwitchEditWidthUnit = (newUnit) => {
    if (newUnit === editWidthUnit) return;
    const currentVal = parseFloat(editFormData.width);
    if (!isNaN(currentVal) && currentVal > 0) {
      const converted = newUnit === "ft" ? (currentVal * 3.28084).toFixed(1) : (currentVal * 0.3048).toFixed(1);
      setEditFormData((prev) => ({ ...prev, width: converted }));
    }
    setEditWidthUnit(newUnit);
  };

  // Filtered Talukas & Areas for Form
  const filteredTalukas = useMemo(() => {
    if (!editFormData.district_id) return talukas;
    return talukas.filter((t) => {
      const dId = t.district_id ?? (typeof t.constituency === "object" ? t.constituency?.district_id : null);
      if (dId !== undefined && dId !== null) {
        return String(dId) === String(editFormData.district_id);
      }
      return false;
    });
  }, [talukas, editFormData.district_id]);

  const filteredAreas = useMemo(() => {
    if (!editFormData.taluka_id) return [];
    return areas.filter((a) => {
      const tId = a.taluka_id ?? (typeof a.taluka === "object" ? a.taluka?.id : a.taluka);
      return String(tId) === String(editFormData.taluka_id);
    });
  }, [areas, editFormData.taluka_id]);

  const handleUpdateTower = async (e) => {
    e.preventDefault();
    if (!editFormData.tower_unique_id.trim()) {
      alert("Please enter a Tower Unique ID.");
      return;
    }
    if (!editFormData.area_id) {
      alert("Please select a Location Area.");
      return;
    }
    if (!editFormData.owner_id) {
      alert("Please select a Tower Owner.");
      return;
    }

    setIsSavingTower(true);
    try {
      const cleanInstallDate = editFormData.installation_date
        ? String(editFormData.installation_date).split("T")[0]
        : null;
      const cleanRentStartDate = editFormData.rent_start_date
        ? String(editFormData.rent_start_date).split("T")[0]
        : null;

      const payload = {
        tower_unique_id: editFormData.tower_unique_id.trim(),
        area_id: parseInt(editFormData.area_id, 10),
        owner_id: parseInt(editFormData.owner_id, 10),
        land_type: editFormData.land_type,
        height: editHeightUnit === "ft" ? (parseFloat(editFormData.height) || 0) * 0.3048 : parseFloat(editFormData.height) || 0,
        width: editWidthUnit === "ft" ? (parseFloat(editFormData.width) || 0) * 0.3048 : parseFloat(editFormData.width) || 0,
        height_meters: editHeightUnit === "ft" ? (parseFloat(editFormData.height) || 0) * 0.3048 : parseFloat(editFormData.height) || 0,
        width_meters: editWidthUnit === "ft" ? (parseFloat(editFormData.width) || 0) * 0.3048 : parseFloat(editFormData.width) || 0,
        base_width: editWidthUnit === "ft" ? (parseFloat(editFormData.width) || 0) * 0.3048 : parseFloat(editFormData.width) || 0,
        frequency: editFormData.frequency,
        status: editFormData.status,
        yearly_rent: parseFloat(editFormData.yearly_rent) || 0,
        rent_cycle_years: parseInt(editFormData.rent_cycle_years, 10) || 1,
        installation_date: cleanInstallDate,
        rent_start_date: cleanRentStartDate,
        address: editFormData.address,
        latitude: editFormData.latitude !== "" && !isNaN(parseFloat(editFormData.latitude)) ? parseFloat(editFormData.latitude) : null,
        longitude: editFormData.longitude !== "" && !isNaN(parseFloat(editFormData.longitude)) ? parseFloat(editFormData.longitude) : null,
      };

      await towerApi.updateTower(tower.id, payload);
      setIsEditModalOpen(false);
      loadDetails();
    } catch (err) {
      if (err.response?.status === 401) {
        alert("Your session has expired. Please sign in again.");
      } else {
        alert(err.response?.data?.message || err.message || "Failed to update tower.");
      }
    } finally {
      setIsSavingTower(false);
    }
  };

  const handleDeleteTower = async () => {
    if (
      window.confirm(
        `Are you sure you want to delete tower "${tower.tower_unique_id}"? This action cannot be undone.`
      )
    ) {
      setIsDeletingTower(true);
      try {
        await towerApi.deleteTower(tower.id);
        navigate("/towers", { replace: true });
      } catch (err) {
        if (err.response?.status === 401) {
          alert("Your session has expired. Please sign in again.");
        } else {
          alert(err.response?.data?.message || err.message || "Failed to delete tower.");
        }
      } finally {
        setIsDeletingTower(false);
      }
    }
  };

  if (isLoading) {
    return <Loading message="Loading mobile tower specifications..." />;
  }

  if (error || !tower) {
    return (
      <div style={{ textAlign: "center", padding: "60px 20px" }}>
        <AlertTriangle size={40} color="#ef4444" style={{ marginBottom: 12 }} />
        <h2>Tower Record Not Found</h2>
        <p style={{ color: "var(--text-secondary)", marginTop: 6, marginBottom: 20 }}>
          {error || "The requested tower could not be loaded."}
        </p>
        <button className="btn btn-secondary" onClick={() => navigate("/towers")}>
          <ArrowLeft size={16} /> Back to Tower Inventory
        </button>
      </div>
    );
  }

  const area = tower.area || {};
  const taluka = area.taluka || {};
  const constituency = taluka.constituency || {};
  const district = constituency.district || {};
  const owner = tower.owner || {};
  const ops = Array.isArray(tower.operators) ? tower.operators : [];

  const totalPaidAmount = payments.reduce((acc, p) => acc + Number(p.amount || 0), 0);

  const formatDate = (dateStr) => {
    if (!dateStr) return "N/A";
    try {
      const cleanStr = String(dateStr).split("T")[0];
      const parts = cleanStr.split("-");
      if (parts.length === 3) {
        const [year, month, day] = parts;
        const d = new Date(parseInt(year, 10), parseInt(month, 10) - 1, parseInt(day, 10));
        return d.toLocaleDateString("en-IN", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        });
      }
      return cleanStr;
    } catch {
      return String(dateStr).split("T")[0] || dateStr;
    }
  };

  const heightVal = tower.height ?? tower.height_meters ?? tower.height_m;
  const widthVal = tower.width ?? tower.width_meters ?? tower.base_width ?? tower.width_m;
  const heightNum = parseFloat(heightVal) || 0;
  const widthNum = parseFloat(widthVal) || 0;

  const toFeet = (m) => Math.round(m * 3.28084 * 10) / 10;
  const formatHeight = (val, unit) => {
    if (!val) return "N/A";
    const ft = toFeet(val);
    if (unit === "both") return `${val} meters (${ft} ft)`;
    if (unit === "ft") return `${ft} feet`;
    return `${val} meters`;
  };
  const formatWidth = (val, unit) => {
    if (!val) return "N/A";
    const ft = toFeet(val);
    if (unit === "both") return `${val} meters (${ft} ft)`;
    if (unit === "ft") return `${ft} feet`;
    return `${val} meters`;
  };
  const formatSpace = (val, unit) => {
    if (!val) return "N/A";
    const sqM = Math.round(val * val);
    const sqFt = Math.round(sqM * 10.7639);
    if (unit === "both") return `${sqM.toLocaleString()} m² (${sqFt.toLocaleString()} sq ft)`;
    if (unit === "ft") return `${sqFt.toLocaleString()} sq ft`;
    return `${sqM.toLocaleString()} m²`;
  };

  // Live valuation calculation for Edit Modal
  const editYearlyVal = parseFloat(editFormData.yearly_rent) || 0;
  const editCycleVal = parseInt(editFormData.rent_cycle_years, 10) || 1;
  const editTotalValuation = editYearlyVal * editCycleVal;

  return (
    <div>
      {/* Top Banner Navigation */}
      <div style={{ marginBottom: 20 }}>
        <button
          className="btn btn-secondary btn-sm"
          onClick={() => navigate("/towers")}
          style={{ marginBottom: 14 }}
        >
          <ArrowLeft size={16} /> Back to Tower Management
        </button>

        <div className="page-header" style={{ marginBottom: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div
              style={{
                width: 48,
                height: 48,
                borderRadius: "var(--radius-md)",
                background: "rgba(6, 182, 212, 0.15)",
                color: "var(--accent-cyan)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Radio size={24} />
            </div>
            <div>
              <h1 style={{ fontSize: "1.6rem", fontWeight: 800 }}>
                {tower.tower_unique_id}
              </h1>
              <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>
                {area.name ? `${area.name}, ` : ""}
                {taluka.name ? `${taluka.name}, ` : ""}
                {district.name || "Goa"}
              </p>
            </div>
          </div>

          <div className="page-actions" style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <button className="btn btn-secondary btn-sm" onClick={loadDetails} title="Refresh Live Data">
              <RefreshCw size={14} /> Refresh
            </button>
            <button className="btn btn-primary btn-sm" onClick={handleOpenEditModal} title="Update Tower Details">
              <Edit2 size={14} /> Edit Tower
            </button>
            <button
              className="btn btn-danger btn-sm"
              onClick={handleDeleteTower}
              disabled={isDeletingTower}
              title="Delete Tower Record"
            >
              <Trash2 size={14} /> {isDeletingTower ? "Deleting..." : "Delete Tower"}
            </button>
            <button className="btn btn-success btn-sm" onClick={() => setIsPaymentModalOpen(true)}>
              <Plus size={14} /> Record Payment
            </button>
          </div>
        </div>
      </div>

      {/* Grid: 3 Main Cards */}
      <div className="grid-cols-3" style={{ marginBottom: 24 }}>
        {/* 1. Structural & Technical Specifications */}
        <div className="card">
          <div className="card-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 8 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <h3 className="card-title" style={{ margin: 0 }}>Technical Specifications</h3>
              <span
                className={`badge ${
                  tower.status === "active" ? "badge-success" : "badge-neutral"
                }`}
              >
                {tower.status || "Active"}
              </span>
            </div>

            {/* Interactive Unit Switcher: [ m / ft | Meters | Feet ] */}
            <div style={{ display: "flex", gap: 2, background: "var(--bg-surface-elevated)", border: "1px solid var(--border-color)", borderRadius: 6, padding: 2 }}>
              {[
                { id: "both", label: "m / ft" },
                { id: "m", label: "Meters" },
                { id: "ft", label: "Feet" },
              ].map((u) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => setDisplayUnit(u.id)}
                  style={{
                    padding: "2px 8px",
                    fontSize: "0.7rem",
                    fontWeight: 600,
                    borderRadius: 4,
                    background: displayUnit === u.id ? "var(--accent-cyan)" : "transparent",
                    color: displayUnit === u.id ? "#0a0f1e" : "var(--text-secondary)",
                    border: "none",
                    cursor: "pointer",
                    transition: "all 0.15s ease",
                  }}
                >
                  {u.label}
                </button>
              ))}
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Tower Height</span>
              <div style={{ textAlign: "right" }}>
                <span style={{ fontWeight: 700, color: "var(--text-primary)" }}>
                  {formatHeight(heightNum, displayUnit)}
                </span>
                {displayUnit !== "both" && heightNum > 0 && (
                  <div style={{ fontSize: "0.74rem", color: "var(--text-muted)" }}>
                    {displayUnit === "m" ? `${toFeet(heightNum)} ft` : `${heightNum} meters`}
                  </div>
                )}
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Base Width / Space</span>
              <div style={{ textAlign: "right" }}>
                <span style={{ fontWeight: 700, color: "var(--text-primary)" }}>
                  {formatWidth(widthNum, displayUnit)}
                </span>
                {displayUnit !== "both" && widthNum > 0 && (
                  <div style={{ fontSize: "0.74rem", color: "var(--text-muted)" }}>
                    {displayUnit === "m" ? `${toFeet(widthNum)} ft` : `${widthNum} meters`}
                  </div>
                )}
              </div>
            </div>

            {widthNum > 0 && (
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
                <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Tower Ground Space</span>
                <span style={{ fontWeight: 600, color: "var(--accent-cyan)", fontSize: "0.88rem" }}>
                  {formatSpace(widthNum, displayUnit)}
                </span>
              </div>
            )}

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Operating Frequency</span>
              <span style={{ fontWeight: 700, color: "var(--accent-cyan)" }}>
                {tower.frequency || "4G / 5G"}
              </span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Installation Date</span>
              <span style={{ fontWeight: 600 }}>{formatDate(tower.installation_date)}</span>
            </div>
          </div>
        </div>

        {/* 2. Geographic Location & Land Owner */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Location & Ownership</h3>
            <span className={`badge ${tower.land_type === "government" ? "badge-success" : "badge-info"}`}>
              {tower.land_type === "government" ? "Government Land" : "Private Land"}
            </span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>District</span>
              <span style={{ fontWeight: 700 }}>{district.name || "North Goa"}</span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Taluka</span>
              <span style={{ fontWeight: 600 }}>{taluka.name || "N/A"}</span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Area / Panchayat</span>
              <span style={{ fontWeight: 600 }}>{area.name || "N/A"}</span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Tower Owner</span>
              <span style={{ fontWeight: 700, color: "var(--primary-light)" }}>
                {owner.name || "Unassigned"}
              </span>
            </div>

            {tower.address && (
              <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: 2, borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
                <strong>Address:</strong> {tower.address}
              </div>
            )}

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", paddingTop: 4 }}>
              <div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", fontWeight: 600 }}>GIS Coordinates</div>
                <div style={{ fontWeight: 700, color: "var(--primary-dark)", fontFamily: "monospace", fontSize: "0.86rem", marginTop: 2 }}>
                  {tower.latitude && tower.longitude
                    ? `${Number(tower.latitude).toFixed(5)}°N, ${Number(tower.longitude).toFixed(5)}°E`
                    : "Exact Area Coordinates Active"}
                </div>
              </div>
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                style={{ fontSize: "0.74rem", padding: "4px 10px", display: "flex", alignItems: "center", gap: 5 }}
                onClick={() => navigate(`/map?search=${tower.tower_unique_id}`)}
              >
                <MapPin size={12} color="#ff5100" />
                <span>Locate on GIS Map</span>
              </button>
            </div>
          </div>
        </div>

        {/* 3. Financial & Rent Cycle Summary */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Rent & Lease Terms</h3>
            <span
              className={`badge ${
                tower.payment_status === "paid" ? "badge-success" : "badge-warning"
              }`}
            >
              {tower.payment_status || "Pending"}
            </span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Yearly Rent</span>
              <span style={{ fontWeight: 800, color: "var(--text-primary)", fontSize: "1.1rem" }}>
                ₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}
              </span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Rent Cycle</span>
              <span style={{ fontWeight: 700, color: "var(--accent-cyan)" }}>
                {tower.rent_cycle_years || 1} Year{tower.rent_cycle_years > 1 ? "s" : ""}
              </span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Rent Start Date</span>
              <span style={{ fontWeight: 600 }}>{formatDate(tower.rent_start_date)}</span>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", borderBottom: "1px solid var(--border-color)", paddingBottom: 8 }}>
              <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>Total Paid Revenue</span>
              <span style={{ fontWeight: 800, color: "#10b981" }}>
                ₹{totalPaidAmount.toLocaleString("en-IN")}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Operators Using This Tower */}
      <div className="card" style={{ marginBottom: 24 }}>
        <div className="card-header">
          <div>
            <h3 className="card-title">Operators Using This Tower</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
              Licensed telecom operators utilizing this tower site
            </p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={handleOpenOpModal}>
            <Antenna size={14} />
            <span>Manage Assigned Operators</span>
          </button>
        </div>

        {ops.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px 0", color: "var(--text-muted)", fontSize: "0.85rem" }}>
            No telecom operators currently registered against this tower.
          </div>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))", gap: 14 }}>
            {ops.map((op) => (
              <div
                key={op.id}
                style={{
                  padding: "14px",
                  background: "var(--bg-surface-elevated)",
                  border: "1px solid var(--border-color)",
                  borderRadius: "var(--radius-md)",
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                }}
              >
                <div
                  style={{
                    width: 36,
                    height: 36,
                    borderRadius: "var(--radius-sm)",
                    background: "rgba(99, 102, 241, 0.15)",
                    color: "var(--primary-light)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: 700,
                    fontSize: "0.8rem",
                  }}
                >
                  {op.short_name || op.name?.slice(0, 3).toUpperCase()}
                </div>
                <div>
                  <div style={{ fontWeight: 700, fontSize: "0.9rem" }}>{op.name}</div>
                  <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
                    Code: {op.short_name || "N/A"}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Payment History Ledger */}
      <div className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">Payment History</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
              Official challans and rent payments recorded for this tower
            </p>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <span style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-primary)" }}>
              Total Collected: ₹{totalPaidAmount.toLocaleString("en-IN")}
            </span>
            <button className="btn btn-primary btn-sm" onClick={() => setIsPaymentModalOpen(true)}>
              <Plus size={14} /> Record Payment
            </button>
          </div>
        </div>

        {payments.length === 0 ? (
          <div style={{ textAlign: "center", padding: "32px 0", color: "var(--text-muted)", fontSize: "0.85rem" }}>
            <CreditCard size={32} style={{ opacity: 0.5, marginBottom: 8 }} />
            <p>No payment records found for this tower yet.</p>
          </div>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Challan / Ref #</th>
                  <th>Payment Date</th>
                  <th>Amount (₹)</th>
                  <th>Payment Mode</th>
                  <th>Remarks</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p, idx) => (
                  <tr key={p.id || idx}>
                    <td style={{ fontWeight: 700, color: "var(--accent-cyan)" }}>
                      {p.challan_number || `CHL-${p.id}`}
                    </td>
                    <td>{formatDate(p.payment_date)}</td>
                    <td style={{ fontWeight: 700 }}>
                      ₹{Number(p.amount || 0).toLocaleString("en-IN")}
                    </td>
                    <td>
                      <span className="badge badge-neutral" style={{ textTransform: "capitalize" }}>
                        {p.payment_mode || "Online"}
                      </span>
                    </td>
                    <td style={{ color: "var(--text-muted)", fontSize: "0.82rem" }}>
                      {p.remarks || "Rent payment"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Operator Assignment Modal */}
      {isOpModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsOpModalOpen(false)}>
          <div className="modal-content" style={{ maxWidth: 500 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ fontSize: "1.15rem" }}>Assign Operators to Tower</h3>
              <button className="btn btn-secondary btn-icon btn-sm" onClick={() => setIsOpModalOpen(false)}>
                <X size={16} />
              </button>
            </div>
            <div className="modal-body">
              <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", marginBottom: 14 }}>
                Select all telecom operators who have active base stations installed on this tower:
              </p>
              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                {allOperators.map((op) => {
                  const isChecked = selectedOpIds.includes(op.id);
                  return (
                    <label
                      key={op.id}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 10,
                        padding: "10px 14px",
                        background: isChecked ? "rgba(6, 182, 212, 0.12)" : "var(--bg-surface-elevated)",
                        border: `1px solid ${isChecked ? "var(--accent-cyan)" : "var(--border-color)"}`,
                        borderRadius: "var(--radius-md)",
                        cursor: "pointer",
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => handleToggleOp(op.id)}
                        style={{ accentColor: "var(--accent-cyan)" }}
                      />
                      <div style={{ fontWeight: 600, fontSize: "0.9rem" }}>{op.name}</div>
                      <span style={{ marginLeft: "auto", fontSize: "0.75rem", color: "var(--text-muted)" }}>
                        {op.short_name}
                      </span>
                    </label>
                  );
                })}
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setIsOpModalOpen(false)}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={handleSaveOperators} disabled={isSavingOps}>
                {isSavingOps ? "Saving Changes..." : "Update Operators"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Record Payment Modal */}
      {isPaymentModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsPaymentModalOpen(false)}>
          <div className="modal-content" style={{ maxWidth: 500 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ fontSize: "1.15rem" }}>Record Challan / Rent Payment</h3>
              <button className="btn btn-secondary btn-icon btn-sm" onClick={() => setIsPaymentModalOpen(false)}>
                <X size={16} />
              </button>
            </div>
            <form onSubmit={handleRecordPayment}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Payment Amount (₹) *</label>
                  <input
                    type="number"
                    className="form-control"
                    placeholder="e.g. 120000"
                    value={paymentForm.amount}
                    onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Challan / Transaction Reference *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. CHL-GOA-2026-0091"
                    value={paymentForm.challan_number}
                    onChange={(e) => setPaymentForm({ ...paymentForm, challan_number: e.target.value })}
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Payment Date *</label>
                    <input
                      type="date"
                      className="form-control"
                      value={paymentForm.payment_date}
                      onChange={(e) => setPaymentForm({ ...paymentForm, payment_date: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Payment Mode</label>
                    <select
                      className="form-select"
                      value={paymentForm.payment_mode}
                      onChange={(e) => setPaymentForm({ ...paymentForm, payment_mode: e.target.value })}
                    >
                      <option value="online">Online / RTGS / NEFT</option>
                      <option value="challan">Government Treasury Challan</option>
                      <option value="dd">Demand Draft (DD)</option>
                      <option value="cheque">Cheque</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Remarks</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Annual lease renewal"
                    value={paymentForm.remarks}
                    onChange={(e) => setPaymentForm({ ...paymentForm, remarks: e.target.value })}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setIsPaymentModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSavingPayment}>
                  {isSavingPayment ? "Recording Payment..." : "Save Payment"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Tower Modal */}
      {isEditModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsEditModalOpen(false)}>
          <div className="modal-content modal-lg" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <h2>Update Tower Specifications & Parameters</h2>
                <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginTop: 2 }}>
                  Edit technical specifications, ownership records, and rent terms for {tower.tower_unique_id}
                </p>
              </div>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsEditModalOpen(false)}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleUpdateTower}>
              <div className="modal-body">
                {/* 1. Identification & Land Ownership */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginBottom: 12 }}>
                  1. Identification & Land Ownership
                </div>

                <div className="form-grid-3" style={{ marginBottom: 16 }}>
                  <div className="form-group">
                    <label className="form-label">Tower Unique ID *</label>
                    <input
                      type="text"
                      className="form-control"
                      value={editFormData.tower_unique_id}
                      onChange={(e) => setEditFormData({ ...editFormData, tower_unique_id: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Land Ownership *</label>
                    <select
                      className="form-select"
                      value={editFormData.land_type}
                      onChange={(e) => setEditFormData({ ...editFormData, land_type: e.target.value })}
                    >
                      <option value="government">Government Land</option>
                      <option value="private">Private Land</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Tower Owner *</label>
                    <select
                      className="form-select"
                      value={editFormData.owner_id}
                      onChange={(e) => setEditFormData({ ...editFormData, owner_id: e.target.value })}
                      required
                    >
                      <option value="">-- Select Registered Owner --</option>
                      {owners.map((o) => (
                        <option key={o.id} value={o.id}>
                          {o.name} ({o.type || "Provider"})
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                {/* 2. Geographical Location Hierarchy */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginBottom: 12 }}>
                  2. Geographic Location Hierarchy
                </div>

                <div className="form-grid-3" style={{ marginBottom: 12 }}>
                  <div className="form-group">
                    <label className="form-label">District</label>
                    <select
                      className="form-select"
                      value={editFormData.district_id}
                      onChange={(e) =>
                        setEditFormData({
                          ...editFormData,
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
                      value={editFormData.taluka_id}
                      onChange={(e) =>
                        setEditFormData({
                          ...editFormData,
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
                      value={editFormData.area_id}
                      onChange={(e) => setEditFormData({ ...editFormData, area_id: e.target.value })}
                      required
                      disabled={!editFormData.taluka_id}
                    >
                      <option value="">
                        {!editFormData.taluka_id
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
                  <label className="form-label">Site Street Address</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Survey No. 42/1, Near Panchayat Hall"
                    value={editFormData.address}
                    onChange={(e) => setEditFormData({ ...editFormData, address: e.target.value })}
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
                  </div>

                  <div className="form-grid-2">
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label" style={{ fontSize: "0.78rem" }}>Exact Latitude (°N)</label>
                      <input
                        type="number"
                        step="0.000001"
                        className="form-control"
                        placeholder="e.g. 15.40182"
                        value={editFormData.latitude}
                        onChange={(e) => setEditFormData({ ...editFormData, latitude: e.target.value })}
                      />
                    </div>

                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label" style={{ fontSize: "0.78rem" }}>Exact Longitude (°E)</label>
                      <input
                        type="number"
                        step="0.000001"
                        className="form-control"
                        placeholder="e.g. 74.01525"
                        value={editFormData.longitude}
                        onChange={(e) => setEditFormData({ ...editFormData, longitude: e.target.value })}
                      />
                    </div>
                  </div>
                </div>

                {/* 3. Structural & Technical Specifications */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginBottom: 12 }}>
                  3. Structural & Technical Specifications
                </div>

                <div className="form-grid-4" style={{ marginBottom: 16 }}>
                  <div className="form-group">
                    <label className="form-label" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      Tower Height
                      <span style={{ display: "flex", gap: 0, border: "1px solid var(--border-color)", borderRadius: 6, overflow: "hidden", marginLeft: 4 }}>
                        {["m", "ft"].map((u) => (
                          <button
                            key={u}
                            type="button"
                            onClick={() => handleSwitchEditHeightUnit(u)}
                            style={{
                              padding: "1px 8px",
                              fontSize: "0.7rem",
                              fontWeight: 600,
                              background: editHeightUnit === u ? "var(--accent-cyan)" : "transparent",
                              color: editHeightUnit === u ? "#0a0f1e" : "var(--text-secondary)",
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
                      placeholder={editHeightUnit === "m" ? "e.g. 35.0" : "e.g. 114.8"}
                      value={editFormData.height}
                      onChange={(e) => setEditFormData({ ...editFormData, height: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      Base Width / Space
                      <span style={{ display: "flex", gap: 0, border: "1px solid var(--border-color)", borderRadius: 6, overflow: "hidden", marginLeft: 4 }}>
                        {["m", "ft"].map((u) => (
                          <button
                            key={u}
                            type="button"
                            onClick={() => handleSwitchEditWidthUnit(u)}
                            style={{
                              padding: "1px 8px",
                              fontSize: "0.7rem",
                              fontWeight: 600,
                              background: editWidthUnit === u ? "var(--accent-cyan)" : "transparent",
                              color: editWidthUnit === u ? "#0a0f1e" : "var(--text-secondary)",
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
                      placeholder={editWidthUnit === "m" ? "e.g. 2.5" : "e.g. 8.2"}
                      value={editFormData.width}
                      onChange={(e) => setEditFormData({ ...editFormData, width: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Operating Frequency</label>
                    <select
                      className="form-select"
                      value={editFormData.frequency}
                      onChange={(e) => setEditFormData({ ...editFormData, frequency: e.target.value })}
                    >
                      <option value="2G/3G">2G / 3G</option>
                      <option value="4G">4G LTE</option>
                      <option value="4G/5G">4G / 5G Dual Band</option>
                      <option value="5G">5G Ultra-High Capacity</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Operational Status</label>
                    <select
                      className="form-select"
                      value={editFormData.status}
                      onChange={(e) => setEditFormData({ ...editFormData, status: e.target.value })}
                    >
                      <option value="active">Active & Operational</option>
                      <option value="inactive">Inactive / Decommissioned</option>
                      <option value="maintenance">Under Maintenance</option>
                    </select>
                  </div>
                </div>

                {/* 4. Financial & Rent Cycle Parameters */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginBottom: 12 }}>
                  4. Rent Cycle & Financial Terms
                </div>

                <div className="form-grid-4" style={{ marginBottom: 12 }}>
                  <div className="form-group">
                    <label className="form-label">Yearly Rent (₹) *</label>
                    <input
                      type="number"
                      className="form-control"
                      placeholder="e.g. 120000"
                      value={editFormData.yearly_rent}
                      onChange={(e) => setEditFormData({ ...editFormData, yearly_rent: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rent Cycle Period</label>
                    <select
                      className="form-select"
                      value={editFormData.rent_cycle_years}
                      onChange={(e) => setEditFormData({ ...editFormData, rent_cycle_years: e.target.value })}
                    >
                      <option value={1}>1 Year (Annual)</option>
                      <option value={2}>2 Years</option>
                      <option value={3}>3 Years</option>
                      <option value={4}>4 Years</option>
                      <option value={5}>5 Years</option>
                      <option value={10}>10 Years (Long Term)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Installation Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={editFormData.installation_date}
                      onChange={(e) => setEditFormData({ ...editFormData, installation_date: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rent Start Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={editFormData.rent_start_date}
                      onChange={(e) => setEditFormData({ ...editFormData, rent_start_date: e.target.value })}
                    />
                  </div>
                </div>

                {/* Live Dynamic Calculated Total Amount */}
                <div className="calculated-total-box" style={{ marginBottom: 16 }}>
                  <div className="calculated-total-details">
                    <div className="calculated-total-title">Calculated Total Cycle Valuation</div>
                    <div className="calculated-total-calc">
                      ₹{editYearlyVal.toLocaleString("en-IN")} / year × {editCycleVal} Year{editCycleVal > 1 ? "s" : ""}
                    </div>
                  </div>
                  <div className="calculated-total-figure">
                    ₹{editTotalValuation.toLocaleString("en-IN")}
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setIsEditModalOpen(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={isSavingTower}
                >
                  {isSavingTower ? "Updating Tower..." : "Update Tower"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default TowerDetails;
