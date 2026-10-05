import React from "react";

export const TowerScene = ({
  phase = 3,
  isConnected = true,
  isConnecting = false,
  isSuccess = false,
  isError = false,
}) => {
  const isPowered = phase >= 2 || isConnected || isConnecting || isSuccess;

  const energyColor = isError
    ? "#ef4444"
    : isSuccess
    ? "#10b981"
    : isConnecting
    ? "#facc15"
    : "#06b6d4";

  const glowColor = isError
    ? "rgba(239, 68, 68, 0.8)"
    : isSuccess
    ? "rgba(16, 185, 129, 0.9)"
    : isConnecting
    ? "rgba(250, 204, 21, 0.8)"
    : "rgba(6, 182, 212, 0.7)";

  const beaconColor = isError
    ? "#dc2626"
    : isSuccess
    ? "#059669"
    : isConnecting
    ? "#eab308"
    : "#38bdf8";

  return (
    <div className={`tower-scene-container ${isError ? "fault-state" : ""} ${isSuccess ? "success-state" : ""}`}>
      {/* 3D Volumetric Horizon Aura & Dynamic Glow */}
      <div
        className="tower-ambient-glow"
        style={{
          background: isError
            ? "radial-gradient(ellipse at 50% 60%, rgba(239, 68, 68, 0.28) 0%, rgba(220, 38, 38, 0.1) 40%, transparent 70%)"
            : isSuccess
            ? "radial-gradient(ellipse at 50% 60%, rgba(16, 185, 129, 0.35) 0%, rgba(5, 150, 105, 0.15) 45%, transparent 70%)"
            : isConnecting
            ? "radial-gradient(ellipse at 50% 60%, rgba(250, 204, 21, 0.28) 0%, rgba(234, 179, 8, 0.1) 40%, transparent 70%)"
            : "radial-gradient(ellipse at 50% 60%, rgba(6, 182, 212, 0.2) 0%, rgba(79, 70, 229, 0.08) 50%, transparent 70%)",
        }}
      />

      <svg
        className={`tower-svg-mesh ${isPowered ? "powered-up" : "dormant"} ${
          isSuccess ? "verified-state" : ""
        } ${isError ? "error-state" : ""}`}
        viewBox="0 0 440 720"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid meet"
      >
        <defs>
          {/* Dynamic Energy Conduit Gradients */}
          <linearGradient id="towerPowerGrad" x1="0%" y1="100%" x2="0%" y2="0%">
            <stop offset="0%" stopColor={isError ? "#7f1d1d" : isSuccess ? "#047857" : isConnecting ? "#ca8a04" : "#0284c7"} stopOpacity="0.3" />
            <stop offset="40%" stopColor={energyColor} stopOpacity="0.9" />
            <stop offset="80%" stopColor={isSuccess ? "#6ee7b7" : isError ? "#fca5a5" : "#7dd3fc"} stopOpacity="1" />
            <stop offset="100%" stopColor="#ffffff" stopOpacity="1" />
          </linearGradient>

          <linearGradient id="latticeSteelGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#334155" />
            <stop offset="50%" stopColor="#64748b" />
            <stop offset="100%" stopColor="#1e293b" />
          </linearGradient>

          <linearGradient id="cabinetGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#1e293b" />
            <stop offset="100%" stopColor="#0f172a" />
          </linearGradient>

          {/* Dynamic Glow Filters */}
          <filter id="beaconPulseGlow" x="-60%" y="-60%" width="220%" height="220%">
            <feGaussianBlur in="SourceGraphic" stdDeviation={isSuccess ? "10" : isError ? "8" : "6"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <filter id="sectorGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation={isSuccess ? "6" : "3.5"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <filter id="electricalSparkGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation="5" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* ============================================================
            1. GROUND FOUNDATION & CONCRETE PLINTH
           ============================================================ */}
        <g id="ground-platform">
          {/* Ground Ambient Grid Lines */}
          <ellipse cx="220" cy="690" rx="190" ry="24" fill="rgba(15, 23, 42, 0.7)" />
          <ellipse cx="220" cy="690" rx="160" ry="18" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
          <ellipse cx="220" cy="690" rx="120" ry="14" stroke={glowColor} strokeWidth="1.5" opacity={isSuccess ? "0.8" : "0.3"} />

          {/* Reinforced Concrete Plinth */}
          <path
            d="M 120 684 L 320 684 L 335 702 L 105 702 Z"
            fill="#1e293b"
            stroke="#334155"
            strokeWidth="1.5"
          />
          {/* Plinth Chamfer highlight */}
          <line x1="120" y1="684" x2="320" y2="684" stroke="#475569" strokeWidth="2" />

          {/* 4 Steel Anchor Base Plates with Bolts */}
          <rect x="135" y="676" width="22" height="8" rx="2" fill="#475569" stroke="#64748b" />
          <circle cx="140" cy="680" r="1.5" fill="#cbd5e1" />
          <circle cx="152" cy="680" r="1.5" fill="#cbd5e1" />

          <rect x="283" y="676" width="22" height="8" rx="2" fill="#475569" stroke="#64748b" />
          <circle cx="288" cy="680" r="1.5" fill="#cbd5e1" />
          <circle cx="300" cy="680" r="1.5" fill="#cbd5e1" />
        </g>

        {/* ============================================================
            2. BTS TELECOM EQUIPMENT SHELTER & CABINET
           ============================================================ */}
        <g id="bts-shelter">
          {/* Main BTS Outdoor Cabinet */}
          <rect
            x="290"
            y="615"
            width="55"
            height="65"
            rx="4"
            fill="url(#cabinetGrad)"
            stroke="#475569"
            strokeWidth="1.5"
          />
          {/* Cabinet Door Seam */}
          <line x1="318" y1="617" x2="318" y2="678" stroke="#334155" strokeWidth="1" />
          {/* Door Handle */}
          <rect x="313" y="642" width="3" height="10" rx="1" fill="#94a3b8" />

          {/* Ventilation Louvers */}
          <line x1="296" y1="623" x2="312" y2="623" stroke="#334155" strokeWidth="1.5" />
          <line x1="296" y1="627" x2="312" y2="627" stroke="#334155" strokeWidth="1.5" />
          <line x1="296" y1="631" x2="312" y2="631" stroke="#334155" strokeWidth="1.5" />

          {/* Rack Status LED Indicators */}
          <circle cx="326" cy="624" r="2" fill={isError ? "#ef4444" : isSuccess ? "#10b981" : isConnecting ? "#facc15" : "#10b981"} filter="url(#sectorGlow)" />
          <circle cx="333" cy="624" r="2" fill={isError ? "#ef4444" : isSuccess ? "#10b981" : "#06b6d4"} />
          <circle cx="340" cy="624" r="2" fill={isError ? "#ef4444" : isSuccess ? "#34d399" : "#38bdf8"} />

          {/* Equipment Status LCD Screen */}
          <rect x="324" y="632" width="18" height="10" rx="1.5" fill="#020617" stroke="#334155" strokeWidth="0.8" />
          <line x1="326" y1="636" x2="338" y2="636" stroke={energyColor} strokeWidth="1" strokeDasharray="2 1" />
          <line x1="326" y1="639" x2="334" y2="639" stroke={energyColor} strokeWidth="1" strokeDasharray="2 1" />

          {/* Heavy Feeder Conduit from BTS Cabinet to Tower Base */}
          <path
            d="M 290 655 C 275 660, 260 665, 235 670"
            stroke="#334155"
            strokeWidth="4"
            fill="none"
          />
          <path
            d="M 290 655 C 275 660, 260 665, 235 670"
            stroke={energyColor}
            strokeWidth={isSuccess ? "3" : isConnecting ? "2.5" : "2"}
            fill="none"
            strokeDasharray={isError ? "3 3" : isSuccess ? "8 2" : "6 3"}
            className={isError ? "conduit-stream fault-flicker" : isSuccess ? "conduit-stream flowing-super" : "conduit-stream flowing"}
          />
        </g>

        {/* ============================================================
            3. HEAVY STEEL LATTICE TOWER STRUCTURE (Multi-Tier)
           ============================================================ */}
        <g id="tower-lattice-structure">
          {/* Vertical Center Climbing Ladder with Rungs */}
          <line x1="216" y1="120" x2="216" y2="676" stroke="#334155" strokeWidth="1.5" />
          <line x1="224" y1="120" x2="224" y2="676" stroke="#334155" strokeWidth="1.5" />
          {/* Ladder Rungs (Every 18px) */}
          {Array.from({ length: 30 }).map((_, idx) => (
            <line
              key={`rung-${idx}`}
              x1="216"
              y1={130 + idx * 18}
              x2="224"
              y2={130 + idx * 18}
              stroke="#475569"
              strokeWidth="1"
            />
          ))}

          {/* Primary High-Voltage Feeder Waveguide (Illuminated Center Spine) */}
          <line
            x1="220"
            y1="40"
            x2="220"
            y2="676"
            stroke={isPowered ? "url(#towerPowerGrad)" : "#1e293b"}
            strokeWidth={isSuccess ? "4" : isConnecting ? "3.5" : isError ? "2" : "3"}
            strokeLinecap="round"
            className={
              isError
                ? "conduit-stream fault-flicker"
                : isSuccess
                ? "conduit-stream flowing-super"
                : isPowered
                ? "conduit-stream flowing"
                : ""
            }
          />

          {/* Left Main Corner Structural Leg (Tapering from 145 to 212) */}
          <line x1="145" y1="676" x2="212" y2="120" stroke="url(#latticeSteelGrad)" strokeWidth="4.5" strokeLinecap="round" />
          {/* Right Main Corner Structural Leg (Tapering from 295 to 228) */}
          <line x1="295" y1="676" x2="228" y2="120" stroke="url(#latticeSteelGrad)" strokeWidth="4.5" strokeLinecap="round" />

          {/* Internal Cross-Legs (3D Depth) */}
          <line x1="165" y1="676" x2="215" y2="120" stroke="#1e293b" strokeWidth="2.5" opacity="0.6" />
          <line x1="275" y1="676" x2="225" y2="120" stroke="#1e293b" strokeWidth="2.5" opacity="0.6" />

          {/* Horizontal Girders & X-Bracing Tiers */}
          {/* Tier 6 (Base) */}
          <line x1="145" y1="676" x2="295" y2="676" stroke="#475569" strokeWidth="3" />
          <line x1="152" y1="580" x2="288" y2="580" stroke="#475569" strokeWidth="3" />
          <line x1="145" y1="676" x2="288" y2="580" stroke="#334155" strokeWidth="2" />
          <line x1="295" y1="676" x2="152" y2="580" stroke="#334155" strokeWidth="2" />
          {/* Secondary K-Brace */}
          <line x1="220" y1="628" x2="148" y2="628" stroke="#334155" strokeWidth="1.5" />
          <line x1="220" y1="628" x2="292" y2="628" stroke="#334155" strokeWidth="1.5" />

          {/* Tier 5 */}
          <line x1="160" y1="486" x2="280" y2="486" stroke="#475569" strokeWidth="3" />
          <line x1="152" y1="580" x2="280" y2="486" stroke="#334155" strokeWidth="2" />
          <line x1="288" y1="580" x2="160" y2="486" stroke="#334155" strokeWidth="2" />

          {/* Tier 4 (Mid-Platform Level with Obstruction Lights) */}
          <line x1="168" y1="394" x2="272" y2="394" stroke="#475569" strokeWidth="3" />
          <line x1="160" y1="486" x2="272" y2="394" stroke="#334155" strokeWidth="2" />
          <line x1="280" y1="486" x2="168" y2="394" stroke="#334155" strokeWidth="2" />

          {/* Mid-Tier Walkway Rest Grating */}
          <rect x="162" y="392" width="116" height="4" rx="1" fill="#475569" stroke="#64748b" />
          {/* Mid-Tier Red Aviation Warning Lights */}
          <circle cx="164" cy="394" r="3.5" fill={isError ? "#ef4444" : "#ef4444"} className="beacon-strobe" filter="url(#beaconPulseGlow)" />
          <circle cx="276" cy="394" r="3.5" fill={isError ? "#ef4444" : "#ef4444"} className="beacon-strobe" filter="url(#beaconPulseGlow)" />

          {/* Tier 3 */}
          <line x1="178" y1="300" x2="262" y2="300" stroke="#475569" strokeWidth="2.5" />
          <line x1="168" y1="394" x2="262" y2="300" stroke="#334155" strokeWidth="1.8" />
          <line x1="272" y1="394" x2="178" y2="300" stroke="#334155" strokeWidth="1.8" />

          {/* Tier 2 */}
          <line x1="190" y1="208" x2="250" y2="208" stroke="#475569" strokeWidth="2.5" />
          <line x1="178" y1="300" x2="250" y2="208" stroke="#334155" strokeWidth="1.8" />
          <line x1="262" y1="300" x2="190" y2="208" stroke="#334155" strokeWidth="1.8" />

          {/* Tier 1 (Apex Base) */}
          <line x1="202" y1="120" x2="238" y2="120" stroke="#475569" strokeWidth="2.5" />
          <line x1="190" y1="208" x2="238" y2="120" stroke="#334155" strokeWidth="1.8" />
          <line x1="250" y1="208" x2="202" y2="120" stroke="#334155" strokeWidth="1.8" />
        </g>

        {/* ============================================================
            4. MICROWAVE DRUM DISH ANTENNAS (Directional Backhaul)
           ============================================================ */}
        <g id="microwave-dishes">
          {/* Dish 1: Left Middle Tier (Facing WNW) */}
          <g transform="translate(144, 320)">
            <ellipse cx="12" cy="18" rx="16" ry="16" fill="#0f172a" stroke="#475569" strokeWidth="2" />
            <ellipse cx="12" cy="18" rx="13" ry="13" fill="#1e293b" stroke={energyColor} strokeWidth="1" />
            <circle cx="12" cy="18" r="4" fill={isPowered ? energyColor : "#475569"} filter={isPowered ? "url(#sectorGlow)" : undefined} />
            {/* Feedhorn Sub-reflector Struts */}
            <line x1="12" y1="18" x2="0" y2="10" stroke="#64748b" strokeWidth="1.5" />
            <line x1="12" y1="18" x2="0" y2="26" stroke="#64748b" strokeWidth="1.5" />
            {/* Mount Bracket */}
            <line x1="28" y1="18" x2="38" y2="18" stroke="#64748b" strokeWidth="3" />
          </g>

          {/* Dish 2: Right Upper Tier (Facing ENE) */}
          <g transform="translate(245, 230)">
            <ellipse cx="14" cy="16" rx="14" ry="14" fill="#0f172a" stroke="#475569" strokeWidth="2" />
            <ellipse cx="14" cy="16" rx="11" ry="11" fill="#1e293b" stroke={energyColor} strokeWidth="1" />
            <circle cx="14" cy="16" r="3.5" fill={isPowered ? energyColor : "#475569"} filter={isPowered ? "url(#sectorGlow)" : undefined} />
            <line x1="14" y1="16" x2="26" y2="9" stroke="#64748b" strokeWidth="1.2" />
            <line x1="14" y1="16" x2="26" y2="23" stroke="#64748b" strokeWidth="1.2" />
            <line x1="0" y1="16" x2="-10" y2="16" stroke="#64748b" strokeWidth="3" />
          </g>
        </g>

        {/* ============================================================
            5. APEX HEADFRAME & 5G MASSIVE MIMO SECTOR ANTENNAS
           ============================================================ */}
        <g id="apex-antenna-array">
          {/* Triangular Headframe Mounting Platform */}
          <polygon points="175,120 265,120 248,114 192,114" fill="#334155" stroke="#64748b" strokeWidth="1.5" />
          <line x1="175" y1="120" x2="265" y2="120" stroke="#94a3b8" strokeWidth="2" />

          {/* Sector 1 (Left 5G MIMO Panel) */}
          <rect
            x="170"
            y="42"
            width="15"
            height="72"
            rx="3"
            fill={isError ? "#1e1e1e" : isPowered ? "#0f172a" : "#1e293b"}
            stroke={isError ? "#ef4444" : isPowered ? energyColor : "#475569"}
            strokeWidth={isSuccess ? "3.5" : isPowered ? "2.5" : "1.5"}
            filter={isPowered ? "url(#sectorGlow)" : undefined}
          />
          {isPowered && (
            <>
              <line x1="177" y1="48" x2="177" y2="108" stroke={energyColor} strokeWidth={isSuccess ? "4.5" : "3"} strokeLinecap="round" />
              <circle cx="177" cy="54" r="2" fill="#ffffff" />
              <circle cx="177" cy="78" r="2" fill="#ffffff" />
              <circle cx="177" cy="102" r="2" fill="#ffffff" />
            </>
          )}

          {/* Sector 2 (Center 5G MIMO Panel) */}
          <rect
            x="212"
            y="36"
            width="16"
            height="78"
            rx="3"
            fill={isError ? "#1e1e1e" : isPowered ? "#0f172a" : "#1e293b"}
            stroke={isError ? "#ef4444" : isPowered ? energyColor : "#475569"}
            strokeWidth={isSuccess ? "4" : isPowered ? "3" : "1.5"}
            filter={isPowered ? "url(#sectorGlow)" : undefined}
          />
          {isPowered && (
            <>
              <line x1="220" y1="42" x2="220" y2="108" stroke={energyColor} strokeWidth={isSuccess ? "5" : "4"} strokeLinecap="round" />
              <circle cx="220" cy="50" r="2.5" fill="#ffffff" />
              <circle cx="220" cy="75" r="2.5" fill="#ffffff" />
              <circle cx="220" cy="100" r="2.5" fill="#ffffff" />
            </>
          )}

          {/* Sector 3 (Right 5G MIMO Panel) */}
          <rect
            x="255"
            y="42"
            width="15"
            height="72"
            rx="3"
            fill={isError ? "#1e1e1e" : isPowered ? "#0f172a" : "#1e293b"}
            stroke={isError ? "#ef4444" : isPowered ? energyColor : "#475569"}
            strokeWidth={isSuccess ? "3.5" : isPowered ? "2.5" : "1.5"}
            filter={isPowered ? "url(#sectorGlow)" : undefined}
          />
          {isPowered && (
            <>
              <line x1="262" y1="48" x2="262" y2="108" stroke={energyColor} strokeWidth={isSuccess ? "4.5" : "3"} strokeLinecap="round" />
              <circle cx="262" cy="54" r="2" fill="#ffffff" />
              <circle cx="262" cy="78" r="2" fill="#ffffff" />
              <circle cx="262" cy="102" r="2" fill="#ffffff" />
            </>
          )}

          {/* Mount Tie Struts */}
          <line x1="177" y1="114" x2="220" y2="120" stroke="#64748b" strokeWidth="2" />
          <line x1="262" y1="114" x2="220" y2="120" stroke="#64748b" strokeWidth="2" />
        </g>

        {/* ============================================================
            6. APEX LIGHTNING MAST & SUPERCHARGED AVIATION BEACON
           ============================================================ */}
        <g id="apex-beacon-group">
          {/* Stainless Lightning Finial Rod */}
          <line x1="220" y1="36" x2="220" y2="6" stroke="#e2e8f0" strokeWidth="3" strokeLinecap="round" />

          {/* Outer Giant Pulsing Aura */}
          <circle
            cx="220"
            cy="6"
            r={isSuccess ? 22 : isError ? 16 : isConnecting ? 18 : 12}
            fill={isError ? "#ef4444" : isSuccess ? "#10b981" : isConnecting ? "#facc15" : "#38bdf8"}
            opacity={isSuccess ? "0.65" : "0.4"}
            filter="url(#beaconPulseGlow)"
          />

          {/* Primary High-Intensity Strobe Beacon */}
          <circle
            cx="220"
            cy="6"
            r={isSuccess ? 10 : 7}
            fill={beaconColor}
            filter="url(#beaconPulseGlow)"
            className="beacon-strobe"
          />

          {/* White-Hot Core Flash */}
          <circle
            cx="220"
            cy="6"
            r="4.5"
            fill="#ffffff"
            style={{ filter: "drop-shadow(0 0 12px #ffffff)" }}
          />
        </g>

        {/* ============================================================
            7. FAULT ELECTRICAL ARC & CIRCUIT TRIP (On Auth Failure)
           ============================================================ */}
        {isError && (
          <g id="fault-arcs">
            {/* Base Cabinet Short-Circuit Spark */}
            <circle cx="290" cy="655" r="16" fill="#ef4444" opacity="0.8" filter="url(#electricalSparkGlow)" />
            <path d="M 280 650 L 295 658 L 285 665 L 305 652" stroke="#fef08a" strokeWidth="3.5" fill="none" />

            {/* Mid-Tier Breaker Trip Burst */}
            <circle cx="220" cy="394" r="14" fill="#f97316" opacity="0.75" filter="url(#electricalSparkGlow)" />
            <path d="M 210 390 L 225 398 L 216 404 L 230 392" stroke="#ffffff" strokeWidth="3" fill="none" />
          </g>
        )}
      </svg>
    </div>
  );
};

export default TowerScene;
