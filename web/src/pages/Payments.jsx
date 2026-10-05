import React, { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  CreditCard,
  Plus,
  Calendar,
  CheckCircle2,
  AlertTriangle,
  Receipt,
  Printer,
  X,
  Trash2,
  RefreshCw,
} from "lucide-react";
import DataTable from "../components/DataTable";
import PaymentReceiptModal from "../components/PaymentReceiptModal";
import rentApi from "../api/rentApi";
import towerApi from "../api/towerApi";

export const Payments = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [payments, setPayments] = useState([]);
  const [towers, setTowers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(
    searchParams.get("action") === "record"
  );
  const [selectedPaymentForReceipt, setSelectedPaymentForReceipt] = useState(null);

  const [formData, setFormData] = useState({
    tower_id: searchParams.get("tower_id") || "",
    amount: "",
    payment_date: new Date().toISOString().split("T")[0],
    payment_reference: "",
    payment_status: "paid",
    payment_method: "Treasury Challan",
    period_start: "",
    period_end: "",
    remarks: "",
  });

  const fetchData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [paymentsData, towersData] = await Promise.all([
        rentApi.getPayments(),
        towerApi.getTowers().catch(() => []),
      ]);
      setPayments(paymentsData);
      setTowers(towersData);
      if (towersData.length > 0 && !formData.tower_id) {
        setFormData((prev) => ({ ...prev, tower_id: towersData[0].id }));
      }
    } catch (e) {
      console.error("Failed to load payments", e);
      setError(e.response?.data?.message || e.message || "Failed to load payment transactions.");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleOpenRecord = () => {
    setFormData({
      tower_id: towers[0]?.id || "",
      amount: "",
      payment_date: new Date().toISOString().split("T")[0],
      payment_reference: "",
      payment_status: "paid",
      payment_method: "Treasury Challan",
      period_start: "",
      period_end: "",
      remarks: "",
    });
    setIsModalOpen(true);
  };

  const handleRecordSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await rentApi.createPayment(formData);
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      alert(err.response?.data?.message || "Failed to save payment transaction.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeletePayment = async (id) => {
    if (window.confirm("Are you sure you want to delete this payment record from the database?")) {
      try {
        await rentApi.deletePayment(id);
        fetchData();
      } catch (err) {
        alert(err.response?.data?.message || "Failed to delete payment.");
      }
    }
  };

  const columns = [
    {
      key: "payment_reference",
      title: "Challan / Ref ID",
      render: (val, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: "var(--radius-sm)",
              background: "rgba(16, 185, 129, 0.15)",
              color: "#10b981",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Receipt size={17} />
          </div>
          <div>
            <div style={{ fontWeight: 700 }}>{val || `REF-${row.id}`}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
              {row.payment_method || "Online"}
            </div>
          </div>
        </div>
      ),
    },
    {
      key: "tower",
      title: "Tower & Operators",
      render: (_, row) => {
        const ops = Array.isArray(row.tower?.operators) ? row.tower.operators : [];
        return (
          <div style={{ minWidth: 160 }}>
            <div
              style={{ fontWeight: 600, color: "var(--primary-light)", cursor: "pointer" }}
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/towers/${row.tower?.id || row.tower_id}`);
              }}
              title="View full tower details"
            >
              {row.tower?.tower_unique_id || `Tower #${row.tower_id}`}
            </div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>
              {row.tower?.owner?.name || row.tower?.address || "Goa Site"}
            </div>
            {ops.length > 0 && (
              <div style={{ display: "flex", gap: 4, marginTop: 4, flexWrap: "wrap" }}>
                {ops.map((op) => (
                  <span
                    key={op.id}
                    className="badge badge-info"
                    style={{ fontSize: "0.68rem", padding: "1px 6px" }}
                  >
                    {op.short_name || op.name}
                  </span>
                ))}
              </div>
            )}
          </div>
        );
      },
    },
    {
      key: "amount",
      title: "Amount",
      render: (val) => (
        <span style={{ fontWeight: 800, fontSize: "0.95rem", color: "#34d399" }}>
          ₹{(parseFloat(val) || 0).toLocaleString()}
        </span>
      ),
    },
    {
      key: "payment_date",
      title: "Payment Date",
      render: (val) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: "0.85rem" }}>
          <Calendar size={13} color="var(--text-muted)" />
          <span>{val ? val.split("T")[0] : "Pending"}</span>
        </div>
      ),
    },
    {
      key: "payment_status",
      title: "Status",
      render: (val) => {
        const isPaid = String(val).toLowerCase() === "paid";
        return (
          <span className={`badge ${isPaid ? "badge-paid" : "badge-overdue"}`}>
            {isPaid ? <CheckCircle2 size={12} /> : <AlertTriangle size={12} />}
            {val || "paid"}
          </span>
        );
      },
    },
    {
      key: "actions",
      title: "Actions",
      sortable: false,
      render: (_, row) => (
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <button
            className="btn btn-secondary btn-sm"
            onClick={() => setSelectedPaymentForReceipt(row)}
            title="Print Official Challan Receipt"
          >
            <Printer size={13} />
            <span>Receipt</span>
          </button>
          <button
            className="btn btn-secondary btn-icon btn-sm"
            style={{ color: "var(--danger)" }}
            onClick={() => handleDeletePayment(row.id)}
            title="Delete Record"
          >
            <Trash2 size={13} />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h1>Payment History & Challans</h1>
          <p>Live transaction ledger directly queried from MySQL rent_payments table</p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary btn-sm" onClick={fetchData}>
            <RefreshCw size={14} />
            <span>Refresh</span>
          </button>
          <button className="btn btn-primary btn-sm" onClick={handleOpenRecord}>
            <Plus size={15} />
            <span>Record Payment</span>
          </button>
        </div>
      </div>

      {error && (
        <div
          style={{
            background: "var(--danger-bg)",
            border: "1px solid var(--danger-border)",
            color: "#f87171",
            padding: "10px 14px",
            borderRadius: "var(--radius-md)",
            marginBottom: 20,
          }}
        >
          {error}
        </div>
      )}

      <DataTable
        columns={columns}
        data={payments}
        initialSearch={searchParams.get("search") || searchParams.get("q") || ""}
        searchPlaceholder="Search payments by Ref ID, Tower ID, Operator, Company, Method..."
        isLoading={isLoading}
        emptyMessage="No payment transactions logged in the database yet."
        exportFilename="MTMMS_Payments"
      />

      {/* Record Payment Modal */}
      {isModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Record Rent Remittance</h3>
              <button
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setIsModalOpen(false)}
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleRecordSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Select Tower Site</label>
                  <select
                    className="form-select"
                    value={formData.tower_id}
                    onChange={(e) => {
                      const twr = towers.find((t) => String(t.id) === String(e.target.value));
                      setFormData({
                        ...formData,
                        tower_id: e.target.value,
                        amount: twr?.yearly_rent || (twr?.monthly_rent ? twr.monthly_rent * 12 : 50000),
                      });
                    }}
                    required
                  >
                    <option value="">Select a tower</option>
                    {towers.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.tower_unique_id || `TWR-${t.id}`} — {t.address || "Goa"} (₹{(parseFloat(t.yearly_rent) || 60000).toLocaleString()}/yr)
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Remittance Amount (₹)</label>
                    <input
                      type="number"
                      className="form-control"
                      value={formData.amount}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          amount: parseFloat(e.target.value) || 0,
                        })
                      }
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Challan / Reference ID</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.payment_reference}
                      onChange={(e) =>
                        setFormData({ ...formData, payment_reference: e.target.value })
                      }
                      placeholder="e.g. CHQ-GA-123456"
                      required
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Payment Method</label>
                    <select
                      className="form-select"
                      value={formData.payment_method}
                      onChange={(e) =>
                        setFormData({ ...formData, payment_method: e.target.value })
                      }
                    >
                      <option value="Treasury Challan">Treasury Challan (Govt)</option>
                      <option value="RTGS / NEFT">RTGS / NEFT Transfer</option>
                      <option value="Cheque / DD">Cheque / Demand Draft</option>
                      <option value="Direct Debit">Direct Bank Mandate</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Payment Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={formData.payment_date}
                      onChange={(e) =>
                        setFormData({ ...formData, payment_date: e.target.value })
                      }
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Audit Remarks</label>
                  <textarea
                    className="form-control"
                    rows={2}
                    value={formData.remarks}
                    onChange={(e) => setFormData({ ...formData, remarks: e.target.value })}
                  ></textarea>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => setIsModalOpen(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary btn-sm"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Submitting..." : "Save Payment"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Official Government Payment Receipt Modal */}
      {selectedPaymentForReceipt && (
        <PaymentReceiptModal
          payment={selectedPaymentForReceipt}
          onClose={() => setSelectedPaymentForReceipt(null)}
        />
      )}
    </div>
  );
};

export default Payments;
