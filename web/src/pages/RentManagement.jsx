import React, { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  Receipt,
  IndianRupee,
  AlertCircle,
  CheckCircle2,
  Calendar,
  CreditCard,
  Building2,
  Radio,
  RefreshCw,
  Printer,
} from "lucide-react";
import StatCard from "../components/StatCard";
import DataTable from "../components/DataTable";
import RentDemandNoticeModal from "../components/RentDemandNoticeModal";
import towerApi from "../api/towerApi";
import rentApi from "../api/rentApi";

export const RentManagement = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [towers, setTowers] = useState([]);
  const [payments, setPayments] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedNoticeTower, setSelectedNoticeTower] = useState(null);

  const [statusFilter, setStatusFilter] = useState(
    searchParams.get("status") || "all"
  );

  const fetchRentData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [towerList, paymentList] = await Promise.all([
        towerApi.getTowers(),
        rentApi.getPayments().catch(() => []),
      ]);
      setTowers(towerList);
      setPayments(paymentList);
    } catch (e) {
      console.error("Failed to load rent records", e);
      setError(e.response?.data?.message || e.message || "Failed to load rent records.");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchRentData();
  }, []);

  // Compute live aggregates
  const totalAnnualDemand = towers.reduce((sum, t) => {
    const yRent = parseFloat(t.yearly_rent) || (parseFloat(t.monthly_rent) || 0) * 12;
    return sum + yRent;
  }, 0);

  const totalCollected = payments.reduce((sum, p) => {
    return sum + (parseFloat(p.amount) || 0);
  }, 0);

  const towersWithDue = towers.filter((t) => {
    if (!t.rent_due_date) return false;
    const dueDate = new Date(t.rent_due_date);
    return dueDate <= new Date();
  });

  const columns = [
    {
      key: "tower_unique_id",
      title: "Tower ID",
      render: (val, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
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
            }}
          >
            <Radio size={16} />
          </div>
          <div>
            <strong
              style={{ color: "var(--primary-light)", cursor: "pointer" }}
              onClick={() => navigate(`/towers/${row.id}`)}
            >
              {val || `TWR-${row.id}`}
            </strong>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
              {row.area?.name || row.area_name || "Goa"}
            </div>
          </div>
        </div>
      ),
    },
    {
      key: "owner",
      title: "Landowner / Entity",
      render: (val, row) => {
        const isGovt = String(row.land_type).toLowerCase() === "government";
        return (
          <div>
            <div style={{ fontWeight: 600 }}>{val?.name || (isGovt ? "Government of Goa" : "Private Landholder")}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>
              {isGovt ? "Government Property" : "Private Property"}
            </div>
          </div>
        );
      },
    },
    {
      key: "operators",
      title: "Operators Using Tower",
      render: (val, row) => {
        const ops = Array.isArray(row.operators) ? row.operators : [];
        if (ops.length === 0) {
          return <span style={{ color: "var(--text-muted)", fontSize: "0.8rem" }}>Unassigned</span>;
        }
        return (
          <div style={{ display: "flex", gap: 4, flexWrap: "wrap", maxWidth: 160 }}>
            {ops.map((op) => (
              <span
                key={op.id}
                className="badge badge-info"
                style={{ fontSize: "0.7rem", padding: "2px 7px", cursor: "pointer" }}
                onClick={(e) => {
                  e.stopPropagation();
                  navigate(`/towers?search=${encodeURIComponent(op.name)}`);
                }}
                title={`Click to view all towers used by ${op.name}`}
              >
                {op.short_name || op.name}
              </span>
            ))}
          </div>
        );
      },
    },
    {
      key: "yearly_rent",
      title: "Yearly Lease Rent",
      render: (val, row) => {
        const amount = parseFloat(val) || (parseFloat(row.monthly_rent) || 0) * 12;
        return (
          <span style={{ fontWeight: 700, color: "var(--text-primary)" }}>
            ₹{amount.toLocaleString()} / yr
          </span>
        );
      },
    },
    {
      key: "rent_cycle",
      title: "Rent Cycle",
      render: (_, row) => {
        const cycle = parseInt(row.rent_cycle_years) || parseInt(row.rent_cycle) || 5;
        return (
          <span className="badge badge-info" style={{ fontWeight: 700 }}>
            {cycle} Years
          </span>
        );
      },
    },
    {
      key: "total_cycle",
      title: "Total Cycle Amount",
      render: (_, row) => {
        const yRent = parseFloat(row.yearly_rent) || (parseFloat(row.monthly_rent) || 0) * 12;
        const cycle = parseInt(row.rent_cycle_years) || parseInt(row.rent_cycle) || 5;
        const total = yRent * cycle;
        return (
          <span style={{ fontWeight: 800, color: "#34d399" }}>
            ₹{total.toLocaleString()}
          </span>
        );
      },
    },
    {
      key: "rent_due_date",
      title: "Due Date",
      render: (val) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: "0.85rem" }}>
          <Calendar size={13} color="var(--text-muted)" />
          <span>{val ? val.split("T")[0] : "Not set"}</span>
        </div>
      ),
    },
    {
      key: "actions",
      title: "Actions",
      sortable: false,
      render: (_, row) => (
        <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
          <button
            className="btn btn-secondary btn-sm"
            onClick={() => setSelectedNoticeTower(row)}
            title="Generate Official Statutory Demand Notice"
            style={{ color: "#f59e0b" }}
          >
            <Printer size={13} />
            <span>Demand Notice</span>
          </button>
          <button
            className="btn btn-secondary btn-sm"
            onClick={() => navigate(`/payments?action=record&tower_id=${row.id}`)}
            title="Record Payment"
          >
            <CreditCard size={13} />
            <span>Pay</span>
          </button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h1>Rent & Lease Management</h1>
          <p>Live rent schedules and revenue metrics directly from MySQL backend</p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary btn-sm" onClick={fetchRentData}>
            <RefreshCw size={14} />
            <span>Refresh</span>
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

      {/* Live Financial KPIs */}
      <div className="grid-cols-3" style={{ marginBottom: 24 }}>
        <StatCard
          title="Total Annual Lease Demand"
          value={`₹${totalAnnualDemand.toLocaleString()}`}
          icon={IndianRupee}
          color="indigo"
          subtitle={`Across ${towers.length} live towers in database`}
        />
        <StatCard
          title="Total Remittances Cleared"
          value={`₹${totalCollected.toLocaleString()}`}
          icon={CheckCircle2}
          color="emerald"
          subtitle={`Logged in rent_payments table (${payments.length} transactions)`}
        />
        <StatCard
          title="Towers Past Due Date"
          value={`${towersWithDue.length}`}
          icon={AlertCircle}
          color={towersWithDue.length > 0 ? "rose" : "emerald"}
          subtitle="Towers where rent_due_date <= today"
        />
      </div>

      <DataTable
        columns={columns}
        data={towers}
        initialSearch={searchParams.get("search") || searchParams.get("q") || ""}
        searchPlaceholder="Search live towers by ID, Operator, Company, Owner, Area..."
        isLoading={isLoading}
        emptyMessage="No tower lease records found."
        exportFilename="MTMMS_Rent_Management"
      />

      {selectedNoticeTower && (
        <RentDemandNoticeModal
          tower={selectedNoticeTower}
          onClose={() => setSelectedNoticeTower(null)}
        />
      )}
    </div>
  );
};

export default RentManagement;
