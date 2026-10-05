import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sun,
  Moon,
  Search,
  LogOut,
  UserCheck,
  Menu,
  X,
  Bell,
  AlertCircle,
  AlertTriangle,
  Clock,
  ArrowRight,
  CheckCircle2,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import towerApi from "../api/towerApi";

export const Navbar = ({ onToggleSidebar, onOpenCommandPalette }) => {
  const navigate = useNavigate();
  const { user, logout, theme, toggleTheme } = useAuth();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [rentNotifications, setRentNotifications] = useState([]);
  const notifRef = useRef(null);

  // Fetch towers and compute rent notifications on mount
  useEffect(() => {
    const load = async () => {
      try {
        const towers = await towerApi.getTowers().catch(() => []);
        if (!Array.isArray(towers)) return;

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const in7 = new Date(today);
        in7.setDate(in7.getDate() + 7);
        const in30 = new Date(today);
        in30.setDate(in30.getDate() + 30);

        const notifs = towers
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
          .slice(0, 15);

        setRentNotifications(notifs);
      } catch (_) {}
    };
    load();
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handler = (e) => {
      if (notifRef.current && !notifRef.current.contains(e.target)) {
        setShowNotifications(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleSearch = (e) => {
    if (e.key === "Enter" && searchQuery.trim()) {
      navigate(`/towers?search=${encodeURIComponent(searchQuery.trim())}`);
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  const overdueCount = rentNotifications.filter((n) => n._status === "overdue").length;
  const criticalCount = rentNotifications.filter((n) => n._status === "critical").length;
  const badgeCount = overdueCount + criticalCount;

  const statusCfg = {
    overdue: {
      icon: <AlertCircle size={14} color="#ef4444" />,
      tagColor: "#ef4444",
      tagBg: "rgba(239,68,68,0.12)",
      borderColor: "#ef444425",
      rowBg: "rgba(239,68,68,0.04)",
      label: "OVERDUE",
    },
    critical: {
      icon: <AlertTriangle size={14} color="#f59e0b" />,
      tagColor: "#f59e0b",
      tagBg: "rgba(245,158,11,0.12)",
      borderColor: "#f59e0b25",
      rowBg: "rgba(245,158,11,0.04)",
      label: "DUE SOON",
    },
    upcoming: {
      icon: <Clock size={14} color="var(--accent-cyan)" />,
      tagColor: "var(--accent-cyan)",
      tagBg: "rgba(6,182,212,0.1)",
      borderColor: "var(--border-color)",
      rowBg: "transparent",
      label: "UPCOMING",
    },
  };

  return (
    <header className="navbar-container">
      {/* Left: Sidebar toggle + brand title */}
      <div className="nav-left">
        <button
          className="btn btn-secondary btn-icon"
          onClick={onToggleSidebar}
          title="Toggle Navigation Menu"
          aria-label="Toggle Navigation Menu"
        >
          <Menu size={18} />
        </button>

        <div className="nav-header-brand-titles">
          <span className="nav-brand-main-title">
            Mobile Tower Monitoring &amp; Management system
          </span>
          <span className="nav-brand-sub-title">
            Department of Information Technology-Gov of Goa
          </span>
        </div>
      </div>

      {/* Center: Global Search / Command Palette */}
      <div
        className="nav-search-wrapper"
        onClick={() => onOpenCommandPalette && onOpenCommandPalette()}
        style={{ cursor: "pointer" }}
        title="Open Command Palette (Ctrl+K)"
      >
        <Search size={16} className="nav-search-icon" />
        <input
          type="text"
          className="nav-search-input"
          placeholder="Search towers, areas, operators... (Ctrl+K)"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyDown={handleSearch}
          readOnly={Boolean(onOpenCommandPalette)}
          style={{ cursor: "pointer" }}
        />
        <span
          className="nav-search-kbd-badge"
          style={{ cursor: "pointer" }}
          onClick={(e) => {
            e.stopPropagation();
            onOpenCommandPalette && onOpenCommandPalette();
          }}
        >
          <kbd>Ctrl+K</kbd>
        </span>
      </div>

      {/* Right: Bell + Theme + Profile */}
      <div className="nav-right">

        {/* ── Bell Notification ── */}
        <div style={{ position: "relative" }} ref={notifRef}>
          <button
            className="btn btn-secondary btn-icon"
            onClick={() => {
              setShowNotifications((v) => !v);
              setShowUserMenu(false);
            }}
            title="Rent Notifications"
            aria-label="Rent Notifications"
            style={{ position: "relative" }}
          >
            <Bell
              size={18}
              color={badgeCount > 0 ? "#f59e0b" : undefined}
              style={
                badgeCount > 0
                  ? { filter: "drop-shadow(0 0 5px #f59e0b90)" }
                  : {}
              }
            />
            {/* Badge */}
            {badgeCount > 0 && (
              <span
                style={{
                  position: "absolute",
                  top: 3,
                  right: 3,
                  minWidth: 16,
                  height: 16,
                  borderRadius: 999,
                  background: overdueCount > 0 ? "#ef4444" : "#f59e0b",
                  color: "#fff",
                  fontSize: "0.58rem",
                  fontWeight: 900,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  padding: "0 3px",
                  boxShadow: "0 0 0 2px var(--bg-surface)",
                  pointerEvents: "none",
                  lineHeight: 1,
                  animation: "pulse 2s ease infinite",
                }}
              >
                {badgeCount > 9 ? "9+" : badgeCount}
              </span>
            )}
          </button>

          {/* Dropdown */}
          {showNotifications && (
            <div
              style={{
                position: "absolute",
                right: 0,
                top: "calc(100% + 10px)",
                width: 360,
                maxHeight: 500,
                overflowY: "auto",
                background: "var(--bg-surface)",
                border: "1px solid var(--border-color-light)",
                borderRadius: "var(--radius-lg)",
                boxShadow: "var(--shadow-lg)",
                zIndex: 60,
                display: "flex",
                flexDirection: "column",
              }}
            >
              {/* Dropdown header */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  padding: "13px 14px 10px",
                  borderBottom: "1px solid var(--border-color)",
                  flexShrink: 0,
                  position: "sticky",
                  top: 0,
                  background: "var(--bg-surface)",
                  zIndex: 1,
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                  <Bell size={14} color={badgeCount > 0 ? "#f59e0b" : "var(--text-muted)"} />
                  <span style={{ fontWeight: 700, fontSize: "0.87rem" }}>
                    Rent Notifications
                  </span>
                  {badgeCount > 0 && (
                    <span
                      style={{
                        background: overdueCount > 0 ? "rgba(239,68,68,0.12)" : "rgba(245,158,11,0.12)",
                        color: overdueCount > 0 ? "#ef4444" : "#f59e0b",
                        fontSize: "0.62rem",
                        fontWeight: 800,
                        padding: "1px 7px",
                        borderRadius: 20,
                        letterSpacing: "0.04em",
                      }}
                    >
                      {badgeCount} Alert{badgeCount !== 1 ? "s" : ""}
                    </span>
                  )}
                </div>
                <button
                  className="btn btn-outline btn-sm"
                  style={{ fontSize: "0.7rem", padding: "2px 9px", gap: 4 }}
                  onClick={() => {
                    navigate("/rent");
                    setShowNotifications(false);
                  }}
                >
                  View All
                  <ArrowRight size={11} />
                </button>
              </div>

              {/* Notification rows */}
              <div style={{ padding: "8px", display: "flex", flexDirection: "column", gap: 4 }}>
                {rentNotifications.length === 0 ? (
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      padding: "30px 0",
                      gap: 8,
                      color: "var(--text-muted)",
                    }}
                  >
                    <CheckCircle2 size={28} color="#34d399" style={{ opacity: 0.75 }} />
                    <p style={{ fontSize: "0.78rem", textAlign: "center", lineHeight: 1.5 }}>
                      All rents are up to date.<br />No dues in the next 30 days.
                    </p>
                  </div>
                ) : (
                  rentNotifications.map((t, idx) => {
                    const cfg = statusCfg[t._status];
                    const now = new Date();
                    now.setHours(0, 0, 0, 0);
                    const daysLeft = Math.ceil(
                      (t._dueDate - now) / (1000 * 60 * 60 * 24)
                    );
                    const dueLabel =
                      t._status === "overdue"
                        ? `${Math.abs(daysLeft)}d overdue`
                        : daysLeft === 0
                        ? "Due today"
                        : `Due in ${daysLeft}d`;

                    return (
                      <div
                        key={t.id || idx}
                        onClick={() => {
                          navigate(`/towers/${t.id}`);
                          setShowNotifications(false);
                        }}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: 9,
                          padding: "8px 10px",
                          borderRadius: "var(--radius-md)",
                          background: cfg.rowBg,
                          border: `1px solid ${cfg.borderColor}`,
                          cursor: "pointer",
                          transition: "background 0.15s",
                        }}
                        onMouseEnter={(e) =>
                          (e.currentTarget.style.background =
                            "var(--bg-surface-elevated)")
                        }
                        onMouseLeave={(e) =>
                          (e.currentTarget.style.background = cfg.rowBg)
                        }
                      >
                        <div style={{ flexShrink: 0 }}>{cfg.icon}</div>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div
                            style={{
                              display: "flex",
                              alignItems: "center",
                              gap: 5,
                              flexWrap: "wrap",
                            }}
                          >
                            <span
                              style={{
                                fontWeight: 700,
                                fontSize: "0.82rem",
                                color: "var(--text-primary)",
                              }}
                            >
                              {t.tower_unique_id || `TWR-${t.id}`}
                            </span>
                            <span
                              style={{
                                fontSize: "0.56rem",
                                fontWeight: 800,
                                color: cfg.tagColor,
                                background: cfg.tagBg,
                                padding: "1px 6px",
                                borderRadius: 20,
                                letterSpacing: "0.05em",
                              }}
                            >
                              {cfg.label}
                            </span>
                          </div>
                          <div
                            style={{
                              fontSize: "0.71rem",
                              color: "var(--text-muted)",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                              whiteSpace: "nowrap",
                            }}
                          >
                            {t.area?.name || t.area_name || "—"}
                          </div>
                        </div>
                        <div style={{ textAlign: "right", flexShrink: 0 }}>
                          <div
                            style={{
                              fontSize: "0.74rem",
                              fontWeight: 700,
                              color: cfg.tagColor,
                              whiteSpace: "nowrap",
                            }}
                          >
                            {dueLabel}
                          </div>
                          <div
                            style={{
                              fontSize: "0.62rem",
                              color: "var(--text-muted)",
                            }}
                          >
                            {t.rent_due_date?.split("T")[0] || "—"}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          )}
        </div>

        {/* Theme toggle */}
        <button
          className="btn btn-secondary btn-icon"
          onClick={toggleTheme}
          title={`Switch to ${theme === "dark" ? "Light" : "Dark"} Mode`}
          aria-label="Toggle Theme"
        >
          {theme === "dark" ? <Sun size={17} /> : <Moon size={17} />}
        </button>

        {/* Officer profile */}
        <div style={{ position: "relative" }}>
          <button
            className="user-profile-btn"
            onClick={() => {
              setShowUserMenu(!showUserMenu);
              setShowNotifications(false);
            }}
            title="Officer Account & Profile"
          >
            <div className="user-avatar">
              <UserCheck size={14} />
            </div>
            <span
              style={{
                fontWeight: 600,
                maxWidth: 120,
                overflow: "hidden",
                textOverflow: "ellipsis",
                whiteSpace: "nowrap",
              }}
            >
              {user?.name || "Officer"}
            </span>
          </button>

          {showUserMenu && (
            <div
              style={{
                position: "absolute",
                right: 0,
                top: "100%",
                marginTop: 8,
                width: 220,
                background: "var(--bg-surface)",
                border: "1px solid var(--border-color-light)",
                borderRadius: "var(--radius-md)",
                boxShadow: "var(--shadow-lg)",
                padding: "8px",
                zIndex: 60,
              }}
            >
              <div
                style={{
                  padding: "8px 10px",
                  borderBottom: "1px solid var(--border-color)",
                }}
              >
                <div
                  style={{
                    fontWeight: 600,
                    fontSize: "0.85rem",
                    color: "var(--text-primary)",
                  }}
                >
                  {user?.name || "Administrator"}
                </div>
                <div
                  style={{
                    fontSize: "0.72rem",
                    color: "var(--text-muted)",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {user?.email || "admin@goa.gov.in"}
                </div>
              </div>

              <button
                onClick={() => {
                  setShowUserMenu(false);
                  navigate("/profile");
                }}
                className="btn btn-secondary btn-sm"
                style={{
                  width: "100%",
                  justifyContent: "flex-start",
                  marginTop: 6,
                  border: "none",
                }}
              >
                <UserCheck size={14} />
                <span>Officer Profile</span>
              </button>

              <button
                onClick={handleLogout}
                className="btn btn-secondary btn-sm"
                style={{
                  width: "100%",
                  justifyContent: "flex-start",
                  color: "#f87171",
                  border: "none",
                }}
              >
                <LogOut size={14} />
                <span>Sign Out</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};

export default Navbar;
