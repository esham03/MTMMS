import React, { useState, useEffect, useRef, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  Search,
  Radio,
  Building2,
  MapPin,
  CreditCard,
  FileText,
  Plus,
  Moon,
  Sun,
  X,
  ArrowRight,
  TrendingUp,
  Map,
  Users,
  Compass,
} from "lucide-react";
import towerApi from "../api/towerApi";
import { useAuth } from "../context/AuthContext";

export const CommandPalette = ({ isOpen, onClose }) => {
  const navigate = useNavigate();
  const { theme, toggleTheme } = useAuth();
  const [query, setQuery] = useState("");
  const [towers, setTowers] = useState([]);
  const [operators, setOperators] = useState([]);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef(null);
  const listRef = useRef(null);

  // Load searchable data on mount or open
  useEffect(() => {
    if (!isOpen) return;
    setQuery("");
    setSelectedIndex(0);

    const loadData = async () => {
      try {
        const [towerData, opData] = await Promise.all([
          towerApi.getTowers().catch(() => []),
          towerApi.getOperators().catch(() => []),
        ]);
        setTowers(Array.isArray(towerData) ? towerData : []);
        setOperators(Array.isArray(opData) ? opData : []);
      } catch (_) {}
    };

    loadData();
    setTimeout(() => {
      inputRef.current?.focus();
    }, 50);
  }, [isOpen]);

  // Static Quick Actions
  const staticActions = useMemo(
    () => [
      {
        id: "act-register",
        title: "Register New Tower",
        category: "Actions",
        icon: <Plus size={16} color="var(--accent-cyan, #06b6d4)" />,
        action: () => navigate("/towers?action=create"),
      },
      {
        id: "act-map",
        title: "Go to GIS Map View",
        category: "Navigation",
        icon: <Map size={16} color="var(--accent-indigo, #818cf8)" />,
        action: () => navigate("/map"),
      },
      {
        id: "act-record-pay",
        title: "Record Lease Payment",
        category: "Actions",
        icon: <CreditCard size={16} color="#34d399" />,
        action: () => navigate("/payments?action=record"),
      },
      {
        id: "act-rent",
        title: "Inspect Rent Dues & Demand Notices",
        category: "Navigation",
        icon: <FileText size={16} color="#f59e0b" />,
        action: () => navigate("/rent"),
      },
      {
        id: "act-towers",
        title: "Browse All Registered Towers",
        category: "Navigation",
        icon: <Radio size={16} color="var(--primary-light, #6366f1)" />,
        action: () => navigate("/towers"),
      },
      {
        id: "act-locations",
        title: "Goa Geographical Location Browser",
        category: "Navigation",
        icon: <Compass size={16} color="var(--accent-cyan, #06b6d4)" />,
        action: () => navigate("/locations"),
      },
      {
        id: "act-owners",
        title: "Panchayats, Municipalities & Landlords",
        category: "Navigation",
        icon: <Users size={16} color="var(--accent-emerald, #10b981)" />,
        action: () => navigate("/owners"),
      },
      {
        id: "act-reports",
        title: "View Government Audit & Revenue Reports",
        category: "Navigation",
        icon: <TrendingUp size={16} color="var(--accent-indigo, #818cf8)" />,
        action: () => navigate("/reports"),
      },
      {
        id: "act-theme",
        title: `Switch Theme to ${theme === "dark" ? "Light" : "Dark"} Mode`,
        category: "Settings",
        icon: theme === "dark" ? <Sun size={16} color="#f59e0b" /> : <Moon size={16} color="var(--accent-indigo, #818cf8)" />,
        action: () => toggleTheme(),
      },
    ],
    [navigate, theme, toggleTheme]
  );

  // Filtered Results
  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) {
      return staticActions.slice(0, 7);
    }

    const matchedActions = staticActions.filter((a) =>
      a.title.toLowerCase().includes(q)
    );

    // Dynamic search actions for the specific query
    const dynamicActions = [
      {
        id: `act-search-towers-${q}`,
        title: `Search all towers used by "${query}"`,
        subtitle: `Open complete Towers registry filtered by "${query}"`,
        category: "Quick Search",
        icon: <Radio size={16} color="var(--primary-light, #6366f1)" />,
        action: () => navigate(`/towers?search=${encodeURIComponent(query)}`),
      },
      {
        id: `act-map-${q}`,
        title: `Locate "${query}" towers on GIS Map`,
        subtitle: `Highlight and zoom to towers used by "${query}"`,
        category: "Quick Search",
        icon: <Map size={16} color="var(--accent-indigo, #818cf8)" />,
        action: () => navigate(`/map?search=${encodeURIComponent(query)}`),
      },
    ];

    const matchedOperators = operators
      .filter((op) =>
        (op.name || "").toLowerCase().includes(q) ||
        (op.short_name || "").toLowerCase().includes(q)
      )
      .slice(0, 3)
      .map((op) => ({
        id: `op-${op.id}`,
        title: `Telecom Operator: ${op.name} (${op.short_name || "OP"})`,
        subtitle: `View all towers used by ${op.name}`,
        category: "Operators Directory",
        icon: <Users size={16} color="var(--accent-cyan, #06b6d4)" />,
        action: () => navigate(`/towers?search=${encodeURIComponent(op.name)}`),
      }));

    const matchedTowers = towers
      .filter((t) => {
        const idMatch = String(t.tower_unique_id || t.id).toLowerCase().includes(q);
        const areaMatch = String(t.area?.name || t.area_name || "").toLowerCase().includes(q);
        const ownerMatch = String(t.owner?.name || "").toLowerCase().includes(q);
        const landMatch = String(t.land_type || "").toLowerCase().includes(q);
        const opMatch = Array.isArray(t.operators) && t.operators.some((op) =>
          String(op.name || "").toLowerCase().includes(q) ||
          String(op.short_name || "").toLowerCase().includes(q)
        );
        return idMatch || areaMatch || ownerMatch || landMatch || opMatch;
      })
      .slice(0, 6)
      .map((t) => {
        const ops = Array.isArray(t.operators)
          ? t.operators.map((o) => o.short_name || o.name).join(", ")
          : "";
        return {
          id: `twr-${t.id}`,
          title: `${t.tower_unique_id || `TWR-${t.id}`} — ${t.area?.name || t.area_name || "Goa"}`,
          subtitle: `${ops ? `Operators: ${ops} · ` : ""}${t.owner?.name || t.land_type || "Government"}`,
          category: "Towers Used",
          icon: <Radio size={16} color="var(--accent-cyan, #06b6d4)" />,
          action: () => navigate(`/towers/${t.id}`),
        };
      });

    const matchedLocations = [
      { name: "North Goa District", path: "/locations?district=north" },
      { name: "South Goa District", path: "/locations?district=south" },
      { name: "Tiswadi Taluka (Panaji)", path: "/locations" },
      { name: "Bardez Taluka (Mapusa / Calangute)", path: "/locations" },
      { name: "Salcete Taluka (Margao)", path: "/locations" },
      { name: "Mormugao Taluka (Vasco)", path: "/locations" },
    ]
      .filter((loc) => loc.name.toLowerCase().includes(q))
      .map((loc, idx) => ({
        id: `loc-${idx}`,
        title: loc.name,
        category: "Geographical Areas",
        icon: <MapPin size={16} color="var(--accent-emerald, #10b981)" />,
        action: () => navigate(loc.path),
      }));

    return [
      ...dynamicActions,
      ...matchedOperators,
      ...matchedTowers,
      ...matchedActions,
      ...matchedLocations,
    ];
  }, [query, staticActions, towers, operators, navigate]);

  // Keyboard navigation
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e) => {
      if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedIndex((prev) => (prev + 1) % (results.length || 1));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedIndex((prev) =>
          prev <= 0 ? results.length - 1 : prev - 1
        );
      } else if (e.key === "Enter") {
        e.preventDefault();
        if (results[selectedIndex]) {
          results[selectedIndex].action();
          onClose();
        }
      } else if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, results, selectedIndex, onClose]);

  // Auto scroll active item into view
  useEffect(() => {
    const listEl = listRef.current;
    if (!listEl) return;
    const activeEl = listEl.children[selectedIndex];
    if (activeEl) {
      activeEl.scrollIntoView({ block: "nearest" });
    }
  }, [selectedIndex]);

  if (!isOpen) return null;

  return (
    <div
      className="modal-backdrop"
      onClick={onClose}
      style={{
        zIndex: 9999,
        background: "rgba(0, 0, 0, 0.72)",
        backdropFilter: "blur(6px)",
        alignItems: "flex-start",
        paddingTop: "12vh",
      }}
    >
      <div
        className="modal-content"
        style={{
          maxWidth: 620,
          width: "100%",
          padding: 0,
          overflow: "hidden",
          background: "var(--bg-surface)",
          border: "1.5px solid var(--border-color)",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.45), 0 0 25px rgba(255, 81, 0, 0.25)",
          borderRadius: "var(--radius-lg)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Bar Input */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            padding: "14px 18px",
            gap: 12,
            borderBottom: "1px solid var(--border-color)",
            background: "var(--bg-surface-elevated)",
          }}
        >
          <Search size={18} color="var(--primary)" style={{ flexShrink: 0 }} />
          <input
            ref={inputRef}
            type="text"
            placeholder="Search towers, locations, landlords, or actions..."
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setSelectedIndex(0);
            }}
            style={{
              flex: 1,
              background: "transparent",
              border: "none",
              outline: "none",
              color: "var(--text-primary)",
              fontSize: "1rem",
              fontWeight: 600,
            }}
          />
          {query ? (
            <button
              type="button"
              onClick={() => setQuery("")}
              style={{
                background: "transparent",
                border: "none",
                color: "var(--text-muted)",
                cursor: "pointer",
                display: "flex",
              }}
            >
              <X size={15} />
            </button>
          ) : (
            <span
              style={{
                fontSize: "0.72rem",
                padding: "2px 7px",
                borderRadius: 4,
                background: "var(--bg-surface-hover)",
                color: "var(--text-secondary)",
                border: "1px solid var(--border-color)",
                fontWeight: 700,
              }}
            >
              ESC
            </span>
          )}
        </div>

        {/* Results List */}
        <div
          ref={listRef}
          style={{
            maxHeight: 380,
            overflowY: "auto",
            padding: "8px 10px",
            display: "flex",
            flexDirection: "column",
            gap: 4,
          }}
        >
          {results.length === 0 ? (
            <div
              style={{
                padding: "36px 20px",
                textAlign: "center",
                color: "var(--text-muted)",
                fontSize: "0.88rem",
              }}
            >
              No matching towers, locations, or commands found for "{query}".
            </div>
          ) : (
            results.map((item, idx) => {
              const isSelected = idx === selectedIndex;
              return (
                <div
                  key={item.id}
                  onClick={() => {
                    item.action();
                    onClose();
                  }}
                  onMouseEnter={() => setSelectedIndex(idx)}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "10px 14px",
                    borderRadius: "var(--radius-md)",
                    cursor: "pointer",
                    background: isSelected
                      ? "rgba(255, 81, 0, 0.12)"
                      : "transparent",
                    border: isSelected
                      ? "1px solid rgba(255, 81, 0, 0.45)"
                      : "1px solid transparent",
                    transition: "all 0.15s ease",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 12, minWidth: 0 }}>
                    <div
                      style={{
                        width: 32,
                        height: 32,
                        borderRadius: "var(--radius-sm)",
                        background: "var(--bg-surface-elevated)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        flexShrink: 0,
                      }}
                    >
                      {item.icon}
                    </div>
                    <div style={{ minWidth: 0 }}>
                      <div
                        style={{
                          fontWeight: 700,
                          fontSize: "0.88rem",
                          color: "var(--text-primary)",
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {item.title}
                      </div>
                      {item.subtitle && (
                        <div
                          style={{
                            fontSize: "0.74rem",
                            color: "var(--text-secondary)",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                            fontWeight: 500,
                          }}
                        >
                          {item.subtitle}
                        </div>
                      )}
                    </div>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
                    <span
                      style={{
                        fontSize: "0.68rem",
                        fontWeight: 700,
                        color: isSelected ? "var(--primary)" : "var(--text-muted)",
                        textTransform: "uppercase",
                        letterSpacing: "0.04em",
                      }}
                    >
                      {item.category}
                    </span>
                    {isSelected && (
                      <ArrowRight size={14} color="var(--primary)" />
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Footer Shortcut Guide */}
        <div
          style={{
            padding: "8px 16px",
            borderTop: "1px solid var(--border-color)",
            background: "var(--bg-surface-elevated)",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            fontSize: "0.74rem",
            color: "var(--text-secondary)",
          }}
        >
          <div style={{ display: "flex", gap: 14 }}>
            <span>
              <kbd style={{ padding: "2px 5px", borderRadius: 4, background: "var(--bg-surface-hover)", border: "1px solid var(--border-color)", color: "var(--text-secondary)", fontWeight: 700 }}>↑↓</kbd> Navigate
            </span>
            <span>
              <kbd style={{ padding: "2px 5px", borderRadius: 4, background: "var(--bg-surface-hover)", border: "1px solid var(--border-color)", color: "var(--text-secondary)", fontWeight: 700 }}>↵</kbd> Select
            </span>
            <span>
              <kbd style={{ padding: "2px 5px", borderRadius: 4, background: "var(--bg-surface-hover)", border: "1px solid var(--border-color)", color: "var(--text-secondary)", fontWeight: 700 }}>ESC</kbd> Close
            </span>
          </div>
          <span style={{ fontWeight: 800, color: "var(--primary)" }}>
            MTMMS Spotlight
          </span>
        </div>
      </div>
    </div>
  );
};

export default CommandPalette;
