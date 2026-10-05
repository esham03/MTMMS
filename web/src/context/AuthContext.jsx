import React, { createContext, useContext, useState, useEffect } from "react";
import api from "../api/api";

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(
    localStorage.getItem("mtmms_token") || sessionStorage.getItem("mtmms_token")
  );
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [theme, setTheme] = useState(localStorage.getItem("mtmms_theme") || "light");

  // Temporary holder for deferred login commits
  const [pendingSession, setPendingSession] = useState(null);

  // Initialize theme
  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("mtmms_theme", theme);
  }, [theme]);

  // Check existing session on load & listen for session invalidation
  useEffect(() => {
    const initializeAuth = async () => {
      const savedToken =
        localStorage.getItem("mtmms_token") || sessionStorage.getItem("mtmms_token");
      const savedUser =
        localStorage.getItem("mtmms_user") || sessionStorage.getItem("mtmms_user");

      if (savedToken && savedUser) {
        try {
          const parsedUser = JSON.parse(savedUser);
          setToken(savedToken);
          setUser(parsedUser);

          // Actively verify token with the backend
          try {
            const res = await api.get("/auth/me");
            const liveUser = res.data?.user || res.data?.data || res.data;
            if (liveUser) {
              setUser(liveUser);
            }
            setIsAuthenticated(true);
          } catch (err) {
            console.warn("Session verification failed on startup:", err?.message || err);
            localStorage.removeItem("mtmms_token");
            localStorage.removeItem("mtmms_user");
            sessionStorage.removeItem("mtmms_token");
            sessionStorage.removeItem("mtmms_user");
            setUser(null);
            setToken(null);
            setIsAuthenticated(false);
          }
        } catch {
          localStorage.removeItem("mtmms_token");
          localStorage.removeItem("mtmms_user");
          sessionStorage.removeItem("mtmms_token");
          sessionStorage.removeItem("mtmms_user");
          setUser(null);
          setToken(null);
          setIsAuthenticated(false);
        }
      } else {
        setIsAuthenticated(false);
      }
      setIsLoading(false);
    };

    initializeAuth();

    const handleAuthInvalid = () => {
      setUser(null);
      setToken(null);
      setIsAuthenticated(false);
      setPendingSession(null);
    };

    window.addEventListener("auth_invalid", handleAuthInvalid);
    return () => window.removeEventListener("auth_invalid", handleAuthInvalid);
  }, []);

  // Login handler with support for deferred session commitment
  const login = async (credentials) => {
    const { email, password, remember = true, deferCommit = false } = credentials;

    const response = await api.post("/auth/login", {
      email: email.trim(),
      password,
    });

    const responseData = response.data;
    const receivedToken = responseData.token || responseData.access_token || responseData.data?.token;
    const userData = responseData.user || responseData.data?.user || {
      id: 1,
      name: "Administrator",
      email: email.trim(),
      role: "admin",
      department: "Department of Information Technology",
    };

    if (!receivedToken) {
      throw new Error("No authorization token received from server.");
    }

    if (deferCommit) {
      // Store session data in pending state so visual celebration can complete
      setPendingSession({ token: receivedToken, user: userData, remember });
      return { user: userData, token: receivedToken };
    }

    // Direct commit
    if (remember) {
      localStorage.setItem("mtmms_token", receivedToken);
      localStorage.setItem("mtmms_user", JSON.stringify(userData));
    } else {
      sessionStorage.setItem("mtmms_token", receivedToken);
      sessionStorage.setItem("mtmms_user", JSON.stringify(userData));
    }

    setToken(receivedToken);
    setUser(userData);
    setIsAuthenticated(true);
    return { user: userData, token: receivedToken };
  };

  // Commit deferred session (called after the 3-second green animation finishes)
  const commitLogin = () => {
    if (pendingSession) {
      const { token: pToken, user: pUser, remember: pRemember } = pendingSession;
      if (pRemember) {
        localStorage.setItem("mtmms_token", pToken);
        localStorage.setItem("mtmms_user", JSON.stringify(pUser));
      } else {
        sessionStorage.setItem("mtmms_token", pToken);
        sessionStorage.setItem("mtmms_user", JSON.stringify(pUser));
      }
      setToken(pToken);
      setUser(pUser);
      setIsAuthenticated(true);
      setPendingSession(null);
    }
  };

  const logout = async () => {
    try {
      if (token) {
        await api.post("/auth/logout").catch(() => {});
      }
    } finally {
      localStorage.removeItem("mtmms_token");
      localStorage.removeItem("mtmms_user");
      sessionStorage.removeItem("mtmms_token");
      sessionStorage.removeItem("mtmms_user");
      setUser(null);
      setToken(null);
      setIsAuthenticated(false);
      setPendingSession(null);
    }
  };

  const updateProfile = (updatedFields) => {
    const updated = { ...user, ...updatedFields };
    setUser(updated);
    // Persist to whichever storage currently holds the session
    if (localStorage.getItem("mtmms_token")) {
      localStorage.setItem("mtmms_user", JSON.stringify(updated));
    } else {
      sessionStorage.setItem("mtmms_user", JSON.stringify(updated));
    }
  };

  const toggleTheme = () => {
    setTheme((prev) => (prev === "dark" ? "light" : "dark"));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated,
        isLoading,
        theme,
        login,
        commitLogin,
        logout,
        updateProfile,
        toggleTheme,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

export default AuthContext;
