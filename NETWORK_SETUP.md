# MTMMS Network Setup & Portable Deployment Guide

**Mobile Tower Monitoring & Management System (MTMMS)**  
*Department of Information Technology, Government of Goa*

---

## 1. Overview & Architecture

MTMMS is engineered for **100% portability** across any Windows computer and local area network (LAN / Wi-Fi).

```
                      +------------------------------------------+
                      |         HOST COMPUTER (WINDOWS)          |
                      |                                          |
                      |   Django REST API (0.0.0.0:8000)         |
                      |                 ^                        |
                      |                 | Localhost (127.0.0.1)  |
                      |                 v                        |
                      |         MySQL Database (Local)           |
                      |                                          |
                      |   React/Vite Web Portal (0.0.0.0:5174)   |
                      |   UDP Discovery Service (Port 41588)     |
                      +--------------------+---------------------+
                                           |
                                   Same Wi-Fi / LAN
                                           |
                  +------------------------+------------------------+
                  |                                                 |
                  v                                                 v
    +---------------------------+                     +---------------------------+
    |       ANDROID PHONE       |                     |   OTHER LAPTOPS / PCS     |
    |  MTMMS Flutter Mobile APK |                     |     Any Web Browser       |
    |                           |                     |                           |
    | 1. Auto-discovers server  |                     |  http://<SERVER_IP>:5174  |
    |    via UDP / Subnet sweep |                     |                           |
    | 2. Connects to:           |                     |  Communicates with:       |
    |    http://<SERVER_IP>:8000|                     |  http://<SERVER_IP>:8000  |
    +---------------------------+                     +---------------------------+
```

---

## 2. Quick Start: How to Start MTMMS

1. Connect the computer running MTMMS to your local Wi-Fi or Ethernet network.
2. Ensure MySQL / MariaDB service is running.
3. In the project folder, double-click:
   ```cmd
   Start-Live-System.bat
   ```
4. The system will:
   - Detect project root automatically (works from `C:\MTMMS`, `D:\Projects\MTMMS`, or Desktop).
   - Detect the computer's active Wi-Fi/Ethernet IPv4 address (e.g. `192.168.1.15`).
   - Generate `.mtmms-runtime.env`, `web/.env`, and Flutter configuration.
   - Check Windows Defender Firewall rules for ports 8000, 5174, 5173, and 41588.
   - Start Django REST API on `0.0.0.0:8000`.
   - Start UDP LAN Discovery Service on port `41588`.
   - Start React/Vite Web Portal on `0.0.0.0:5174`.
   - Verify API health endpoint at `http://<SERVER_IP>:8000/api/health/`.
   - Display the interactive terminal banner with network endpoints.

---

## 3. How Dynamic IP Detection Works

`mtmms_api/network_utils.py` inspects the machine's network interfaces dynamically:
- Uses Windows PowerShell (`Get-NetIPAddress`) to isolate physical adapters.
- Filters out loopback (`127.0.0.1`), unconfigured APIPA link-local (`169.254.x.x`), and virtual adapters (WSL, Docker, VMware, VirtualBox, VPN).
- Prioritizes active Wi-Fi and physical Ethernet adapters.
- Resolves routing via socket UDP probe against standard LAN gateways.
- Saves the detected IP as the single source of truth in `.mtmms-runtime.env`.
- Automatically supplies the IP to Django (`ALLOWED_HOSTS`), React (`VITE_API_URL`), and Flutter.

---

## 4. How to Connect an Android Phone (Flutter APK)

You only need **ONE portable APK**. You do **not** need to rebuild the APK when moving to different Wi-Fi networks!

1. Install `mobile_tower_app\build\app\outputs\flutter-apk\app-release.apk` (or `mobile_tower_app\app-release.apk`) on your Android phone.
2. Connect the phone to the **SAME Wi-Fi** as the computer running MTMMS.
3. Open the **MTMMS** app.
4. **Self-Discovery in Action**:
   - The app verifies cached server connection.
   - If server IP changed or app is opened for the first time, the app broadcasts a discovery probe on UDP port `41588`.
   - If the router blocks UDP broadcast, it automatically sweeps candidate IPs on the `/24` subnet.
   - Once the server responds with valid MTMMS signature (`"service": "MTMMS API"`), the app locks onto the server.
   - The app navigates to Login Screen with the API ready.
5. Log in with your departmental credentials:
   - **Email / Username**: `admin@mtmms.gov.in` (or your registered officer username)
   - **Password**: `password`

---

## 5. How to Connect Another Laptop / PC (Web Portal)

1. Connect the other laptop or tablet to the **SAME Wi-Fi** as the MTMMS server.
2. Open any web browser (Chrome, Edge, Firefox, Safari).
3. Type the Web URL displayed in the launcher:
   ```
   http://<SERVER_IP>:5174
   ```
   *(Example: `http://192.168.1.15:5174`)*
4. The web application will load and automatically direct all API requests to:
   ```
   http://<SERVER_IP>:8000/api
   ```
5. Log in with your administrator or officer account.

---

## 6. Required Wi-Fi & Network Configuration

- Both the computer and the mobile device/other laptops must be on the **same subnet** (e.g., connected to the same Wi-Fi SSID or same router).
- **No Internet Required**: MTMMS operates entirely within the local offline network. An active internet connection is NOT required.
- **Client / AP Isolation**: Ensure the Wi-Fi router does not have "AP Isolation" or "Client Isolation" turned on (which prevents Wi-Fi devices from communicating with each other). Most home, office, and mobile hotspot Wi-Fi networks allow peer-to-peer communication by default.

---

## 7. Windows Defender Firewall Settings

The MTMMS launcher checks firewall rules automatically. If other devices cannot connect, run:
```cmd
Setup-Firewall.bat
```
*(Right-click and select "Run as administrator")*

This configures inbound rules for:
- **Django REST API**: TCP Port `8000`
- **React/Vite Web Portal**: TCP Port `5174` and `5173`
- **UDP LAN Discovery Service**: UDP Port `41588`

*Note: MySQL (Port 3306) remains private to localhost (`127.0.0.1`) and is NEVER exposed to the LAN.*

---

## 8. Network URLs Reference

| Service | Protocol / Port | URL Format |
|---|---|---|
| **Django REST API** | TCP 8000 | `http://<SERVER_IP>:8000/api` |
| **API Health Check** | TCP 8000 | `http://<SERVER_IP>:8000/api/health/` |
| **React Web Portal** | TCP 5174 | `http://<SERVER_IP>:5174` |
| **Electron Desktop** | Local Runtime | Uses `MTMMS_API_URL` from runtime env |
| **Server Discovery** | UDP 41588 | `255.255.255.255:41588` |

---

## 9. What Happens When the IP Changes?

When you move the computer from one network (e.g. `192.168.1.15`) to another network (e.g. `192.168.0.25`):
1. Run `Start-Live-System.bat` on the new network.
2. The launcher detects the new IP (`192.168.0.25`) in under 1 second.
3. `.mtmms-runtime.env`, `web/.env`, and Flutter configuration are instantly regenerated.
4. Django restarts binding to `0.0.0.0:8000` and allows `192.168.0.25` in `ALLOWED_HOSTS`.
5. Discovery service advertises `http://192.168.0.25:8000/api`.
6. On the Android phone, open the MTMMS app:
   - The app notices the old IP `192.168.1.15` is unreachable.
   - It performs LAN discovery probe on the new Wi-Fi.
   - It finds `192.168.0.25:8000/api`, verifies health, and connects seamlessly.
   - **No rebuilding of APK required. No manual IP typing required.**

---

## 10. Troubleshooting

### Issue 1: "MTMMS Server Not Found" on Phone
1. Verify both the phone and computer are connected to the exact same Wi-Fi SSID.
2. Verify `Start-Live-System.bat` is running on the computer.
3. Run `Setup-Firewall.bat` as Administrator on the computer.
4. Check if the router has "AP Isolation" enabled. If using a phone mobile hotspot, ensure both devices are connected to the hotspot.
5. In the app's splash screen or login screen, tap "Retry Discovery" or "Auto-Discover MTMMS Server on Wi-Fi".

### Issue 2: Web portal opens on server PC but not on other laptops
1. Check that you are typing `http://<SERVER_IP>:5174` (not `localhost`).
2. Run `Setup-Firewall.bat` as Administrator.
3. Test if `http://<SERVER_IP>:8000/api/health/` opens in the other laptop's browser.

### Issue 3: MySQL connection warning during startup
1. Open Windows Services (`services.msc`) and verify `MySQL` or `MariaDB` service is running.
2. Verify the `mtmms` database exists (`mysql -u root -e "CREATE DATABASE IF NOT EXISTS mtmms;"`).
3. You can import `mtmms.sql` if tables need initialization:
   ```cmd
   mysql -u root mtmms < mtmms.sql
   ```

---

## 11. Stopping the System

To stop all MTMMS background processes cleanly:
- Select Option `[5]` from the `Start-Live-System.bat` menu, OR
- Double-click:
  ```cmd
  Stop-System.bat
  ```
This terminates:
- Django backend server
- UDP Discovery service
- Vite / Node web server
- Any running Electron desktop instances
