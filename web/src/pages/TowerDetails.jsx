import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
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
  TrendingUp,
  Clock,
  ShieldAlert,
  CheckCircle2,
  History,
  FileText,
  AlertCircle,
  ArrowUpRight,
} from "lucide-react";
import Loading from "../components/Loading";
import towerApi from "../api/towerApi";
import rentApi from "../api/rentApi";
import { useAuth } from "../context/AuthContext";
import { GOA_EXACT_LOCATION_COORDS } from "./MapView";

export const TowerDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const canRenew = user?.role === "admin" || user?.role === "officer";

  const [tower, setTower] = useState(null);
  const [payments, setPayments] = useState([]);
  const [renewals, setRenewals] = useState([]);
  const [allOperators, setAllOperators] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // Renewal & Escalation Modal State
  const [isRenewalModalOpen, setIsRenewalModalOpen] = useState(false);
  const [renewalPreview, setRenewalPreview] = useState(null);
  const [isLoadingPreview, setIsLoadingPreview] = useState(false);
  const [isSubmittingRenewal, setIsSubmittingRenewal] = useState(false);
  const [renewalError, setRenewalError] = useState(null);
  const [renewalSuccessMsg, setRenewalSuccessMsg] = useState(null);
  const [renewalForm, setRenewalForm] = useState({
    renewal_cycle_years: 5,
    escalation_enabled: true,
    escalation_percentage: "10",
    new_agreement_start_date: "",
    new_agreement_end_date: "",
    effective_date: "",
    is_manual_override: false,
    override_yearly_rent: "",
    override_reason: "",
    remarks: "",
  });

  // Direct Escalation Rate Adjustment Modal State
  const [isAdjustRateModalOpen, setIsAdjustRateModalOpen] = useState(false);
  const [adjustRateForm, setAdjustRateForm] = useState({
    escalation_enabled: true,
    escalation_percentage: "10",
  });
  const [isSubmittingAdjustRate, setIsSubmittingAdjustRate] = useState(false);
  const [adjustRateError, setAdjustRateError] = useState(null);

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
    escalation_enabled: true,
    escalation_percentage: 10,
    agreement_start_date: "",
    agreement_end_date: "",
    address: "",
  });

  const loadDetails = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [towerData, paymentsData, operatorsData, renewalsData] = await Promise.all([
        towerApi.getTower(id),
        rentApi.getTowerPayments(id).catch(() => []),
        towerApi.getOperators().catch(() => []),
        towerApi.getTowerRenewals(id).catch(() => []),
      ]);
      setTower(towerData);
      setPayments(paymentsData || towerData?.rent_payments || []);
      setAllOperators(operatorsData);
      setRenewals(renewalsData || towerData?.renewals || []);

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

  // Open Renewal Modal and fetch initial preview
  const handleOpenRenewalModal = async () => {
    setRenewalError(null);
    setRenewalSuccessMsg(null);
    const cycle = tower?.rent_cycle_years || 5;
    const prevEnd = tower?.agreement_end_date || tower?.next_renewal_date;
    const startStr = prevEnd ? String(prevEnd).split("T")[0] : new Date().toISOString().split("T")[0];
    
    // Auto-compute end date
    const startDateObj = new Date(startStr);
    const endDateObj = new Date(startDateObj);
    endDateObj.setFullYear(endDateObj.getFullYear() + cycle);
    const endStr = endDateObj.toISOString().split("T")[0];

    const currentRate = tower?.escalation_percentage != null ? String(tower.escalation_percentage) : "10";
    const isEscEnabled = tower?.escalation_enabled !== false;

    const initialForm = {
      renewal_cycle_years: cycle,
      escalation_enabled: isEscEnabled,
      escalation_percentage: currentRate,
      new_agreement_start_date: startStr,
      new_agreement_end_date: endStr,
      effective_date: startStr,
      is_manual_override: false,
      override_yearly_rent: "",
      override_reason: "",
      remarks: `Official agreement renewal for ${cycle} years.`,
    };
    setRenewalForm(initialForm);
    setIsRenewalModalOpen(true);

    setIsLoadingPreview(true);
    try {
      const previewRes = await towerApi.previewRenewal(id, {
        renewal_cycle_years: cycle,
        new_agreement_start_date: startStr,
        new_agreement_end_date: endStr,
        effective_date: startStr,
        escalation_percentage: parseFloat(currentRate) || 10,
        escalation_enabled: isEscEnabled,
      });
      setRenewalPreview(previewRes?.data || previewRes);
    } catch (err) {
      console.error("Preview failed:", err);
      setRenewalError(err.response?.data?.error || err.message || "Failed to calculate renewal preview.");
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleCycleChangeInRenewal = async (newCycle) => {
    const cycle = parseInt(newCycle, 10) || 5;
    const startStr = renewalForm.new_agreement_start_date || new Date().toISOString().split("T")[0];
    const startDateObj = new Date(startStr);
    const endDateObj = new Date(startDateObj);
    endDateObj.setFullYear(endDateObj.getFullYear() + cycle);
    const endStr = endDateObj.toISOString().split("T")[0];

    setRenewalForm((prev) => ({
      ...prev,
      renewal_cycle_years: cycle,
      new_agreement_end_date: endStr,
    }));

    setIsLoadingPreview(true);
    try {
      const previewRes = await towerApi.previewRenewal(id, {
        renewal_cycle_years: cycle,
        new_agreement_start_date: startStr,
        new_agreement_end_date: endStr,
        effective_date: renewalForm.effective_date || startStr,
        escalation_percentage: parseFloat(renewalForm.escalation_percentage) || 10,
        escalation_enabled: renewalForm.escalation_enabled !== false,
      });
      setRenewalPreview(previewRes?.data || previewRes);
    } catch (err) {
      setRenewalError(err.response?.data?.error || err.message || "Failed to update preview.");
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleStartDateChangeInRenewal = async (newStartDate) => {
    const startStr = newStartDate;
    const cycle = parseInt(renewalForm.renewal_cycle_years, 10) || 5;
    let endStr = renewalForm.new_agreement_end_date;
    if (startStr) {
      const startDateObj = new Date(startStr);
      if (!isNaN(startDateObj.getTime())) {
        const endDateObj = new Date(startDateObj);
        endDateObj.setFullYear(endDateObj.getFullYear() + cycle);
        endStr = endDateObj.toISOString().split("T")[0];
      }
    }

    setRenewalForm((prev) => ({
      ...prev,
      new_agreement_start_date: startStr,
      new_agreement_end_date: endStr,
      effective_date: startStr,
    }));

    setIsLoadingPreview(true);
    try {
      const previewRes = await towerApi.previewRenewal(id, {
        renewal_cycle_years: cycle,
        new_agreement_start_date: startStr,
        new_agreement_end_date: endStr,
        effective_date: startStr,
        escalation_percentage: parseFloat(renewalForm.escalation_percentage) || 10,
        escalation_enabled: renewalForm.escalation_enabled !== false,
      });
      setRenewalPreview(previewRes?.data || previewRes);
    } catch (err) {
      setRenewalError(err.response?.data?.error || err.message || "Failed to update preview.");
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleEscalationPercentageChangeInRenewal = async (newPct) => {
    setRenewalForm((prev) => ({
      ...prev,
      escalation_percentage: newPct,
    }));

    const pctNum = parseFloat(newPct);
    if (isNaN(pctNum) || pctNum < 0) return;

    setIsLoadingPreview(true);
    try {
      const previewRes = await towerApi.previewRenewal(id, {
        renewal_cycle_years: parseInt(renewalForm.renewal_cycle_years, 10) || 5,
        new_agreement_start_date: renewalForm.new_agreement_start_date,
        new_agreement_end_date: renewalForm.new_agreement_end_date,
        effective_date: renewalForm.effective_date || renewalForm.new_agreement_start_date,
        escalation_percentage: pctNum,
        escalation_enabled: renewalForm.escalation_enabled !== false,
      });
      setRenewalPreview(previewRes?.data || previewRes);
    } catch (err) {
      console.error("Preview failed:", err);
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleEscalationToggleInRenewal = async (newEnabled) => {
    setRenewalForm((prev) => ({
      ...prev,
      escalation_enabled: newEnabled,
    }));

    setIsLoadingPreview(true);
    try {
      const previewRes = await towerApi.previewRenewal(id, {
        renewal_cycle_years: parseInt(renewalForm.renewal_cycle_years, 10) || 5,
        new_agreement_start_date: renewalForm.new_agreement_start_date,
        new_agreement_end_date: renewalForm.new_agreement_end_date,
        effective_date: renewalForm.effective_date || renewalForm.new_agreement_start_date,
        escalation_percentage: parseFloat(renewalForm.escalation_percentage) || 10,
        escalation_enabled: newEnabled,
      });
      setRenewalPreview(previewRes?.data || previewRes);
    } catch (err) {
      console.error("Preview failed:", err);
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleConfirmRenewal = async (e) => {
    e.preventDefault();
    setIsSubmittingRenewal(true);
    setRenewalError(null);
    try {
      const payload = {
        renewal_cycle_years: parseInt(renewalForm.renewal_cycle_years, 10) || 5,
        new_agreement_start_date: renewalForm.new_agreement_start_date,
        new_agreement_end_date: renewalForm.new_agreement_end_date,
        effective_date: renewalForm.effective_date || renewalForm.new_agreement_start_date,
        escalation_enabled: renewalForm.escalation_enabled !== false,
        escalation_percentage: parseFloat(renewalForm.escalation_percentage) || 0,
        remarks: renewalForm.remarks,
      };

      if (renewalForm.is_manual_override) {
        if (!isAdmin) {
          throw new Error("Only authorized administrators are permitted to manually override yearly rent.");
        }
        if (!renewalForm.override_yearly_rent || parseFloat(renewalForm.override_yearly_rent) <= 0) {
          throw new Error("Please enter a valid positive overridden yearly rent amount.");
        }
        if (!renewalForm.override_reason?.trim()) {
          throw new Error("A justification reason is mandatory when manually overriding rent escalation.");
        }
        payload.override_yearly_rent = parseFloat(renewalForm.override_yearly_rent);
        payload.override_reason = renewalForm.override_reason.trim();
      }

      const res = await towerApi.confirmRenewal(id, payload);
      setIsRenewalModalOpen(false);
      setRenewalSuccessMsg(res?.message || "Rental agreement renewed successfully!");
      await loadDetails();
      setTimeout(() => setRenewalSuccessMsg(null), 8000);
    } catch (err) {
      console.error("Renewal confirmation failed:", err);
      setRenewalError(err.response?.data?.error || err.message || "Failed to confirm agreement renewal.");
    } finally {
      setIsSubmittingRenewal(false);
    }
  };

  // Direct escalation rate adjustment modal handlers
  const handleOpenAdjustRateModal = () => {
    setAdjustRateForm({
      escalation_enabled: tower?.escalation_enabled !== false,
      escalation_percentage: String(tower?.escalation_percentage != null ? tower.escalation_percentage : 10),
    });
    setAdjustRateError(null);
    setIsAdjustRateModalOpen(true);
  };

  const handleSaveAdjustRate = async (e) => {
    e.preventDefault();
    setIsSubmittingAdjustRate(true);
    setAdjustRateError(null);
    try {
      const pct = parseFloat(adjustRateForm.escalation_percentage);
      if (isNaN(pct) || pct < 0 || pct > 100) {
        throw new Error("Please enter a valid escalation percentage between 0% and 100%.");
      }
      await towerApi.updateEscalation(id, {
        escalation_enabled: adjustRateForm.escalation_enabled,
        escalation_percentage: pct,
      });
      setIsAdjustRateModalOpen(false);
      setRenewalSuccessMsg(`Escalation configuration updated successfully to ${pct}%.`);
      await loadDetails();
      setTimeout(() => setRenewalSuccessMsg(null), 6000);
    } catch (err) {
      setAdjustRateError(err.response?.data?.error || err.message || "Failed to update escalation rate.");
    } finally {
      setIsSubmittingAdjustRate(false);
    }
  };

  useEffect(() => {
    if (searchParams.get("action") === "renew" && tower && !isRenewalModalOpen) {
      handleOpenRenewalModal();
    }
  }, [searchParams, tower]);

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
        escalation_enabled: tower.escalation_enabled !== false,
        escalation_percentage: tower.escalation_percentage != null ? tower.escalation_percentage : 10,
        agreement_start_date: tower.agreement_start_date ? String(tower.agreement_start_date).split("T")[0] : (tower.rent_start_date ? String(tower.rent_start_date).split("T")[0] : ""),
        agreement_end_date: tower.agreement_end_date ? String(tower.agreement_end_date).split("T")[0] : "",
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
      const cleanAgreementStartDate = editFormData.agreement_start_date
        ? String(editFormData.agreement_start_date).split("T")[0]
        : null;
      const cleanAgreementEndDate = editFormData.agreement_end_date
        ? String(editFormData.agreement_end_date).split("T")[0]
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
        escalation_enabled: Boolean(editFormData.escalation_enabled),
        escalation_percentage: parseFloat(editFormData.escalation_percentage) || 0,
        agreement_start_date: cleanAgreementStartDate,
        agreement_end_date: cleanAgreementEndDate,
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
            {canRenew && (
              <button
                className="btn btn-warning btn-sm"
                onClick={handleOpenRenewalModal}
                title="Renew Rental Agreement & Escalate Rent"
                style={{
                  background: "linear-gradient(135deg, #f59e0b, #d97706)",
                  color: "#ffffff",
                  border: "none",
                  fontWeight: 600,
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                }}
              >
                <TrendingUp size={14} /> Renew Agreement
              </button>
            )}
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

      {renewalSuccessMsg && (
        <div
          style={{
            background: "rgba(16, 185, 129, 0.15)",
            border: "1px solid #10b981",
            color: "#34d399",
            padding: "12px 16px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <CheckCircle2 size={18} />
          <span>{renewalSuccessMsg}</span>
        </div>
      )}

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

      {/* Rent Escalation Configuration Card */}
      <div className="card" style={{ marginBottom: 24, borderLeft: "4px solid #f59e0b" }}>
        <div className="card-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <TrendingUp size={20} color="#f59e0b" />
              <h3 className="card-title" style={{ margin: 0 }}>Rent Escalation Configuration</h3>
              <span
                className={`badge ${
                  tower.escalation_enabled !== false ? "badge-success" : "badge-neutral"
                }`}
                style={{ fontSize: "0.75rem" }}
              >
                {tower.escalation_enabled !== false ? "Automatic Escalation Enabled" : "Escalation Disabled"}
              </span>
            </div>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: 4 }}>
              Configured statutory lease parameters and compounding rent revision rules for this tower
            </p>
          </div>

          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {canRenew && (
              <button
                className="btn btn-warning btn-sm"
                onClick={handleOpenRenewalModal}
                title="Initiate rental agreement renewal with compounding rent increase"
                style={{
                  background: "linear-gradient(135deg, #f59e0b, #d97706)",
                  color: "#fff",
                  border: "none",
                  fontWeight: 600,
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                }}
              >
                <TrendingUp size={14} />
                <span>Renew Agreement &amp; Escalate Rent</span>
              </button>
            )}
            {isAdmin && (
              <>
                <button
                  className="btn btn-secondary btn-sm"
                  onClick={handleOpenAdjustRateModal}
                  title="Manually adjust rent escalation rate (%)"
                  style={{ display: "flex", alignItems: "center", gap: 6 }}
                >
                  <TrendingUp size={13} color="#f59e0b" />
                  <span>Adjust Escalation Rate</span>
                </button>
                <button
                  className="btn btn-secondary btn-sm"
                  onClick={handleOpenEditModal}
                  title="Edit Escalation Configuration"
                >
                  <Edit2 size={13} />
                  <span>Configure Escalation</span>
                </button>
              </>
            )}
          </div>
        </div>

        {/* 9 Requirements Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(210px, 1fr))", gap: 14, padding: "16px 0", borderBottom: "1px solid var(--border-color)" }}>
          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              1. Auto Escalation Status
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 6, fontWeight: 700, color: tower.escalation_enabled !== false ? "#10b981" : "var(--text-muted)" }}>
              {tower.escalation_enabled !== false ? (
                <>
                  <CheckCircle2 size={15} /> Enabled
                </>
              ) : (
                <>
                  <X size={15} /> Disabled
                </>
              )}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              2. Current Yearly Rent
            </div>
            <div style={{ fontWeight: 800, fontSize: "1.1rem", color: "var(--text-primary)" }}>
              ₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}
              <span style={{ fontSize: "0.75rem", fontWeight: 500, color: "var(--text-secondary)", marginLeft: 6 }}>
                (₹{Number(tower.monthly_rent || Math.round((tower.yearly_rent || 0) / 12)).toLocaleString("en-IN")}/mo)
              </span>
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
              <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em" }}>
                3. Escalation Rate (%)
              </div>
              {isAdmin && (
                <button
                  type="button"
                  className="btn btn-secondary btn-xs"
                  onClick={handleOpenAdjustRateModal}
                  style={{ padding: "2px 6px", fontSize: "0.7rem", height: "auto" }}
                  title="Manually adjust escalation rate"
                >
                  Adjust
                </button>
              )}
            </div>
            <div style={{ fontWeight: 800, fontSize: "1.1rem", color: "#f59e0b" }}>
              {tower.escalation_percentage != null ? tower.escalation_percentage : 10}%
              <span style={{ fontSize: "0.75rem", fontWeight: 500, color: "var(--text-secondary)", marginLeft: 6 }}>
                per renewal cycle
              </span>
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              4. Agreement Duration
            </div>
            <div style={{ fontWeight: 700, fontSize: "1rem", color: "var(--accent-cyan)" }}>
              {tower.rent_cycle_years || 5} Year{tower.rent_cycle_years > 1 ? "s" : ""}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              5. Agreement Start Date
            </div>
            <div style={{ fontWeight: 600, fontSize: "0.95rem" }}>
              {formatDate(tower.agreement_start_date || tower.rent_start_date)}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              6. Agreement End Date
            </div>
            <div style={{ fontWeight: 600, fontSize: "0.95rem" }}>
              {formatDate(tower.agreement_end_date || tower.next_renewal_date)}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              7. Next Renewal Date
            </div>
            <div style={{ fontWeight: 700, fontSize: "0.95rem", color: "#f59e0b" }}>
              {formatDate(tower.next_renewal_date || tower.agreement_end_date)}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              8. Last Revised Rent
            </div>
            <div style={{ fontWeight: 600, fontSize: "0.95rem" }}>
              ₹{Number(tower.last_revised_rent || tower.yearly_rent || 0).toLocaleString("en-IN")}
            </div>
          </div>

          <div style={{ padding: "12px", background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 4 }}>
              9. Last Escalation Date
            </div>
            <div style={{ fontWeight: 600, fontSize: "0.95rem" }}>
              {formatDate(tower.last_escalation_date) || "Initial Agreement"}
            </div>
          </div>
        </div>

        {/* Live Preview Box */}
        <div
          style={{
            marginTop: 16,
            padding: "14px 16px",
            borderRadius: "var(--radius-sm)",
            background: "rgba(245, 158, 11, 0.08)",
            border: "1px dashed rgba(245, 158, 11, 0.4)",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: 12,
          }}
        >
          <div>
            <div style={{ fontWeight: 700, fontSize: "0.9rem", color: "#f59e0b", display: "flex", alignItems: "center", gap: 6 }}>
              <TrendingUp size={16} /> Live Compounded Rent Projection on Next Renewal
            </div>
            <div style={{ fontSize: "0.82rem", color: "var(--text-secondary)", marginTop: 4 }}>
              {tower.escalation_enabled !== false ? (
                <span>
                  Configured rate <strong>{tower.escalation_percentage || 10}%</strong> on current rent of <strong>₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}</strong> yields an increase of <strong>₹{Number(Math.round((tower.yearly_rent || 0) * (tower.escalation_percentage || 10) / 100)).toLocaleString("en-IN")}</strong>.
                </span>
              ) : (
                <span>
                  Automatic escalation is currently <strong>disabled</strong> for this tower. Renewal will maintain current yearly rent unless manually adjusted.
                </span>
              )}
            </div>
          </div>

          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase" }}>
              Projected Revised Rent
            </div>
            <div style={{ fontSize: "1.3rem", fontWeight: 800, color: tower.escalation_enabled !== false ? "#10b981" : "var(--text-primary)" }}>
              ₹{Number(
                tower.escalation_enabled !== false
                  ? Math.round((tower.yearly_rent || 0) * (1 + (tower.escalation_percentage || 10) / 100))
                  : (tower.yearly_rent || 0)
              ).toLocaleString("en-IN")}
              <span style={{ fontSize: "0.8rem", fontWeight: 600, color: "var(--text-secondary)" }}> / yr</span>
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

      {/* Rent Revision & Agreement Renewal History Ledger */}
      <div className="card" style={{ marginTop: 24, marginBottom: 24 }}>
        <div className="card-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 10 }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <History size={18} color="#f59e0b" />
              <h3 className="card-title" style={{ margin: 0 }}>Rental Agreement &amp; Rent Revision History</h3>
              <span className="badge badge-info" style={{ fontSize: "0.75rem" }}>
                {renewals.length} Revision{renewals.length !== 1 ? "s" : ""}
              </span>
            </div>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: 4 }}>
              Immutable audit ledger of confirmed agreement renewals, compounded rent calculations, and authorized overrides
            </p>
          </div>
          {canRenew && (
            <button className="btn btn-warning btn-sm" onClick={handleOpenRenewalModal}>
              <TrendingUp size={14} /> Renew Agreement
            </button>
          )}
        </div>

        {renewals.length === 0 ? (
          <div style={{ textAlign: "center", padding: "32px 0", color: "var(--text-muted)", fontSize: "0.85rem" }}>
            <FileText size={32} style={{ opacity: 0.5, marginBottom: 8 }} />
            <p>No agreement renewals have been recorded for this tower yet.</p>
            <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
              Initial baseline annual rent is <strong>₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}</strong>.
            </p>
          </div>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Renewal Ref #</th>
                  <th>Effective Date</th>
                  <th>Previous Rent</th>
                  <th>Escalation %</th>
                  <th>Increase (₹)</th>
                  <th>Revised Rent</th>
                  <th>Agreement Period</th>
                  <th>Approved By</th>
                  <th>Audit Status</th>
                </tr>
              </thead>
              <tbody>
                {renewals.map((r) => (
                  <tr key={r.id || r.renewal_reference}>
                    <td style={{ fontWeight: 700, color: "var(--accent-cyan)", fontSize: "0.82rem" }}>
                      {r.renewal_reference}
                    </td>
                    <td>{formatDate(r.effective_date)}</td>
                    <td style={{ color: "var(--text-secondary)" }}>
                      ₹{Number(r.previous_yearly_rent || 0).toLocaleString("en-IN")}
                    </td>
                    <td>
                      <span className="badge badge-info" style={{ fontWeight: 700 }}>
                        {r.escalation_percentage}%
                      </span>
                    </td>
                    <td style={{ fontWeight: 700, color: "#10b981" }}>
                      +₹{Number(r.increase_amount || 0).toLocaleString("en-IN")}
                    </td>
                    <td style={{ fontWeight: 800, color: "var(--text-primary)" }}>
                      ₹{Number(r.new_yearly_rent || 0).toLocaleString("en-IN")}
                    </td>
                    <td style={{ fontSize: "0.8rem" }}>
                      {formatDate(r.new_agreement_start_date)} ➔ {formatDate(r.new_agreement_end_date)}
                      <div style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>
                        {r.renewal_cycle_years} Year Cycle
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: "0.85rem", fontWeight: 600 }}>
                        {r.approved_by_details?.name || r.approved_by_name || "Administrator"}
                      </div>
                      <div style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>
                        {r.approved_by_details?.role ? String(r.approved_by_details.role).toUpperCase() : "ADMIN"}
                      </div>
                    </td>
                    <td>
                      {r.is_manual_override ? (
                        <div>
                          <span className="badge badge-warning" style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                            <AlertCircle size={11} /> Overridden
                          </span>
                          {r.manual_override_reason && (
                            <div style={{ fontSize: "0.72rem", color: "#f59e0b", marginTop: 2, maxWidth: 160 }} title={r.manual_override_reason}>
                              "{r.manual_override_reason}"
                            </div>
                          )}
                        </div>
                      ) : (
                        <span className="badge badge-success">
                          Confirmed
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Agreement Renewal & Rent Escalation Modal */}
      {isRenewalModalOpen && (
        <div className="modal-backdrop" onClick={() => !isSubmittingRenewal && setIsRenewalModalOpen(false)}>
          <div className="modal-content modal-lg" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 750 }}>
            <div className="modal-header" style={{ borderBottom: "1px solid var(--border-color)", paddingBottom: 14 }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <TrendingUp size={20} color="#f59e0b" />
                  <h3 style={{ fontSize: "1.2rem", margin: 0, fontWeight: 700 }}>
                    Rental Agreement Renewal &amp; Rent Escalation
                  </h3>
                </div>
                <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: 4 }}>
                  Confirm statutory lease renewal for {tower.tower_unique_id}. Rent increases are compounded and applied only upon confirmation.
                </p>
              </div>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsRenewalModalOpen(false)}
                disabled={isSubmittingRenewal}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleConfirmRenewal}>
              <div className="modal-body" style={{ maxHeight: "75vh", overflowY: "auto", padding: "20px 24px" }}>
                {renewalError && (
                  <div
                    style={{
                      background: "rgba(239, 68, 68, 0.15)",
                      border: "1px solid #ef4444",
                      color: "#f87171",
                      padding: "10px 14px",
                      borderRadius: "var(--radius-sm)",
                      marginBottom: 16,
                      fontSize: "0.85rem",
                    }}
                  >
                    {renewalError}
                  </div>
                )}

                {/* Summary Info Cards */}
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
                    gap: 12,
                    marginBottom: 20,
                    padding: 14,
                    background: "var(--bg-surface-elevated)",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                  }}
                >
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Tower ID</span>
                    <strong style={{ color: "var(--accent-cyan)", fontSize: "0.95rem" }}>{tower.tower_unique_id}</strong>
                  </div>
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Location</span>
                    <span style={{ fontSize: "0.85rem", fontWeight: 600 }}>{area.name || "N/A"}, {taluka.name || "Goa"}</span>
                  </div>
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Owner Entity</span>
                    <span style={{ fontSize: "0.85rem", fontWeight: 600 }}>{owner.name || (tower.land_type === "government" ? "Government of Goa" : "Private")}</span>
                  </div>
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Previous Yearly Rent</span>
                    <strong style={{ fontSize: "1.05rem", color: "var(--text-primary)" }}>₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}</strong>
                  </div>
                  <div style={{ gridColumn: "1 / -1", borderTop: "1px solid var(--border-color)", paddingTop: 8, marginTop: 4, display: "flex", justifyContent: "space-between", fontSize: "0.8rem" }}>
                    <span style={{ color: "var(--text-secondary)" }}>Previous Agreement Tenure:</span>
                    <strong style={{ color: "var(--text-primary)" }}>
                      {formatDate(tower.agreement_start_date || tower.rent_start_date)} to {formatDate(tower.agreement_end_date || tower.next_renewal_date)}
                    </strong>
                  </div>
                </div>

                {/* Form Controls */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "var(--accent-cyan)", marginBottom: 10 }}>
                  1. New Agreement Tenure Parameters
                </div>

                <div className="form-grid-3" style={{ marginBottom: 16 }}>
                  <div className="form-group">
                    <label className="form-label">Renewal Period *</label>
                    <select
                      className="form-select"
                      value={renewalForm.renewal_cycle_years}
                      onChange={(e) => handleCycleChangeInRenewal(e.target.value)}
                      disabled={isSubmittingRenewal}
                      required
                    >
                      <option value={1}>1 Year (Annual)</option>
                      <option value={2}>2 Years</option>
                      <option value={3}>3 Years</option>
                      <option value={5}>5 Years (Standard Cycle)</option>
                      <option value={10}>10 Years (Long Term)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">New Agreement Start *</label>
                    <input
                      type="date"
                      className="form-control"
                      value={renewalForm.new_agreement_start_date}
                      onChange={(e) => handleStartDateChangeInRenewal(e.target.value)}
                      disabled={isSubmittingRenewal}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">New Agreement End *</label>
                    <input
                      type="date"
                      className="form-control"
                      value={renewalForm.new_agreement_end_date}
                      onChange={(e) => setRenewalForm({ ...renewalForm, new_agreement_end_date: e.target.value })}
                      disabled={isSubmittingRenewal}
                      required
                    />
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: 20 }}>
                  <label className="form-label">Effective Date *</label>
                  <input
                    type="date"
                    className="form-control"
                    value={renewalForm.effective_date}
                    onChange={(e) => setRenewalForm({ ...renewalForm, effective_date: e.target.value })}
                    disabled={isSubmittingRenewal}
                    required
                  />
                  <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
                    Date on which the new lease terms and revised rent become statutory
                  </div>
                </div>

                {/* Escalation Rate Adjustment Section */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "#f59e0b", marginBottom: 10, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <span>2. Escalation Rate & Compounding Settings</span>
                  <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", fontWeight: 400 }}>
                    Adjust rate for this agreement renewal
                  </span>
                </div>

                <div
                  style={{
                    padding: 14,
                    background: "var(--bg-surface-elevated)",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                    marginBottom: 16,
                  }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                    <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", fontWeight: 600, fontSize: "0.88rem" }}>
                      <input
                        type="checkbox"
                        checked={renewalForm.escalation_enabled !== false}
                        onChange={(e) => handleEscalationToggleInRenewal(e.target.checked)}
                        disabled={isSubmittingRenewal}
                      />
                      <span>Apply Rent Escalation on this Renewal</span>
                    </label>
                    <span className={`badge ${renewalForm.escalation_enabled !== false ? "badge-success" : "badge-neutral"}`} style={{ fontSize: "0.72rem" }}>
                      {renewalForm.escalation_enabled !== false ? "Active" : "Disabled (0% Increase)"}
                    </span>
                  </div>

                  {renewalForm.escalation_enabled !== false && (
                    <div>
                      <div className="form-group" style={{ marginBottom: 10 }}>
                        <label className="form-label" style={{ fontSize: "0.8rem", display: "flex", justifyContent: "space-between" }}>
                          <span>Escalation Rate (%)</span>
                          <span style={{ color: "var(--text-muted)" }}>Default configured: {tower.escalation_percentage != null ? tower.escalation_percentage : 10}%</span>
                        </label>
                        <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
                          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                            <input
                              type="number"
                              step="0.1"
                              min="0"
                              max="100"
                              className="form-control"
                              style={{ maxWidth: 120, fontWeight: 700, color: "#f59e0b" }}
                              value={renewalForm.escalation_percentage}
                              onChange={(e) => handleEscalationPercentageChangeInRenewal(e.target.value)}
                              disabled={isSubmittingRenewal}
                              required
                            />
                            <span style={{ fontWeight: 600, color: "var(--text-muted)" }}>%</span>
                          </div>

                          {/* Quick selection preset buttons */}
                          <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginLeft: 4 }}>
                            {[5, 8, 10, 12, 15, 20].map((rate) => (
                              <button
                                key={rate}
                                type="button"
                                className="btn btn-secondary btn-xs"
                                style={{
                                  padding: "3px 8px",
                                  fontSize: "0.75rem",
                                  borderColor: parseFloat(renewalForm.escalation_percentage) === rate ? "#f59e0b" : "var(--border-color)",
                                  background: parseFloat(renewalForm.escalation_percentage) === rate ? "rgba(245, 158, 11, 0.15)" : "transparent",
                                  color: parseFloat(renewalForm.escalation_percentage) === rate ? "#f59e0b" : "var(--text-secondary)",
                                  fontWeight: parseFloat(renewalForm.escalation_percentage) === rate ? 700 : 500,
                                }}
                                onClick={() => handleEscalationPercentageChangeInRenewal(rate)}
                                disabled={isSubmittingRenewal}
                              >
                                {rate}%
                              </button>
                            ))}
                            {tower.escalation_percentage != null && (
                              <button
                                type="button"
                                className="btn btn-secondary btn-xs"
                                style={{
                                  padding: "3px 8px",
                                  fontSize: "0.72rem",
                                  color: "var(--text-muted)",
                                }}
                                onClick={() => handleEscalationPercentageChangeInRenewal(tower.escalation_percentage)}
                                disabled={isSubmittingRenewal}
                                title="Reset to tower's base rate"
                              >
                                Reset ({tower.escalation_percentage}%)
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                      <div style={{ fontSize: "0.74rem", color: "var(--text-muted)" }}>
                        You can manually adjust the escalation rate for this renewal. The calculation below updates automatically.
                      </div>
                    </div>
                  )}
                </div>

                {/* Rent Escalation Preview Box */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "#f59e0b", marginBottom: 10 }}>
                  3. Compounded Rent Calculation Summary
                </div>

                <div
                  style={{
                    padding: 16,
                    background: "rgba(245, 158, 11, 0.08)",
                    border: "1px solid rgba(245, 158, 11, 0.3)",
                    borderRadius: "var(--radius-md)",
                    marginBottom: 20,
                  }}
                >
                  {isLoadingPreview ? (
                    <div style={{ padding: "16px 0", textAlign: "center", color: "var(--text-muted)" }}>
                      <RefreshCw size={20} className="spin" style={{ marginBottom: 6 }} />
                      <p>Calculating statutory compounding increase...</p>
                    </div>
                  ) : (
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 14 }}>
                      <div>
                        <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Current Rent</span>
                        <div style={{ fontWeight: 700, fontSize: "1rem" }}>
                          ₹{Number(renewalPreview?.previous_yearly_rent || tower.yearly_rent || 0).toLocaleString("en-IN")}
                        </div>
                      </div>
                      <div>
                        <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Escalation Rate</span>
                        <div style={{ fontWeight: 800, fontSize: "1.05rem", color: "#f59e0b" }}>
                          {renewalPreview?.escalation_enabled !== false ? `${renewalPreview?.escalation_percentage || tower.escalation_percentage || 10}%` : "Disabled (0%)"}
                        </div>
                      </div>
                      <div>
                        <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Increase Amount</span>
                        <div style={{ fontWeight: 800, fontSize: "1.05rem", color: "#10b981" }}>
                          +₹{Number(renewalPreview?.increase_amount || 0).toLocaleString("en-IN")}
                        </div>
                      </div>
                      <div>
                        <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Proposed New Rent</span>
                        <div style={{ fontWeight: 800, fontSize: "1.2rem", color: "var(--text-primary)" }}>
                          ₹{Number(renewalPreview?.proposed_yearly_rent || 0).toLocaleString("en-IN")}
                          <span style={{ fontSize: "0.75rem", fontWeight: 500, color: "var(--text-secondary)", display: "block" }}>
                            ₹{Number(renewalPreview?.proposed_monthly_rent || 0).toLocaleString("en-IN")}/mo
                          </span>
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Manual Override Section */}
                <div style={{ padding: 14, background: "var(--bg-surface-elevated)", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)", marginBottom: 16 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <div>
                      <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: isAdmin ? "pointer" : "not-allowed", fontWeight: 700, fontSize: "0.9rem", color: "var(--text-primary)" }}>
                        <input
                          type="checkbox"
                          checked={renewalForm.is_manual_override}
                          onChange={(e) => setRenewalForm({ ...renewalForm, is_manual_override: e.target.checked })}
                          disabled={!isAdmin || isSubmittingRenewal}
                        />
                        <span>Manual Rent Override (Admin Only)</span>
                      </label>
                      <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 2, marginLeft: 24 }}>
                        Enable if executive or council order dictates an annual rent differing from the auto-escalated calculation
                      </p>
                    </div>
                    {!isAdmin && (
                      <span className="badge badge-neutral" style={{ fontSize: "0.7rem" }}>
                        Requires Admin Role
                      </span>
                    )}
                  </div>

                  {renewalForm.is_manual_override && (
                    <div style={{ marginTop: 14, paddingTop: 14, borderTop: "1px dashed var(--border-color)" }}>
                      <div
                        style={{
                          background: "rgba(245, 158, 11, 0.1)",
                          border: "1px solid rgba(245, 158, 11, 0.3)",
                          color: "#fbbf24",
                          padding: "8px 12px",
                          borderRadius: "var(--radius-sm)",
                          fontSize: "0.78rem",
                          marginBottom: 14,
                          display: "flex",
                          alignItems: "center",
                          gap: 8,
                        }}
                      >
                        <ShieldAlert size={16} />
                        <span>
                          <strong>Audit Warning:</strong> Overridden values are permanently logged in the audit ledger with your identity ({user?.name || "Administrator"}).
                        </span>
                      </div>

                      <div className="form-grid-2">
                        <div className="form-group">
                          <label className="form-label">Approved Overridden Yearly Rent (₹) *</label>
                          <input
                            type="number"
                            className="form-control"
                            placeholder="e.g. 240000"
                            value={renewalForm.override_yearly_rent}
                            onChange={(e) => setRenewalForm({ ...renewalForm, override_yearly_rent: e.target.value })}
                            disabled={isSubmittingRenewal}
                            required={renewalForm.is_manual_override}
                          />
                        </div>

                        <div className="form-group">
                          <label className="form-label">Mandatory Justification Reason *</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Council Resolution #144/2026 or Special Co-location Tariff"
                            value={renewalForm.override_reason}
                            onChange={(e) => setRenewalForm({ ...renewalForm, override_reason: e.target.value })}
                            disabled={isSubmittingRenewal}
                            required={renewalForm.is_manual_override}
                          />
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                <div className="form-group">
                  <label className="form-label">Internal Renewal Remarks</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Agreement signed by both parties at North Goa Collectorate"
                    value={renewalForm.remarks}
                    onChange={(e) => setRenewalForm({ ...renewalForm, remarks: e.target.value })}
                    disabled={isSubmittingRenewal}
                  />
                </div>
              </div>

              <div className="modal-footer" style={{ borderTop: "1px solid var(--border-color)", padding: "14px 24px", display: "flex", justifyContent: "space-between" }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setIsRenewalModalOpen(false)}
                  disabled={isSubmittingRenewal}
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  className="btn btn-warning"
                  disabled={isSubmittingRenewal || isLoadingPreview}
                  style={{
                    background: "linear-gradient(135deg, #f59e0b, #d97706)",
                    color: "#fff",
                    fontWeight: 700,
                  }}
                >
                  {isSubmittingRenewal ? (
                    <>
                      <RefreshCw size={14} className="spin" /> Confirming Renewal...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 size={16} /> Confirm Renewal &amp; Apply Escalation
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

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

                {/* 5. Rent Escalation Configuration */}
                <div style={{ fontWeight: 700, fontSize: "0.85rem", color: "#f59e0b", marginTop: 14, marginBottom: 12, display: "flex", alignItems: "center", gap: 6 }}>
                  <TrendingUp size={15} /> 5. Rent Escalation Configuration
                </div>

                <div className="form-grid-3" style={{ marginBottom: 12 }}>
                  <div className="form-group">
                    <label className="form-label">Automatic Rent Escalation</label>
                    <select
                      className="form-select"
                      value={editFormData.escalation_enabled ? "true" : "false"}
                      onChange={(e) => setEditFormData({ ...editFormData, escalation_enabled: e.target.value === "true" })}
                    >
                      <option value="true">Enabled (Auto-Compounded)</option>
                      <option value="false">Disabled (No Escalation)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Escalation Rate (%)</label>
                    <input
                      type="number"
                      step="0.1"
                      min="0"
                      max="100"
                      className="form-control"
                      placeholder="e.g. 10"
                      value={editFormData.escalation_percentage}
                      onChange={(e) => setEditFormData({ ...editFormData, escalation_percentage: e.target.value })}
                      disabled={!editFormData.escalation_enabled}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Agreement Start Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={editFormData.agreement_start_date}
                      onChange={(e) => setEditFormData({ ...editFormData, agreement_start_date: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-grid-2" style={{ marginBottom: 14 }}>
                  <div className="form-group">
                    <label className="form-label">Agreement End Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={editFormData.agreement_end_date}
                      onChange={(e) => setEditFormData({ ...editFormData, agreement_end_date: e.target.value })}
                    />
                  </div>

                  {/* Live Escalation Calculation Preview in Edit Modal */}
                  <div
                    style={{
                      background: "rgba(245, 158, 11, 0.08)",
                      border: "1px dashed rgba(245, 158, 11, 0.4)",
                      borderRadius: "var(--radius-sm)",
                      padding: "10px 14px",
                      display: "flex",
                      flexDirection: "column",
                      justifyContent: "center",
                    }}
                  >
                    <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)", textTransform: "uppercase" }}>
                      Projected Rent on Next Renewal
                    </div>
                    <div style={{ fontSize: "1.05rem", fontWeight: 800, color: editFormData.escalation_enabled ? "#10b981" : "var(--text-primary)" }}>
                      {editFormData.escalation_enabled ? (
                        <>
                          ₹{Math.round(editYearlyVal * (1 + (parseFloat(editFormData.escalation_percentage) || 0) / 100)).toLocaleString("en-IN")}{" "}
                          <span style={{ fontSize: "0.75rem", color: "#f59e0b", fontWeight: 600 }}>
                            (+₹{Math.round(editYearlyVal * ((parseFloat(editFormData.escalation_percentage) || 0) / 100)).toLocaleString("en-IN")})
                          </span>
                        </>
                      ) : (
                        `₹${editYearlyVal.toLocaleString("en-IN")} (No Increase)`
                      )}
                    </div>
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

      {/* Adjust Escalation Rate Modal */}
      {isAdjustRateModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsAdjustRateModalOpen(false)}>
          <div className="modal-content" style={{ maxWidth: 520 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <TrendingUp size={22} color="#f59e0b" />
                <div>
                  <h3 style={{ fontSize: "1.15rem", margin: 0 }}>Adjust Rent Escalation Rate</h3>
                  <p style={{ fontSize: "0.78rem", color: "var(--text-muted)", marginTop: 2 }}>
                    Update automatic rent escalation rate for {tower.tower_unique_id}
                  </p>
                </div>
              </div>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsAdjustRateModalOpen(false)}
                disabled={isSubmittingAdjustRate}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleSaveAdjustRate}>
              <div className="modal-body">
                {adjustRateError && (
                  <div
                    style={{
                      background: "rgba(239, 68, 68, 0.15)",
                      border: "1px solid #ef4444",
                      color: "#ef4444",
                      padding: "10px 14px",
                      borderRadius: "var(--radius-md)",
                      marginBottom: 16,
                      fontSize: "0.85rem",
                    }}
                  >
                    {adjustRateError}
                  </div>
                )}

                {/* Quick Info Strip */}
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: 12,
                    padding: 12,
                    background: "var(--bg-surface-elevated)",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                    marginBottom: 16,
                  }}
                >
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Current Yearly Rent</span>
                    <strong style={{ fontSize: "1rem", color: "var(--text-primary)" }}>
                      ₹{Number(tower.yearly_rent || 0).toLocaleString("en-IN")}
                    </strong>
                  </div>
                  <div>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "block" }}>Current Configured Rate</span>
                    <strong style={{ fontSize: "1rem", color: "#f59e0b" }}>
                      {tower.escalation_percentage != null ? tower.escalation_percentage : 10}%
                    </strong>
                  </div>
                </div>

                <div
                  style={{
                    padding: 12,
                    background: "var(--bg-surface-elevated)",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                    marginBottom: 16,
                  }}
                >
                  <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", fontWeight: 600, fontSize: "0.9rem" }}>
                    <input
                      type="checkbox"
                      checked={adjustRateForm.escalation_enabled}
                      onChange={(e) => setAdjustRateForm({ ...adjustRateForm, escalation_enabled: e.target.checked })}
                      disabled={isSubmittingAdjustRate}
                    />
                    <span>Enable Automatic Rent Escalation</span>
                  </label>
                  <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4, marginLeft: 24 }}>
                    When enabled, yearly rent increases automatically upon agreement renewal
                  </p>
                </div>

                {adjustRateForm.escalation_enabled && (
                  <>
                    <div className="form-group" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontWeight: 600 }}>
                        Escalation Percentage (%) *
                      </label>
                      <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                        <input
                          type="number"
                          step="0.1"
                          min="0"
                          max="100"
                          className="form-control"
                          style={{ maxWidth: 140, fontWeight: 700, fontSize: "1.1rem", color: "#f59e0b" }}
                          value={adjustRateForm.escalation_percentage}
                          onChange={(e) => setAdjustRateForm({ ...adjustRateForm, escalation_percentage: e.target.value })}
                          disabled={isSubmittingAdjustRate}
                          required
                        />
                        <span style={{ fontWeight: 700, fontSize: "1.1rem", color: "var(--text-muted)" }}>%</span>
                      </div>
                      <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
                        Permitted range: 0% to 100%. Standard municipal rates range from 5% to 15%.
                      </div>
                    </div>

                    {/* Quick Presets */}
                    <div style={{ marginBottom: 16 }}>
                      <label style={{ fontSize: "0.75rem", color: "var(--text-secondary)", display: "block", marginBottom: 6 }}>
                        Quick Select Presets:
                      </label>
                      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                        {[5, 8, 10, 12, 15, 20].map((rate) => (
                          <button
                            key={rate}
                            type="button"
                            className="btn btn-secondary btn-sm"
                            style={{
                              padding: "4px 12px",
                              borderColor: parseFloat(adjustRateForm.escalation_percentage) === rate ? "#f59e0b" : "var(--border-color)",
                              background: parseFloat(adjustRateForm.escalation_percentage) === rate ? "rgba(245, 158, 11, 0.15)" : "var(--bg-surface-elevated)",
                              color: parseFloat(adjustRateForm.escalation_percentage) === rate ? "#f59e0b" : "var(--text-primary)",
                              fontWeight: parseFloat(adjustRateForm.escalation_percentage) === rate ? 700 : 500,
                            }}
                            onClick={() => setAdjustRateForm({ ...adjustRateForm, escalation_percentage: String(rate) })}
                            disabled={isSubmittingAdjustRate}
                          >
                            {rate}%
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Live Calculation Preview */}
                    {(() => {
                      const curRent = parseFloat(tower.yearly_rent) || 0;
                      const rate = parseFloat(adjustRateForm.escalation_percentage) || 0;
                      const inc = Math.round((curRent * rate) / 100);
                      const proj = Math.round(curRent + inc);
                      return (
                        <div
                          style={{
                            padding: 14,
                            background: "rgba(245, 158, 11, 0.08)",
                            border: "1px solid rgba(245, 158, 11, 0.3)",
                            borderRadius: "var(--radius-md)",
                            marginBottom: 16,
                          }}
                        >
                          <div style={{ fontSize: "0.75rem", color: "#f59e0b", fontWeight: 700, textTransform: "uppercase", marginBottom: 8 }}>
                            Live Escalation Projection
                          </div>
                          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                            <div>
                              <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Increase Amount:</span>
                              <div style={{ fontWeight: 700, color: "#10b981", fontSize: "0.95rem" }}>
                                +₹{inc.toLocaleString("en-IN")}
                              </div>
                            </div>
                            <div>
                              <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>Projected Next Rent:</span>
                              <div style={{ fontWeight: 800, color: "var(--text-primary)", fontSize: "1rem" }}>
                                ₹{proj.toLocaleString("en-IN")}
                              </div>
                            </div>
                          </div>
                          <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", marginTop: 8 }}>
                            Formula: ₹{curRent.toLocaleString("en-IN")} + ({rate}% of ₹{curRent.toLocaleString("en-IN")}) = ₹{proj.toLocaleString("en-IN")}
                          </div>
                        </div>
                      );
                    })()}
                  </>
                )}
              </div>

              <div className="modal-footer" style={{ borderTop: "1px solid var(--border-color)", padding: "12px 20px", display: "flex", justifyContent: "space-between" }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setIsAdjustRateModalOpen(false)}
                  disabled={isSubmittingAdjustRate}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-warning"
                  disabled={isSubmittingAdjustRate}
                  style={{
                    background: "linear-gradient(135deg, #f59e0b, #d97706)",
                    color: "#fff",
                    fontWeight: 700,
                  }}
                >
                  {isSubmittingAdjustRate ? (
                    <>
                      <RefreshCw size={14} className="spin" /> Saving...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 size={16} /> Save Escalation Rate
                    </>
                  )}
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
