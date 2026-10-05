import React from "react";

export const SignalWaves = ({
  phase = 3,
  isConnecting = false,
  isSuccess = false,
  isError = false,
}) => {
  const isBroadcasting = !isError && (phase >= 2 || isConnecting || isSuccess);
  const isBeamActive = phase >= 3 || isConnecting || isSuccess || isError;

  return (
    <div
      className={`signal-waves-container ${
        isBroadcasting ? "active" : ""
      } ${isSuccess ? "verified-broadcast" : ""} ${isError ? "fault-collapsed" : ""}`}
    >
      {/* 1. Concentric RF Waves from Tower Apex Beacon */}
      {isBroadcasting && (
        <div className="rf-pulse-origin">
          <div className="rf-wave wave-1 transmitting"></div>
          <div className="rf-wave wave-2 transmitting"></div>
          <div className="rf-wave wave-3 transmitting"></div>
          <div className="rf-wave wave-4 transmitting"></div>
        </div>
      )}

      {/* 2. Directed High-Speed Microwave Beam to Upper Corner of Login Card */}
      {isBeamActive && (
        <div
          className={`network-connection-bridge ${
            isConnecting ? "high-intensity" : ""
          } ${isSuccess ? "verified-link" : ""} ${isError ? "beam-severed" : ""}`}
        >
          <svg className="data-beam-svg" viewBox="0 0 800 120" fill="none" preserveAspectRatio="none">
            <defs>
              <linearGradient id="beamGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
                <stop offset="20%" stopColor="#06b6d4" stopOpacity="0.9" />
                <stop offset="60%" stopColor="#38bdf8" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#4f46e5" stopOpacity="0.8" />
              </linearGradient>
              <linearGradient id="connectingGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
                <stop offset="25%" stopColor="#facc15" stopOpacity="1" />
                <stop offset="65%" stopColor="#38bdf8" stopOpacity="1" />
                <stop offset="100%" stopColor="#06b6d4" stopOpacity="0.9" />
              </linearGradient>
              <linearGradient id="successGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
                <stop offset="25%" stopColor="#10b981" stopOpacity="1" />
                <stop offset="60%" stopColor="#34d399" stopOpacity="1" />
                <stop offset="100%" stopColor="#6ee7b7" stopOpacity="1" />
              </linearGradient>
              <linearGradient id="errorGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
                <stop offset="30%" stopColor="#ef4444" stopOpacity="1" />
                <stop offset="70%" stopColor="#dc2626" stopOpacity="0.8" />
                <stop offset="100%" stopColor="#7f1d1d" stopOpacity="0.3" />
              </linearGradient>
            </defs>

            {/* Background Ambient Glow Beam (Gently arches directly to top corner of card) */}
            <path
              d="M 0 8 Q 380 4, 780 24"
              stroke={
                isError
                  ? "url(#errorGrad)"
                  : isSuccess
                  ? "url(#successGrad)"
                  : isConnecting
                  ? "url(#connectingGrad)"
                  : "url(#beamGrad)"
              }
              strokeWidth={isSuccess ? "10" : isConnecting ? "8" : isError ? "5" : "6"}
              fill="none"
              opacity={isError ? "0.65" : isSuccess ? "0.6" : isConnecting ? "0.5" : "0.35"}
              strokeLinecap="round"
            />

            {/* Core Focused Stream */}
            <path
              d="M 0 8 Q 380 4, 780 24"
              stroke={
                isError
                  ? "url(#errorGrad)"
                  : isSuccess
                  ? "url(#successGrad)"
                  : isConnecting
                  ? "url(#connectingGrad)"
                  : "url(#beamGrad)"
              }
              strokeWidth={isSuccess ? "4.5" : isConnecting ? "3.5" : isError ? "2" : "2.5"}
              fill="none"
              strokeDasharray={isError ? "6 6" : isSuccess ? "18 3" : isConnecting ? "14 4" : "12 6"}
              className={isError ? "severed-data-stream" : "traveling-data-stream"}
            />
          </svg>

          {/* Flowing High-Energy Photon Particles along the upper trajectory */}
          {!isError && (
            <>
              <div className="photon-node node-1"></div>
              <div className="photon-node node-2"></div>
              <div className="photon-node node-3"></div>
            </>
          )}

          {/* Real-Time Telemetry Status Badge positioned cleanly above the beam */}
          <div
            className="beam-telemetry-badge"
            style={{
              borderColor: isError
                ? "rgba(239, 68, 68, 0.8)"
                : isSuccess
                ? "rgba(16, 185, 129, 0.9)"
                : isConnecting
                ? "rgba(250, 204, 21, 0.8)"
                : "rgba(6, 182, 212, 0.5)",
              color: isError
                ? "#fca5a5"
                : isSuccess
                ? "#6ee7b7"
                : isConnecting
                ? "#fef08a"
                : "#38bdf8",
              boxShadow: isError
                ? "0 0 20px rgba(239, 68, 68, 0.5)"
                : isSuccess
                ? "0 0 25px rgba(16, 185, 129, 0.5)"
                : isConnecting
                ? "0 0 20px rgba(250, 204, 21, 0.4)"
                : "0 0 15px rgba(6, 182, 212, 0.3)",
              background: isError
                ? "rgba(30, 10, 10, 0.95)"
                : isSuccess
                ? "rgba(6, 30, 20, 0.95)"
                : "rgba(15, 23, 42, 0.92)",
            }}
          >
            <span
              className="telemetry-dot"
              style={{
                background: isError ? "#ef4444" : isSuccess ? "#10b981" : isConnecting ? "#facc15" : "#38bdf8",
                boxShadow: isError
                  ? "0 0 10px #ef4444"
                  : isSuccess
                  ? "0 0 12px #10b981"
                  : isConnecting
                  ? "0 0 10px #facc15"
                  : "0 0 8px #38bdf8",
              }}
            ></span>
            <span>
              {isError
                ? "AUTH LINK REJECTED • ACCESS DENIED"
                : isSuccess
                ? "AUTHENTICATED • POWER 100% (2 SEC)"
                : isConnecting
                ? "VERIFYING SANCTUM CREDENTIALS..."
                : "RF LINK ACTIVE • 3.5GHz 5G"}
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default SignalWaves;
