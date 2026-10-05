import React from "react";
import { BrowserRouter, HashRouter } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import ErrorBoundary from "./components/ErrorBoundary";
import AppRoutes from "./routes/AppRoutes";
import "./styles/main.css";

// Use HashRouter in Electron / file protocol to support static file loading & reloading
const isElectron =
  typeof window !== "undefined" &&
  (window.navigator.userAgent.includes("Electron") ||
    window.location.protocol === "file:");

const Router = isElectron ? HashRouter : BrowserRouter;

export function App() {
  return (
    <Router>
      <AuthProvider>
        <ErrorBoundary>
          <AppRoutes />
        </ErrorBoundary>
      </AuthProvider>
    </Router>
  );
}

export default App;