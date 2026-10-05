import React from "react";

export const NormalTowerManScene = ({
  status = "idle", // "idle" | "connecting" | "success" | "error"
}) => {
  const isSuccess = status === "success";
  const isError = status === "error";
  const isConnecting = status === "connecting";

  // Exact Storyboard Colors:
  // Success: #00FF88 (Green)
  // Failure: #FF3B3B (Red)
  // Default: #FF5100 / #FF7700 (Solar Orange)
  const themeColor = isSuccess
    ? "#00FF88"
    : isError
    ? "#FF3B3B"
    : isConnecting
    ? "#FF7700"
    : "#FF5100";

  return (
    <div className={`normal-tower-scene-root ${status}`}>
      <svg
        id="normal-tower-svg-element"
        className="normal-tower-svg"
        viewBox="0 0 520 620"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid meet"
      >
        <defs>
          {/* Gradients */}
          <linearGradient id="normalTowerGrad" x1="0%" y1="100%" x2="0%" y2="0%">
            <stop offset="0%" stopColor={themeColor} stopOpacity="0.25" />
            <stop offset="60%" stopColor={themeColor} stopOpacity="0.95" />
            <stop offset="100%" stopColor="#ffffff" stopOpacity="1" />
          </linearGradient>

          <filter id="normalGlowFilter" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation={isSuccess ? "7" : isError ? "6" : "4"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* ============================================================
            1. GROUND PLATFORM & FOUNDATION (Slightly larger foundation)
           ============================================================ */}
        {/* Extended Ground Baseline Track for Walking Officer from Left Mark */}
        <line x1="-260" y1="575" x2="510" y2="575" stroke="rgba(255, 81, 0, 0.22)" strokeWidth="1.2" strokeDasharray="6 4" />
        <ellipse cx="-240" cy="575" rx="20" ry="4" fill="rgba(255, 81, 0, 0.18)" />

        <ellipse cx="290" cy="562" rx="225" ry="26" fill="#e2e8f0" />
        <ellipse cx="290" cy="562" rx="180" ry="18" stroke="rgba(15, 23, 42, 0.08)" strokeWidth="1.2" />
        <ellipse cx="290" cy="562" rx="135" ry="14" stroke={themeColor} strokeWidth="1.8" opacity="0.35" />

        {/* Concrete Foundation Plinth */}
        <path d="M 170 550 L 410 550 L 426 570 L 154 570 Z" fill="#1e293b" stroke="#334155" strokeWidth="1.8" />
        <line x1="170" y1="550" x2="410" y2="550" stroke="#475569" strokeWidth="2.5" />

        {/* Base BTS Telecom Equipment Shelter (Slightly bigger with crisp details) */}
        <rect x="330" y="480" width="68" height="70" rx="4" fill="#0f172a" stroke="#334155" strokeWidth="1.8" />
        <line x1="364" y1="482" x2="364" y2="548" stroke="#1e293b" strokeWidth="1.5" />
        {/* BTS Ventilation Louvers */}
        <line x1="338" y1="518" x2="356" y2="518" stroke="#334155" strokeWidth="1.5" />
        <line x1="338" y1="524" x2="356" y2="524" stroke="#334155" strokeWidth="1.5" />
        <line x1="338" y1="530" x2="356" y2="530" stroke="#334155" strokeWidth="1.5" />
        {/* Status Indicators */}
        <circle cx="344" cy="492" r="2.5" fill={themeColor} filter="url(#normalGlowFilter)" />
        <circle cx="353" cy="492" r="2.5" fill={themeColor} />
        <circle cx="376" cy="492" r="2.5" fill={isError ? "#FF3B3B" : "#10b981"} />

        {/* Base Feeder Conduit to Tower */}
        <path d="M 330 515 Q 310 530, 290 545" stroke={themeColor} strokeWidth="2.5" fill="none" strokeDasharray="5 3" />

        {/* ============================================================
            2. NORMAL TELECOM TOWER & BIGGER COMPONENTS (Centered at X = 290)
           ============================================================ */}
        <g id="vector-tower-lattice" filter={isSuccess || isError ? "url(#normalGlowFilter)" : undefined}>
          {/* Main Corner Structural Steel Legs (Broader stance: 205/375 at base to 281/299 at apex) */}
          <line x1="205" y1="550" x2="281" y2="85" stroke="#64748b" strokeWidth="4" strokeLinecap="round" />
          <line x1="375" y1="550" x2="299" y2="85" stroke="#64748b" strokeWidth="4" strokeLinecap="round" />

          {/* Central Power Waveguide Conduit (Glowing Center Line) */}
          <line
            x1="290"
            y1="30"
            x2="290"
            y2="550"
            stroke="url(#normalTowerGrad)"
            strokeWidth={isSuccess ? "4" : isError ? "3.5" : "2.5"}
            className="vector-tower-spine"
          />

          {/* Horizontal Lattice Crossbeams & X-Bracing */}
          {/* Tier 6 (Base) */}
          <line x1="205" y1="550" x2="375" y2="550" stroke="#475569" strokeWidth="3" />
          <line x1="220" y1="460" x2="360" y2="460" stroke="#475569" strokeWidth="2.5" />
          <line x1="205" y1="550" x2="360" y2="460" stroke="#334155" strokeWidth="1.8" />
          <line x1="375" y1="550" x2="220" y2="460" stroke="#334155" strokeWidth="1.8" />

          {/* Tier 5 */}
          <line x1="234" y1="370" x2="346" y2="370" stroke="#475569" strokeWidth="2.5" />
          <line x1="220" y1="460" x2="346" y2="370" stroke="#334155" strokeWidth="1.6" />
          <line x1="360" y1="460" x2="234" y2="370" stroke="#334155" strokeWidth="1.6" />

          {/* Tier 4 (Mid-Platform Level with Red Aviation Strobes) */}
          <line x1="245" y1="280" x2="335" y2="280" stroke="#94a3b8" strokeWidth="3" />
          <line x1="247" y1="272" x2="333" y2="272" stroke="#475569" strokeWidth="1.5" />
          <line x1="234" y1="370" x2="331" y2="280" stroke="#334155" strokeWidth="1.6" />
          <line x1="346" y1="370" x2="249" y2="280" stroke="#334155" strokeWidth="1.6" />
          {/* Mid-tier Red Obstruction Beacons */}
          <circle cx="245" cy="280" r="4" fill="#FF3B3B" className="vector-aviation-blink" />
          <circle cx="335" cy="280" r="4" fill="#FF3B3B" className="vector-aviation-blink" />

          {/* Tier 3 */}
          <line x1="264" y1="190" x2="316" y2="190" stroke="#475569" strokeWidth="2.2" />
          <line x1="249" y1="280" x2="316" y2="190" stroke="#334155" strokeWidth="1.5" />
          <line x1="331" y1="280" x2="264" y2="190" stroke="#334155" strokeWidth="1.5" />

          {/* Tier 2 */}
          <line x1="275" y1="120" x2="305" y2="120" stroke="#475569" strokeWidth="2" />
          <line x1="264" y1="190" x2="305" y2="120" stroke="#334155" strokeWidth="1.4" />
          <line x1="316" y1="190" x2="275" y2="120" stroke="#334155" strokeWidth="1.4" />

          {/* Tier 1 (Apex Mount) */}
          <line x1="281" y1="85" x2="299" y2="85" stroke="#94a3b8" strokeWidth="2.5" />
          <line x1="275" y1="120" x2="299" y2="85" stroke="#334155" strokeWidth="1.4" />
          <line x1="305" y1="120" x2="281" y2="85" stroke="#334155" strokeWidth="1.4" />

          {/* Microwave Parabolic Dish (Left - Enlarged) */}
          <ellipse cx="242" cy="225" rx="16" ry="16" fill="#0f172a" stroke="#64748b" strokeWidth="2" />
          <ellipse cx="242" cy="225" rx="11" ry="11" stroke="#334155" strokeWidth="1.2" />
          <circle cx="242" cy="225" r="4.5" fill={themeColor} filter="url(#normalGlowFilter)" />
          <line x1="258" y1="225" x2="272" y2="225" stroke="#64748b" strokeWidth="2.5" />

          {/* Microwave Parabolic Dish (Right - Enlarged) */}
          <ellipse cx="336" cy="155" rx="14" ry="14" fill="#0f172a" stroke="#64748b" strokeWidth="2" />
          <ellipse cx="336" cy="155" rx="9" ry="9" stroke="#334155" strokeWidth="1.2" />
          <circle cx="336" cy="155" r="4" fill={themeColor} filter="url(#normalGlowFilter)" />
          <line x1="322" y1="155" x2="308" y2="155" stroke="#64748b" strokeWidth="2.5" />

          {/* Secondary Sector Dish (Lower Left Tier 5) */}
          <ellipse cx="226" cy="340" rx="12" ry="12" fill="#0f172a" stroke="#64748b" strokeWidth="1.8" />
          <circle cx="226" cy="340" r="3.5" fill={themeColor} />
          <line x1="238" y1="340" x2="248" y2="340" stroke="#64748b" strokeWidth="2" />

          {/* Apex 5G MIMO Active Antenna Arrays (Bigger & Crisp) */}
          <rect x="264" y="38" width="12" height="52" rx="2.5" fill="#0f172a" stroke={themeColor} strokeWidth="1.8" />
          <line x1="270" y1="44" x2="270" y2="84" stroke={themeColor} strokeWidth="2.2" strokeLinecap="round" />

          <rect x="283" y="30" width="14" height="60" rx="3" fill="#0f172a" stroke={themeColor} strokeWidth="2.2" />
          <line x1="290" y1="37" x2="290" y2="84" stroke={themeColor} strokeWidth="2.8" strokeLinecap="round" />

          <rect x="304" y="38" width="12" height="52" rx="2.5" fill="#0f172a" stroke={themeColor} strokeWidth="1.8" />
          <line x1="310" y1="44" x2="310" y2="84" stroke={themeColor} strokeWidth="2.2" strokeLinecap="round" />

          {/* Top Apex Point: Lightning Mast & Strobe Beacon (At X=290, Y=10) */}
          <line x1="290" y1="30" x2="290" y2="10" stroke="#e2e8f0" strokeWidth="3" strokeLinecap="round" />
          {/* Dedicated Apex Target Element for Connection Beam Connection */}
          <circle
            id="tower-apex-tip"
            cx="290"
            cy="10"
            r={isSuccess ? "10" : "8"}
            fill={themeColor}
            filter="url(#normalGlowFilter)"
            className="vector-apex-strobe"
          />
          <circle cx="290" cy="10" r="4" fill="#ffffff" />
        </g>

        {/* Radio Broadcast Waves radiating from Apex Top Point (Bigger and wider arcs) */}
        <g id="apex-radio-waves" transform="translate(290, 10)">
          {/* Right side waves */}
          <path d="M 22 -22 A 32 32 0 0 1 22 22" stroke={themeColor} strokeWidth="3" strokeLinecap="round" fill="none" opacity="0.9" className="vector-rf-arc arc-1" />
          <path d="M 38 -38 A 54 54 0 0 1 38 38" stroke={themeColor} strokeWidth="3" strokeLinecap="round" fill="none" opacity="0.7" className="vector-rf-arc arc-2" />
          <path d="M 54 -54 A 76 76 0 0 1 54 54" stroke={themeColor} strokeWidth="2.5" strokeLinecap="round" fill="none" opacity="0.45" className="vector-rf-arc arc-3" />

          {/* Left side waves */}
          <path d="M -22 -22 A 32 32 0 0 0 -22 22" stroke={themeColor} strokeWidth="3" strokeLinecap="round" fill="none" opacity="0.9" className="vector-rf-arc arc-1" />
          <path d="M -38 -38 A 54 54 0 0 0 -38 38" stroke={themeColor} strokeWidth="3" strokeLinecap="round" fill="none" opacity="0.7" className="vector-rf-arc arc-2" />
          <path d="M -54 -54 A 76 76 0 0 0 -54 54" stroke={themeColor} strokeWidth="2.5" strokeLinecap="round" fill="none" opacity="0.45" className="vector-rf-arc arc-3" />
        </g>

        {/* ============================================================
            3. FIELD OFFICER / MAN (Slightly bigger figure with animated walking)
               Profile/3-quarter side view approaching the tower base
           ============================================================ */}
        <g id="man-scale-wrapper" transform="translate(130, 575) scale(1.22) translate(-130, -575)">
          <g id="side-walking-man" className="side-walking-man-figure">
            {/* Man Ground Shadow */}
            <ellipse cx="135" cy="580" rx="32" ry="7" fill="rgba(0,0,0,0.7)" />

            {/* Back Leg (Right leg trailing in walk cycle) */}
            <path
              d="M 126 495 L 110 538 L 98 578 L 114 578 L 123 540 Z"
              fill="#0f172a"
              stroke="#020617"
              strokeWidth="1.2"
              className="man-side-leg-back"
            />

            {/* Front Leg (Left leg stepping forward toward tower) */}
            <path
              d="M 132 495 L 148 536 L 162 578 L 146 578 L 137 540 Z"
              fill="#1e293b"
              stroke="#020617"
              strokeWidth="1.2"
              className="man-side-leg-front"
            />

            {/* Boots */}
            <rect x="96" y="573" width="20" height="7" rx="2" fill="#334155" />
            <rect x="146" y="573" width="20" height="7" rx="2" fill="#334155" />

            {/* Torso & Field Jacket in Side Profile */}
            <path
              d="M 115 422 C 110 446, 112 490, 118 500 L 146 500 C 152 490, 156 446, 150 422 Z"
              fill="#1e293b"
              stroke="#0f172a"
              strokeWidth="2"
            />

            {/* Hi-Vis Safety Vest Overlay in Side View */}
            <path
              d="M 117 426 L 148 426 L 145 492 L 120 492 Z"
              fill={isError ? "#7f1d1d" : isSuccess ? "#047857" : "#0369a1"}
            />
            <line x1="118" y1="452" x2="147" y2="452" stroke={themeColor} strokeWidth="3" />
            <line x1="120" y1="472" x2="145" y2="472" stroke={themeColor} strokeWidth="3" />

            {/* Trailing Arm (Swinging back) */}
            <path
              d="M 120 428 L 106 460 L 102 485"
              stroke="#1e293b"
              strokeWidth="8"
              strokeLinecap="round"
              className="man-side-arm-back"
            />

            {/* Leading Arm (Holding diagnostic device forward toward tower) */}
            <path
              d="M 142 428 L 160 458 L 178 466"
              stroke="#1e293b"
              strokeWidth="8"
              strokeLinecap="round"
              className="man-side-arm-front"
            />

            {/* Diagnostic Tablet held forward */}
            <rect x="175" y="454" width="16" height="24" rx="3" fill="#0f172a" stroke={themeColor} strokeWidth="2" />
            <circle cx="183" cy="466" r="3.5" fill={themeColor} filter="url(#normalGlowFilter)" />
            <line x1="178" y1="473" x2="188" y2="473" stroke={themeColor} strokeWidth="1.5" />

            {/* Head & Safety Helmet in Profile (Facing Right toward Tower) */}
            <circle cx="135" cy="402" r="14" fill="#1e293b" />
            {/* Safety Helmet */}
            <path d="M 121 400 C 121 384, 151 384, 151 400 Z" fill="#f59e0b" stroke="#b45309" strokeWidth="1.8" />
            <rect x="119" y="398" width="34" height="4.5" rx="2" fill="#f59e0b" />
            {/* Helmet Headlamp projecting light beam forward to tower */}
            <rect x="150" y="395" width="6" height="6" rx="2" fill={themeColor} filter="url(#normalGlowFilter)" />
            <polygon points="156,398 225,380 225,420" fill={themeColor} opacity="0.18" />
          </g>
        </g>
      </svg>
    </div>
  );
};

export default NormalTowerManScene;

