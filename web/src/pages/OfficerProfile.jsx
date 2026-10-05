import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  UserCheck,
  ShieldCheck,
  Save,
  Lock,
  UserPlus,
  Trash2,
  Eye,
  EyeOff,
  CheckCircle2,
  AlertTriangle,
  X,
  Edit2,
  RefreshCw,
  Loader2,
  LogIn,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import api from "../api/api";
import userApi from "../api/userApi";

export const OfficerProfile = () => {
  const navigate = useNavigate();
  const { user, updateProfile, logout } = useAuth();

  const [activeTab, setActiveTab] = useState("profile"); // "profile" | "personnel" | "security"
  const [successMessage, setSuccessMessage] = useState(null);
  const [errorMessage, setErrorMessage] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // 1. Officer Profile State
  const [profileData, setProfileData] = useState({
    name: user?.name || "Administrator",
    email: user?.email || "admin@goa.gov.in",
    department: user?.department || "Department of Information Technology",
    designation: user?.designation || "Senior Systems Manager",
    contact_number: user?.contact_number || "+91 832 2419000",
  });

  // Synchronize profile data whenever the logged-in user changes or loads
  useEffect(() => {
    if (user) {
      setProfileData((prev) => ({
        ...prev,
        name: user.name || prev.name,
        email: user.email || prev.email,
        department: user.department || prev.department,
        designation: user.designation || prev.designation,
        contact_number: user.contact_number || prev.contact_number,
      }));
    }
  }, [user]);

  // 2. Authorised Personnel State
  const [personnelList, setPersonnelList] = useState([]);
  const [isLoadingPersonnel, setIsLoadingPersonnel] = useState(false);
  const [lastCreatedOfficer, setLastCreatedOfficer] = useState(null);

  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedPersonnel, setSelectedPersonnel] = useState(null);

  const [newPersonnel, setNewPersonnel] = useState({
    name: "",
    email: "",
    password: "",
    role: "officer",
    department: "Department of Information Technology",
  });
  const [showAddPw, setShowAddPw] = useState(false);
  const [showEditPw, setShowEditPw] = useState(false);

  // 3. Credentials & Security State
  const [credData, setCredData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [showCurrentPw, setShowCurrentPw] = useState(false);
  const [showNewPw, setShowNewPw] = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);

  const notifySuccess = (msg) => {
    setSuccessMessage(msg);
    setErrorMessage(null);
    setTimeout(() => setSuccessMessage(null), 4000);
  };

  const notifyError = (msg) => {
    setErrorMessage(msg);
    setSuccessMessage(null);
    setTimeout(() => setErrorMessage(null), 4500);
  };

  // Fetch live personnel from the backend API
  const loadPersonnel = async () => {
    setIsLoadingPersonnel(true);
    try {
      const data = await userApi.getUsers();
      const list = Array.isArray(data) ? data : data.data || [];
      setPersonnelList(list);
    } catch (err) {
      console.error("Failed to load authorized personnel:", err);
      try {
        const saved = localStorage.getItem("mtmms_authorised_personnel");
        if (saved) setPersonnelList(JSON.parse(saved));
      } catch {}
    } finally {
      setIsLoadingPersonnel(false);
    }
  };

  // Load personnel on component mount
  useEffect(() => {
    loadPersonnel();
  }, []);

  // Save changes to current officer's own profile
  const handleSaveProfile = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const res = await api.put("/auth/profile", {
        name: profileData.name.trim(),
        email: profileData.email.trim(),
        department: profileData.department.trim(),
      });
      const updatedUser = res.data?.user || { ...user, ...profileData };
      updateProfile(updatedUser);
      notifySuccess("Officer profile information saved to system successfully.");
    } catch (err) {
      console.warn("Could not save profile to remote backend, saving locally:", err);
      updateProfile(profileData);
      notifySuccess("Officer profile saved locally.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Change current user's password
  const handleSavePassword = async (e) => {
    e.preventDefault();
    if (!credData.currentPassword) {
      notifyError("Please enter your current password.");
      return;
    }
    if (credData.newPassword.length < 6) {
      notifyError("New password must be at least 6 characters in length.");
      return;
    }
    if (credData.newPassword !== credData.confirmPassword) {
      notifyError("New password and confirm password do not match.");
      return;
    }

    setIsSubmitting(true);
    try {
      await api.post("/auth/change-password", {
        current_password: credData.currentPassword,
        new_password: credData.newPassword,
      });
      setCredData({ currentPassword: "", newPassword: "", confirmPassword: "" });
      notifySuccess("Password and credentials updated successfully on the server.");
    } catch (err) {
      console.error("Password change failed:", err);
      const msg =
        err.response?.data?.errors?.current_password?.[0] ||
        err.response?.data?.errors?.new_password?.[0] ||
        err.response?.data?.message ||
        "Failed to update password. Please check your current password.";
      notifyError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Add new authorized person with login credentials directly to the backend
  const handleAddPersonnel = async (e) => {
    e.preventDefault();
    if (!newPersonnel.name.trim() || !newPersonnel.email.trim()) {
      notifyError("Please provide both officer name and official email.");
      return;
    }
    if (!newPersonnel.password || newPersonnel.password.length < 6) {
      notifyError("Login password must be at least 6 characters in length.");
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = {
        name: newPersonnel.name.trim(),
        email: newPersonnel.email.trim(),
        password: newPersonnel.password,
        role: newPersonnel.role,
        department: newPersonnel.department?.trim() || "Department of Information Technology",
      };

      await userApi.createUser(payload);

      notifySuccess(
        `Authorised officer "${payload.name}" added successfully with active login credentials!`
      );

      setLastCreatedOfficer({
        name: payload.name,
        email: payload.email,
        role: payload.role,
      });

      setShowAddModal(false);
      setNewPersonnel({
        name: "",
        email: "",
        password: "",
        role: "officer",
        department: "Department of Information Technology",
      });
      setShowAddPw(false);
      await loadPersonnel();
    } catch (err) {
      console.error("Error creating authorized person:", err);
      const msg =
        err.response?.data?.errors?.email?.[0] ||
        err.response?.data?.errors?.password?.[0] ||
        err.response?.data?.message ||
        "Failed to create authorized person. Please check email uniqueness and password requirements.";
      notifyError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Update existing authorized person's details or reset password
  const handleUpdatePersonnel = async (e) => {
    e.preventDefault();
    if (!selectedPersonnel) return;

    setIsSubmitting(true);
    try {
      const payload = {
        name: selectedPersonnel.name.trim(),
        email: selectedPersonnel.email.trim(),
        role: selectedPersonnel.role,
        department: selectedPersonnel.department?.trim() || "Department of Information Technology",
      };

      if (selectedPersonnel.newPassword && selectedPersonnel.newPassword.trim().length > 0) {
        if (selectedPersonnel.newPassword.length < 6) {
          notifyError("Password must be at least 6 characters in length.");
          setIsSubmitting(false);
          return;
        }
        payload.password = selectedPersonnel.newPassword;
      }

      await userApi.updateUser(selectedPersonnel.id, payload);
      notifySuccess(`Authorised officer "${payload.name}" updated successfully.`);
      setShowEditModal(false);
      await loadPersonnel();
    } catch (err) {
      console.error("Error updating authorized person:", err);
      const msg =
        err.response?.data?.errors?.email?.[0] ||
        err.response?.data?.errors?.password?.[0] ||
        err.response?.data?.message ||
        "Failed to update authorized person.";
      notifyError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Revoke/Delete authorized person
  const handleDeletePersonnel = async (id, name) => {
    if (user && user.id === id) {
      notifyError("You cannot revoke your own active login session account.");
      return;
    }
    if (personnelList.length <= 1) {
      notifyError("At least one primary administrator must remain authorized.");
      return;
    }
    if (
      window.confirm(
        `Are you sure you want to revoke authorization for ${name || "this officer"}? Their login access to MTMMS will be completely deactivated.`
      )
    ) {
      try {
        await userApi.deleteUser(id);
        notifySuccess(`Authorised personnel "${name || id}" revoked.`);
        await loadPersonnel();
      } catch (err) {
        console.error("Error deleting authorized person:", err);
        const msg = err.response?.data?.message || "Failed to revoke authorized person.";
        notifyError(msg);
      }
    }
  };

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Officer Profile & Authorised Personnel</h1>
          <p>Official Department of Information Technology officer management and access credentials</p>
        </div>
      </div>

      {/* Alerts */}
      {successMessage && (
        <div
          style={{
            background: "var(--success-bg)",
            border: "1px solid var(--success-border)",
            color: "#34d399",
            padding: "12px 16px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <CheckCircle2 size={18} />
          <span>{successMessage}</span>
        </div>
      )}

      {errorMessage && (
        <div
          style={{
            background: "var(--danger-bg)",
            border: "1px solid var(--danger-border)",
            color: "#f87171",
            padding: "12px 16px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <AlertTriangle size={18} />
          <span>{errorMessage}</span>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display: "flex", gap: 10, marginBottom: 20 }}>
        <button
          className={`btn ${activeTab === "profile" ? "btn-primary" : "btn-secondary"}`}
          onClick={() => setActiveTab("profile")}
        >
          <UserCheck size={16} />
          <span>Officer Profile</span>
        </button>

        <button
          className={`btn ${activeTab === "personnel" ? "btn-primary" : "btn-secondary"}`}
          onClick={() => {
            setActiveTab("personnel");
            loadPersonnel();
          }}
        >
          <ShieldCheck size={16} />
          <span>Authorised Personnel ({personnelList.length})</span>
        </button>

        <button
          className={`btn ${activeTab === "security" ? "btn-primary" : "btn-secondary"}`}
          onClick={() => setActiveTab("security")}
        >
          <Lock size={16} />
          <span>Credentials & Security</span>
        </button>
      </div>

      {/* Tab 1: Profile Information */}
      {activeTab === "profile" && (
        <div className="grid-cols-2">
          <div className="card">
            <div className="card-header">
              <h3 className="card-title">Officer Information</h3>
              <span className="badge badge-success">Verified Active</span>
            </div>

            <form onSubmit={handleSaveProfile}>
              <div className="form-group">
                <label className="form-label">Full Name</label>
                <input
                  type="text"
                  className="form-control"
                  value={profileData.name}
                  onChange={(e) => setProfileData({ ...profileData, name: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Official Email</label>
                <input
                  type="email"
                  className="form-control"
                  value={profileData.email}
                  onChange={(e) => setProfileData({ ...profileData, email: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Department</label>
                <input
                  type="text"
                  className="form-control"
                  value={profileData.department}
                  onChange={(e) => setProfileData({ ...profileData, department: e.target.value })}
                  required
                />
              </div>

              <div className="form-grid-2">
                <div className="form-group">
                  <label className="form-label">Designation</label>
                  <input
                    type="text"
                    className="form-control"
                    value={profileData.designation}
                    onChange={(e) => setProfileData({ ...profileData, designation: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contact Number</label>
                  <input
                    type="text"
                    className="form-control"
                    value={profileData.contact_number}
                    onChange={(e) => setProfileData({ ...profileData, contact_number: e.target.value })}
                  />
                </div>
              </div>

              <button
                type="submit"
                className="btn btn-primary"
                style={{ marginTop: 10 }}
                disabled={isSubmitting}
              >
                {isSubmitting ? <Loader2 size={15} className="spinner" /> : <Save size={15} />}
                <span>Save Profile Changes</span>
              </button>
            </form>
          </div>

          <div className="card">
            <div className="card-header">
              <h3 className="card-title">Government Identity Card</h3>
            </div>

            <div
              style={{
                background: "linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)",
                border: "1.5px solid #cbd5e1",
                borderTop: "3.5px solid #ff5100",
                borderRadius: "var(--radius-lg)",
                padding: "24px",
                display: "flex",
                flexDirection: "column",
                gap: 16,
                boxShadow: "0 10px 30px -4px rgba(15, 23, 42, 0.08), 0 0 20px rgba(255, 81, 0, 0.08)",
                position: "relative",
                overflow: "hidden",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 12 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                  <div
                    style={{
                      width: 54,
                      height: 54,
                      borderRadius: "50%",
                      background: "linear-gradient(135deg, #ff5100 0%, #ff7700 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: "1.25rem",
                      fontWeight: 800,
                      color: "#ffffff",
                      boxShadow: "0 4px 14px rgba(255, 81, 0, 0.35)",
                    }}
                  >
                    {profileData.name?.slice(0, 2).toUpperCase()}
                  </div>
                  <div>
                    <div style={{ fontSize: "1.2rem", fontWeight: 800, color: "var(--text-primary)" }}>{profileData.name}</div>
                    <div style={{ fontSize: "0.85rem", color: "#ff5100", fontWeight: 700 }}>
                      {profileData.designation}
                    </div>
                  </div>
                </div>

                <div
                  style={{
                    fontSize: "0.68rem",
                    fontWeight: 800,
                    color: "#ff5100",
                    background: "rgba(255, 81, 0, 0.1)",
                    border: "1px solid rgba(255, 81, 0, 0.3)",
                    padding: "4px 10px",
                    borderRadius: "14px",
                    letterSpacing: "0.06em",
                    textTransform: "uppercase",
                  }}
                >
                  Official Govt Badge
                </div>
              </div>

              <div
                style={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 10,
                  fontSize: "0.88rem",
                  borderTop: "1.5px solid #e2e8f0",
                  paddingTop: 16,
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap" }}>
                  <span style={{ color: "#475569", fontWeight: 600 }}>Official Email:</span>
                  <span style={{ fontWeight: 700, color: "#0a0f1d" }}>{profileData.email}</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap" }}>
                  <span style={{ color: "#475569", fontWeight: 600 }}>Department:</span>
                  <span style={{ fontWeight: 700, color: "#0a0f1d" }}>{profileData.department}</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap" }}>
                  <span style={{ color: "#475569", fontWeight: 600 }}>State Authority:</span>
                  <span style={{ fontWeight: 700, color: "#0a0f1d" }}>Government of Goa</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap" }}>
                  <span style={{ color: "#475569", fontWeight: 600 }}>System Role:</span>
                  <span className="badge badge-success" style={{ fontWeight: 800, textTransform: "uppercase" }}>
                    {user?.role || "admin"}
                  </span>
                </div>
              </div>

              <div
                style={{
                  fontSize: "0.72rem",
                  color: "#475569",
                  fontWeight: 600,
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                  paddingTop: 12,
                  borderTop: "1px dashed #cbd5e1",
                  marginTop: 2,
                }}
              >
                <ShieldCheck size={14} color="#ff5100" />
                <span>Verified State Telecommunications Personnel · Goa DoIT</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: Authorised Personnel */}
      {activeTab === "personnel" && (
        <div className="card">
          <div className="card-header" style={{ flexWrap: "wrap", gap: 12 }}>
            <div>
              <h3 className="card-title">Authorised Personnel Management</h3>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Officers and administrators permitted to log in and operate the MTMMS system
              </p>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button
                className="btn btn-secondary btn-sm"
                onClick={loadPersonnel}
                disabled={isLoadingPersonnel}
                title="Refresh authorized personnel list"
              >
                <RefreshCw size={14} className={isLoadingPersonnel ? "spinner" : ""} />
                <span>Refresh</span>
              </button>
              <button
                className="btn btn-primary btn-sm"
                onClick={() => {
                  setNewPersonnel({
                    name: "",
                    email: "",
                    password: "",
                    role: "officer",
                    department: "Department of Information Technology",
                  });
                  setShowAddPw(false);
                  setShowAddModal(true);
                }}
              >
                <UserPlus size={15} />
                <span>Add Authorised Person</span>
              </button>
            </div>
          </div>

          {/* Newly Created Officer Banner with Instant Switch Option */}
          {lastCreatedOfficer && (
            <div
              style={{
                background: "linear-gradient(135deg, rgba(16, 185, 129, 0.12) 0%, rgba(6, 182, 212, 0.12) 100%)",
                border: "1px solid rgba(16, 185, 129, 0.3)",
                borderRadius: "var(--radius-md)",
                padding: "14px 18px",
                marginBottom: 20,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                flexWrap: "wrap",
                gap: 12,
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <CheckCircle2 size={22} color="#10b981" />
                <div>
                  <div style={{ fontWeight: 700, fontSize: "0.92rem", color: "#10b981" }}>
                    New Authorized Person Created & Ready to Log In:
                  </div>
                  <div style={{ fontSize: "0.82rem", color: "var(--text-secondary)", marginTop: 2 }}>
                    <strong>{lastCreatedOfficer.name}</strong> ({lastCreatedOfficer.email}) &bull; Role:{" "}
                    <span style={{ textTransform: "capitalize" }}>{lastCreatedOfficer.role}</span>
                  </div>
                </div>
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                <button
                  type="button"
                  className="btn btn-primary btn-sm"
                  onClick={async () => {
                    await logout();
                    navigate("/login", { state: { email: lastCreatedOfficer.email } });
                  }}
                  title="Log out current account and sign in with this new officer account"
                >
                  <LogIn size={14} />
                  <span>Log In as {lastCreatedOfficer.name}</span>
                </button>
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => setLastCreatedOfficer(null)}
                >
                  Dismiss
                </button>
              </div>
            </div>
          )}

          {isLoadingPersonnel ? (
            <div style={{ padding: "40px 20px", textAlign: "center", color: "var(--text-muted)" }}>
              <Loader2 size={28} className="spinner" style={{ margin: "0 auto 10px" }} />
              <div>Loading authorized personnel from database...</div>
            </div>
          ) : personnelList.length === 0 ? (
            <div style={{ padding: "40px 20px", textAlign: "center", color: "var(--text-muted)" }}>
              <UserPlus size={32} style={{ margin: "0 auto 10px", opacity: 0.5 }} />
              <div>No authorized personnel found. Click "Add Authorised Person" above to create one.</div>
            </div>
          ) : (
            <div className="table-container">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Officer Name</th>
                    <th>Official Email (Login)</th>
                    <th>Role</th>
                    <th>Department</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {personnelList.map((p) => {
                    const isSelf = user?.id === p.id || user?.email === p.email;
                    return (
                      <tr key={p.id}>
                        <td>
                          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                            <div
                              style={{
                                width: 34,
                                height: 34,
                                borderRadius: "50%",
                                background: isSelf
                                  ? "rgba(16, 185, 129, 0.15)"
                                  : "rgba(6, 182, 212, 0.15)",
                                color: isSelf ? "#10b981" : "var(--accent-cyan)",
                                display: "flex",
                                alignItems: "center",
                                justifyCenter: "center",
                                fontSize: "0.78rem",
                                fontWeight: 700,
                              }}
                            >
                              <span style={{ margin: "auto" }}>
                                {p.name?.slice(0, 2).toUpperCase()}
                              </span>
                            </div>
                            <div>
                              <div style={{ fontWeight: 600 }}>{p.name}</div>
                              {isSelf && (
                                <span
                                  style={{
                                    fontSize: "0.7rem",
                                    color: "var(--accent-emerald)",
                                    fontWeight: 600,
                                    display: "block",
                                  }}
                                >
                                  (Current Active Session)
                                </span>
                              )}
                            </div>
                          </div>
                        </td>
                        <td>
                          <span style={{ fontFamily: "monospace", fontSize: "0.85rem" }}>
                            {p.email}
                          </span>
                        </td>
                        <td>
                          <span
                            className={`badge ${
                              p.role === "admin"
                                ? "badge-info"
                                : p.role === "officer"
                                ? "badge-success"
                                : "badge-neutral"
                            }`}
                            style={{ textTransform: "capitalize" }}
                          >
                            {p.role}
                          </span>
                        </td>
                        <td>{p.department || "Dept of IT"}</td>
                        <td>
                          <span className="badge badge-success">Active Authorized</span>
                        </td>
                        <td>
                          <div style={{ display: "flex", gap: 6 }}>
                            <button
                              className="btn btn-secondary btn-icon btn-sm"
                              onClick={() => {
                                setSelectedPersonnel({
                                  ...p,
                                  newPassword: "",
                                });
                                setShowEditPw(false);
                                setShowEditModal(true);
                              }}
                              title="Edit Officer Details & Reset Password"
                            >
                              <Edit2 size={13} />
                            </button>

                            {!isSelf && (
                              <button
                                className="btn btn-secondary btn-icon btn-sm"
                                onClick={async () => {
                                  if (
                                    window.confirm(
                                      `Log out of your current session and open login page for ${p.name}?`
                                    )
                                  ) {
                                    await logout();
                                    navigate("/login", { state: { email: p.email } });
                                  }
                                }}
                                title={`Switch to / Log In as ${p.name}`}
                              >
                                <LogIn size={13} />
                              </button>
                            )}

                            <button
                              className="btn btn-danger btn-icon btn-sm"
                              onClick={() => handleDeletePersonnel(p.id, p.name)}
                              disabled={isSelf}
                              title={isSelf ? "Cannot revoke your own active account" : "Revoke Access"}
                              style={isSelf ? { opacity: 0.35, cursor: "not-allowed" } : {}}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Tab 3: Credentials & Security */}
      {activeTab === "security" && (
        <div className="grid-cols-2">
          <div className="card">
            <div className="card-header">
              <h3 className="card-title">Update Password</h3>
            </div>

            <form onSubmit={handleSavePassword}>
              <div className="form-group">
                <label className="form-label">Current Password *</label>
                <div className="input-icon-wrapper">
                  <Lock size={16} className="input-leading-icon" />
                  <input
                    type={showCurrentPw ? "text" : "password"}
                    className="form-control input-with-icon input-with-trailing"
                    placeholder="Enter current password"
                    value={credData.currentPassword}
                    onChange={(e) => setCredData({ ...credData, currentPassword: e.target.value })}
                    required
                  />
                  <button
                    type="button"
                    className="input-trailing-btn"
                    onClick={() => setShowCurrentPw(!showCurrentPw)}
                    title={showCurrentPw ? "Hide password" : "Show password"}
                  >
                    {showCurrentPw ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">New Password * (Min 6 characters)</label>
                <div className="input-icon-wrapper">
                  <Lock size={16} className="input-leading-icon" />
                  <input
                    type={showNewPw ? "text" : "password"}
                    className="form-control input-with-icon input-with-trailing"
                    placeholder="Enter new strong password"
                    value={credData.newPassword}
                    onChange={(e) => setCredData({ ...credData, newPassword: e.target.value })}
                    minLength={6}
                    required
                  />
                  <button
                    type="button"
                    className="input-trailing-btn"
                    onClick={() => setShowNewPw(!showNewPw)}
                    title={showNewPw ? "Hide password" : "Show password"}
                  >
                    {showNewPw ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Confirm New Password *</label>
                <div className="input-icon-wrapper">
                  <Lock size={16} className="input-leading-icon" />
                  <input
                    type={showConfirmPw ? "text" : "password"}
                    className="form-control input-with-icon input-with-trailing"
                    placeholder="Re-type new password"
                    value={credData.confirmPassword}
                    onChange={(e) => setCredData({ ...credData, confirmPassword: e.target.value })}
                    minLength={6}
                    required
                  />
                  <button
                    type="button"
                    className="input-trailing-btn"
                    onClick={() => setShowConfirmPw(!showConfirmPw)}
                    title={showConfirmPw ? "Hide password" : "Show password"}
                  >
                    {showConfirmPw ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                className="btn btn-primary"
                style={{ marginTop: 8 }}
                disabled={isSubmitting}
              >
                {isSubmitting ? <Loader2 size={15} className="spinner" /> : <Lock size={15} />}
                <span>Update Password</span>
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Add Personnel Modal */}
      {showAddModal && (
        <div className="modal-backdrop" onClick={() => setShowAddModal(false)}>
          <div className="modal-content" style={{ maxWidth: 520 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ fontSize: "1.15rem" }}>Add Authorised Person</h3>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setShowAddModal(false)}
              >
                <X size={16} />
              </button>
            </div>
            <form onSubmit={handleAddPersonnel}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Officer Sunita Naik"
                    value={newPersonnel.name}
                    onChange={(e) => setNewPersonnel({ ...newPersonnel, name: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Official Email (Username for Login) *</label>
                  <input
                    type="email"
                    className="form-control"
                    placeholder="e.g. sunita.naik@goa.gov.in"
                    value={newPersonnel.email}
                    onChange={(e) => setNewPersonnel({ ...newPersonnel, email: e.target.value })}
                    required
                  />
                  <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
                    Must be unique. This email is used to log in at the authentication portal.
                  </p>
                </div>

                <div className="form-group">
                  <label className="form-label">Login Password * (Min 6 characters)</label>
                  <div className="input-icon-wrapper">
                    <Lock size={16} className="input-leading-icon" />
                    <input
                      type={showAddPw ? "text" : "password"}
                      className="form-control input-with-icon input-with-trailing"
                      placeholder="Set initial password for login"
                      value={newPersonnel.password}
                      onChange={(e) => setNewPersonnel({ ...newPersonnel, password: e.target.value })}
                      minLength={6}
                      required
                    />
                    <button
                      type="button"
                      className="input-trailing-btn"
                      onClick={() => setShowAddPw(!showAddPw)}
                      title={showAddPw ? "Hide password" : "Show password"}
                    >
                      {showAddPw ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
                    The officer will use this password to access MTMMS.
                  </p>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Role</label>
                    <select
                      className="form-select"
                      value={newPersonnel.role}
                      onChange={(e) => setNewPersonnel({ ...newPersonnel, role: e.target.value })}
                    >
                      <option value="admin">Administrator (Full Access)</option>
                      <option value="officer">Field Officer (Standard)</option>
                      <option value="inspector">Site Inspector</option>
                      <option value="viewer">Auditor / Viewer (Read Only)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Department</label>
                    <input
                      type="text"
                      className="form-control"
                      value={newPersonnel.department}
                      onChange={(e) =>
                        setNewPersonnel({ ...newPersonnel, department: e.target.value })
                      }
                      placeholder="e.g. Dept of IT"
                    />
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowAddModal(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? (
                    <Loader2 size={15} className="spinner" />
                  ) : (
                    <UserPlus size={15} />
                  )}
                  <span>Create Authorised Officer</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Personnel Modal */}
      {showEditModal && selectedPersonnel && (
        <div className="modal-backdrop" onClick={() => setShowEditModal(false)}>
          <div className="modal-content" style={{ maxWidth: 520 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ fontSize: "1.15rem" }}>Edit Authorised Person</h3>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setShowEditModal(false)}
              >
                <X size={16} />
              </button>
            </div>
            <form onSubmit={handleUpdatePersonnel}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input
                    type="text"
                    className="form-control"
                    value={selectedPersonnel.name}
                    onChange={(e) =>
                      setSelectedPersonnel({ ...selectedPersonnel, name: e.target.value })
                    }
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Official Email</label>
                  <input
                    type="email"
                    className="form-control"
                    value={selectedPersonnel.email}
                    onChange={(e) =>
                      setSelectedPersonnel({ ...selectedPersonnel, email: e.target.value })
                    }
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Role</label>
                    <select
                      className="form-select"
                      value={selectedPersonnel.role}
                      onChange={(e) =>
                        setSelectedPersonnel({ ...selectedPersonnel, role: e.target.value })
                      }
                    >
                      <option value="admin">Administrator (Full Access)</option>
                      <option value="officer">Field Officer (Standard)</option>
                      <option value="inspector">Site Inspector</option>
                      <option value="viewer">Auditor / Viewer (Read Only)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Department</label>
                    <input
                      type="text"
                      className="form-control"
                      value={selectedPersonnel.department || ""}
                      onChange={(e) =>
                        setSelectedPersonnel({ ...selectedPersonnel, department: e.target.value })
                      }
                    />
                  </div>
                </div>

                <div className="form-group" style={{ marginTop: 8 }}>
                  <label className="form-label">Reset Password (Optional)</label>
                  <div className="input-icon-wrapper">
                    <Lock size={16} className="input-leading-icon" />
                    <input
                      type={showEditPw ? "text" : "password"}
                      className="form-control input-with-icon input-with-trailing"
                      placeholder="Leave blank to keep existing password"
                      value={selectedPersonnel.newPassword || ""}
                      onChange={(e) =>
                        setSelectedPersonnel({
                          ...selectedPersonnel,
                          newPassword: e.target.value,
                        })
                      }
                      minLength={6}
                    />
                    <button
                      type="button"
                      className="input-trailing-btn"
                      onClick={() => setShowEditPw(!showEditPw)}
                      title={showEditPw ? "Hide password" : "Show password"}
                    >
                      {showEditPw ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>
                    Only enter a new password if you want to reset this officer's login password.
                  </p>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowEditModal(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? <Loader2 size={15} className="spinner" /> : <Save size={15} />}
                  <span>Save Changes</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default OfficerProfile;
