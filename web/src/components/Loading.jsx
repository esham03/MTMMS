import React from "react";
import { Radio } from "lucide-react";

export const Loading = ({ message = "Loading MTMMS data..." }) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "340px",
        width: "100%",
        gap: 16,
        padding: 40,
      }}
    >
      <div
        style={{
          position: "relative",
          width: 64,
          height: 64,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {/* Glowing pulse ring */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: "50%",
            background: "var(--primary-gradient)",
            opacity: 0.3,
            animation: "pulse 1.5s ease-in-out infinite",
          }}
        ></div>

        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: "50%",
            background: "var(--primary-gradient)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "white",
            boxShadow: "0 0 20px rgba(99, 102, 241, 0.5)",
            zIndex: 2,
          }}
        >
          <Radio size={24} />
        </div>
      </div>

      <div style={{ textAlign: "center" }}>
        <p
          style={{
            fontWeight: 600,
            fontSize: "0.95rem",
            color: "var(--text-primary)",
            marginBottom: 4,
          }}
        >
          {message}
        </p>
        <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
          Department of Telecommunications • Mobile Tower Portal
        </span>
      </div>
    </div>
  );
};

export default Loading;
