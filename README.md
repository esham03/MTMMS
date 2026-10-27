# MTMMS — Mobile Tower Monitoring and Management System

<p align="center">
  <img src="web/public/goa-emblem.png" width="100" alt="Government of Goa Emblem" />
</p>

<p align="center">
  <strong>Department of Information Technology, Electronics & Communications</strong><br>
  <em>Government of Goa</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square" alt="Status" />
  <img src="https://img.shields.io/badge/Backend-Django%205.x%20%7C%20DRF-092E20?style=flat-square&logo=django" alt="Django" />
  <img src="https://img.shields.io/badge/Frontend-React%2019%20%7C%20Vite-61DAFB?style=flat-square&logo=react" alt="React" />
  <img src="https://img.shields.io/badge/Desktop-Electron-47848F?style=flat-square&logo=electron" alt="Electron" />
  <img src="https://img.shields.io/badge/Mobile-Flutter%20%7C%20Dart-02569B?style=flat-square&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Database-MySQL-4479A1?style=flat-square&logo=mysql" alt="MySQL" />
  <img src="https://img.shields.io/badge/License-Proprietary%20%2F%20Govt%20of%20Goa-blue?style=flat-square" alt="License" />
</p>

---

## 📋 Overview

The **Mobile Tower Monitoring and Management System (MTMMS)** is an enterprise-grade digital governance platform developed for the **Department of Information Technology, Government of Goa**. 

It provides end-to-end administration, geospatial mapping, tenancy monitoring, and statutory fee compliance for all telecommunications infrastructure across North Goa and South Goa districts.

### Key Capabilities
- **📡 Telecom Tower Registry**: Comprehensive database of mobile towers, ground/rooftop classifications, structural attributes, and geographical coordinates.
- **🏢 Multi-Tenant Infrastructure Tracking**: Management of licensed telecom operators (Jio, Airtel, Vi, BSNL) sharing infrastructure across government and private lands.
- **💰 Statutory Rent & Arrears Engine**: Automated computation of annual rents, 5% late surcharges, municipal dues, and generation of official **Form VII Statutory Rent Demand Notices**.
- **🗺️ Interactive GIS Mapping**: Real-time Leaflet map visualization of tower locations, district/taluka distributions, and compliance statuses.
- **📱 Any-Network Field Operations**: Seamless field officer mobile app functioning on local Wi-Fi hotspots and across 4G/5G cellular data anywhere in the state.
- **🖥️ Desktop Administrative Suite**: High-performance Electron desktop portal for nodal telecom officers and IT administrators.

---

## 🏗️ Architecture & Technology Stack

```
                               ┌──────────────────────────────────────────────┐
                               │             MTMMS System Gateway             │
                               │           (Start-Live-System.bat)            │
                               └───────┬──────────────────────────────┬───────┘
                                       │                              │
                     [Local Network / Wi-Fi / Hotspot]    [Global Cloud Tunnel (4G/5G)]
                                       │                              │
                     ┌─────────────────┴─────────────────┐            │
                     ▼                                   ▼            ▼
       ┌───────────────────────────┐       ┌───────────────────────────────┐
       │     React / Vite Web      │       │      Flutter Mobile App       │
       │   (http://<IP>:5174)      │       │     (Android Release APK)     │
       └─────────────┬─────────────┘       └──────────────┬────────────────┘
                     │                                    │
                     └─────────────────┬──────────────────┘
                                       ▼
                       ┌───────────────────────────────┐
                       │     Django REST Framework     │
                       │          (Port 8000)          │
                       └───────────────┬───────────────┘
                                       │
                      ┌────────────────┴────────────────┐
                      ▼                                 ▼
       ┌───────────────────────────────┐ ┌───────────────────────────────┐
       │        MySQL Database         │ │    Multi-Subnet Discovery     │
       │      (Database: mtmms)        │ │         (UDP 41588)           │
       └───────────────────────────────┘ └───────────────────────────────┘
```

| Layer | Technology | Key Components |
|---|---|---|
| **Backend API** | Python 3.12 / Django 5.x | Django REST Framework, JWT Auth, CORS Headers, Network Utilities |
| **Web Portal** | React 19, Vite, Leaflet | Tailwind-free Vanilla CSS Design System, GIS Tower Map, Notice Generator |
| **Desktop App** | Electron 44 | Standalone executable (`MTMMS Desktop.exe`), local zero-latency loopback |
| **Mobile App** | Flutter 3.x / Dart | Multi-subnet UDP auto-discovery, manual IP/Cloud URL connect, offline cache |
| **Database** | MySQL / MariaDB | Relational schema (`mtmms.sql`) covering towers, owners, operators, payments |
| **Networking** | Node.js, UDP Sockets | Dynamic IP detection, UDP port 41588 beacon, automated HTTPS cloud tunnel |

---

## 🌐 Multi-Network Connectivity

MTMMS includes built-in multi-network support so that services operate seamlessly across any network environment:

1. **Local Wi-Fi & Hotspots (Same Network)**:
   - The server dynamically detects active IPv4 network adapters (Wi-Fi, Ethernet, Mobile Hotspots).
   - The built-in UDP Discovery Service broadcasts server availability on port **41588** across all active subnets.
   - The Flutter mobile app automatically discovers and connects to the server with zero manual configuration.
2. **Global Cloud Access (4G / 5G / Remote Wi-Fi)**:
   - Built-in secure HTTPS cloud tunnel (`web/tunnel.cjs`) exposes the API over public HTTPS.
   - Field officers on cellular mobile data or remote networks can connect instantly by selecting **"Connect via Cloud / Manual IP"** and entering the cloud URL.
3. **Local PC Access (Zero-Latency Loopback)**:
   - The Web Portal (`http://localhost:5174`) and Desktop Application connect via loopback (`127.0.0.1:8000`) to guarantee instant response and avoid router NAT hairpinning dropouts.

---

## 🚀 Quick Start Guide

### Prerequisites
- **Windows 10 / 11 (64-bit)**
- **Python 3.10+** (Added to PATH)
- **Node.js 18+** & **npm**
- **MySQL / MariaDB Service** running locally on port 3306 with database `mtmms` imported from [`mtmms.sql`](file:///c:/MTMMS/mtmms.sql)

### 1. Launch the System
In the project root directory, double-click:
```bat
Start-Live-System.bat
```
The launcher will automatically:
1. Verify toolchains (Python, Pip, Node.js, npm).
2. Validate required Python packages and Node dependencies.
3. Verify MySQL database connectivity.
4. Detect the active LAN IP and configure environment variables.
5. Start the Django REST API on port `8000`.
6. Start the UDP Multi-Subnet Discovery Service on port `41588`.
7. Start the React/Vite Web Portal on port `5174`.
8. Start the Global Cloud Tunnel for 4G/5G access.
9. Display the interactive service control console:

```text
================================================================
            MTMMS MULTI-NETWORK SYSTEM READY
================================================================

[1] LOCAL WI-FI / HOTSPOT ACCESS (Same Wi-Fi Network):
    • Server IP:      172.20.10.3
    • Web Portal:     http://172.20.10.3:5174
    • REST API:       http://172.20.10.3:8000/api
    • Discovery:      UDP Port 41588 (Active on all subnets)

[2] GLOBAL CLOUD ACCESS (ANY Network: 4G, 5G, Remote Wi-Fi):
    • Cloud Web:      https://<subdomain>.loca.lt
    • Cloud API:      https://<subdomain>.loca.lt/api

================================================================
 ANDROID APP COMPATIBILITY:
  • Same Wi-Fi:   App automatically discovers this PC instantly
  • 4G/5G/Remote: Enter or paste the Cloud API URL in the app
================================================================

Options:
  [1] Open Web Application on this PC (localhost)
  [2] Launch Electron Desktop Application
  [3] Test API Health Check Endpoint
  [4] Refresh Network & Cloud Tunnel Status
  [5] Configure Windows Firewall (Run as Admin)
  [6] Stop / Shutdown All MTMMS Services
  [Q] Quit Launcher Menu (Leave Services Running)
```

---

## 🔑 Default Administrator Credentials

| Field | Value |
|---|---|
| **Email** | `admin@goa.gov.in` |
| **Password** | `Admin@1234` |
| **Role** | System Administrator (DoIT Goa) |

---

## 📱 Mobile App (Android)

The compiled release APK is included in the repository:
- **Root Path:** [`MTMMS.apk`](file:///c:/MTMMS/MTMMS.apk) (~55.5 MB)
- **App Directory:** [`mobile_tower_app/app-release.apk`](file:///c:/MTMMS/mobile_tower_app/app-release.apk)

### Connection Modes:
1. **On Same Wi-Fi / Hotspot:** Open the app — the auto-discovery engine locates the server automatically.
2. **On 4G/5G Cellular Data:** Tap **"Connect via Cloud / Manual IP"** on the splash or login screen, paste the active Cloud API URL (`https://<subdomain>.loca.lt/api`), and tap **Connect**.

---

## 📊 Project Presentation & Viva Defense

The repository includes the official project presentation for review and evaluation:
- **Presentation File:** [`Final_Project_Presentation.pptx`](file:///c:/MTMMS/Final_Project_Presentation.pptx) (~900 KB)
- **Format:** 12 slides, clean academic white theme, structured for university evaluation and departmental review.
- **Coverage:** Problem statement, statutory Right-of-Way (RoW) framework, enterprise 4-tier architecture, 3NF schema, UDP discovery, GIS mapping, Form VII statutory notices, individual contributions, and QA validation.

---

## 📸 Verified Application Screenshots

High-resolution application screenshots demonstrating live system modules:
- **[01. System Login](screenshots/01_login.png):** Secure portal authentication with SimpleJWT bearer issuance.
- **[02. Executive Dashboard](screenshots/02_dashboard.png):** Real-time infrastructure statistics, district roll-ups, and operator breakdown.
- **[03. Tower Asset Registry](screenshots/03_tower_registry.png):** Comprehensive tower dossiers, structural heights, and carrier tenancy.
- **[04. GIS Spatial Map View](screenshots/04_gis_map_view.png):** Interactive Leaflet map with GPS coordinates (Ponda Police Station premises).
- **[05. Rent & Lease Management](screenshots/05_rent_management.png):** Annual lease rent engine, statutory 5-year cycles, and payment ledgers.
- **[06. Form VII Statutory Notice](screenshots/06_form_vii_notice.png):** Auto-generated Goa Government demand notice with 5% statutory late surcharge.
- **[07. 4-Tier Location Browser](screenshots/07_location_hierarchy.png):** District → Constituency → Taluka → Area hierarchical drilldown across 101 Goa areas.
- **[08. Operator Co-Location](screenshots/08_operators.png):** Multi-tenant carrier tracking (Airtel, Jio, Vi, BSNL) sharing physical infrastructure.
- **[09. Reports & Analytics](screenshots/09_reports_analytics.png):** Exportable compliance ledgers and revenue audit reports.

---

## 📁 Repository Structure

```
c:\MTMMS
├── Final_Project_Presentation.pptx # Official 12-slide project presentation
├── Start-Live-System.bat         # Main launcher for all MTMMS services
├── Stop-System.bat               # Clean shutdown script for all services
├── Launch-Desktop-App.bat        # Standalone Electron desktop app launcher
├── Setup-Firewall.bat            # Windows Firewall rules configuration
├── start-desktop-dev.bat         # Electron desktop development launcher
├── NETWORK_SETUP.md              # Detailed network switching & troubleshooting guide
├── mtmms.sql                     # Full MySQL 3NF schema and initial seed data
├── MTMMS.apk                     # Precompiled Android release APK (~55.5 MB)
├── .mtmms-runtime.env            # Active runtime network configuration
│
├── screenshots/                  # Verified live application screenshots (01–09)
│
├── mtmms_api/                    # Django REST API Backend (Python 3.12 / Django 5.1)
│   ├── manage.py
│   ├── requirements.txt          # Python dependencies
│   ├── network_utils.py          # Multi-adapter detection & health checks
│   ├── discovery_service.py      # UDP 41588 broadcast discovery daemon
│   ├── mtmms_project/            # Project configuration & settings
│   └── apps/                     # 9 Modular Django applications:
│       ├── towers/               # Tower structural specifications & coordinates
│       ├── locations/            # 4-tier hierarchy (District → Taluka → Area)
│       ├── operators/            # Telecom carriers (Airtel, Jio, Vi, BSNL)
│       ├── owners/               # Landowner profiles (Government & Private)
│       ├── rent_payments/        # Financial lease ledgers & arrears
│       ├── reports/              # Custom reporting and statutory exports
│       ├── dashboard/            # Executive KPI statistics
│       ├── users/                # Administrative user management
│       └── auth_app/             # SimpleJWT token authentication
│
├── web/                          # React 19 Web & Electron Desktop Frontend
│   ├── package.json
│   ├── vite.config.js
│   ├── tunnel.cjs                # HTTPS cloud tunnel service (Localtunnel)
│   ├── electron/                 # Electron main and preload processes
│   ├── dist/                     # Compiled production web bundle
│   ├── dist-desktop/             # Standalone MTMMS Desktop.exe executable
│   └── src/
│       ├── api/api.js            # Centralized dynamic multi-network API client
│       ├── context/              # Authentication & App state management
│       ├── pages/                # Dashboard, Towers, Rent, Notice Generator, Login
│       └── components/           # UI components, Leaflet Map, Navigation
│
└── mobile_tower_app/             # Flutter Native Android Application
    ├── pubspec.yaml
    ├── app-release.apk           # Compiled release Android binary
    └── lib/
        ├── config/               # Server configuration endpoints
        ├── services/             # UDP auto-discovery & REST communication
        └── screens/              # Splash, Login, Tower Map, Inspection Audits
```

---

## 🛠️ Management & Troubleshooting Commands

### Stop All Services
Double-click [`Stop-System.bat`](file:///c:/MTMMS/Stop-System.bat) or select option **`[6]`** from the launcher menu.

### Windows Firewall Configuration
If client devices cannot reach the host PC on local Wi-Fi, run [`Setup-Firewall.bat`](file:///c:/MTMMS/Setup-Firewall.bat) as Administrator to allow TCP ports `8000`, `5174`, `5173`, and UDP port `41588`.

### API Health Check
Test backend availability directly:
```bash
python mtmms_api/network_utils.py health http://127.0.0.1:8000/api/health/
```

---

## 👨‍💻 Project Authorship & Mentorship

- **Developer:** **Esham Uday Chari** (Roll No: 23B-IT-503)  
  *Department of Information Technology, Goa College of Engineering (GEC), Farmagudi, Ponda, Goa*
- **Department Mentor:** **Ms. Soniya Usgaonkar**  
  *Department of Information Technology, Electronics & Communications (DoIT), Government of Goa*
- **Academic Year:** 2026–2027

---

## 📄 License & Ownership

**Government of Goa — Department of Information Technology, Electronics & Communications.**  
All rights reserved. Proprietary software developed for official state governance and telecommunications infrastructure regulation.
