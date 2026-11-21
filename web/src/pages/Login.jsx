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
  KeyRound,
  ArrowLeft,
  RefreshCw,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import api from "../api/api";
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

  // Password Recovery Multi-step States (Zero-Cost Local Simulation)
  const [forgotStep, setForgotStep] = useState(1); // 1: Email, 2: OTP & New Password, 3: Success
  const [forgotEmail, setForgotEmail] = useState("");
  const [forgotOtp, setForgotOtp] = useState("");
  const [forgotNewPassword, setForgotNewPassword] = useState("");
  const [forgotConfirmPassword, setForgotConfirmPassword] = useState("");
  const [forgotShowNewPass, setForgotShowNewPass] = useState(false);
  const [forgotOtpPreview, setForgotOtpPreview] = useState("");
  const [forgotLoading, setForgotLoading] = useState(false);
  const [forgotError, setForgotError] = useState(null);
  const [forgotSuccessMsg, setForgotSuccessMsg] = useState(null);
  const [forgotCountdown, setForgotCountdown] = useState(300);

  // OTP Countdown timer for Step 2
  useEffect(() => {
    let timer;
    if (showForgotModal && forgotStep === 2 && forgotCountdown > 0) {
      timer = setInterval(() => {
        setForgotCountdown((prev) => (prev > 0 ? prev - 1 : 0));
      }, 1000);
    }
    return () => {
      if (timer) clearInterval(timer);
    };
  }, [showForgotModal, forgotStep, forgotCountdown]);

  const handleOpenForgotModal = () => {
    setForgotStep(1);
    setForgotEmail(email || "");
    setForgotOtp("");
    setForgotNewPassword("");
    setForgotConfirmPassword("");
    setForgotError(null);
    setForgotSuccessMsg(null);
    setShowForgotModal(true);
  };

  const handleRequestOtp = async (e) => {
    if (e) e.preventDefault();
    if (!forgotEmail.trim()) {
      setForgotError("Please enter your registered official email address.");
      return;
    }
    setForgotLoading(true);
    setForgotError(null);
    try {
      const res = await api.post("/auth/forgot-password/request-otp", {
        email: forgotEmail.trim(),
      });
      setForgotOtpPreview(res.data.otp_preview || "");
      setForgotCountdown(300);
      setForgotStep(2);
    } catch (err) {
      const msg =
        err.response?.data?.errors?.email?.[0] ||
        err.response?.data?.message ||
        "Failed to request verification code. Please check your email.";
      setForgotError(msg);
    } finally {
      setForgotLoading(false);
    }
  };

  const handleVerifyAndReset = async (e) => {
    if (e) e.preventDefault();
    if (!forgotOtp.trim()) {
      setForgotError("Please enter the 6-digit OTP verification code.");
      return;
    }
    if (!forgotNewPassword) {
      setForgotError("Please enter a new password.");
      return;
    }
    if (forgotNewPassword.length < 6) {
      setForgotError("New password must be at least 6 characters long.");
      return;
    }
    if (forgotNewPassword !== forgotConfirmPassword) {
      setForgotError("Passwords do not match. Please re-enter.");
      return;
    }

    setForgotLoading(true);
    setForgotError(null);
    try {
      const res = await api.post("/auth/forgot-password/verify-reset", {
        email: forgotEmail.trim(),
        otp: forgotOtp.trim(),
        new_password: forgotNewPassword,
      });
      setForgotSuccessMsg(res.data.message || "Password updated successfully!");
      setForgotStep(3);
      // Pre-fill login inputs with the newly updated credentials
      setEmail(forgotEmail.trim());
      setPassword(forgotNewPassword);
    } catch (err) {
      const msg =
        err.response?.data?.errors?.otp?.[0] ||
        err.response?.data?.errors?.new_password?.[0] ||
        err.response?.data?.message ||
        "Verification failed. Please check the OTP and try again.";
      setForgotError(msg);
    } finally {
      setForgotLoading(false);
    }
  };

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
                  onClick={handleOpenForgotModal}
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

      {/* 100% Free In-App Password Recovery Modal */}
      {showForgotModal && (
        <div className="modal-backdrop" onClick={() => setShowForgotModal(false)}>
          <div
            className="modal-content"
            style={{ maxWidth: 460 }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <KeyRound size={18} color="var(--primary-color, #f97316)" />
                <h3 style={{ fontSize: "1.05rem", margin: 0 }}>Official Password Recovery</h3>
              </div>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setShowForgotModal(false)}
                aria-label="Close"
              >
                <X size={16} />
              </button>
            </div>

            {/* STEP 1: Enter Registered Email */}
            {forgotStep === 1 && (
              <form onSubmit={handleRequestOtp}>
                <div className="modal-body" style={{ fontSize: "0.88rem", color: "var(--text-secondary)" }}>
                  <p style={{ marginBottom: 16, lineHeight: 1.5 }}>
                    Enter your registered government email address to receive an official 6-digit verification code.
                  </p>

                  <div className="storyboard-form-group" style={{ marginBottom: 12 }}>
                    <label className="storyboard-label" style={{ fontWeight: 600 }}>
                      Official Email Address
                    </label>
                    <input
                      type="email"
                      className="storyboard-input"
                      placeholder="e.g. admin@goa.gov.in"
                      value={forgotEmail}
                      onChange={(e) => {
                        setForgotEmail(e.target.value);
                        setForgotError(null);
                      }}
                      required
                      autoFocus
                    />
                  </div>

                  {forgotError && (
                    <div className="storyboard-error-alert" style={{ marginTop: 10, marginBottom: 10 }}>
                      <AlertCircle size={16} style={{ flexShrink: 0 }} />
                      <span>{forgotError}</span>
                    </div>
                  )}

                  <div style={{
                    background: "var(--bg-surface-elevated)",
                    padding: "10px 12px",
                    borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border-color)",
                    fontSize: "0.8rem",
                    color: "var(--text-muted)",
                    marginTop: 12
                  }}>
                    🔒 <strong>Self-Contained Verification:</strong> Operates 100% locally with zero paid third-party dependencies or external mail gateways.
                  </div>
                </div>

                <div className="modal-footer" style={{ display: "flex", justifyContent: "space-between" }}>
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => setShowForgotModal(false)}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="btn btn-primary"
                    disabled={forgotLoading}
                  >
                    {forgotLoading ? (
                      <span className="btn-flex-center">
                        <Loader2 size={16} className="animate-spin" />
                        <span>Generating Code...</span>
                      </span>
                    ) : (
                      <span>Generate Verification OTP</span>
                    )}
                  </button>
                </div>
              </form>
            )}

            {/* STEP 2: Enter OTP & Set New Password */}
            {forgotStep === 2 && (
              <form onSubmit={handleVerifyAndReset}>
                <div className="modal-body" style={{ fontSize: "0.88rem", color: "var(--text-secondary)" }}>
                  {/* Local Dispatch Simulation Banner */}
                  <div style={{
                    background: "rgba(14, 165, 233, 0.08)",
                    border: "1px solid rgba(14, 165, 233, 0.3)",
                    borderRadius: "var(--radius-md)",
                    padding: "12px 14px",
                    marginBottom: 16
                  }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#0284c7", letterSpacing: "0.5px" }}>
                        OFFICIAL OTP DISPATCH
                      </span>
                      <span style={{ fontSize: "0.76rem", color: "var(--text-muted)" }}>
                        {forgotCountdown > 0
                          ? `Expires in ${Math.floor(forgotCountdown / 60)}:${forgotCountdown % 60 < 10 ? "0" : ""}${forgotCountdown % 60}`
                          : "Expired"}
                      </span>
                    </div>
                    <div style={{ marginTop: 8, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                      <span style={{ fontSize: "0.84rem", color: "var(--text-primary)" }}>
                        Your 6-Digit Verification OTP:
                      </span>
                      <span style={{
                        fontSize: "1.25rem",
                        fontWeight: 700,
                        letterSpacing: "4px",
                        color: "var(--primary-color, #ea580c)",
                        background: "var(--bg-surface)",
                        padding: "3px 10px",
                        borderRadius: "var(--radius-sm)",
                        border: "1px solid rgba(234, 88, 12, 0.3)"
                      }}>
                        {forgotOtpPreview}
                      </span>
                    </div>
                  </div>

                  <div className="storyboard-form-group" style={{ marginBottom: 12 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                      <label className="storyboard-label" style={{ fontWeight: 600, margin: 0 }}>
                        Enter 6-Digit OTP
                      </label>
                      <button
                        type="button"
                        onClick={handleRequestOtp}
                        disabled={forgotLoading}
                        style={{
                          background: "none",
                          border: "none",
                          color: "var(--accent-cyan, #0284c7)",
                          fontSize: "0.78rem",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: 4,
                          padding: 0
                        }}
                      >
                        <RefreshCw size={12} className={forgotLoading ? "animate-spin" : ""} />
                        <span>Resend OTP</span>
                      </button>
                    </div>
                    <input
                      type="text"
                      className="storyboard-input"
                      maxLength={6}
                      placeholder="••••••"
                      value={forgotOtp}
                      onChange={(e) => {
                        setForgotOtp(e.target.value.replace(/\D/g, ""));
                        setForgotError(null);
                      }}
                      style={{
                        letterSpacing: "8px",
                        textAlign: "center",
                        fontSize: "1.2rem",
                        fontWeight: 700
                      }}
                      required
                      autoFocus
                    />
                  </div>

                  <div className="storyboard-form-group" style={{ marginBottom: 12 }}>
                    <label className="storyboard-label" style={{ fontWeight: 600 }}>
                      New Password
                    </label>
                    <div className="storyboard-password-wrapper">
                      <input
                        type={forgotShowNewPass ? "text" : "password"}
                        className="storyboard-input password-input"
                        placeholder="At least 6 characters"
                        value={forgotNewPassword}
                        onChange={(e) => {
                          setForgotNewPassword(e.target.value);
                          setForgotError(null);
                        }}
                        required
                      />
                      <button
                        type="button"
                        className="storyboard-eye-btn"
                        onClick={() => setForgotShowNewPass(!forgotShowNewPass)}
                        tabIndex={-1}
                      >
                        {forgotShowNewPass ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>

                  <div className="storyboard-form-group" style={{ marginBottom: 12 }}>
                    <label className="storyboard-label" style={{ fontWeight: 600 }}>
                      Confirm New Password
                    </label>
                    <input
                      type={forgotShowNewPass ? "text" : "password"}
                      className="storyboard-input"
                      placeholder="Re-enter new password"
                      value={forgotConfirmPassword}
                      onChange={(e) => {
                        setForgotConfirmPassword(e.target.value);
                        setForgotError(null);
                      }}
                      required
                    />
                  </div>

                  {forgotError && (
                    <div className="storyboard-error-alert" style={{ marginTop: 8, marginBottom: 8 }}>
                      <AlertCircle size={16} style={{ flexShrink: 0 }} />
                      <span>{forgotError}</span>
                    </div>
                  )}
                </div>

                <div className="modal-footer" style={{ display: "flex", justifyContent: "space-between" }}>
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => setForgotStep(1)}
                    style={{ display: "flex", alignItems: "center", gap: 6 }}
                  >
                    <ArrowLeft size={16} />
                    <span>Back</span>
                  </button>
                  <button
                    type="submit"
                    className="btn btn-primary"
                    disabled={forgotLoading}
                  >
                    {forgotLoading ? (
                      <span className="btn-flex-center">
                        <Loader2 size={16} className="animate-spin" />
                        <span>Updating Password...</span>
                      </span>
                    ) : (
                      <span>Verify & Reset Password</span>
                    )}
                  </button>
                </div>
              </form>
            )}

            {/* STEP 3: Success Confirmation */}
            {forgotStep === 3 && (
              <div>
                <div className="modal-body" style={{ textAlign: "center", padding: "28px 16px" }}>
                  <div style={{
                    width: 60,
                    height: 60,
                    borderRadius: "50%",
                    background: "rgba(16, 185, 129, 0.12)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto 16px"
                  }}>
                    <Check size={32} color="#10b981" strokeWidth={3} />
                  </div>
                  <h4 style={{ fontSize: "1.15rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: 8 }}>
                    Password Reset Successfully!
                  </h4>
                  <p style={{ fontSize: "0.88rem", color: "var(--text-secondary)", maxWidth: 360, margin: "0 auto 16px", lineHeight: 1.5 }}>
                    Your password has been securely updated in the database. You can now proceed to log in with your new credentials.
                  </p>
                </div>
                <div className="modal-footer" style={{ display: "flex", justifyContent: "center" }}>
                  <button
                    type="button"
                    className="btn btn-primary"
                    style={{ minWidth: 160 }}
                    onClick={() => setShowForgotModal(false)}
                  >
                    Sign In Now
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default Login;
