import React, { useState, useEffect } from "react";
import { Printer, X, AlertTriangle, Building2, MapPin } from "lucide-react";
import goaEmblem from "../assets/goa-emblem.png";

// All 12 Statutory Talukas of Goa
const ALL_GOA_TALUKAS = [
  "Bardez",
  "Bicholim",
  "Canacona",
  "Dharbandora",
  "Mormugao",
  "Pernem",
  "Ponda",
  "Quepem",
  "Salcete",
  "Sanguem",
  "Sattari",
  "Tiswadi",
];

// District mapping for every Taluka
const TALUKA_DISTRICT_MAP = {
  Bardez: "North Goa",
  Bicholim: "North Goa",
  Pernem: "North Goa",
  Sattari: "North Goa",
  Tiswadi: "North Goa",
  Canacona: "South Goa",
  Dharbandora: "South Goa",
  Mormugao: "South Goa",
  Ponda: "South Goa",
  Quepem: "South Goa",
  Salcete: "South Goa",
  Sanguem: "South Goa",
};

// Comprehensive Area / Panchayat to Taluka Resolution Dictionary
const GOA_LOCATION_TALUKA_MAP = {
  // Ponda
  "ponda": "Ponda",
  "ponda city": "Ponda",
  "curti": "Ponda",
  "shiroda": "Ponda",
  "marcaim": "Ponda",
  "priol": "Ponda",
  "khandepar": "Ponda",
  "bandora": "Ponda",
  "usgao": "Ponda",
  "borim": "Ponda",
  "kundaim": "Ponda",
  "tiwim": "Ponda",
  "bethora": "Ponda",

  // Tiswadi (Panaji)
  "panaji": "Tiswadi",
  "panaji city": "Tiswadi",
  "patto": "Tiswadi",
  "patto plaza": "Tiswadi",
  "miramar": "Tiswadi",
  "caranzalem": "Tiswadi",
  "taleigao": "Tiswadi",
  "santa cruz": "Tiswadi",
  "st cruz": "Tiswadi",
  "bambolim": "Tiswadi",
  "ribandar": "Tiswadi",
  "old goa": "Tiswadi",
  "chimbel": "Tiswadi",
  "corlim": "Tiswadi",
  "merces": "Tiswadi",

  // Bardez (Mapusa)
  "mapusa": "Bardez",
  "mapusa town": "Bardez",
  "calangute": "Bardez",
  "candolim": "Bardez",
  "porvorim": "Bardez",
  "baga": "Bardez",
  "anjuna": "Bardez",
  "vagator": "Bardez",
  "arpora": "Bardez",
  "siolim": "Bardez",
  "saligao": "Bardez",
  "guirim": "Bardez",
  "aldona": "Bardez",
  "socorro": "Bardez",
  "penha de franca": "Bardez",
  "sangolda": "Bardez",
  "nerul": "Bardez",
  "colvale": "Bardez",

  // Salcete (Margao)
  "margao": "Salcete",
  "margao city": "Salcete",
  "madgaon": "Salcete",
  "colva": "Salcete",
  "benaulim": "Salcete",
  "fatorda": "Salcete",
  "navelim": "Salcete",
  "cansaulim": "Salcete",
  "curtorim": "Salcete",
  "nuvem": "Salcete",
  "varca": "Salcete",
  "cavelossim": "Salcete",
  "betalbatim": "Salcete",
  "aquem": "Salcete",
  "chinchinim": "Salcete",
  "raia": "Salcete",

  // Mormugao (Vasco)
  "vasco": "Mormugao",
  "vasco da gama": "Mormugao",
  "chicalim": "Mormugao",
  "dabolim": "Mormugao",
  "sancoale": "Mormugao",
  "cortalim": "Mormugao",
  "bogmalo": "Mormugao",
  "baina": "Mormugao",
  "mormugao": "Mormugao",

  // Pernem
  "pernem": "Pernem",
  "mandrem": "Pernem",
  "morjim": "Pernem",
  "arambol": "Pernem",
  "ashwem": "Pernem",
  "mopa": "Pernem",
  "tuem": "Pernem",
  "dhargal": "Pernem",
  "korgao": "Pernem",

  // Bicholim
  "bicholim": "Bicholim",
  "sanquelim": "Bicholim",
  "mayem": "Bicholim",
  "amona": "Bicholim",
  "karapur": "Bicholim",
  "piligao": "Bicholim",

  // Sattari
  "sattari": "Sattari",
  "valpoi": "Sattari",
  "honda": "Sattari",
  "pissurlem": "Sattari",
  "querim": "Sattari",
  "guleli": "Sattari",

  // Quepem
  "quepem": "Quepem",
  "curchorem": "Quepem",
  "sanvordem": "Quepem",
  "cuncolim": "Quepem",
  "chandor": "Quepem",
  "assolna": "Quepem",

  // Sanguem
  "sanguem": "Sanguem",
  "netravali": "Sanguem",
  "rivona": "Sanguem",
  "curdi": "Sanguem",
  "bhati": "Sanguem",

  // Canacona
  "canacona": "Canacona",
  "palolem": "Canacona",
  "chaudi": "Canacona",
  "agonda": "Canacona",
  "poinguinim": "Canacona",
  "loliem": "Canacona",

  // Dharbandora
  "dharbandora": "Dharbandora",
  "mollem": "Dharbandora",
  "collem": "Dharbandora",
  "kirlapal": "Dharbandora",
  "sacorda": "Dharbandora",
};

// Automatic detection of taluka based on location, area, and address
const autoDetectTaluka = (t) => {
  if (!t) return "Ponda";

  // 1. Direct relationship from API (area -> taluka)
  if (t.area?.taluka?.name) return t.area.taluka.name;
  if (t.taluka?.name) return t.taluka.name;
  if (t.taluka_name) return t.taluka_name;

  // 2. Check area name against known Goa localities
  const areaName = String(t.area?.name || t.area_name || "").toLowerCase().trim();
  if (areaName) {
    if (GOA_LOCATION_TALUKA_MAP[areaName]) {
      return GOA_LOCATION_TALUKA_MAP[areaName];
    }
    for (const [key, taluka] of Object.entries(GOA_LOCATION_TALUKA_MAP)) {
      if (areaName.includes(key)) return taluka;
    }
  }

  // 3. Check tower address
  const address = String(t.address || "").toLowerCase();
  for (const [key, taluka] of Object.entries(GOA_LOCATION_TALUKA_MAP)) {
    if (address.includes(key)) return taluka;
  }

  // 4. Check unique ID string if it contains taluka acronym
  const uid = String(t.tower_unique_id || "").toLowerCase();
  for (const [key, taluka] of Object.entries(GOA_LOCATION_TALUKA_MAP)) {
    if (uid.includes(key)) return taluka;
  }

  return "Ponda";
};

export const RentDemandNoticeModal = ({ tower, onClose }) => {
  if (!tower) return null;

  // Automatically select taluka based on location
  const [selectedTaluka, setSelectedTaluka] = useState(() => autoDetectTaluka(tower));

  useEffect(() => {
    setSelectedTaluka(autoDetectTaluka(tower));
  }, [tower]);

  const selectedDistrict =
    tower.area?.taluka?.constituency?.district?.name ||
    TALUKA_DISTRICT_MAP[selectedTaluka] ||
    "Goa";

  const locationName = tower.area?.name || tower.area_name || "Goa";

  const todayStr = new Date().toLocaleDateString("en-IN", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  const refNumber = `GOA/DOIT/MTMMS/${new Date().getFullYear()}/DN-${String(tower.id || "001").padStart(4, "0")}`;

  const annualRent =
    parseFloat(tower.yearly_rent) ||
    (parseFloat(tower.monthly_rent) || 0) * 12;

  const latePenalty = Math.round(annualRent * 0.05); // 5% statutory penalty
  const totalDue = annualRent + latePenalty;

  const dueDateFormatted = tower.rent_due_date
    ? new Date(tower.rent_due_date).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        year: "numeric",
      })
    : "Immediate";

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="modal-backdrop" onClick={onClose} style={{ zIndex: 100 }}>
      <div
        className="modal-content printable-modal"
        style={{
          maxWidth: 780,
          maxHeight: "92vh",
          display: "flex",
          flexDirection: "column",
          padding: 0,
          overflow: "hidden",
          background: "#ffffff",
          color: "#1e293b",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Toolbar (hidden on print) */}
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
            flexWrap: "wrap",
            gap: 12,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <AlertTriangle size={17} color="#f59e0b" />
            <span style={{ fontWeight: 700, fontSize: "0.92rem", color: "#f8fafc" }}>
              Official Rent Demand Notice Preview
            </span>
          </div>

          {/* Interactive Taluka Selector (Auto-selected based on Location) */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              background: "#1e293b",
              padding: "4px 10px",
              borderRadius: 6,
              border: "1px solid #334155",
            }}
          >
            <label
              style={{
                fontSize: "0.78rem",
                color: "#94a3b8",
                fontWeight: 600,
                display: "flex",
                alignItems: "center",
                gap: 5,
              }}
            >
              <Building2 size={13} style={{ color: "#38bdf8" }} />
              <span>Jurisdiction Taluka:</span>
            </label>
            <select
              value={selectedTaluka}
              onChange={(e) => setSelectedTaluka(e.target.value)}
              style={{
                background: "#0f172a",
                color: "#38bdf8",
                border: "1px solid #475569",
                borderRadius: 4,
                padding: "3px 8px",
                fontSize: "0.8rem",
                fontWeight: 700,
                outline: "none",
                cursor: "pointer",
              }}
              title="Taluka automatically selected based on tower location (can be manually adjusted if required)"
            >
              {ALL_GOA_TALUKAS.map((t) => (
                <option key={t} value={t}>
                  {t} Taluka ({TALUKA_DISTRICT_MAP[t] || "Goa"})
                </option>
              ))}
            </select>
            <span
              style={{
                fontSize: "0.7rem",
                color: "#10b981",
                fontWeight: 600,
                padding: "1px 6px",
                background: "rgba(16, 185, 129, 0.15)",
                borderRadius: 10,
                border: "1px solid rgba(16, 185, 129, 0.3)",
                display: "flex",
                alignItems: "center",
                gap: 3,
              }}
            >
              <MapPin size={10} /> Auto-Selected
            </span>
          </div>

          <div style={{ display: "flex", gap: 10 }}>
            <button
              type="button"
              className="btn btn-primary btn-sm"
              onClick={handlePrint}
              style={{ background: "linear-gradient(135deg, #ff5100 0%, #ff7700 100%)", color: "#ffffff", border: "none", fontWeight: 700 }}
            >
              <Printer size={14} />
              <span>Print / Save as PDF</span>
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-icon btn-sm"
              onClick={onClose}
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
            lineHeight: 1.6,
            color: "#0f172a",
            fontFamily: "'Inter', system-ui, -apple-system, sans-serif",
          }}
        >
          {/* Header */}
          <div
            style={{
              textAlign: "center",
              borderBottom: "2px solid #0f172a",
              paddingBottom: 16,
              marginBottom: 20,
            }}
          >
            <img
              src={goaEmblem}
              alt="Government of Goa"
              style={{ width: 56, height: "auto", marginBottom: 6 }}
            />
            <h2
              style={{
                fontSize: "15px",
                fontWeight: 800,
                letterSpacing: "0.05em",
                margin: 0,
                textTransform: "uppercase",
                color: "#0f172a",
              }}
            >
              Government of Goa
            </h2>
            <h3
              style={{
                fontSize: "13px",
                fontWeight: 700,
                margin: "2px 0",
                color: "#1e293b",
              }}
            >
              Department of Information Technology, Electronics &amp; Communications
            </h3>
            <p style={{ margin: 0, fontSize: "11px", color: "#475569" }}>
              Altinho, Panaji, Goa — 403001 · Phone: +91 832 2411234 · doit.goa.gov.in
            </p>
            <div
              style={{
                marginTop: 8,
                display: "inline-block",
                padding: "3px 14px",
                border: "1px solid #dc2626",
                borderRadius: 4,
                fontWeight: 800,
                fontSize: "12px",
                color: "#dc2626",
                textTransform: "uppercase",
                letterSpacing: "0.06em",
              }}
            >
              Form VII — Statutory Rent Demand Notice
            </div>
          </div>

          {/* Metadata Row */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              marginBottom: 16,
              fontSize: "12px",
            }}
          >
            <div>
              <strong>Ref. No:</strong> {refNumber}
            </div>
            <div>
              <strong>Date of Issue:</strong> {todayStr}
            </div>
          </div>

          {/* Addressee */}
          <div style={{ marginBottom: 16 }}>
            <strong>TO:</strong>
            <div style={{ marginLeft: 16, marginTop: 4 }}>
              <div style={{ fontWeight: 700 }}>
                The Authorized Nodal Telecom Infrastructure Representative / Landlord
              </div>
              <div>
                Premises of Tower ID: <strong>{tower.tower_unique_id || `TWR-${tower.id}`}</strong>
              </div>
              <div>
                Location: <strong>{locationName}</strong> · Taluka: <strong>{selectedTaluka}</strong> ({selectedDistrict})
              </div>
              {tower.address && (
                <div style={{ fontSize: "11.5px", color: "#475569" }}>
                  Address: {tower.address}
                </div>
              )}
              <div>
                Owner / Local Body:{" "}
                <strong>
                  {tower.owner?.name ||
                    (String(tower.land_type || "").toLowerCase() === "government"
                      ? "Govt. of Goa / Local Panchayat"
                      : "Private Landowner")}
                </strong>
              </div>
            </div>
          </div>

          {/* Subject */}
          <div
            style={{
              background: "#f1f5f9",
              padding: "8px 12px",
              borderRadius: 4,
              marginBottom: 16,
              fontWeight: 700,
              fontSize: "12.5px",
              borderLeft: "4px solid #dc2626",
            }}
          >
            SUBJECT: STATUTORY DEMAND FOR IMMEDIATE REMITTANCE OF OUTSTANDING TELECOM TOWER RENT / LICENSING DUES — {selectedTaluka.toUpperCase()} TALUKA JURISDICTION.
          </div>

          {/* Notice Text */}
          <p style={{ marginBottom: 12 }}>
            Whereas, as per the official records maintained under the{" "}
            <strong>Goa Telecom Infrastructure Policy and Mobile Tower Monitoring &amp; Management System (MTMMS)</strong>,
            the mobile communication structure identified below within the jurisdiction of{" "}
            <strong>{selectedTaluka} Taluka ({selectedDistrict})</strong> has accumulated overdue rent / licensing arrears:
          </p>

          {/* Tower & Rent Particulars Table */}
          <table
            style={{
              width: "100%",
              borderCollapse: "collapse",
              marginBottom: 18,
              fontSize: "12px",
            }}
          >
            <thead>
              <tr style={{ background: "#e2e8f0" }}>
                <th style={{ border: "1px solid #cbd5e1", padding: "6px 10px", textAlign: "left" }}>Description</th>
                <th style={{ border: "1px solid #cbd5e1", padding: "6px 10px", textAlign: "left" }}>Details</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Tower Unique ID</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 700, color: "#1e293b" }}>
                  {tower.tower_unique_id || `TWR-${tower.id}`}
                </td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Jurisdiction / Taluka</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>
                  {selectedTaluka} Taluka ({selectedDistrict})
                </td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Location Area / Panchayat</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px" }}>
                  {locationName}
                </td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Classification / Land Type</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", textTransform: "capitalize" }}>
                  {tower.land_type || "Government"} Property
                </td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Original Due Date</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", color: "#dc2626", fontWeight: 700 }}>
                  {dueDateFormatted}
                </td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Principal Rent Overdue</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px" }}>₹{annualRent.toLocaleString()}</td>
              </tr>
              <tr>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px", fontWeight: 600 }}>Late Payment Interest / Surcharge (5%)</td>
                <td style={{ border: "1px solid #cbd5e1", padding: "6px 10px" }}>₹{latePenalty.toLocaleString()}</td>
              </tr>
              <tr style={{ background: "#fef2f2", fontWeight: 800 }}>
                <td style={{ border: "1px solid #f87171", padding: "8px 10px", color: "#991b1b" }}>TOTAL DEMAND PAYABLE</td>
                <td style={{ border: "1px solid #f87171", padding: "8px 10px", color: "#991b1b", fontSize: "14px" }}>
                  ₹{totalDue.toLocaleString()}
                </td>
              </tr>
            </tbody>
          </table>

          {/* Statutory Directives */}
          <div style={{ marginBottom: 20 }}>
            <p style={{ margin: "0 0 8px" }}>
              <strong>TAKE NOTICE:</strong> You are hereby directed to remit the aforesaid sum of{" "}
              <strong>₹{totalDue.toLocaleString()}</strong> within <strong>fifteen (15) calendar days</strong> from the
              receipt of this statutory demand notice.
            </p>
            <p style={{ margin: 0, fontSize: "11.5px", color: "#475569" }}>
              Failure to effect payment within the stipulated period will initiate proceedings under the Goa Land
              Revenue Code / Panchayat Raj Act for recovery as arrears of land revenue, along with disconnection of utility
              power feed and forfeiture of site license.
            </p>
          </div>

          {/* Signatures */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "flex-end",
              marginTop: 36,
              paddingTop: 16,
            }}
          >
            <div style={{ fontSize: "11px", color: "#475569", fontWeight: 500 }}>
              <div>Generated via MTMMS Portal</div>
              <div>Jurisdiction: {selectedTaluka} Taluka, {selectedDistrict}</div>
              <div>Official DoIT Portal Verification: <span style={{ textDecoration: "underline" }}>mtmms.goa.gov.in/verify</span></div>
            </div>

            <div style={{ textAlign: "center", minWidth: 220 }}>
              <div style={{ borderBottom: "1px solid #0f172a", marginBottom: 6, height: 36 }}></div>
              <div style={{ fontWeight: 800, fontSize: "12px", color: "#0a0f1d" }}>Nodal Telecommunications Officer</div>
              <div style={{ fontSize: "11px", color: "#475569", fontWeight: 600 }}>{selectedTaluka} Taluka Jurisdiction</div>
              <div style={{ fontSize: "10.5px", color: "#475569", fontWeight: 600 }}>Dept. of Information Technology, Goa</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RentDemandNoticeModal;
