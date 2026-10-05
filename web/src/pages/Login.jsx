import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import {
  Lock,
  Eye,
  EyeOff,
  Shield,
  Check,
  X,
  Loader2,
  AlertCircle,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import NormalTowerManScene from "../components/login/NormalTowerManScene";
import ConnectionBeam from "../components/login/ConnectionBeam";
import goaEmblem from "../assets/goa-emblem.png";

export const Login = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login, commitLogin } = useAuth();

  const [email, setEmail] = useState(location.state?.email || "");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);

  // Animation & Auth lifecycle state:
  // "idle" | "connecting" | "success" | "error"
  const [authStatus, setAuthStatus] = useState("idle");
  const [errorMessage, setErrorMessage] = useState(null);
  const [countdownSeconds, setCountdownSeconds] = useState(3);
  const [showForgotModal, setShowForgotModal] = useState(false);

  const from = location.state?.from?.pathname || "/dashboard";

  // Handle exactly 3 seconds of #00FF88 Green celebration before transitioning
  useEffect(() => {
    let timer;
    let interval;

    if (authStatus === "success") {
      setCountdownSeconds(3);

      interval = setInterval(() => {
        setCountdownSeconds((prev) => (prev > 1 ? prev - 1 : 1));
      }, 1000);

      // Exactly 3 seconds of green glow & countdown before navigation
      timer = setTimeout(() => {
        clearInterval(interval);
        commitLogin();
        navigate(from, { replace: true });
      }, 3000);

      return () => {
        if (interval) clearInterval(interval);
        if (timer) clearTimeout(timer);
      };
    }
  }, [authStatus, commitLogin, navigate, from]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email.trim() || !password) {
      setErrorMessage("Please enter your official Email / Username and Password.");
      setAuthStatus("error");
      return;
    }

    setAuthStatus("connecting");
    setErrorMessage(null);

    try {
      // Authenticate with deferred commit so 3-second green celebration displays completely
      await login({
        email: email.trim(),
        password,
        remember,
        deferCommit: true,
      });

      // Authentication Accepted -> Trigger #00FF88 Green Glow & 3-Second Countdown!
      setAuthStatus("success");
    } catch (err) {
      const serverMsg =
        err.response?.data?.message ||
        err.response?.data?.errors?.email?.[0] ||
        err.response?.data?.errors?.password?.[0] ||
        err.message ||
        "Authentication rejected. Please verify your email/username and password.";
      setErrorMessage(serverMsg);
      // Trigger #FF3B3B Red Glow & Failure Shake
      setAuthStatus("error");
    }
  };

  const handleInputChange = () => {
    if (authStatus === "error") {
      setAuthStatus("idle");
      setErrorMessage(null);
    }
  };

  return (
    <div className={`storyboard-login-page ${authStatus}`}>
      {/* Background Atmosphere */}
      <div className="login-cinematic-bg" />

      {/* Main Storyboard Grid Layout */}
      <div className="login-storyboard-container">
        {/* ========================================================
            LEFT COLUMN: BRANDING & NORMAL TOWER + MAN SCENE
           ======================================================== */}
        <div className="login-left-pane">
          {/* Government Branding Header (Pushed towards the left) */}
          <div className="login-branding-header">
            <h1 className="mtmms-brand-title">MTMMS</h1>
            <p className="mtmms-brand-subtitle">
              Mobile Tower Monitoring and Management System
            </p>

            {/* Official Government of Goa Emblem Badge (High Visibility) */}
            <div className="gov-emblem-badge-row">
              <div className="gov-emblem-container">
                <img
                  src={goaEmblem}
                  alt="Government of Goa Emblem"
                  className="gov-emblem-img"
                  onError={(e) => {
                    e.target.style.display = "none";
                  }}
                />
              </div>
              <div className="gov-title-text">
                <span className="dept-label">Department of Information Technology</span>
                <span className="gov-label">Government of Goa</span>
              </div>
            </div>
          </div>

          {/* Normal Telecom Tower Scene with Side-Walking Man */}
          <div className="cinematic-tower-wrapper">
            <NormalTowerManScene status={authStatus} />
          </div>
        </div>

        {/* ========================================================
            CENTER: DIRECTED CONNECTION BEAM (Real-time tracking apex to shield)
           ======================================================== */}
        <ConnectionBeam status={authStatus} />

        {/* ========================================================
            RIGHT COLUMN: SECURE NETWORK ACCESS LOGIN CARD (Big Size)
           ======================================================== */}
        <div className="login-right-pane">
          <div
            className={`storyboard-login-card ${
              authStatus === "success"
                ? "card-glow-success"
                : authStatus === "error"
                ? "card-glow-error"
                : authStatus === "connecting"
                ? "card-glow-connecting"
                : "card-glow-idle"
            }`}
          >
            {/* Top Shield Badge with Target ID for precise beam connection */}
            <div
              id="login-shield-badge"
              className={`shield-badge-container ${
                authStatus === "success"
                  ? "shield-success"
                  : authStatus === "error"
                  ? "shield-error"
                  : "shield-idle"
              }`}
            >
              {authStatus === "success" ? (
                <div className="success-check-circle">
                  <Check size={32} color="#020617" strokeWidth={3.5} />
                </div>
              ) : authStatus === "error" ? (
                <div className="error-x-circle">
                  <X size={32} color="#ffffff" strokeWidth={3.5} />
                </div>
              ) : (
                <div className="shield-icon-box">
                  <Shield size={30} className="shield-outline" />
                  <Lock size={15} className="shield-lock-core" />
                </div>
              )}
            </div>

            {/* Header Title */}
            <h2 className="secure-access-title">
              {authStatus === "success" ? "Access Authorized" : "Secure Network Access"}
            </h2>

            {/* Error Alert on Rejection */}
            {authStatus === "error" && errorMessage && (
              <div className="storyboard-error-alert">
                <AlertCircle size={18} style={{ flexShrink: 0 }} />
                <span>{errorMessage}</span>
              </div>
            )}

            {/* Login Form */}
            <form onSubmit={handleSubmit} className="storyboard-form">
              <div className="storyboard-form-group">
                <label className="storyboard-label">Email / Username</label>
                <input
                  type="text"
                  className="storyboard-input"
                  placeholder="Enter official email or username"
                  value={email}
                  onChange={(e) => {
                    setEmail(e.target.value);
                    handleInputChange();
                  }}
                  autoComplete="username"
                  required
                  disabled={authStatus === "success"}
                />
              </div>

              <div className="storyboard-form-group">
                <label className="storyboard-label">Password</label>
                <div className="storyboard-password-wrapper">
                  <input
                    type={showPassword ? "text" : "password"}
                    className="storyboard-input password-input"
                    placeholder="Enter password"
                    value={password}
                    onChange={(e) => {
                      setPassword(e.target.value);
                      handleInputChange();
                    }}
                    autoComplete="current-password"
                    required
                    disabled={authStatus === "success"}
                  />
                  <button
                    type="button"
                    className="storyboard-eye-btn"
                    onClick={() => setShowPassword(!showPassword)}
                    tabIndex={-1}
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              <div className="storyboard-options-row">
                <label className="storyboard-checkbox-label">
                  <input
                    type="checkbox"
                    checked={remember}
                    onChange={(e) => setRemember(e.target.checked)}
                    className="storyboard-checkbox"
                    disabled={authStatus === "success"}
                  />
                  <span>Remember me</span>
                </label>

                <button
                  type="button"
                  className="forgot-password-link"
                  onClick={() => setShowForgotModal(true)}
                >
                  Forgot Password?
                </button>
              </div>

              <button
                type="submit"
                className={`storyboard-submit-btn ${
                  authStatus === "success"
                    ? "btn-state-success"
                    : authStatus === "error"
                    ? "btn-state-error"
                    : authStatus === "connecting"
                    ? "btn-state-connecting"
                    : ""
                }`}
                disabled={authStatus === "connecting" || authStatus === "success"}
              >
                {authStatus === "connecting" ? (
                  <span className="btn-flex-center">
                    <Loader2 size={20} className="animate-spin" />
                    <span>Verifying Credentials...</span>
                  </span>
                ) : authStatus === "success" ? (
                  <span className="btn-flex-center">
                    <Check size={20} />
                    <span>Authenticated • Redirecting...</span>
                  </span>
                ) : (
                  <span>Sign In</span>
                )}
              </button>
            </form>

            {/* 3-Second Success Progress Ring (Visible during Success State) */}
            {authStatus === "success" && (
              <div className="countdown-timer-badge">
                <div className="countdown-ring-wrapper">
                  <svg className="countdown-ring-svg" viewBox="0 0 40 40">
                    <circle cx="20" cy="20" r="16" className="ring-track" />
                    <circle cx="20" cy="20" r="16" className="ring-progress" />
                  </svg>
                  <span className="countdown-number">{countdownSeconds}</span>
                </div>
                <span className="countdown-label">SECONDS TO DASHBOARD</span>
              </div>
            )}

            {/* Official System Footer */}
            <div className="storyboard-card-footer">
              MTMMS - Secure. Monitor. Manage.
            </div>
          </div>
        </div>
      </div>

      {/* Forgot Password Modal */}
      {showForgotModal && (
        <div className="modal-backdrop" onClick={() => setShowForgotModal(false)}>
          <div
            className="modal-content"
            style={{ maxWidth: 440 }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <h3 style={{ fontSize: "1.1rem" }}>Official Password Recovery</h3>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setShowForgotModal(false)}
              >
                <X size={16} />
              </button>
            </div>
            <div className="modal-body" style={{ fontSize: "0.88rem", color: "var(--text-secondary)" }}>
              <p style={{ marginBottom: 12 }}>
                Password resets for MTMMS authorized officers are managed directly through the <strong>Department of Information Technology, Government of Goa</strong> nodal security directory.
              </p>
              <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)", marginBottom: 14 }}>
                <strong>Default System Administrator:</strong>
                <div style={{ color: "var(--accent-cyan)", marginTop: 4 }}>Email: <code>admin@goa.gov.in</code></div>
                <div style={{ color: "var(--text-primary)", marginTop: 2 }}>Password: <code>Admin@1234</code></div>
              </div>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                For credential reassignment, contact the DoIT Goa Systems Helpdesk at <span style={{ color: "var(--text-primary)" }}>helpdesk-doit@goa.gov.in</span>.
              </p>
            </div>
            <div className="modal-footer">
              <button
                className="btn btn-primary"
                onClick={() => {
                  setEmail("admin@goa.gov.in");
                  setPassword("Admin@1234");
                  setShowForgotModal(false);
                }}
              >
                Auto-fill Admin Credentials
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Login;
