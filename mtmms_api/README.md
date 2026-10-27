# MTMMS REST API Backend

**Mobile Tower Monitoring & Management System (MTMMS)**  
*Department of Information Technology, Government of Goa*  
*Project by: Esham Uday Chari (Roll No: 23B-IT-503) | Mentor: Ms. Soniya Usgaonkar*

---

## 1. Overview

The **MTMMS REST API Backend** is the core enterprise service layer powering both the Web Portal / Desktop Suite and the Native Android Mobile Application. Built on **Python 3.12** and **Django 5.1** using **Django REST Framework (DRF)**, it provides high-throughput, secure, and transactional RESTful endpoints backed by a relational **MySQL (3NF Normalized)** database.

The backend also incorporates custom network automation engines:
- **UDP Broadcast Auto-Discovery Daemon (`discovery_service.py`)**: Enables instant zero-configuration mobile device discovery on port `41588`.
- **Multi-Adapter Network Detection Engine (`network_utils.py`)**: Automatically detects active network interfaces (Wi-Fi, Ethernet, Hotspot) and dynamically binds server endpoints.

---

## 2. Technology Stack & Dependencies

| Layer | Component | Version / Library | Purpose |
|---|---|---|---|
| **Runtime** | Python | 3.12+ | Clean, high-performance backend execution |
| **Framework** | Django | 5.1 | Enterprise web framework and ORM |
| **API Layer** | Django REST Framework | 3.15.2 | RESTful serializers, viewsets, and permissions |
| **Authentication** | SimpleJWT | 5.3.1 | JSON Web Token (JWT) access & refresh lifecycle |
| **CORS** | Django CORS Headers | 4.4.0 | Cross-Origin Resource Sharing for Web & Mobile |
| **Database Client**| MySQLclient | 2.2.4 | High-performance native C connector for MySQL |
| **Database** | MySQL / MariaDB | 8.x / 10.x | 3NF normalized relational database (`mtmms`) |
| **Environment** | Python Dotenv | 1.0.1 | Configuration management via `.env` |
| **WSGI Server** | Gunicorn / WhiteNoise | 21.2 / 6.6 | Production WSGI runtime and static asset hosting |

---

## 3. Modular App Architecture

The backend is organized into **9 domain-driven modular apps** located under `apps/`:

```
mtmms_api/
├── apps/
│   ├── auth_app/         # SimpleJWT authentication, token refresh, officer login/logout
│   ├── dashboard/        # High-performance analytics, KPI counters, and status aggregations
│   ├── locations/        # Spatial hierarchy: Districts, Talukas, Panchayats, Villages, Wards
│   ├── operators/        # Telecom cellular carriers (Jio, Airtel, Vi, BSNL) & licenses
│   ├── owners/           # Landowners / premises hosts, agreement tenures, bank details
│   ├── rent_payments/    # Monthly lease payments, payment statuses, invoices, receipts
│   ├── reports/          # Data audit exports, compliance summaries, PDF/Excel generation
│   ├── towers/           # Core mobile tower registry, coordinates, height, status, photos
│   └── users/            # Role-based user management (Admin, Officer, Inspector, Auditor)
├── mtmms_project/        # Root project configuration (settings.py, urls.py, wsgi.py)
├── discovery_service.py  # Multi-threaded UDP discovery daemon (port 41588)
├── network_utils.py      # Dynamic network interface detection & binding engine
├── manage.py             # Django management CLI
├── requirements.txt      # Python dependencies manifest
└── start.bat             # Standalone API startup script
```

### Module Descriptions:

1. **`apps/auth_app`**:
   - Manages user authentication using JSON Web Tokens (JWT).
   - Generates cryptographically signed access tokens and refresh tokens.
   - Enforces role validation across endpoints.

2. **`apps/dashboard`**:
   - Aggregates system metrics in a single low-latency call.
   - Computes total towers, active operational counts, pending maintenance issues, and revenue metrics.
   - Supplies data for frontend visual charts (operator distribution, taluka breakdown).

3. **`apps/locations`**:
   - Models the administrative geography of Goa:
     - North Goa & South Goa Districts.
     - 12 Talukas (Bardez, Tiswadi, Salcete, Ponda, Mormugao, etc.).
     - Local Village Panchayats, Municipal Councils, and Ward numbers.

4. **`apps/operators`**:
   - Manages authorized telecom service providers (Reliance Jio, Bharti Airtel, Vodafone Idea, BSNL).
   - Stores nodal officer contacts, operating frequency bands, and total deployed tenancies.

5. **`apps/owners`**:
   - Maintains records of private citizens, commercial establishments, and government bodies that lease land/rooftops for towers.
   - Stores bank details (Account number, IFSC) for direct lease disbursement.
   - Tracks agreement validity periods and escalation terms.

6. **`apps/rent_payments`**:
   - Automated monthly rental accruals based on active lease contracts.
   - Status tracking: `Paid`, `Pending`, `Overdue`.
   - Records transaction reference numbers, payment mode (NEFT/RTGS), and receipt metadata.

7. **`apps/reports`**:
   - Provides filtered queries across towers, financial statements, and compliance audits.
   - Generates audit-ready reports exportable to PDF, Excel, and CSV formats.

8. **`apps/towers`**:
   - The primary physical asset registry.
   - Fields: Unique Tower Code, Structure Type (`GBT` - Ground-Based Tower, `RTP` - Roof-Top Pole, `COW` - Cell On Wheels), Height in meters, Installation Date, Power Backup, Operational Status (`Active`, `Maintenance`, `Inactive`).
   - Spatial Coordinates: Precise Latitude and Longitude for GIS mapping and GPS radius queries.

9. **`apps/users`**:
   - Granular Role-Based Access Control (RBAC):
     - `Superadmin`: Full system configuration and user management.
     - `DoIT Officer`: Statewide monitoring, approvals, and financial overview.
     - `Field Inspector`: On-site inspections, GPS verification, status updates.
     - `Auditor`: Read-only access to logs, reports, and payments.

---

## 4. Network Daemons & Automation

### 1. UDP Auto-Discovery Service (`discovery_service.py`)
To eliminate the need for field officers to manually find or type IP addresses:
- Listens on UDP port `41588` across `0.0.0.0`.
- Periodically broadcasts discovery packets (`MTMMS_DISCOVER:<IP>:<PORT>`) across `255.255.255.255` and local subnet broadcast addresses.
- Answers incoming `MTMMS_PING` datagrams from mobile devices with an immediate signed response containing the host API URL.

### 2. Multi-Adapter IP Detection (`network_utils.py`)
- Automatically enumerates all network interfaces using Windows sockets and system commands.
- Prioritizes active Wi-Fi adapters, Ethernet connections, and Mobile Hotspot interfaces while filtering out inactive virtual loopbacks.
- Exposes clean helper methods used by `Start-Live-System.bat` to rebind server URLs instantly.

---

## 5. API Endpoints Reference

All endpoints are prefixed with `/api/`:

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/auth/login/` | Obtain JWT access and refresh token pair | No |
| `POST` | `/api/auth/refresh/` | Refresh expired access token | No |
| `GET` | `/api/dashboard/stats/` | System-wide counts, financial KPIs, and charts | Yes |
| `GET`, `POST` | `/api/towers/` | List towers (with filters) / Register new tower | Yes |
| `GET`, `PUT`, `DELETE` | `/api/towers/<id>/` | View, update, or remove a specific tower | Yes |
| `GET` | `/api/towers/nearby/` | Spatial query for towers within a GPS radius | Yes |
| `GET`, `POST` | `/api/locations/` | List or create administrative location hierarchies | Yes |
| `GET`, `POST` | `/api/operators/` | List or register telecom operators | Yes |
| `GET`, `POST` | `/api/owners/` | Manage landowners and premises lease profiles | Yes |
| `GET`, `POST` | `/api/rent-payments/` | View and record monthly rent disbursements | Yes |
| `GET` | `/api/reports/summary/` | Retrieve filtered audit and compliance records | Yes |
| `GET`, `POST` | `/api/users/` | Manage system users and role permissions | Yes (Admin) |

---

## 6. Installation & Setup

### Prerequisites
- Python 3.12 or higher
- MySQL Server 8.0+ or MariaDB 10.5+
- Visual C++ Build Tools (required for compiling `mysqlclient` on Windows)

### 1. Create and Activate Virtual Environment
```bash
cd mtmms_api
python -m venv .venv
.venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Environment Configuration
Create a `.env` file in `mtmms_api/` (copied from `.env.example`):
```env
DEBUG=True
SECRET_KEY=your-secure-secret-key-here
DB_NAME=mtmms
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_HOST=127.0.0.1
DB_PORT=3306
ALLOWED_HOSTS=*
CORS_ALLOW_ALL_ORIGINS=True
```

### 4. Database Setup & Migrations
Ensure your MySQL service is running and create the database:
```sql
CREATE DATABASE mtmms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
Import the production seed data:
```bash
mysql -u root -p mtmms < ../mtmms.sql
```
Or apply Django migrations:
```bash
python manage.py migrate
```

### 5. Running the Backend Server
Start the Django development server on all interfaces:
```bash
python manage.py runserver 0.0.0.0:8000
```

To run concurrently with the UDP auto-discovery service:
```bash
python manage.py run_with_discovery
```
Or use the universal master launcher from the root directory:
```cmd
Start-Live-System.bat
```
