import React from "react";
import { Printer, X, CheckCircle2 } from "lucide-react";
import goaEmblem from "../assets/goa-emblem.png";

export const PaymentReceiptModal = ({ payment, onClose }) => {
  if (!payment) return null;

  const paymentDate = payment.payment_date
    ? new Date(payment.payment_date).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "long",
        year: "numeric",
      })
    : new Date().toLocaleDateString("en-IN", {
        day: "numeric",
        month: "long",
        year: "numeric",
      });

  const receiptNo = `GOA-MTMMS-REC-${String(payment.id || "001").padStart(5, "0")}`;
  const amountNum = parseFloat(payment.amount_paid || payment.amount || 0);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="modal-backdrop" onClick={onClose} style={{ zIndex: 100 }}>
      <div
        className="modal-content printable-modal"
        style={{
          maxWidth: 680,
          maxHeight: "90vh",
          display: "flex",
          flexDirection: "column",
          padding: 0,
          overflow: "hidden",
          background: "#ffffff",
          color: "#1e293b",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Toolbar (hidden on print) */}
        <div
          className="no-print"
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            padding: "12px 20px",
            background: "#0f172a",
            color: "#ffffff",
            borderBottom: "1px solid #334155",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <CheckCircle2 size={17} color="#10b981" />
            <span style={{ fontWeight: 700, fontSize: "0.92rem", color: "#f8fafc" }}>
              Official Payment Voucher / Receipt
            </span>
          </div>

          <div style={{ display: "flex", gap: 10 }}>
            <button
              type="button"
              className="btn btn-primary btn-sm"
              onClick={handlePrint}
              style={{ background: "#059669", color: "#ffffff", border: "none" }}
            >
              <Printer size={14} />
              <span>Print Receipt</span>
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-icon btn-sm"
              onClick={onClose}
              style={{ background: "#334155", color: "#ffffff", border: "1px solid #475569" }}
            >
              <X size={15} />
            </button>
          </div>
        </div>

        {/* Printable Receipt Body */}
        <div
          className="printable-document"
          style={{
            padding: "32px 40px",
            overflowY: "auto",
            fontSize: "13px",
            lineHeight: 1.6,
            color: "#0f172a",
            fontFamily: "'Inter', system-ui, -apple-system, sans-serif",
          }}
        >
          {/* Header */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 16,
              borderBottom: "2px solid #0f172a",
              paddingBottom: 14,
              marginBottom: 16,
            }}
          >
            <img
              src={goaEmblem}
              alt="Government of Goa"
              style={{ width: 52, height: "auto" }}
            />
            <div>
              <h2
                style={{
                  fontSize: "14px",
                  fontWeight: 800,
                  letterSpacing: "0.05em",
                  margin: 0,
                  textTransform: "uppercase",
                  color: "#0f172a",
                }}
              >
                Government of Goa
              </h2>
              <h3
                style={{
                  fontSize: "12.5px",
                  fontWeight: 700,
                  margin: "1px 0",
                  color: "#1e293b",
                }}
              >
                Department of Information Technology, Electronics &amp; Communications
              </h3>
              <p style={{ margin: 0, fontSize: "11px", color: "#64748b" }}>
                Mobile Tower Monitoring &amp; Management System (MTMMS) — Revenue Collection Receipt
              </p>
            </div>
          </div>

          {/* Receipt Identification Grid */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: 12,
              background: "#f8fafc",
              padding: "12px 16px",
              borderRadius: 6,
              border: "1px solid #e2e8f0",
              marginBottom: 20,
              fontSize: "12px",
            }}
          >
            <div>
              <span style={{ color: "#64748b" }}>Receipt Voucher No:</span>
              <div style={{ fontWeight: 800, color: "#0f172a", fontSize: "13px" }}>{receiptNo}</div>
            </div>
            <div>
              <span style={{ color: "#64748b" }}>Date of Payment:</span>
              <div style={{ fontWeight: 700, color: "#0f172a" }}>{paymentDate}</div>
            </div>
            <div>
              <span style={{ color: "#64748b" }}>Tower Reference ID:</span>
              <div style={{ fontWeight: 700, color: "#0284c7" }}>
                {payment.tower?.tower_unique_id || `TWR-${payment.tower_id || payment.tower?.id || "—"}`}
              </div>
            </div>
            <div>
              <span style={{ color: "#64748b" }}>Payment Channel / Mode:</span>
              <div style={{ fontWeight: 700, textTransform: "uppercase" }}>
                {payment.payment_mode || payment.mode || "Online / NEFT"}
              </div>
            </div>
          </div>

          {/* Payment Particulars Table */}
          <table
            style={{
              width: "100%",
              borderCollapse: "collapse",
              marginBottom: 20,
              fontSize: "12px",
            }}
          >
            <thead>
              <tr style={{ background: "#0f172a", color: "#ffffff" }}>
                <th style={{ border: "1px solid #0f172a", padding: "7px 10px", textAlign: "left" }}>Particulars</th>
                <th style={{ border: "1px solid #0f172a", padding: "7px 10px", textAlign: "right" }}>Amount (₹)</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style={{ border: "1px solid #e2e8f0", padding: "8px 10px" }}>
                  <div style={{ fontWeight: 600 }}>Mobile Infrastructure Rent / License Fee</div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>
                    Location: {payment.tower?.area?.name || "Goa"} · Recipient: {payment.tower?.owner?.name || "Govt. of Goa / Panchayat Treasury"}
                  </div>
                </td>
                <td style={{ border: "1px solid #e2e8f0", padding: "8px 10px", textAlign: "right", fontWeight: 700 }}>
                  ₹{amountNum.toLocaleString()}
                </td>
              </tr>
              {payment.transaction_id && (
                <tr>
                  <td style={{ border: "1px solid #e2e8f0", padding: "6px 10px", fontSize: "11.5px" }}>
                    Bank Transaction / UTR Ref: <code>{payment.transaction_id}</code>
                  </td>
                  <td style={{ border: "1px solid #e2e8f0", padding: "6px 10px", textAlign: "right", color: "#059669" }}>
                    Verified
                  </td>
                </tr>
              )}
              <tr style={{ background: "#ecfdf5", fontWeight: 800 }}>
                <td style={{ border: "1px solid #a7f3d0", padding: "9px 10px", color: "#065f46" }}>TOTAL RECEIVED</td>
                <td style={{ border: "1px solid #a7f3d0", padding: "9px 10px", textAlign: "right", color: "#065f46", fontSize: "14px" }}>
                  ₹{amountNum.toLocaleString()}
                </td>
              </tr>
            </tbody>
          </table>

          {/* Acknowledgement Statement */}
          <div
            style={{
              padding: "10px 14px",
              background: "#f1f5f9",
              borderRadius: 4,
              fontSize: "11.5px",
              color: "#334155",
              marginBottom: 28,
            }}
          >
            Received with thanks the sum of <strong>₹{amountNum.toLocaleString()}</strong> towards official telecommunication infrastructure rent and compliance dues for the stated period. This receipt serves as official proof of remittance for statutory audit purposes.
          </div>

          {/* Footer Seals */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "flex-end",
              paddingTop: 12,
            }}
          >
            <div style={{ fontSize: "10.5px", color: "#475569", fontWeight: 500 }}>
              <div>Computer Generated Official Electronic Voucher</div>
              <div>No physical signature required · Rule 12(B) Goa IT Rules</div>
            </div>

            <div style={{ textAlign: "center", minWidth: 180 }}>
              <div
                style={{
                  display: "inline-block",
                  padding: "4px 10px",
                  border: "1px dashed #059669",
                  borderRadius: 4,
                  fontSize: "10px",
                  fontWeight: 800,
                  color: "#059669",
                  marginBottom: 6,
                  textTransform: "uppercase",
                }}
              >
                ✓ Remittance Cleared
              </div>
              <div style={{ fontWeight: 800, fontSize: "11.5px", color: "#0a0f1d" }}>Treasury Officer / Accounts</div>
              <div style={{ fontSize: "10.5px", color: "#475569", fontWeight: 600 }}>DoIT, Govt. of Goa</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PaymentReceiptModal;
