import React, { useState, useEffect, useMemo } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  MapPin,
  Building2,
  Radio,
  Landmark,
  Layers,
  ChevronRight,
  RefreshCw,
  Eye,
  Trash2,
  Search,
  X,
  IndianRupee,
  Activity,
  Filter,
} from "lucide-react";
import Loading from "../components/Loading";
import towerApi from "../api/towerApi";

export const LocationBrowser = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [districts, setDistricts] = useState([]);
  const [areas, setAreas] = useState([]);
  const [towers, setTowers] = useState([]);

  const [selectedDistrictId, setSelectedDistrictId] = useState("all");
  const [selectedAreaId, setSelectedAreaId] = useState("all");
  const [selectedLandType, setSelectedLandType] = useState("all");
  const [selectedStatus, setSelectedStatus] = useState("all");

  const [searchTerm, setSearchTerm] = useState(
    searchParams.get("search") || searchParams.get("q") || ""
  );

  useEffect(() => {
    const q = searchParams.get("search") || searchParams.get("q");
    if (q !== null && q !== undefined) {
      setSearchTerm(q);
    }
  }, [searchParams]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchLocationTowers = async () => {
    setIsRefreshing(true);
    try {
      const [distList, areaList, towerList] = await Promise.all([
        towerApi.getDistricts().catch(() => []),
        towerApi.getAreas().catch(() => []),
        towerApi.getTowers().catch(() => []),
      ]);

      let finalDistList = Array.isArray(distList) && distList.length > 0 ? distList : [];
      if (finalDistList.length === 0) {
        finalDistList = [
          { id: 1, name: "North Goa" },
          { id: 2, name: "South Goa" },
        ];
      }

      setDistricts(finalDistList);
      setAreas(Array.isArray(areaList) ? areaList : []);
      setTowers(Array.isArray(towerList) ? towerList : []);
    } catch (e) {
      console.error("Failed to load location tower data", e);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  const handleDeleteTower = async (towerId, towerUid, e) => {
    if (e) e.stopPropagation();
    if (
      window.confirm(
        `Are you sure you want to delete tower "${towerUid || towerId}"? This action cannot be undone.`
      )
    ) {
      try {
        await towerApi.deleteTower(towerId);
        fetchLocationTowers();
      } catch (err) {
        alert(err.response?.data?.message || "Failed to delete tower.");
      }
    }
  };

  useEffect(() => {
    fetchLocationTowers();
  }, []);

  // Robust district resolver for any tower
  const getTowerDistrict = (tower) => {
    if (!tower) return null;
    const a = tower.area || areas.find((ar) => String(ar.id) === String(tower.area_id));

    // 1. Direct district ID or object on area
    if (a?.district?.id) {
      return { id: String(a.district.id), name: a.district.name || "" };
    }
    if (a?.district_id) {
      const d = districts.find((dist) => String(dist.id) === String(a.district_id));
      if (d) return { id: String(d.id), name: d.name || "" };
    }

    // 2. Taluka -> Constituency -> District hierarchy
    const taluka = a?.taluka || {};
    const constituency = taluka.constituency || {};
    const distFromConst = constituency.district || {};
    if (distFromConst.id) {
      return { id: String(distFromConst.id), name: distFromConst.name || "" };
    }
    if (constituency.district_id) {
      const d = districts.find((dist) => String(dist.id) === String(constituency.district_id));
      if (d) return { id: String(d.id), name: d.name || "" };
    }

    // 3. Taluka -> District direct
    if (taluka.district?.id) {
      return { id: String(taluka.district.id), name: taluka.district.name || "" };
    }
    if (taluka.district_id) {
      const d = districts.find((dist) => String(dist.id) === String(taluka.district_id));
      if (d) return { id: String(d.id), name: d.name || "" };
    }

    // 4. District name matching from candidate strings
    const candidateName = (
      distFromConst.name ||
      taluka.district?.name ||
      a?.district?.name ||
      ""
    ).toLowerCase();
    if (candidateName) {
      const matched = districts.find(
        (d) => d.name.toLowerCase() === candidateName || candidateName.includes(d.name.toLowerCase())
      );
      if (matched) return { id: String(matched.id), name: matched.name };
    }

    // 5. Geographic keyword lookup (Mapusa, Bardez, Panaji, etc. -> North Goa; Margao, Vasco, etc. -> South Goa)
    const northKeywords = [
      "mapusa", "bardez", "panaji", "tiswadi", "pernem", "bicholim",
      "sattari", "porvorim", "calangute", "candolim", "siolim", "aldona",
      "saligao", "valpoi", "sanquelim", "morod", "north"
    ];
    const southKeywords = [
      "margao", "margoa", "salcete", "vasco", "mormugao", "ponda",
      "quepem", "sanguem", "canacona", "dharbandora", "cuncolim",
      "curchorem", "cortalim", "nuvem", "navelim", "south"
    ];

    const searchPool = `${a?.name || ""} ${taluka.name || ""} ${constituency.name || ""} ${tower.address || ""}`.toLowerCase();

    if (northKeywords.some((k) => searchPool.includes(k))) {
      const northDist = districts.find((d) => d.name.toLowerCase().includes("north")) || { id: "1", name: "North Goa" };
      return { id: String(northDist.id), name: northDist.name };
    }

    if (southKeywords.some((k) => searchPool.includes(k))) {
      const southDist = districts.find((d) => d.name.toLowerCase().includes("south")) || { id: "2", name: "South Goa" };
      return { id: String(southDist.id), name: southDist.name };
    }

    return null;
  };

  // Filtered Towers based on location and tower filters
  const filteredTowers = useMemo(() => {
    let result = [...towers];

    // District Filter
    if (selectedDistrictId !== "all") {
      result = result.filter((t) => {
        const dist = getTowerDistrict(t);
        return dist && String(dist.id) === String(selectedDistrictId);
      });
    }

    // Area Filter
    if (selectedAreaId !== "all") {
      result = result.filter((t) => String(t.area_id) === String(selectedAreaId));
    }

    // Land Type Filter
    if (selectedLandType !== "all") {
      result = result.filter((t) => (t.land_type || "").toLowerCase() === selectedLandType.toLowerCase());
    }

    // Status Filter
    if (selectedStatus !== "all") {
      result = result.filter((t) => (t.status || "").toLowerCase() === selectedStatus.toLowerCase());
    }

    // Search Query (Tower ID, Area name, Address, Owner, Operator)
    if (searchTerm.trim()) {
      const q = searchTerm.toLowerCase();
      result = result.filter((t) => {
        const towerId = (t.tower_unique_id || "").toLowerCase();
        const areaName = (t.area?.name || "").toLowerCase();
        const address = (t.address || "").toLowerCase();
        const ownerName = (t.owner?.name || "").toLowerCase();
        const towerType = (t.tower_type || "").toLowerCase();
        const operators = Array.isArray(t.operators)
          ? t.operators.map((op) => (op.name || op.short_name || "").toLowerCase()).join(" ")
          : "";

        return (
          towerId.includes(q) ||
          areaName.includes(q) ||
          address.includes(q) ||
          ownerName.includes(q) ||
          towerType.includes(q) ||
          operators.includes(q)
        );
      });
    }

    return result;
  }, [towers, areas, districts, selectedDistrictId, selectedAreaId, selectedLandType, selectedStatus, searchTerm]);

  // Tower-Centric Metrics for current filter
  const metrics = useMemo(() => {
    const total = filteredTowers.length;
    const govt = filteredTowers.filter((t) => (t.land_type || "").toLowerCase() === "government").length;
    const pvt = filteredTowers.filter((t) => (t.land_type || "").toLowerCase() === "private").length;
    const active = filteredTowers.filter((t) => (t.status || "active").toLowerCase() === "active").length;
    const totalRent = filteredTowers.reduce((acc, t) => acc + Number(t.yearly_rent || 0), 0);
    const totalTenancies = filteredTowers.reduce(
      (acc, t) => acc + (Array.isArray(t.operators) ? t.operators.length : 0),
      0
    );

    return {
      total,
      govt,
      pvt,
      active,
      totalRent,
      totalTenancies,
      govtPct: total > 0 ? Math.round((govt / total) * 100) : 0,
      pvtPct: total > 0 ? Math.round((pvt / total) * 100) : 0,
    };
  }, [filteredTowers]);

  // Area-wise Tower Aggregations (Top areas hosting towers)
  const areaTowerStats = useMemo(() => {
    const map = {};
    filteredTowers.forEach((t) => {
      const areaId = t.area_id || "unknown";
      const areaName = t.area?.name || "Other Area";
      const pincode = t.area?.pincode || "";

      if (!map[areaId]) {
        map[areaId] = {
          id: areaId,
          name: areaName,
          pincode,
          count: 0,
          govtCount: 0,
          pvtCount: 0,
          revenue: 0,
        };
      }
      map[areaId].count += 1;
      if ((t.land_type || "").toLowerCase() === "government") map[areaId].govtCount += 1;
      if ((t.land_type || "").toLowerCase() === "private") map[areaId].pvtCount += 1;
      map[areaId].revenue += Number(t.yearly_rent || 0);
    });

    return Object.values(map).sort((a, b) => b.count - a.count);
  }, [filteredTowers]);

  if (isLoading) {
    return <Loading message="Loading mobile tower location data..." />;
  }

  return (
    <div>
      {/* Official Government Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Location Browser</h1>
          <p>
            Geographical distribution, land classification, and specifications of mobile towers across Goa
          </p>
        </div>

        <div className="page-actions">
          <button
            className="btn btn-secondary btn-sm"
            onClick={fetchLocationTowers}
            disabled={isRefreshing}
            title="Refresh location tower records"
          >
            <RefreshCw size={14} className={isRefreshing ? "animate-spin" : ""} />
            <span>{isRefreshing ? "Refreshing..." : "Refresh Live Data"}</span>
          </button>
        </div>
      </div>

      {/* Tower-Focused Location KPIs */}
      <div className="grid-cols-5" style={{ marginBottom: 24 }}>
        <div className="stat-card" style={{ padding: "18px 20px" }}>
          <div className="stat-card-header">
            <span className="stat-label">Total Towers</span>
            <div
              className="stat-icon-wrapper"
              style={{ background: "rgba(6, 182, 212, 0.15)", color: "var(--accent-cyan)" }}
            >
              <Radio size={20} />
            </div>
          </div>
          <div className="stat-value">{metrics.total.toLocaleString()}</div>
          <span className="stat-subtitle">
            {selectedDistrictId === "all" ? "Statewide registered sites" : "In selected geographical zone"}
          </span>
        </div>

        <div className="stat-card" style={{ padding: "18px 20px" }}>
          <div className="stat-card-header">
            <span className="stat-label">Government Land</span>
            <div
              className="stat-icon-wrapper"
              style={{ background: "rgba(16, 185, 129, 0.15)", color: "#10b981" }}
            >
              <Landmark size={20} />
            </div>
          </div>
          <div className="stat-value">{metrics.govt.toLocaleString()}</div>
          <span className="stat-subtitle" style={{ color: "#34d399", fontWeight: 600 }}>
            {metrics.govtPct}% of regional mobile sites
          </span>
        </div>

        <div className="stat-card" style={{ padding: "18px 20px" }}>
          <div className="stat-card-header">
            <span className="stat-label">Private Land</span>
            <div
              className="stat-icon-wrapper"
              style={{ background: "rgba(99, 102, 241, 0.15)", color: "var(--primary-light)" }}
            >
              <Building2 size={20} />
            </div>
          </div>
          <div className="stat-value">{metrics.pvt.toLocaleString()}</div>
          <span className="stat-subtitle" style={{ color: "var(--accent-cyan)", fontWeight: 600 }}>
            {metrics.pvtPct}% private properties
          </span>
        </div>

        <div className="stat-card" style={{ padding: "18px 20px" }}>
          <div className="stat-card-header">
            <span className="stat-label">Operator Tenancies</span>
            <div
              className="stat-icon-wrapper"
              style={{ background: "rgba(245, 158, 11, 0.15)", color: "#f59e0b" }}
            >
              <Layers size={20} />
            </div>
          </div>
          <div className="stat-value">{metrics.totalTenancies.toLocaleString()}</div>
          <span className="stat-subtitle">Active telecom co-locations</span>
        </div>

        <div className="stat-card" style={{ padding: "18px 20px" }}>
          <div className="stat-card-header">
            <span className="stat-label">Annual Lease Value</span>
            <div
              className="stat-icon-wrapper"
              style={{ background: "rgba(239, 68, 68, 0.15)", color: "#ef4444" }}
            >
              <IndianRupee size={20} />
            </div>
          </div>
          <div className="stat-value" style={{ fontSize: "1.45rem" }}>
            ₹{metrics.totalRent.toLocaleString("en-IN")}
          </div>
          <span className="stat-subtitle">Total annual lease revenue</span>
        </div>
      </div>

      {/* Main Filter & Search Control Panel */}
      <div
        className="card"
        style={{
          padding: "16px 20px",
          marginBottom: 24,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 16 }}>
          {/* Left: District Filter Tabs */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
            <span style={{ fontSize: "0.82rem", fontWeight: 700, color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.04em" }}>
              District:
            </span>
            <button
              type="button"
              className={`btn btn-sm ${selectedDistrictId === "all" ? "btn-primary" : "btn-secondary"}`}
              onClick={() => {
                setSelectedDistrictId("all");
                setSelectedAreaId("all");
              }}
            >
              All Goa ({towers.length})
            </button>
            {districts.map((d) => {
              const dCount = towers.filter((t) => {
                const dist = getTowerDistrict(t);
                return dist && (String(dist.id) === String(d.id) || dist.name.toLowerCase() === d.name.toLowerCase());
              }).length;

              const isSelected = String(selectedDistrictId) === String(d.id);

              return (
                <button
                  key={d.id}
                  type="button"
                  className={`btn btn-sm ${isSelected ? "btn-primary" : "btn-secondary"}`}
                  onClick={() => {
                    setSelectedDistrictId(d.id);
                    setSelectedAreaId("all");
                  }}
                >
                  <MapPin size={13} />
                  <span>{d.name}</span>
                  <span className="badge badge-neutral" style={{ background: "rgba(0,0,0,0.25)", padding: "2px 6px" }}>
                    {dCount}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Right: Land Type & Status Filters */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
            <select
              className="form-select form-select-sm"
              style={{ width: "auto" }}
              value={selectedLandType}
              onChange={(e) => setSelectedLandType(e.target.value)}
            >
              <option value="all">All Land Ownership</option>
              <option value="government">Government Land</option>
              <option value="private">Private Land</option>
            </select>

            <select
              className="form-select form-select-sm"
              style={{ width: "auto" }}
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
            >
              <option value="all">All Tower Status</option>
              <option value="active">Active / Operational</option>
              <option value="maintenance">Under Maintenance</option>
              <option value="inactive">Inactive / Offline</option>
            </select>

            {(selectedDistrictId !== "all" || selectedAreaId !== "all" || selectedLandType !== "all" || selectedStatus !== "all" || searchTerm) && (
              <button
                className="btn btn-secondary btn-sm"
                onClick={() => {
                  setSelectedDistrictId("all");
                  setSelectedAreaId("all");
                  setSelectedLandType("all");
                  setSelectedStatus("all");
                  setSearchTerm("");
                }}
                style={{ color: "var(--accent-cyan)", borderColor: "rgba(6, 182, 212, 0.3)" }}
              >
                Reset Filters
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Top Location Tower Density Cards */}
      {areaTowerStats.length > 0 && selectedAreaId === "all" && (
        <div style={{ marginBottom: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--text-primary)" }}>
              Top Tower Hosting Locations
            </h3>
            <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
              Showing {Math.min(areaTowerStats.length, 6)} major areas
            </span>
          </div>

          <div className="grid-cols-3">
            {areaTowerStats.slice(0, 6).map((item) => (
              <div
                key={item.id}
                onClick={() => setSelectedAreaId(item.id)}
                className="card"
                style={{
                  padding: "16px 18px",
                  cursor: "pointer",
                  border: "1px solid var(--border-color)",
                  transition: "all 0.2s ease",
                }}
                onMouseEnter={(e) => (e.currentTarget.style.borderColor = "var(--accent-cyan)")}
                onMouseLeave={(e) => (e.currentTarget.style.borderColor = "var(--border-color)")}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
                  <div>
                    <h4 style={{ fontSize: "0.98rem", fontWeight: 700, color: "var(--text-primary)" }}>
                      {item.name}
                    </h4>
                    <span style={{ fontSize: "0.74rem", color: "var(--text-muted)" }}>
                      {item.pincode ? `PIN: ${item.pincode}` : "Goa Region"}
                    </span>
                  </div>
                  <span className="badge badge-info" style={{ fontSize: "0.75rem", padding: "4px 8px" }}>
                    <Radio size={12} /> {item.count} Towers
                  </span>
                </div>

                <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.78rem", color: "var(--text-secondary)", marginTop: 10, paddingTop: 10, borderTop: "1px solid var(--border-color)" }}>
                  <span>
                    Govt: <strong>{item.govtCount}</strong> • Pvt: <strong>{item.pvtCount}</strong>
                  </span>
                  <span style={{ color: "var(--accent-cyan)", fontWeight: 600 }}>
                    ₹{item.revenue.toLocaleString("en-IN")}/yr
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Main Table: Tower Details in Location */}
      <div className="card" style={{ padding: 0 }}>
        {/* Table Toolbar with Search Box and Active Filter Tag */}
        <div className="table-toolbar">
          <div className="table-toolbar-left">
            <div className="table-search-wrapper">
              <Search size={15} className="table-search-icon" />
              <input
                type="text"
                className="table-search-input"
                placeholder="Search by Tower ID, area, address, owner..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              {searchTerm && (
                <button
                  type="button"
                  className="table-search-clear-btn"
                  onClick={() => setSearchTerm("")}
                  title="Clear search"
                >
                  <X size={13} />
                </button>
              )}
            </div>

            {selectedAreaId !== "all" && (
              <span
                className="badge badge-info"
                style={{ cursor: "pointer", display: "inline-flex", alignItems: "center", gap: 6 }}
                onClick={() => setSelectedAreaId("all")}
                title="Click to clear area filter"
              >
                <span>Area: {areaTowerStats.find((a) => a.id === selectedAreaId)?.name || selectedAreaId}</span>
                <X size={12} />
              </span>
            )}
          </div>

          <div className="table-toolbar-right">
            <span style={{ fontSize: "0.85rem", color: "var(--text-muted)", fontWeight: 500 }}>
              Showing <strong>{filteredTowers.length}</strong> Tower{filteredTowers.length !== 1 ? "s" : ""}
            </span>
          </div>
        </div>

        {/* Tower Records Table */}
        {filteredTowers.length === 0 ? (
          <div style={{ textAlign: "center", padding: "48px 20px", color: "var(--text-muted)" }}>
            <Radio size={36} style={{ opacity: 0.4, marginBottom: 12 }} />
            <h4 style={{ color: "var(--text-secondary)", marginBottom: 6 }}>No Towers Found</h4>
            <p style={{ fontSize: "0.85rem" }}>
              No mobile towers match the current location and filter criteria.
            </p>
          </div>
        ) : (
          <div className="table-container" style={{ width: "100%", overflowX: "auto", WebkitOverflowScrolling: "touch" }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ whiteSpace: "nowrap", minWidth: 150 }}>Tower ID</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 140 }}>Location / Area</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 130 }}>Land Ownership</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 140 }}>Tower Type / Height</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 140 }}>Infrastructure Owner</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 130 }}>Hosted Operators</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 110 }}>Annual Rent</th>
                  <th style={{ whiteSpace: "nowrap", minWidth: 90 }}>Status</th>
                  <th style={{ textAlign: "right", whiteSpace: "nowrap", minWidth: 90, paddingRight: 16 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredTowers.map((t) => (
                  <tr
                    key={t.id}
                    onClick={() => navigate(`/towers/${t.id || t.tower_unique_id}`)}
                    style={{ cursor: "pointer" }}
                  >
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 140 }}>
                        <div
                          style={{
                            width: 30,
                            height: 30,
                            borderRadius: "var(--radius-sm)",
                            background: "rgba(6, 182, 212, 0.15)",
                            color: "var(--accent-cyan)",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            flexShrink: 0,
                          }}
                        >
                          <Radio size={15} />
                        </div>
                        <div>
                          <div style={{ fontWeight: 700, color: "var(--text-primary)", whiteSpace: "nowrap" }}>
                            {t.tower_unique_id}
                          </div>
                          {t.latitude && t.longitude ? (
                            <div style={{ fontSize: "0.7rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                              {Number(t.latitude).toFixed(3)}° N, {Number(t.longitude).toFixed(3)}° E
                            </div>
                          ) : (
                            <div style={{ fontSize: "0.7rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                              {t.frequency || "4G/5G"}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>

                    <td>
                      <div style={{ minWidth: 130 }}>
                        <div style={{ fontWeight: 600, color: "var(--text-primary)", whiteSpace: "nowrap" }}>
                          {t.area?.name || "Goa Site"}
                        </div>
                        <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                          {t.area?.taluka?.name ? `${t.area.taluka.name}, ` : ""}{t.address || (t.area?.pincode ? `PIN: ${t.area.pincode}` : "Goa")}
                        </div>
                      </div>
                    </td>

                    <td>
                      <span
                        className={`badge ${
                          (t.land_type || "").toLowerCase() === "government"
                            ? "badge-success"
                            : "badge-neutral"
                        }`}
                        style={{ whiteSpace: "nowrap" }}
                      >
                        {(t.land_type || "").toLowerCase() === "government" ? "Government Land" : "Private Land"}
                      </span>
                    </td>

                    <td>
                      <div style={{ minWidth: 130 }}>
                        <div style={{ fontSize: "0.85rem", fontWeight: 500, whiteSpace: "nowrap" }}>
                          {t.tower_type || "Ground Based Tower"}
                        </div>
                        <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                          {(t.height || t.height_meters) ? `${t.height || t.height_meters} Meters` : "Standard Height"}
                        </div>
                      </div>
                    </td>

                    <td>
                      <div style={{ minWidth: 130 }}>
                        <div style={{ fontWeight: 600, fontSize: "0.85rem", whiteSpace: "nowrap" }}>
                          {t.owner?.name || "Telecom Infrastructure"}
                        </div>
                        <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                          {t.owner?.contact_number || t.owner?.phone || t.owner?.contact_no || t.owner?.phone_number || t.owner?.mobile || "Verified"}
                        </div>
                      </div>
                    </td>

                    <td>
                      <div style={{ display: "flex", gap: 4, flexWrap: "wrap", maxWidth: 180 }}>
                        {Array.isArray(t.operators) && t.operators.length > 0 ? (
                          t.operators.map((op) => (
                            <span
                              key={op.id}
                              className="badge badge-info"
                              style={{ fontSize: "0.68rem", padding: "2px 7px", whiteSpace: "nowrap" }}
                            >
                              {op.short_name || op.name}
                            </span>
                          ))
                        ) : (
                          <span style={{ color: "var(--text-muted)", fontSize: "0.75rem", whiteSpace: "nowrap" }}>None Assigned</span>
                        )}
                      </div>
                    </td>

                    <td>
                      <div style={{ minWidth: 100 }}>
                        <div style={{ fontWeight: 700, color: "var(--text-primary)", fontSize: "0.9rem", whiteSpace: "nowrap" }}>
                          ₹{Number(t.yearly_rent || 0).toLocaleString("en-IN")}
                        </div>
                        <div style={{ fontSize: "0.7rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>Per Annum</div>
                      </div>
                    </td>

                    <td>
                      <span
                        className={`badge ${
                          (t.status || "active").toLowerCase() === "active"
                            ? "badge-success"
                            : (t.status || "").toLowerCase() === "maintenance"
                            ? "badge-warning"
                            : "badge-neutral"
                        }`}
                        style={{ whiteSpace: "nowrap" }}
                      >
                        <Activity size={10} style={{ marginRight: 2 }} />
                        {t.status ? t.status.toUpperCase() : "ACTIVE"}
                      </span>
                    </td>

                    <td style={{ textAlign: "right", whiteSpace: "nowrap", paddingRight: 16 }}>
                      <div style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                        <button
                          className="btn btn-secondary btn-icon btn-sm"
                          onClick={(e) => {
                            e.stopPropagation();
                            navigate(`/towers/${t.id || t.tower_unique_id}`);
                          }}
                          title="View Tower Details"
                        >
                          <Eye size={14} />
                        </button>
                        <button
                          className="btn btn-danger btn-icon btn-sm"
                          onClick={(e) => handleDeleteTower(t.id, t.tower_unique_id, e)}
                          title="Delete Tower Record"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default LocationBrowser;
