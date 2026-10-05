import React from "react";

export const EngineerAnimation = ({
  phase = 0,
  isConnected = false,
  isConnecting = false,
  isError = false,
  isSuccess = false,
}) => {
  // Phase 0: Walking towards tower base
  // Phase 1+: Arrived, connected, operating
  const isWalking = phase === 0 && !isError;
  const isOperating = phase >= 1 || isConnected || isConnecting || isSuccess;

  return (
    <div
      className={`engineer-wrapper ${
        isWalking ? "walking-in" : "stationed-at-tower"
      } ${isError ? "engineer-fault" : ""}`}
    >
      <svg
        className={`engineer-svg ${isWalking ? "walking" : "connected"}`}
        viewBox="0 0 120 180"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <filter id="toolGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation={isSuccess ? "5" : "2"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Headlamp Light Beam */}
        <path
          d="M 62 42 L 120 20 L 120 65 Z"
          fill={
            isError
              ? "rgba(239, 68, 68, 0.25)"
              : isSuccess
              ? "rgba(16, 185, 129, 0.25)"
              : isConnecting
              ? "rgba(250, 204, 21, 0.2)"
              : "rgba(6, 182, 212, 0.18)"
          }
          className={`headlamp-beam ${isOperating ? "active" : ""}`}
        />

        {/* Ground Shadow */}
        <ellipse cx="50" cy="172" rx="28" ry="6" fill="rgba(0, 0, 0, 0.5)" />

        {/* Left Leg */}
        <path
          d="M 42 110 L 36 142 L 30 170 L 45 170"
          stroke="#1e293b"
          strokeWidth="10"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="engineer-leg-left"
        />

        {/* Right Leg */}
        <path
          d="M 58 110 L 62 142 L 68 170 L 82 170"
          stroke="#0f172a"
          strokeWidth="10"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="engineer-leg-right"
        />

        {/* Boots */}
        <rect x="25" y="165" width="22" height="7" rx="3" fill="#334155" />
        <rect x="63" y="165" width="22" height="7" rx="3" fill="#334155" />

        {/* Torso */}
        <path
          d="M 34 56 L 66 56 L 62 112 L 38 112 Z"
          fill="#1e293b"
          stroke="#0f172a"
          strokeWidth="2"
        />

        {/* High-Vis Safety Uniform Vest */}
        <path
          d="M 36 60 L 64 60 L 60 106 L 40 106 Z"
          fill={isError ? "#991b1b" : isSuccess ? "#047857" : "#0369a1"}
        />
        <line
          x1="38"
          y1="76"
          x2="62"
          y2="76"
          stroke={isError ? "#ef4444" : isSuccess ? "#34d399" : "#38bdf8"}
          strokeWidth="3"
        />
        <line
          x1="40"
          y1="92"
          x2="60"
          y2="92"
          stroke={isError ? "#ef4444" : isSuccess ? "#34d399" : "#38bdf8"}
          strokeWidth="3"
        />

        {/* Left Arm (Carrying diagnostic device) */}
        <path
          d="M 36 62 L 28 85 L 50 96"
          stroke="#1e293b"
          strokeWidth="7"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="engineer-arm-left"
        />

        {/* Right Arm (Connecting cable forward to BTS cabinet when arrived) */}
        <path
          d={
            isOperating
              ? "M 64 62 L 88 75 L 110 82"
              : "M 64 62 L 76 85 L 60 98"
          }
          stroke="#1e293b"
          strokeWidth="7"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="engineer-arm-right"
        />

        {/* Field Diagnostic Terminal Device */}
        <g id="handheld-device">
          <rect
            x="46"
            y="88"
            width="18"
            height="24"
            rx="3"
            fill="#0f172a"
            stroke={isError ? "#ef4444" : isSuccess ? "#10b981" : isConnecting ? "#facc15" : "#475569"}
            strokeWidth="1.5"
          />
          <rect
            x="48"
            y="90"
            width="14"
            height="14"
            rx="2"
            fill={
              isError
                ? "#ef4444"
                : isSuccess
                ? "#10b981"
                : isConnecting
                ? "#facc15"
                : isOperating
                ? "#06b6d4"
                : "#334155"
            }
            filter={isOperating ? "url(#toolGlow)" : undefined}
          />
          {isOperating && (
            <line
              x1="50"
              y1="97"
              x2="60"
              y2="97"
              stroke="#ffffff"
              strokeWidth="1.5"
              strokeDasharray="2 1"
            />
          )}

          {/* Connection Cable extending from diagnostic terminal to tower cabinet */}
          {isOperating && (
            <path
              d="M 64 100 Q 90 106 112 84"
              stroke={isError ? "#ef4444" : isSuccess ? "#10b981" : isConnecting ? "#facc15" : "#06b6d4"}
              strokeWidth="2.5"
              fill="none"
              strokeDasharray="4 2"
              className="connection-spark-line"
            />
          )}
        </g>

        {/* Head */}
        <circle cx="50" cy="40" r="13" fill="#1e293b" />

        {/* Safety Helmet (Hard Hat) */}
        <path
          d="M 35 38 C 35 24, 65 24, 65 38 Z"
          fill="#f59e0b"
          stroke="#b45309"
          strokeWidth="1.5"
        />
        <rect x="33" y="36" width="34" height="4" rx="2" fill="#f59e0b" />

        {/* Helmet Headlamp */}
        <rect
          x="62"
          y="34"
          width="5"
          height="5"
          rx="1.5"
          fill={isError ? "#ef4444" : isSuccess ? "#34d399" : isConnecting ? "#fef08a" : "#38bdf8"}
          filter={isOperating ? "url(#toolGlow)" : undefined}
        />
      </svg>

      {/* Terminal Connection Spark Pulse */}
      {isOperating && !isError && <div className="cable-plug-spark"></div>}
      {isError && <div className="cable-plug-spark error-spark"></div>}
    </div>
  );
};

export default EngineerAnimation;
