import React, { useState, useEffect, useCallback } from "react";

export const ConnectionBeam = ({
  status = "idle", // "idle" | "connecting" | "success" | "error"
}) => {
  const [coords, setCoords] = useState(null);

  const isSuccess = status === "success";
  const isError = status === "error";
  const isConnecting = status === "connecting";

  // Storyboard Theme Colors:
  // Success: #00FF88 (Green)
  // Failure: #FF3B3B (Red)
  // Default: #FF5100 (Solar Orange)
  const beamColor = isSuccess
    ? "#00FF88"
    : isError
    ? "#FF3B3B"
    : isConnecting
    ? "#FF7700"
    : "#FF5100";

  const updateCoordinates = useCallback(() => {
    const svgElement = document.getElementById("normal-tower-svg-element");
    const shieldElement = document.getElementById("login-shield-badge");

    if (svgElement && shieldElement) {
      try {
        // Native SVG Matrix Transform: map (290, 10) to exact client screen pixels
        const ctm = svgElement.getScreenCTM();
        if (ctm) {
          const pt = svgElement.createSVGPoint();
          pt.x = 290; // Exact center of mast apex
          pt.y = 10;  // Exact top tip of beacon
          const screenApex = pt.matrixTransform(ctm);

          const shieldRect = shieldElement.getBoundingClientRect();

          setCoords({
            x1: screenApex.x,
            y1: screenApex.y,
            x2: shieldRect.left + 4,
            y2: shieldRect.top + shieldRect.height / 2,
          });
          return;
        }
      } catch {
        // Fallback to bounding client rect if matrix transform fails
      }

      const apexElement = document.getElementById("tower-apex-tip");
      if (apexElement) {
        const apexRect = apexElement.getBoundingClientRect();
        const shieldRect = shieldElement.getBoundingClientRect();
        setCoords({
          x1: apexRect.left + apexRect.width / 2,
          y1: apexRect.top + apexRect.height / 2,
          x2: shieldRect.left + 4,
          y2: shieldRect.top + shieldRect.height / 2,
        });
      }
    }
  }, []);

  useEffect(() => {
    if (status === "idle") return;

    updateCoordinates();

    const handleResize = () => updateCoordinates();
    window.addEventListener("resize", handleResize);
    window.addEventListener("scroll", handleResize);

    const t1 = setTimeout(updateCoordinates, 30);
    const t2 = setTimeout(updateCoordinates, 150);
    const t3 = setTimeout(updateCoordinates, 400);

    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("scroll", handleResize);
      clearTimeout(t1);
      clearTimeout(t2);
      clearTimeout(t3);
    };
  }, [status, updateCoordinates]);

  if (status === "idle" || !coords) return null;

  const { x1, y1, x2, y2 } = coords;
  // Graceful arching curve above the scene
  const cx = (x1 + x2) / 2;
  const cy = Math.min(y1, y2) - 40;
  const pathD = `M ${x1} ${y1} Q ${cx} ${cy}, ${x2} ${y2}`;

  return (
    <div className={`connection-beam-fixed-layer ${status}`}>
      <svg
        className="connection-beam-fullscreen-svg"
        viewBox={`0 0 ${window.innerWidth || 1920} ${window.innerHeight || 1080}`}
        fill="none"
      >
        <defs>
          <linearGradient id="liveApexBeamGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
            <stop offset="15%" stopColor={beamColor} stopOpacity="1" />
            <stop offset="85%" stopColor={beamColor} stopOpacity="0.95" />
            <stop
              offset="100%"
              stopColor={isSuccess ? "#6ee7b7" : isError ? "#f87171" : "#ff7700"}
              stopOpacity="1"
            />
          </linearGradient>

          <filter id="liveApexAura" x="-20%" y="-50%" width="140%" height="200%">
            <feGaussianBlur stdDeviation={isSuccess ? "8" : isError ? "6" : "5"} result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Originating Pulse at the EXACT Center of the Tower Apex Top Tip */}
        <circle
          cx={x1}
          cy={y1}
          r={isSuccess ? "12" : "9"}
          fill={beamColor}
          filter="url(#liveApexAura)"
          opacity="0.9"
        />
        <circle cx={x1} cy={y1} r="4" fill="#ffffff" />

        {/* Outer Radiant Glow Path */}
        <path
          d={pathD}
          stroke={beamColor}
          strokeWidth={isSuccess ? "12" : isConnecting ? "9" : "6"}
          opacity={isSuccess ? "0.65" : isError ? "0.6" : "0.45"}
          strokeLinecap="round"
          filter="url(#liveApexAura)"
        />

        {/* Core Electric Beam Stream */}
        <path
          d={pathD}
          stroke="url(#liveApexBeamGrad)"
          strokeWidth={isSuccess ? "5" : isConnecting ? "4" : "3"}
          strokeDasharray={isError ? "8 8" : isSuccess ? "20 4" : "14 4"}
          className={isError ? "beam-severed-pulse" : "beam-data-flow"}
          strokeLinecap="round"
        />

        {/* Destination Arrival Impact Spark on Left Edge of Shield Badge */}
        <circle
          cx={x2}
          cy={y2}
          r={isSuccess ? "10" : "7"}
          fill={beamColor}
          filter="url(#liveApexAura)"
          opacity="0.85"
        />
      </svg>
    </div>
  );
};

export default ConnectionBeam;
