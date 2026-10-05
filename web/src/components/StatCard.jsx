import React from "react";
import { TrendingUp, TrendingDown, Minus } from "lucide-react";

export const StatCard = ({
  title,
  value,
  icon: Icon,
  color = "indigo", // 'indigo' | 'cyan' | 'emerald' | 'amber' | 'rose'
  subtitle,
  badgeText,
  badgeType = "positive", // 'positive' | 'negative' | 'neutral'
  onClick,
}) => {
  const getColorStyles = () => {
    switch (color) {
      case "cyan":
        return {
          bg: "rgba(6, 182, 212, 0.15)",
          color: "var(--accent-cyan)",
          border: "1px solid rgba(6, 182, 212, 0.3)",
        };
      case "emerald":
        return {
          bg: "rgba(16, 185, 129, 0.15)",
          color: "#10b981",
          border: "1px solid rgba(16, 185, 129, 0.3)",
        };
      case "amber":
        return {
          bg: "rgba(245, 158, 11, 0.15)",
          color: "#f59e0b",
          border: "1px solid rgba(245, 158, 11, 0.3)",
        };
      case "rose":
        return {
          bg: "rgba(239, 68, 68, 0.15)",
          color: "#ef4444",
          border: "1px solid rgba(239, 68, 68, 0.3)",
        };
      case "indigo":
      default:
        return {
          bg: "rgba(99, 102, 241, 0.15)",
          color: "var(--primary-light)",
          border: "1px solid rgba(99, 102, 241, 0.3)",
        };
    }
  };

  const colorStyle = getColorStyles();

  return (
    <div
      className="stat-card"
      onClick={onClick}
      style={{ cursor: onClick ? "pointer" : "default" }}
    >
      <div className="stat-card-header">
        <span className="stat-label">{title}</span>
        {Icon && (
          <div
            className="stat-icon-wrapper"
            style={{
              background: colorStyle.bg,
              color: colorStyle.color,
              border: colorStyle.border,
            }}
          >
            <Icon size={20} />
          </div>
        )}
      </div>

      <div className="stat-value">{value}</div>

      {(subtitle || badgeText) && (
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 2 }}>
          {badgeText && (
            <span
              className={`badge ${
                badgeType === "positive"
                  ? "badge-success"
                  : badgeType === "negative"
                  ? "badge-danger"
                  : "badge-neutral"
              }`}
            >
              {badgeText}
            </span>
          )}
          {subtitle && <span>{subtitle}</span>}
        </div>
      )}
    </div>
  );
};

export default StatCard;
