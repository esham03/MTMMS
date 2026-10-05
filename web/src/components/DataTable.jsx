import React, { useState, useMemo, useEffect } from "react";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Inbox,
  X,
  Download,
} from "lucide-react";

// Helper to recursively search through primitives, arrays, and objects
const deepSearchMatch = (item, term) => {
  if (item === null || item === undefined) return false;
  if (typeof item === "string" || typeof item === "number" || typeof item === "boolean") {
    return String(item).toLowerCase().includes(term);
  }
  if (Array.isArray(item)) {
    return item.some((elem) => deepSearchMatch(elem, term));
  }
  if (typeof item === "object") {
    return Object.values(item).some((val) => deepSearchMatch(val, term));
  }
  return false;
};

export const DataTable = ({
  columns = [],
  data = [],
  searchable = true,
  searchPlaceholder = "Search records...",
  filterSlot = null,
  actionSlot = null,
  pageSize = 10,
  onRowClick = null,
  emptyMessage = "No records found.",
  isLoading = false,
  exportable = true,
  exportFilename = "MTMMS_Export",
  initialSearch = "",
  onSearchChange = null,
}) => {
  const [searchTerm, setSearchTerm] = useState(initialSearch || "");
  const [currentPage, setCurrentPage] = useState(1);
  const [sortColumn, setSortColumn] = useState(null);
  const [sortDirection, setSortDirection] = useState("asc"); // 'asc' | 'desc'

  // Sync initialSearch if prop changes (e.g. from URL search params)
  useEffect(() => {
    if (initialSearch !== undefined && initialSearch !== null) {
      setSearchTerm(initialSearch);
    }
  }, [initialSearch]);

  // Reset to page 1 whenever the data source or search term changes
  useEffect(() => {
    setCurrentPage(1);
  }, [data, searchTerm]);

  // Filter records based on deep search term
  const filteredData = useMemo(() => {
    if (!searchTerm.trim()) return data;
    const term = searchTerm.toLowerCase().trim();
    return data.filter((row) => {
      // 1. Recursive search in all fields of the row (nested objects and arrays)
      if (deepSearchMatch(row, term)) return true;

      // 2. Also check accessor or column render values if applicable
      for (const col of columns) {
        if (col.key && row[col.key] !== undefined) {
          if (deepSearchMatch(row[col.key], term)) return true;
        }
      }
      return false;
    });
  }, [data, searchTerm, columns]);

  // Sort filtered records
  const sortedData = useMemo(() => {
    if (!sortColumn) return filteredData;
    return [...filteredData].sort((a, b) => {
      let valA = a[sortColumn];
      let valB = b[sortColumn];

      if (valA === undefined || valA === null) valA = "";
      if (valB === undefined || valB === null) valB = "";

      if (typeof valA === "number" && typeof valB === "number") {
        return sortDirection === "asc" ? valA - valB : valB - valA;
      }

      const strA = String(valA).toLowerCase();
      const strB = String(valB).toLowerCase();
      if (strA < strB) return sortDirection === "asc" ? -1 : 1;
      if (strA > strB) return sortDirection === "asc" ? 1 : -1;
      return 0;
    });
  }, [filteredData, sortColumn, sortDirection]);

  // Pagination calculation
  const totalPages = Math.ceil(sortedData.length / pageSize) || 1;
  const paginatedData = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return sortedData.slice(start, start + pageSize);
  }, [sortedData, currentPage, pageSize]);

  const handleSort = (colKey) => {
    if (sortColumn === colKey) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortColumn(colKey);
      setSortDirection("asc");
    }
  };

  const handleExportCSV = () => {
    if (!sortedData || sortedData.length === 0) return;

    const exportColumns = columns.filter(
      (col) =>
        col.exportable !== false &&
        col.key !== "actions" &&
        col.title !== "Actions"
    );

    const headers = exportColumns.map(
      (c) => `"${(c.title || c.key || "").replace(/"/g, '""')}"`
    );

    const rows = sortedData.map((row) => {
      return exportColumns
        .map((col) => {
          let rawVal = row[col.key];

          if (typeof col.accessor === "function") {
            try {
              rawVal = col.accessor(row);
            } catch (_) {}
          } else if (rawVal === undefined || rawVal === null) {
            rawVal = "";
          }

          if (typeof rawVal === "object") {
            if (Array.isArray(rawVal)) {
              rawVal = rawVal
                .map((item) =>
                  typeof item === "object"
                    ? item.name || item.title || JSON.stringify(item)
                    : item
                )
                .join(", ");
            } else {
              rawVal =
                rawVal.name ||
                rawVal.title ||
                rawVal.id ||
                JSON.stringify(rawVal);
            }
          }

          const strVal = String(rawVal ?? "").replace(/"/g, '""');
          return `"${strVal}"`;
        })
        .join(",");
    });

    const csvContent = [headers.join(","), ...rows].join("\r\n");
    const blob = new Blob(["\uFEFF" + csvContent], {
      type: "text/csv;charset=utf-8;",
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    const dateStr = new Date().toISOString().split("T")[0];
    link.setAttribute("href", url);
    link.setAttribute("download", `${exportFilename}_${dateStr}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="table-wrapper">
      {/* Toolbar: Search, Filters, and Custom Action Slot */}
      <div className="table-toolbar">
        <div className="table-toolbar-left">
          {searchable && (
            <div className="table-search-wrapper">
              <Search size={15} className="table-search-icon" />
              <input
                type="text"
                className="table-search-input"
                placeholder={searchPlaceholder}
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                  if (onSearchChange) onSearchChange(e.target.value);
                }}
              />
              {searchTerm && (
                <button
                  type="button"
                  className="table-search-clear-btn"
                  onClick={() => {
                    setSearchTerm("");
                    setCurrentPage(1);
                    if (onSearchChange) onSearchChange("");
                  }}
                  title="Clear search"
                >
                  <X size={13} />
                </button>
              )}
            </div>
          )}
          {filterSlot}
        </div>

        <div
          className="table-toolbar-right"
          style={{ display: "flex", alignItems: "center", gap: 8 }}
        >
          {exportable && sortedData.length > 0 && (
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={handleExportCSV}
              title="Download filtered records as CSV spreadsheet"
            >
              <Download size={13} />
              <span>Export CSV</span>
            </button>
          )}
          {actionSlot}
        </div>
      </div>

      {/* Main Table Container */}
      <div className="data-table-container">
        <table className="data-table">
          <thead>
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key || col.title}
                  onClick={() => col.sortable !== false && handleSort(col.key)}
                  style={{
                    cursor: col.sortable !== false ? "pointer" : "default",
                    width: col.width,
                  }}
                >
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 6,
                      userSelect: "none",
                    }}
                  >
                    <span>{col.title}</span>
                    {col.sortable !== false && (
                      <span style={{ color: "var(--text-muted)", display: "inline-flex" }}>
                        {sortColumn === col.key ? (
                          sortDirection === "asc" ? (
                            <ArrowUp size={13} color="var(--primary-light)" />
                          ) : (
                            <ArrowDown size={13} color="var(--primary-light)" />
                          )
                        ) : (
                          <ArrowUpDown size={12} />
                        )}
                      </span>
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td
                  colSpan={columns.length}
                  style={{ textAlign: "center", padding: "48px 20px" }}
                >
                  <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 10 }}>
                    <div
                      style={{
                        width: 20,
                        height: 20,
                        border: "2px solid var(--primary-light)",
                        borderTopColor: "transparent",
                        borderRadius: "50%",
                        animation: "spin 0.8s linear infinite",
                      }}
                    ></div>
                    <span style={{ color: "var(--text-secondary)" }}>Loading records...</span>
                  </div>
                </td>
              </tr>
            ) : paginatedData.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length}
                  style={{ textAlign: "center", padding: "48px 20px" }}
                >
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      gap: 10,
                      color: "var(--text-muted)",
                    }}
                  >
                    <Inbox size={36} strokeWidth={1.5} />
                    <p style={{ fontSize: "0.9rem" }}>{emptyMessage}</p>
                  </div>
                </td>
              </tr>
            ) : (
              paginatedData.map((row, rowIndex) => (
                <tr
                  key={row.id || rowIndex}
                  onClick={() => onRowClick && onRowClick(row)}
                  style={{ cursor: onRowClick ? "pointer" : "default" }}
                >
                  {columns.map((col) => (
                    <td key={col.key || col.title}>
                      {col.render
                        ? col.render(row[col.key], row, rowIndex)
                        : row[col.key] ?? "-"}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination Footer */}
      {!isLoading && sortedData.length > 0 && (
        <div className="table-pagination">
          <div>
            Showing{" "}
            <strong>{(currentPage - 1) * pageSize + 1}</strong> to{" "}
            <strong>{Math.min(currentPage * pageSize, sortedData.length)}</strong> of{" "}
            <strong>{sortedData.length}</strong> entries
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <button
              className="btn btn-secondary btn-sm"
              disabled={currentPage === 1}
              onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
            >
              <ChevronLeft size={14} /> Previous
            </button>
            <span style={{ padding: "0 8px", fontSize: "0.85rem" }}>
              Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong>
            </span>
            <button
              className="btn btn-secondary btn-sm"
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
            >
              Next <ChevronRight size={14} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default DataTable;
