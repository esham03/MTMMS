import React, { useState, useEffect } from "react";
import {
  BarChart3,
  Download,
  Printer,
  FileSpreadsheet,
  Building2,
  Radio,
  IndianRupee,
  CheckCircle2,
  TrendingUp,
  MapPin,
  RefreshCw,
  X,
  ShieldCheck,
} from "lucide-react";
import StatCard from "../components/StatCard";
import towerApi from "../api/towerApi";
import rentApi from "../api/rentApi";
import Loading from "../components/Loading";
import goaEmblem from "../assets/goa-emblem.png";

export const Reports = () => {
  const [towers, setTowers] = useState([]);
  const [payments, setPayments] = useState([]);
  const [districts, setDistricts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [exportNotice, setExportNotice] = useState(null);
  const [showPrintModal, setShowPrintModal] = useState(false);

  const handlePrint = () => {
    if (window.electronAPI?.printPage) {
      window.electronAPI.printPage();
    } else {
      window.print();
    }
  };

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [towerList, paymentList, districtList] = await Promise.all([
        towerApi.getTowers(),
        rentApi.getPayments().catch(() => []),
        towerApi.getDistricts().catch(() => []),
      ]);
      setTowers(towerList);
      setPayments(paymentList);
      setDistricts(districtList);
    } catch (e) {
      console.error("Failed to load reports data", e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  if (isLoading) {
    return <Loading message="Generating live audit reports from backend..." />;
  }

  // Aggregate live metrics
  const totalLeaseDemand = towers.reduce((sum, t) => {
    return sum + (parseFloat(t.yearly_rent) || (parseFloat(t.monthly_rent) || 0) * 12);
  }, 0);

  const totalCollected = payments.reduce((sum, p) => {
    return sum + (parseFloat(p.amount) || 0);
  }, 0);

  const govtTowersCount = towers.filter(
    (t) => String(t.land_type).toLowerCase() === "government"
  ).length;

  const pvtTowersCount = towers.length - govtTowersCount;

  // Group by district dynamically
  const districtMap = {};
  towers.forEach((t) => {
    const dName =
      t.area?.taluka?.constituency?.district?.name || t.district || "North Goa";
    if (!districtMap[dName]) {
      districtMap[dName] = {
        district: dName,
        towers: 0,
        govtTowers: 0,
        pvtTowers: 0,
        annualDemand: 0,
        collected: 0,
      };
    }
    districtMap[dName].towers += 1;
    if (String(t.land_type).toLowerCase() === "government") {
      districtMap[dName].govtTowers += 1;
    } else {
      districtMap[dName].pvtTowers += 1;
    }
    districtMap[dName].annualDemand +=
      parseFloat(t.yearly_rent) || (parseFloat(t.monthly_rent) || 0) * 12;
  });

  // Attach payments to districts
  payments.forEach((p) => {
    const dName =
      p.tower?.area?.taluka?.constituency?.district?.name || "North Goa";
    if (districtMap[dName]) {
      districtMap[dName].collected += parseFloat(p.amount) || 0;
    }
  });

  const districtRows = Object.values(districtMap);

  const handleExportCSV = () => {
    const csvContent =
      "data:text/csv;charset=utf-8," +
      "District,Total Towers,Govt Towers,Private Towers,Annual Demand (INR),Collected (INR),Compliance\n" +
      districtRows
        .map((d) => {
          const comp =
            d.annualDemand > 0
              ? `${Math.min(100, Math.round((d.collected / d.annualDemand) * 100))}%`
              : "0%";
          return `${d.district},${d.towers},${d.govtTowers},${d.pvtTowers},${d.annualDemand},${d.collected},${comp}`;
        })
        .join("\n");

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `MTMMS_Live_Report_${new Date().toISOString().split("T")[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setExportNotice("Live data exported successfully as CSV.");
    setTimeout(() => setExportNotice(null), 3500);
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h1>Reports & Revenue Analytics</h1>
          <p>Live infrastructure and revenue audit aggregated directly from MySQL</p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary btn-sm" onClick={fetchData}>
            <RefreshCw size={14} />
            <span>Refresh</span>
          </button>
          <button className="btn btn-secondary btn-sm" onClick={() => setShowPrintModal(true)}>
            <Printer size={14} />
            <span>Print Report</span>
          </button>
          <button className="btn btn-primary btn-sm" onClick={handleExportCSV}>
            <Download size={14} />
            <span>Export Live CSV</span>
          </button>
        </div>
      </div>

      {exportNotice && (
        <div
          style={{
            background: "var(--success-bg)",
            border: "1px solid var(--success-border)",
            color: "#34d399",
            padding: "10px 14px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          <CheckCircle2 size={16} />
          <span>{exportNotice}</span>
        </div>
      )}

      {/* Live Financial KPIs */}
      <div className="grid-cols-4" style={{ marginBottom: 24 }}>
        <StatCard
          title="Total State Lease Demand"
          value={`₹${totalLeaseDemand.toLocaleString()}`}
          icon={IndianRupee}
          color="indigo"
          subtitle={`Annual value across ${towers.length} live towers`}
        />
        <StatCard
          title="Total Collected"
          value={`₹${totalCollected.toLocaleString()}`}
          icon={CheckCircle2}
          color="emerald"
          badgeText={
            totalLeaseDemand > 0
              ? `${Math.round((totalCollected / totalLeaseDemand) * 100)}% Realized`
              : "0%"
          }
          badgeType="positive"
          subtitle="Recorded in rent_payments table"
        />
        <StatCard
          title="Government vs Private"
          value={`${govtTowersCount} Govt / ${pvtTowersCount} Pvt`}
          icon={Building2}
          color="cyan"
          subtitle="Land allocation distribution"
        />
        <StatCard
          title="Registered Towers"
          value={`${towers.length} Sites`}
          icon={Radio}
          color="emerald"
          subtitle="Direct MySQL record count"
        />
      </div>

      {/* District Revenue Breakdown Table */}
      <div className="card" style={{ marginBottom: 24 }}>
        <div className="card-header">
          <div>
            <h3 className="card-title">Live District-wise Infrastructure & Revenue</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
              Direct live roll-up of database records by district
            </p>
          </div>
        </div>

        <div className="data-table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>District</th>
                <th>Total Towers</th>
                <th>Govt / Private</th>
                <th>Annual Lease Demand</th>
                <th>Realized Collection</th>
                <th>Compliance %</th>
              </tr>
            </thead>
            <tbody>
              {districtRows.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", padding: 30, color: "var(--text-muted)" }}>
                    No tower data available in database to generate report.
                  </td>
                </tr>
              ) : (
                districtRows.map((row) => {
                  const compliancePct =
                    row.annualDemand > 0
                      ? `${Math.min(100, Math.round((row.collected / row.annualDemand) * 100))}%`
                      : "0%";
                  return (
                    <tr key={row.district}>
                      <td>
                        <div style={{ display: "flex", alignItems: "center", gap: 8, fontWeight: 700 }}>
                          <MapPin size={14} color="var(--primary-light)" />
                          <span>{row.district}</span>
                        </div>
                      </td>
                      <td>
                        <strong>{row.towers}</strong>
                      </td>
                      <td>
                        <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>
                          {row.govtTowers} Govt / {row.pvtTowers} Pvt
                        </span>
                      </td>
                      <td style={{ fontWeight: 700 }}>
                        ₹{row.annualDemand.toLocaleString()}
                      </td>
                      <td style={{ fontWeight: 700, color: "#34d399" }}>
                        ₹{row.collected.toLocaleString()}
                      </td>
                      <td>
                        <span className="badge badge-success">{compliancePct}</span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Official Printable State Infrastructure & Revenue Audit Report Modal */}
      {showPrintModal && (
        <div className="modal-backdrop" onClick={() => setShowPrintModal(false)} style={{ zIndex: 100 }}>
          <div
            className="modal-content printable-modal"
            style={{
              maxWidth: 820,
              maxHeight: "92vh",
              display: "flex",
              flexDirection: "column",
              padding: 0,
              background: "#ffffff",
              color: "#1e293b",
              border: "1px solid #cbd5e1",
              borderRadius: "var(--radius-lg)",
              overflow: "hidden",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Top Control Bar (Hidden on actual print) */}
            <div
              className="no-print"
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "12px 20px",
                background: "#0f172a",
                color: "#ffffff",
                borderBottom: "1px solid #334155",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <CheckCircle2 size={17} color="#10b981" />
                <span style={{ fontWeight: 700, fontSize: "0.92rem", color: "#f8fafc" }}>
                  State Infrastructure & Revenue Audit Report
                </span>
              </div>

              <div style={{ display: "flex", gap: 10 }}>
                <button
                  type="button"
                  className="btn btn-primary btn-sm"
                  onClick={handlePrint}
                  style={{
                    background: "linear-gradient(135deg, #ff5100 0%, #ff7700 100%)",
                    color: "#ffffff",
                    border: "none",
                    fontWeight: 700,
                  }}
                >
                  <Printer size={14} />
                  <span>Print / Save as PDF</span>
                </button>
                <button
                  type="button"
                  className="btn btn-secondary btn-icon btn-sm"
                  onClick={() => setShowPrintModal(false)}
                  style={{ background: "#334155", color: "#ffffff", border: "1px solid #475569" }}
                >
                  <X size={15} />
                </button>
              </div>
            </div>

            {/* Printable Document Body */}
            <div
              className="printable-document"
              style={{
                padding: "36px 44px",
                overflowY: "auto",
                fontSize: "13px",
                lineHeight: 1.5,
                background: "#ffffff",
                color: "#0f172a",
              }}
            >
              {/* Official Government Header */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  borderBottom: "2.5px solid #0f172a",
                  paddingBottom: 16,
                  marginBottom: 20,
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                  <img
                    src={goaEmblem}
                    alt="Government of Goa Emblem"
                    style={{ width: 62, height: 62, objectFit: "contain" }}
                  />
                  <div>
                    <h2
                      style={{
                        margin: 0,
                        fontSize: "15px",
                        fontWeight: 800,
                        letterSpacing: "0.06em",
                        color: "#0f172a",
                        textTransform: "uppercase",
                      }}
                    >
                      Government of Goa
                    </h2>
                    <h3
                      style={{
                        margin: "2px 0 0",
                        fontSize: "13px",
                        fontWeight: 700,
                        color: "#ff5100",
                      }}
                    >
                      Department of Information Technology, Electronics & Communications
                    </h3>
                    <p style={{ margin: "2px 0 0", fontSize: "11px", color: "#475569" }}>
                      Directorate of Telecommunication Infrastructure & Revenue Monitoring · Panaji, Goa
                    </p>
                  </div>
                </div>

                <div style={{ textAlign: "right", fontSize: "11px", color: "#475569" }}>
                  <div style={{ fontWeight: 800, color: "#0f172a", fontSize: "12px" }}>
                    OFFICIAL STATE AUDIT
                  </div>
                  <div>DoIT-MTMMS/REV/2026</div>
                  <div>Date: {new Date().toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}</div>
                </div>
              </div>

              {/* Report Title */}
              <div style={{ textAlign: "center", marginBottom: 20 }}>
                <h1
                  style={{
                    fontSize: "17px",
                    fontWeight: 800,
                    margin: "0 0 4px",
                    letterSpacing: "0.02em",
                    color: "#0f172a",
                    textTransform: "uppercase",
                  }}
                >
                  Consolidated Telecom Infrastructure & Revenue Audit Report
                </h1>
                <div style={{ fontSize: "11.5px", color: "#475569" }}>
                  Aggregated from Live Goa Telecom Infrastructure Database (MySQL Repository)
                </div>
              </div>

              {/* Key Executive KPIs Summary Box */}
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(4, 1fr)",
                  gap: 12,
                  marginBottom: 24,
                  background: "#f8fafc",
                  border: "1px solid #cbd5e1",
                  borderRadius: 8,
                  padding: "14px 16px",
                }}
              >
                <div>
                  <div style={{ fontSize: "10.5px", color: "#64748b", fontWeight: 700, textTransform: "uppercase" }}>
                    Total Tower Sites
                  </div>
                  <div style={{ fontSize: "16px", fontWeight: 800, color: "#0f172a", marginTop: 2 }}>
                    {towers.length}
                  </div>
                  <div style={{ fontSize: "10px", color: "#475569" }}>
                    {govtTowersCount} Govt / {pvtTowersCount} Pvt
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: "10.5px", color: "#64748b", fontWeight: 700, textTransform: "uppercase" }}>
                    Annual Lease Demand
                  </div>
                  <div style={{ fontSize: "16px", fontWeight: 800, color: "#ff5100", marginTop: 2 }}>
                    ₹{totalLeaseDemand.toLocaleString()}
                  </div>
                  <div style={{ fontSize: "10px", color: "#475569" }}>Current Financial Year</div>
                </div>

                <div>
                  <div style={{ fontSize: "10.5px", color: "#64748b", fontWeight: 700, textTransform: "uppercase" }}>
                    Realized Revenue
                  </div>
                  <div style={{ fontSize: "16px", fontWeight: 800, color: "#059669", marginTop: 2 }}>
                    ₹{totalCollected.toLocaleString()}
                  </div>
                  <div style={{ fontSize: "10px", color: "#475569" }}>Treasury Confirmed</div>
                </div>

                <div>
                  <div style={{ fontSize: "10.5px", color: "#64748b", fontWeight: 700, textTransform: "uppercase" }}>
                    Compliance Rate
                  </div>
                  <div style={{ fontSize: "16px", fontWeight: 800, color: "#2563eb", marginTop: 2 }}>
                    {totalLeaseDemand > 0 ? Math.round((totalCollected / totalLeaseDemand) * 100) : 0}%
                  </div>
                  <div style={{ fontSize: "10px", color: "#475569" }}>Demand-to-Collection</div>
                </div>
              </div>

              {/* District Breakdown Table */}
              <div style={{ marginBottom: 24 }}>
                <h4
                  style={{
                    fontSize: "12px",
                    fontWeight: 700,
                    textTransform: "uppercase",
                    letterSpacing: "0.04em",
                    marginBottom: 8,
                    color: "#0f172a",
                  }}
                >
                  District-wise Infrastructure & Revenue Analysis
                </h4>

                <table
                  style={{
                    width: "100%",
                    borderCollapse: "collapse",
                    fontSize: "11.5px",
                    border: "1px solid #cbd5e1",
                  }}
                >
                  <thead>
                    <tr style={{ background: "#0f172a", color: "#ffffff" }}>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "left" }}>District</th>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "center" }}>Towers</th>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "center" }}>Govt / Pvt Allocation</th>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "right" }}>Annual Demand</th>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "right" }}>Realized Amount</th>
                      <th style={{ border: "1px solid #334155", padding: "8px 10px", textAlign: "center" }}>Compliance</th>
                    </tr>
                  </thead>
                  <tbody>
                    {districtRows.map((row, idx) => {
                      const compliancePct =
                        row.annualDemand > 0
                          ? `${Math.min(100, Math.round((row.collected / row.annualDemand) * 100))}%`
                          : "0%";
                      return (
                        <tr
                          key={row.district}
                          style={{
                            background: idx % 2 === 0 ? "#ffffff" : "#f8fafc",
                            color: "#0f172a",
                          }}
                        >
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", fontWeight: 700 }}>
                            {row.district}
                          </td>
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", textAlign: "center", fontWeight: 700 }}>
                            {row.towers}
                          </td>
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", textAlign: "center", color: "#475569" }}>
                            {row.govtTowers} Govt / {row.pvtTowers} Pvt
                          </td>
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", textAlign: "right", fontWeight: 700 }}>
                            ₹{row.annualDemand.toLocaleString()}
                          </td>
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", textAlign: "right", fontWeight: 700, color: "#059669" }}>
                            ₹{row.collected.toLocaleString()}
                          </td>
                          <td style={{ border: "1px solid #cbd5e1", padding: "7px 10px", textAlign: "center", fontWeight: 700 }}>
                            {compliancePct}
                          </td>
                        </tr>
                      );
                    })}

                    {/* Total Row */}
                    <tr style={{ background: "#e2e8f0", fontWeight: 800, color: "#0f172a" }}>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px" }}>STATE TOTAL</td>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px", textAlign: "center" }}>{towers.length}</td>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px", textAlign: "center" }}>
                        {govtTowersCount} Govt / {pvtTowersCount} Pvt
                      </td>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px", textAlign: "right", color: "#ff5100" }}>
                        ₹{totalLeaseDemand.toLocaleString()}
                      </td>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px", textAlign: "right", color: "#059669" }}>
                        ₹{totalCollected.toLocaleString()}
                      </td>
                      <td style={{ border: "1px solid #94a3b8", padding: "8px 10px", textAlign: "center" }}>
                        {totalLeaseDemand > 0 ? Math.round((totalCollected / totalLeaseDemand) * 100) : 0}%
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              {/* Official Sign-off and Verification Footer */}
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-end",
                  marginTop: 32,
                  paddingTop: 16,
                  borderTop: "1px solid #e2e8f0",
                }}
              >
                <div style={{ fontSize: "11px", color: "#475569" }}>
                  <div>Official System Generated Audit Document</div>
                  <div>Certified under Goa Telecom Infrastructure Policy & IT Rules 2026</div>
                  <div>
                    Verification Portal: <span style={{ textDecoration: "underline", color: "#0f172a" }}>mtmms.goa.gov.in/verify</span>
                  </div>
                </div>

                <div style={{ textAlign: "center", minWidth: 220 }}>
                  <div style={{ borderBottom: "1px solid #0f172a", marginBottom: 6, height: 32 }}></div>
                  <div style={{ fontWeight: 800, fontSize: "12px", color: "#0f172a" }}>
                    Director / Nodal Telecom Officer
                  </div>
                  <div style={{ fontSize: "11px", color: "#475569", fontWeight: 600 }}>
                    Dept. of Information Technology, Goa
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Reports;
