import React from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutDashboard,
  Map,
  Radio,
  Building2,
  MapPin,
  Antenna,
  Receipt,
  CreditCard,
  BarChart3,
  UserCheck,
  LogOut,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";

export const Sidebar = ({ collapsed = false, isOpen = false, onClose }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  const coreLinks = [
    { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
    { to: "/map", label: "GIS Map View", icon: Map },
    { to: "/towers", label: "Tower Management", icon: Radio },
    { to: "/owners", label: "Tower Owners", icon: Building2 },
    { to: "/locations", label: "Location Browser", icon: MapPin },
    { to: "/operators", label: "Operators", icon: Antenna },
  ];

  const financialLinks = [
    { to: "/rent", label: "Rent Management", icon: Receipt },
    { to: "/payments", label: "Payment History", icon: CreditCard },
    { to: "/reports", label: "Reports", icon: BarChart3 },
  ];

  const adminLinks = [
    { to: "/profile", label: "Officer Profile", icon: UserCheck },
  ];

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && (
        <div
          onClick={onClose}
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(0,0,0,0.55)",
            backdropFilter: "blur(2px)",
            zIndex: 29,
          }}
          aria-label="Close sidebar"
        />
      )}
      <aside
        className={`sidebar-container ${collapsed ? "sidebar-collapsed" : ""} ${
          isOpen ? "sidebar-open" : ""
        }`}
      >
      {/* Sidebar Header / Brand */}
      <div className="sidebar-header">
        <NavLink to="/dashboard" className="brand-logo" onClick={onClose}>
          <div className="brand-icon-box">
            <Radio size={20} />
          </div>
          {!collapsed && (
            <div className="brand-text">
              <h2>MTMMS</h2>
              <span>DoIT Gov of Goa</span>
            </div>
          )}
        </NavLink>
      </div>

      {/* Navigation Sections */}
      <nav className="sidebar-nav">
        {!collapsed && <div className="nav-section-title">Core Modules</div>}
        {coreLinks.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onClose}
              className={({ isActive }) =>
                `nav-link-item ${isActive ? "active" : ""}`
              }
              title={collapsed ? item.label : undefined}
            >
              <Icon size={18} style={{ flexShrink: 0 }} />
              {!collapsed && <span>{item.label}</span>}
            </NavLink>
          );
        })}

        {!collapsed && <div className="nav-section-title">Finance & Revenue</div>}
        {financialLinks.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onClose}
              className={({ isActive }) =>
                `nav-link-item ${isActive ? "active" : ""}`
              }
              title={collapsed ? item.label : undefined}
            >
              <Icon size={18} style={{ flexShrink: 0 }} />
              {!collapsed && <span>{item.label}</span>}
            </NavLink>
          );
        })}

        {!collapsed && <div className="nav-section-title">Administration</div>}
        {adminLinks.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onClose}
              className={({ isActive }) =>
                `nav-link-item ${isActive ? "active" : ""}`
              }
              title={collapsed ? item.label : undefined}
            >
              <Icon size={18} style={{ flexShrink: 0 }} />
              {!collapsed && <span>{item.label}</span>}
            </NavLink>
          );
        })}

        <button
          type="button"
          onClick={handleLogout}
          className="nav-link-item"
          style={{
            background: "none",
            border: "none",
            width: "100%",
            textAlign: "left",
            cursor: "pointer",
            marginTop: 8,
            color: "#f87171",
          }}
          title={collapsed ? "Logout" : undefined}
        >
          <LogOut size={18} style={{ flexShrink: 0 }} />
          {!collapsed && <span>Logout</span>}
        </button>
      </nav>

      {/* Sidebar Footer User Badge */}
      {!collapsed && (
        <div className="sidebar-footer">
          <div className="admin-badge-card">
            <div className="user-avatar">
              <UserCheck size={15} />
            </div>
            <div style={{ overflow: "hidden" }}>
              <div
                style={{
                  fontSize: "0.82rem",
                  fontWeight: 600,
                  color: "var(--text-primary)",
                  whiteSpace: "nowrap",
                  textOverflow: "ellipsis",
                  overflow: "hidden",
                }}
              >
                {user?.name || "Administrator"}
              </div>
              <div
                style={{
                  fontSize: "0.7rem",
                  color: "var(--text-muted)",
                  whiteSpace: "nowrap",
                  textOverflow: "ellipsis",
                  overflow: "hidden",
                }}
              >
                {user?.department || "Department of Information Technology"}
              </div>
            </div>
          </div>
        </div>
      )}
    </aside>
    </>
  );
};

export default Sidebar;
