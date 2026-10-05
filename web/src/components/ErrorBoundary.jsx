import React from "react";
import { AlertCircle, RefreshCw, Home } from "lucide-react";

export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error("MTMMS Application Error Boundary caught:", error, errorInfo);
    this.setState({ errorInfo });
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
    window.location.href = "/dashboard";
  };

  handleReload = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div
          style={{
            minHeight: "70vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: "40px 20px",
          }}
        >
          <div
            className="card"
            style={{
              maxWidth: 520,
              width: "100%",
              textAlign: "center",
              padding: "40px 32px",
              boxShadow: "var(--shadow-xl)",
              border: "1px solid rgba(239, 68, 68, 0.3)",
            }}
          >
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: "50%",
                background: "rgba(239, 68, 68, 0.12)",
                color: "#ef4444",
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                marginBottom: 18,
              }}
            >
              <AlertCircle size={28} />
            </div>

            <h2 style={{ fontSize: "1.35rem", marginBottom: 8, fontWeight: 700 }}>
              Something went wrong
            </h2>

            <p
              style={{
                color: "var(--text-secondary)",
                fontSize: "0.9rem",
                marginBottom: 20,
                lineHeight: 1.5,
              }}
            >
              An unexpected error prevented this view from rendering. You can reload the page or navigate back to the dashboard.
            </p>

            {this.state.error?.message && (
              <div
                style={{
                  background: "var(--bg-surface-elevated)",
                  border: "1px solid var(--border-color)",
                  borderRadius: "var(--radius-md)",
                  padding: "10px 14px",
                  fontSize: "0.78rem",
                  fontFamily: "monospace",
                  color: "#ef4444",
                  textAlign: "left",
                  marginBottom: 24,
                  wordBreak: "break-word",
                  maxHeight: 100,
                  overflowY: "auto",
                }}
              >
                {this.state.error.message}
              </div>
            )}

            <div
              style={{
                display: "flex",
                gap: 12,
                justifyContent: "center",
                flexWrap: "wrap",
              }}
            >
              <button
                className="btn btn-primary btn-sm"
                onClick={this.handleReload}
              >
                <RefreshCw size={14} />
                <span>Reload Page</span>
              </button>
              <button
                className="btn btn-secondary btn-sm"
                onClick={this.handleReset}
              >
                <Home size={14} />
                <span>Go to Dashboard</span>
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
