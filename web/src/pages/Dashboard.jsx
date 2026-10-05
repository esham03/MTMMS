import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  Radio,
  Building2,
  Antenna,
  IndianRupee,
  Plus,
  ArrowRight,
  TrendingUp,
  MapPin,
  RefreshCw,
  AlertCircle,
  Landmark,
  Bell,
  AlertTriangle,
  Clock,
  CheckCircle2,
  CreditCard,
  Printer,
} from "lucide-react";
import StatCard from "../components/StatCard";
import Loading from "../components/Loading";
import RentDemandNoticeModal from "../components/RentDemandNoticeModal";
import dashboardApi from "../api/dashboardApi";
import towerApi from "../api/towerApi";

export const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [towers, setTowers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState(null);
  const [selectedNoticeTower, setSelectedNoticeTower] = useState(null);

  const fetchDashboardData = async () => {
    setIsRefreshing(true);
    setError(null);
    try {
      const [data, towerList] = await Promise.all([
        dashboardApi.getStats(),
        towerApi.getTowers().catch(() => []),
      ]);
      setStats(data);
      setTowers(Array.isArray(towerList) ? towerList : []);
    } catch (e) {
      console.error("Dashboard API load error", e);
      setError(
        e.response?.data?.message ||
          e.message ||
          "Failed to fetch live dashboard stats."
      );
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  if (isLoading) {
    return <Loading message="Fetching live metrics from MTMMS server..." />;
  }

  if (error && !stats) {
    return (
      <div style={{ textAlign: "center", padding: "60px 20px" }}>
        <AlertCircle size={40} color="#ef4444" style={{ marginBottom: 12 }} />
        <h2>Unable to Load Dashboard</h2>
        <p
          style={{
            color: "var(--text-secondary)",
            marginTop: 6,
            marginBottom: 20,
          }}
        >
          {error}
        </p>
        <button className="btn btn-primary btn-sm" onClick={fetchDashboardData}>
          <RefreshCw size={14} /> Retry Connection
        </button>
      </div>
    );
  }

  const totalTowers = stats?.total_towers || 0;
  const govtTowers = stats?.government_towers || 0;
  const pvtTowers =
    stats?.private_towers ?? Math.max(0, totalTowers - govtTowers);
  const totalOperators = stats?.total_operators || 0;
  const rentDue = stats?.rent_due || 0;

  const districtWise = stats?.district_wise || [];
  const operatorWise = stats?.operator_wise || [];
  const talukaWise = stats?.taluka_wise || [];

  // Rent notification classification
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const in30 = new Date(today);
  in30.setDate(in30.getDate() + 30);
  const in7 = new Date(today);
  in7.setDate(in7.getDate() + 7);

  const rentNotifications = (Array.isArray(towers) ? towers : [])
    .filter((t) => t && t.rent_due_date)
    .map((t) => {
      const due = new Date(t.rent_due_date);
      if (isNaN(due.getTime())) return null;
      due.setHours(0, 0, 0, 0);
      let status = null;
      if (due < today) status = "overdue";
      else if (due <= in7) status = "critical";
      else if (due <= in30) status = "upcoming";
      return { ...t, _dueDate: due, _status: status };
    })
    .filter((t) => t && t._status !== null)
    .sort((a, b) => a._dueDate - b._dueDate)
    .slice(0, 10);

  return (
    <div>
      {/* Official Government Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Dashboard</h1>
        </div>

        <div className="page-actions">
          <button
            className="btn btn-secondary btn-sm"
            onClick={fetchDashboardData}
            disabled={isRefreshing}
          >
            <RefreshCw
              size={14}
              className={isRefreshing ? "animate-spin" : ""}
            />
            <span>{isRefreshing ? "Refreshing..." : "Refresh Live Data"}</span>
          </button>

          <button
            className="btn btn-primary btn-sm"
            onClick={() => navigate("/towers?action=create")}
          >
            <Plus size={15} />
            <span>Register New Tower</span>
          </button>
        </div>
      </div>

      {/* 5 Main Statistics KPI Grid */}
      <div className="grid-cols-5" style={{ marginBottom: 24 }}>
        <StatCard
          title="Total Towers"
          value={totalTowers.toLocaleString()}
          icon={Radio}
          color="indigo"
          subtitle="Registered mobile towers"
          onClick={() => navigate("/towers")}
        />

        <StatCard
          title="Government Land"
          value={govtTowers.toLocaleString()}
          icon={Landmark}
          color="emerald"
          subtitle="Municipal & panchayat plots"
          onClick={() => navigate("/towers?land_type=government")}
        />

        <StatCard
          title="Private Land"
          value={pvtTowers.toLocaleString()}
          icon={Building2}
          color="cyan"
          subtitle="Private properties"
          onClick={() => navigate("/towers?land_type=private")}
        />

        <StatCard
          title="Total Operators"
          value={totalOperators.toLocaleString()}
          icon={Antenna}
          color="amber"
          subtitle="Licensed telecom operators"
          onClick={() => navigate("/operators")}
        />

        <StatCard
          title="Towers with Rent Due"
          value={rentDue.toLocaleString()}
          icon={IndianRupee}
          color="rose"
          subtitle="Pending rent cycle payments"
          onClick={() => navigate("/rent")}
        />
      </div>

      {/* Regional & Operator Breakdown Section */}
      <div className="grid-cols-2" style={{ marginBottom: 24 }}>
        {/* District-Wise Infrastructure Overview */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">District Distribution</h3>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Geographical distribution across Goa
              </p>
            </div>
            <button
              className="btn btn-outline btn-sm"
              onClick={() => navigate("/locations")}
            >
              <span>Location Browser</span>
              <ArrowRight size={13} />
            </button>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            {districtWise.length === 0 ? (
              <div style={{ padding: "20px 0", textAlign: "center", color: "var(--text-muted)", fontSize: "0.85rem" }}>
                <MapPin size={28} style={{ opacity: 0.5, marginBottom: 6 }} />
                <p>No district tower data recorded in the system yet.</p>
              </div>
            ) : (
              districtWise.map((d, idx) => {
                const percentage =
                  totalTowers > 0
                    ? Math.round(((d.tower_count || 0) / totalTowers) * 100)
                    : 0;

                return (
                  <div
                    key={d.district_id || idx}
                    style={{
                      padding: "12px 16px",
                      background: "var(--bg-surface-elevated)",
                      borderRadius: "var(--radius-md)",
                      border: "1px solid var(--border-color)",
                    }}
                  >
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        marginBottom: 6,
                      }}
                    >
                      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                        <MapPin size={16} color="var(--accent-cyan)" />
                        <span style={{ fontWeight: 600, fontSize: "0.9rem" }}>
                          {d.district}
                        </span>
                      </div>
                      <span className="badge badge-info">
                        {d.tower_count || 0} Towers ({percentage}%)
                      </span>
                    </div>

                    <div
                      style={{
                        width: "100%",
                        height: 6,
                        background: "rgba(255, 255, 255, 0.08)",
                        borderRadius: 3,
                        overflow: "hidden",
                      }}
                    >
                      <div
                        style={{
                          width: `${percentage}%`,
                          height: "100%",
                          background: "var(--primary-gradient)",
                          borderRadius: 3,
                        }}
                      />
                    </div>
                  </div>
                );
              })
            )}

            {talukaWise.length > 0 && (
              <div
                style={{
                  marginTop: 8,
                  paddingTop: 14,
                  borderTop: "1px solid var(--border-color)",
                }}
              >
                <div
                  style={{
                    fontSize: "0.75rem",
                    color: "var(--text-muted)",
                    marginBottom: 8,
                    fontWeight: 600,
                    textTransform: "uppercase",
                  }}
                >
                  Top Talukas by Tower Count
                </div>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  {talukaWise.slice(0, 5).map((t, idx) => (
                    <span
                      key={idx}
                      className="badge badge-neutral"
                      style={{ padding: "5px 10px" }}
                    >
                      {t.taluka}: <strong>{t.tower_count}</strong>
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Licensed Telecom Operators Tenancy */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Licensed Telecom Operators</h3>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Active infrastructure tenancies
              </p>
            </div>
            <button
              className="btn btn-outline btn-sm"
              onClick={() => navigate("/operators")}
            >
              <span>Manage Operators</span>
              <ArrowRight size={13} />
            </button>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {operatorWise.length === 0 ? (
              <div style={{ padding: "20px 0", textAlign: "center", color: "var(--text-muted)", fontSize: "0.85rem" }}>
                <Antenna size={28} style={{ opacity: 0.5, marginBottom: 6 }} />
                <p>No telecom operators registered yet.</p>
              </div>
            ) : (
              operatorWise.map((op, idx) => (
                <div
                  key={op.operator_id || idx}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "10px 14px",
                    background: "var(--bg-surface-elevated)",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div
                      style={{
                        width: 34,
                        height: 34,
                        borderRadius: "var(--radius-sm)",
                        background: "rgba(99, 102, 241, 0.15)",
                        color: "var(--primary-light)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontWeight: 700,
                        fontSize: "0.75rem",
                      }}
                    >
                      {op.short_name || op.operator?.slice(0, 3).toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: "0.9rem" }}>
                        {op.operator}
                      </div>
                      <div
                        style={{
                          fontSize: "0.75rem",
                          color: "var(--text-muted)",
                        }}
                      >
                        {op.tower_count || 0} Connected Towers
                      </div>
                    </div>
                  </div>

                  <span className="badge badge-info">{op.tower_count || 0} Sites</span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Rent Notifications Panel */}
      <div className="card" style={{ marginBottom: 24 }}>
        <div className="card-header">
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: "var(--radius-sm)",
                background: rentNotifications.some((n) => n._status === "overdue")
                  ? "rgba(239,68,68,0.15)"
                  : "rgba(251,191,36,0.12)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Bell
                size={18}
                color={
                  rentNotifications.some((n) => n._status === "overdue")
                    ? "#ef4444"
                    : "#f59e0b"
                }
              />
            </div>
            <div>
              <h3 className="card-title">Rent Notifications</h3>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Overdue &amp; upcoming rent due dates across all towers
              </p>
            </div>
          </div>
          <button
            className="btn btn-outline btn-sm"
            onClick={() => navigate("/rent")}
          >
            <span>View All</span>
            <ArrowRight size={13} />
          </button>
        </div>

        {rentNotifications.length === 0 ? (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              padding: "28px 0",
              gap: 8,
              color: "var(--text-muted)",
            }}
          >
            <CheckCircle2 size={32} color="#34d399" style={{ opacity: 0.7 }} />
            <p style={{ fontSize: "0.875rem" }}>
              All rents are up to date — no dues in the next 30 days.
            </p>
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {/* Legend */}
            <div
              style={{
                display: "flex",
                gap: 16,
                marginBottom: 4,
                flexWrap: "wrap",
              }}
            >
              {["overdue", "critical", "upcoming"].map((s) => {
                const count = rentNotifications.filter(
                  (n) => n._status === s
                ).length;
                if (!count) return null;
                const cfg = {
                  overdue: { label: "Overdue", color: "#ef4444", bg: "rgba(239,68,68,0.1)" },
                  critical: { label: "Due ≤ 7 Days", color: "#f59e0b", bg: "rgba(245,158,11,0.1)" },
                  upcoming: { label: "Due ≤ 30 Days", color: "var(--accent-cyan)", bg: "rgba(6,182,212,0.08)" },
                }[s];
                return (
                  <span
                    key={s}
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: 5,
                      fontSize: "0.72rem",
                      fontWeight: 700,
                      color: cfg.color,
                      background: cfg.bg,
                      border: `1px solid ${cfg.color}30`,
                      borderRadius: 20,
                      padding: "2px 10px",
                    }}
                  >
                    {count} {cfg.label}
                  </span>
                );
              })}
            </div>

            {rentNotifications.map((t, idx) => {
              const cfg = {
                overdue: {
                  icon: <AlertCircle size={15} color="#ef4444" />,
                  borderColor: "#ef444430",
                  bg: "rgba(239,68,68,0.05)",
                  tagColor: "#ef4444",
                  tagBg: "rgba(239,68,68,0.12)",
                  tagLabel: "OVERDUE",
                },
                critical: {
                  icon: <AlertTriangle size={15} color="#f59e0b" />,
                  borderColor: "#f59e0b30",
                  bg: "rgba(245,158,11,0.05)",
                  tagColor: "#f59e0b",
                  tagBg: "rgba(245,158,11,0.12)",
                  tagLabel: "DUE SOON",
                },
                upcoming: {
                  icon: <Clock size={15} color="var(--accent-cyan)" />,
                  borderColor: "var(--border-color)",
                  bg: "var(--bg-surface-elevated)",
                  tagColor: "var(--accent-cyan)",
                  tagBg: "rgba(6,182,212,0.08)",
                  tagLabel: "UPCOMING",
                },
              }[t._status];

              const daysLeft = Math.ceil(
                (t._dueDate - today) / (1000 * 60 * 60 * 24)
              );
              const dueLabel =
                t._status === "overdue"
                  ? `${Math.abs(daysLeft)} day${Math.abs(daysLeft) !== 1 ? "s" : ""} ago`
                  : daysLeft === 0
                  ? "Today"
                  : `In ${daysLeft} day${daysLeft !== 1 ? "s" : ""}`;

              const yearlyRent =
                parseFloat(t.yearly_rent) ||
                (parseFloat(t.monthly_rent) || 0) * 12;

              return (
                <div
                  key={t.id || idx}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "10px 14px",
                    background: cfg.bg,
                    border: `1px solid ${cfg.borderColor}`,
                    borderRadius: "var(--radius-md)",
                    gap: 12,
                    flexWrap: "wrap",
                  }}
                >
                  {/* Left: icon + tower info */}
                  <div
                    style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}
                  >
                    {cfg.icon}
                    <div style={{ minWidth: 0 }}>
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: 8,
                          flexWrap: "wrap",
                        }}
                      >
                        <span
                          style={{
                            fontWeight: 700,
                            fontSize: "0.9rem",
                            color: "var(--text-primary)",
                            cursor: "pointer",
                          }}
                          onClick={() => navigate(`/towers/${t.id}`)}
                        >
                          {t.tower_unique_id || `TWR-${t.id}`}
                        </span>
                        <span
                          style={{
                            fontSize: "0.65rem",
                            fontWeight: 800,
                            color: cfg.tagColor,
                            background: cfg.tagBg,
                            padding: "1px 7px",
                            borderRadius: 20,
                            letterSpacing: "0.04em",
                          }}
                        >
                          {cfg.tagLabel}
                        </span>
                      </div>
                      <div
                        style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}
                      >
                        {t.area?.name || t.area_name || "—"} &nbsp;·&nbsp;{" "}
                        {t.owner?.name ||
                          (String(t.land_type || "").toLowerCase() ===
                          "government"
                            ? "Govt. of Goa"
                            : "Private")}
                      </div>
                    </div>
                  </div>

                  {/* Middle: rent amount */}
                  <div style={{ textAlign: "center" }}>
                    <div
                      style={{
                        fontWeight: 800,
                        fontSize: "0.95rem",
                        color: "var(--text-primary)",
                      }}
                    >
                      ₹{yearlyRent.toLocaleString()}
                    </div>
                    <div
                      style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}
                    >
                      / yr
                    </div>
                  </div>

                  {/* Right: due date + action */}
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 10,
                      flexShrink: 0,
                    }}
                  >
                    <div style={{ textAlign: "right" }}>
                      <div
                        style={{
                          fontSize: "0.8rem",
                          fontWeight: 700,
                          color: cfg.tagColor,
                        }}
                      >
                        {dueLabel}
                      </div>
                      <div
                        style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}
                      >
                        {typeof t.rent_due_date === "string"
                          ? t.rent_due_date.split("T")[0]
                          : String(t.rent_due_date || "—")}
                      </div>
                    </div>
                    {t._status === "overdue" && (
                      <button
                        className="btn btn-secondary btn-sm"
                        style={{ flexShrink: 0, color: "#f59e0b" }}
                        onClick={() => setSelectedNoticeTower(t)}
                        title="Generate Statutory Demand Notice"
                      >
                        <Printer size={13} />
                        <span>Notice</span>
                      </button>
                    )}
                    <button
                      className="btn btn-secondary btn-sm"
                      style={{ flexShrink: 0 }}
                      onClick={() =>
                        navigate(`/payments?action=record&tower_id=${t.id}`)
                      }
                    >
                      <CreditCard size={13} />
                      <span>Pay</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Quick Operational Action Bar */}
      <div className="card quick-actions-card">
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: 16,
          }}
        >
          <div>
            <h4 style={{ fontSize: "1.05rem", marginBottom: 3, fontWeight: 700 }}>
              Quick Operational Actions
            </h4>
            <p style={{ fontSize: "0.82rem", color: "var(--text-secondary)" }}>
              Streamlined workflows for tower administration, rent verification, and audit reports
            </p>
          </div>

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button
              className="btn btn-secondary btn-sm"
              onClick={() => navigate("/locations")}
            >
              <MapPin size={14} />
              <span>Location Browser</span>
            </button>

            <button
              className="btn btn-secondary btn-sm"
              onClick={() => navigate("/rent")}
            >
              <IndianRupee size={14} />
              <span>Inspect Rent Dues</span>
            </button>

            <button
              className="btn btn-secondary btn-sm"
              onClick={() => navigate("/payments?action=record")}
            >
              <Plus size={14} />
              <span>Record Payment</span>
            </button>

            <button
              className="btn btn-primary btn-sm"
              onClick={() => navigate("/reports")}
            >
              <TrendingUp size={14} />
              <span>Audit Report</span>
            </button>
          </div>
        </div>
      </div>

      {selectedNoticeTower && (
        <RentDemandNoticeModal
          tower={selectedNoticeTower}
          onClose={() => setSelectedNoticeTower(null)}
        />
      )}
    </div>
  );
};

export default Dashboard;
