# MTMMS Web Portal & Desktop Suite

**Mobile Tower Monitoring & Management System (MTMMS)**  
*Department of Information Technology, Government of Goa*  
*Project by: Esham Uday Chari (Roll No: 23B-IT-503) | Mentor: Ms. Soniya Usgaonkar*

---

## 1. Overview

The **MTMMS Web Portal & Desktop Suite** is the central command center for administrative officers, DoIT executives, and infrastructure managers. It provides comprehensive GIS mapping, real-time telemetry analytics, inventory management, telecom operator tracking, and financial lease accounting across all mobile towers in the State of Goa.

The application is built as a single responsive codebase that runs both as a modern high-performance **Web SPA (Single Page Application)** in any browser and as a native **Windows Desktop Application** packaged via Electron.

---

## 2. Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend Framework** | React 19 (`react`, `react-dom` 19.2) | Component architecture with modern hooks |
| **Build Tool & Dev Server** | Vite 8 (`vite` 8.2) | Instant HMR, optimized ES-module bundling |
| **Routing** | React Router DOM 7 (`react-router-dom` 7.18) | Client-side declarative routing and protected routes |
| **GIS & Spatial Mapping** | Leaflet 1.9.4 (`leaflet`) | Interactive OpenStreetMap rendering, custom tower markers |
| **UI Design System** | Vanilla CSS (Tailored Design System) | Glassmorphism, CSS variables, dark/light harmonious palette |
| **Icons & Visuals** | Lucide React (`lucide-react` 1.33) | Vector icon set |
| **HTTP Client** | Axios (`axios` 1.19) | REST client with automatic JWT bearer injection |
| **Desktop Runtime** | Electron 44 (`electron` 44.5) | Native desktop windowing, system tray, and packaging |
| **Packaging Tools** | Electron Builder & Electron Packager | Automated NSIS installers and standalone portable binaries |
| **Cloud Tunneling** | LocalTunnel (`localtunnel` 2.0) | Zero-configuration public HTTPS tunnels for 4G/5G mobile access |

---

## 3. Key Modules & Features

1. **Executive Dashboard (`/dashboard`)**:
   - Real-time KPIs: Total Towers, Operational Active, Maintenance Required, Under Construction.
   - Financial Summaries: Total Rent Disbursed, Pending Payments, Monthly Run-rates.
   - Status Breakdown Charts and Operator Distribution Breakdown.
   - Quick-action shortcuts and recent audit activity feed.

2. **Interactive GIS Map (`/map`)**:
   - Geospatial mapping of all towers across North Goa and South Goa.
   - Dynamic filtering by Taluka, Operator (Jio, Airtel, Vi, BSNL), Status, and Tower Type (Ground-Based GBT, Roof-Top RTP, Cell-on-Wheels COW).
   - Interactive popups with live tower health, height, coordinates, owner, and rent status.
   - Direct navigation to full tower detail views from map pins.

3. **Tower Inventory Management (`/towers`)**:
   - Complete CRUD operations for mobile towers.
   - Granular technical specifications: structural height (m), mounting type, generator backup, power source.
   - Geospatial coordinates (latitude, longitude) with address and ward mapping.
   - Search, multi-field filters, and paginated records table.

4. **Landowner & Premises Registry (`/owners`)**:
   - Profiles of private and government premises owners hosting mobile towers.
   - Contact details, identity proofs, and bank disbursement accounts.
   - Active lease agreements, contract start/end dates, and escalation clauses.

5. **Rent & Lease Financial Accounting (`/rent-payments`)**:
   - Monthly lease tracking and accruals.
   - Status categorization: Paid, Pending, Overdue.
   - Invoice and receipt generation with transaction reference logging.

6. **Telecom Operator Management (`/operators`)**:
   - Registry of authorized telecom operators (Reliance Jio, Bharti Airtel, Vodafone Idea, BSNL).
   - Nodal officer contact information, active license permits, and total tenancy counts.

7. **System Reports & Audit (`/reports`)**:
   - Filterable data reporting by taluka, operator, structural status, and date range.
   - Compliance auditing and inspection readiness records.

---

## 4. Directory Structure

```
web/
├── dist/                     # Optimized production web bundle (generated)
├── dist-desktop/             # Standalone Windows desktop package (generated)
├── electron/
│   ├── main.cjs              # Electron main process (lifecycle, IPC, window management)
│   └── preload.cjs           # Secure context-bridge preload script
├── public/                   # Static assets, logos, and favicon
├── src/
│   ├── assets/               # Local icons, branding assets, images
│   ├── components/           # Reusable UI components (Navbar, Sidebar, Modal, Card, Table)
│   ├── context/              # React Context providers (AuthContext, ThemeContext)
│   ├── pages/                # Route pages (Dashboard, Map, Towers, Owners, Rent, Login)
│   ├── services/             # Axios API client, auth service, token storage
│   ├── styles/               # Design system stylesheets, CSS variables, utility classes
│   ├── App.jsx               # Main application router and layout hierarchy
│   ├── index.css             # Core design tokens, typography, reset rules
│   └── main.jsx              # React 19 application entry point
├── package.json              # Dependencies and build scripts
├── tunnel.cjs                # Cloud tunnel service script
└── vite.config.js            # Vite configuration and server proxy rules
```

---

## 5. Getting Started & Development

### Prerequisites
- Node.js (v18.0.0 or higher recommended)
- npm (v9.0.0 or higher)

### Installation
```bash
cd web
npm install
```

### Running the Web Application
Start the Vite development server with Hot Module Replacement (HMR):
```bash
npm run dev
```
The application will be accessible at:
- Local browser: `http://localhost:5174`
- Network devices (same Wi-Fi): `http://<YOUR_LOCAL_IP>:5174`

### Running the Electron Desktop Client
Launch the application inside a native Electron desktop window:
```bash
npm run electron:start
```
Or run Vite and Electron concurrently during active development:
```bash
npm run electron:dev
```

### Building for Production
Create the optimized static production web bundle in `dist/`:
```bash
npm run build
```
Preview the production build locally:
```bash
npm run preview
```

### Packaging the Windows Desktop Application
Build the standalone Windows x64 desktop binary:
```bash
npm run pack:win
```
The executable application will be created in:
```
web/dist-desktop/MTMMS Desktop-win32-x64/MTMMS Desktop.exe
```

---

## 6. Multi-Network & Cloud Tunnel Integration

The web frontend includes a zero-configuration cloud tunnel utility (`tunnel.cjs`) powered by LocalTunnel. This allows remote field officers and mobile phones on 4G/5G mobile data to securely connect to the web portal without port forwarding or static public IPs.

To launch the tunnel manually:
```bash
npm run tunnel
```
This prints a public HTTPS endpoint (e.g., `https://<subdomain>.loca.lt`) that routes traffic directly to the local Vite web portal and Django REST API.
