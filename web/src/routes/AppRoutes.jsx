import { Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import DashboardLayout from "../layouts/DashboardLayout";
import Loading from "../components/Loading";

// Pages
import Login from "../pages/Login";
import Dashboard from "../pages/Dashboard";
import MapView from "../pages/MapView";
import Towers from "../pages/Towers";
import TowerDetails from "../pages/TowerDetails";
import LocationBrowser from "../pages/LocationBrowser";
import Owners from "../pages/Owners";
import Operators from "../pages/Operators";
import RentManagement from "../pages/RentManagement";
import Payments from "../pages/Payments";
import Reports from "../pages/Reports";
import OfficerProfile from "../pages/OfficerProfile";

// Protected Route Guard
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <Loading message="Authenticating session..." />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

// Public Route Guard (Redirect if already logged in)
const PublicRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <Loading message="Loading MTMMS..." />;
  }

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
};

export const AppRoutes = () => {
  return (
    <Routes>
      {/* Authentication */}
      <Route
        path="/login"
        element={
          <PublicRoute>
            <Login />
          </PublicRoute>
        }
      />

      {/* Protected Backoffice Layout */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="map" element={<MapView />} />
        <Route path="towers" element={<Towers />} />
        <Route path="towers/:id" element={<TowerDetails />} />
        <Route path="owners" element={<Owners />} />
        <Route path="locations" element={<LocationBrowser />} />
        <Route path="operators" element={<Operators />} />
        <Route path="rent" element={<RentManagement />} />
        <Route path="payments" element={<Payments />} />
        <Route path="reports" element={<Reports />} />
        <Route path="profile" element={<OfficerProfile />} />
        <Route path="settings" element={<OfficerProfile />} />
      </Route>

      {/* Catch-all Fallback */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
};

export default AppRoutes;
