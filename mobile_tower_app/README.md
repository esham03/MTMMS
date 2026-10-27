# MTMMS Mobile Application (Android Native)

**Mobile Tower Monitoring & Management System (MTMMS)**  
*Department of Information Technology, Government of Goa*  
*Project by: Esham Uday Chari (Roll No: 23B-IT-503) | Mentor: Ms. Soniya Usgaonkar*

---

## 1. Overview

The **MTMMS Mobile Application** is an enterprise field-inspection and real-time tower audit tool built for on-site field officers, technical inspectors, and DoIT survey teams. Developed using **Flutter & Dart**, the app enables field personnel to locate nearby mobile towers, capture live GPS coordinates, conduct on-site physical audits, review lease agreement details with landowners, and track monthly rent disbursements directly in the field.

The app is engineered with **Dual-Path Network Portability**:
1. **Local Zero-Config Auto-Discovery**: When connected to the same Wi-Fi router or laptop mobile hotspot as the host PC, the app automatically discovers the server via UDP broadcast beacons on port `41588` and multi-subnet sweeps.
2. **Global Cloud Tunneling (4G / 5G)**: When officers are deployed in the field on cellular data, the app connects directly via secure cloud HTTPS endpoints without requiring VPNs or local network sharing.

---

## 2. Technology Stack & Packages

| Component | Package / Technology | Purpose |
|---|---|---|
| **Framework** | Flutter 3.x / Dart 3.13+ | Cross-platform high-performance native compiled UI |
| **Design Language** | Material Design 3 | Harmonious theme, modern typography, elevation tokens |
| **GIS & Mapping** | `flutter_map: ^8.3.2` + `latlong2: ^0.10.1` | Native OpenStreetMap rendering, custom tower markers, radius visualizer |
| **Biometric Security** | `local_auth: ^2.3.0` | Fingerprint & Face ID authentication via Android BiometricPrompt |
| **Secure Storage** | `flutter_secure_storage: ^9.2.4` | Encrypted hardware keystore storage for JWT tokens |
| **Persistent Cache** | `shared_preferences: ^2.5.5` | Fast local caching of server URLs, preferences, and session data |
| **HTTP Networking** | `http: ^1.6.0` | REST API communication with automated Bearer token injection |
| **Analytics Charts** | `fl_chart: ^1.2.0` | Mobile-optimized trend charts, tower status distribution graphs |
| **Typography** | `google_fonts: ^8.2.1` | Inter / Poppins clean modern typography |

---

## 3. Key Capabilities & Mobile Screens

1. **Auto-Discovery & Dynamic Server Switcher (`splash_screen.dart`, `login_screen.dart`)**:
   - Broadcasts and listens for UDP beacons across `255.255.255.255:41588`.
   - Concurrent subnet ping scanner as an automatic fallback.
   - Manual Cloud API configuration modal with one-tap connection testing.
   - Remembers the last validated server endpoint across app restarts.

2. **Secure Authentication & Biometrics (`login_screen.dart`)**:
   - SimpleJWT authentication with role validation.
   - Quick unlock via fingerprint / biometrics for authenticated officers.

3. **Field Dashboard (`dashboard_screen.dart`)**:
   - Quick KPI cards: Total Towers, Operational, Maintenance Alerts, Pending Audits.
   - Interactive breakdown charts for quick status overview.
   - Quick-action shortcuts: Find Nearby Towers, Add New Tower, View Overdue Rents.

4. **Interactive Field Map (`map_view_screen.dart`)**:
   - Live GPS location pinning with compass alignment.
   - Radius visualization showing all towers within 1 km, 5 km, or 10 km.
   - Filter towers by operator, status, or structural type.
   - Tap-to-inspect popup with direct navigation actions.

5. **Tower Registry & Field Audit (`tower_management_screen.dart`, `add_edit_tower_screen.dart`)**:
   - Complete inventory search and filter by taluka/panchayat.
   - On-site GPS coordinate verification: compares phone's live GPS reading with registered tower coordinates.
   - Update operational status (Active, Maintenance Required, Inactive).
   - Record structural attributes (Height, Ground/Roof mount, Backup generator).

6. **Landowner & Lease Verification (`owners/`, `rent_management_screen.dart`)**:
   - Search landowners associated with specific tower sites.
   - Verify agreement tenure dates and escalation terms on site.
   - Review payment history and pending rental disbursements.

7. **Officer Profile & Settings (`officer_profile_screen.dart`, `system_settings_screen.dart`)**:
   - Officer credentials, assigned taluka/region, and active session management.
   - Server connectivity diagnostics and cache management.

---

## 4. Directory Structure

```
mobile_tower_app/
├── android/                  # Native Android gradle configuration & manifest
├── assets/
│   └── images/               # App icons, splash artwork, and branding assets
├── lib/
│   ├── config/               # API endpoints, network constants, and environment config
│   ├── models/               # Strongly-typed Dart data models (Tower, Owner, RentPayment, User)
│   ├── screens/              # 18 specialized screen views and workflows
│   │   ├── owners/           # Landowner management screens
│   │   ├── towers/           # Tower detail and editing views
│   │   ├── dashboard_screen.dart
│   │   ├── map_view_screen.dart
│   │   ├── login_screen.dart
│   │   ├── splash_screen.dart
│   │   └── ...
│   ├── services/             # API client, UDP discovery engine, Auth & Biometrics, Storage
│   ├── theme/                # Material Design 3 color palette and typography
│   ├── widgets/              # Reusable UI widgets (cards, metric chips, filter sheets)
│   └── main.dart             # Application entry point and route initialization
└── pubspec.yaml              # Package dependencies and asset configurations
```

---

## 5. Build & Deployment Instructions

### Prerequisites
- Flutter SDK (v3.13.0 or higher)
- Android Studio / Android SDK (API Level 34 / Android 14 target)
- Java Development Kit (JDK 17)

### 1. Install Dependencies
```bash
cd mobile_tower_app
flutter pub get
```

### 2. Run in Debug Mode (USB Debugging / Emulator)
Connect your Android phone via USB with USB Debugging enabled, then run:
```bash
flutter run
```

### 3. Build Production Release APK
Generate an optimized, standalone release APK:
```bash
flutter build apk --release
```
The compiled APK will be output to:
```
mobile_tower_app/build/app/outputs/flutter-apk/app-release.apk
```

### 4. Direct Standalone Sideloading
A precompiled, production-ready APK is maintained at the root of the project:
```
MTMMS.apk
```
You can transfer this single file directly to any Android smartphone via USB, WhatsApp, or Google Drive, and install it instantly without needing Android Studio or Flutter installed.

---

## 6. How to Connect in the Field

### When on the Same Wi-Fi / Hotspot:
1. Turn on Wi-Fi on your phone and connect to the host computer's network or hotspot.
2. Launch **MTMMS**.
3. The UDP auto-discovery service discovers the server in under 2 seconds and opens the login screen automatically.

### When on Cellular Data (4G / 5G):
1. Launch **MTMMS**.
2. Tap the **Server** icon in the top-right corner of the login screen.
3. Enter or paste the active Cloud API URL displayed in the server launcher (e.g., `https://<subdomain>.loca.lt/api`).
4. Tap **Test & Connect** — the app immediately locks onto the cloud endpoint and authenticates securely.
