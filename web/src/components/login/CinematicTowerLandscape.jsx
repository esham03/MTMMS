import React from "react";
import towerManHero from "../../assets/cinematic_tower_man.jpg";

export const CinematicTowerLandscape = ({
  status = "idle", // "idle" | "connecting" | "success" | "error"
}) => {
  const isSuccess = status === "success";
  const isError = status === "error";
  const isConnecting = status === "connecting";

  // Storyboard Theme Colors:
  // Success: #00FF88 (Green)
  // Failure: #FF3B3B (Red)
  // Default: #00D2FF (Cyan)
  const primaryColor = isSuccess
    ? "#00FF88"
    : isError
    ? "#FF3B3B"
    : isConnecting
    ? "#38BDF8"
    : "#00D2FF";

  return (
    <div className={`cinematic-landscape-container ${status}`}>
      {/* 1. Photorealistic Cinematic Background Image */}
      <img
        src={towerManHero}
        alt="MTMMS Mobile Tower and Field Engineer"
        className="cinematic-hero-img"
      />

      {/* 2. Dynamic Atmosphere Glow Tint */}
      <div
        className="dynamic-atmosphere-overlay"
        style={{
          background: isSuccess
            ? "radial-gradient(ellipse at 60% 40%, rgba(0, 255, 136, 0.35) 0%, rgba(0, 255, 136, 0.1) 45%, transparent 75%)"
            : isError
            ? "radial-gradient(ellipse at 60% 40%, rgba(255, 59, 59, 0.35) 0%, rgba(255, 59, 59, 0.1) 45%, transparent 75%)"
            : isConnecting
            ? "radial-gradient(ellipse at 60% 40%, rgba(56, 189, 248, 0.3) 0%, transparent 65%)"
            : "radial-gradient(ellipse at 60% 40%, rgba(0, 210, 255, 0.2) 0%, transparent 60%)",
        }}
      />

      {/* 3. Interactive SVG Layer: Radio Waves, Aviation Strobes, & Energy Surge */}
      <svg
        className="overlay-svg-layer"
        viewBox="0 0 1000 600"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid slice"
      >
        <defs>
          <filter id="heroAuraFilter" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation={isSuccess ? "8" : isError ? "7" : "5"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Radio Broadcast Waves Radiating from Tower Apex (Coordinates align with mast top ~[600, 75]) */}
        <g id="apex-radio-arcs" transform="translate(600, 75)">
          <path
            d="M 22 -22 A 32 32 0 0 1 22 22"
            stroke={primaryColor}
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
            opacity="0.9"
            className="rf-hero-arc arc-1"
            filter="url(#heroAuraFilter)"
          />
          <path
            d="M 40 -40 A 58 58 0 0 1 40 40"
            stroke={primaryColor}
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
            opacity="0.7"
            className="rf-hero-arc arc-2"
            filter="url(#heroAuraFilter)"
          />
          <path
            d="M 58 -58 A 84 84 0 0 1 58 58"
            stroke={primaryColor}
            strokeWidth="2.5"
            strokeLinecap="round"
            fill="none"
            opacity="0.5"
            className="rf-hero-arc arc-3"
            filter="url(#heroAuraFilter)"
          />

          {/* Left-side symmetrical arcs */}
          <path
            d="M -22 -22 A 32 32 0 0 0 -22 22"
            stroke={primaryColor}
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
            opacity="0.9"
            className="rf-hero-arc arc-1"
            filter="url(#heroAuraFilter)"
          />
          <path
            d="M -40 -40 A 58 58 0 0 0 -40 40"
            stroke={primaryColor}
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
            opacity="0.7"
            className="rf-hero-arc arc-2"
            filter="url(#heroAuraFilter)"
          />
          <path
            d="M -58 -58 A 84 84 0 0 0 -58 58"
            stroke={primaryColor}
            strokeWidth="2.5"
            strokeLinecap="round"
            fill="none"
            opacity="0.5"
            className="rf-hero-arc arc-3"
            filter="url(#heroAuraFilter)"
          />
        </g>

        {/* Apex Aviation Strobe Beacons */}
        <circle
          cx="600"
          cy="75"
          r={isSuccess ? "10" : "7"}
          fill={primaryColor}
          filter="url(#heroAuraFilter)"
          className="hero-apex-strobe"
        />
        <circle cx="600" cy="75" r="4" fill="#ffffff" />

        {/* Tower Left Mast Strobe */}
        <circle
          cx="515"
          cy="95"
          r="6"
          fill={primaryColor}
          filter="url(#heroAuraFilter)"
          className="hero-apex-strobe"
        />
        <circle cx="515" cy="95" r="3" fill="#ffffff" />

        {/* Tower Mid-Tier Red Obstruction Lights */}
        <circle cx="518" cy="225" r="4" fill="#FF3B3B" className="hero-aviation-blink" />
        <circle cx="602" cy="205" r="4" fill="#FF3B3B" className="hero-aviation-blink" />

        {/* Upward Volumetric Lighting Pulse on Tower Spine */}
        <line
          x1="600"
          y1="75"
          x2="600"
          y2="340"
          stroke={primaryColor}
          strokeWidth={isSuccess ? "5" : isError ? "4" : "3"}
          strokeLinecap="round"
          opacity={isSuccess ? "0.85" : isError ? "0.75" : "0.55"}
          className="tower-spine-stream"
          filter="url(#heroAuraFilter)"
        />
      </svg>
    </div>
  );
};

export default CinematicTowerLandscape;
